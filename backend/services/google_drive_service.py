"""Google Drive API service for MediHive Marathi.

Handles file upload, download, listing, and folder management
via the Google Drive v3 API.

Credentials are obtained through the shared ``GoogleAuthService``
so that authentication is centralised in a single place.
"""

from __future__ import annotations

from googleapiclient.discovery import build

from config.google_config import config
from services.google_auth_service import GoogleAuthService


class GoogleDriveService:
    """Drive operations backed by a live Google Drive v3 service."""

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
                "Google Drive credentials not available. "
                "Run utils/generate_drive_token.py first."
            )
        return build("drive", "v3", credentials=creds)

    # ------------------------------------------------------------------
    # Placeholder methods (to be implemented later)
    # ------------------------------------------------------------------

    def upload_file(self) -> None:
        ...

    def download_file(self) -> None:
        ...

    def list_files(self) -> None:
        ...

    def create_folder(self) -> None:
        ...
