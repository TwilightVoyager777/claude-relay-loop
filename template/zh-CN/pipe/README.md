# pipe/ — 交接区

Cowork（规划）和 Claude Code（实现）从不直接对话。它们靠这里的文件交接工作，每个功能只要负责人来回各转一段短话。

| 路径 | 谁写 | 放什么 |
|---|---|---|
| `cowork/latest.md` | Cowork | 当前状态、任务表、任务卡（覆盖写） |
| `cowork/log/YYYY-MM-DD.md` | Cowork | 历史（只追加） |
| `claudecode/latest.md` | Claude Code | 当前的实现状态（覆盖写） |
| `claudecode/log/YYYY-MM-DD.md` | Claude Code | 历史（只追加） |
| `claudecode/plans/` | Claude Code | 实现计划，一张卡一份 |

每边只写自己的文件夹，可以读对方的。谁都不改写对方的结论。

## 循环

```
Cowork ──「发给 Claude Code 的话」──▶ 负责人 ──▶ Claude Code 主会话「F003 …」
                                                 │ 写计划，开子会话「F003-T01 执行：…」
                                                 │ 核对，每张卡汇报
Cowork ◀──「发给 Cowork 的话」─────── 负责人 ◀───┘ 功能做完时
```

## latest.md 的四段

两边的 `latest.md` 都用这四段，顺序如下：

1. **正在做什么**：手上在做的事。
2. **已完成 / 已决定**：做完的工作和定下的决定，带日期和提交号。
3. **下一步**：Cowork 这边先是任务表，再是任务卡；Claude Code 这边是它接下来要做的事。
4. **需要对方知道 / 回答的事**：要对方回答的问题、要对方知道的事。

## 发给 Claude Code 的话

功能可以开工时由 Cowork 写。负责人把它贴进一个**新的** Claude Code 会话。

```text
F003 CSV 导出 — 主会话开工
任务卡：F003-T01（pipe/cowork/latest.md › 下一步）
计划审阅：跳过（写完计划直接开子会话）
先读：features/F003-csv-export/plan.md
备注：导出的列顺序要和 plan.md §3 一致。
```

- 第一行以 F 编号开头，会话标题也就以它开头。
- 「计划审阅」写 `跳过` 或 `先给我看`。
- 「备注」可以不写，用来写卡上没说的事。

## 发给 Cowork 的话

功能做完时由 Claude Code 主会话写。负责人把它贴进 Cowork。

```text
F003 CSV 导出做完了。
任务卡：F003-T01、F003-T02。已合并进 main：是（a1b2c3d）。
测试：全量通过（212 条）。
请读：这次会话还没读过 COWORK.md 的话先读它，再读 pipe/claudecode/latest.md › 已完成 / 已决定（偏离）、需要对方知道 / 回答的事。
未验证：没试过超过 10 万行的导出。
需要你定：偏离 2（日期按 ISO 8601 导出）接不接受？
请更新方案状态、任务表和 roadmap.md，然后给我下一个功能的「发给 Claude Code 的话」。
```

## 日志

一天一个文件，用 `date +%F` 命名。只追加，不改写以前的条目。每条写：时间、F 编号或卡号、改了或定了什么、为什么、对方需要知道什么。
