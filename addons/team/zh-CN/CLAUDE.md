# 团队规则 — {{PROJECT_NAME}}

每个人的 Claude Code 都会读这个文件。有 `CLAUDE.local.md` 的话，那里是负责人自己的工作规则，在负责人的会话里以它为准。

## 任务和交付

- 你只做负责人发给你的任务卡（编号像 `F003-T02`，卡上有「负责人」一行），而且只做分给你的那张、只做卡上写的事。有不清楚的，在 pull request 或回复里问，然后停下；不要猜。
- 任务卡会指向 `features/F<NNN>-<slug>/plan.md` 里的功能方案。
- 开工前：先 `git fetch`，再从最新的 main 拉分支 `feat/F<NNN>-T<NN>-<slug>`。不要提交到 main，不要 force-push。
- 做完后：跑测试，只提交这张卡的改动，push 你的分支，向 main 开 pull request。按 pull request 模板的几节写：任务卡和做卡的人、改了什么、怎么运行和验证、测试结果（有失败或没跑的要写明）、没做完或没验证的、要问负责人的问题。
- 一次只做一张卡。开完 pull request 就停下，由负责人审阅和合并。
- `pipe/`、`features/`、`roadmap.md`、`COWORK.md` 和 `TEAM.md` 由负责人的规划层维护。想改的话在 pull request 里提，不要直接改。

## 边界

- 用项目里实际有的测试和检查。失败的、跳过的检查，如实汇报。
- 不编造提交号或结果。
- 只 push 自己的分支。不合并、不部署、不发布。
- 密钥、密码和 token 不要写进代码、文档和 git 历史。
