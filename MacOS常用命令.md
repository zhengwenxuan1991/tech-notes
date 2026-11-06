# Mac OS 常用命令

## 1. 环境变量管理

### 查看环境变量
```bash
# 查看所有环境变量
env

# 查看特定环境变量
echo $PATH

# 查看某个变量的值
printenv PATH
```

### 修改环境变量
```bash
# 临时设置（当前会话有效）
export PATH=$PATH:/usr/local/bin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_281.jdk/Contents/Home

# 永久设置（修改配置文件）
# zsh (macOS Catalina 及之后默认)
nano ~/.zshrc

# bash (旧版本 macOS)
nano ~/.bash_profile
```

### 配置文件位置
- **zsh**: `~/.zshrc`
- **bash**: `~/.bash_profile` 或 `~/.bashrc`
- **全局配置**: `/etc/paths`, `/etc/profile`, `/etc/bashrc`, `/etc/zshrc`

### 配置文件示例
```bash
# ~/.zshrc 示例
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home
export M2_HOME=/usr/local/apache-maven-3.8.6
export PATH=$PATH:$M2_HOME/bin

# 生效配置
source ~/.zshrc
```

---

## 2. Hosts 文件修改

### Hosts 文件位置
```bash
# Hosts 文件位于
/etc/hosts
```

### 修改步骤
```bash
# 1. 使用管理员权限编辑 hosts 文件
sudo nano /etc/hosts

# 或使用 vim
sudo vim /etc/hosts

# 2. 修改完成后保存退出
# nano: Ctrl+O 保存, Ctrl+X 退出
# vim: :wq 保存并退出

# 3. 刷新 DNS 缓存
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### Hosts 文件格式示例
```
# Host Database
# localhost is used to configure the loopback interface
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost

# 自定义映射示例
127.0.0.1       myproject.local
192.0.2.10   server.local
```

### DNS 缓存清理
```bash
# macOS Ventura 及之后
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# macOS Big Sur/Monterey
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

# 旧版本
sudo killall -HUP mDNSResponder
sudo discoveryutil udnsflushcaches
```

---

## 3. 命令别名（Alias）

### 创建别名

#### 临时别名（当前会话）
```bash
alias ll='ls -alF'
alias gs='git status'
alias gp='git pull'
```

#### 永久别名（写入配置文件）
```bash
# 编辑配置文件
nano ~/.zshrc

# 添加别名到文件
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias c='clear'

# 生效配置
source ~/.zshrc
```

### 常用别名示例
```bash
# 目录导航
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd ~'

# Git 相关
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Docker 相关
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'

# 其他工具
alias h='history'
alias c='clear'
alias ports='netstat -tulanp'
alias mkdir='mkdir -pv'  # 创建目录时自动创建父目录
alias rm='rm -i'          # 删除前确认
alias cp='cp -i'          # 覆盖前确认
alias mv='mv -i'          # 移动前确认
```

### 函数别名（带参数）
```bash
# 添加到 ~/.zshrc
mkcd() {
    mkdir -p "$1"
    cd "$1"
}

extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) unrar x $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}
```

### 查看所有别名
```bash
alias
```

### 删除别名
```bash
unalias ll
```

---

## 4. 系统信息与监控

### 系统信息
```bash
# 查看系统版本
sw_vers

# 查看内核版本
uname -r

# 查看硬件信息
system_profiler SPHardwareDataType

# 查看处理器信息
sysctl -n machdep.cpu.brand_string

# 查看内存信息
system_profiler SPMemoryDataType

# 查看磁盘使用情况
df -h

# 查看目录大小
du -sh /path/to/directory

# 查看当前目录下各子目录大小
du -sh */ | sort -hr
```

### 进程管理
```bash
# 查看所有进程
ps aux

# 查找特定进程
ps aux | grep process_name

# 杀死进程
kill PID
kill -9 PID  # 强制杀死

# 按名称杀死进程
killall process_name

# 实时监控进程
top

# 实时监控（交互式更强）
htop  # 需要安装: brew install htop

# 查看端口占用
lsof -i :port
lsof -i :8080

# 查看所有网络连接
netstat -an

# 查看 PID 占用的端口
lsof -p PID
```

---

## 5. 文件操作

### 基本操作
```bash
# 查看文件（显示隐藏文件）
ls -la

# 查看详细文件信息
ls -lh

# 递归查看目录
ls -R

# 查找文件
find /path -name "filename"
find ~ -name "*.txt"

# 查找包含特定内容的文件
grep -r "search_text" /path

# 查看文件内容
cat file.txt
less file.txt  # 分页查看，q 退出

# 查看文件前/后 n 行
head -n 10 file.txt
tail -n 10 file.txt
tail -f file.txt  # 实时查看日志

# 复制文件
cp source.txt dest.txt
cp -r source_dir/ dest_dir/  # 递归复制目录

# 移动/重命名文件
mv old.txt new.txt
mv file.txt /path/to/dest/

# 删除文件
rm file.txt
rm -r directory/  # 删除目录
rm -rf directory/  # 强制删除目录（谨慎使用！）
```

### 权限管理
```bash
# 查看权限
ls -l

# 修改权限
chmod 755 file.sh
chmod +x script.sh

# 修改所有者
chown user:group file

# 递归修改目录权限
chmod -R 755 directory/
chown -R user:group directory/
```

---

## 6. Homebrew 包管理

### 基本命令
```bash
# 搜索包
brew search package_name

# 安装包
brew install package_name
brew install python
brew install git

# 查看已安装包
brew list

# 更新 Homebrew
brew update

# 更新所有已安装包
brew upgrade

# 更新特定包
brew upgrade package_name

# 卸载包
brew uninstall package_name

# 清理旧版本
brew cleanup

# 查看包信息
brew info package_name

# 查看 Homebrew 状态
brew doctor
```

### 常用 Homebrew Cask（图形应用）
```bash
# 搜索
brew search --cask app_name

# 安装应用
brew install --cask visual-studio-code
brew install --cask google-chrome
brew install --cask docker

# 查看已安装应用
brew list --cask
```

---

## 7. 网络相关

### 网络诊断
```bash
# Ping 测试
ping google.com

# 追踪路由
traceroute google.com

# DNS 查询
nslookup google.com
dig google.com

# 查看网络接口
ifconfig

# 测试端口连通性
nc -zv host port
nc -zv google.com 80

# 下载文件
curl -O https://example.com/file.zip
wget https://example.com/file.zip  # 需要安装 wget

# 查看 HTTP 头信息
curl -I https://example.com
```

### SSH 相关
```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -b 4096 -C "email@example.com"

# 启动 SSH 服务
sudo systemsetup -setremotelogin on

# 停止 SSH 服务
sudo systemsetup -setremotelogin off

# 查看 SSH 状态
sudo systemsetup -getremotelogin

# SSH 连接
ssh user@hostname
ssh -p port user@hostname

# 复制文件到远程服务器
scp file.txt user@remote:/path/

# 从远程服务器复制文件
scp user@remote:/path/file.txt .
```

---

## 8. 压缩与解压

```bash
# 压缩
zip -r archive.zip directory/
tar -czf archive.tar.gz directory/

# 解压 zip
unzip archive.zip

# 解压 tar.gz
tar -xzf archive.tar.gz

# 解压 tar.bz2
tar -xjf archive.tar.bz2

# 查看 tar 内容
tar -tzf archive.tar.gz
```

---

## 9. 其他实用命令

### 文本处理
```bash
# 统计行数
wc -l file.txt

# 查找替换
sed 's/old/new/g' file.txt

# 按行排序
sort file.txt

# 去重
sort file.txt | uniq

# 查看文件类型
file filename

# 比较文件差异
diff file1.txt file2.txt
```

### 时间日期
```bash
# 查看当前时间
date

# 格式化输出
date "+%Y-%m-%d %H:%M:%S"

# 日志时间戳
date +"%Y-%m-%d %T"
```

### 历史命令
```bash
# 查看历史
history

# 执行历史命令（按编号）
!100

# 执行上一个命令
!!

# 搜索历史命令（按 Ctrl+R 后输入）

# 清空历史
history -c
```

### 快捷键
```
Ctrl + C    # 中断当前命令
Ctrl + Z    # 暂停当前命令（fg 恢复）
Ctrl + D    # 退出当前 shell
Ctrl + L    # 清屏（相当于 clear）
Ctrl + A    # 光标移到行首
Ctrl + E    # 光标移到行尾
Ctrl + U    # 删除光标到行首
Ctrl + K    # 删除光标到行尾
!!          # 执行上一条命令
!$          # 上一条命令的最后一个参数
```

---

## 10. 常见问题解决

### Permission denied
```bash
# 使用 sudo 执行
sudo command

# 或修改权限
chmod +x script.sh
```

### Command not found
```bash
# 检查 PATH
echo $PATH

# 添加到 PATH
export PATH=$PATH:/new/path

# 或安装缺失的工具
brew install tool_name
```

### 查找命令位置
```bash
which command
whereis command
```

### 手动加载配置
```bash
# zsh
source ~/.zshrc

# bash
source ~/.bash_profile
```
