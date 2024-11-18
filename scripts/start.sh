#!/bin/bash

# 检查配置文件
check_config() {
    # 检查后端配置
    if [ ! -f "backend/.env" ]; then
        echo "错误: 后端配置文件不存在"
        exit 1
    fi

    # 检查前端配置
    if [ ! -f "frontend/.env" ]; then
        echo "错误: 前端配置文件不存在"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    # 检查socat
    if ! command -v socat &> /dev/null; then
        echo "正在安装 socat..."
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y socat
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y socat
        else
            echo "请手动安装 socat"
            exit 1
        fi
    fi

    # 检查python依赖
    if [ ! -d "backend/venv" ]; then
        echo "创建Python虚拟环境..."
        python3 -m venv backend/venv
    fi

    # 检查node依赖
    if [ ! -d "frontend/node_modules" ]; then
        echo "安装前端依赖..."
        cd frontend && npm install && cd ..
    fi
}

# 启动服务
start_services() {
    # 启动后端
    echo "启动后端服务..."
    cd backend
    source venv/bin/activate
    pip install -r requirements.txt
    uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
    cd ..

    # 启动前端
    echo "启动前端服务..."
    cd frontend
    npm run dev &
    cd ..
}

# 主流程
main() {
    check_config
    check_dependencies
    start_services

    echo "服务已启动!"
    echo "后端地址: http://localhost:8000"
    echo "前端地址: http://localhost:5173"
    echo "按 Ctrl+C 停止服务"

    # 等待用户输入
    wait
}

# 运行主流程
main 