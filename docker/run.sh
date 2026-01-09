#!/bin/bash
# LLM Gateway Docker 容器启动脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 配置参数
IMAGE_NAME="${IMAGE_NAME:-llm-gateway}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-llm-gateway}"
PORT="${PORT:-3000}"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/packages/backend/.env.local}"

echo "🐳 启动 LLM Gateway 容器..."
echo "镜像: $IMAGE_NAME:$IMAGE_TAG"
echo "容器名: $CONTAINER_NAME"
echo "端口: $PORT"
echo "环境变量文件: $ENV_FILE"
echo ""

# 检查环境变量文件
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ 错误: 环境变量文件不存在: $ENV_FILE"
  echo "请先创建配置文件:"
  echo "  cp packages/backend/.env.example packages/backend/.env.local"
  echo "  # 然后编辑 packages/backend/.env.local 填入真实配置"
  exit 1
fi

# 停止并删除旧容器
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "🛑 停止旧容器..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# 启动新容器
echo "🚀 启动新容器..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "$PORT:3000" \
  --env-file "$ENV_FILE" \
  --restart unless-stopped \
  "$IMAGE_NAME:$IMAGE_TAG"

echo ""
echo "✅ 容器已启动！"
echo ""
echo "常用命令："
echo "  查看日志: docker logs -f $CONTAINER_NAME"
echo "  停止容器: docker stop $CONTAINER_NAME"
echo "  进入容器: docker exec -it $CONTAINER_NAME sh"
echo "  重启容器: docker restart $CONTAINER_NAME"
echo ""
echo "🌐 访问地址: http://localhost:$PORT"
echo "💚 健康检查: http://localhost:$PORT/health"
