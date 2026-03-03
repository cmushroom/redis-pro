# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Redis Pro is a macOS Redis management client built with SwiftUI and The Composable Architecture (TCA). It supports direct TCP connections and SSH tunneling for managing Redis databases.

## Build & Run Commands

This is an Xcode project. Since Xcode command-line tools are installed but not full Xcode:

```bash
# Open project in Xcode
open redis-pro.xcodeproj

# Run tests (requires Xcode)
# In Xcode: Cmd+U or Product > Test
```

**Note**: Running tests requires a Redis server running on localhost:6379 (see test files in `Tests/` directory).

## Architecture

### The Composable Architecture (TCA)

The app uses TCA for state management with a hierarchical store structure:

- **RootStore**: Manages multiple window instances, each window has independent state
- **AppStore**: Main store for each window containing:
  - `AppContextStore`: Global shared state using `@Shared(.inMemory("appContext"))`
  - `FavoriteStore`: Manages saved Redis connections
  - `SettingsStore`: App settings and preferences
  - `RedisKeysStore`: Redis key browser state
  - `LoadingStore`: Loading state management

Each feature-specific store (e.g., `StringValueStore`, `HashValueStore`, `ZSetValueStore`, `ListValueStore`, `SetValueStore`) manages its own domain state.

### Multi-Window Architecture

The app supports multiple windows with independent state:
- Each window gets its own `AppStore` instance with a unique `id`
- Each window has its own `RediStackClient` instance injected via TCA dependencies
- Windows can be created via Cmd+T (New Tab command in `openNewWindow()`)
- Shared state is managed via `@Shared` property wrapper for cross-window state synchronization

### Dependency Injection

Dependencies are declared in `redis-pro/Store/DependencyKeys.swift`:
- `redisClient`: RediStackClient instance (per-window)
- `redisInstance`: RedisInstanceModel wrapper

Dependencies are injected at window creation in `redis_proApp.swift` and `RootStore.swift`.

### Redis Client Layer

`RediStackClient` is the core Redis client wrapper around RediStack (SwiftNIO-based Redis client):

**Connection Management** (`RedisClientConn.swift`):
- Supports TCP and SSH tunnel connections
- Connection pooling via `RedisConnectionPool`
- Automatic reconnection and keepalive

**Redis Command Extensions** (split by data type):
- `RedisClientString.swift`: String operations
- `RedisClientHash.swift`: Hash operations
- `RedisClientList.swift`: List operations
- `RedisClientSet.swift`: Set operations
- `RedisClientZSet.swift`: Sorted set operations
- `RedisClientKeys.swift`: Key operations (GET, SET, DEL, SCAN)
- `RedisClientScan.swift`: SCAN operations with pagination
- `RedisClientSystem.swift`: Server info, clients, memory stats
- `RedisClientConfig.swift`: Redis CONFIG commands
- `RedisClientSlowLog.swift`: Slow log queries
- `RedisClientLua.swift`: Lua script execution

**SSH Support** (`redis-pro/Common/SSH/`):
- `SSHRediStackClient.swift`: SSH tunnel wrapper
- `SSHForward.swift`: Port forwarding implementation
- `SSHTunnel.swift`: SSH tunnel management
- Built on SwiftNIO SSH

### View Layer

Views follow SwiftUI + TCA patterns:

- **IndexView**: Root view switching between LoginView and HomeView based on connection state
- **LoginView/LoginForm**: Connection form with favorite management
- **HomeView**: Main split view with sidebar (key list) and detail (value editor)
- **RedisEditorView/**: Type-specific value editors (String, Hash, List, Set, ZSet)
- **System/**: Server info, client list, config, slow log views
- **Components/**: Reusable UI components (buttons, forms, tables, modals)

Custom form components use prefix conventions:
- `M*` prefix: Custom macOS-styled components (MButton, MTextField, MLabel, etc.)
- `N*` prefix: Native-wrapped components with enhancements (NTextField, NSearchField, etc.)
- `FormItem*`: TCA-integrated form field wrappers

### Models

Core data models in `redis-pro/Model/`:
- `RedisModel`: Connection configuration (host, port, auth, SSH settings)
- `RedisKeyValueModel`: Key-value pair representation
- `RedisHashEntryModel`, `RedisZSetItemModel`, `RedisListItemModel`: Type-specific data models
- `RedisInfoModel`, `ClientModel`, `SlowLogModel`: Server info models
- `Page`: Pagination model for SCAN operations
- `GlobalContext`: Shared app context (deprecated, being replaced by `@Shared` state)

### Error Handling

- `BizError`: Business logic errors
- `ErrorExt.swift`: Error extension utilities for TCA integration
- `Messages.swift`: NSAlert-based error/info message display

## Key Dependencies

From `Package.resolved`:
- **RediStack** (custom fork): Redis client built on SwiftNIO
- **swift-composable-architecture** (1.17.1): TCA state management
- **Puppy** (0.7.0): Logging backend for swift-log
- **swift-nio** (2.62.0): Non-blocking I/O
- **swift-nio-ssh** (0.8.0): SSH tunnel support
- **firebase-ios-sdk** (11.5.0): Analytics/crashlytics
- **SwiftJSONFormatter** (2.0.0): JSON formatting in value editors

## Development Conventions

### State Management

1. Use `@ObservableState` for TCA state structs
2. Use `@Shared` for cross-window or persistent state
3. All state mutations must happen through TCA actions/reducers
4. Prefer `WithPerceptionTracking` in views for fine-grained updates

### Multi-Window State

When adding features that need cross-window synchronization:
1. Use `@Shared(.inMemory("key"))` for in-memory shared state
2. Use `@Shared(.appStorage("key"))` for persistent shared state (UserDefaults)
3. Define shared state extensions in `ShareStateExt.swift`
4. See `AppStore.State.appContext` for example usage

### Redis Client Usage

When adding new Redis operations:
1. Create extension file in `redis-pro/Common/RedisClient/` organized by feature
2. Follow existing patterns: async/await, error handling with `handleError()`
3. Use `begin()` and `complete()` for loading state
4. Wrap RediStack commands with custom logic as needed

### Logging

Use swift-log with labels:
```swift
private let logger = Logger(label: "component-name")
logger.info("message")
logger.error("error: \(error)")
```

Logger is configured in `LoggerFactory.swift` with Puppy backend (console + file).

### Testing

Test structure:
- `Tests/RedisBaseTests/`: Base test classes with Redis connection setup
- `Tests/Store/`: TCA store tests using `@TestStore`
- `Tests/RedisCommandTests/`: Redis client operation tests

Tests require Redis server on localhost:6379.

## Code Organization

```
redis-pro/
├── Common/                    # Shared utilities and clients
│   ├── RedisClient/          # Redis client implementation (split by feature)
│   ├── SSH/                  # SSH tunnel support
│   ├── Enums/                # Global enums (connection type, key type, etc.)
│   ├── Helpers/              # Utility helpers (date, string, number)
│   └── UserDefaults/         # UserDefaults keys and wrappers
├── Model/                    # Data models
├── Store/                    # TCA stores (one per feature domain)
├── Views/                    # SwiftUI views
│   ├── Components/           # Reusable UI components
│   ├── Login/                # Connection/favorite management
│   ├── RedisEditorView/      # Value editors by type
│   ├── System/               # Server management views
│   ├── App/                  # Settings, about
│   └── Sidebar/              # Key list sidebar
├── Command/                  # Menu bar commands
└── redis_proApp.swift        # App entry point
```

## Important Notes

- The app is transitioning from `GlobalContext` to TCA `@Shared` state for multi-window support
- Firebase is configured in `AppDelegate.applicationDidFinishLaunching`
- Dark mode switching is handled at NSApp.appearance level (not per-window)
- The custom RediStack fork includes user authentication support
- SSH connections use password auth only (SSH key auth is TODO per README)
