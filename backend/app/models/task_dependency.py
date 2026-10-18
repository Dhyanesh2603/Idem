from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Boolean, DateTime
from backend.app.core.database import Base

class TaskDependency(Base):
    __tablename__ = "task_dependencies"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    blocker_task_id = Column(String, nullable=False, index=True)
    blocked_task_id = Column(String, nullable=False, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    is_deleted = Column(Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "blocker_task_id": self.blocker_task_id,
            "blocked_task_id": self.blocked_task_id,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "is_deleted": self.is_deleted,
        }
