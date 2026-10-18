# Obsidian Slate: Technical Implementation Notes

This document captures low-level architectural decisions, technical trade-offs, and implementation details established across development milestones.

---

## 1. Riverpod 3 State Management Architecture

During implementation, modern `Notifier<T>` and `NotifierProvider<T, State>` were selected across all feature layers rather than legacy `StateProvider` and `StateNotifier`.

### Rationale
- **Fine-Grained Encapsulation**: Each feature (`tasks`, `categories`, `theme`, `sync`) owns distinct notifiers that expose explicit mutation methods (`selectCategory`, `updateFilter`, `setThemeMode`) rather than allowing external callers to directly mutate raw state.
- **Synchronous Initialization & Lazy Async Hydration**: The `ThemeNotifier` immediately provides a non-blocking initial state (`ThemeMode.dark`, `AccentPack.forest`) and asynchronously hydrates persisted preferences from `SharedPreferences` without causing layout jank or blocking Flutter's first frame.

---

## 2. Drift SQLite Storage & Zero-Plugin Desktop Path Resolution

A critical challenge when building cross-platform Flutter desktop applications (Windows and Linux) is avoiding native plugin symlink or C++ toolchain lockouts in sandboxed developer environments.

### The Problem
When dependencies transitively import platform channel packages that require Windows build symlinks (such as `path_provider_windows`), test runners and builds can fail if Windows Developer Mode is disabled.

### The Solution: Direct OS Path Resolution
Instead of relying on platform channels for simple directory discovery, `DatabaseConnectionFactory` uses pure Dart standard libraries (`dart:io` and `package:path`):
- **Windows**: `Platform.environment['APPDATA'] / ObsidianSlate`
- **Linux**: `Platform.environment['HOME'] / .local/share/obsidian_slate`
- **macOS**: `Platform.environment['HOME'] / Library/Application Support/obsidian_slate`
- **Mobile/Testing**: Standard documents or in-memory fallback.

This guarantees:
1. Pure Dart execution speed without platform channel latency.
2. 100% test reliability with zero C++ plugin compilation overhead.
3. Standard OS-compliant directory placement across Linux and Windows.

---

## 3. Persistent Sync Queue Invariant

In Obsidian Slate, the UI **never** talks to the network directly. All mutations follow a strict one-way pipeline:

$$\text{User Action} \longrightarrow \text{TaskRepository} \longrightarrow \text{Local SQLite Write} \longrightarrow \text{SyncQueue Enqueue} \longrightarrow \text{UI Stream Emits}$$

### The Crash Recovery Guarantee
Because mutations are written to `sync_queue` table inside SQLite prior to returning to the caller:
- If the application crashes, the process is killed, or battery runs out, the operation is already persisted to disk.
- When the application starts up, the `SyncEngine` queries pending operations (`status in ('pending', 'failed')`) and resumes pushing operations in the exact chronological order of their creation.

---

## 4. Exponential Backoff Retry Strategy

When an operation fails due to network dropouts or timeout:
- Counter `attempts` increments by 1.
- Delay is computed as:
  $$\text{delay} = 2^{\text{attempts}} \text{ seconds}$$
- A scheduled timestamp `next_retry_at = now + delay` is recorded in SQLite.
- The `SyncEngine` query ignores records where `next_retry_at > now`, preventing network flooding or CPU spin loops while the device is in an unstable network zone.

---

## 5. Idempotent API & Duplicate Prevention

To solve the classic distributed systems problem where a network drops during an HTTP response, leading to duplicate records upon retry:
1. Every entity has a client-generated UUID v4 (`id`).
2. Every sync operation has a unique `operation_id` sent via `X-Idempotency-Key`.
3. The server checks the `sync_logs` table. If the `operation_id` has already been committed, the server returns `HTTP 200` with `Already processed (idempotent)`.
4. This ensures that retrying a sync operation 10 times produces the exact same server state as executing it once.

---

## 6. Last-Write-Wins (LWW) Conflict Resolution

When two clients update the same task concurrently:
- Each task tracks an ISO-8601 `updated_at` timestamp and an integer `server_version`.
- If the server has a newer record, it returns `HTTP 409 Conflict` containing the authoritative record.
- The `SyncEngine` inspects the server timestamp:
  - If the server's record is genuinely newer: the local database updates with the server data and marks the queue entry complete.
  - If the local record has a newer timestamp: the client issues a `FORCE_UPDATE` to bring the server up to date.
- All conflicts resolve automatically without disrupting the user with intrusive conflict popups.

---

## 7. Responsive Desktop & Mobile Differentiation

Mobile and Desktop layouts are handled using explicit responsive breakpoints (`≥ 768px` width):
- **Desktop**:
  - Persistent 230px left navigation sidebar with Lucide icons.
  - Global keyboard shortcuts (`Cmd/Ctrl + 1..5`, `Cmd/Ctrl + F`).
  - Wide layout with constrained readable line lengths (`maxWidth: 600px`).
  - Real-time sync status indicator at the sidebar footer.
- **Mobile**:
  - Clean bottom navigation bar (`NavigationBar`) with 5 destinations.
  - Thumb-friendly quick actions and bottom modal sheets for task editing and daily planning.
