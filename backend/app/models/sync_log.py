from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime
from backend.app.core.database import Base

class SyncLog(Base):
    __tablename__ = "sync_logs"

    id = Column(String, primary_key=True)
    entity_type = Column(String, nullable=False)
    entity_id = Column(String, nullable=False, index=True)
    operation_type = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
