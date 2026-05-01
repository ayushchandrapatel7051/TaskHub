# TaskHub Project Architecture & Documentation

TaskHub is a cross-platform, offline-first desktop productivity application built using **C++ (Logic)**, **Qt 6 / QML (UI)**, **SQLite (Local Storage)**, and **Firebase REST APIs (Cloud Sync & Auth)**. It strictly follows the **MVVM (Model-View-ViewModel)** architectural pattern.

---

## 📂 Project Structure

```text
TaskHub/
├── CMakeLists.txt                 # The CMake build configuration file
├── app/
│   └── main.cpp                   # Application entry point. Wires up services and viewmodels.
├── cpp/                           # Core C++ Backend
│   ├── models/                    # Data Structures
│   │   ├── Task.h                 # Task entity definition
│   │   └── Task.cpp               # Serialization logic (to/from QVariantMap and JSON)
│   ├── services/                  # Business Logic & Data Access
│   │   ├── AuthService.h/.cpp     # Handles Firebase Authentication (Login/Signup via REST)
│   │   ├── FirestoreService.h/.cpp# Handles Firebase Firestore database syncing (GET/PATCH)
│   │   ├── LocalCacheService.h/.cpp# Manages the local SQLite database for offline-first usage
│   │   ├── SyncService.h/.cpp     # Background timer that orchestrates cloud sync
│   │   └── TaskService.h/.cpp     # High-level wrapper for Task CRUD operations
│   └── viewmodels/                # The Bridge between C++ and QML
│       └── TaskListViewModel.h/.cpp# Exposes task data and actions (add/toggle) to the UI
├── qml/                           # Frontend UI (QML)
│   ├── Main.qml                   # Root window & Router (Switches between Login and Dashboard)
│   ├── components/                # Reusable UI Widgets
│   │   ├── LoginScreen.qml        # Handles user login and signup interfaces
│   │   ├── Sidebar.qml            # Left navigation panel
│   │   ├── TaskDetail.qml         # Right panel for viewing/editing a selected task
│   │   ├── TaskItem.qml           # Individual list row delegate (shows title and checkbox)
│   │   └── TaskList.qml           # Center panel displaying the list of tasks and Quick Add
│   └── theme/
│       ├── Theme.qml              # Design System Singleton (Colors, Fonts, Spacing)
│       └── qmldir                 # Exposes Theme as a global singleton to all QML files
└── resources/
    └── firebase_config.json       # Centralized config holding Firebase API keys and Project ID
```

---

## ⚙️ How It Works (Workflow Breakdown)

### 1. The Startup Flow (`main.cpp`)
When the application launches, `main.cpp` acts as the dependency injector:
1. It reads `firebase_config.json` to get the API Key and Project ID.
2. It initializes the **Services** (`LocalCacheService`, `TaskService`, `AuthService`, `FirestoreService`, `SyncService`).
3. It initializes the **ViewModels** (`TaskListViewModel`) and passes the `TaskService` into it.
4. It injects the `authService` and `taskListViewModel` directly into the QML Root Context.
5. Finally, it loads `Main.qml`.

### 2. The Authentication Flow (With Auto-Login)
1. On launch, `main.cpp` instructs `authService.autoLogin()`.
2. `AuthService` checks `QSettings` for a persistently saved `refreshToken`.
3. If found, it exchanges the refresh token with Google's Secure Token endpoint for a new `idToken`, avoiding repetitive logins.
4. If no token exists, `Main.qml` routes the user to `LoginScreen.qml`.
5. Upon successful login/signup, new tokens are saved to `QSettings`, and the dashboard is loaded.

### 3. The Offline-First Task Workflow (MVVM)
TaskHub uses an **Offline-First** approach. The UI always reads from and writes to the local SQLite database first to ensure zero latency.

- **Creating a Task:**
  1. The user types a task in `TaskList.qml` and presses Enter.
  2. QML calls `taskListViewModel.addTask(title, "")`.
  3. The ViewModel passes this to `TaskService::createTask()`.
  4. `TaskService` asks `LocalCacheService` to execute an `INSERT` into the SQLite database.
  5. If successful, `TaskService` emits `tasksChanged()`.
  6. The `TaskListViewModel` catches this signal, reloads the tasks, sorts them, and updates the UI automatically.

- **Grouping and Sorting (Phase 1):**
  1. During `loadTasks()`, the C++ ViewModel automatically computes a string category for each task based on its DB state: "Pinned", "Overdue", "Today", "Upcoming", "No Date", or "Completed".
  2. The ViewModel sorts the tasks strictly by Category Order → Priority → Due Date → OrderIndex.
  3. QML's `ListView.section.property` utilizes this pre-sorted sequence to effortlessly render dynamic sticky headers with collapsible arrow icons.

- **Inline Actions (Phase 2):**
  1. Tasks can be renamed via native QML `TextField`s. Hitting Enter immediately commits the update to C++.
  2. Clicking the trash icon triggers `softDeleteTask`, which sets `status="trashed"` in SQLite. `LocalCacheService` automatically filters these out of future queries.

### 4. Background Cloud Synchronization (`SyncService`)
To keep data backed up to Firebase without blocking the UI, the `SyncService` acts as a background manager.
1. In `main.cpp`, `syncService.startSync()` is called on launch.
2. It sets up a `QTimer` to run every 5 minutes.
3. **Sync Up:** It reads all tasks from `LocalCacheService` and passes them to `FirestoreService::syncTasksUp()`.
4. `FirestoreService` sends `PATCH` requests to the Firebase Firestore REST API, attaching the `idToken` from `AuthService` for authorization.
5. **Sync Down:** It calls `FirestoreService::fetchRemoteTasks()` to pull any new tasks created on other devices, merging them into local SQLite.

### 5. The Design System (`Theme.qml`)
Instead of hardcoding colors like `"#121212"` everywhere, we use a global singleton called `Theme.qml`.
If we ever want to change the app's primary color from Blue to Purple, or switch from Dark Mode to Light Mode, we only need to change the values inside `Theme.qml`, and the entire application will instantly update.
