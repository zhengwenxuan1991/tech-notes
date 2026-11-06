# Apache Doris 表模型

Apache Doris 主要有以下几类"表模型（Table Model）"，这是 Doris 最核心的设计之一，不同模型决定了数据写入、更新、聚合、查询的行为。

---

## 1. DUPLICATE KEY（明细模型）

最常用，类似"Append Only"。

### 特点

- 不去重
- 不聚合
- 相同 Key 可以存在多行
- 写入性能最好

### 适合场景

- 明细日志
- IoT/车辆轨迹
- 埋点
- 行为数据

### 示例

```sql
CREATE TABLE vehicle_log (
    vehicle_id BIGINT,
    ts BIGINT,
    speed INT
)
DUPLICATE KEY(vehicle_id, ts)
DISTRIBUTED BY HASH(vehicle_id) BUCKETS 16;
```

**行为：** 插入 `(1,1000,60)` 和 `(1,1000,80)` 两条记录，最终两条都存在。

---

## 2. AGGREGATE KEY（聚合模型）

写入时自动聚合。

### 特点

- 相同 Key 自动聚合
- Value 列必须指定聚合函数

### 支持聚合函数

`SUM` | `MAX` | `MIN` | `REPLACE` | `HLL_UNION` | `BITMAP_UNION`

### 适合场景

- 报表
- 指标汇总
- OLAP Cube
- PV/UV/count/sum

### 示例

```sql
CREATE TABLE vehicle_stat (
    dt DATE,
    vehicle_id BIGINT,
    mileage BIGINT SUM
)
AGGREGATE KEY(dt, vehicle_id)
DISTRIBUTED BY HASH(vehicle_id) BUCKETS 16;
```

**行为：** 插入 `(2025-01-01,1,100)` 和 `(2025-01-01,1,200)`，查询结果为 `(2025-01-01,1,300)`。

---

## 3. UNIQUE KEY（主键模型）

用于"更新"场景。

### 特点

- Key 唯一
- 相同 Key 后写覆盖前写
- 支持 UPSERT

### 适合场景

- 用户状态
- 车辆最新状态
- 设备当前在线状态
- 维表

### 示例

```sql
CREATE TABLE vehicle_online (
    vehicle_id BIGINT,
    online_status TINYINT,
    update_time DATETIME
)
UNIQUE KEY(vehicle_id)
DISTRIBUTED BY HASH(vehicle_id) BUCKETS 16;
```

**行为：** 插入 `(1,1,10:00)` 后插入 `(1,0,10:05)`，最终结果为 `(1,0,10:05)`。

---

## 4. PRIMARY KEY（主键模型，新版）

Doris 新一代更新模型。

### 特点

相比 UNIQUE KEY：

- 更新效率更高
- 查询性能更强
- 支持部分列更新
- Merge-on-Write
- 更适合高频更新

### 适合场景

- 实时画像
- 实时状态
- 高并发 UPSERT
- 实时维表

### 示例

```sql
CREATE TABLE vehicle_state (
    vehicle_id BIGINT,
    speed INT,
    gps_time BIGINT
)
PRIMARY KEY(vehicle_id)
DISTRIBUTED BY HASH(vehicle_id) BUCKETS 16;
```

---

## 5. UNIQUE KEY vs PRIMARY KEY 对比

| 对比 | UNIQUE KEY | PRIMARY KEY |
| --- | --- | --- |
| 实现方式 | Merge-on-Read | Merge-on-Write |
| 查询时是否需要合并 | 是 | 否 |
| 更新性能 | 一般 | 更好 |
| 查询性能 | 一般 | 更好 |
| 部分列更新 | 较弱 | 强 |
| 推荐程度 | 老方案 | **新方案** |

> 💡 **官方推荐：** 新项目优先使用 PRIMARY KEY

---

## 6. 业务场景选型指南

### 车辆轨迹 / 原始上报

**推荐：** `DUPLICATE KEY`

原因：
- 数据天然追加
- 不需要更新
- 写入量巨大

适合场景：车辆低频数据、OBU 数据、Kafka 落库

### 车辆实时在线状态

**推荐：** `PRIMARY KEY(vehicle_id)`

原因：
- 只关心最新状态
- 高频更新

### 日统计指标

比如每天每车里程、每天事故数、万公里事故率中间表

**推荐：** `AGGREGATE KEY`

### 风险分析结果 / 最新画像

**推荐：** `PRIMARY KEY`

原因：
- 会反复修正
- 支持 UPSERT
- 支持部分字段更新

---

## 7. 特殊表类型

| 类型 | 说明 |
| --- | --- |
| External Table | 外表（Hive/MySQL/Iceberg） |
| View | 视图 |
| Materialized View | 物化视图 |
| Async Materialized View | 异步物化视图 |
| Partition Table | 分区表 |
| Dynamic Partition | 动态分区 |
| Colocate Table | 共桶表 |
| Rollup | 预聚合索引 |

---

## 8. 实际场景推荐

结合车联网业务场景：

| 数据 | 推荐模型 |
| --- | --- |
| 原始轨迹点 | DUPLICATE KEY |
| 车辆在线状态 | PRIMARY KEY |
| 每小时统计 | AGGREGATE KEY |
| 每日统计 | AGGREGATE KEY |
| 风险画像 | PRIMARY KEY |
| geohash 中间结果 | DUPLICATE KEY |
| 维表 | PRIMARY KEY |

---

## 9. 常见误区

> ⚠️ **错误做法：** 什么都用 DUPLICATE KEY，然后靠 SQL 去 dedup

**后果：**
- 查询越来越慢
- 明细越来越大
- 聚合压力爆炸

> 💡 **Doris 核心思想：** "把部分计算前移到存储层"

**正确的架构：**

| 数据特征 | 模型选择 |
| --- | --- |
| 明细 | DUPLICATE |
| 聚合 | AGGREGATE |
| 状态 | PRIMARY/UNIQUE |