---
type: "query"
date: "2026-10-03T10:23:57.462601+00:00"
question: "Login flow trace from UI to service to API/storage"
contributor: "graphify"
outcome: "useful"
source_nodes: ["LoginScreen", "_LoginScreenState", "SecureStorageService", "login_screen.dart", "secure_storage_service.dart"]
---

# Q: Login flow trace from UI to service to API/storage

## Answer

Traced login flow: main.dart -> login_screen.dart (_checkPin) -> crypto (sha256) -> secure_storage_service.dart (SecureStorageService.getPin) -> dashboard_screen.dart. Offline-first local storage.

## Outcome

- Signal: useful

## Source Nodes

- LoginScreen
- _LoginScreenState
- SecureStorageService
- login_screen.dart
- secure_storage_service.dart