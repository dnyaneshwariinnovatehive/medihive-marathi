import requests
import json
import base64
import logging
from config import WHATSAPP_TOKEN, WHATSAPP_PHONE_NUMBER_ID, WHATSAPP_API_BASE

logger = logging.getLogger(__name__)


def _headers():
    return {
        'Authorization': f'Bearer {WHATSAPP_TOKEN}',
        'Content-Type': 'application/json',
    }


def upload_media(file_bytes: bytes, file_name: str) -> str | None:
    if not WHATSAPP_TOKEN:
        logger.warning('WHATSAPP_TOKEN not configured')
        return None

    url = f'{WHATSAPP_API_BASE}/{WHATSAPP_PHONE_NUMBER_ID}/media'
    try:
        resp = requests.post(
            url,
            headers={'Authorization': f'Bearer {WHATSAPP_TOKEN}'},
            files={
                'file': (file_name, file_bytes, 'application/pdf'),
                'messaging_product': (None, 'whatsapp'),
            },
            timeout=30,
        )
        data = resp.json()
        if resp.status_code == 200 and 'id' in data:
            logger.info(f'Media uploaded, ID: {data["id"]}')
            return data['id']
        logger.error(f'Media upload failed: {data}')
        return None
    except Exception as e:
        logger.error(f'Media upload error: {e}')
        return None


def send_document(
    to_phone: str,
    media_id: str,
    caption: str = '',
    file_name: str = 'Prescription.pdf',
) -> bool:
    if not WHATSAPP_TOKEN:
        logger.warning('WHATSAPP_TOKEN not configured')
        return False

    url = f'{WHATSAPP_API_BASE}/{WHATSAPP_PHONE_NUMBER_ID}/messages'

    body = {
        'messaging_product': 'whatsapp',
        'to': to_phone,
        'type': 'document',
        'document': {
            'id': media_id,
            'filename': file_name,
            'caption': caption,
        },
    }

    try:
        resp = requests.post(url, headers=_headers(), json=body, timeout=15)
        data = resp.json()
        if resp.status_code == 200 and data.get('messages'):
            logger.info(f'Document sent to {to_phone}')
            return True
        logger.error(f'Send failed: {data}')
        return False
    except Exception as e:
        logger.error(f'Send error: {e}')
        return False


def send_prescription(to_phone: str, file_bytes: bytes, file_name: str) -> dict:
    if not WHATSAPP_TOKEN:
        return {'success': False, 'error': 'WhatsApp API not configured - set WHATSAPP_TOKEN'}

    phone = to_phone.replace('+', '').replace(' ', '')
    if not phone.startswith('91') and len(phone) == 10:
        phone = '91' + phone

    media_id = upload_media(file_bytes, file_name)
    if not media_id:
        return {'success': False, 'error': 'Failed to upload media to WhatsApp'}

    sent = send_document(phone, media_id, file_name=file_name)
    if not sent:
        return {'success': False, 'error': 'Failed to send message via WhatsApp'}

    return {'success': True, 'message': f'Prescription sent to {phone}'}
