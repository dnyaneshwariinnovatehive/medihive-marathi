# Global Application Configuration — Architecture Report

## Summary

Created a centralized Settings system that loads from, persists to,
and serves application settings via REST API.  All settings are
accessible globally from any module without duplication.

---

## Files Created (4)

| # | File | Lines | Purpose |
|---|------|-------|---------|
| 1 | `backend/models/settings_model.py` | ~120 | Strongly-typed `SettingsModel` dataclass with serialization/deserialization |
| 2 | `backend/services/settings_manager.py` | ~150 | `SettingsManager` singleton — loads, caches, persists, notifies |
| 3 | `backend/routes/settings.py` | ~60 | REST API: `GET /api/settings`, `PUT /api/settings`, `POST /api/settings/reset` |
| 4 | (modified) `backend/app.py` | ~65 | Registers `settings_bp`, lazy-initializes settings on first request |

## Files Modified (1)

| # | File | Change |
|---|------|--------|
| 1 | `backend/app.py` | Added `from routes.settings import settings_bp`, registered `settings_bp` at `/api/settings`, added `before_request` hook to lazy-load settings on first HTTP request |

---

## Settings Architecture

```
                     ┌─────────────────────────┐
                     │   Android App / Client   │
                     └──────────┬──────────────┘
                                │ GET/PUT
                                ▼
                ┌───────────────────────────────┐
                │   GET  /api/settings          │
                │   PUT  /api/settings          │
                │   POST /api/settings/reset    │
                └──────────┬────────────────────┘
                           │
                ┌──────────▼────────────────────┐
                │  routes/settings.py            │
                │  (just delegates to manager)   │
                └──────────┬────────────────────┘
                           │
                ┌──────────▼────────────────────┐
                │  services/settings_manager.py  │◄── Singleton
                │                                │    shared by all
                │  ┌────────────┐  ┌───────────┐ │    backend modules
                │  │ In-memory  │  │ Listener   │ │
                │  │ cache      │  │ registry   │ │
                │  └─────┬──────┘  └───────────┘ │
                │        │                        │
                │  ┌─────▼────────────────────┐   │
                │  │  DB persistence           │   │
                │  │  (settings table)         │   │
                │  └──────────────────────────┘   │
                └─────────────────────────────────┘
                           │
                ┌──────────▼────────────────────┐
                │  models/settings_model.py      │
                │                                 │
                │  SettingsModel dataclass        │
                │  ├─ to_dict()  → JSON response │
                │  ├─ from_raw() → from payload  │
                │  ├─ from_db_rows() → from DB   │
                │  ├─ to_db_rows() → for INSERT  │
                │  └─ defaults() → factory reset │
                └─────────────────────────────────┘
                           │
                ┌──────────▼────────────────────┐
                │  database.py                   │
                │   settings TABLE               │
                │   key TEXT PRIMARY KEY         │
                │   value TEXT NOT NULL          │
                └─────────────────────────────────┘
```

### Data Flow

1. **Startup**: First HTTP request triggers `before_request` → `settings_manager.load()`. Loads all rows from `settings` table. If table is empty, inserts defaults.

2. **Read**: Any module calls `settings_manager.get()` to get the cached `SettingsModel`. No DB hit on subsequent reads.

3. **Write**: Client `PUT /api/settings` with partial payload → `settings_manager.update(partial)` → merges with current → persists all rows via upsert → updates in-memory cache → notifies listeners.

4. **Reset**: Client `POST /api/settings/reset` → overwrites all rows with defaults.

---

## Default Settings

| Key | Default | Type | Description |
|-----|---------|------|-------------|
| `language` | `"en"` | string | ISO language code (`"en"`, `"mr"`, etc.) |
| `theme` | `"light"` | string | `"light"` or `"dark"` |
| `notifications_enabled` | `true` | bool | Push notification toggle |
| `auto_sync_enabled` | `true` | bool | Auto-sync to cloud toggle |
| `doctor_name` | `""` | string | Doctor's display name |
| `clinic_name` | `""` | string | Clinic display name |
| `clinic_address` | `""` | string | Clinic address |
| `clinic_phone` | `""` | string | Clinic contact number |

---

## How Future Features Will Use This Manager

### Adding a new setting

1. Add a field to `SettingsModel` dataclass with a default value:

```python
@dataclass
class SettingsModel:
    language: str = "en"
    theme: str = "light"
    # ... existing fields ...
    new_feature_enabled: bool = False   # ← new field
```

2. The `from_raw()`, `to_dict()`, and `to_db_rows()` methods all work automatically. No other code changes needed.

### Reading settings from any backend module

```python
from services.settings_manager import settings_manager

s = settings_manager.get()
print(s.language)           # "en"
print(s.clinic_name)        # "My Clinic"
print(s.notifications_enabled)  # True
```

### Reacting to changes

```python
from services.settings_manager import settings_manager

def on_settings_change(new_settings):
    print(f"Language changed to {new_settings.language}")

unsubscribe = settings_manager.subscribe(on_settings_change)

# Later, when no longer needed:
unsubscribe()
```

### API-driven consumption (e.g. Flutter)

```
GET  /api/settings  →  { "settings": { ... } }
PUT  /api/settings  ←  { "language": "mr" }
```

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Settings stored as `key TEXT, value TEXT`** | Reuses existing `settings` table. No schema migration needed. Forward-compatible — new fields don't require new columns. |
| **In-memory cache** | Avoids DB lookup on every request. Settings change infrequently. |
| **Partial updates** | Client sends only changed fields. Manager merges with current state. |
| **Boolean stored as `"true"` / `"false"`** | SQLite/PostgreSQL TEXT column. Easy to read and debug. |
| **Lazy init on first request** | Module can be imported without a live DB connection. Tests and scripts don't need a running PostgreSQL. |
| **Listener pattern** | Future features (e.g. language switch, theme switch) can react to settings changes without tight coupling. |
| **Forward-compatible `from_raw()`** | Unknown keys are silently ignored, so old code won't crash when newer settings are added. |
