# Git Submodule 使用指南

> 系统学习入口：[Git 系统学习 · 课程大纲](00-课程大纲.md)

> 场景：一个 Git 仓库需要引用另一个独立 Git 仓库的代码，并且希望明确锁定被引用仓库的版本。

---

## 1. Submodule 是什么

Git Submodule（子模块）允许你把一个 Git 仓库挂到另一个 Git 仓库的某个目录下。

主仓库不会直接保存子模块的完整代码内容，而是保存两类信息：

| 内容 | 说明 |
|------|------|
| `.gitmodules` | 记录子模块路径和远程仓库地址 |
| 子模块提交指针 | 记录当前主仓库使用子模块的哪个 commit |

可以理解为：**主仓库只记录“这个目录来自哪个仓库，并固定在该仓库的哪个提交”**。

例如：

```text
main-project/
├── .gitmodules
├── app/
└── libs/common-sdk/     # 一个独立 Git 仓库，被作为 submodule 引入
```

---

## 2. 适合使用 Submodule 的场景

### 2.1 多项目复用同一份代码

例如多个业务系统都依赖同一个公共 SDK：

```text
vehicle-platform/
ops-platform/
admin-platform/
```

这些项目都需要引用：

```text
common-sdk/
```

如果公共 SDK 本身需要独立版本管理、独立发版、独立权限控制，可以考虑使用 submodule。

### 2.2 主项目需要锁定依赖源码版本

有些场景下不能只依赖包管理器版本号，而是希望主项目明确绑定依赖仓库的某个 commit。

典型情况：

- 引用内部算法库源码
- 引用第三方项目源码并做审计
- 引用可独立构建的插件仓库
- 引用部署脚本、基础设施模板、文档仓库

Submodule 的好处是：主仓库每次提交都会记录子模块的精确 commit，方便复现。

### 2.3 子项目需要保持独立仓库身份

如果某个模块需要：

- 独立 Issue / PR
- 独立 CI
- 独立权限
- 独立发布节奏
- 被多个上层项目引用

它更适合作为独立仓库，再由主项目通过 submodule 引入。

### 2.4 固定第三方源码

例如主项目需要依赖某个开源项目的一部分源码，又不希望直接复制代码：

```bash
git submodule add https://github.com/example/open-lib.git third_party/open-lib
```

这样能清楚看到第三方源码来源，也方便后续同步上游更新。

---

## 3. 不适合使用 Submodule 的场景

Submodule 有使用成本，不是所有代码复用都适合。

| 场景 | 更推荐的方式 |
|------|--------------|
| Java 公共库 | 发布到 Maven 私服 |
| Node 公共库 | 发布到 npm / 私有 npm |
| Python 公共库 | 发布到 PyPI / 私有源 |
| 只是想拆目录 | Monorepo |
| 主项目和子项目强耦合、总是一起改 | 放在同一个仓库 |
| 团队不熟悉 Git 子模块 | 优先用包管理器或直接合并代码 |

如果公共代码本质上是一个“依赖包”，优先考虑包管理器；如果多个模块需要一起开发、一起提交、一起发版，优先考虑 monorepo。

---

## 4. 添加 Submodule

### 4.1 添加子模块

在主仓库根目录执行：

```bash
git submodule add <子模块仓库地址> <本地路径>
```

示例：

```bash
git submodule add git@github.com:company/common-sdk.git libs/common-sdk
```

执行后会出现：

```text
.gitmodules
libs/common-sdk/
```

`.gitmodules` 内容大概如下：

```ini
[submodule "libs/common-sdk"]
	path = libs/common-sdk
	url = git@github.com:company/common-sdk.git
```

### 4.2 提交主仓库变更

添加 submodule 后，需要提交主仓库里的 `.gitmodules` 和子模块指针：

```bash
git status
git add .gitmodules libs/common-sdk
git commit -m "add common-sdk submodule"
```

注意：这里提交的 `libs/common-sdk` 不是普通目录内容，而是一个指向子模块 commit 的引用。

---

## 5. 克隆带 Submodule 的项目

### 5.1 推荐方式：递归克隆

```bash
git clone --recurse-submodules <主仓库地址>
```

这样会同时拉取主仓库和所有子模块。

### 5.2 已经普通 clone 了怎么办

如果已经执行过普通克隆：

```bash
git clone <主仓库地址>
```

进入项目后再初始化子模块：

```bash
git submodule update --init --recursive
```

参数说明：

| 参数 | 说明 |
|------|------|
| `--init` | 根据 `.gitmodules` 初始化本地子模块配置 |
| `--recursive` | 如果子模块里面还有子模块，继续递归拉取 |

---

## 6. 更新 Submodule

Submodule 的更新分两种：一种是“按主仓库记录的 commit 更新”，一种是“主动把子模块升级到新 commit”。

### 6.1 更新到主仓库记录的版本

多人协作时，别人提交了新的子模块指针，你拉取主仓库后需要同步子模块：

```bash
git pull
git submodule update --init --recursive
```

这个命令会让本地子模块回到主仓库当前记录的 commit。

### 6.2 主动升级子模块到最新代码

进入子模块目录：

```bash
cd libs/common-sdk
git checkout main
git pull origin main
```

回到主仓库：

```bash
cd ../..
git status
git add libs/common-sdk
git commit -m "update common-sdk submodule"
```

重点：**子模块升级后，主仓库必须提交新的子模块指针**。否则别人拉主仓库时不会知道你升级了子模块版本。

### 6.3 一次性更新所有子模块到远端最新分支

```bash
git submodule update --remote --merge
```

这个命令会按 `.gitmodules` 中配置的分支更新子模块。

如果想指定子模块跟踪分支：

```bash
git config -f .gitmodules submodule.libs/common-sdk.branch main
git add .gitmodules
git commit -m "track main branch for common-sdk submodule"
```

---

## 7. 在 Submodule 中开发代码

Submodule 本质上仍然是一个独立 Git 仓库，所以修改子模块代码时需要提交两次：

1. 在子模块仓库提交代码。
2. 在主仓库提交子模块指针变更。

示例：

```bash
# 进入子模块
cd libs/common-sdk

# 正常开发、提交、推送
git checkout -b feature/add-helper
git add .
git commit -m "add helper"
git push origin feature/add-helper
```

子模块代码合并后，切到目标分支并拉取：

```bash
git checkout main
git pull origin main
```

回到主仓库提交指针：

```bash
cd ../..
git add libs/common-sdk
git commit -m "update common-sdk pointer"
git push
```

---

## 8. 常用命令速查

```bash
# 添加子模块
git submodule add <repo-url> <path>

# 克隆时带上子模块
git clone --recurse-submodules <repo-url>

# 初始化并拉取子模块
git submodule update --init --recursive

# 查看子模块状态
git submodule status

# 更新到主仓库记录的子模块 commit
git submodule update --recursive

# 拉取所有子模块远端最新代码
git submodule update --remote --merge

# 对所有子模块执行命令
git submodule foreach 'git status'
git submodule foreach 'git checkout main && git pull'

# 同步 .gitmodules 中的 URL 到本地配置
git submodule sync --recursive
```

---

## 9. 常见问题

### 9.1 克隆后子模块目录是空的

原因：普通 `git clone` 不会自动拉取 submodule 内容。

解决：

```bash
git submodule update --init --recursive
```

### 9.2 子模块处于 detached HEAD 状态

这是正常现象。Submodule 默认会检出主仓库记录的具体 commit，而不是某个分支。

如果要在子模块里开发，需要手动切分支：

```bash
cd libs/common-sdk
git checkout main
```

或者新建开发分支：

```bash
git checkout -b feature/xxx
```

### 9.3 主仓库显示子模块 modified

查看状态：

```bash
git status
```

可能原因：

| 状态 | 含义 | 处理方式 |
|------|------|----------|
| `new commits` | 子模块当前 commit 和主仓库记录的不一致 | 确认是否需要提交主仓库指针 |
| `modified content` | 子模块内部有未提交改动 | 进入子模块提交或还原 |
| `untracked content` | 子模块内部有未跟踪文件 | 进入子模块处理未跟踪文件 |

### 9.4 子模块地址变了

修改 `.gitmodules`：

```bash
git config -f .gitmodules submodule.libs/common-sdk.url git@github.com:company/new-common-sdk.git
git add .gitmodules
git commit -m "update common-sdk submodule url"
```

同步到本地配置：

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

### 9.5 删除 Submodule

现代 Git 可以直接使用：

```bash
git submodule deinit -f libs/common-sdk
git rm -f libs/common-sdk
rm -rf .git/modules/libs/common-sdk
git commit -m "remove common-sdk submodule"
```

注意检查 `.gitmodules` 是否已经移除对应条目：

```bash
git config -f .gitmodules --list
```

---

## 10. 团队协作建议

### 10.1 明确谁负责升级子模块

不要让每个人都随手升级 submodule 指针。推荐约定：

- 子模块由固定负责人维护。
- 升级子模块需要单独提交或单独 PR。
- 主仓库升级前确认子模块变更内容和兼容性。

### 10.2 主仓库提交信息写清楚

不推荐：

```text
update
```

推荐：

```text
update common-sdk submodule to support vehicle tag sync
```

### 10.3 CI 需要拉取 Submodule

CI/CD 脚本里要确保拉取子模块：

```bash
git submodule update --init --recursive
```

GitHub Actions 示例：

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

### 10.4 权限要提前确认

主仓库有权限不代表子模块仓库也有权限。常见问题：

- 本地 clone 主仓库成功，但 submodule 拉取失败。
- CI 机器没有子模块仓库访问权限。
- 子模块使用 SSH 地址，机器没有配置对应 deploy key。

团队使用时要统一 HTTPS / SSH 方式，并确保开发机和 CI 都能访问。

---

## 11. Submodule、Monorepo、包管理器怎么选

| 方案 | 适合场景 | 优点 | 缺点 |
|------|----------|------|------|
| Submodule | 独立仓库源码依赖，需要锁定 commit | 版本可复现，仓库边界清晰 | 学习成本高，容易忘记初始化/更新 |
| Monorepo | 多模块强关联，经常一起改 | 协作简单，统一构建和重构方便 | 仓库可能变大，权限边界较弱 |
| 包管理器 | 标准库依赖、公共组件、SDK | 使用简单，版本语义清晰 | 调试源码和本地联调相对麻烦 |
| 复制代码 | 临时引入、小范围一次性使用 | 最简单 | 后续同步困难，来源不清晰 |

简单判断：

- 需要独立仓库、独立权限、固定源码 commit：选 **Submodule**。
- 代码总是一起开发、一起发布：选 **Monorepo**。
- 代码是标准依赖库：选 **包管理器**。
- 只是临时参考或一次性使用：可以复制，但要注明来源。

---

## 12. 推荐工作流

### 新人首次拉项目

```bash
git clone --recurse-submodules <主仓库地址>
```

如果已经 clone：

```bash
git submodule update --init --recursive
```

### 日常拉取主仓库更新

```bash
git pull
git submodule update --init --recursive
```

### 升级某个子模块

```bash
cd libs/common-sdk
git checkout main
git pull origin main

cd ../..
git add libs/common-sdk
git commit -m "update common-sdk submodule"
git push
```

### 修改子模块代码

```bash
cd libs/common-sdk
git checkout -b feature/xxx
git add .
git commit -m "xxx"
git push origin feature/xxx

# 子模块分支合并后，回主仓库提交新指针
cd ../..
git add libs/common-sdk
git commit -m "update common-sdk pointer"
git push
```

---

## 13. 一句话总结

Git Submodule 适合把“需要独立维护的 Git 仓库”作为主项目的一部分引入，并让主项目精确记录它使用的 commit。

它的核心价值是：**边界清晰、版本可复现**。

它的核心成本是：**团队必须理解子模块指针、初始化、更新和权限配置**。
