# pip 和 pip3 的区别

## 核心区别

| 命令     | 说明                                |
| ------ | --------------------------------- |
| `pip`  | 默认的 Python 包管理器，指向系统默认的 Python 版本 |
| `pip3` | **明确指定** Python 3 的包管理器           |

## 具体行为取决于系统环境

**情况 1：只安装了 Python 3**
- `pip` 和 `pip3` 指向同一个程序，功能完全一样

**情况 2：同时安装了 Python 2 和 Python 3**
- `pip` → Python 2 的包管理器
- `pip3` → Python 3 的包管理器

**情况 3：有多个 Python 3 版本**
- `pip3` → 默认的 Python 3.x
- `pip3.9`、`pip3.11` → 特定版本

## 推荐做法

```bash
# 查看当前 pip 对应的 Python 版本
pip --version
pip3 --version

# 最推荐：使用 python -m pip，明确指定解释器
python3 -m pip install package_name
```

使用 `python3 -m pip` 可以**确保包安装到指定的 Python 环境中**，避免因 pip 指向不明导致的混乱。

---

## macOS 上 pip 命令找不到的问题

### 原因分析

在 macOS 上：

1. **Python 2 已被弃用** — 现代系统不再预装 Python 2
2. **pip3 才是标准** — 通过 Homebrew 或官方安装的 Python 3 只提供 `pip3` 命令
3. **pip 命令不存在** — 因为没有 Python 2，所以不会创建 `pip` 这个别名

### 验证

```bash
# 这个应该正常工作
pip3 --version

# 这个找不到是正常的
pip --version
```

### 解决方案

**方案 1：直接使用 pip3（推荐）**
```bash
pip3 install package_name
```

**方案 2：创建别名**

在 `~/.zshrc` 中添加：
```bash
alias pip='pip3'
```

然后执行：
```bash
source ~/.zshrc
```

**方案 3：使用 python -m pip（最可靠）**
```bash
python3 -m pip install package_name
```

### 总结

| 命令 | 状态 |
|------|------|
| `pip` | ❌ 不存在（无 Python 2） |
| `pip3` | ✅ 正常使用 |
| `python3 -m pip` | ✅ 推荐方式 |

> 直接用 `pip3` 就好，不需要纠结 `pip` 命令。
