# MediHive Marathi — Backend Architecture Review

> **Project Context:** Android ↔ Cloud ↔ Android (desktop removed)
> **Date:** 2026-07-11
> **Status:** Analysis Only — No code modified

---

## Table of Contents

1. [Project Structure Overview](#1-project-structure-overview)
2. [Task 1 — Desktop Artifacts Identified](#2-task-1--desktop-artifacts-identified)
3. [Task 2 — File Classification (Keep / Modify / Remove)](#3-task-2--file-classification-keep--modify--remove)
4. [Task 3 — API Route Analysis](#4-task-3--api-route-analysis)
5. [Task 4 — Synchronization Analysis](#5-task-4--synchronization-analysis)
6. [Task 5 — Database Architecture Review](#6-task-5--database-architecture-review)
7. [Task 6 — Google Integration Review](#7-task-6--google-integration-review)
8. [Task 7 — Full Recommendations](#8-task-7--full-recommendations)

---

## 1. Project Structure Overview

```
backend/
├── __init__.py
├── app.py                          # Flask app factory (184 lines)
├── config.py                       # Env-based config (85 lines)
├── database.py                     # PostgreSQL pool + schema DDL (366 lines)
├── .env                            # 11 env vars
├── .gitignore
├── .dockerignore
├── requirements.txt
├── runtime.txt
├── Procfile
├── Dockerfile
├── medihive.db                     # ⚠️ Legacy SQLite file (should be removed)
├── sheet_id.json                   # ⚠️ Legacy sheet ID file
├── drive_token.json                # Active OAuth token
├── oauth_credentials.json          # Active OAuth client
│
├── config/
│   ├── __init__.py
│   └── google_config.py            # Google-specific env loading
│
├── models/
│   ├── __init__.py
│   ├── patient.py                  # Active
│   ├── opd_record.py               # Active
│   ├── appointment.py              # Active
│   ├── clinic.py                   # Active
│   ├── device_registry.py          # Active (mobile-only use)
│   └── deleted_entity.py           # Active (sync support)
│
├── routes/
│   ├── __init__.py
│   ├── auth.py                     # Active
│   ├── patients.py                 # Active
│   ├── opd.py                      # Active (imports desktop_google)
│   ├── appointments.py             # Active
│   ├── sync.py                     # ⚠️ Desktop sync (507 lines)
│   ├── fcm.py                      # Active
│   ├── whatsapp.py                 # Active
│   └── cloud.py                    # ⚠️ Cloud sync (492 lines)
│
├── services/
│   ├── __init__.py
│   ├── google_auth_service.py      # NEW centralized auth
│   ├── google_sheets_service.py    # NEW placeholder (53 lines)
│   ├── google_drive_service.py     # NEW placeholder (53 lines)
│   ├── log_service.py              # Active
│   ├── whatsapp_cloud.py           # Active
│   └── fcm_service.py              # Active
│
├── desktop_google/                 # ⚠️ FULLY LEGACY — 9 files
│   ├── __init__.py
│   ├── sheets_service.py           # Active at runtime (711 lines)
│   ├── drive_service.py            # Active at runtime (289 lines)
│   ├── auth_service.py             # Dead code
│   ├── auth_routes.py              # Dead code (not registered)
│   ├── sync_service.py             # Dead code (excluded by .dockerignore)
│   ├── sync_queue.py               # Dead code (excluded by .dockerignore)
│   ├── image_service.py            # Dead code (excluded by .dockerignore)
│   ├── generate_drive_token.py     # Duplicate token generator
│   ├── drive_token.json            # ⚠️ Second OAuth token (project medihive-500611)
│   └── oauth_credentials.json      # ⚠️ Second OAuth client (project medihive-500611)
│
├── scripts/
│   ├── validate_production.py      # Active (references desktop sync)
│   ├── validate_neon.py            # Active
│   ├── deploy_cloud_run.py         # Active
│   ├── deploy_production.sh        # Active
│   └── deploy_production.ps1       # Active
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py                 # Active
│   └── test_postgresql_queries.py  # Active (518 lines)
│
└── utils/
    ├── __init__.py
    ├── generate_drive_token.py     # NEW token generator
    ├── test_google_sheet.py        # NEW sheet test
    └── test_google_drive.py        # NEW drive test
```

---

## 2. Task 1 — Desktop Artifacts Identified

### 2.1 Desktop Synchronization Code

| File | Lines | What It Does | Currently Used? |
|------|-------|-------------|-----------------|
| `routes/sync.py` | 507 | Push/pull sync for desktop Flutter app (JWT auth). Imports `desktop_google/drive_service` and `desktop_google/sheets_service`. | **YES** — registered in `app.py` |
| `routes/cloud.py` | 492 | Cloud sync for multi-device (device_id auth). Overlaps with `routes/sync.py`. Also imports `desktop_google` modules. | **YES** — registered in `app.py` |
| `desktop_google/sync_service.py` | 389 | Background sync loop (SQLAlchemy) processing `sync_queue` every 60s. | **NO** — excluded by `.dockerignore` |
| `desktop_google/sync_queue.py` | 21 | SQLAlchemy `SyncQueue` model. | **NO** — excluded by `.dockerignore` |

### 2.2 Desktop SQLite Compatibility

| Location | Reference | Details |
|----------|-----------|---------|
| `database.py:67` | Comment | `DBConnection` wrapper "mimics sqlite3's connection.execute() interface" |
| `desktop_google/sheets_service.py:103` | Comment | `"SHEET ID PERSISTENCE (SQLite + file fallback)"` — stale comment, code uses PostgreSQL |
| `validate_production.py:142` | Comment | `"Same ID format as desktop SQLite app"` |
| `deploy_cloud_run.py:236` | Comment | `"Patient IDs - P001, P002 format (desktop compatible)"` |
| `medihive.db` | File | Legacy SQLite database file in backend root |

### 2.3 Desktop-Specific APIs

| Route | File | Purpose | Status |
|-------|------|---------|--------|
| `POST /api/sync/pull` | `routes/sync.py:102` | Desktop pull sync | Active (needs JWT) |
| `POST /api/sync/push` | `routes/sync.py:145` | Desktop push sync | Active (needs JWT) |
| `POST /api/sync/push/images/<opd_id>` | `routes/sync.py:305` | Desktop image upload | Active (needs JWT) |
| `POST /api/sync/clear-data` | `routes/sync.py:446` | Clear all data | Active (needs JWT) |

### 2.4 Desktop Authentication (Dead Code)

| File | Purpose |
|------|---------|
| `desktop_google/auth_service.py` | OTP-based login, password reset — uses SQLAlchemy `db` object that doesn't exist |
| `desktop_google/auth_routes.py` | `POST /api/auth/send-otp`, `POST /api/auth/reset-password` — never registered in `app.py` |

### 2.5 Desktop Repositories / Models (Dead Code)

| File | Purpose |
|------|---------|
| `desktop_google/sync_queue.py` | SQLAlchemy `SyncQueue` model referencing `backend.database.db.Base` — does not exist |
| `desktop_google/image_service.py` | Local image save with `sync_status="PENDING"` |

### 2.6 Desktop Upload/Download Logic (Active but Legacy)

| File | Purpose | Notes |
|------|---------|-------|
| `desktop_google/drive_service.py` | Google Drive image upload (289 lines) | **Still imported** by `routes/sync.py` and `routes/opd.py` |
| `desktop_google/sheets_service.py` | Google Sheets OPD sync (711 lines) | **Still imported** by `routes/sync.py` and `routes/opd.py` |

### 2.7 Desktop Routes in `routes/cloud.py`

`routes/cloud.py` duplicates many sync endpoints under different names:

| Route | Equivalent Desktop Route | Purpose |
|-------|------------------------|---------|
| `POST /api/cloud/upload-changes` | `POST /api/sync/push` | Upload changes |
| `POST /api/cloud/download-changes` | `POST /api/sync/pull` | Download changes |
| `POST /api/cloud/upload-images/<opd_id>` | `POST /api/sync/push/images/<opd_id>` | Image upload |
| `POST /api/sync/upload` | `POST /api/sync/push` | Alternative upload |
| `GET /api/sync/download` | `POST /api/sync/pull` | Alternative download |

---

## 3. Task 2 — File Classification (Keep / Modify / Remove)

### 3.1 Files to KEEP (No Changes Needed)

| File | Reason |
|------|--------|
| `backend/__init__.py` | Package marker |
| `backend/config/__init__.py` | Package marker |
| `backend/models/__init__.py` | Package marker |
| `backend/routes/__init__.py` | Package marker |
| `backend/services/__init__.py` | Package marker |
| `backend/utils/__init__.py` | Package marker with path setup |
| `backend/.gitignore` | Already correct |
| `backend/runtime.txt` | Python version spec |
| `backend/Procfile` | Gunicorn startup |
| `backend/Dockerfile` | Container configuration |
| `backend/requirements.txt` | Dependencies (may need updates) |
| `backend/config.py` | Environment config (works for PostgreSQL) |
| `backend/config/google_config.py` | Google-specific config from `.env` |
| `backend/models/patient.py` | Core entity — no desktop references |
| `backend/models/opd_record.py` | Core entity — no desktop references |
| `backend/models/appointment.py` | Core entity — no desktop references |
| `backend/models/clinic.py` | Core entity — mobile-only compatible |
| `backend/models/device_registry.py` | Mobile device tracking — keep |
| `backend/models/deleted_entity.py` | Sync audit trail — keep |
| `backend/routes/auth.py` | Auth routes — mobile-compatible |
| `backend/routes/patients.py` | Patient CRUD — mobile-compatible |
| `backend/routes/opd.py` | OPD CRUD — **needs cleanup of desktop_google imports** (see Modify) |
| `backend/routes/appointments.py` | Appointment CRUD — mobile-compatible |
| `backend/routes/fcm.py` | FCM token registration — mobile-only |
| `backend/routes/whatsapp.py` | WhatsApp integration — mobile-compatible |
| `backend/services/log_service.py` | Logging utility |
| `backend/services/whatsapp_cloud.py` | WhatsApp Cloud API |
| `backend/services/fcm_service.py` | FCM push notifications |
| `backend/services/google_auth_service.py` | New centralized auth — keep |
| `backend/services/google_sheets_service.py` | New placeholder — keep |
| `backend/services/google_drive_service.py` | New placeholder — keep |
| `backend/utils/generate_drive_token.py` | New token generator — keep |
| `backend/utils/test_google_sheet.py` | New sheet tester — keep |
| `backend/utils/test_google_drive.py` | New drive tester — keep |
| `backend/scripts/validate_neon.py` | Neon PostgreSQL validator |
| `backend/scripts/deploy_cloud_run.py` | Cloud Run deployment guide |
| `backend/scripts/deploy_production.sh` | Production deployment |
| `backend/scripts/deploy_production.ps1` | Production deployment |
| `backend/tests/__init__.py` | Package marker |
| `backend/tests/conftest.py` | Test configuration |
| `backend/tests/test_postgresql_queries.py` | PostgreSQL query tests |

### 3.2 Files to MODIFY

| File | Reason | Required Changes |
|------|--------|-----------------|
| `backend/app.py` | Imports and registers desktop sync blueprints. Initializes legacy Google services. | Remove `desktop_google` imports. Remove legacy blueprint registrations. Use new `services/google_auth_service.py` for Google init. Remove debug endpoints that depend on legacy code. |
| `backend/database.py` | Contains `is_synced` columns (desktop sync), `last_sync` table (desktop), `cloud_sync_log` table (over-engineered). `DBConnection` mimics sqlite3 unnecessarily. | Simplify: remove `is_synced` columns (mobile sync uses different mechanism), remove `last_sync` table, simplify `cloud_sync_log`. Drop sqlite3 compatibility comments. |
| `backend/routes/sync.py` | **507 lines of desktop sync logic.** Imports `desktop_google/drive_service` and `desktop_google/sheets_service`. | Complete rewrite for mobile-only architecture. Replace with simplified sync endpoints that use new `services/google_*_service.py`. |
| `backend/routes/cloud.py` | **492 lines of cloud sync.** Duplicates `sync.py` functionality. Imports `desktop_google` modules. | Full consolidation with `sync.py`. Remove duplication. Use centralized auth. |
| `backend/routes/opd.py` | Imports `desktop_google/drive_service` and `desktop_google/sheets_service` for image upload and sheet sync. | Replace desktop_google imports with new `services/google_drive_service.py` and `services/google_sheets_service.py`. |
| `backend/scripts/validate_production.py` | Tests desktop `sync/push` and `sync/pull` endpoints. References "desktop SQLite". | Update validation to test new mobile sync endpoints. Remove desktop references. |

### 3.3 Files to REMOVE

| File | Reason |
|------|--------|
| `backend/desktop_google/__init__.py` | Entire package is legacy. All functionality replaced by new `services/` package. |
| `backend/desktop_google/sheets_service.py` | **711 lines** — replaced by `services/google_sheets_service.py` (to be implemented fully) |
| `backend/desktop_google/drive_service.py` | **289 lines** — replaced by `services/google_drive_service.py` (to be implemented fully) |
| `backend/desktop_google/auth_service.py` | Dead code — OTP auth, SQLAlchemy `db` doesn't exist |
| `backend/desktop_google/auth_routes.py` | Dead code — never registered in `app.py` |
| `backend/desktop_google/sync_service.py` | Dead code — excluded by `.dockerignore` |
| `backend/desktop_google/sync_queue.py` | Dead code — excluded by `.dockerignore` |
| `backend/desktop_google/image_service.py` | Dead code — excluded by `.dockerignore` |
| `backend/desktop_google/generate_drive_token.py` | Duplicate — replaced by `utils/generate_drive_token.py` |
| `backend/desktop_google/drive_token.json` | Duplicate — uses different Google project (`medihive-500611`) |
| `backend/desktop_google/oauth_credentials.json` | Duplicate — uses different Google project (`medihive-500611`) |
| `backend/medihive.db` | Legacy SQLite database — no longer used |
| `backend/sheet_id.json` | Legacy — sheet ID is now in `.env` |

---

## 4. Task 3 — API Route Analysis

### 4.1 Complete Route Map

| Endpoint | Method | Auth | Status | Notes |
|----------|--------|------|--------|-------|
| **Flask Routes (app.py)** | | | | |
| `GET /api/health` | GET | None | ✅ KEEP | Standard health check |
| `GET /` | GET | None | ✅ KEEP | Root redirect |
| `GET /debug-users` | GET | None | ⚠️ MODIFY | Debug endpoint — protect or remove in production |
| `GET /debug-sync` | GET | None | 🔴 REMOVE | Debug — depends on legacy sync |
| `GET /debug-google` | GET | None | 🔴 REMOVE | Debug — depends on `desktop_google` |
| **Auth Routes** | | | | |
| `POST /api/auth/login` | POST | None | ✅ KEEP | Mobile login (SHA-256) — add salt |
| `POST /api/auth/register` | POST | None | ✅ KEEP | Mobile registration |
| `GET /api/auth/me` | GET | JWT | ✅ KEEP | Current user info |
| **Patient Routes** | | | | |
| `GET /api/patients` | GET | JWT | ✅ KEEP | List patients |
| `GET /api/patients/<id>` | GET | JWT | ✅ KEEP | Get patient |
| `POST /api/patients` | POST | JWT | ✅ KEEP | Create patient |
| `PUT /api/patients/<id>` | PUT | JWT | ✅ KEEP | Update patient |
| `DELETE /api/patients/<id>` | DELETE | JWT | ✅ KEEP | Delete patient |
| **OPD Routes** | | | | |
| `GET /api/opd` | GET | JWT | ✅ KEEP | List OPD records |
| `GET /api/opd/<id>` | GET | JWT | ✅ KEEP | Get OPD record |
| `POST /api/opd` | POST | JWT | ✅ KEEP | Create OPD |
| `PUT /api/opd/<id>` | PUT | JWT | ✅ KEEP | Update OPD |
| `DELETE /api/opd/<id>` | DELETE | JWT | ✅ KEEP | Delete OPD |
| `GET /api/opd/<id>/debug-sheet` | GET | JWT | 🔴 REMOVE | Debug endpoint — desktop-only |
| `POST /api/opd/<id>/images` | POST | JWT | ⚠️ MODIFY | Replace `desktop_google` usage with new services |
| **Appointment Routes** | | | | |
| All 5 routes | GET/POST/PUT/DELETE | JWT | ✅ KEEP | Standard CRUD |
| **Sync Routes** | | | | |
| `POST /api/sync/pull` | POST | JWT | 🔴 REMOVE | Desktop-only sync |
| `POST /api/sync/push` | POST | JWT | 🔴 REMOVE | Desktop-only sync |
| `POST /api/sync/push/images/<opd_id>` | POST | JWT | 🔴 REMOVE | Desktop-only image upload |
| `POST /api/sync/clear-data` | POST | JWT | 🔴 REMOVE | Destructive — not needed |
| **Cloud Sync Routes** | | | | |
| `POST /api/cloud/register-device` | POST | None | ✅ KEEP | Mobile device registration |
| `POST /api/cloud/upload-changes` | POST | DeviceID | ⚠️ MODIFY | Consolidate with other upload |
| `POST /api/cloud/download-changes` | POST | DeviceID | ⚠️ MODIFY | Consolidate with other download |
| `POST /api/cloud/heartbeat` | POST | None | ✅ KEEP | Mobile heartbeat |
| `POST /api/cloud/upload-images/<opd_id>` | POST | None | ⚠️ MODIFY | Use new services |
| `GET /api/cloud/clinic-info` | GET | JWT | ✅ KEEP | Clinic info |
| **Sync Cloud Routes** | | | | |
| `POST /api/sync/upload` | POST | DeviceID | 🔴 REMOVE | Duplicate of `cloud/upload-changes` |
| `GET /api/sync/download` | GET | DeviceID | 🔴 REMOVE | Duplicate of `cloud/download-changes` |
| `POST /api/sync/ack` | POST | None | 🔴 REMOVE | Desktop ack — not needed |
| **Device Routes** | | | | |
| `POST /api/device/register` | POST | None | 🔴 REMOVE | Duplicate — merge with cloud/register-device |
| **FCM Routes** | | | | |
| `POST /api/fcm/token` | POST | JWT | ✅ KEEP | Mobile push token |
| **WhatsApp Routes** | | | | |
| `POST /api/whatsapp/send-prescription` | POST | JWT | ✅ KEEP | Mobile-prescription |

### 4.2 Route Summary

| Category | Count |
|----------|-------|
| Routes to KEEP | 28 |
| Routes to MODIFY | 5 |
| Routes to REMOVE | 13 |
| **Total Active Routes** | **41** |
| **Proposed Mobile-Only** | **~28** |

---

## 5. Task 4 — Synchronization Analysis

### 5.1 Current Sync Architecture (Desktop)

```
Desktop App ──JWT──> Flask API ──> PostgreSQL
                              └──> desktop_google/sheets_service.py ──> Google Sheets
                              └──> desktop_google/drive_service.py  ──> Google Drive
                              └──> desktop_google/sync_service.py   ──> Background queue

Mobile Device ──DeviceID──> Flask API ──> PostgreSQL
                              └──> desktop_google/sheets_service.py ──> Google Sheets
                              └──> desktop_google/drive_service.py  ──> Google Drive
```

### 5.2 Proposed Mobile-Only Sync Architecture

```
Android App ──JWT──> Flask API ──> PostgreSQL (Neon)
                                    │
                                    ├──> services/google_sheets_service.py ──> Google Sheets
                                    └──> services/google_drive_service.py  ──> Google Drive

Sync Flow:
1. Android creates/updates data locally (SQLite)
2. Android calls POST /api/sync/upload with changes
3. Flask API upserts into PostgreSQL
4. Flask API syncs OPD data to Google Sheets (async)
5. Flask API syncs images to Google Drive (async)
6. Other Android devices call GET /api/sync/download
```

### 5.3 Desktop Sync Code to Remove

| Component | Lines | Replacement |
|-----------|-------|-------------|
| `routes/sync.py` — all 4 endpoints | 507 | New simplified sync endpoints in a single file |
| `routes/cloud.py` — all redundant endpoints | ~200 | Consolidated into `sync.py` |
| `desktop_google/sync_service.py` | 389 | No replacement needed (was background queue) |
| `desktop_google/sync_queue.py` | 21 | No replacement needed |
| `desktop_google/drive_service.py` | 289 | New `services/google_drive_service.py` |
| `desktop_google/sheets_service.py` | 711 | New `services/google_sheets_service.py` |

### 5.4 Key Simplifications

- **No bidirectional sync**: Android devices sync via API calls (client-initiated)
- **No background sync loop**: Backend is stateless between requests
- **No sync queue table**: Remove from schema
- **No cloud_sync_log table**: Simplify or remove
- **One unified sync file**: Replace `sync.py` + `cloud.py` with one module

---

## 6. Task 5 — Database Architecture Review

### 6.1 Current Tables (11)

| # | Table | Purpose | Status |
|---|-------|---------|--------|
| 1 | `patients` | Patient records | ✅ KEEP |
| 2 | `opd_records` | OPD visit records | ✅ KEEP |
| 3 | `appointments` | Appointments | ✅ KEEP |
| 4 | `users` | Authentication | ✅ KEEP (improve password hashing) |
| 5 | `fcm_tokens` | Push notification tokens | ✅ KEEP |
| 6 | `clinics` | Clinic management | ✅ KEEP |
| 7 | `device_registry` | Mobile device tracking | ✅ KEEP |
| 8 | `deleted_entities` | Soft-delete tracking | ✅ KEEP |
| 9 | `settings` | Key-value config | ✅ KEEP |
| 10 | `last_sync` | Per-user sync timestamps | 🔴 REMOVE (desktop-only) |
| 11 | `cloud_sync_log` | Cloud sync audit log | ⚠️ SIMPLIFY |

### 6.2 Columns to Remove

**`patients` table:**
- `is_synced INTEGER DEFAULT 0` — desktop sync flag, not needed

**`opd_records` table:**
- `is_synced INTEGER DEFAULT 0` — desktop sync flag, not needed

**`appointments` table:**
- `is_synced INTEGER DEFAULT 0` — desktop sync flag, not needed

### 6.3 Columns to Add

- `patients`: `phone TEXT` (primary contact) — better indexing
- `opd_records`: `image_urls TEXT` (store Drive URLs directly)
- No sync-specific columns needed beyond `updated_at`

### 6.4 Schema Improvements

| Issue | Current | Proposed |
|-------|---------|----------|
| **ID format** | `P001`, `CLI001` — string keys | Keep format for mobile compatibility but use `TEXT` |
| **Date format** | Stored as `TEXT` strings | Keep for simplicity (ISO 8601) |
| **Fees** | All `TEXT` (`'0'`, `'500'`) | Change to `NUMERIC` or `INTEGER` |
| **Image links** | `TEXT` — comma-separated URLs | Keep `TEXT` (JSON array would be better) |
| **Password hashing** | SHA-256 (no salt) | Add bcrypt or argon2 |
| **`cloud_sync_log`** | 12 columns, detailed | Reduce to: `id, clinic_id, device_id, status, created_at` |

### 6.5 Migration Framework

| Current | Proposed |
|---------|----------|
| Inline `ALTER TABLE` with try/except in `database.py` | Adopt Alembic for versioned, reversible migrations |
| No migration history | `/backend/migrations/` directory |

---

## 7. Task 6 — Google Integration Review

### 7.1 Current State

```
GoogleAuthService (services/google_auth_service.py)
    ↓ NOT USED BY
    ↓
GoogleDriveService (services/google_drive_service.py)  ──── placeholder only
GoogleSheetsService (services/google_sheets_service.py) ── placeholder only

Instead, production code uses:
    desktop_google/drive_service.py   ──── 289 lines, active
    desktop_google/sheets_service.py  ──── 711 lines, active
```

### 7.2 Proposed Architecture

```
GoogleConfig (config/google_config.py)
    │
    ▼
GoogleAuthService (services/google_auth_service.py)
    │  get_credentials() returns Credentials
    │
    ├──► GoogleDriveService (services/google_drive_service.py)
    │       ▲ upload_file()
    │       ▲ download_file()
    │       ▲ list_files()
    │       ▲ create_folder()
    │
    └──► GoogleSheetsService (services/google_sheets_service.py)
            ▲ append_row()
            ▲ read_range()
            ▲ update_cell()
            ▲ clear_sheet()
```

### 7.3 Required Changes

1. **Implement** `GoogleDriveService` in `services/google_drive_service.py` — migrate logic from `desktop_google/drive_service.py`
2. **Implement** `GoogleSheetsService` in `services/google_sheets_service.py` — migrate logic from `desktop_google/sheets_service.py`
3. **Remove** `desktop_google/drive_service.py` and `desktop_google/sheets_service.py`
4. **Add** `drive_token.json` — keep single token in root, remove `desktop_google/drive_token.json`

### 7.4 OAuth Credential Cleanup

| Current | Action |
|---------|--------|
| `backend/oauth_credentials.json` | ✅ KEEP (medihive-marathi project) |
| `backend/drive_token.json` | ✅ KEEP (medihive-marathi project) |
| `backend/desktop_google/oauth_credentials.json` | 🔴 REMOVE (medihive-500611 project — wrong) |
| `backend/desktop_google/drive_token.json` | 🔴 REMOVE (medihive-500611 project — wrong) |

---

## 8. Task 7 — Full Recommendations

### 8.1 Files to KEEP (33 files)

All files listed in §3.1 above. Core business logic, models, config, new services, utilities, deployment, and tests.

### 8.2 Files to MODIFY (5 files)

| Priority | File | Effort | Impact |
|----------|------|--------|--------|
| **P0** | `backend/app.py` | 1 hour | Removes dead imports and registrations |
| **P0** | `backend/routes/sync.py` | 4 hours | Core sync rewrite for mobile-only |
| **P1** | `backend/routes/cloud.py` | 3 hours | Consolidation with sync.py |
| **P1** | `backend/routes/opd.py` | 1 hour | Replace desktop_google imports |
| **P2** | `backend/database.py` | 2 hours | Schema cleanup (remove is_synced, last_sync) |
| **P3** | `backend/scripts/validate_production.py` | 30 min | Update test endpoints |

### 8.3 Files to REMOVE (12 files)

| Priority | File | Reason |
|----------|------|--------|
| **P0** | `backend/desktop_google/` (entire directory — 9 files + 2 JSON) | Complete legacy package |
| **P1** | `backend/medihive.db` | Legacy SQLite file |
| **P1** | `backend/sheet_id.json` | Replaced by `.env` |

### 8.4 API Improvements

| # | Improvement | Details |
|---|-------------|---------|
| 1 | **Unified sync endpoints** | Replace `sync.py` (4 routes) + `cloud.py` (6 routes) with 2-3 consolidated routes |
| 2 | **Remove desktop sync** | Remove `POST /api/sync/pull`, `push`, `push/images`, `clear-data` |
| 3 | **Remove duplicates** | Remove `/api/sync/upload|download|ack` and `/api/device/register` |
| 4 | **Consistent auth** | All non-public endpoints use JWT (remove raw device_id auth) |
| 5 | **Remove debug endpoints** | Remove `/debug-users`, `/debug-sync`, `/debug-google`, `/api/opd/<id>/debug-sheet` |
| 6 | **Add sync endpoint** | Single `POST /api/sync` with action=`upload`|`download` parameter |
| 7 | **Standardize responses** | Consistent JSON envelope `{success, data?, error?}` |

### 8.5 Database Improvements

| # | Improvement | Details |
|---|-------------|---------|
| 1 | **Remove deprecated columns** | Drop `is_synced` from patients, opd_records, appointments |
| 2 | **Remove deprecated tables** | Drop `last_sync` table |
| 3 | **Simplify `cloud_sync_log`** | Reduce to 5 columns (id, clinic_id, device_id, status, created_at) |
| 4 | **Improve password hashing** | Replace SHA-256 with bcrypt (via `flask-bcrypt` or `passlib`) |
| 5 | **Add Alembic** | Add migration framework instead of inline `ALTER TABLE` |
| 6 | **Fix fee columns** | Change `TEXT` to `NUMERIC(10,2)` for fee columns |
| 7 | **Add indexes** | Add `idx_patients_mobile`, `idx_opd_clinic_date` |
| 8 | **Remove default admin** | Remove hardcoded `admin_medihive` / `1234567890` seed |

### 8.6 Sync Improvements

| # | Improvement | Details |
|---|-------------|---------|
| 1 | **Client-initiated sync** | Android app pushes changes when online, backend applies them |
| 2 | **No background jobs** | Backend syncs to Drive/Sheets synchronously during push |
| 3 | **No sync queue** | Remove queue-based sync — simpler request-response model |
| 4 | **last-write-wins** | Use `updated_at` for conflict resolution (sufficient for single-user clinics) |
| 5 | **Bulk sync** | Upload/download all changed entities in single request |
| 6 | **Sync images separately** | Upload images to Drive, store URL in DB, sync URL to Sheets |

### 8.7 Security Improvements

| # | Issue | Severity | Fix |
|---|-------|----------|-----|
| 1 | SHA-256 password hashing (no salt) | **HIGH** | Use bcrypt |
| 2 | Hardcoded default admin credentials | **HIGH** | Remove seed; require first-user registration |
| 3 | OAuth tokens committed to repo | **MEDIUM** | Already have `.gitignore` — verify no future leaks |
| 4 | Debug endpoints exposed without auth | **MEDIUM** | Remove or add admin-only auth |
| 5 | Device ID auth (no JWT) in cloud routes | **MEDIUM** | Standardize to JWT |
| 6 | No rate limiting | **LOW** | Add rate limiting on login/register |
| 7 | No input validation library | **LOW** | Add marshmallow or pydantic for request validation |

### 8.8 Performance Improvements

| # | Improvement | Details |
|---|-------------|---------|
| 1 | **Async Google API calls** | Use `asyncio` or thread pool for parallel Drive/Sheets operations |
| 2 | **Connection pool tuning** | Increase `DB_POOL_MAX` from 5 to match expected concurrency |
| 3 | **Add Redis cache** | Cache clinic info, user sessions, Google API tokens |
| 4 | **Batch Google Sheets writes** | Buffer multiple row writes instead of one per OPD |
| 5 | **Lazy Google service init** | Initialize Drive/Sheets services on first use, not at app startup |

### 8.9 Recommended Mobile-Only Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Android App                        │
│  (Local SQLite cache + JWT auth + Sync engine)       │
└──────────────────┬──────────────────────────────────┘
                   │ HTTPS / JSON
                   ▼
┌─────────────────────────────────────────────────────┐
│               Flask API (Cloud Run)                  │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                  │
│  │  Auth Routes  │  │  Data Routes │                  │
│  │  /api/auth    │  │  /api/patients                 │
│  │               │  │  /api/opd                      │
│  │               │  │  /api/appointments             │
│  └──────────────┘  └──────┬───────┘                  │
│                           │                          │
│  ┌──────────────┐  ┌──────▼───────┐                  │
│  │  Sync Route   │  │  Models      │                  │
│  │  /api/sync    │  │  (raw SQL)   │                  │
│  │  upload/      │  │              │                  │
│  │  download     │  └──────┬───────┘                  │
│  └──────────────┘         │                          │
│                           ▼                          │
│  ┌────────────────────────────────────────────────┐  │
│  │        PostgreSQL (Neon)                       │  │
│  │  Tables: patients, opd_records, appointments,   │  │
│  │          users, clinics, fcm_tokens,            │  │
│  │          device_registry, deleted_entities,     │  │
│  │          settings, cloud_sync_log (simplified)  │  │
│  └────────────────────────────────────────────────┘  │
│                           │                          │
│  ┌────────────────────────┼────────────────────────┐ │
│  │        GoogleAuthService                        │ │
│  │            │                                    │ │
│  │    ┌───────▼───────┐  ┌────────▼────────┐       │ │
│  │    │ GoogleDrive    │  │ GoogleSheets    │       │ │
│  │    │ Service        │  │ Service         │       │ │
│  │    │ (images)       │  │ (OPD rows)      │       │ │
│  │    └───────────────┘  └─────────────────┘       │ │
│  └──────────────────────────────────────────────────┘ │
│                                                      │
│  ┌──────────────┐  ┌──────────────┐                  │
│  │  FCM Service  │  │  WhatsApp    │                  │
│  │  (push notif) │  │  Cloud API   │                  │
│  └──────────────┘  └──────────────┘                  │
└─────────────────────────────────────────────────────┘
```

### 8.10 Migration Roadmap

| Phase | Tasks | Duration |
|-------|-------|----------|
| **Phase 1: Cleanup** | Remove `desktop_google/` package, remove dead files, update `.dockerignore` | 1 day |
| **Phase 2: Google Services** | Implement `GoogleDriveService` and `GoogleSheetsService` with centralized auth | 2 days |
| **Phase 3: Sync Rewrite** | Consolidate `sync.py` + `cloud.py` into single streamlined sync module | 2 days |
| **Phase 4: Database Cleanup** | Remove legacy columns/tables, add Alembic, improve password hashing | 2 days |
| **Phase 5: Route Cleanup** | Remove deprecated routes, standardize auth, add request validation | 1 day |
| **Phase 6: Security & Performance** | Rate limiting, async Google calls, Redis caching | 2 days |
| **Total** | | **~10 days** |

---

## Appendix: Desktop References in Production Code

Every case where active production code references desktop/legacy architecture:

| File | Line | Reference | Action |
|------|------|-----------|--------|
| `app.py` | 12 | `from routes.sync import sync_bp` | ⚠️ Desktop sync — move to new consolidated sync |
| `app.py` | 15 | `from routes.cloud import cloud_bp, sync_cloud_bp, device_bp` | ⚠️ Contains duplicates |
| `app.py` | 34-39 | Blueprint registrations for sync/cloud/device | ⚠️ Consolidate |
| `app.py` | 65 | `GET /debug-sync` | 🔴 Remove |
| `app.py` | 89 | `GET /debug-google` | 🔴 Remove |
| `app.py` | 150 | `initialize_google_services()` from `desktop_google` | 🔴 Replace with new services |
| `routes/sync.py` | 11-16 | `from desktop_google import drive_service, sheets_service` | 🔴 Replace |
| `routes/opd.py` | 8-9 | `from desktop_google import drive_service, sheets_service` | 🔴 Replace |
| `routes/cloud.py` | 10-12 | `from desktop_google import drive_service, sheets_service` | 🔴 Replace |
| `routes/cloud.py` | 29 | `_sync_opd_to_google_sheets()` → calls `sync._sync_opd_to_sheets()` | 🔴 Remove duplication |
| `config.py` | 26-29 | `DATABASE_PATH = os.getenv("DATABASE_PATH", "medihive.db")` | 🔴 Legacy SQLite path |
| `database.py` | 162,193,225 | `is_synced INTEGER DEFAULT 0` in CREATE TABLE | 🔴 Remove columns |
| `database.py` | 296-303 | `last_sync` table definition | 🔴 Remove table |
| `database.py` | 67 | Comment: "mimics sqlite3's connection.execute()" | ✅ Update comment |
