# Database Architecture & Schema: Drift (SQLite)

Obsidian Slate implements an offline-first architecture where the local SQLite database is the single source of truth for the user interface. Network synchronization acts as a background transport layer, never as a blocker for user interactions.

---

## 1. Architectural Philosophy

- **Zero UI-Layer SQL**: All database operations are encapsulated behind clean repository interfaces (`TaskRepository`, `CategoryRepository`, `SyncQueueRepository`). The UI layer consumes reactive Dart streams (`Stream<List<TaskModel>>`) and never interacts with Drift or SQL directly.
- **Immediate Local Persistence**: Every mutation (create, edit, delete, reorder, complete) commits locally to SQLite immediately. Optimistic UI is backed by atomic disk writes.
- **Decoupled Domain Entities**: The domain models (`TaskModel`, `CategoryModel`, `SyncOperation`) are pure Dart classes decoupled from the generated Drift data classes (`TaskEntry`, `CategoryEntry`). This protects the business logic and UI layer from database refactoring.
- **Soft Deletion for Distributed Sync**: Entities are marked with `is_deleted = true` instead of being hard-deleted immediately, allowing sync deletion deltas to propagate cleanly across multiple devices.

---

## 2. Relational Schema & Tables

### `Tasks`
Primary entity storing tasks, scheduling metadata, time tracking, and priority levels.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Client-generated UUID v4 |
| `title` | `TEXT` | `NOT NULL, max: 500` | Task title |
| `description` | `TEXT` | `DEFAULT ''` | Markdown body notes / checklists |
| `is_completed` | `BOOLEAN` | `DEFAULT FALSE` | Completion status |
| `completed_at` | `DATETIME`| `NULLABLE` | Timestamp of completion |
| `priority` | `TEXT` | `DEFAULT 'none'` | `urgent`, `high`, `medium`, `low`, `none` |
| `deadline` | `DATETIME`| `NULLABLE` | Scheduled date or deadline |
| `category_id` | `TEXT` | `NULLABLE` | Foreign key to `Categories.id` |
| `order_index` | `REAL` | `DEFAULT 0.0` | Fractional ordering index for reordering |
| `is_focus` | `BOOLEAN` | `DEFAULT FALSE` | Flag for Today's Focus workspace |
| `recurring_rule`| `TEXT` | `DEFAULT 'none'` | `none`, `daily`, `weekdays`, `weekly`, `monthly` |
| `parent_task_id`| `TEXT` | `NULLABLE` | Parent task ID for nested subtasks |
| `estimated_minutes` | `INT` | `DEFAULT 0` | Planned duration |
| `time_spent_minutes`| `INT` | `DEFAULT 0` | Logged duration |
| `created_at` | `DATETIME`| `NOT NULL` | Local creation timestamp |
| `updated_at` | `DATETIME`| `NOT NULL` | Last local modification timestamp |
| `server_version` | `INT` | `DEFAULT 1` | Optimistic concurrency version |
| `is_deleted` | `BOOLEAN` | `DEFAULT FALSE` | Soft delete flag |
| `sync_status` | `TEXT` | `DEFAULT 'pending'` | `synced`, `pending`, `failed` |

### `Categories`
Organizes tasks into projects, contexts, or tags.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 |
| `name` | `TEXT` | `NOT NULL, max: 100` | Display name |
| `color_hex` | `TEXT` | `DEFAULT '#94A3B8'` | Color badge hex |
| `icon_name` | `TEXT` | `DEFAULT 'tag'` | Lucide icon identifier |
| `created_at` | `DATETIME`| `NOT NULL` | Timestamp |
| `updated_at` | `DATETIME`| `NOT NULL` | Timestamp |
| `is_deleted` | `BOOLEAN` | `DEFAULT FALSE` | Soft delete flag |
| `sync_status` | `TEXT` | `DEFAULT 'pending'` | Sync status |

### `TaskDependencies`
Enforces directed prerequisite graphs between tasks.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 |
| `blocker_task_id`| `TEXT` | `NOT NULL` | Task that must finish first |
| `blocked_task_id`| `TEXT` | `NOT NULL` | Task that cannot start until blocker finishes |
| `created_at` | `DATETIME`| `NOT NULL` | Timestamp |
| `is_deleted` | `BOOLEAN` | `DEFAULT FALSE` | Soft delete flag |

### `SyncQueue`
The persistent heartbeat of offline-first synchronization.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 |
| `entity_type` | `TEXT` | `NOT NULL` | `'task'`, `'category'`, `'dependency'` |
| `entity_id` | `TEXT` | `NOT NULL` | Target entity ID |
| `operation_type`| `TEXT` | `NOT NULL` | `'CREATE'`, `'UPDATE'`, `'DELETE'`, `'COMPLETE'`, `'REORDER'` |
| `payload` | `TEXT` | `NOT NULL` | Serialized JSON mutation payload |
| `attempts` | `INT` | `DEFAULT 0` | Retry counter |
| `max_attempts` | `INT` | `DEFAULT 5` | Maximum retry threshold |
| `next_retry_at`| `DATETIME`| `NULLABLE` | Exponential backoff scheduled timestamp |
| `created_at` | `DATETIME`| `NOT NULL` | Timestamp queued |
| `status` | `TEXT` | `DEFAULT 'pending'` | `'pending'`, `'in_flight'`, `'failed'`, `'completed'` |
| `last_error` | `TEXT` | `NULLABLE` | Error diagnostics |

### `SyncHistory`
Audit log of background and manual synchronization runs.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 |
| `timestamp` | `DATETIME`| `NOT NULL` | Sync execution time |
| `status` | `TEXT` | `NOT NULL` | `'success'`, `'failure'` |
| `changes_count` | `INT` | `DEFAULT 0` | Number of changes pushed/pulled |
| `error_message` | `TEXT` | `NULLABLE` | Detailed exception message if failed |

### `DailyPlans`
Preserves morning planning sessions and mindful workload limits.

| Column | Type | Constraints / Defaults | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUID v4 |
| `plan_date` | `TEXT` | `NOT NULL` | Date in `YYYY-MM-DD` format |
| `target_task_count`| `INT` | `DEFAULT 3` | Recommended intentional workload count |
| `reflection_notes` | `TEXT` | `NULLABLE` | Evening reflection notes |
| `is_completed` | `BOOLEAN` | `DEFAULT FALSE` | Status flag |
| `created_at` | `DATETIME`| `NOT NULL` | Timestamp |

---

## 3. Concurrency, WAL & Foreign Keys

On startup, `MigrationStrategy.beforeOpen` configures:
```sql
PRAGMA foreign_keys = ON;
```
Ensuring relational integrity across dependencies and categories. SQLite Write-Ahead Logging (WAL) is enabled on desktop and mobile platforms for concurrent reads while writes are being executed in background isolates.
