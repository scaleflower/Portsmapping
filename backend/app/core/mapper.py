import subprocess
import logging
import psutil
from typing import Dict, Optional
from dataclasses import dataclass
from datetime import datetime

@dataclass
class MappingInfo:
    local_port: int
    remote_host: str
    remote_port: int
    process: Optional[subprocess.Popen] = None
    start_time: datetime = None
    status: str = "stopped"

class SocatMapper:
    def __init__(self):
        self.mappings: Dict[int, MappingInfo] = {}
        self.logger = logging.getLogger(__name__)

    def create_mapping(self, local_port: int, remote_host: str, remote_port: int) -> bool:
        try:
            # 构建 socat 命令
            cmd = [
                'socat',
                f'TCP-LISTEN:{local_port},reuseaddr,fork',
                f'TCP:{remote_host}:{remote_port}'
            ]
            
            # 启动 socat 进程
            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            # 存储映射信息
            self.mappings[local_port] = MappingInfo(
                local_port=local_port,
                remote_host=remote_host,
                remote_port=remote_port,
                process=process,
                start_time=datetime.now(),
                status="running"
            )
            
            self.logger.info(f"创建映射成功: {local_port} -> {remote_host}:{remote_port}")
            return True
            
        except Exception as e:
            self.logger.error(f"创建映射失败: {str(e)}")
            return False

    def stop_mapping(self, local_port: int) -> bool:
        if local_port in self.mappings:
            mapping = self.mappings[local_port]
            if mapping.process:
                try:
                    # 终止 socat 进程及其子进程
                    parent = psutil.Process(mapping.process.pid)
                    children = parent.children(recursive=True)
                    for child in children:
                        child.terminate()
                    parent.terminate()
                    mapping.status = "stopped"
                    self.logger.info(f"停止映射成功: {local_port}")
                    return True
                except Exception as e:
                    self.logger.error(f"停止映射失败: {str(e)}")
        return False

    def get_mapping_status(self, local_port: int) -> Optional[dict]:
        if local_port in self.mappings:
            mapping = self.mappings[local_port]
            if mapping.process:
                # 检查进程是否还在运行
                is_running = mapping.process.poll() is None
                return {
                    "local_port": mapping.local_port,
                    "remote_host": mapping.remote_host,
                    "remote_port": mapping.remote_port,
                    "status": "running" if is_running else "stopped",
                    "start_time": mapping.start_time.isoformat(),
                }
        return None 