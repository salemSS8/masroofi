# Graph Report - bashnddof  (2026-10-03)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 364 nodes · 469 edges · 22 communities (15 shown, 7 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Win32Window
- GeneratedPluginRegistrant.swift
- my_application.cc
- main.dart
- package:flutter/material.dart
- initial_budget_setup_screen.dart
- presentation/pin_setup_screen.dart
- utils.cpp
- transaction_model.dart
- FlutterWindow
- dashboard/presentation/screens/dashboard_screen.dart
- database_helper.dart
- manifest.json
- encryption_service.dart
- windows/flutter/generated_plugin_registrant.cc
- envelopes_screen.dart
- MainActivity.kt

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `MessageHandler` - 12 edges
3. `FlutterWindow` - 10 edges
4. `Create` - 10 edges
5. `WndProc` - 10 edges
6. `MessageHandler` - 9 edges
7. `WindowClassRegistrar` - 7 edges
8. `_MyApplication` - 7 edges
9. `OnCreate` - 7 edges
10. `Destroy` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  windows/runner/win32_window.cpp → windows/runner/win32_window.h
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.h → windows/flutter/generated_plugin_registrant.cc
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `FlutterWindow` --inherits--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h
- `MessageHandler` --references--> `Win32Window`  [EXTRACTED]
  windows/runner/flutter_window.h → windows/runner/win32_window.h

## Import Cycles
- None detected.

## Communities (22 total, 7 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.08
Nodes (33): OnCreate, OnDestroy, EnableFullDpiSupportIfAvailable(), Point, x, y, Scale(), Size (+25 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (17): Cocoa, Flutter, flutter_secure_storage_macos, FlutterMacOS, Foundation, AppDelegate, RunnerTests, local_auth_darwin (+9 more)

### Community 2 - "my_application.cc"
Cohesion: 0.08
Nodes (14): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+6 more)

### Community 3 - "main.dart"
Cohesion: 0.07
Nodes (18): build, createState, _decideInitialRoute, _homeRoute, initState, isFirstTime, main, MyApp (+10 more)

### Community 4 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (15): build, IntroScreen, _onStart, build, RecurringTransactionsScreen, build, ReportsScreen, build (+7 more)

### Community 5 - "initial_budget_setup_screen.dart"
Cohesion: 0.08
Nodes (21): PinSetupScreen, build, createState, dispose, _pinController, PinSetupScreen, _showWarningDialog, build (+13 more)

### Community 6 - "presentation/pin_setup_screen.dart"
Cohesion: 0.09
Nodes (19): build, _checkPin, createState, dispose, _isChecking, LoginScreen, _LoginScreenState, _pinController (+11 more)

### Community 7 - "utils.cpp"
Cohesion: 0.12
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 8 - "transaction_model.dart"
Cohesion: 0.11
Nodes (14): CategoryModel, fromMap, id, name, toMap, amount, category, datetime (+6 more)

### Community 9 - "FlutterWindow"
Cohesion: 0.12
Nodes (5): FlutterWindow, flutter_controller_, FlutterWindow::FlutterWindow(), MessageHandler, project_

### Community 10 - "dashboard/presentation/screens/dashboard_screen.dart"
Cohesion: 0.13
Nodes (7): build, createState, _DashboardScreenState, _onItemTapped, _selectedIndex, _widgetOptions, build

### Community 11 - "database_helper.dart"
Cohesion: 0.16
Nodes (8): AppDatabase, _db, getInstance, _createDB, _database, DatabaseHelper, _initDB, instance

### Community 12 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 13 - "encryption_service.dart"
Cohesion: 0.22
Nodes (5): decrypt, encrypt, _encrypter, EncryptionService, _iv

### Community 15 - "envelopes_screen.dart"
Cohesion: 0.33
Nodes (5): build, _buildEnvelopeCard, createState, EnvelopesScreen, _EnvelopesScreenState

## Knowledge Gaps
- **115 isolated node(s):** `x`, `y`, `height`, `width`, `child_content_` (+110 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 197 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `FlutterWindow`, `utils.cpp`?**
  _High betweenness centrality (0.037) - this node is a cross-community bridge._
- **Why does `OnCreate` connect `Win32Window` to `FlutterWindow`, `windows/flutter/generated_plugin_registrant.cc`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `MessageHandler` connect `FlutterWindow` to `Win32Window`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `Create` (e.g. with `Destroy` and `UpdateTheme`) actually correct?**
  _`Create` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `x`, `y`, `height` to the rest of the system?**
  _115 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.07908163265306123 - nodes in this community are weakly interconnected._