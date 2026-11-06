# Maven常用命令

## 依赖管理

### 查询依赖树

**基础命令：**
```bash
mvn dependency:tree
```

**常用参数组合：**

1. **查看完整依赖树**（包括传递依赖）：
```bash
mvn dependency:tree
```

2. **输出到文件**：
```bash
mvn dependency:tree -DoutputFile=dependency-tree.txt
```

3. **只显示指定依赖**：
```bash
mvn dependency:tree -Dincludes=groupId:artifactId
```

4. **显示冲突依赖**：
```bash
mvn dependency:tree -Dverbose
```

5. **按指定格式输出**：
```bash
# 输出为 DOT 格式（可用于可视化）
mvn dependency:tree -DoutputType=dot

# 输出为 GraphML 格式
mvn dependency:tree -DoutputType=graphml

# 输出为 TGF 格式
mvn dependency:tree -DoutputType=tgf
```

6. **分析特定作用域的依赖**：
```bash
# 只看 compile 作用域
mvn dependency:tree -Dscope=compile

# 只看 test 作用域
mvn dependency:tree -Dscope=test
```

7. **排除某些依赖**：
```bash
mvn dependency:tree -Dexcludes=groupId:artifactId
```

**实用技巧：**

- 使用 `grep` 过滤特定依赖：
  ```bash
  mvn dependency:tree | grep "spring"
  ```

- 查找依赖冲突：
  ```bash
  mvn dependency:tree -Dverbose | grep "omitted for conflict"
  ```

- 查看某个具体依赖的完整路径：
  ```bash
  mvn dependency:tree -Dverbose -Dincludes=groupId:artifactId
  ```

---

## 项目构建

### 清理项目
```bash
mvn clean
```

### 编译项目
```bash
mvn compile
```

### 打包项目
```bash
mvn package
```

### 跳过测试打包
```bash
mvn package -DskipTests
```

### 安装到本地仓库
```bash
mvn install
```

### 部署到远程仓库
```bash
mvn deploy
```

---

## 测试相关

### 运行测试
```bash
mvn test
```

### 运行指定测试类
```bash
mvn test -Dtest=TestClassName
```

### 运行指定测试方法
```bash
mvn test -Dtest=TestClassName#testMethodName
```

---

## 其他常用命令

### 查看有效 POM
```bash
mvn help:effective-pom
```

### 查看有效 settings
```bash
mvn help:effective-settings
```

### 查看插件信息
```bash
mvn help:describe -Dplugin=插件名
```

### 更新依赖
```bash
mvn versions:display-dependency-updates
```

### 更新插件
```bash
mvn versions:display-plugin-updates
```
