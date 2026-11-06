# IPage 反序列化问题与微服务分层规范

## 一、问题根源：为什么会报错？

### 本质原因
**接口无法被实例化。**

### 报错流程

1. **JSON 传输**：当 A 服务调用 B 服务时，数据以 JSON 字符串形式在网络中传输

2. **反序列化瓶颈**：Feign Client 定义返回值为 `IPage<T>`。当 Feign 收到 JSON 准备还原成 Java 对象时，Jackson 发现 `IPage` 是个**接口**

3. **Jackson 的困惑**：Jackson 不知道该用哪个具体的类来承载这些数据（是 `Page`？还是自定义的 `MyPage`？）。由于接口没有默认构造函数，Jackson 直接抛出 `InvalidDefinitionException`

---

## 二、微服务开发分层规范

### 设计原则
兼顾代码的**抽象性（解耦）**和**传输的稳定性（反序列化）**

### 分层规范表

| 开发层次 | 推荐使用类型 | 规范说明 |
|---------|-------------|---------|
| **Controller 层** | `Page<T>` | **对外边界**。必须使用具体类，确保 Swagger 文档解析准确及 JSON 序列化安全 |
| **Feign Client** | **`Page<T>`** | **传输协议**。必须使用具体实现类，否则消费者端无法反序列化 |
| **Service 接口层** | `IPage<T>` | **业务抽象**。面向接口编程，不强制绑定具体实现，方便后期扩展或 Mock 测试 |
| **Service 实现类** | `Page<T>` | **逻辑执行**。需要实例化分页参数时使用 `new Page<>()` |
| **Mapper 层** | `IPage<T>` | **持久化规范**。符合 MyBatis-Plus 插件的标准定义 |

---

## 三、规范代码示例

### 1. Feign Client（关键改动）

这是解决反序列化报错的关键：

```java
@FeignClient(name = "property-service")
public interface VehicleRpcService {
    @GetMapping("/api/vehicles/page")
    // 明确使用 Page 而非 IPage
    Result<Page<VehicleVO>> listVehiclePage(@SpringQueryMap VehicleQueryDTO query);
}
```

### 2. Controller 层

```java
@RestController
public class VehicleController {
    @Autowired
    private VehicleService vehicleService;

    @GetMapping("/page")
    public Result<Page<VehicleVO>> getPage(VehicleQueryDTO query) {
        // Service 返回 IPage，这里可以自动向上转型为 Page (因为 Page implements IPage)
        return Result.success((Page<VehicleVO>) vehicleService.queryVehiclePage(query));
    }
}
```

### 3. Service 层（保持优雅）

```java
public interface VehicleService {
    // 接口层保持抽象
    IPage<VehicleVO> queryVehiclePage(VehicleQueryDTO query);
}

@Service
public class VehicleServiceImpl implements VehicleService {
    @Override
    public IPage<VehicleVO> queryVehiclePage(VehicleQueryDTO query) {
        // 实例化时用 Page
        Page<VehicleVO> pageParam = new Page<>(query.getCurrent(), query.getSize());
        return baseMapper.selectMyPage(pageParam, query);
    }
}
```

---

## 四、避坑小贴士

### ⚠️ 常见错误

- **不要在 Feign 中使用 IPage**：即使 Provider 端（提供者）没报错，Consumer 端（消费者）在解析时必报错

### 💡 技巧建议

- **类型转换技巧**：如果需要把 `IPage<Entity>` 转换为 `IPage<VO>`，可以使用 MyBatis-Plus 提供的 `page.convert(entity -> vo)` 方法，它会保留分页元数据（总数、页码等）

---

## 五、核心总结

> **对内编程用 `IPage`（接口），对外传输用 `Page`（实体）。**

---

## 扩展：Jackson 全局配置

如果有很多旧代码不想一一修改 Feign 接口，可以配置 Jackson 自动将 `IPage` 映射到 `Page`。需要配置方案的话可以继续提问。
