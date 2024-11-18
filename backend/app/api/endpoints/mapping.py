from fastapi import APIRouter, HTTPException
from typing import Dict, List
from pydantic import BaseModel

router = APIRouter()
mapper = SocatMapper()
monitor = TrafficMonitor()

class MappingRequest(BaseModel):
    local_port: int
    remote_host: str
    remote_port: int

@router.post("/mappings")
async def create_mapping(mapping: MappingRequest):
    success = mapper.create_mapping(
        mapping.local_port,
        mapping.remote_host,
        mapping.remote_port
    )
    if not success:
        raise HTTPException(status_code=400, detail="创建映射失败")
    return {"status": "success"}

@router.delete("/mappings/{local_port}")
async def stop_mapping(local_port: int):
    success = mapper.stop_mapping(local_port)
    if not success:
        raise HTTPException(status_code=404, detail="映射不存在或停止失败")
    return {"status": "success"}

@router.get("/mappings/{local_port}/status")
async def get_mapping_status(local_port: int):
    status = mapper.get_mapping_status(local_port)
    if not status:
        raise HTTPException(status_code=404, detail="映射不存在")
    
    # 添加流量统计信息
    mapping = mapper.mappings.get(local_port)
    if mapping and mapping.process:
        traffic_stats = monitor.update_traffic_stats(local_port, mapping.process)
        if traffic_stats:
            status["traffic"] = traffic_stats
            
    return status 