# Testing & Evaluation Demonstration Guide

This guide provides end-to-end instructions for testing the **Obsidian Slate** application across Android and Desktop platforms, validating offline persistence, conflict handling, and video demonstration requirements.

---

## 1. Quick Testing Overview

| Feature | How to Test | Expected Result |
| :--- | :--- | :--- |
| **Offline Persistence** | Create/edit tasks with WiFi disconnected or Airplane Mode active. Close the app completely and restart. | All tasks and state remain intact. Nothing is lost. |
| **Connectivity Badge** | Toggle device network connection on/off. | Top-right pill updates from **"Synced"** / **"Queued"** to **"Offline"** in real time. |
| **Idempotent Sync** | Reconnect network with pending offline queue. | SyncEngine drains operations sequentially and status becomes **"Synced"**. No duplicate records appear. |
| **Conflict Resolution (LWW)** | Modify the same task from two clients with different timestamps. | The mutation with the latest timestamp prevails; stale overwrite is rejected. |
| **Drag & Drop** | Long press or grab the drag handle (`⋮⋮`) on any task. Drag up or down. | Task reorders smoothly; new order is persisted and synced. |
| **Categories & Search** | Tap category pills (`Work`, `Personal`, `Study`) or tap the search icon. | Task list filters dynamically in real time. |
| **Deadline Alerts** | Create a task with a deadline for today or an overdue date. | A warning banner appears at the top summarizing imminent deadlines. |
| **Focus Mode** | Press `⌘+F` or navigate to Focus screen from the sidebar/bottom navigation. | Calm minimalist full-screen workstation with distraction-free timer. |
| **Daily Planning** | Tap **"Plan Day"** in the top-right header. | Modal sheet allows selecting 3–5 high-priority focus tasks for today. |
| **7 Accent Packs** | Open **Settings** > **Accent Pack**. Choose *Forest*, *Ocean*, *Amber*, *Burgundy*, etc. | Interactive elements tint to selected palette while dark neutral surfaces remain obsidian. |

---

## 2. Running the Backend Synchronization Server

The synchronization backend is built with FastAPI and SQLite/PostgreSQL.

```bash
# Navigate to the backend directory
cd backend

# Install dependencies
pip install -r requirements.txt

# Run backend test suite
python -m pytest tests

# Start the server locally on port 8000
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The interactive OpenAPI / Swagger documentation is available at `http://localhost:8000/docs`.

---

## 3. Running the Flutter Client

### Windows Desktop
```bash
flutter run -d windows
```

### Android Device / Emulator
```bash
# Ensure emulator or physical device is connected
flutter devices

# Run in debug mode
flutter run -d android

# Or install the pre-built APK directly
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 4. Step-by-Step Demonstration Video Script (5 Minutes)

For submission, record a concise video walkthrough following these 6 scenes:

### Scene 1: Introduction & Intentional Design (0:00 - 0:45)
- Open Obsidian Slate on desktop or mobile.
- Highlight the **Obsidian Slate** design system:
  - No noisy gamification or hero greeting banners.
  - Dark mode (`#0F1115`) typography using Geist/Inter.
  - Show the 7 accent packs in Settings (demonstrating how Forest, Ocean, Amber tint checkboxes and focus rings while keeping background neutral).

### Scene 2: Core Task Management & Reordering (0:45 - 1:45)
- Quick-capture a new task in < 3 seconds using the inline capture bar: `"Implement SQLite sync engine"`.
- Tap the task to open **Task Details**:
  - Assign a priority: **High**.
  - Assign a category: **Work**.
  - Set a deadline: **Today**.
- Demonstrate **Drag-and-Drop Reordering**:
  - Touch/drag the task handle (`⋮⋮`) to change task sequence in the list.
- Demonstrate **Focus Mode**:
  - Tap `⌘+F` or the Focus Mode menu item to show the calm, typography-first countdown workstation.

### Scene 3: Toggling Offline (1:45 - 2:30)
- In the top right header, point to the status badge: **"Synced"** (Green dot).
- Turn on **Airplane Mode** or disconnect WiFi/Ethernet.
- Observe the connectivity badge dynamically transition to **"Offline"** (Amber warning dot).
- Tap the badge to show the **Sync Status Bottom Sheet**:
  - Status: *Offline*
  - Pending Queue: *0 operations*
  - Network state: *Disconnected*

### Scene 4: Offline Operations & Persistent Queue (2:30 - 3:30)
- While completely offline:
  1. Add a new task: `"Offline draft report"`.
  2. Mark an existing task as complete: Notice instant animated checkbox strike-through.
  3. Reorder tasks in the list.
  4. Edit task description.
- Re-open the Sync Status badge:
  - Show that operations are queued locally (`4 operations queued`).
- **Restart Test**: Force-close the app completely (`kill` or swipe away on Android). Reopen the app.
- Notice that all changes, reordering, and queued operations are 100% preserved. Zero data loss.

### Scene 5: Reconnection & Automatic Synchronization (3:30 - 4:15)
- Turn WiFi / Mobile Data back on.
- Observe the SyncEngine automatically wake up:
  - The badge transitions from **"Offline"** ➔ **"Syncing..."** ➔ **"Synced"**.
  - All 4 pending mutations are drained sequentially and pushed to the backend.
- Open **Settings** > **Sync Activity Log**:
  - Show the detailed audit log record with timestamp, duration, processed operation count, and `SUCCESS` status.

### Scene 6: Conflict Resolution & Conclusion (4:15 - 5:00)
- Briefly explain the **Last-Write-Wins (LWW)** deterministic resolution and UUID-based idempotency keys that guarantee zero duplicate records.
- Summarize adherence to GDG Wildcard Challenge requirements and clean architecture principles.
