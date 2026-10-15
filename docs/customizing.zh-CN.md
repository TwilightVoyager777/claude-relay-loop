# 自定义

[English](customizing.md) | 简体中文

## 提交和 pull request 里的 AI 署名（`--no-attribution`）

Claude Code 默认会在提交里加一行共同作者署名（Co-Authored-By），在 pull request 描述里加一句说明。`--no-attribution` 会写一份 `.claude/settings.json`：

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

这个文件已经存在的话，`init.sh` 不动它，只把上面这段打印出来，让你自己合并。这个文件不在 `.gitignore` 里：提交之后，仓库里每个用 Claude Code 的人都会受它影响。

## 每次提交后自动 push（`--auto-push`）

加上 `.claude/hooks/auto-push.sh`，并在 `.claude/settings.local.json` 里把它注册为一个 `PostToolUse` 钩子；这个设置文件不进 git，只影响你自己。Claude Code 跑的 Bash 命令里只要含 `git commit`，钩子就会跑 `git push -u origin HEAD`，并显示结果的最后一行。

- 钩子运行时需要 `jq`。
- 它把当前所在的分支 push 到 `origin`，包括主会话把计划提交到 `main` 的时候。如果你不想每个提交都马上到远程，就别用它。
- 要关掉它，删掉 `.claude/settings.local.json` 里的 `hooks` 那一项。

## 循环的默认做法

默认做法写在 `CLAUDE.md`（加了 `--team` 时在 `CLAUDE.local.md`）的「默认做法」下面：

- **计划审阅。** 主会话写完计划就开子会话。想先看某张卡的计划，让 Cowork 在那张卡上写 `计划审阅：先给我看`；想每张卡都先看，就改这条默认做法。
- **一份计划一个子会话。** 只有计划里的任务互不相干、改的是不同的文件时，才拆开。

## 语言（`--lang`）

`--lang en`（默认）或 `--lang zh` 决定 `init.sh` 写出的所有东西用哪种语言：规则文件、各种模板，以及最后打印的「下一步」。两种语言的文件名和结构一样。除了「下一步」，`init.sh` 的其他输出都是英文。

不管选哪种，两层都用你跟它们说话的语言回复。想让 Cowork 和 Claude Code 用第三种语言写项目文件（roadmap、方案、交接记录），改 `roadmap.md` 开头的「文件语言」那一行，或者在第一次会话时请 Cowork 改。规则文件本身仍是英文或中文。

## 以后再加团队包

在已经装了单人版的项目上跑 `init.sh --team`，会因为 `CLAUDE.md` 已存在而跳过它，并打印切换用的命令，路径、语言和项目名都已填好。不加 `--lang` 时，`init.sh` 会照 `COWORK.md` 认出项目原来用的语言。打印出来大致是这样：

```bash
mv '/path/to/my-project/CLAUDE.md' '/path/to/my-project/CLAUDE.local.md' && '/path/to/claude-relay-loop/init.sh' '/path/to/my-project' --team --lang zh --name '我的项目'
```

之后 `CLAUDE.local.md` 里是你自己的循环规则（不进 git），新的 `CLAUDE.md` 里是给队友的共用规则。

## 以后更新规则

`init.sh` 不会更新已经在用循环的项目。想用上新版规则，把你的文件和最新的 `template/zh-CN/`（或 `template/en/`）比一比，手动合并。`CLAUDE.md`（加了 `--team` 时是 `CLAUDE.local.md`）里的 `<!-- relay-loop:rules -->` 那一行要留着：`init.sh` 靠它判断循环规则在不在。
