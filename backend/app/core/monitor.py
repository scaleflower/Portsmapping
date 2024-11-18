import psutil
from typing import Dict, Optional
from datetime import datetime

class TrafficMonitor:
    def __init__(self):
        self.stats: Dict[int, Dict] = {}

    def update_traffic_stats(self, local_port: int, process: Optional[subprocess.Popen]):
        if not process:
            return None
            
        try:
            # 获取进程的网络连接信息
            process_info = psutil.Process(process.pid)
            connections = process_info.connections()
            
            # 统计连接数和流量
            stats = {
                "connections": len(connections),
                "bytes_sent": 0,
                "bytes_recv": 0,
                "update_time": datetime.now().isoformat()
            }
            
            # 获取进程的网络IO统计
            net_io = process_info.io_counters()
            if net_io:
                stats["bytes_sent"] = net_io.write_bytes
                stats["bytes_recv"] = net_io.read_bytes
            
            self.stats[local_port] = stats
            return stats
            
        except Exception as e:
            logging.error(f"获取流量统计失败: {str(e)}")
            return None 