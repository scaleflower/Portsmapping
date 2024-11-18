import os
from datetime import datetime

# 确保日志目录存在
LOG_DIR = "logs"
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)

# 日志配置
LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        },
        "detailed": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s - [%(filename)s:%(lineno)d]"
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
            "level": "INFO"
        },
        "file": {
            "class": "logging.handlers.RotatingFileHandler",
            "filename": os.path.join(LOG_DIR, "portmapping.log"),
            "maxBytes": 10485760,  # 10MB
            "backupCount": 5,
            "formatter": "detailed",
            "level": "INFO"
        }
    },
    "root": {
        "handlers": ["console", "file"],
        "level": "INFO"
    }
} 