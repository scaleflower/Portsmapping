#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 检查系统类型
check_system() {
    log_info "检查系统类型..."
    if [ -f /etc/debian_version ]; then
        SYSTEM_TYPE="debian"
        log_info "检测到 Debian/Ubuntu 系统"
    elif [ -f /etc/redhat-release ]; then
        SYSTEM_TYPE="redhat"
        log_info "检测到 RHEL/CentOS 系统"
    else
        log_error "不支持的系统类型"
        exit 1
    fi
}

# 检查并安装基础依赖
install_base_dependencies() {
    log_info "安装基础依赖..."
    if [ "$SYSTEM_TYPE" = "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv nodejs npm socat git curl
    elif [ "$SYSTEM_TYPE" = "redhat" ]; then
        sudo yum install -y python3 python3-pip nodejs npm socat git curl
    fi
}

# 检查Python版本

check_python_version() {
    log_info "检查Python版本..."
    
    # 获取 Python 版本的主版本和次版本，并与 3.8 进行比较
    PYTHON_VERSION=$(python3 -c 'import platform; print(platform.python_version())' | cut -d. -f1-2)
    
    if [[ $(echo "$PYTHON_VERSION" | tr -d '.') -ge 38 ]]; then
        log_info "Python版本检查通过: $PYTHON_VERSION"
    else
        log_error "Python版本必须 >= 3.8，当前版本: $PYTHON_VERSION"
        exit 1
    fi
}


# 检查Node.js版本
check_nodejs_version() {
    log_info "检查Node.js版本..."
    NODE_VERSION=$(node -v | cut -d'v' -f2)
    if (( $(echo "$NODE_VERSION 14.0" | awk '{print ($1 < $2)}') )); then
        log_error "Node.js版本必须 >= 14.0，当前版本: $NODE_VERSION"
        exit 1
    fi
    log_info "Node.js版本检查通过: $NODE_VERSION"
}

# 创建项目目录
create_project_structure() {
    log_info "创建项目目录结构..."
    
    # 创建主项目目录
    mkdir -p port-mapping
    cd port-mapping
    
    # 创建后端目录结构
    mkdir -p backend/{app/{api,core,models,utils},config,logs}
    
    # 创建前端目录结构
    mkdir -p frontend/src/{api,components,views,stores,assets}
}

# 配置环境变量
configure_environment() {
    log_info "配置环境变量..."
    
    # 提示用户输入配置信息
    read -p "请输入后端服务端口 (默认: 8000): " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-8000}
    
    read -p "请输入前端服务端口 (默认: 5173): " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-5173}
    
    # 生成后端.env文件
    cat > backend/.env << EOF
DEBUG=True
HOST=0.0.0.0
PORT=$BACKEND_PORT
DATABASE_URL=sqlite:///./portmapping.db
LOG_LEVEL=INFO
LOG_FILE=logs/portmapping.log
SECRET_KEY=$(openssl rand -hex 32)
ALLOW_ORIGINS=["http://localhost:$FRONTEND_PORT"]
EOF

    # 生成前端.env文件
    cat > frontend/.env << EOF
VITE_API_BASE_URL=http://localhost:$BACKEND_PORT/api
VITE_API_TIMEOUT=5000
VITE_APP_TITLE=端口映射管理系统
VITE_APP_VERSION=1.0.0
VITE_MONITOR_INTERVAL=2000
EOF

    log_info "环境变量配置完成"
}

# 安装后端依赖
setup_backend() {
    log_info "设置后端环境..."
    
    cd backend
    
    # 创建虚拟环境
    python3 -m venv venv
    source venv/bin/activate
    
    # 安装依赖
    pip install fastapi uvicorn sqlalchemy psutil python-dotenv
    
    # 初始化数据库
    python3 << EOF
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String, DateTime
import datetime

Base = declarative_base()

class Mapping(Base):
    __tablename__ = 'mappings'
    
    id = Column(Integer, primary_key=True)
    local_port = Column(Integer, unique=True)
    remote_host = Column(String)
    remote_port = Column(Integer)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

engine = create_engine('sqlite:///portmapping.db')
Base.metadata.create_all(engine)
EOF
    
    deactivate
    cd ..
    
    log_info "后端环境设置完成"
}

# 安装前端依赖
setup_frontend() {
    log_info "设置前端环境..."
    
    cd frontend
    
    # 初始化npm项目
    npm init -y
    
    # 安装依赖
    npm install vue@next element-plus axios echarts pinia vue-router
    npm install -D vite @vitejs/plugin-vue sass
    
    cd ..
    
    log_info "前端环境设置完成"
}

# 创建启动脚本
create_start_script() {
    log_info "创建启动脚本..."
    
    cat > start.sh << 'EOF'
#!/bin/bash

# 启动后端
start_backend() {
    cd backend
    source venv/bin/activate
    uvicorn main:app --reload --host 0.0.0.0 --port $(grep PORT .env | cut -d= -f2) &
    BACKEND_PID=$!
    cd ..
    echo $BACKEND_PID > .backend.pid
}

# 启动前端
start_frontend() {
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    echo $FRONTEND_PID > .frontend.pid
}

# 停止服务
stop_services() {
    if [ -f .backend.pid ]; then
        kill $(cat .backend.pid)
        rm .backend.pid
    fi
    if [ -f .frontend.pid ]; then
        kill $(cat .frontend.pid)
        rm .frontend.pid
    fi
}

# 注册清理函数
trap stop_services EXIT

# 启动服务
start_backend
start_frontend

echo "服务已启动!"
echo "后端地址: http://localhost:$(grep PORT backend/.env | cut -d= -f2)"
echo "前端地址: http://localhost:$(grep FRONTEND_PORT frontend/.env | cut -d= -f2)"
echo "按 Ctrl+C 停止服务"

# 等待用户输入
wait
EOF

    chmod +x start.sh
    log_info "启动脚本创建完成"
}

# 下载源代码
download_source_code() {
    log_info "从GitHub下载源代码..."
    
    # 检查git是否安装
    if ! command -v git &> /dev/null; then
        log_warn "Git未安装，正在安装..."
        if [ "$SYSTEM_TYPE" = "debian" ]; then
            sudo apt-get install -y git
        elif [ "$SYSTEM_TYPE" = "redhat" ]; then
            sudo yum install -y git
        fi
    fi
    
    # 克隆代码仓库
    git clone https://github.com/scaleflower/Portsmapping.git temp_repo
    
    # 移动文件到对应目录
    if [ -d "temp_repo" ]; then
        # 移动后端文件
        cp -r temp_repo/backend/* backend/
        # 移动前端文件
        cp -r temp_repo/frontend/* frontend/
        # 清理临时目录
        rm -rf temp_repo
        log_info "源代码下载完成"
    else
        log_error "源代码下载失败"
        exit 1
    fi
}

# 主函数
main() {
    log_info "开始安装端口映射系统..."
    
    check_system
    install_base_dependencies
    download_source_code
    check_python_version
    check_nodejs_version
    create_project_structure
    configure_environment
    setup_backend
    setup_frontend
    create_start_script
    
    log_info "安装完成！"
    log_info "使用以下命令启动服务："
    log_info "    ./start.sh"
}

# 执行主函数
main 