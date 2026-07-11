"""REST API for application settings.

Endpoints
---------
GET    /api/settings  — Return all current settings.
PUT    /api/settings  — Update one or more settings (partial).
POST   /api/settings/reset — Reset all settings to defaults.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models.settings_model import SettingsModel
from services.settings_manager import settings_manager
from services.log_service import get_logger

logger = get_logger(__name__)

settings_bp = Blueprint("settings", __name__)


@settings_bp.route("", methods=["GET"])
@jwt_required()
def get_settings():
    """Return all current application settings."""
    s = settings_manager.get()
    return jsonify({"settings": s.to_dict()}), 200


@settings_bp.route("", methods=["PUT"])
@jwt_required()
def update_settings():
    """Update one or more settings (partial update).

    Only the keys present in the request body are changed.
    Unrecognised keys are silently ignored.
    """
    data = request.get_json(silent=True) or {}
    if not data:
        return jsonify({"error": "Request body required"}), 400

    # Strip any wrapping key
    payload = data.get("settings", data)

    # Validate that all keys are recognised
    known = set(SettingsModel._field_names())
    unknown = set(payload.keys()) - known
    if unknown:
        return jsonify({
            "error": f"Unknown settings fields: {', '.join(sorted(unknown))}",
        }), 422

    updated = settings_manager.update(payload)
    return jsonify({"settings": updated.to_dict(), "message": "Settings updated"}), 200


@settings_bp.route("/reset", methods=["POST"])
@jwt_required()
def reset_settings():
    """Reset all settings to factory defaults."""
    defaults = settings_manager.reset()
    return jsonify({"settings": defaults.to_dict(), "message": "Settings reset to defaults"}), 200
