-- Monkey-patches for kawre/leetcode.nvim. Kept in one file so it's easy
-- to lift into an upstream PR later if any of these become first-class
-- in the plugin.
--
-- Patches applied:
--   1. Replace hardcoded LEETCODE ascii banner with WITHERS
--   2. Add a "Google" button to the main menu that expands into a
--      submenu picking the time window (1m / 3m / 6m / >6m). Each
--      window opens a fzf-lua picker over LeetCode's Google company
--      favorite list (Premium required).
--   3. Inside the picker: ctrl-t filters by topic tag, ctrl-r clears.
--   4. Expose :LeetGoogle [window] (bang = bust cache) for the same picker
--   5. Route Rust questions into per-question Cargo crates so
--      rust-analyzer attaches with full project semantics instead of
--      standalone mode.
--
-- The picker reuses leetcode.nvim's own GraphQL helper (auth + retry)
-- and caches responses for 24h under stdpath("cache")/leetcode-company.

local M = {}

-- ======================================================================
-- Banner override
-- ======================================================================

local BANNER = {
  [[██╗    ██╗██╗████████╗██╗  ██╗███████╗██████╗ ███████╗]],
  [[██║    ██║██║╚══██╔══╝██║  ██║██╔════╝██╔══██╗██╔════╝]],
  [[██║ █╗ ██║██║   ██║   ███████║█████╗  ██████╔╝███████╗]],
  [[██║███╗██║██║   ██║   ██╔══██║██╔══╝  ██╔══██╗╚════██║]],
  [[╚███╔███╔╝██║   ██║   ██║  ██║███████╗██║  ██║███████║]],
  [[ ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝]],
}

local function override_banner()
  local Lines = require("leetcode-ui.lines")
  local Header = Lines:extend("LeetMenuHeader")
  function Header:init()
    Header.super.init(self, {}, { hl = "Keyword" })
    for _, line in ipairs(BANNER) do
      self:append(line):endl()
    end
  end
  package.loaded["leetcode-ui.lines.menu-header"] = Header()
end

-- ======================================================================
-- Company favorite picker (Google) with cache
-- ======================================================================

local CACHE_DIR = vim.fn.stdpath("cache") .. "/leetcode-company"
local TTL_SECONDS = 24 * 60 * 60
local DEFAULT_WINDOW = "three-months"
-- The four favoriteSlug windows LeetCode actually exposes for company
-- tags. "all-time" is NOT one of them — the API returns an empty list
-- for it (manifests as the "Premium required" warning).
local WINDOWS = {
  "thirty-days",
  "three-months",
  "six-months",
  "more-than-six-months",
}

local QUERY = [[
query favoriteQuestionList(
  $favoriteSlug: String!
  $limit: Int
  $skip: Int
) {
  favoriteQuestionList(
    favoriteSlug: $favoriteSlug
    limit: $limit
    skip: $skip
  ) {
    questions {
      titleSlug
      title
      questionFrontendId
      difficulty
      topicTags { name slug }
      acRate
      status
      frequency
      paidOnly
    }
    totalLength
    hasMore
  }
}
]]

local function cache_path(slug)
  return CACHE_DIR .. "/" .. slug .. ".json"
end

local function cache_read(slug)
  local f = io.open(cache_path(slug), "r")
  if not f then
    return nil
  end
  local body = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, body)
  if not ok or type(data) ~= "table" then
    return nil
  end
  if (os.time() - (data.fetched_at or 0)) > TTL_SECONDS then
    return nil
  end
  return data.questions
end

local function cache_write(slug, questions)
  vim.fn.mkdir(CACHE_DIR, "p")
  local f = io.open(cache_path(slug), "w")
  if not f then
    return
  end
  f:write(vim.json.encode { fetched_at = os.time(), questions = questions })
  f:close()
end

local function fetch(slug, cb)
  local cached = cache_read(slug)
  if cached then
    return cb(cached, true)
  end

  local ok, api_utils = pcall(require, "leetcode.api.utils")
  if not ok then
    vim.notify("LeetGoogle: leetcode.nvim not loaded yet", vim.log.levels.ERROR)
    return
  end

  api_utils.query(QUERY, { favoriteSlug = slug, limit = 1000, skip = 0 }, {
    callback = function(res, err)
      if err then
        vim.notify("LeetGoogle: " .. err.msg, vim.log.levels.ERROR)
        return
      end
      local list = res and res.data and res.data.favoriteQuestionList
      local qs = list and list.questions
      if not qs or #qs == 0 then
        vim.notify("LeetGoogle: empty response (Premium required for company tags)", vim.log.levels.WARN)
        return
      end
      cache_write(slug, qs)
      cb(qs, false)
    end,
  })
end

-- Resolve favoriteQuestionList responses (their shape uses titleSlug,
-- topicTags, frequency, etc.) into the canonical `lc.cache.Question`
-- objects from leetcode.nvim's problemlist cache. This lets us hand
-- them to leetcode.nvim's own question picker pipeline and inherit
-- its rendering (difficulty dot, AC%, status icon, slug highlight).
--
-- We stash the fav-list-only fields (frequency, topicTags) on the
-- canonical question as `_g_freq` / `_g_tags` so we can sort and
-- tag-filter without losing the canonical Q identity.
local function favorite_to_canonical(qs)
  local problemlist = require("leetcode.cache.problemlist")
  local missing = 0
  local result = {}
  for _, fq in ipairs(qs) do
    local ok, canon = pcall(problemlist.get_by_title_slug, fq.titleSlug)
    if ok then
      canon._g_freq = fq.frequency or 0
      canon._g_tags = fq.topicTags or {}
      table.insert(result, canon)
    else
      missing = missing + 1
    end
  end
  table.sort(result, function(a, b)
    return (a._g_freq or 0) > (b._g_freq or 0)
  end)
  return result, missing
end

local function has_tag(canon, tag_slug)
  for _, t in ipairs(canon._g_tags or {}) do
    if t.slug == tag_slug then
      return true
    end
  end
  return false
end

local function collect_tags(canonical_qs)
  local count = {}
  for _, q in ipairs(canonical_qs) do
    for _, t in ipairs(q._g_tags or {}) do
      count[t.slug] = (count[t.slug] or 0) + 1
    end
  end
  local list = {}
  for slug, n in pairs(count) do
    table.insert(list, { slug = slug, count = n })
  end
  table.sort(list, function(a, b)
    return a.count > b.count
  end)
  return list
end

local build_picker -- forward decl (recursive: tag-filter re-enters)

---@param canonical_qs table[] full (unfiltered) canonical Question list
---@param label_slug string company-window slug, for prompt display
---@param from_cache boolean for prompt display
---@param tag_filter? string topic slug; nil = no filter
build_picker = function(canonical_qs, label_slug, from_cache, tag_filter)
  local question_picker = require("leetcode.picker.question")
  local problemlist = require("leetcode.cache.problemlist")
  local Picker = require("leetcode.picker")
  local fzf = require("fzf-lua")
  local deli = " " -- same hidden delimiter as leetcode.nvim's own picker

  local filtered = canonical_qs
  if tag_filter then
    filtered = vim.tbl_filter(function(q)
      return has_tag(q, tag_filter)
    end, canonical_qs)
  end

  -- Build rows using leetcode.nvim's own renderers: identical look-and-feel
  -- to `:Leet list` (difficulty dot, AC%, slug). Order preserved (we
  -- already sorted by frequency upstream).
  local items = question_picker.items(filtered, {})
  local lines = {}
  for _, item in ipairs(items) do
    table.insert(lines, Picker.normalize({ item })[1] .. deli .. Picker.apply_hl(item.value.title_slug, "leetcode_alt"))
  end

  fzf.fzf_exec(lines, {
    prompt = ("%s%s%s ❯ "):format(
      label_slug,
      from_cache and " [cache]" or "",
      tag_filter and (" #" .. tag_filter) or ""
    ),
    winopts = { height = question_picker.height, width = question_picker.width },
    fzf_opts = {
      ["--delimiter"] = deli,
      ["--nth"] = "3..-3",
      ["--header"] = "ctrl-t: filter by tag  ·  ctrl-r: clear tag filter",
    },
    actions = {
      ["default"] = function(selected)
        if not (selected and selected[1]) then
          return
        end
        local slug = Picker.hidden_field(selected[1], deli)
        if not slug then
          return
        end
        local ok, q = pcall(problemlist.get_by_title_slug, slug)
        if not ok then
          vim.notify("LeetGoogle: problem not in cache — run `:Leet cache update` first", vim.log.levels.WARN)
          return
        end
        question_picker.select(q)
      end,
      ["ctrl-t"] = function()
        local tag_list = collect_tags(canonical_qs)
        local tag_labels = {}
        for _, t in ipairs(tag_list) do
          table.insert(tag_labels, ("%-30s (%d)"):format(t.slug, t.count))
        end
        fzf.fzf_exec(tag_labels, {
          prompt = "Tag ❯ ",
          winopts = { height = 0.5, width = 0.5 },
          actions = {
            ["default"] = function(sel)
              if not (sel and sel[1]) then
                return
              end
              local chosen = sel[1]:match("^(%S+)")
              build_picker(canonical_qs, label_slug, from_cache, chosen)
            end,
          },
        })
      end,
      ["ctrl-r"] = function()
        build_picker(canonical_qs, label_slug, from_cache, nil)
      end,
    },
  })
end

local function pick(slug)
  fetch(slug, function(qs, from_cache)
    local canonical, missing = favorite_to_canonical(qs)
    if #canonical == 0 then
      vim.notify("LeetGoogle: no problems resolved in local cache — run `:Leet cache update`", vim.log.levels.WARN)
      return
    end
    if missing > 0 then
      vim.notify(("LeetGoogle: %d/%d problems missing from cache (skipped)"):format(missing, #qs), vim.log.levels.INFO)
    end
    build_picker(canonical, slug, from_cache, nil)
  end)
end

---@param company string e.g. "google"
---@param window? string e.g. "three-months" (default)
function M.pick_company(company, window)
  pick(("%s-%s"):format(company, window or DEFAULT_WINDOW))
end

-- ======================================================================
-- Menu page override: add Google button
-- ======================================================================

local function override_menu()
  local cmd = require("leetcode.command")
  local Page = require("leetcode-ui.group.page")
  local Title = require("leetcode-ui.lines.title")
  local Buttons = require("leetcode-ui.group.buttons.menu")
  local Button = require("leetcode-ui.lines.button.menu")
  local ExitButton = require("leetcode-ui.lines.button.menu.exit")
  local header = require("leetcode-ui.lines.menu-header")
  local footer = require("leetcode-ui.lines.footer")

  local page = Page()
  page:insert(header)
  page:insert(Title({}, "Menu"))
  page:insert(Buttons {
    Button("Problems", {
      icon = "",
      sc = "p",
      on_press = function()
        cmd.set_menu_page("problems")
      end,
      expandable = true,
    }),
    Button("Google", {
      icon = "",
      sc = "g",
      on_press = function()
        cmd.set_menu_page("google")
      end,
      expandable = true,
    }),
    Button("Statistics", {
      icon = "󰄪",
      sc = "s",
      on_press = function()
        cmd.set_menu_page("stats")
      end,
      expandable = true,
    }),
    Button("Cookie", {
      icon = "󰆘",
      sc = "i",
      on_press = function()
        cmd.set_menu_page("cookie")
      end,
      expandable = true,
    }),
    Button("Cache", {
      icon = "",
      sc = "c",
      on_press = function()
        cmd.set_menu_page("cache")
      end,
      expandable = true,
    }),
    ExitButton(),
  })
  page:insert(footer)

  package.loaded["leetcode-ui.group.page.menu"] = page
end

-- ======================================================================
-- Google submenu page: pick window (1m / 3m / 6m / all-time)
-- ======================================================================

local function override_google_page()
  local Page = require("leetcode-ui.group.page")
  local Title = require("leetcode-ui.lines.title")
  local Buttons = require("leetcode-ui.group.buttons.menu")
  local Button = require("leetcode-ui.lines.button.menu")
  local BackButton = require("leetcode-ui.lines.button.menu.back")
  local header = require("leetcode-ui.lines.menu-header")
  local footer = require("leetcode-ui.lines.footer")

  -- nf-fa-calendar (U+F073), written as bytes so it survives any
  -- pipeline that strips supplementary-plane / PUA chars.
  local CALENDAR = "\xef\x81\xb3"

  local function make(label, sc, window)
    return Button(label, {
      icon = CALENDAR,
      sc = sc,
      on_press = function()
        M.pick_company("google", window)
      end,
      expandable = true,
    })
  end

  local page = Page()
  page:insert(header)
  page:insert(Title({}, "Google"))
  page:insert(Buttons {
    make("Thirty days", "1", "thirty-days"),
    make("Three months", "2", "three-months"),
    make("Six months", "3", "six-months"),
    make("More than 6 months", "4", "more-than-six-months"),
    BackButton("menu"),
  })
  page:insert(footer)

  package.loaded["leetcode-ui.group.page.google"] = page
end

-- ======================================================================
-- Rust per-question crate: rust-analyzer attaches as a proper crate
-- instead of degraded standalone mode.
--
-- For Rust questions only, route the file into a per-question Cargo
-- crate layout:
--
--   <storage>/<id>.<slug>-rust/
--     Cargo.toml          minimal [package] manifest
--     src/lib.rs          the solution (lib crate, no fn main needed —
--                         leetcode snippets are impl-only)
--
-- Legacy flat `<storage>/<id>.<slug>.rs` is migrated on first open
-- (content copied into lib.rs, the flat file removed).
-- ======================================================================

local CARGO_TOML_TEMPLATE = [[
[package]
name = "%s"
version = "0.1.0"
edition = "2021"
]]

-- Virtual manifest at the storage root. Without it rust-analyzer pins to
-- whichever per-question crate it discovers first and every other
-- question opens as an unlinked-file (no IDE services). The glob member
-- auto-includes new `<id>.<slug>-rust` crates, so there's no list to
-- maintain.
local WORKSPACE_TOML = [[
[workspace]
resolver = "2"
members = ["*-rust"]
]]

-- Idempotent: leetcode's `enter` hook fires on every menu open, but we
-- only need to monkey-patch the Question class once.
local rust_patched = false

local function override_rust_path()
  if rust_patched then
    return
  end
  -- IMPORTANT: this must run AFTER leetcode.start() (which is what
  -- finally calls config.setup() and populates config.storage). Calling
  -- it earlier crashes because `leetcode-ui.question` transitively
  -- requires `leetcode.cache.cookie`, which reads config.storage.cache
  -- at module-load time. The `enter` hook satisfies that ordering.
  local Question = require("leetcode-ui.question")
  local config = require("leetcode.config")
  local utils = require("leetcode.utils")

  local orig_path = Question.path

  function Question:path()
    if self.lang ~= "rust" then
      return orig_path(self)
    end

    local lang = utils.get_lang(self.lang)
    local id = tostring(self.q.frontend_id)
    local slug = self.q.title_slug

    local crate_dir = config.storage.home:joinpath(("%s.%s-rust"):format(id, slug))
    local src_dir = crate_dir:joinpath("src")
    local rs_file = src_dir:joinpath("lib.rs")
    local cargo_toml = crate_dir:joinpath("Cargo.toml")
    local legacy = config.storage.home:joinpath(("%s.%s.%s"):format(id, slug, lang.ft))

    crate_dir:mkdir { parents = true, exists_ok = true }
    src_dir:mkdir { parents = true, exists_ok = true }

    -- Ensure the storage root is a Cargo workspace so rust-analyzer loads
    -- every per-question crate at once instead of pinning to one.
    local ws_toml = config.storage.home:joinpath("Cargo.toml")
    if not ws_toml:exists() then
      ws_toml:write(WORKSPACE_TOML, "w")
    end

    if not cargo_toml:exists() then
      local pkg = ("lc-%s-%s"):format(id, slug:gsub("[^%w_-]", "-"))
      cargo_toml:write(CARGO_TOML_TEMPLATE:format(pkg), "w")
    end

    local existed = rs_file:exists()
    if not existed then
      if legacy:exists() then
        rs_file:write(legacy:read(), "w")
        legacy:rm()
        existed = true
      else
        rs_file:write(self:snippet(), "w")
      end
    end

    self.file = rs_file
    return rs_file:absolute(), existed
  end

  rust_patched = true
end

-- Exposed so the plugin spec's `enter` hook can wire it in; the hook
-- is the earliest point at which leetcode.config.storage exists.
M.apply_rust_patch = override_rust_path

-- ======================================================================
-- Entry point
-- ======================================================================

function M.apply()
  override_banner()
  override_google_page()
  override_menu()

  vim.api.nvim_create_user_command("LeetGoogle", function(o)
    local window = (o.args ~= "" and o.args) or DEFAULT_WINDOW
    if o.bang then
      pcall(os.remove, cache_path("google-" .. window))
    end
    pick("google-" .. window)
  end, {
    nargs = "?",
    bang = true,
    desc = "Pick LeetCode problem from Google company tag (! to bust cache)",
    complete = function()
      return WINDOWS
    end,
  })
end

return M
