# 和队友协作 — {{PROJECT_NAME}}

Cowork 每次开会话都读这个文件（COWORK.md 第 2 节）。队友照 `CLAUDE.md` 做；负责人自己的 Claude Code 照 `CLAUDE.local.md` 做。

## 成员

| 名字 | 负责的部分 | 用的工具 |
|---|---|---|

由 Cowork 和负责人一起填。

## 队友怎么领任务

1. Cowork 照常在 `pipe/cowork/latest.md` 的「下一步」写任务卡，「负责人」列写队友的名字。
2. Cowork 同时把这张卡写成一个负责人能直接发出去的文件：`features/F<NNN>-<slug>/F<NNN>-T<NN>-card.md`，照 `features/_template/task-card.md` 写。
3. 负责人提交并 push 规划文件，让队友能读到功能方案，然后把任务卡文件发给队友。Cowork 从不直接联系队友。
4. 队友交付一个分支和一个 pull request。pull request 的描述就是队友的实现记录；队友不用 `pipe/`。

## 读结果

- 负责人把 pull request（或者它的链接和描述）贴进 Cowork。Cowork 更新任务表、功能方案和 `roadmap.md`，并在 `pipe/cowork/latest.md` 里记下还要负责人定的事。
- 写新任务卡之前，先看看已合并的 pull request，免得重复派活。
- 合并、发布和改方案，都由负责人定。

## 队友之间的约定

两个人的工作有交叉时（共用的数据、模块之间的接口），先把约定单独作为一个功能写下来，合并之后两边再在它上面开发。
