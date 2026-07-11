"""Backward-compatible cloud sync endpoints for MediHive Marathi.

All routes now delegate to the consolidated sync module.
New mobile clients should use /api/sync/* endpoints directly.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.clinic import Clinic
from models.device_registry import DeviceRegistry
from database import get_db
from datetime import datetime
from services.log_service import get_logger

logger = get_logger(__name__)

cloud_bp = Blueprint('cloud', __name__)


@cloud_bp.route('/register-device', methods=['POST'])
def register_device():
    from routes.sync import register_device
    return register_device()


@cloud_bp.route('/heartbeat', methods=['POST'])
def heartbeat():
    from routes.sync import heartbeat
    return heartbeat()


@cloud_bp.route('/upload-images/<opd_id>', methods=['POST'])
def cloud_upload_images(opd_id):
    from routes.sync import sync_upload_images
    return sync_upload_images(opd_id)


@cloud_bp.route('/clinic-info', methods=['GET'])
@jwt_required()
def clinic_info():
    from routes.sync import clinic_info
    return clinic_info()


@cloud_bp.route('/upload-changes', methods=['POST'])
@jwt_required()
def upload_changes():
    from routes.sync import sync_upload
    return sync_upload()


@cloud_bp.route('/download-changes', methods=['POST'])
@jwt_required()
def download_changes():
    from routes.sync import sync_download
    return sync_download()


@cloud_bp.route('/full-restore', methods=['GET'])
@jwt_required()
def full_restore():
    from routes.sync import full_restore
    return full_restore()
