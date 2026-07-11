"""Google Sheets API service for MediHive Marathi.

Handles reading from and writing to Google Sheets for
structured data export and synchronization.

Credentials are obtained through the shared ``GoogleAuthService``
so that authentication is centralised in a single place.
"""

from __future__ import annotations

from googleapiclient.discovery import build

from config.google_config import config
from services.google_auth_service import GoogleAuthService


class GoogleSheetsService:
    """Sheets operations backed by a live Google Sheets v4 service."""

    def __init__(self) -> None:
        self._service = self._build_service()

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _build_service():
        auth = GoogleAuthService(config.token_path)
        creds = auth.get_credentials()
        if creds is None:
            raise RuntimeError(
                "Google Sheets credentials not available. "
                "Run utils/generate_drive_token.py first."
            )
        return build("sheets", "v4", credentials=creds)

    # ------------------------------------------------------------------
    # Placeholder methods (to be implemented later)
    # ------------------------------------------------------------------

    def append_row(self) -> None:
        ...

    def read_range(self) -> None:
        ...

    def update_cell(self) -> None:
        ...

    def clear_sheet(self) -> None:
        ...
