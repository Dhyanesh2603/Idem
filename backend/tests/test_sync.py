import uuid
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)

def test_sync_push_and_pull():
    task_id = str(uuid.uuid4())
    op_id = str(uuid.uuid4())
    now_str = datetime.now(timezone.utc).isoformat()

    # 1. Push CREATE task
    push_res = client.post(
        "/api/sync/push",
        headers={"X-Idempotency-Key": op_id},
        json={
            "operation_id": op_id,
            "entity_type": "task",
            "entity_id": task_id,
            "operation_type": "CREATE",
            "payload": {
                "id": task_id,
                "title": "Backend Sync Test Task",
                "description": "Verifying sync engine",
                "is_completed": False,
                "priority": "high",
                "created_at": now_str,
            },
            "timestamp": now_str,
        },
    )
    assert push_res.status_code == 200
    assert push_res.json()["success"] is True

    # 2. Test Idempotency: replay the same op_id
    replay_res = client.post(
        "/api/sync/push",
        headers={"X-Idempotency-Key": op_id},
        json={
            "operation_id": op_id,
            "entity_type": "task",
            "entity_id": task_id,
            "operation_type": "CREATE",
            "payload": {"title": "Replay"},
            "timestamp": now_str,
        },
    )
    assert replay_res.status_code == 200
    assert "idempotent" in replay_res.json()["message"]

    # 3. Pull deltas
    pull_res = client.get("/api/sync/pull")
    assert pull_res.status_code == 200
    tasks = pull_res.json()["tasks"]
    matching = [t for t in tasks if t["id"] == task_id]
    assert len(matching) == 1
    assert matching[0]["title"] == "Backend Sync Test Task"
