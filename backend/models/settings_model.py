"""Settings model for MediHive Marathi.

Provides a strongly-typed settings object with JSON serialization,
default values, and field validation.

The settings are stored in the database ``settings`` table
(key-value) and cached in memory by SettingsManager.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field, asdict
from typing import Optional


DEFAULT_SETTINGS = {
    "language": "en",
    "theme": "light",
    "notifications_enabled": "true",
    "auto_sync_enabled": "true",
    "doctor_name": "",
    "clinic_name": "",
    "clinic_address": "",
    "clinic_phone": "",
}


@dataclass
class SettingsModel:
    """Application-wide settings with defaults.

    Every field has a default so new settings can be added without
    breaking existing data.  Fields are stored as strings in the DB
    and converted to the appropriate Python type on access.
    """
    language: str = "en"
    theme: str = "light"
    notifications_enabled: bool = True
    auto_sync_enabled: bool = True
    doctor_name: str = ""
    clinic_name: str = ""
    clinic_address: str = ""
    clinic_phone: str = ""

    # Internal metadata
    _raw: dict[str, str] = field(default_factory=dict, repr=False, compare=False)

    # ── Serialisation ────────────────────────────────────────────

    def to_dict(self) -> dict:
        """Return a plain dict with Python types suitable for JSON responses."""
        return {
            "language": self.language,
            "theme": self.theme,
            "notifications_enabled": self.notifications_enabled,
            "auto_sync_enabled": self.auto_sync_enabled,
            "doctor_name": self.doctor_name,
            "clinic_name": self.clinic_name,
            "clinic_address": self.clinic_address,
            "clinic_phone": self.clinic_phone,
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict())

    # ── Deserialisation ──────────────────────────────────────────

    @classmethod
    def from_db_rows(cls, rows: list[dict]) -> SettingsModel:
        """Build a SettingsModel from a list of ``{key, value}`` dicts.

        ``rows`` is the result of ``SELECT key, value FROM settings``.
        Missing keys receive their default value.
        """
        raw = {row["key"]: row["value"] for row in rows}
        return cls.from_raw(raw)

    @classmethod
    def from_raw(cls, raw: dict[str, str]) -> SettingsModel:
        """Build a SettingsModel from a key-value dict (e.g. an API payload).

        Keys that are not recognised are silently ignored so that
        forward-compatible payloads (with newer fields) still work.
        """
        kwargs = {}
        for field_name in cls._field_names():
            default = getattr(cls, field_name)
            raw_value = raw.get(field_name)

            if raw_value is None:
                kwargs[field_name] = default
            elif isinstance(default, bool):
                kwargs[field_name] = cls._to_bool(raw_value)
            elif isinstance(default, str):
                kwargs[field_name] = str(raw_value)
            else:
                kwargs[field_name] = raw_value

        instance = cls(**kwargs)
        instance._raw = raw
        return instance

    @classmethod
    def defaults(cls) -> SettingsModel:
        """Return a SettingsModel populated entirely with defaults."""
        return cls()

    # ── Diff helpers (for partial updates) ───────────────────────

    def to_db_rows(self) -> list[dict]:
        """Convert the current state to rows suitable for the settings table.

        Returns ``[{key, value}, …]`` — usable directly with the
        ``INSERT … ON CONFLICT DO UPDATE`` pattern.
        """
        rows = []
        d = self.to_dict()
        for k, v in d.items():
            if isinstance(v, bool):
                v = "true" if v else "false"
            else:
                v = str(v)
            rows.append({"key": k, "value": v})
        return rows

    # ── Internal helpers ─────────────────────────────────────────

    @staticmethod
    def _field_names() -> list[str]:
        """Return field names in declaration order (excluding ``_raw``)."""
        return [f.name for f in fields(SettingsModel) if not f.name.startswith("_")]

    @staticmethod
    def _to_bool(v) -> bool:
        if isinstance(v, bool):
            return v
        if isinstance(v, str):
            return v.lower() in ("1", "true", "yes", "on")
        return bool(v)


# Avoid circular import at module level
from dataclasses import fields  # noqa: E402
