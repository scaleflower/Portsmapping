import os
from pathlib import Path
from dotenv import load_dotenv

# 加载.env文件
load_dotenv()

# 基础配置
BASE_DIR = Path(__file__).resolve().parent.parent
DEBUG = os.getenv("DEBUG", "False").lower() == "true"
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))

# 数据库配置
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./portmapping.db")

# 安全配置
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-here")
ALLOW_ORIGINS = eval(os.getenv("ALLOW_ORIGINS", '["http://localhost:5173"]'))

# 日志配置
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
LOG_FILE = os.getenv("LOG_FILE", "logs/portmapping.log")

# Socat配置
SOCAT_PATH = "/usr/bin/socat"
SOCAT_TIMEOUT = 60

# 监控配置
MONITOR_INTERVAL = 5  # 监控数据更新间隔（秒）
TRAFFIC_HISTORY_LENGTH = 3600  # 保存1小时的流量历史数据 