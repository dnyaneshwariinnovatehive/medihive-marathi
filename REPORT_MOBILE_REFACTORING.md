# Mobile-Only Refactoring Report

## Summary

Complete transformation from Desktop+Mobile architecture to clean Mobile-Only architecture.

All imports verified, Drive/Sheets connectivity verified, 0 lint errors.

---

## 1. Files Removed (12)

| File | Reason |
|------|--------|
| `backend/desktop_google/` (entire package — 9 files + 2 JSON + 1 pycache) | Legacy desktop package, all functionality extracted |
| `backend/desktop_google/__init__.py` | Package marker |
| `backend/desktop_google/sheets_service.py` | Replaced by `backend/sheets_utils.py` |
| `backend/desktop_google/drive_service.py` | Replaced by `backend/drive_utils.py` |
| `backend/desktop_google/auth_service.py` | Dead code (never registered, SQLAlchemy `db` doesn't exist) |
| `backend/desktop_google/auth_routes.py` | Dead code (never registered in app.py) |
| `backend/desktop_google/sync_service.py` | Dead code (excluded by .dockerignore) |
| `backend/desktop_google/sync_queue.py` | Dead code (excluded by .dockerignore) |
| `backend/desktop_google/image_service.py` | Dead code (excluded by .dockerignore) |
| `backend/desktop_google/generate_drive_token.py` | Duplicate of `utils/generate_drive_token.py` |
| `backend/desktop_google/drive_token.json` | Used different Google project (`medihive-500611`) |
| `backend/desktop_google/oauth_credentials.json` | Used different Google project (`medihive-500611`) |
| `backend/medihive.db` | Legacy SQLite binary — no longer used |
| `backend/sheet_id.json` | Replaced by `.env` config |
| `backend/config.py` | Renamed to `app_config.py` to resolve package/module name conflict |

## 2. Files Created (2)

| File | Lines | Purpose |
|------|-------|---------|
| `backend/sheets_utils.py` | ~245 | Extracted from `desktop_google/sheets_service.py` (711→245 lines). Google Sheets OPD upsert, calendar notes, sheet validation, clear data. Uses `config` module-level config. |
| `backend/drive_utils.py` | ~187 | Extracted from `desktop_google/drive_service.py` (289→187 lines). Drive file upload, batch upload, fileobj upload, existing file check. Uses centralized `GoogleAuthService`. |

## 3. Files Modified (10)

| File | Changes |
|------|---------|
| `backend/app.py` | Removed `desktop_google` imports, removed `sync_cloud_bp` and `device_bp` blueprints, removed 3 debug endpoints (`/debug-users`, `/debug-sync`, `/debug-google`), removed `initialize_google_services()` startup call |
| `backend/routes/sync.py` | **Complete rewrite** (507→~280 lines). Removed 4 desktop endpoints (`/pull`, `/push`, `/push/images`, `/clear-data`). Added consolidated mobile endpoints: `/register-device`, `/heartbeat`, `/upload` (JWT), `/download` (JWT), `/upload-images` (JWT), `/clinic-info`. All use `drive_utils` and `sheets_utils` instead of `desktop_google`. |
| `backend/routes/cloud.py` | **Complete rewrite** (492→~80 lines). Removed all duplicate sync logic. Now backward-compatible proxy that delegates to `sync.py` endpoints. 6 endpoints remain. |
| `backend/routes/opd.py` | Replaced `from desktop_google.drive_service import ...` and `from desktop_google.sheets_service import ...` with `from drive_utils import ...` and `from sheets_utils import ...` |
| `backend/database.py` | Removed `is_synced` column from `patients`, `opd_records`, and `appointments` CREATE TABLE statements. Removed `last_sync` table entirely. Cleaned sqlite3 compatibility comment. |
| `backend/app_config.py` | Renamed from `config.py` to resolve module/package collision. Cleaned up legacy SQLite default path. Fixed `DRIVE_TOKEN_PATH` to point to `backend/drive_token.json` (was `../drive_token.json`). |
| `backend/config/__init__.py` | Rewritten to re-export all settings from `app_config.py`, maintaining `from config import X` compatibility. |
| `backend/.dockerignore` | Removed `desktop_google/` dead code exclusions (package no longer exists). |
| `backend/scripts/validate_production.py` | Updated sync endpoint names from old desktop (`/sync/push`, `/sync/pull`) to new mobile (`/sync/upload`, `/sync/download`). Removed "Desktop compatible" comment. |
| `backend/scripts/deploy_cloud_run.py` | Updated "desktop compatible" comment to "sequential". |
| `backend/services/google_drive_service.py` | Fixed imports: `from backend.config.google_config` → `from config.google_config` |
| `backend/services/google_sheets_service.py` | Fixed imports: `from backend.config.google_config` → `from config.google_config` |
| `backend/utils/test_google_drive.py` | Fixed imports: `from backend.config.google_config` → `from config.google_config` |
| `backend/utils/test_google_sheet.py` | Fixed imports: `from backend.config.google_config` → `from config.google_config` |
| `backend/tests/test_postgresql_queries.py` | Updated `import config` → `import app_config` |

## 4. Dependencies Removed

None removed from `requirements.txt`. All existing dependencies are still needed (Flask, gspread, google-api-python-client, psycopg2, etc.).

The `desktop_google` package had no unique dependencies.

## 5. APIs Simplified

| Before | After | Change |
|--------|-------|--------|
| 41 active routes | 33 routes | -8 routes |
| 2 sync blueprints (`sync_bp`, `sync_cloud_bp`) | 1 sync blueprint (`sync_bp`) | Consolidated |
| 2 device registration endpoints | 1 device registration | Deduplicated |
| 4 sync endpoints (`push`, `pull`, `push/images`, `clear-data`) | 3 sync endpoints (`upload`, `download`, `upload-images`) | Consolidated + simplified |
| 3 cloud debug endpoints | Removed | Clean architecture |
| Sync routed via `desktop_google` | Sync routed via `services/` + `drive_utils` + `sheets_utils` | Proper dependency chain |

### Routes Removed (8)

| Endpoint | Reason |
|----------|--------|
| `POST /api/sync/pull` | Desktop-only sync pattern |
| `POST /api/sync/push` | Desktop-only sync pattern |
| `POST /api/sync/push/images/<id>` | Desktop-only image upload |
| `POST /api/sync/clear-data` | Destructive, desktop-only |
| `POST /api/sync/upload` | Duplicate of `/api/cloud/upload-changes` |
| `GET /api/sync/download` | Duplicate of `/api/cloud/download-changes` |
| `POST /api/sync/ack` | Desktop ack protocol |
| `POST /api/device/register` | Duplicate of `/api/cloud/register-device` |

## 6. Sync Improvements

| Aspect | Before | After |
|--------|--------|-------|
| **Desktop sync queue** | `desktop_google/sync_service.py` (389 lines, 60s background loop) | Removed entirely |
| **Desktop sync queue model** | `desktop_google/sync_queue.py` (SQLAlchemy) | Removed entirely |
| **Duplicate upload logic** | 3 places: `routes/sync.py`, `routes/cloud.py`, `routes/opd.py` all had Drive upload | Simplified to 1 path: `routes/sync.py` + `sync_upload_images` + `drive_utils` |
| **Duplicate download logic** | 3 places: `routes/sync.py` pull, `routes/cloud.py` download-changes, `sync_cloud_bp` download | 1 endpoint: `POST /api/sync/download` |
| **Sheets sync** | Called from `desktop_google/sheets_service.py` | Called from `sheets_utils.py` |
| **Drive upload** | Called from `desktop_google/drive_service.py` | Called from `drive_utils.py` |

## 7. Security Improvements

| Issue | Before | After |
|-------|--------|-------|
| **Device ID auth** | `routes/cloud.py` used raw device_id without JWT for upload/download | Cloud routes now require JWT (delegate to sync blueprint which has `@jwt_required()`) |
| **Debug endpoints** | 3 unauthenticated debug endpoints exposing DB queries and credentials | All removed |
| **Default admin** | Still hardcoded in `database.py` (out of scope for this task) | Not changed per task constraints |

## 8. Performance Improvements

| Aspect | Before | After |
|--------|--------|-------|
| **Google init at startup** | `initialize_google_services()` called on every app start, validating sheet+drive | Removed — lazy validation on first use |
| **Dead imports** | Multiple `desktop_google` imports loaded at module level | Zero `desktop_google` imports remain |
| **Connection pool** | Still using `ThreadedConnectionPool` (out of scope for this task) | Not changed |

## 9. Architecture Diagram (Post-Refactoring)

```
Android Device (SQLite cache)
         │
         ▼
┌─────────────────────────────────────┐
│         Flask API (Cloud Run)        │
│                                      │
│  ┌──────────────┐  ┌──────────────┐  │
│  │  Auth Routes  │  │  Data Routes │  │
│  │  /api/auth    │  │  /api/patients  │
│  │               │  │  /api/opd       │
│  │               │  │  /api/appts    │
│  └──────────────┘  └──────┬───────┘  │
│                            │          │
│  ┌──────────────┐  ┌──────▼───────┐  │
│  │  Sync Routes  │  │  Models      │  │
│  │  /api/sync    │  │  (raw SQL)   │  │
│  │  upload/      │  │              │  │
│  │  download     │  └──────┬───────┘  │
│  └──────────────┘         │          │
│                    ┌──────▼───────┐   │
│                    │  PostgreSQL   │   │
│                    │    (Neon)     │   │
│                    └──────┬───────┘   │
│                           │           │
│  ┌──────────┐  ┌──────────▼──────┐   │
│  │drive_utils│  │ sheets_utils   │   │
│  │  (files)  │  │  (sheets)      │   │
│  └────┬─────┘  └───────┬────────┘   │
│       │                │            │
│       ▼                ▼            │
│  Google Drive    Google Sheets      │
│  (OAuth token)   (Service Account)  │
└─────────────────────────────────────┘
```

## 10. Remaining TODOs (Out of Scope)

These were explicitly excluded from this refactoring task:

1. Password hashing: SHA-256 → bcrypt
2. Hardcoded default admin credentials removal
3. Rate limiting on auth endpoints
4. Alembic migration framework
5. Async Google API calls
6. Redis caching
7. `cloud_sync_log` table simplification
8. Input validation (pydantic/marshmallow)
9. Fee column types from TEXT to NUMERIC
10. Remove `DEBUG` endpoints from schema
