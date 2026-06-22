from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.fcm_service import save_fcm_token

fcm_bp = Blueprint('fcm', __name__)


@fcm_bp.route('/token', methods=['POST'])
@jwt_required()
def register_token():
    data = request.get_json()
    if not data or not data.get('fcm_token'):
        return jsonify({'error': 'fcm_token is required'}), 400

    user_id = get_jwt_identity()
    save_fcm_token(data['fcm_token'], user_id)
    return jsonify({'status': 'ok'}), 200
