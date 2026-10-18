from datetime import datetime, timezone
import uuid
from sqlalchemy import Column, String, Boolean, DateTime, Float, Integer, ForeignKey
from backend.app.core.database import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    title = Column(String(500), nullable=False)
    description = Column(String, default="")
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime, nullable=True)
    priority = Column(String, default="none")
    deadline = Column(DateTime, nullable=True)
    category_id = Column(String, nullable=True)
    order_index = Column(Float, default=0.0)
    is_focus = Column(Boolean, default=False)
    recurring_rule = Column(String, default="none")
    parent_task_id = Column(String, nullable=True)
    estimated_minutes = Column(Integer, default=0)
    time_spent_minutes = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    server_version = Column(Integer, default=1)
    is_deleted = Column(Boolean, default=False)

    def to_dict(self):
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "is_completed": self.is_completed,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "priority": self.priority,
            "deadline": self.deadline.isoformat() if self.deadline else None,
            "category_id": self.category_id,
            "order_index": self.order_index,
            "is_focus": self.is_focus,
            "recurring_rule": self.recurring_rule,
            "parent_task_id": self.parent_task_id,
            "estimated_minutes": self.estimated_minutes,
            "time_spent_minutes": self.time_spent_minutes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "server_version": self.server_version,
            "is_deleted": self.is_deleted,
            "sync_status": "synced"
        }
