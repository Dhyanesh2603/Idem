# Obsidian Slate Synchronization Server: API Reference

The Obsidian Slate backend is built with FastAPI, SQLAlchemy, and JWT authentication. It is specifically designed to support idempotent, high-concurrency offline-first synchronization with Last-Write-Wins (LWW) conflict handling.

---

## 1. Base URL & Protocol

- **Local Development**: `http://127.0.0.1:8000/api`
- **Format**: JSON (`Content-Type: application/json`, `Accept: application/json`)
- **Authentication**: Bearer Token (`Authorization: Bearer <token>`)

---

## 2. Authentication Endpoints

### Register User
`POST /api/auth/register`

Creates a new user profile with bcrypt-hashed credentials.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com"
}
```

---

### Login & Issue JWT
`POST /api/auth/login`

Verifies user password and returns an access token valid for 7 days.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6...",
  "token_type": "bearer"
}
```

---

## 3. Synchronization Endpoints

### Push Operation
`POST /api/sync/push`

Pushes a single queued mutation from client to server. Supports idempotent replay via `X-Idempotency-Key`.

**Headers:**
- `X-Idempotency-Key`: Client-generated UUID string corresponding to `operation_id`.

**Request Body:**
```json
{
  "operation_id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
  "entity_type": "task",
  "entity_id": "c9a646d3-9c61-4cc9-bc9f-1d89a4ffef7b",
  "operation_type": "CREATE",
  "payload": {
    "id": "c9a646d3-9c61-4cc9-bc9f-1d89a4ffef7b",
    "title": "Build Flutter offline sync engine",
    "description": "Clean architecture repository pattern",
    "is_completed": false,
    "completed_at": null,
    "priority": "urgent",
    "deadline": "2026-10-20T18:00:00Z",
    "is_focus": true,
    "created_at": "2026-10-18T10:00:00Z"
  },
  "timestamp": "2026-10-18T10:00:00Z"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "operation_id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
  "message": "Operation committed successfully"
}
```

**Conflict Response (409 Conflict):**
Returned if server holds a newer mutation than client `timestamp`.
```json
{
  "detail": {
    "id": "c9a646d3-9c61-4cc9-bc9f-1d89a4ffef7b",
    "title": "Server Updated Title",
    "description": "Modified on another client",
    "is_completed": true,
    "updated_at": "2026-10-18T11:30:00Z",
    "server_version": 3
  }
}
```

---

### Pull Deltas
`GET /api/sync/pull`

Retrieves all entities updated since an optional ISO-8601 timestamp.

**Query Parameters:**
- `since` (optional, string): ISO-8601 timestamp string (e.g., `2026-10-18T00:00:00Z`).

**Response (200 OK):**
```json
{
  "tasks": [
    {
      "id": "c9a646d3-9c61-4cc9-bc9f-1d89a4ffef7b",
      "title": "Build Flutter offline sync engine",
      "description": "Clean architecture repository pattern",
      "is_completed": false,
      "priority": "urgent",
      "deadline": "2026-10-20T18:00:00Z",
      "updated_at": "2026-10-18T10:00:00Z",
      "server_version": 2,
      "is_deleted": false
    }
  ],
  "categories": [],
  "server_timestamp": "2026-10-18T14:30:00Z"
}
```
