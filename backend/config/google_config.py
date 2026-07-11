"""Google Cloud configuration constants for the MediHive Marathi backend.

Loads environment variables and provides typed configuration values
for Google API integration (Drive, Sheets, Auth).
"""

from __future__ import annotations

import os

from dotenv import load_dotenv

_base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(_base_dir, ".env"))


class GoogleConfig:
    """Typed configuration container for Google API credentials and settings."""

    base_dir: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    project_id: str = os.getenv("GOOGLE_PROJECT_ID", "")
    sheet_id: str = os.getenv("GOOGLE_SHEET_ID", "")
    drive_root_folder_id: str = os.getenv("GOOGLE_DRIVE_ROOT_FOLDER_ID", "")
    client_id: str = os.getenv("GOOGLE_CLIENT_ID", "")
    client_secret: str = os.getenv("GOOGLE_CLIENT_SECRET", "")
    application_credentials: str = os.getenv(
        "GOOGLE_APPLICATION_CREDENTIALS",
        os.path.join(base_dir, "oauth_credentials.json"),
    )
    backend_url: str = os.getenv("BACKEND_URL", "")
    database_url: str = os.getenv("DATABASE_URL", "")

    token_path: str = os.path.join(base_dir, "drive_token.json")
    credentials_path: str = (
        application_credentials
        if os.path.isabs(application_credentials)
        else os.path.join(base_dir, application_credentials)
    )


config = GoogleConfig()
