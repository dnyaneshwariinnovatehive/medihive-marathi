import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SECRET_KEY = os.environ.get('SECRET_KEY', 'medihive-secret-key-change-in-production')
JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'medihive-jwt-secret-change-in-production')
JWT_ACCESS_TOKEN_EXPIRES = 86400  # 24 hours

DATABASE_PATH = os.path.join(BASE_DIR, 'medihive.db')

# WhatsApp Cloud API
WHATSAPP_TOKEN = os.environ.get('WHATSAPP_TOKEN', '')
WHATSAPP_PHONE_NUMBER_ID = os.environ.get('WHATSAPP_PHONE_NUMBER_ID', '')
WHATSAPP_API_VERSION = 'v22.0'
WHATSAPP_API_BASE = f'https://graph.facebook.com/{WHATSAPP_API_VERSION}'
