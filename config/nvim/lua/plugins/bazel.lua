-- Bazel runner: fzf pickers over the current package's targets, run in a
-- float toggleterm (same shape as rust.lua). Queries stay package-scoped so
-- they are cheap even in big monorepos, where `//...` loads thousands of
-- packages and can OOM a small VM.

local last -- { cmd, cwd } of the previous run, for <leader>Bl

local function run(cmd, cwd)
  last = { cmd = cmd, cwd = cwd }
  require("toggleterm.terminal").Terminal:new({
    cmd = cmd,
    dir = cwd,
    direction = "float",
    close_on_exit = false,
  }):toggle()
end

-- Workspace root, package path ("" for the root package) and package dir of the current buffer.
local function context()
  local ws = vim.fs.root(0, { "MODULE.bazel", "WORKSPACE.bazel", "WORKSPACE" })
  local pkg_dir = vim.fs.root(0, { "BUILD.bazel", "BUILD" })
  if not ws or not pkg_dir or #pkg_dir < #ws then
    vim.notify("Not in a Bazel package", vim.log.levels.WARN)
    return
  end
  return ws, pkg_dir == ws and "" or pkg_dir:sub(#ws + 2), pkg_dir
end

-- Run `bazel query`, then let the user pick targets (Tab for several) and run `bazel <verb>` on them.
local function pick(verb, query, ws)
  vim.notify("bazel query " .. query)
  vim.system({ "bazel", "query", query }, { cwd = ws, text = true }, function(r)
    vim.schedule(function()
      local targets = vim.split(r.stdout or "", "\n", { trimempty = true })
      if r.code ~= 0 or #targets == 0 then
        local err = vim.split(vim.trim(r.stderr or ""), "\n")
        vim.notify("bazel query: " .. (r.code ~= 0 and err[#err] or "no targets"), vim.log.levels.WARN)
        return
      end
      local function cmd(selected)
        return "bazel " .. verb .. " " .. table.concat(selected, " ")
      end
      require("fzf-lua").fzf_exec(targets, {
        prompt = "bazel " .. verb .. "❯ ",
        fzf_opts = { ["--multi"] = true },
        winopts = { height = 0.4, width = 0.6 },
        actions = {
          -- Enter: run
          ["default"] = function(selected)
            run(cmd(selected), ws)
          end,
          -- Alt-Enter: edit the command first (add flags, --test_filter=...)
          ["alt-enter"] = function(selected)
            vim.ui.input({ prompt = "Run: ", default = cmd(selected) .. " " }, function(input)
              if input and input ~= "" then
                run(input, ws)
              end
            end)
          end,
        },
      })
    end)
  end)
end

-- fmt gets the package pattern, e.g. "tests(%s)" -> tests(//pkg:all)
local function in_package(verb, fmt)
  local ws, pkg = context()
  if ws then
    pick(verb, fmt:format("//" .. pkg .. ":all"), ws)
  end
end

-- Tests in this package that (transitively) depend on the current file.
local function test_file()
  local ws, pkg, pkg_dir = context()
  if not ws then
    return
  end
  local file = vim.api.nvim_buf_get_name(0):sub(#pkg_dir + 2)
  if file == "" or file:match("^BUILD") then
    return in_package("test", "tests(%s)")
  end
  pick("test", ("tests(rdeps(//%s:all, //%s:%s))"):format(pkg, pkg, file), ws)
end

local function goto_build()
  local _, _, pkg_dir = context()
  if pkg_dir then
    local f = pkg_dir .. "/BUILD.bazel"
    vim.cmd.edit(vim.uv.fs_stat(f) and f or pkg_dir .. "/BUILD")
  end
end

return {
  "akinsho/toggleterm.nvim",
  optional = true,
  keys = {
    { "<leader>Bt", function() in_package("test", "tests(%s)") end, desc = "Test: pick in package" },
    { "<leader>Bf", test_file, desc = "Test: this file" },
    { "<leader>Bb", function() in_package("build", "kind(rule, %s)") end, desc = "Build: pick in package" },
    { "<leader>Br", function() in_package("run", "kind(rule, %s)") end, desc = "Run: pick in package" },
    {
      "<leader>Bl",
      function()
        if last then
          run(last.cmd, last.cwd)
        else
          vim.notify("No previous bazel run", vim.log.levels.WARN)
        end
      end,
      desc = "Re-run last",
    },
    { "<leader>BB", goto_build, desc = "Go to BUILD file" },
  },
}
