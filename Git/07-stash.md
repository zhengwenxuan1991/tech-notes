---
title: Git 07 · stash 暂存现场
tags:
  - 技术学习
  - git
date: 2026-11-06
status: active
---

# 07 · stash 暂存现场

> 上一篇：[远程协作](06-远程协作.md) · 下一篇：[reflog 与回退](08-reflog与回退.md)

## 1. 解决什么问题

工作区有未完成改动，但必须临时切分支、拉代码或改别的 bug——又不想现在 commit。`stash` 把现场存进栈，工作区变干净。

更重的并行开发可优先 [Worktree](Git%20Worktree%20使用指南.md)，stash 适合短打断。

## 2. 基本用法

```bash
git stash push -m "wip: login form"
# 旧：git stash / git stash save "msg"

git stash list
git stash show -p stash@{0}
git stash pop                  # 应用并删掉栈顶
git stash apply stash@{0}      # 应用但保留栈项
git stash drop stash@{0}
git stash clear                # 清空（慎）
```

## 3. 常用选项

```bash
git stash push -u -m "include untracked"   # 含未跟踪文件
git stash push -a -m "include ignored"     # 连 ignore 也纳入（少用）
git stash push -p -m "partial"             # 交互挑选
git stash push -- path/file.ts             # 只藏部分路径
```

默认 stash **不包含** untracked；忘记 `-u` 时新文件还在，切分支可能把脏文件带走。

## 4. 冲突与恢复

`pop`/`apply` 可能冲突，处理同 [05](05-冲突处理.md)。冲突后 stash 条目可能仍留在 list（视版本与是否 pop 成功），用 `list` 确认，别急着 `clear`。

```bash
git stash branch wip/login stash@{0}   # 新建分支并应用该 stash，适合藏很久的改动
```

## 5. 和 commit 的取舍

| 方式 | 适合 |
|------|------|
| stash | 分钟～小时级打断，不想留提交 |
| WIP commit | 改动大、怕丢、可能跨天；可用 `fix`/`reset` 后再整理 |
| worktree | 并行两套目录，长期切换 |

## 6. 小结

- stash = 本地临时货架，不进分支历史，也**不会**随 push 上远程。
- 需要未跟踪文件时加 `-u`。
- 长期 WIP 用分支或 worktree 更清晰。
