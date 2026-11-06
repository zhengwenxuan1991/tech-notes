# IDEA 使用技巧

## 查看代码行数（排除注释）

### 使用 Statistic 插件（推荐）

Statistic 插件可以精确统计代码行数，区分有效代码、注释和空行。

#### 安装插件

1. 打开 Preferences：`Cmd + ,`
2. 左侧选择 `Plugins` → `Marketplace`
3. 搜索 **"Statistic"**
4. 点击 `Install`，安装完成后重启 IDEA

#### 使用插件统计

1. 打开 Statistic 窗口：`View` → `Tool Windows` → `Statistic`
   - 或点击左侧边栏的 Statistic 图标
2. 选择统计范围：
   - `Project` - 整个项目
   - `Module` - 单个模块
   - `Directory` - 指定目录
3. 查看统计结果：

| 指标 | 说明 |
|------|------|
| **Source Code Lines** | 有效代码行（**不含注释和空行**） |
| Comment Lines | 注释行数 |
| Blank Lines | 空行数 |
| Total Lines | 总行数 |

> **提示**：点击表头可以按该列排序，方便找出代码量最大的文件。

---

### 统计单个文件的行数

#### 方法 1：使用 Statistic 插件

1. 打开 Statistic 窗口
2. 切换到 `File` 标签页
3. 在文件列表中找到目标文件（可使用搜索框）
4. 查看该文件的详细统计：
   - **Source Code Lines** - 有效代码行（不含注释）
   - **Comment Lines** - 注释行数
   - **Blank Lines** - 空行数

#### 方法 2：使用 IDEA 内置的 "Show Statistics"

**方式一：快捷键**
- `Cmd + Shift + A` → 输入 `Show Statistics` → 回车

**方式二：菜单栏**
- `View` → `Appearance` → `Status Bar` → 确保勾选
- 点击底部状态栏的 `行号:列号` 区域（如 `156:42`）
- 弹出窗口显示当前文件统计

**方式三：右键菜单**
- 在代码编辑区右键 → `Analyze` → `Show Statistics`

**方式四：顶部菜单**
- `Analyze` → `Show Statistics`（部分版本在 `Code` → `Analyze` 下）

> **注意**：如果菜单中没有该选项，可能是 IDEA 版本差异，建议使用 Statistic 插件或方式一的快捷键搜索。

#### 方法 3：使用终端命令（macOS）

```bash
# 统计总行数（含注释和空行）
wc -l /path/to/YourFile.java

# 统计有效代码行（排除空行和 // 注释）
cat /path/to/YourFile.java | \
  grep -v "^[[:space:]]*$" | \
  grep -v "^[[:space:]]*//" | \
  wc -l
```

> **注意**：终端命令无法完美排除 `/* */` 多行注释，如需精确统计建议使用 Statistic 插件。

