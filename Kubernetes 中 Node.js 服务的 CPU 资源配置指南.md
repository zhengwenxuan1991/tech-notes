---
title: Kubernetes 中 Node.js 服务的 CPU 资源配置指南
date: 2026-08-24
tags:
  - nodejs
  - kubernetes
  - k8s
  - 性能优化
aliases:
  - Node.js K8s CPU 配置
---

# Kubernetes 中 Node.js 服务的 CPU 资源配置指南

> [!abstract] 核心结论
> 对于普通 Node.js Web 服务，建议采用“**一个 Node.js 进程对应一个 Pod，每个 Pod 从 500m～1 Core 起步，通过增加 Pod 数量横向扩容**”的方式。最终配置应以压测和生产监控数据为准。

## Node.js 的线程模型

Node.js 不能简单地归类为单线程或多线程，其运行模型可以概括为：

> JavaScript 单线程执行 + Event Loop 调度 + 底层多线程协作。

- **JavaScript 默认单线程执行**：业务代码主要在一个主线程中运行，由事件循环依次调度。
- **底层并非单线程**：libuv 线程池可处理文件 I/O、部分 DNS、加密等任务。
- **支持显式并行**：可通过 `worker_threads`、`cluster` 或子进程使用多个 CPU 核心。

因此，普通 Node.js 服务即使被分配多个 CPU Core，JavaScript 主线程通常也不能自动利用所有核心。多核并行需要应用主动创建 Worker 或多个进程。

## K8s 中 CPU 配置的含义

Kubernetes 使用 Core 或 millicpu（`m`）表示 CPU：

- `1000m` 等于 `1 Core`。
- `500m` 等于 `0.5 Core`。
- `100m` 等于 `0.1 Core`。

资源配置中，`requests` 和 `limits` 的作用不同：

| 配置项 | 作用 |
|---|---|
| `requests.cpu` | Pod 调度时预留的 CPU 资源，也是 CPU 竞争时的权重依据 |
| `limits.cpu` | 容器可以使用的 CPU 硬上限，超过后会受到 CPU throttling |

> [!warning] 注意
> 分配 `1 Core` 不代表 Pod 独占一个物理核心。CPU request 主要用于调度和资源竞争；CPU limit 是容器可获得 CPU 时间的上限。

## 推荐配置

### 普通 Web/API 服务

普通 API 服务通常以数据库、Redis、RPC 或其他网络 I/O 为主，建议从以下配置开始：

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

对应的资源建议如下：

| 场景 | CPU request | CPU limit | 扩容方式 |
|---|---:|---:|---|
| 低流量 API、I/O 密集型服务 | `250m` | `500m～1` | 增加 Pod |
| 常规生产 API 服务 | `500m` | `1` | 增加 Pod |
| JSON 处理较多或单请求计算偏重 | `500m～1` | `1～1.5` | 压测后增加 Pod |
| 图片、压缩、加密或复杂计算 | 按 Worker 数量估算 | 按压测结果设置 | Worker + Pod 扩容 |
| Pod 内运行 4 个 cluster worker | `4` 左右 | `4～5` | 一般优先拆成多个 Pod |

### 使用 Worker 或 Cluster 的服务

如果应用使用 `worker_threads` 或 `cluster` 执行 CPU 密集型任务，可以按“**一个持续繁忙的 JavaScript Worker 约对应一个 Core**”进行初始估算，并为主线程和系统开销预留余量。

例如，Pod 内运行 2 个 CPU 密集型 Worker 时，可以从 `2～2.5 Core` 开始压测。

不过，对于无状态 Web 服务，更推荐让每个 Pod 只运行一个 Node.js 进程，由 Kubernetes 负责副本调度、故障恢复和负载均衡。这样资源隔离和扩缩容通常更简单。

## 推荐部署方式

```text
单个 Node.js 进程
        ↓
每个 Pod 配置约 500m～1 Core
        ↓
生产环境至少部署 2 个副本
        ↓
使用 HPA 按 CPU 或业务指标横向扩容
```

Deployment 资源配置示例：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: node-api
  template:
    metadata:
      labels:
        app: node-api
    spec:
      containers:
        - name: node-api
          image: example/node-api:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1"
              memory: "1Gi"
```

## HPA 配置示例

建议生产环境至少部署 2 个副本，并使用 Horizontal Pod Autoscaler 自动扩容：

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: node-api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: node-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65
```

HPA 的 CPU 利用率以 `requests.cpu` 为基准。例如：

- `requests.cpu` 为 `500m`；
- Pod 当前使用 `325m`；
- HPA 观察到的 CPU 利用率约为 `65%`。

因此，`requests.cpu` 应根据服务的稳定负载合理设置。设置过低可能导致频繁扩容，设置过高则可能导致扩容不及时和集群资源浪费。

## 如何确定最终 Core 数量

初始配置只是基线，生产配置应通过压测和监控逐步校准，重点观察：

- CPU 平均值、P95 和峰值使用率；
- CPU throttling 时间和比例；
- 接口 P95、P99 响应时间；
- Node.js Event Loop Lag；
- 吞吐量（QPS）和错误率；
- Pod 扩容频率和扩容后的负载分布；
- 内存使用量和 OOM 情况。

可以按照以下原则调整：

1. 单 Pod CPU 长期较低时，适当降低 `requests.cpu`，提高集群利用率。
2. 单 Pod 接近 `1 Core` 后延迟明显上升时，优先增加 Pod，而不是继续给单进程增加 Core。
3. CPU throttling 明显且接口延迟同步上升时，适当提高 CPU limit，或重新评估是否需要设置 CPU limit。
4. CPU 不高但 Event Loop Lag 较大时，排查同步计算、超大 JSON、正则表达式、序列化等阻塞主线程的逻辑。
5. CPU 密集型任务无法拆分时，使用 Worker，并根据 Worker 数量增加 CPU 配额。

> [!tip] 建议
> 对大多数无状态 Node.js API 服务，可先使用 `requests.cpu: 500m`、`limits.cpu: 1`、`replicas: 2` 和 HPA 65% 作为起始配置，再通过压测确定最终值。

## 参考资料

- [Node.js Cluster 官方文档](https://nodejs.org/api/cluster.html)
- [Node.js Worker Threads 官方文档](https://nodejs.org/api/worker_threads.html)
- [Kubernetes Pod 和容器资源管理](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)

