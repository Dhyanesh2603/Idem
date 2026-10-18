from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session
from backend.app.core.database import get_db
from backend.app.models.task import Task
from backend.app.models.category import Category
from backend.app.models.sync_log import SyncLog
from backend.app.schemas.sync import PushOperation, PushResponse, PullResponse

router = APIRouter(prefix="/sync", tags=["sync"])

def parse_iso(dt_str: Optional[str]) -> Optional[datetime]:
    if not dt_str:
        return None
    try:
        return datetime.fromisoformat(dt_str)
    except Exception:
        return None

@router.post("/push", response_model=PushResponse)
def push_operation(
    op: PushOperation,
    db: Session = Depends(get_db),
    x_idempotency_key: Optional[str] = Header(None),
):
    op_id = x_idempotency_key or op.operation_id

    # 1. Idempotency Check: if this exact operation was already processed, return 200
    existing_log = db.query(SyncLog).filter(SyncLog.id == op_id).first()
    if existing_log:
        return PushResponse(
            success=True,
            operation_id=op_id,
            message="Already processed (idempotent)",
        )

    client_dt = parse_iso(op.timestamp) or datetime.now(timezone.utc)
    payload = op.payload

    # 2. Process Task Mutations
    if op.entity_type == "task":
        task = db.query(Task).filter(Task.id == op.entity_id).first()

        if op.operation_type == "CREATE":
            if task:
                # Task already exists on server: Conflict check
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=task.to_dict(),
                )
            task = Task(
                id=op.entity_id,
                title=payload.get("title", ""),
                description=payload.get("description", ""),
                is_completed=payload.get("is_completed", False),
                completed_at=parse_iso(payload.get("completed_at")),
                priority=payload.get("priority", "none"),
                deadline=parse_iso(payload.get("deadline")),
                category_id=payload.get("category_id"),
                order_index=float(payload.get("order_index", 0.0)),
                is_focus=payload.get("is_focus", False),
                recurring_rule=payload.get("recurring_rule", "none"),
                parent_task_id=payload.get("parent_task_id"),
                estimated_minutes=int(payload.get("estimated_minutes", 0)),
                created_at=parse_iso(payload.get("created_at")) or client_dt,
                updated_at=client_dt,
                server_version=1,
                is_deleted=payload.get("is_deleted", False),
            )
            db.add(task)

        elif op.operation_type in ("UPDATE", "COMPLETE", "FORCE_UPDATE"):
            if not task:
                # If updating a non-existent task, treat as creation
                task = Task(
                    id=op.entity_id,
                    title=payload.get("title", ""),
                    description=payload.get("description", ""),
                    is_completed=payload.get("is_completed", False),
                    completed_at=parse_iso(payload.get("completed_at")),
                    priority=payload.get("priority", "none"),
                    deadline=parse_iso(payload.get("deadline")),
                    created_at=client_dt,
                    updated_at=client_dt,
                    server_version=1,
                )
                db.add(task)
            else:
                # Check Last-Write-Wins: if server was updated after client timestamp and not force update
                if op.operation_type != "FORCE_UPDATE" and task.updated_at and client_dt < task.updated_at.replace(tzinfo=timezone.utc if task.updated_at.tzinfo is None else None):
                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail=task.to_dict(),
                    )
                # Apply update
                if "title" in payload:
                    task.title = payload["title"]
                if "description" in payload:
                    task.description = payload["description"]
                if "is_completed" in payload:
                    task.is_completed = payload["is_completed"]
                if "completed_at" in payload:
                    task.completed_at = parse_iso(payload["completed_at"])
                if "priority" in payload:
                    task.priority = payload["priority"]
                if "deadline" in payload:
                    task.deadline = parse_iso(payload["deadline"])
                if "category_id" in payload:
                    task.category_id = payload["category_id"]
                if "order_index" in payload:
                    task.order_index = float(payload["order_index"])
                if "is_focus" in payload:
                    task.is_focus = payload["is_focus"]
                if "recurring_rule" in payload:
                    task.recurring_rule = payload["recurring_rule"]
                if "is_deleted" in payload:
                    task.is_deleted = payload["is_deleted"]
                task.updated_at = client_dt
                task.server_version += 1

        elif op.operation_type == "DELETE":
            if task:
                task.is_deleted = True
                task.updated_at = client_dt
                task.server_version += 1

    # 3. Process Category Mutations
    elif op.entity_type == "category":
        cat = db.query(Category).filter(Category.id == op.entity_id).first()
        if op.operation_type == "CREATE":
            if not cat:
                cat = Category(
                    id=op.entity_id,
                    name=payload.get("name", ""),
                    color_hex=payload.get("color_hex", "#94A3B8"),
                    icon_name=payload.get("icon_name", "tag"),
                    created_at=parse_iso(payload.get("created_at")) or client_dt,
                    updated_at=client_dt,
                    is_deleted=payload.get("is_deleted", False),
                )
                db.add(cat)
        elif op.operation_type in ("UPDATE", "FORCE_UPDATE"):
            if cat:
                if "name" in payload:
                    cat.name = payload["name"]
                if "color_hex" in payload:
                    cat.color_hex = payload["color_hex"]
                if "icon_name" in payload:
                    cat.icon_name = payload["icon_name"]
                cat.updated_at = client_dt
        elif op.operation_type == "DELETE":
            if cat:
                cat.is_deleted = True
                cat.updated_at = client_dt

    # 4. Log processed operation for idempotency
    log = SyncLog(
        id=op_id,
        entity_type=op.entity_type,
        entity_id=op.entity_id,
        operation_type=op.operation_type,
    )
    db.add(log)
    db.commit()

    return PushResponse(
        success=True,
        operation_id=op_id,
        message="Operation committed successfully",
    )

@router.get("/pull", response_model=PullResponse)
def pull_deltas(
    since: Optional[str] = None,
    db: Session = Depends(get_db),
):
    since_dt = parse_iso(since)
    task_query = db.query(Task)
    cat_query = db.query(Category)

    if since_dt:
        task_query = task_query.filter(Task.updated_at >= since_dt)
        cat_query = cat_query.filter(Category.updated_at >= since_dt)

    tasks = [t.to_dict() for t in task_query.all()]
    categories = [c.to_dict() for c in cat_query.all()]
    now_str = datetime.now(timezone.utc).isoformat()

    return PullResponse(
        tasks=tasks,
        categories=categories,
        server_timestamp=now_str,
    )
