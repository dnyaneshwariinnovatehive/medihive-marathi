import sqlite3
from config import DATABASE_PATH


def get_db():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db():
    conn = get_db()
    cursor = conn.cursor()

    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS patients (
            id          TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            dob         TEXT DEFAULT '',
            age         INTEGER DEFAULT 0,
            gender      TEXT DEFAULT 'Not Specified',
            blood_group TEXT DEFAULT 'Not Specified',
            mobile      TEXT DEFAULT '',
            address     TEXT DEFAULT '',
            last_diagnosis   TEXT DEFAULT '',
            last_visit_date  TEXT DEFAULT '',
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL,
            is_synced   INTEGER DEFAULT 0,
            user_id     TEXT DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS opd_records (
            id                  TEXT PRIMARY KEY,
            patient_id          TEXT NOT NULL,
            type                TEXT DEFAULT 'consultation',
            symptoms            TEXT DEFAULT '',
            diagnosis           TEXT DEFAULT '',
            medicines           TEXT DEFAULT '',
            visit_date          TEXT NOT NULL,
            clinical_notes      TEXT DEFAULT '',
            consultation_fee    TEXT DEFAULT '0',
            medicine_fee        TEXT DEFAULT '0',
            discount            TEXT DEFAULT '0',
            payment_mode        TEXT DEFAULT '',
            charge_type         TEXT DEFAULT '',
            previous_visit_date TEXT DEFAULT '',
            follow_up_reason    TEXT DEFAULT '',
            next_visit          TEXT DEFAULT '',
            blood_group         TEXT DEFAULT '',
            image_links         TEXT DEFAULT '',
            created_at          TEXT NOT NULL,
            updated_at          TEXT NOT NULL,
            is_synced           INTEGER DEFAULT 0,
            user_id             TEXT DEFAULT '',
            FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS appointments (
            id          TEXT PRIMARY KEY,
            patient_id  TEXT DEFAULT '',
            patient_name TEXT DEFAULT '',
            date_time   TEXT NOT NULL,
            notes       TEXT DEFAULT '',
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL,
            is_synced   INTEGER DEFAULT 0,
            user_id     TEXT DEFAULT ''
        );

        CREATE TABLE IF NOT EXISTS users (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            username    TEXT UNIQUE NOT NULL,
            password    TEXT NOT NULL,
            name        TEXT DEFAULT 'Doctor',
            created_at  TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS fcm_tokens (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            fcm_token   TEXT NOT NULL,
            user_id     TEXT DEFAULT '',
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL
        );

        CREATE UNIQUE INDEX IF NOT EXISTS idx_fcm_token ON fcm_tokens(fcm_token);

        CREATE INDEX IF NOT EXISTS idx_opd_patient ON opd_records(patient_id);
        CREATE INDEX IF NOT EXISTS idx_opd_visit   ON opd_records(visit_date);
        CREATE INDEX IF NOT EXISTS idx_appt_date   ON appointments(date_time);
    """)

    # Migration: add image_links column for existing databases
    try:
        cursor.execute("ALTER TABLE opd_records ADD COLUMN image_links TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass  # column already exists

    # Migration: add user_id columns for multi-device sync
    try:
        cursor.execute("ALTER TABLE patients ADD COLUMN user_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE opd_records ADD COLUMN user_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE appointments ADD COLUMN user_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass

    # Migration: add clinic_id for multi-clinic cloud sync
    try:
        cursor.execute("ALTER TABLE patients ADD COLUMN clinic_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE opd_records ADD COLUMN clinic_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE appointments ADD COLUMN clinic_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE users ADD COLUMN clinic_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass
    try:
        cursor.execute("ALTER TABLE deleted_entities ADD COLUMN clinic_id TEXT DEFAULT ''")
    except sqlite3.OperationalError:
        pass

    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS deleted_entities (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id   TEXT NOT NULL,
            deleted_at  TEXT NOT NULL,
            user_id     TEXT DEFAULT ''
        );

        CREATE INDEX IF NOT EXISTS idx_deleted_at ON deleted_entities(deleted_at);
        CREATE INDEX IF NOT EXISTS idx_deleted_type_id ON deleted_entities(entity_type, entity_id);

        CREATE TABLE IF NOT EXISTS last_sync (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     TEXT NOT NULL UNIQUE,
            last_sync   TEXT NOT NULL,
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS settings (
            key         TEXT PRIMARY KEY,
            value       TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS clinics (
            id          TEXT PRIMARY KEY,
            name        TEXT NOT NULL,
            email       TEXT DEFAULT '',
            phone       TEXT DEFAULT '',
            address     TEXT DEFAULT '',
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS device_registry (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id   TEXT NOT NULL UNIQUE,
            device_name TEXT DEFAULT '',
            clinic_id   TEXT NOT NULL,
            fcm_token   TEXT DEFAULT '',
            app_version TEXT DEFAULT '',
            last_seen   TEXT DEFAULT '',
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL
        );

        CREATE INDEX IF NOT EXISTS idx_device_registry_clinic ON device_registry(clinic_id);

        CREATE TABLE IF NOT EXISTS cloud_sync_log (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            clinic_id       TEXT NOT NULL,
            device_id       TEXT DEFAULT '',
            direction       TEXT NOT NULL,
            patients_count  INTEGER DEFAULT 0,
            opd_count       INTEGER DEFAULT 0,
            appointments_count INTEGER DEFAULT 0,
            deleted_count   INTEGER DEFAULT 0,
            status          TEXT DEFAULT 'success',
            error_message   TEXT DEFAULT '',
            created_at      TEXT NOT NULL
        );
    """)

    conn.commit()
    conn.close()
