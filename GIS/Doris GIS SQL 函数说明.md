---
title: Doris GIS SQL 函数说明
tags:
  - doris
  - gis
  - sql
  - spatial
aliases:
  - Doris 空间函数说明
  - Doris ST_CONTAINS 用法
created: 2026-06-02
---

# Doris GIS SQL 函数说明

这篇笔记记录 Apache Doris 中常用 GIS / Spatial SQL 函数的基本用法，重点说明电子围栏命中场景里最常见的几个函数：

- `ST_GeometryFromText`
- `ST_Point`
- `ST_Contains`
- `ST_AsText`

适用场景：

- 围栏 `WKT` 文本转几何对象
- 轨迹点落围栏判断
- 围栏数据排错

## 1. 核心结论

如果表字段里存的是 `WKT` 字符串，例如：

```sql
POLYGON ((116.1 39.9, 116.2 39.9, 116.2 40.0, 116.1 40.0, 116.1 39.9))
```

那么不能直接这样写：

```sql
ST_CONTAINS(c.region_wkt, ST_Point(t1.longitude, t1.latitude))
```

原因：

- `c.region_wkt` 是字符串，不是几何对象
- `ST_CONTAINS` 的第一个参数必须是 geometry

正确写法：

```sql
ST_CONTAINS(
    ST_GeometryFromText(c.region_wkt),
    ST_Point(t1.longitude, t1.latitude)
)
```

## 2. 函数说明

### 2.1 `ST_GeometryFromText`

作用：把 `WKT` 文本转成 Doris 可计算的几何对象。

语法：

```sql
ST_GeometryFromText(wkt_string)
```

示例：

```sql
SELECT ST_AsText(ST_GeometryFromText('POINT (116.397128 39.916527)'));
```

说明：

- 输入是 `POINT`、`LINESTRING`、`POLYGON`、`MULTIPOLYGON` 等 WKT 字符串
- 如果 WKT 格式不合法，返回 `NULL`
- `MULTIPOLYGON` 解析从 `Apache Doris 3.0.6` 开始支持

### 2.2 `ST_Point`

作用：根据坐标构造一个点对象。

语法：

```sql
ST_Point(x, y)
```

在经纬度场景里：

- `x = longitude`
- `y = latitude`

示例：

```sql
SELECT ST_AsText(ST_Point(116.397128, 39.916527));
```

输出应类似：

```sql
POINT (116.397128 39.916527)
```

注意：经纬度不要写反，必须是 `ST_Point(经度, 纬度)`。

### 2.3 `ST_Contains`

作用：判断几何对象 `shape1` 是否包含 `shape2`。

语法：

```sql
ST_Contains(shape1, shape2)
```

返回值：

- `1`：包含
- `0`：不包含

围栏命中场景中，通常是：

```sql
ST_Contains(围栏面, 轨迹点)
```

即：

```sql
ST_Contains(
    ST_GeometryFromText(c.region_wkt),
    ST_Point(t1.longitude, t1.latitude)
)
```

### 2.4 `ST_AsText`

作用：把几何对象转回 `WKT` 文本，便于排查问题。

语法：

```sql
ST_AsText(geometry)
```

常见用途：

- 验证 `ST_GeometryFromText` 是否成功解析
- 验证 `ST_Point` 生成的点坐标是否正确

示例：

```sql
SELECT ST_AsText(ST_Point(116.397128, 39.916527));
```

## 3. 电子围栏命中 SQL 写法

假设：

- `dim_electronic_fence_geo_meta.region_wkt` 存放围栏 WKT
- `dwd_car_cloud_low_freq_info_tenant.longitude` / `latitude` 存放车辆轨迹点

标准写法如下：

```sql
SELECT
    t1.vehicle_id,
    t1.tenant_id,
    t1.longitude,
    t1.latitude,
    t1.p_date,
    c.fence_id,
    c.electronic_name
FROM dwd_car_cloud_low_freq_info_tenant t1
JOIN dim_electronic_fence_geo_meta c
    ON t1.tenant_id = c.tenant_id
WHERE t1.p_date = '2025-08-12'
  AND t1.vehicle_id = 'I100010J'
  AND t1.geohash7 IS NOT NULL
  AND t1.longitude BETWEEN -180 AND 180
  AND t1.latitude BETWEEN -90 AND 90
  AND t1.mileage_sec IS NOT NULL
  AND c.region_wkt IS NOT NULL
  AND ST_Contains(
        ST_GeometryFromText(c.region_wkt),
        ST_Point(t1.longitude, t1.latitude)
      ) = 1;
```

## 4. 推荐的性能优化写法

如果围栏很多，先用外接矩形预过滤，再做 `ST_Contains`，通常更省资源：

```sql
SELECT
    t1.vehicle_id,
    t1.tenant_id,
    t1.longitude,
    t1.latitude,
    c.fence_id,
    c.electronic_name
FROM dwd_car_cloud_low_freq_info_tenant t1
JOIN dim_electronic_fence_geo_meta c
    ON t1.tenant_id = c.tenant_id
WHERE t1.p_date = '2025-08-12'
  AND t1.vehicle_id = 'I100010J'
  AND t1.longitude BETWEEN -180 AND 180
  AND t1.latitude BETWEEN -90 AND 90
  AND c.region_wkt IS NOT NULL
  AND t1.longitude BETWEEN c.min_lon AND c.max_lon
  AND t1.latitude BETWEEN c.min_lat AND c.max_lat
  AND ST_Contains(
        ST_GeometryFromText(c.region_wkt),
        ST_Point(t1.longitude, t1.latitude)
      ) = 1;
```

## 5. 常见错误

### 5.1 直接把字符串传给 `ST_Contains`

错误写法：

```sql
ST_CONTAINS(c.region_wkt, ST_Point(t1.longitude, t1.latitude))
```

问题：

- `region_wkt` 是字符串
- 不是 geometry

正确写法：

```sql
ST_CONTAINS(
    ST_GeometryFromText(c.region_wkt),
    ST_Point(t1.longitude, t1.latitude)
)
```

### 5.2 用错了经纬度字段

错误示例：

```sql
ST_CONTAINS(c.region_wkt, ST_Point(c.longitude, c.latitude))
```

问题：

- `c` 是围栏表别名，不一定有 `longitude` / `latitude`
- 点应该来自轨迹表，例如 `t1.longitude`、`t1.latitude`

### 5.3 经纬度顺序写反

错误示例：

```sql
ST_Point(t1.latitude, t1.longitude)
```

正确写法：

```sql
ST_Point(t1.longitude, t1.latitude)
```

### 5.4 WKT 本身不合法

例如：

- `POLYGON` 首尾没有闭合
- 点位数量不足
- 坐标格式错误

这类情况下：

```sql
ST_GeometryFromText(region_wkt)
```

通常会返回 `NULL`。

## 6. 排错 SQL

### 6.1 检查 WKT 能否正常解析

```sql
SELECT
    fence_id,
    region_wkt,
    ST_AsText(ST_GeometryFromText(region_wkt)) AS parsed_wkt
FROM dim_electronic_fence_geo_meta
WHERE region_wkt IS NOT NULL
LIMIT 10;
```

如果 `parsed_wkt` 是 `NULL`，说明这条 `WKT` 有问题。

### 6.2 检查轨迹点是否正确

```sql
SELECT
    vehicle_id,
    longitude,
    latitude,
    ST_AsText(ST_Point(longitude, latitude)) AS point_wkt
FROM dwd_car_cloud_low_freq_info_tenant
WHERE p_date = '2025-08-12'
  AND vehicle_id = 'I100010J'
LIMIT 10;
```

### 6.3 用固定点测试某个围栏

```sql
SELECT
    fence_id,
    electronic_name,
    ST_Contains(
        ST_GeometryFromText(region_wkt),
        ST_Point(116.397128, 39.916527)
    ) AS hit
FROM dim_electronic_fence_geo_meta
WHERE region_wkt IS NOT NULL
LIMIT 10;
```

### 6.4 检查解析后几何对象是否为空

```sql
SELECT
    fence_id,
    region_wkt
FROM dim_electronic_fence_geo_meta
WHERE region_wkt IS NOT NULL
  AND ST_GeometryFromText(region_wkt) IS NULL;
```

## 7. 你的场景可直接套用的 SQL

```sql
SELECT
    t1.*,
    c.fence_id,
    c.electronic_name
FROM dwd_car_cloud_low_freq_info_tenant t1
JOIN dim_electronic_fence_geo_meta c
    ON t1.tenant_id = c.tenant_id
WHERE t1.p_date BETWEEN '2025-08-12' AND '2025-08-12'
  AND t1.geohash7 IS NOT NULL
  AND t1.longitude BETWEEN -180 AND 180
  AND t1.latitude BETWEEN -90 AND 90
  AND t1.mileage_sec IS NOT NULL
  AND t1.vehicle_id IN ('I100010J')
  AND c.region_wkt IS NOT NULL
  AND ST_Contains(
        ST_GeometryFromText(c.region_wkt),
        ST_Point(t1.longitude, t1.latitude)
      ) = 1;
```

## 8. 一句话记忆

在 Doris 里：

- 围栏如果是 `WKT` 字符串，先 `ST_GeometryFromText`
- 轨迹点用 `ST_Point(经度, 纬度)`
- 面包点判断用 `ST_Contains(面, 点)`
- 排错优先用 `ST_AsText`

## 9. 官方文档

- `ST_CONTAINS`:
  https://doris.apache.org/docs/4.x/sql-manual/sql-functions/scalar-functions/spatial-functions/st-contains/
- `ST_GEOMETRYFROMTEXT`:
  https://doris.apache.org/docs/dev/sql-manual/sql-functions/scalar-functions/spatial-functions/st-geometryfromtext/
- `ST_ASTEXT`:
  https://doris.apache.org/docs/4.x/sql-manual/sql-functions/scalar-functions/spatial-functions/st-astext/

