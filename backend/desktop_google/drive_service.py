"""
drive_service.py
================
Uploads patient images to YOUR personal Google Drive using OAuth token.

WHY OAUTH INSTEAD OF SERVICE ACCOUNT:
- Service accounts have 0 storage quota (causes storageQuotaExceeded)
- OAuth token represents YOUR personal Google account
- Files upload into YOUR Drive using YOUR 15GB quota
- No quota errors, no shared drives needed

HOW IT WORKS:
1. One-time: run generate_drive_token.py to authorize
2. Token saved to drive_token.json (path set in config.py as DRIVE_TOKEN_PATH)
3. This service loads that token on every upload
4. Token auto-refreshes — never expires

FOLDER STRUCTURE IN YOUR DRIVE:
  All images upload directly into the 'MediHive Images' root folder.
  No subfolders are created — filenames are prefixed with OPD ID to
  avoid collisions (e.g. R001_image_1.jpeg).
"""

import io
import json
from pathlib import Path

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseUpload
from googleapiclient.errors import HttpError

from config import (
    DRIVE_ROOT_FOLDER_ID,
    DRIVE_TOKEN_PATH,
    DRIVE_TOKEN_JSON
)
from services.log_service import get_logger

logger = get_logger(__name__)

SCOPES = ["https://www.googleapis.com/auth/drive"]


def get_drive_service():
    """
    Load personal OAuth token and return Drive API client.
    Credentials can come from DRIVE_TOKEN_JSON env var (cloud) or drive_token.json file (local).
    Token auto-refreshes when expired — no manual action needed.
    """
    token_path = Path(DRIVE_TOKEN_PATH)
    logger.info("DRIVE_AUTH: loading token from path=%s has_env_var=%s",
                DRIVE_TOKEN_PATH, bool(DRIVE_TOKEN_JSON))

    if DRIVE_TOKEN_JSON:
        logger.info("DRIVE_AUTH: loading Drive token from DRIVE_TOKEN_JSON env var")
        try:
            info = json.loads(DRIVE_TOKEN_JSON)
            creds = Credentials.from_authorized_user_info(info, SCOPES)
            logger.info("DRIVE_AUTH: token loaded from env var, valid=%s expired=%s has_refresh=%s",
                        creds.valid, creds.expired, bool(creds.refresh_token))
        except Exception as e:
            logger.error("DRIVE_AUTH: failed to load token from env var: %s", e)
            raise
    else:
        if not token_path.exists():
            logger.error("DRIVE_AUTH: token file not found at %s", DRIVE_TOKEN_PATH)
            raise FileNotFoundError(
                f"drive_token.json not found at: {DRIVE_TOKEN_PATH}\n"
                "Run once from your project root:\n"
                "  python generate_drive_token.py"
            )
        logger.info("DRIVE_AUTH: loading token from file: %s", token_path)
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
        logger.info("DRIVE_AUTH: token loaded from file, valid=%s expired=%s has_refresh=%s",
                    creds.valid, creds.expired, bool(creds.refresh_token))

    # Auto-refresh if expired
    if not creds.valid:
        if creds.expired and creds.refresh_token:
            logger.info("DRIVE_AUTH: OAuth token expired — refreshing...")
            try:
                creds.refresh(Request())
                token_str = creds.to_json()
                logger.info("DRIVE_AUTH: token refresh SUCCESS")
                if DRIVE_TOKEN_JSON:
                    pass  # Can't persist env var, logging is fine
                else:
                    with open(str(token_path), "w", encoding="utf-8") as f:
                        f.write(token_str)
                    logger.info("DRIVE_AUTH: refreshed token saved to file")
            except Exception as e:
                logger.error("DRIVE_AUTH: token refresh FAILED: %s", e)
                raise
        else:
            logger.error("DRIVE_AUTH: token invalid and cannot be refreshed. valid=%s expired=%s has_refresh=%s",
                         creds.valid, creds.expired, bool(creds.refresh_token))
            raise RuntimeError(
                "OAuth token is invalid and cannot be refreshed.\n"
                "Run again: python generate_drive_token.py"
            )

    service = build("drive", "v3", credentials=creds)
    logger.info("DRIVE_AUTH: Drive API service created successfully")
    return service


def check_existing_drive_files(opd_id, visit_date, expected_count):
    """
    Check if OPD images already exist in the root 'MediHive Images' folder.
    Returns list of public URLs if enough files found.
    Returns empty list if none or fewer files found.
    """
    if not DRIVE_ROOT_FOLDER_ID:
        return []

    service = get_drive_service()

    query = (
        f"name contains '{opd_id}' "
        f"and '{DRIVE_ROOT_FOLDER_ID}' in parents "
        f"and trashed=false"
    )
    response = service.files().list(
        q=query,
        fields="files(id, name)"
    ).execute()
    existing_files = response.get("files", [])

    if len(existing_files) >= expected_count:
        logger.info(
            "Found %d existing file(s) in Drive for OPD %s, skipping upload",
            len(existing_files), opd_id
        )
        return [
            f"https://drive.google.com/file/d/{f['id']}/view"
            for f in existing_files
        ]

    logger.info(
        "Found %d existing file(s) in Drive for OPD %s, need %d — proceeding with upload",
        len(existing_files), opd_id, expected_count
    )
    return []


def upload_images_to_drive(opd_id, image_records, visit_date):
    """
    Upload all images for one OPD visit to the existing 'MediHive Images' folder.
    No subfolders are created — all images go directly into the root folder.
    Returns list of public view URLs in same order as image_records.
    """
    if not DRIVE_ROOT_FOLDER_ID:
        logger.error("DRIVE_ROOT_FOLDER_ID is empty in config.py")
        raise ValueError(
            "DRIVE_ROOT_FOLDER_ID is empty in config.py\n"
            "Open your MediHive Images folder in Drive, copy the ID from the URL."
        )

    logger.info(
        "DRIVE_UPLOAD: Starting batch upload: OPD=%s root_folder=%s record_count=%d",
        opd_id, DRIVE_ROOT_FOLDER_ID, len(image_records)
    )

    service = get_drive_service()
    uploaded_links = []

    for idx, image in enumerate(image_records, 1):
        local_path = Path(image.file_path)

        if not local_path.exists():
            logger.warning("DRIVE_UPLOAD: Image missing on disk: %s (index=%d)", local_path, idx)
            continue

        file_size = local_path.stat().st_size
        logger.info("DRIVE_UPLOAD: Starting file upload: OPD=%s index=%d path=%s size=%d bytes",
                    opd_id, idx, local_path, file_size)

        try:
            # Prefix filename with OPD ID to avoid name collisions in flat folder
            safe_name = f"{opd_id}_{local_path.name}"
            logger.info("DRIVE_UPLOAD: Creating Drive file: name=%s", safe_name)

            media = MediaFileUpload(str(local_path), resumable=True)

            uploaded = service.files().create(
                body={
                    "name": safe_name,
                    "parents": [DRIVE_ROOT_FOLDER_ID]
                },
                media_body=media,
                fields="id"
            ).execute()

            file_id = uploaded["id"]
            logger.info("DRIVE_UPLOAD: File created: file_id=%s name=%s", file_id, safe_name)

            # Make file publicly viewable (anyone with link)
            logger.info("DRIVE_UPLOAD: Setting public permission for file_id=%s", file_id)
            service.permissions().create(
                fileId=file_id,
                body={"type": "anyone", "role": "reader"}
            ).execute()
            logger.info("DRIVE_UPLOAD: Public permission set for file_id=%s", file_id)

            public_url = f"https://drive.google.com/file/d/{file_id}/view"
            uploaded_links.append(public_url)

            logger.info("DRIVE_UPLOAD: SUCCESS: index=%d name=%s url=%s", idx, safe_name, public_url)

        except HttpError as e:
            logger.error("DRIVE_UPLOAD: FAILED: index=%d name=%s error=%s",
                        idx, local_path.name, e)
            raise

    logger.info(
        "DRIVE_UPLOAD: Batch complete: %d/%d image(s) uploaded for OPD %s",
        len(uploaded_links), len(image_records), opd_id
    )

    return uploaded_links


def upload_image_fileobj_to_drive(opd_id, file_storage, index):
    """
    Upload a single image from a Flask FileStorage object directly to Drive.
    Uses in-memory BytesIO to avoid Windows file-locking issues.
    Returns the public Drive URL.

    This function is cloud-compatible — it does not require a permanent
    local storage directory.
    """
    logger.info("DRIVE_UPLOAD_FILEOBJ: START: OPD=%s index=%d filename=%s content_type=%s",
                opd_id, index, file_storage.filename, file_storage.content_type)

    # Read file content into memory — no temp file, no Windows locking
    content = file_storage.read()
    content_len = len(content)
    logger.info("DRIVE_UPLOAD_FILEOBJ: Read file content: OPD=%s index=%d size=%d bytes",
                opd_id, index, content_len)

    if content_len == 0:
        logger.error("DRIVE_UPLOAD_FILEOBJ: Empty file content for OPD=%s index=%d", opd_id, index)
        return None

    file_io = io.BytesIO(content)

    service = get_drive_service()
    filename = file_storage.filename or f"image_{index}.jpg"
    safe_name = f"{opd_id}_{index:02d}_{filename}"
    logger.info("DRIVE_UPLOAD_FILEOBJ: safe_name=%s size=%d", safe_name, content_len)

    mimetype = file_storage.content_type or 'image/jpeg'
    media = MediaIoBaseUpload(file_io, mimetype=mimetype, resumable=True)

    logger.info("DRIVE_UPLOAD_FILEOBJ: Calling files().create() for %s", safe_name)
    try:
        uploaded = service.files().create(
            body={"name": safe_name, "parents": [DRIVE_ROOT_FOLDER_ID]},
            media_body=media,
            fields="id"
        ).execute()
    except HttpError as e:
        logger.error("DRIVE_UPLOAD_FILEOBJ: files().create() FAILED: OPD=%s index=%d error=%s",
                     opd_id, index, e)
        raise
    except Exception as e:
        logger.error("DRIVE_UPLOAD_FILEOBJ: files().create() FAILED (non-HTTP): OPD=%s index=%d error=%s",
                     opd_id, index, e)
        raise

    file_id = uploaded["id"]
    logger.info("DRIVE_UPLOAD_FILEOBJ: files().create() SUCCESS: file_id=%s", file_id)

    logger.info("DRIVE_UPLOAD_FILEOBJ: Setting public permissions for file_id=%s", file_id)
    try:
        service.permissions().create(
            fileId=file_id,
            body={"type": "anyone", "role": "reader"}
        ).execute()
        logger.info("DRIVE_UPLOAD_FILEOBJ: Permission set SUCCESS for file_id=%s", file_id)
    except HttpError as e:
        logger.error("DRIVE_UPLOAD_FILEOBJ: Permission set FAILED for file_id=%s: %s", file_id, e)
        raise

    public_url = f"https://drive.google.com/file/d/{file_id}/view"
    logger.info("DRIVE_UPLOAD_FILEOBJ: COMPLETE: OPD=%s index=%d url=%s", opd_id, index, public_url)
    return public_url
