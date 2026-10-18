# Offline Storage, Synchronization, and Conflict Resolution

Obsidian Slate is engineered under a strict **Local-First, Offline-ByDefault** architectural philosophy. The network is treated solely as an asynchronous transport layer rather than a synchronous blocker.

---

## 1. Offline Storage & Persistence (25% Weight)

### Architecture
- **Single Source of Truth**: All user operations (create, update, complete, snooze, reorder, delete) read and write directly to an embedded local SQLite database managed via **Drift ORM**.
- **Cross-Platform Storage Strategy**:
  - **Android**: Persisted in the app's sandboxed private internal files directory (`/data/user/0/com.obsidian.slate.obsidian_slate/databases/obsidian_slate.sqlite`).
  - **Windows Desktop**: Persisted in `%APPDATA%\ObsidianSlate\obsidian_slate.sqlite`.
  - **Linux Desktop**: Persisted in `~/.local/share/ObsidianSlate/obsidian_slate.sqlite`.
- **Relational Integrity**:
  - `tasks`: Core task attributes (UUID primary key, title, description, priority, deadline, category_id, order_index, is_focus, is_completed, completed_at, is_deleted, server_version, sync_status).
  - `categories`: User categories with distinct hex color tokens and icons.
  - `task_dependencies`: Directional prerequisite blocker relationships.
  - `sync_queue`: Persistent queue tracking mutations pending cloud upload.
  - `sync_history`: Complete audit trail of sync runs (timestamp, duration, processed count, status, errors).
- **Reactive UI**: Flutter widgets subscribe to reactive database streams (`watchTodayTasks()`, `watchInboxTasks()`). UI components reflect changes in < 16ms without waiting for HTTP handshakes.

---

## 2. Synchronization Engine (30% Weight)

The synchronization pipeline is coordinated by `SyncEngine` and `SyncQueueRepository`:

```
┌─────────────────────────────────────────────────────────────┐
│                      FLUTTER CLIENT                         │
│                                                             │
│  [User Action] ──► [Drift SQLite DB]                        │
│                           │                                 │
│                           ▼ (atomic transaction)            │
│                  [Persistent sync_queue]                    │
│                           │                                 │
│  [Connectivity Probe] ──► [SyncEngine]                      │
│                           │                                 │
│                           ├── 1. Push Queue (Sequential)   │
│                           └── 2. Pull Server Deltas (LWW)   │
└───────────────────────────┼─────────────────────────────────┘
                            │ HTTPS / REST (Idempotent)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   FASTAPI BACKEND SERVER                    │
│                                                             │
│   /api/v1/sync/push ──► Verify JWT & Idempotency Key       │
│                     ──► Execute LWW Conflict Logic          │
│                     ──► Return Server Versions              │
│                                                             │
│   /api/v1/sync/pull ──► Query tasks modified since cursor   │
│                     ──► Return delta updates & tombstones   │
└─────────────────────────────────────────────────────────────┘
```

### Queue Guarantees
1. **FIFO Sequential Draining**: Offline mutations are pushed in order of local creation to preserve user intent (e.g., creation followed by edit).
2. **Persistent Across Restarts**: The queue is stored in SQLite table `sync_queue`. If the user kills the app or the device powers off mid-sync, all uncommitted changes remain intact and resume automatically upon next launch.
3. **Exponential Backoff**: If the remote server returns a `5xx` or connection timeout, the sync engine applies an exponential backoff schedule ($2^n$ seconds: 1s, 2s, 4s, 8s, up to 60s) to eliminate battery drain and server flooding.

---

## 3. Conflict Resolution & Duplicate Prevention

### Last-Write-Wins (LWW) Algorithm
When multiple devices modify the same record, conflicts are deterministically resolved using UTC ISO-8601 timestamps and atomic server version counters:

1. **Client Push**:
   - The client sends its mutation with `updated_at` (UTC timestamp) and current `server_version`.
   - The server compares the client's `updated_at` against the existing database record's `updated_at`.
   - If `client.updated_at >= server.updated_at`, the client mutation is accepted, server version is incremented, and updated timestamp saved.
   - If `client.updated_at < server.updated_at`, the server's version is newer; the server retains its state and rejects stale client overwrite.

2. **Client Pull**:
   - The client polls `/api/v1/sync/pull?since={last_sync_timestamp}`.
   - For every remote task received, if `remote.updated_at > local.updated_at`, the local SQLite record is updated and `sync_status` set to `synced`.
   - Soft deletes (`is_deleted: true`) propagate tombstones across devices cleanly without orphaned foreign keys.

### Duplicate Prevention
- **Client-Generated UUIDv4**: Every entity receives an immutable UUIDv4 upon local instantiation. This ID serves as the primary key both locally and remotely, guaranteeing that retrying an insert cannot spawn duplicate rows.
- **HTTP Idempotency Keys**: Network requests carry `X-Idempotency-Key: {operation_id}`. Retried requests are recognized by the server and return the cached successful response without duplicate side effects.

---

## 4. Crash Recovery & Resilience

- **Atomic Transactions**: Every local entity update and its corresponding `sync_queue` enqueue statement execute inside a single SQLite transaction (`db.transaction(...)`). Either both succeed or neither does.
- **In-Flight Recovery**: When the app starts, any operations left in status `in_flight` (from an abrupt OS process termination) are automatically rolled back to `pending` and retried upon network availability.
