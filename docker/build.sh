#!/bin/bash
# LLM Gateway Docker 镜像构建脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 默认配置
IMAGE_NAME="${IMAGE_NAME:-llm-gateway}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🔨 开始构建 LLM Gateway Docker 镜像..."
echo "镜像名称: $IMAGE_NAME:$IMAGE_TAG"
echo "项目根目录: $PROJECT_ROOT"
echo ""

# 构建镜像
docker build \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  -f Dockerfile \
  .

echo ""
echo "✅ 构建完成！"
echo "镜像: $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "下一步："
echo "  启动容器: ./docker/run.sh"
echo "  或手动启动: docker run -d --name llm-gateway -p 3000:3000 --env-file packages/backend/.env.local $IMAGE_NAME:$IMAGE_TAG"
