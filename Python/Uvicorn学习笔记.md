# Uvicorn 学习笔记

## 1. 什么是 Uvicorn

**Uvicorn** 是一个用于 Python 的**高性能 ASGI（Asynchronous Server Gateway Interface）Web 服务器**，基于 uvloop 和 httptools 构建，使用 asyncio 实现异步 I/O。

它通常用于运行基于 ASGI 框架（如 FastAPI、Starlette、Django Channels、Quart 等）构建的异步 Web 应用。

## 2. 核心特点

- **极速**：基于 `uvloop`（Cython 实现的事件循环）和 `httptools`（C 语言实现的 HTTP 解析器），性能接近 Node.js 和 Go。
- **ASGI 兼容**：完整支持 ASGI 2 和 ASGI 3 规范。
- **HTTP/1.1 与 WebSocket**：原生支持 HTTP/1.1 和 WebSocket。
- **生产级支持**：支持通过 Gunicorn 作为工作进程（worker）运行，实现多进程部署。
- **热重载**：开发模式下可自动检测代码变更并重载（`--reload`）。

## 3. 安装

```bash
# 基础安装
pip3 install uvicorn

# 包含标准依赖（推荐）
pip3 install "uvicorn[standard]"
```

`[standard]` 会安装 `uvloop`、`httptools`、`websockets` 等性能依赖。如果安装失败，Uvicorn 会降级使用纯 Python 实现。

## 4. 基本使用

假设有一个 ASGI 应用文件 `main.py`：

```python
async def app(scope, receive, send):
    assert scope["type"] == "http"
    await send({
        "type": "http.response.start",
        "status": 200,
        "headers": [[b"content-type", b"text/plain"]],
    })
    await send({
        "type": "http.response.body",
        "body": b"Hello, Uvicorn!",
    })
```

### 4.1 命令行启动

```bash
# 基本启动
uvicorn main:app

# 指定主机和端口
uvicorn main:app --host 0.0.0.0 --port 8080

# 开发模式：启用热重载
uvicorn main:app --reload
```

> `main:app` 表示从 `main.py` 文件中加载名为 `app` 的 ASGI 应用对象。

### 4.2 常用命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--host` | 监听主机 | `127.0.0.1` |
| `--port` | 监听端口 | `8000` |
| `--reload` | 开发热重载 | `False` |
| `--workers` | 工作进程数 | `1` |
| `--log-level` | 日志级别 | `info` |
| `--access-log` | 是否记录访问日志 | `True` |
| `--timeout-keep-alive` | 长连接保持时间（秒） | `5` |
| `--loop` | 事件循环实现 | `auto` |
| `--http` | HTTP 协议实现 | `auto` |
| `--ws` | WebSocket 实现 | `auto` |

## 5. 编程式启动

```python
import uvicorn

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
```

常用配置项：

```python
uvicorn.run(
    app,
    host="0.0.0.0",
    port=8000,
    log_level="info",
    access_log=True,
    workers=4,
    timeout_keep_alive=5,
)
```

## 6. 与 FastAPI 配合使用

FastAPI 应用本身就是 ASGI 应用，可以直接用 Uvicorn 运行：

```python
# main.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```

```bash
uvicorn main:app --reload
```

## 7. 生产环境部署

### 7.1 使用 Gunicorn + Uvicorn Worker

对于生产环境，推荐通过 Gunicorn 启动多个 Uvicorn 工作进程，以利用多核 CPU：

```bash
pip3 install gunicorn

gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
```

| 参数 | 说明 |
|------|------|
| `-w 4` | 4 个工作进程 |
| `-k uvicorn.workers.UvicornWorker` | 使用 Uvicorn worker 类 |

### 7.2 使用 Uvicorn 官方 Worker 类

- `uvicorn.workers.UvicornWorker`：标准 worker，使用 C 扩展。
- `uvicorn.workers.UvicornH11Worker`：纯 Python 实现，兼容性更好。

## 8. 事件循环与协议实现

Uvicorn 支持选择不同的事件循环和协议实现：

```bash
# 强制使用 uvloop
uvicorn main:app --loop uvloop

# 使用 h11 代替 httptools（纯 Python）
uvicorn main:app --http h11

# 使用 websockets 库
uvicorn main:app --ws websockets
```

| 选项 | 可用值 |
|------|--------|
| `--loop` | `auto`, `asyncio`, `uvloop` |
| `--http` | `auto`, `h11`, `httptools` |
| `--ws` | `auto`, `none`, `websockets`, `wsproto` |

## 9. 日志配置

可以通过 `--log-config` 参数指定日志配置文件（JSON 或 YAML 格式）：

```bash
uvicorn main:app --log-config log_config.yaml
```

示例 `log_config.yaml`：

```yaml
version: 1
disable_existing_loggers: False
formatters:
  default:
    format: '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
handlers:
  default:
    formatter: default
    class: logging.StreamHandler
    stream: ext://sys.stdout
loggers:
  uvicorn:
    level: INFO
    handlers: [default]
  uvicorn.error:
    level: INFO
  uvicorn.access:
    level: INFO
    handlers: [default]
```

## 10. 典型示例

### 10.1 运行 FastAPI 应用

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 10.2 生产环境运行

```bash
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000
```

### 10.3 编程式运行

```python
import uvicorn
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"msg": "hello"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## 11. 注意事项

1. **开发环境**使用 `--reload` 方便调试，但**生产环境不要开启**，因为热重载会消耗额外资源并可能带来稳定性问题。
2. **单进程模式**适合开发，生产环境建议配合 **Gunicorn** 使用多进程。
3. 如果安装 `[standard]` 失败，Uvicorn 可以降级运行，但性能会下降。
4. Uvicorn 主要支持 HTTP/1.1 和 WebSocket，**HTTP/2 需要借助 Hypercorn 等服务器**。

## 12. 参考链接

- [Uvicorn 官方文档](https://www.uvicorn.org/)
- [ASGI 规范](https://asgi.readthedocs.io/)
- [FastAPI 官方文档](https://fastapi.tiangolo.com/)
