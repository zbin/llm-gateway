# Docker 部署指南

本文档介绍如何使用 Docker 部署 LLM Gateway。

## 快速开始

### 1. 准备环境变量

```bash
# 进入后端目录
cd packages/backend

# 复制环境变量示例文件
cp .env.example .env.local

# 编辑 .env.local 文件，填入实际的配置值
vim .env.local
```

### 2. 使用 Docker Compose（推荐）

```bash
# 返回项目根目录
cd ../..

# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f llm-gateway

# 停止服务
docker-compose down
```

### 3. 使用 Docker 命令

```bash
# 构建镜像
docker build -t llm-gateway:latest .

# 运行容器（需要先启动 MySQL）
docker run -d \
  --name llm-gateway \
  -p 3000:3000 \
  -v $(pwd)/packages/backend/.env.local:/app/packages/backend/.env.local:ro \
  -v llm-gateway-data:/app/data \
  -v llm-gateway-backups:/app/temp/backups \
  llm-gateway:latest
```

## 配置说明

### 环境变量文件位置

环境变量文件位于：`packages/backend/.env.local`

### 必需环境变量

在 `packages/backend/.env.local` 中配置以下必需变量：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `MYSQL_HOST` | MySQL 主机地址 | `mysql` 或 `10.10.2.60` |
| `MYSQL_PORT` | MySQL 端口 | `3306` |
| `MYSQL_USER` | MySQL 用户名 | `llm_gateway` |
| `MYSQL_PASSWORD` | MySQL 密码 | `your_password` |
| `MYSQL_DATABASE` | 数据库名称 | `llm_gateway` |
| `JWT_SECRET` | JWT 签名密钥 | `your_secret_key` |

### 可选环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `PORT` | 服务端口 | `3000` |
| `NODE_ENV` | 运行环境 | `production` |
| `LOG_LEVEL` | 日志级别 | `info` |
| `PUBLIC_URL` | 公网访问地址 | `http://localhost:3000` |
| `DEMO_MODE` | 演示模式 | `false` |
| `BACKUP_SCHEDULE_CRON` | 备份计划 | `0 2 * * *` |
| `BACKUP_RETENTION_DAYS` | 备份保留天数 | `30` |

## 数据持久化

Docker 部署使用以下卷来持久化数据：

- `llm-gateway-data`: 应用数据
- `llm-gateway-backups`: 备份文件
- `mysql-data`: MySQL 数据（如使用 docker-compose 的 MySQL）

## Entrypoint 功能

容器启动时会自动执行以下操作：

1. **加载环境变量**: 从 `/app/packages/backend/.env.local` 加载配置
2. **创建目录**: 创建必要的数据和备份目录
3. **健康检查**: 验证构建产物是否存在
4. **等待 MySQL**: 如果配置了 MySQL，等待其就绪
5. **启动服务**: 启动后端服务

## 健康检查

容器包含健康检查，默认每 30 秒检查一次服务是否正常运行：

```bash
# 查看容器健康状态
docker ps

# 查看健康检查日志
docker inspect llm-gateway | grep -A 10 Health
```

## 日志查看

```bash
# 查看实时日志
docker logs -f llm-gateway

# 查看最近 100 行日志
docker logs --tail 100 llm-gateway

# 使用 docker-compose
docker-compose logs -f llm-gateway
```

## 故障排查

### 1. 容器无法启动

```bash
# 查看容器日志
docker logs llm-gateway

# 检查环境变量文件
docker exec llm-gateway cat /app/packages/backend/.env.local
```

### 2. 数据库连接失败

- 确认 MySQL 服务正在运行
- 检查 `.env.local` 中的 `MYSQL_HOST` 是否正确
- 验证数据库凭据是否正确
- 如果使用 docker-compose 的 MySQL，确保服务名称为 `mysql`

### 3. 环境变量未生效

```bash
# 进入容器检查
docker exec -it llm-gateway sh

# 查看已加载的环境变量
env | grep MYSQL
```

## 生产环境建议

1. **使用外部 MySQL**: 不要在生产环境使用 docker-compose 的 MySQL
2. **设置强密码**: 使用随机生成的强密码
3. **保护敏感信息**: 不要将 `.env.local` 提交到版本控制
4. **配置资源限制**: 在 docker-compose.yml 中添加资源限制
5. **使用镜像版本**: 固定镜像版本而不是使用 `latest`
6. **配置备份策略**: 定期备份持久化卷

## 更新部署

```bash
# 拉取最新代码
git pull

# 重新构建镜像
docker-compose build

# 重启服务
docker-compose up -d
```

## 清理

```bash
# 停止并删除所有容器和卷
docker-compose down -v

# 删除构建的镜像
docker rmi llm-gateway:latest
```
