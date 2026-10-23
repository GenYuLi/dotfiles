---
name: weekly-leader-sync
description: Use when Withers asks to prepare for a recurring 1:1, weekly, sync or check-in with a manager, lead or exec (Mykola, Nate, Mutema, Reza, or any named leader), or says 對齊方向 / 準備 1on1 / 他這週在忙什麼 / 跟主管聊什麼. Also use when asked to write up what a leader did this week.
---

# Weekly leader sync

一份給 Withers 自己看的會前包：先判讀，再問題，再自己的 update，最後留會後空格。研究要深，輸出要短。

## 輸入

- LEADER：名字 + Slack user ID + GitHub login（用 `slack_search_users` 查 ID；GitHub login 用 `gh search prs --author`）
- WEEK：預設「上週一 00:00 台北」到現在
- MY_WEEK：Withers 這週做了什麼；沒給就從 Withers 自己的 Slack / gh / Jira 足跡推，並標「推測」

## 研究（平行做，每條附連結）

1. **先讀本地**：memory 裡該人的檔、vault `etched/0-onboarding/2-people/<LEADER>.md` 與上次 1:1 筆記；上次答應的事這次要追。
2. **Slack**：`from:<@ID> after:WEEK` 全讀，按 thread 分組；另查 `<@ID> after:WEEK` 裡**他被 @ 卻沒回的 thread**，單獨列出。
3. **GitHub**：他 author / review / comment 的 PR；review comment 原話留下來，那是他的標準。
4. **Jira**：assignee 或 reporter 是他、WEEK 內更新的票；Epic 狀態變化。
5. **Confluence / Google Doc**：他這週建立或大改的頁面；1:1 notes doc 若存在，讀 action items。

時間一律換成台北時間並標 TPE。查不到的來源要列在最後一節。

## 輸出契約（順序與上限都是硬的）

每節開頭就是結論，證據放後面。

```
## 0. 一句話判讀                ≤ 40 字：他這週最在意的事 + 對我的影響
## 1. 他這週三件事              三行編號，每行照這個模板，§1 在第三個連結後結束：
                                `N. <事實，一個動詞一個結果，≤ 30 字，無日期票號>。對我：<≤ 15 字>。 [來源](url)`
                                例：`1. PDU 遠端 AC cycle 上線，client 還沒好。對我：下週二 Pega 要用。 [ETCH-49515](…)`
## 2. 被 @ 但沒回               thread 標題 + 連結，各 ≤ 30 字；沒有就寫「無」
## 3. 方向訊號 / 思考方式 / 跟我有關   各 ≤ 3 點，每點 ≤ 40 字
## 4. 問題 5 個                 英文 ≤ 25 字 + 中文一行「為什麼問」；順序：他的事 → 方向 → 我的事；
                                至少 1 題問「做 X 決定時最難取捨的是什麼」
## 5. 我的 2 分鐘 update        英文 ≤ 120 字：做了什麼 / 卡在哪 / 下週要他拍板的 1 件事
## 6. 會後填                    他給的方向：__ / 我答應的事：__ / 下週追蹤：__
## 7. 來源與沒查到的            查了什麼、沒查到什麼
```

全文 ≤ 900 字（不含連結與 §7）。無法用連結佐證的句子標「推測」。

## 會後

Withers 回來填 §6 後，把 §6 與他的原話 append 到 vault `etched/0-onboarding/2-people/<LEADER>.md`（沒有就建，照 `_meta/templates/note.md`，並掛到該資料夾的 `00` 筆記），更新 memory 裡對該人的方向判讀。

## 常見錯誤

| 錯誤 | 改法 |
|---|---|
| 把研究全寫出來，兩千字 | 契約上限是硬的；多出來的放 §7 一句「還有 N 個 thread 沒寫」 |
| §1 每件塞進時間線、三個日期、兩個票號，或在三行後加括號補充 | 照模板那一行寫；日期、票號、補充都屬於 §7 |
| 問題是在報告自己 | §4 前三題必須是他的事 |
| 時間留 PDT | 全部換 TPE |
| 「已 merge」「已同意」沒連結 | 標推測，或刪 |
| 沒看上次 1:1 答應的事 | 先讀 vault 2-people 與 memory，追蹤項放進 §4 或 §5 |

## 例子

Withers：「幫我準備週一跟 Mykola 的 weekly」
→ 查 Mykola ID 與 login → 讀 memory + vault 2-people/Mykola → 四路平行查 WEEK 足跡 → 照契約輸出 §0–§7 → 等 Withers 填 §6 → 寫回 vault 與 memory。
