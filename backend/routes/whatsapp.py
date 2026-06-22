from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from services.whatsapp_cloud import send_prescription
import base64

whatsapp_bp = Blueprint('whatsapp', __name__)


@whatsapp_bp.route('/send-prescription', methods=['POST'])
@jwt_required()
def send_prescription_route():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body required'}), 400

    phone = data.get('phone', '').strip()
    file_base64 = data.get('file_base64', '')
    file_name = data.get('file_name', 'Prescription.pdf')

    if not phone:
        return jsonify({'error': 'Phone number required'}), 400
    if not file_base64:
        return jsonify({'error': 'File data required'}), 400

    try:
        file_bytes = base64.b64decode(file_base64)
    except Exception:
        return jsonify({'error': 'Invalid file data'}), 400

    if len(file_bytes) > 16 * 1024 * 1024:
        return jsonify({'error': 'File too large (max 16MB)'}), 400

    result = send_prescription(phone, file_bytes, file_name)
    status = 200 if result['success'] else 500
    return jsonify(result), status
