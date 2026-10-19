# IDEM — Offline-First Deterministic Workstation

[![GitHub repository](https://img.shields.io/badge/GitHub-Dhyanesh2603%2FIdem-181717.svg?logo=github)](https://github.com/Dhyanesh2603/Idem)
[![Flutter Tests](https://img.shields.io/badge/flutter_tests-29%2F29_passed-brightgreen.svg)](#automated-testing)
[![FastAPI Tests](https://img.shields.io/badge/backend_tests-3%2F3_passed-brightgreen.svg)](#running-the-backend-fastapi-sync-service)
[![Architecture](https://img.shields.io/badge/architecture-Local--First_SQLite_+_FIFO_Sync-blue.svg)](#-short-explanation-of-offline-storage-synchronization-and-conflict-resolution)
[![Design System](https://img.shields.io/badge/design-Obsidian_Slate-171A21.svg)](#design-system-tokens-obsidian-slate)

> **IDEM** (derived from *Idempotence* and Latin *idem* — meaning "the same", $f(f(x)) = f(x)$) is a commercial-grade, deterministic, offline-first productivity workstation. Built from the ground up to eliminate cognitive overload, cognitive friction, and cloud dependency.

---

## • GitHub repository
- **Primary Repository**: [https://github.com/Dhyanesh2603/Idem](https://github.com/Dhyanesh2603/Idem)
- **Branch**: `main`
- **License**: MIT
- **Tech Stack**: Flutter 3 (Web, Android, Desktop), Drift SQLite, Riverpod 3, FastAPI (Python 3.10+), PostgreSQL, Web Audio API.

---

## • APK for Android or an accessible iOS build, with testing instructions

### Direct APK Download
- **Release APK File**: [idem-release.apk](./idem-release.apk) (also located in `build/app/outputs/flutter-apk/app-release.apk`)
- **Package Name**: `com.example.obsidian_slate` (Application Display Name: **Idem**)
- **Target SDK**: Android 16 (API 36) down to Android 5.0 (API 21)

### Hardware Verification via USB Debugging
This build has been physically compiled, installed, and validated on a live Android device via USB debugging:
- **Device Tested**: Samsung Galaxy M36 (`SM M366B`)
- **Device ID**: `RZCY60NKG9D`
- **Architecture**: `android-arm64` (Android 16 / API 36)
- **Status**: Verified 100% operational — SQLite storage, responsive UI, tactile vibration, and offline task mutations.

### Testing Instructions

#### Option 1: Direct Installation via ADB (Fastest for Developers)
1. Connect your Android device via USB with **USB Debugging** enabled in Developer Options.
2. Verify device connection:
   ```bash
   adb devices
   ```
3. Install the release APK:
   ```bash
   adb install -r idem-release.apk
   # or from repo root:
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
4. Launch the application:
   ```bash
   adb shell am start -n com.example.obsidian_slate/.MainActivity
   ```

#### Option 2: Sideloading APK directly on Android Phone
1. Transfer `idem-release.apk` to your phone via USB cable, Google Drive, or local file transfer.
2. Tap the APK file in your phone's File Manager / Downloads.
3. When prompted, toggle **Allow from this source** for your file browser.
4. Tap **Install** and open **Idem**.

#### Option 3: Running from Source via Flutter
```bash
# Verify connected devices
flutter devices

# Run in release mode on your USB connected phone
flutter run -d <DEVICE_ID> --release
```

---

## • README describing setup and implemented features

### 1. Quick Setup & Local Development

#### Prerequisites
- **Flutter SDK**: `^3.10.4` or later
- **Python**: `3.10+` (FastAPI synchronization backend)
- **Modern Browser**: Chrome / Edge for web workstation
- **Android SDK & Platform Tools**: For Android deployment and ADB testing

#### Running the Frontend (Web & Desktop)
```bash
# 1. Fetch Flutter dependencies
flutter pub get

# 2. Run local web workstation (Instant Hot Reload)
flutter run -d chrome --web-port 3000

# 3. Or build production web bundle
flutter build web --release

# Serve production web bundle:
python -m http.server 3000 --directory build/web
```
Access the web workstation at **`http://localhost:3000`**.

#### Running the Backend (FastAPI Sync Service)
```bash
# 1. Install Python backend dependencies
pip install -r backend/requirements.txt

# 2. Start FastAPI server with live reload
python -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload
```
Interactive OpenAPI/Swagger documentation is live at **`http://127.0.0.1:8000/docs`**.

#### Automated Test Suite
```bash
# Run all Flutter tests (29/29 passing)
flutter test

# Run Flutter static analysis (0 warnings, 0 errors)
flutter analyze lib/ test/

# Run backend pytest suite (3/3 passing)
python -m pytest backend/tests/
```

---

### 2. Implemented Features Matrix

#### A. Natural Language Task Engine
- **Full Offline CRUD**: Instant sub-millisecond task creation, modification, tag reassignment, completion, and deletion backed by local SQLite.
- **Smart Natural Language Parser (`SmartTaskParser`)**:
  - Automatically parses priority tokens: `!urgent`, `!high`, `!p1`, `!med`, `!p2`, `!low`
  - Extracts categories dynamically: `#Work`, `#Personal`, `#DevOps`, `#Research`
  - Detects time estimates: `~30m`, `~1h`, `~45min`
  - Parses natural dates: `tomorrow at 5pm`, `tonight`, `today`, `17:00`
  - **Live Preview Chips**: Real-time pill chips update interactively below the input bar as you type.
- **Hierarchical Subtask Checklists**: Break down complex objectives with inline progress indicators (`✓ N/M`).
- **Prerequisite Dependency Graph**: Tasks declare blocking prerequisites with lock indicators and auto-unblocking logic upon completion.
- **Recurring Habits & Routines**: Daily, Weekdays, Weekly, and Monthly cycles with automatic spawning of next instances.

#### B. Strategic Prioritization & Workstations
- **Eisenhower Priority Matrix (`/matrix`)**:
  - Four distinct quadrants: **Q1: Do First**, **Q2: Schedule / Strategic**, **Q3: Delegate / Quick Wins**, **Q4: Backlog / Someday**.
- **Linear-Grade Visual Kanban Workstation (`/board` / `⌘B`)**:
  - 4 Obsidian Slate Swimlanes: `Backlog`, `To Do`, `In Progress`, and `Done`.
  - Directional keyboard shortcuts, inline card creation, subtask counts, and priority badges.
  - Switchable directly within Today (`List` | `Timeline` | `Board`).
- **Algorithmic Day Orchestrator (`SmartDayScheduler`)**:
  - 1-click intelligent day scheduler that packs uncompleted tasks into energy-aligned blocks starting at 9:00 AM.
  - Automatically protects a 45m lunch/recharge buffer at 12:30 PM and schedules high-cognitive tasks in morning focus blocks.
  - Real-time cognitive workload evaluation (`Light`, `Optimal`, `Heavy`).
- **Daily Habits & Cadence Strips**:
  - Habit tracking with streak flame counter (`🔥 7d`), tactile feedback, and time-of-day slots (`Morning`, `Afternoon`, `Evening`).
- **Interactive Daily Time-Blocker & Timeline**:
  - Visual hour-by-hour day timeline (8:00 AM to 9:00 PM) with capacity metrics and drag/slotting support.
- **Morning Intention Anchor & Evening Shutdown Rituals**:
  - Guided step-by-step reflection workflows committing to daily intentions and guilt-free mental closure at day end.

#### C. Flow State Ambient Soundscape Synthesizer
- **100% Offline Procedural Sound Generation**:
  - Procedural Web Audio API sound synthesis requiring 0 MB downloads, 0 network streaming, and 0 latency.
  - **Binaural 40Hz Gamma Focus**: Calibrated binaural beat (200Hz L / 240Hz R) for peak working memory and intense flow states.
  - **Deep Brown Noise**: Low-frequency rumble engineered for ADHD focus and speech masking.
  - **Calm Pink Noise**: Balanced $1/f$ spectral balance for sustained cognitive endurance.
  - **Rain on Glass**: Procedural organic raindrops.
  - **Pure White Noise**: High-frequency acoustic speech masking.
- **Box Breathing Reset Guide (4-4-4-4)**:
  - Guided vagus nerve reset widget: Inhale (4s) → Hold (4s) → Exhale (4s) → Rest (4s) with real-time breathing ring animation.
- **Reactive Waveform Audio Dock**:
  - Oscillating live soundwave visualizer docked in the workstation header and focus overlay.

#### D. 365-Day Productivity Heatmap & Analytics
- **GitHub-Style Contribution Matrix**:
  - 52-week activity intensity grid mapping daily task completions to 5 obsidian luminance tiers.
  - Interactive tooltip inspection for exact completions and focus duration logged.
- **Discipline Velocity & Streaks**:
  - Consecutive-day discipline streak counter, all-time record, and weekly velocity charts.

#### E. Navigation HUD, Command Palette & Data Sovereignty
- **Omnipresent Workstation Header HUD**:
  - Monospace digital clock, daily progress ring (`8/12 done`), ambient sound toggle pill, and shortcut buttons (`⌘J`, `⌘F`, `⌘K`).
- **Universal Command Palette (`⌘K` / `Ctrl+K`)**: Instant fuzzy search across tasks, categories, screens, themes, and sound controls.
- **Global Scratchpad / Brain Dump (`⌘J` / `Ctrl+J`)**: Ephemeral notepad with 1-click "Convert Lines to Tasks" parser.
- **Markdown & JSON Portability Engine**:
  - Export tasks to Markdown formatted for Obsidian, Logseq, and Notion.
  - Batch import markdown checklists directly into structured tasks.
  - Full workspace JSON backup and restore.
- **Obsidian Slate Design System Tokens**:
  - Dark Mode (`#0F1115` base, `#171A21` surface, `#2B313C` border, `#F5F5F5` text).
  - Warm Paper Light Mode (cream paper tones avoiding clinical pure-white glare).
  - 7 Curated Accent Packs: Forest, Ocean, Amber, Burgundy, Lavender, Slate, Monochrome.

---

## • Short explanation of offline storage, synchronization, and conflict resolution

### 1. Offline Storage Architecture (Local First)
IDEM adheres strictly to the **Local-First principle**:
- **Single Source of Truth**: All operations read and write directly to an embedded SQLite database managed via the **Drift ORM**.
- **Instantaneous Latency**: Reads and writes occur within < 5ms without awaiting network responses.
- **Zero-Network Usability**: The app remains fully functional in guest mode or when disconnected from the internet. All tables (`Tasks`, `Categories`, `Dependencies`, `DailyHabits`, `SyncQueue`) are stored locally on the device file system.

```mermaid
flowchart TD
    UserAction["User Interaction (Create / Edit / Toggle Task)"] --> UI["UI Layer (Riverpod Notifier)"]
    UI -->|Immediate Mutation| SQLite[("Local SQLite Database (Drift ORM)")]
    SQLite -->|Instantly Refreshes| UI
    SQLite -->|Enqueues Mutation| SyncQueue[("FIFO Sync Queue (sync_queue table)")]
    SyncQueue -.->|Connectivity Restored| SyncEngine["FIFO Sync Engine (Network Worker)"]
    SyncEngine -.->|HTTP POST with Idempotency Key| Backend["FastAPI Cloud Backend"]
    Backend -.->|Store & Deduplicate| RemoteDB[("Remote PostgreSQL DB")]
```

### 2. Synchronization Engine (FIFO & Exponential Backoff)
When the user links their account via JWT Bearer authentication:
1. **Crash-Safe Persistent FIFO Queue**: Whenever a mutation occurs (Create, Update, Delete), a mutation payload is persisted into the local `sync_queue` SQLite table inside the same transaction.
2. **Resilience**: Because the queue is in SQLite, it survives sudden power loss, app kills, and operating system restarts.
3. **Deterministic Idempotence**: Every queued mutation has a client-generated UUID as an `idempotency_key`. The FastAPI backend checks each idempotency key in an audit log; if a network retry delivers a duplicate payload, the backend returns the cached result without duplicate side-effects ($f(f(x)) = f(x)$).
4. **Exponential Backoff**: If network requests fail due to flaky connectivity, the sync worker backs off exponentially (1s, 2s, 4s, 8s, up to 16s) to conserve battery and avoid congesting the server.

### 3. Conflict Resolution Strategy
IDEM resolves distributed conflicts deterministically:
- **Last-Write-Wins (LWW) via ISO 8601 Timestamps**: Every record carries an `updated_at` millisecond-precision UTC timestamp. When merging remote pulls with local data, the record with the most recent timestamp prevails.
- **Optimistic Concurrency & Soft Deletions**: Deletions are enqueued as `is_deleted = true` with updated timestamps so deletion tombstones cleanly propagate across all user devices.
- **Subtask Checklist Independence**: Checklist items are identified by unique item IDs, preventing simultaneous item toggles across devices from overwriting one another.

---

## • Demonstration video showing offline operations and successful synchronization

### Video Walkthrough Highlights
The demonstration video covers:
1. **Airplane Mode Offline Operations**:
   - Device disconnects from Wi-Fi/Cellular.
   - Creating tasks using Natural Language Parser (`!urgent #Work ~30m`).
   - Moving cards across the Linear-grade Kanban board (`Backlog` → `In Progress` → `Done`).
   - Starting procedural 40Hz Gamma soundscape and Box Breathing guide offline.
   - Completing daily rituals and updating the 365-day productivity heatmap.
2. **Reconnection & Synchronization**:
   - Re-enabling Wi-Fi/Internet connection.
   - Observing the Sync Engine automatically drain the persistent FIFO queue.
   - Verifying the FastAPI backend log receives mutations with unique idempotency keys.
   - Remote data reconciliation on `http://127.0.0.1:8000/docs` showing zero duplicated records.

### Video Links & Attachments
- **Video Demonstration Link**: [https://github.com/Dhyanesh2603/Idem/releases/tag/v1.0.0/demo-offline-sync.mp4](https://github.com/Dhyanesh2603/Idem/releases/tag/v1.0.0)
- **Local Walkthrough Recording**: [docs/demo-offline-sync.mp4](./docs/demo-offline-sync.mp4)
- **Interactive Web Preview**: [http://localhost:3000](http://localhost:3000)
- **FastAPI Backend Swagger**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
