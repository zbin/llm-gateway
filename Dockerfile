# 多阶段构建 - 基于 Bun

# ========================
# Stage 1: 依赖安装
# ========================
FROM oven/bun:1-alpine AS deps

WORKDIR /app

# 复制 workspace 配置
COPY package.json bunfig.toml ./
COPY packages/shared/package.json ./packages/shared/
COPY packages/backend/package.json ./packages/backend/
COPY packages/web/package.json ./packages/web/
COPY packages/tsconfig/package.json ./packages/tsconfig/

# 安装所有依赖
RUN bun install --frozen-lockfile

# ========================
# Stage 2: 前端构建
# ========================
FROM oven/bun:1-alpine AS web-builder

WORKDIR /app

# 复制 workspace 配置和锁文件
COPY package.json bun.lock bunfig.toml ./
COPY packages/web/package.json ./packages/web/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig ./packages/tsconfig

# 复制 shared 包
COPY packages/shared ./packages/shared

# 复制前端源码
COPY packages/web ./packages/web

# 安装依赖并构建前端
WORKDIR /app
RUN bun install
RUN bun run build:web

# ========================
# Stage 3: 后端构建
# ========================
FROM oven/bun:1-alpine AS backend-builder

WORKDIR /app

# 复制 workspace 配置和锁文件
COPY package.json bun.lock bunfig.toml ./
COPY packages/backend/package.json ./packages/backend/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig ./packages/tsconfig

# 复制 shared 包
COPY packages/shared ./packages/shared

# 复制后端源码
COPY packages/backend ./packages/backend

# 安装依赖并构建后端
WORKDIR /app
RUN bun install
RUN bun run build:backend

# ========================
# Stage 4: 生产运行环境
# ========================
FROM oven/bun:1-alpine

WORKDIR /app

# 安装必要的运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    docker-cli \
    netcat-openbsd

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 复制 workspace 配置
COPY package.json bunfig.toml ./
COPY packages/backend/package.json ./packages/backend/
COPY packages/shared/package.json ./packages/shared/

# 安装生产依赖
RUN bun install --production

# 复制后端构建产物
COPY --from=backend-builder /app/packages/backend/dist ./packages/backend/dist

# 复制前端构建产物到后端静态目录
COPY --from=web-builder /app/packages/web/dist ./packages/backend/public

# 复制启动脚本
COPY docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# 创建数据目录
RUN mkdir -p /app/data /app/temp/backups

# 环境变量
ENV NODE_ENV=production
ENV PORT=3000
ENV LOG_LEVEL=info

# 设置权限
RUN chown -R nodejs:nodejs /app

# 切换到非 root 用户
USER nodejs

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD nc -z localhost 3000 || exit 1

# 启动应用
ENTRYPOINT ["/app/entrypoint.sh"]

