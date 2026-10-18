# Obsidian Slate: Offline-First Calm Productivity Workstation

Obsidian Slate is a commercial-grade, offline-first productivity application and synchronization server built from the ground up to reduce cognitive overhead, eliminate visual clutter, and help users focus on intentional daily work.

Designed around the "Obsidian Slate" design system, the application replaces noisy dashboards, neon gradients, and gamified animations with quiet typography, meaningful whitespace, and instant local-first responsiveness across Android, Windows Desktop, and Linux Desktop from a single Flutter codebase.

---

## 1. Project Philosophy

Most modern productivity applications suffer from cognitive bloat. They force users into complex hierarchical dashboards, bombard them with statistics, and make task management feel like maintaining a secondary spreadsheet.

Obsidian Slate is guided by three product principles:
1. **The Interface Must Disappear**: The user opens the workstation to focus on *what to do next*, not to admire a grid of metrics cards.
2. **Offline is the Default, Not a Fallback**: Every mutation commits to local storage in milliseconds. The network is treated solely as an asynchronous transport layer.
3. **Intentional Workload Limits**: Overwhelm is prevented at the root by promoting a daily planning session that encourages users to commit to 3 to 5 core priorities for today.

---

## 2. Features

### Mandatory & Core Features
- **Offline First**: All task CRUD, reordering, and status changes succeed immediately without network access.
- **Persistent Local Database**: Backed by Drift (SQLite) with relational schema definitions, migrations, and reactive streams.
- **Task Management**: Title, markdown notes, deadline scheduling, priority levels (Urgent, High, Medium, Low), and category tags.
- **Connectivity Detection**: Integrated with `connectivity_plus` and active reachability probes to detect genuine internet access.
- **Persistent Synchronization Queue**: Operation queue survives crashes, process kills, and device restarts.
- **Retry Strategy**: Automated exponential backoff (1s, 2s, 4s, 8s, 16s) preventing network flooding.
- **Conflict Resolution**: Last-Write-Wins (LWW) resolution comparing ISO-8601 timestamps and optimistic server versions.
- **Idempotency & Duplicate Prevention**: Client-generated UUIDs and `X-Idempotency-Key` headers prevent record duplication on retried requests.
- **Responsive Layout**: Dedicated Desktop Sidebar with keyboard navigation and thumb-friendly Mobile Navigation Bar.

### Bonus Features
- **Recurring Tasks**: Automatic computation and spawning of subsequent cycles (Daily, Weekdays, Weekly, Monthly) upon task completion.
- **Drag and Drop Reordering**: Reorder tasks with fractional order indices persisted to disk and synced across clients.
- **Task Dependencies**: Prerequisite blocker graphs preventing premature task execution and surfacing dependency warnings.
- **Multi-Device Sync**: Cross-platform delta synchronization between mobile, desktop, and web clients.
- **Sync History Audit Log**: Visual inspection of background and manual synchronization runs.

### Premium Productivity Features
- **Focus Mode**: Minimalist full-screen interface featuring large typography, zero distractions, and an integrated session timer.
- **Daily Planning Session**: Morning workflow prompting users to select a realistic workload (3 to 5 tasks) to reduce overwhelm.
- **Smart Inbox**: Rapid capture mechanism designed to record thoughts and tasks in under three seconds without forced categorization.
- **Deadline Load Balancer**: Visual timeline indicating days with excessive task volume and offering one-tap load balancing.
- **Smart Snooze**: Quick actions to defer tasks to Tomorrow, Next Week, or Next Monday.
- **Recovery Assistant**: Guilt-free reset tool for overdue tasks that assists in clearing mental backlogs without friction.
- **Obsidian Slate Accent Packs**: 7 curated accent palettes (Forest, Ocean, Amber, Burgundy, Lavender, Slate, Monochrome) that strictly tint interactive feedback while preserving neutral monochrome surfaces.

---

## 3. Technology Stack

### Frontend (Flutter Client)
- **Framework**: Flutter 3.38+ / Dart 3.10+
- **State Management**: Riverpod 3 (`Notifier`, `NotifierProvider`, `StreamProvider`)
- **Navigation & Routing**: GoRouter with `StatefulShellRoute`
- **Local Persistence**: Drift (SQLite) with native isolates
- **Networking**: Dio with custom interceptors and idempotency injection
- **Icons**: Lucide Icons
- **Typography**: Geist (with Inter fallback)
- **Motion**: Standard cubic motion tokens bounded strictly between 150ms and 250ms

### Backend (Synchronization Server)
- **Framework**: FastAPI (Python 3.13+)
- **ORM & Database**: SQLAlchemy with SQLite (default) and PostgreSQL compatibility
- **Authentication**: JWT (JSON Web Tokens) with bcrypt password hashing
- **Data Validation**: Pydantic v2
- **Testing**: pytest and httpx

---

## 4. Architectural Overview

The application follows a strict Feature-First Clean Architecture where domain models and business logic remain decoupled from UI and SQL storage details.

```
Flutter UI Layer (Riverpod 3)
           │
           ▼
    Repository Layer (TaskRepository, CategoryRepository)
           │
     ┌─────┴────────────────┐
     ▼                      ▼
Local SQLite DB       Persistent Sync Queue
(Drift)               (sync_queue table)
     │                      │
     ▼                      ▼
Reactive Streams       SyncEngine
(Stream<List<Task>>)        │
                            ▼
                     API Client (Dio)
                            │
                            ▼
                  FastAPI Sync Server
```

### Why This Architecture Was Chosen

1. **Why Drift over raw SQLite?**
   Raw SQL string queries scattered throughout Flutter applications cause runtime type errors, make refactoring fragile, and complicate schema migrations. Drift provides compile-time type-safe queries, Dart-idiomatic table definitions, and reactive stream subscriptions (`watchTasks()`) that automatically notify UI widgets whenever the underlying database tables change.

2. **Why a Persistent Sync Queue?**
   In-memory queues lose un-synced operations when an application process is terminated in the background by the mobile operating system. By writing mutations to a SQLite table (`sync_queue`) before completing the user's action, operations are guaranteed to survive application crashes, power loss, and device reboots.

3. **Why Last-Write-Wins (LWW) with Idempotency Keys?**
   Distributed sync without a single source of truth often results in duplicate tasks when network requests time out during response transmission. By assigning UUIDs on the client and passing an `X-Idempotency-Key`, the backend guarantees that retrying an operation is completely idempotent. Conflicts are resolved quietly and predictably by comparing high-resolution timestamps.

---

## 5. Directory Structure

```
d:/gdg_app/
├── lib/
│   ├── main.dart                          # Application entry point
│   ├── core/
│   │   ├── theme/                         # Obsidian Slate tokens, typography, accent packs
│   │   ├── router/                        # GoRouter declarative shell navigation
│   │   ├── services/                      # Connectivity reachability service
│   │   └── network/                       # Dio ApiClient and domain exceptions
│   ├── shared/
│   │   └── widgets/                       # Responsive desktop sidebar & mobile shell
│   ├── database/
│   │   ├── app_database.dart              # Drift database declaration and migrations
│   │   ├── tables/                        # Drift schema tables (Tasks, Categories, SyncQueue)
│   │   └── connection/                    # Cross-platform SQLite connection factory
│   └── features/
│       ├── today/                         # Today workspace, quick add, daily planning
│       ├── inbox/                         # Smart inbox rapid capture
│       ├── calendar/                      # Timeline & deadline load balancer
│       ├── focus/                         # Distraction-free focus mode with timer
│       ├── review/                        # Weekly review & recovery assistant
│       ├── settings/                      # Accent pack selector & sync diagnostics
│       ├── tasks/                         # Task domain models, repositories, detail sheet
│       ├── categories/                    # Category domain models and repository
│       └── sync/                          # Persistent queue repository & SyncEngine
├── backend/
│   ├── requirements.txt                   # Backend dependencies
│   ├── app/
│   │   ├── main.py                        # FastAPI entry point & CORS configuration
│   │   ├── core/                          # Config, security (JWT/bcrypt), database session
│   │   ├── models/                        # SQLAlchemy relational models
│   │   ├── schemas/                       # Pydantic v2 validation models
│   │   └── api/                           # Auth and Sync route handlers
│   └── tests/                             # Pytest test suite for sync and auth
├── docs/
│   ├── Architecture.md                    # In-depth architectural specification
│   ├── ImplementationNotes.md             # Low-level engineering decisions and trade-offs
│   ├── Theme.md                           # Obsidian Slate design system specification
│   ├── API.md                             # REST & Sync protocol documentation
│   └── Database.md                        # Drift relational schema specification
└── test/
    ├── widget_test.dart                   # Smoke and UI integration test
    └── unit/
        ├── theme_test.dart                # Design tokens & accent packs test suite
        ├── database_test.dart             # Drift repository & task dependency tests
        └── sync_engine_test.dart          # SyncEngine, retry, and LWW conflict tests
```

---

## 6. Installation & Setup

### Prerequisites
- Flutter SDK (version 3.38.0 or higher)
- Dart SDK (version 3.10.0 or higher)
- Python (version 3.11 or higher)
- Git

### Cloning the Repository
```bash
git clone https://github.com/dhyan-dev/obsidian-slate.git
cd obsidian-slate
```

---

## 7. Running the FastAPI Backend

1. Navigate to the backend directory and install dependencies:
```bash
python -m pip install -r backend/requirements.txt
```

2. Run backend test suite:
```bash
python -m pytest backend/tests/
```

3. Launch the FastAPI synchronization server:
```bash
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```

The interactive OpenAPI documentation is available at:
`http://127.0.0.1:8000/api/docs`

---

## 8. Running the Flutter Application

1. Resolve Flutter package dependencies:
```bash
dart pub get
```

2. Run the complete automated test suite:
```bash
flutter test
```

3. Run static analysis to verify code quality:
```bash
flutter analyze lib/
```

4. Launch the application:
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```
- **Linux Desktop**:
  ```bash
  flutter run -d linux
  ```
- **Android Device or Emulator**:
  ```bash
  flutter run -d android
  ```
- **Web Browser (Preview)**:
  ```bash
  flutter run -d chrome
  ```

---

## 9. Desktop Experience & Keyboard Navigation

The desktop implementation provides an optimized workstation environment rather than stretching mobile views:
- **Persistent Sidebar Navigation**: Stays accessible at all times without taking over task context.
- **Global Keyboard Shortcuts**:
  - `Cmd / Ctrl + 1`: Navigate to Today Workspace
  - `Cmd / Ctrl + 2`: Navigate to Smart Inbox
  - `Cmd / Ctrl + 3`: Navigate to Calendar Timeline
  - `Cmd / Ctrl + 4`: Navigate to Weekly Review
  - `Cmd / Ctrl + 5`: Navigate to Settings & Sync Diagnostics
  - `Cmd / Ctrl + F`: Toggle Distraction-Free Focus Mode
  - `Enter`: Instant task creation from Quick Add bar

---

## 10. Future Improvements
- End-to-end client-side encryption for sensitive task descriptions.
- WebAssembly (Wasm) compile target optimization.
- Native desktop system tray minimizer with background sync scheduler.
- Natural language parsing for deadline extraction ("Tomorrow at 5pm").

---

## 11. License
This project is licensed under the MIT License. See the LICENSE file for details.
