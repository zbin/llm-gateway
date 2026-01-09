# Docker 部署指南

本目录包含 LLM Gateway 的所有 Docker 相关资源。

## 📁 目录结构

```
docker/
├── README.md                  # 本文件
├── build.sh                   # 镜像构建脚本
├── run.sh                     # 容器启动脚本
├── entrypoint.sh             # 容器入口脚本
├── docker-compose.yml        # 生产环境编排
├── docker-compose.dev.yml    # 开发环境编排（仅 MySQL）
└── mysql/                    # MySQL 配置
    └── conf.d/
        └── llm.cnf           # MySQL 性能配置
```

## 🚀 快速开始

### 方式 1：使用便捷脚本（推荐）

```bash
# 1. 准备环境变量
cp packages/backend/.env.example packages/backend/.env.local
# 编辑 packages/backend/.env.local 填入真实配置

# 2. 构建镜像
./docker/build.sh

# 3. 启动容器
./docker/run.sh
```

### 方式 2：手动执行

```bash
# 1. 构建镜像
docker build -t llm-gateway:latest .

# 2. 启动容器
docker run -d \
  --name llm-gateway \
  -p 3000:3000 \
  --env-file packages/backend/.env.local \
  llm-gateway:latest
```

### 方式 3：使用 Docker Compose

```bash
# 生产环境（包含 MySQL + LLM Gateway）
cd docker
docker-compose up -d

# 开发环境（仅 MySQL，后端本地运行）
docker-compose -f docker/docker-compose.dev.yml up -d
bun run dev:backend
```

## 📝 环境变量配置

环境变量文件位置：`packages/backend/.env.local`

必需配置：
- `JWT_SECRET`: JWT 密钥（至少 32 字符）
- `MYSQL_HOST`: MySQL 主机地址
- `MYSQL_PASSWORD`: MySQL 密码
- `MYSQL_DATABASE`: 数据库名称

详细配置请参考：`packages/backend/.env.example`

## 🔧 常用命令

### 构建相关
```bash
# 构建镜像
./docker/build.sh

# 自定义镜像名和标签
IMAGE_NAME=my-gateway IMAGE_TAG=v1.0 ./docker/build.sh
```

### 容器管理
```bash
# 启动容器
./docker/run.sh

# 查看日志
docker logs -f llm-gateway

# 进入容器
docker exec -it llm-gateway sh

# 停止容器
docker stop llm-gateway

# 重启容器
docker restart llm-gateway

# 删除容器
docker rm -f llm-gateway
```

### Docker Compose
```bash
# 启动所有服务
docker-compose -f docker/docker-compose.yml up -d

# 查看服务状态
docker-compose -f docker/docker-compose.yml ps

# 查看日志
docker-compose -f docker/docker-compose.yml logs -f

# 停止所有服务
docker-compose -f docker/docker-compose.yml down
```

## 🔍 健康检查

```bash
# 健康检查接口
curl http://localhost:3000/health

# 访问前端
open http://localhost:3000
```

## 🐛 故障排查

### 问题 1：容器无法启动

```bash
# 查看详细日志
docker logs llm-gateway

# 检查配置文件是否存在
ls -la packages/backend/.env.local
```

### 问题 2：无法连接数据库

```bash
# 检查 MySQL 容器是否运行
docker ps | grep mysql

# 测试数据库连接
docker exec -it llm-gateway-mysql mysql -uroot -p
```

### 问题 3：前端无法访问

检查日志中是否有 "静态文件服务已启用" 消息：
```bash
docker logs llm-gateway | grep "静态文件"
```

## 📚 更多文档

- [项目主 README](../README.md)
- [环境变量配置说明](../packages/backend/.env.example)
- [开发指南](../docs/) （如果有的话）

## 💡 提示

1. **本地开发**：使用 `docker-compose.dev.yml` 只启动 MySQL，后端在本地运行调试更方便
2. **生产部署**：使用完整的 `docker-compose.yml` 或直接使用便捷脚本
3. **环境变量**：永远不要提交 `.env.local` 文件到 Git
4. **端口冲突**：如果 3000 端口被占用，修改 `PORT` 环境变量或 `-p` 参数
