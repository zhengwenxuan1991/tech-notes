# Miniconda 安装使用指南

## 简介

Miniconda 是 Anaconda 的精简版本，提供了 conda 包管理器和 Python 环境。相比 Anaconda，它更轻量，只包含最基本的组件。

## 安装步骤

### macOS (使用 Homebrew)

```bash
# 安装 miniconda
brew install --cask miniconda
```

### 初始化 conda

安装完成后，需要初始化 conda 以便在终端中使用：

```bash
# 初始化 conda（根据你的 shell 选择）
conda init zsh      # 如果使用 zsh
conda init bash     # 如果使用 bash

# 重新加载 shell 配置
source ~/.zshrc     # zsh
source ~/.bashrc    # bash
```

### 验证安装

```bash
conda --version
conda info
```

## 常用命令

### 环境管理

```bash
# 创建新环境（指定 Python 版本）
conda create -n 环境名 python=3.9

# 创建环境时同时安装包
conda create -n 环境名 python=3.9 numpy pandas

# 激活环境
conda activate 环境名

# 退出当前环境
conda deactivate

# 列出所有环境
conda env list
conda info --envs

# 删除环境
conda remove -n 环境名 --all

# 克隆环境
conda create -n 新环境名 --clone 原环境名
```

### 包管理

```bash
# 安装包
conda install 包名
conda install 包名=版本号

# 从指定渠道安装
conda install -c 渠道名 包名

# 卸载包
conda remove 包名

# 更新包
conda update 包名

# 更新 conda 自身
conda update conda

# 更新所有包
conda update --all

# 列出已安装的包
conda list

# 搜索包
conda search 包名
```

### 使用 pip

在 conda 环境中也可以使用 pip：

```bash
# 激活环境后
conda activate 环境名

# 使用 pip 安装
pip install 包名

# 从 requirements.txt 安装
pip install -r requirements.txt
```

### 导出和导入环境

```bash
# 导出环境配置
conda env export > environment.yml

# 从配置文件创建环境
conda env create -f environment.yml
```

## 项目实践示例

### 创建 mqtt-proxy 项目环境

```bash
# 创建 Python 3.9 环境
conda create -n mqtt-proxy python=3.9

# 激活环境
conda activate mqtt-proxy

# 进入项目目录
cd /path/to/mqtt-proxy

# 安装项目依赖
pip install -r requirements.txt

# 启动项目
PYTHONPATH=/path/to/mqtt-proxy:/path/to/mqtt-proxy/src python3 src/main.py -c ./deploy/default.yaml -s bridge
```

## 配置优化

### 配置国内镜像源

加速包下载：

```bash
# 配置清华镜像
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
conda config --set show_channel_urls yes
```

或编辑 `~/.condarc`：

```yaml
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - defaults
show_channel_urls: true
```

### pip 国内镜像

```bash
# 临时使用
pip install 包名 -i https://pypi.tuna.tsinghua.edu.cn/simple

# 永久配置
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

## 清理空间

```bash
# 清理缓存
conda clean --all

# 查看缓存占用
du -sh ~/miniconda3/pkgs
```

## 常见问题

### conda 命令找不到

确保已执行 `conda init` 并重启终端。

### 环境激活失败

```bash
# 重新初始化
conda init zsh
source ~/.zshrc
```

### 包版本冲突

```bash
# 创建新环境解决冲突
conda create -n 新环境 python=3.9
conda activate 新环境
pip install -r requirements.txt
```

## 参考链接

- [Miniconda 官方文档](https://docs.conda.io/en/latest/miniconda.html)
- [Conda 用户指南](https://docs.conda.io/projects/conda/en/latest/user-guide/index.html)
- [清华开源镜像站](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/)