# kubectl 日志过滤命令

> 场景：实时跟踪 Pod 日志，只关注关心的错误关键字，避免被健康检查、心跳等噪音日志刷屏。

## 基础命令

实时跟踪日志并过滤多个关键字（**任一命中即显示**）：

```bash
kubectl logs -f <pod-name> -n <namespace> | grep --line-buffered -E '视频文件不存在或为空|FTP文件删除失败|处理记录异常'
```

## 命令解析

| 片段 | 说明 |
|------|------|
| `kubectl logs -f` | 实时跟踪日志输出（类似 `tail -f`） |
| `<pod-name>` / `-n <namespace>` | 目标 Pod 名称与命名空间 |
| `grep -E` | 使用扩展正则表达式，`\|` 表示“或”，匹配多个关键字中的任意一个 |
| `--line-buffered` | 行缓冲输出。不加时管道会积压缓冲区，`-f` 模式下匹配日志无法实时打印 |
| 单引号内关键字 | `视频文件不存在或为空`、`FTP文件删除失败`、`处理记录异常`，任一条日志包含其中一个即显示 |

## 关键字说明

| 关键字 | 用途 |
|--------|------|
| `视频文件不存在或为空` | 视频文件缺失/为空类异常 |
| `FTP文件删除失败` | FTP 删除文件失败类异常 |
| `处理记录异常` | 业务处理记录异常类日志 |

## 常用变体

### 只看最近 N 行再过滤

```bash
kubectl logs --tail=500 -f <pod-name> -n <namespace> | grep --line-buffered -E '视频文件不存在或为空|FTP文件删除失败|处理记录异常'
```

### 多个 Pod 一起过滤（按标签选择）

```bash
kubectl logs -f -l app=<app-name> -n <namespace> | grep --line-buffered -E '视频文件不存在或为空|FTP文件删除失败|处理记录异常'
```

### 带时间戳

```bash
kubectl logs -f --timestamps <pod-name> -n <namespace> | grep --line-buffered -E '视频文件不存在或为空|FTP文件删除失败|处理记录异常'
```

## 相关文档

- K8s 常用命令：K8s 常规运维命令汇总（重启、扩缩容、日志排除等）
- 查看 Job 日志：Job 名 vs Pod 名、`-f` 失效、BackoffLimitExceeded
