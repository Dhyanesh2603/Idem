from typing import Any, Dict, List, Optional
from pydantic import BaseModel

class PushOperation(BaseModel):
    operation_id: str
    entity_type: str
    entity_id: str
    operation_type: str
    payload: Dict[str, Any]
    timestamp: str

class PushResponse(BaseModel):
    success: bool
    operation_id: str
    message: str

class PullResponse(BaseModel):
    tasks: List[Dict[str, Any]]
    categories: List[Dict[str, Any]]
    server_timestamp: str
