#!/bin/sh
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 加载环境变量文件
load_env_file() {
    local env_file="/app/packages/backend/.env.local"

    if [ -f "$env_file" ]; then
        log_info "加载环境变量文件: $env_file"

        # 读取 .env 文件并导出变量
        while IFS='=' read -r key value; do
            # 跳过注释和空行
            [[ $key =~ ^#.*$ ]] && continue
            [[ -z $key ]] && continue

            # 移除值前后的空格和引号
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

            # 导出变量（如果尚未设置）
            if [ -z "${!key}" ]; then
                export "$key=$value"
            fi
        done < "$env_file"

        log_info "环境变量加载完成"
    else
        log_info "未找到环境变量文件: $env_file，使用环境变量或默认值"
    fi
}

# 检查必需的环境变量
check_required_env() {
    if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ]; then
        log_warn "未配置 MySQL 环境变量，请确保在容器启动时设置以下环境变量："
        log_warn "  - MYSQL_HOST"
        log_warn "  - MYSQL_DATABASE"
        log_warn "  - MYSQL_USER"
        log_warn "  - MYSQL_PASSWORD"
    fi
}

# 等待 MySQL 就绪
wait_for_mysql() {
    if [ -n "$MYSQL_HOST" ]; then
        log_info "等待 MySQL 服务就绪..."

        max_attempts=30
        attempt=0

        while [ $attempt -lt $max_attempts ]; do
            # 尝试使用 nc (netcat) 连接
            if command -v nc >/dev/null 2>&1; then
                if nc -z "$MYSQL_HOST" "${MYSQL_PORT:-3306}" 2>/dev/null; then
                    log_info "MySQL 服务已就绪"
                    return 0
                fi
            # 如果没有 nc，使用 bun 直接测试连接
            else
                if bun -e "
                const mysql = require('mysql2/promise');
                mysql.createConnection({
                    host: process.env.MYSQL_HOST,
                    port: parseInt(process.env.MYSQL_PORT || '3306'),
                    user: process.env.MYSQL_USER,
                    password: process.env.MYSQL_PASSWORD,
                    database: process.env.MYSQL_DATABASE,
                    connectTimeout: 2000
                }).then(() => process.exit(0)).catch(() => process.exit(1));
                " 2>/dev/null; then
                    log_info "MySQL 服务已就绪"
                    return 0
                fi
            fi

            attempt=$((attempt + 1))
            if [ $((attempt % 5)) -eq 0 ]; then
                log_info "仍在等待 MySQL... ($attempt/$max_attempts)"
            fi
            sleep 2
        done

        log_warn "MySQL 服务在 ${max_attempts} 次尝试后仍未就绪，但将继续启动"
        return 0
    fi
}

# 创建必要的目录
create_directories() {
    log_info "创建数据目录..."

    mkdir -p /app/data
    mkdir -p /app/temp/backups

    log_info "目录创建完成"
}

# 显示启动信息
show_startup_info() {
    log_info "=========================================="
    log_info "LLM Gateway 正在启动"
    log_info "=========================================="
    log_info "环境: ${NODE_ENV:-production}"
    log_info "端口: ${PORT:-3000}"
    log_info "日志级别: ${LOG_LEVEL:-info}"

    if [ -n "$MYSQL_HOST" ]; then
        log_info "数据库: mysql://$MYSQL_USER@$MYSQL_HOST:${MYSQL_PORT:-3306}/$MYSQL_DATABASE"
    else
        log_warn "未配置数据库连接"
    fi

    log_info "=========================================="
}

# 健康检查
health_check() {
    log_info "执行启动前健康检查..."

    # 检查后端构建产物
    if [ ! -f "/app/packages/backend/dist/index.js" ]; then
        log_error "后端构建产物不存在: /app/packages/backend/dist/index.js"
        return 1
    fi

    # 检查前端构建产物（警告但不失败）
    if [ ! -d "/app/packages/backend/public" ]; then
        log_warn "前端构建产物不存在: /app/packages/backend/public (UI 将不可用)"
    fi

    log_info "健康检查通过"
}

# 主函数
main() {
    log_info "初始化 LLM Gateway..."

    # 加载环境变量文件（如果存在）
    load_env_file

    check_required_env
    create_directories
    health_check

    # 如果配置了 MySQL，等待其就绪
    if [ -n "$MYSQL_HOST" ]; then
        wait_for_mysql
    fi

    show_startup_info

    # 启动应用
    log_info "启动后端服务..."

    cd /app/packages/backend

    # 使用 exec 确保信号正确传递
    exec bun run dist/index.js
}

# 捕获信号，优雅退出
trap 'log_info "收到终止信号，正在关闭..."; exit 0' TERM INT

# 执行主函数
main "$@"
