"""Utility script to generate drive_token.json via OAuth authorization.

Run this script to walk through the OAuth consent flow and produce
a valid drive_token.json file for use by the backend services.
"""

from __future__ import annotations

import json
import os
import sys

# Allow running directly via python backend/utils/<script>.py
_current = os.path.dirname(os.path.abspath(__file__))
_backend_dir = os.path.dirname(_current)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    "https://www.googleapis.com/auth/drive",
    "https://www.googleapis.com/auth/spreadsheets",
]

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKEND_DIR = os.path.dirname(SCRIPT_DIR)

CREDENTIALS_PATH = os.path.join(BACKEND_DIR, "oauth_credentials.json")
TOKEN_PATH = os.path.join(BACKEND_DIR, "drive_token.json")


def main() -> None:
    if not os.path.exists(CREDENTIALS_PATH):
        print(
            f"Error: oauth_credentials.json not found at {CREDENTIALS_PATH}",
            file=sys.stderr,
        )
        sys.exit(1)

    flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_PATH, SCOPES)

    creds = flow.run_local_server(open_browser=True)

    token_data = {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": creds.client_id,
        "client_secret": creds.client_secret,
        "scopes": creds.scopes,
        "expiry": creds.expiry.isoformat() if creds.expiry else "",
    }

    with open(TOKEN_PATH, "w") as f:
        json.dump(token_data, f, indent=2)

    print(f"Success: drive_token.json generated at {TOKEN_PATH}")


if __name__ == "__main__":
    main()
