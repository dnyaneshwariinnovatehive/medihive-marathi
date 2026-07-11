"""Google OAuth authentication service for MediHive Marathi.

Manages the OAuth 2.0 authorization flow, token storage,
and refresh logic for accessing Google APIs.

All Google services should obtain credentials through this class
to avoid duplicated authentication logic.
"""

from __future__ import annotations

import json
import os

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials


class GoogleAuthService:
    """Provides shared Google API credentials from drive_token.json."""

    def __init__(self, token_path: str) -> None:
        self._token_path = token_path
        self._creds: Credentials | None = None

    def get_credentials(self) -> Credentials | None:
        """Load and return credentials from drive_token.json.

        Automatically refreshes the token if it is expired and a
        refresh token is available.  Returns ``None`` when the token
        file is missing or cannot be parsed.
        """
        if not os.path.exists(self._token_path):
            return None

        try:
            with open(self._token_path) as f:
                token_data = json.load(f)
        except (json.JSONDecodeError, OSError):
            return None

        creds = Credentials(
            token=token_data.get("token"),
            refresh_token=token_data.get("refresh_token"),
            token_uri=token_data.get("token_uri"),
            client_id=token_data.get("client_id"),
            client_secret=token_data.get("client_secret"),
            scopes=token_data.get("scopes"),
        )

        if creds.expired and creds.refresh_token:
            creds.refresh(Request())

        self._creds = creds
        return creds

    def get_authorization_url(self) -> str:
        ...

    def exchange_code_for_token(self) -> None:
        ...

    def refresh_token(self) -> None:
        ...

    def revoke_token(self) -> None:
        ...
