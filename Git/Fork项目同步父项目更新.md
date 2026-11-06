# Fork 项目同步父项目（upstream）更新

> 系统学习入口：[Git 系统学习 · 课程大纲](00-课程大纲.md)

> 场景：你 fork 了别人的项目，原项目（父项目）持续更新，你想把这些更新同步到你自己的 fork 中。

---

## 1. 先搞清楚三个概念

| 名称 | 含义 | 例子 |
|------|------|------|
| **origin** | 你自己的 fork（你有写权限） | `https://github.com/你的名字/项目.git` |
| **upstream** | 父项目 / 原仓库（通常只有读权限） | `https://github.com/原作者/项目.git` |
| **fork** | 从原仓库复制一份到你自己账号下的操作 | —— |

同步的核心思路就是：**从 upstream 拉更新 → 合并到本地 → 推送到 origin**。

---

## 2. 首次配置：添加 upstream 远程仓库

克隆你自己的 fork 后，默认只有 `origin`。先确认一下：

```bash
git remote -v
```

输出大概是这样（只有 origin，没有 upstream）：

```
origin    https://github.com/你的名字/项目.git (fetch)
origin    https://github.com/你的名字/项目.git (push)
```

添加 upstream（把地址换成父项目的地址）：

```bash
git remote add upstream https://github.com/原作者/项目.git
```

如果是 SSH 方式：

```bash
git remote add upstream git@github.com:原作者/项目.git
```

再确认一次：

```bash
git remote -v
```

应该能看到 `origin` 和 `upstream` 两个了。

---

## 3. 同步更新（标准流程）

### 3.1 切到主分支

```bash
git checkout main      # 如果主分支叫 master 就换成 master
```

### 3.2 拉取 upstream 的最新代码

```bash
git fetch upstream
```

> `fetch` 只是把 upstream 的代码下载到本地，**不会改动你正在工作的分支**，很安全。

### 3.3 合并到本地分支

```bash
git merge upstream/main    # upstream 后面跟父项目的主分支名
```

### 3.4 推送到你自己的 fork（origin）

```bash
git push origin main
```

完成。此时你的 fork 在 GitHub 上的代码就和父项目同步了。

---

## 4. 推荐做法：用 rebase 保持历史干净

如果你想让提交历史是一条直线、不产生多余的 merge commit，可以用 `rebase` 代替 `merge`：

```bash
git fetch upstream
git rebase upstream/main
git push origin main --force-with-lease    # rebase 后需要强推
```

> ⚠️ 注意：
> - `--force-with-lease` 比 `-f` / `--force` 更安全，它会在远端有别人新提交时拒绝推送。
> - **强推只对自己的 fork 用**，千万别对协作的共享分支强推。

---

## 5. 一键同步（3 条命令搞定）

如果只是想快速同步，记住这三步：

```bash
git fetch upstream
git merge upstream/main
git push origin main
```

---

## 6. 遇到冲突怎么办

合并时如果报冲突（CONFLICT）：

```bash
git merge upstream/main
# Auto-merging xxx.java
# CONFLICT (content): Merge conflict in xxx.java
```

处理步骤：

1. 打开冲突文件，找到冲突标记：
   ```text
   <<<<<<< HEAD
   你的代码
   =======
   upstream 的代码
   >>>>>>> upstream/main
   ```
2. 手动修改，保留需要的内容，删除 `<<<<<<<`、`=======`、`>>>>>>>` 标记。
3. 标记已解决并提交：
   ```bash
   git add 冲突文件
   git commit
   ```
4. 推送：
   ```bash
   git push origin main
   ```

如果合并到一半想放弃：

```bash
git merge --abort
```

---

## 7. 一个常见坑：本地有未提交的改动

同步前如果本地有改了一半的代码，git 会拒绝合并。两个办法：

- **暂存起来**（推荐）：
  ```bash
  git stash
  # 同步完成后恢复
  git stash pop
  ```
- **先提交到一个临时分支**：
  ```bash
  git checkout -b my-feature
  git add . && git commit -m "wip"
  git checkout main
  # 同步完成后
  git checkout my-feature
  git rebase main   # 把你的改动放到最新代码之上
  ```

---

## 8. 如果你在 fork 上做了自定义修改

fork 后如果直接改代码，每次同步 upstream 都可能冲突。推荐的工作流：

1. **不要直接在 `main` 上改**。
2. 新建自己的开发分支：
   ```bash
   git checkout -b my-custom main
   ```
3. `main` 分支**只用来跟 upstream 保持一致**，不直接动它。
4. 需要 upstream 新功能时，先同步 `main`，再合并到你的分支：
   ```bash
   git checkout main
   git fetch upstream && git merge upstream/main
   git push origin main
   git checkout my-custom
   git rebase main      # 或 git merge main
   ```

这样冲突只集中在你自己的分支上，`main` 永远干净。

---

## 9. 在 GitHub 网页上一键同步（最简单）

如果不想敲命令，GitHub 网页也支持：

1. 打开你 fork 的仓库页面。
2. 如果落后于父项目，`Code` 按钮下方会有 **Sync fork** 按钮。
3. 点击 → **Update branch** → 自动创建一个 PR 或直接合并。

> 限制：如果有冲突，网页同步会失败，还是得用命令行解决。

---

## 10. 速查表

```bash
# 查看
git remote -v

# 添加 upstream（只需一次）
git remote add upstream <父项目地址>

# 同步三连
git fetch upstream
git merge upstream/main
git push origin main

# 干净历史版（rebase）
git fetch upstream
git rebase upstream/main
git push origin main --force-with-lease

# 出错回退
git merge --abort
```

---

## 附：upstream 地址填错了怎么改

```bash
# 修改地址
git remote set-url upstream https://新的地址.git

# 删除重新加
git remote remove upstream
git remote add upstream https://新地址.git
```
