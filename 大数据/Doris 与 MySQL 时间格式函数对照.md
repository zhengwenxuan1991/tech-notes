# Doris 与 MySQL 时间格式函数对照

本文补充 `FROM_UNIXTIME` 与 `DATE_FORMAT` 在 Doris 和 MySQL 中的常见写法，便于 SQL 迁移时直接对照。

## 1. FROM_UNIXTIME

### 1.1 基本作用

将 Unix 时间戳转换为日期时间。

### 1.2 MySQL

```sql
SELECT FROM_UNIXTIME(1715142896);
SELECT FROM_UNIXTIME(1715142896, '%Y-%m-%d %H:%i:%s');
```

说明：

- 第一个写法返回 `DATETIME` 风格结果。
- 第二个写法按指定格式直接返回字符串。

### 1.3 Doris

```sql
SELECT FROM_UNIXTIME(1715142896);
SELECT FROM_UNIXTIME(1715142896, '%Y-%m-%d %H:%i:%s');
```

说明：

- Doris 也支持 `FROM_UNIXTIME(timestamp)`。
- Doris 也支持 `FROM_UNIXTIME(timestamp, format)`，格式化占位符基本沿用 MySQL 风格。

### 1.4 兼容写法

MySQL 和 Doris 中通常都可以直接这样写：

```sql
SELECT FROM_UNIXTIME(create_time, '%Y-%m-%d %H:%i:%s') AS create_time_str
FROM test_table;
```

如果源字段是毫秒级时间戳，需要先除以 `1000`：

```sql
SELECT FROM_UNIXTIME(create_time_ms / 1000, '%Y-%m-%d %H:%i:%s')
FROM test_table;
```

## 2. DATE_FORMAT

### 2.1 基本作用

将日期或日期时间按指定格式输出为字符串。

### 2.2 MySQL

```sql
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d');
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s');
```

### 2.3 Doris

```sql
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d');
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s');
```

说明：

- Doris 支持 `DATE_FORMAT(date, format)`。
- 日常使用中，大部分格式串可直接复用 MySQL 写法。

## 3. 常用格式符

| 格式符 | 含义 |
| --- | --- |
| `%Y` | 四位年份 |
| `%m` | 两位月份 |
| `%d` | 两位日期 |
| `%H` | 24 小时制小时 |
| `%i` | 分钟 |
| `%s` | 秒 |

常见组合：

```sql
'%Y-%m-%d'
'%Y-%m-%d %H:%i:%s'
'%Y%m%d'
'%Y%m%d%H%i%s'
```

## 4. SQL 迁移建议

从 MySQL 迁移到 Doris 时，这两个函数一般可以直接沿用，但要重点确认下面几点：

- 时间戳是秒级还是毫秒级。
- 入参字段类型是否为整数、`DATE`、`DATETIME`。
- 个别复杂格式串在目标版本中的兼容性是否完全一致。
- 如果用于分区、聚合或查询条件，最好先验证函数结果类型是否符合预期。

## 5. 常见示例

### 5.1 时间戳转日期时间

```sql
SELECT FROM_UNIXTIME(1715142896, '%Y-%m-%d %H:%i:%s');
```

### 5.2 日期时间转日期字符串

```sql
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d');
```

### 5.3 组合使用

```sql
SELECT DATE_FORMAT(FROM_UNIXTIME(1715142896), '%Y-%m-%d') AS dt;
```

结论：

- Doris 支持 `FROM_UNIXTIME`。
- Doris 支持 `DATE_FORMAT`。
- 这两个函数在常见场景下与 MySQL 写法基本兼容，可作为迁移时的优先尝试方案。
