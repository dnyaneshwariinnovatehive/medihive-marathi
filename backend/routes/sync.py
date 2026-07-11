"""Mobile-only sync endpoints for MediHive Marathi.

Consolidated sync module with clinic_id isolation,
incremental upload/download, and disaster recovery.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.patient import Patient
from models.opd_record import OPDRecord
from models.appointment import Appointment
from models.deleted_entity import DeletedEntity
from models.clinic import Clinic
from models.device_registry import DeviceRegistry
from database import get_db
from datetime import datetime
from pathlib import Path
from config import IMAGE_STORAGE_PATH, IS_CLOUD
from services.log_service import get_logger
from routes.opd import save_images_locally, build_sheet_row_data, _ImageRecord

logger = get_logger(__name__)

sync_bp = Blueprint('sync', __name__)


def _get_user_clinic_id(user_id):
    db = get_db()
    user = db.execute(
        "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
    ).fetchone()
    db.close()
    return user['clinic_id'] if user and user['clinic_id'] else None


def _sync_opd_to_sheets(opd, image_links=None):
    opd_id = opd.get('id', 'UNKNOWN')
    patient_id = opd.get('patient_id', 'UNKNOWN')
    logger.info(
        "SHEET SYNC START: OPD=%s patient_id=%s has_images=%s",
        opd_id, patient_id, bool(image_links),
    )

    patient = Patient.get(patient_id)
    if not patient:
        logger.warning(
            "Patient %s not found in PostgreSQL, creating placeholder for sheet sync for OPD %s",
            patient_id, opd_id,
        )
        now = datetime.utcnow().isoformat()
        db = get_db()
        db.execute("""
            INSERT INTO patients
                (id, name, mobile, gender, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (
            patient_id, 'Unknown (Auto-created)',
            '', 'Not Specified', now, now,
        ))
        db.commit()
        db.close()
        patient = Patient.get(patient_id)
        if not patient:
            logger.error(
                "Could not create placeholder patient %s for OPD %s",
                patient_id, opd_id,
            )
            patient = {
                'id': patient_id,
                'name': 'Unknown',
                'mobile': '',
                'gender': 'Not Specified',
                'dob': '',
                'age': 0,
                'blood_group': '',
                'address': '',
            }

    row_data = build_sheet_row_data(opd, patient, image_links or [])
    try:
        from sheets_utils import upsert_opd_row_in_sheet
        upsert_opd_row_in_sheet(opd_id, row_data)
        logger.info("SHEET SYNC END: OPD=%s", opd_id)
    except RuntimeError as e:
        logger.warning("Sheet sync skipped for OPD %s: %s", opd_id, e)
    except Exception as e:
        logger.warning("Sheet sync error for OPD %s: %s", opd_id, e)


# ── Device Registration ─────────────────────────────

@sync_bp.route('/register-device', methods=['POST'])
def register_device():
    data = request.get_json() or {}
    device_id = data.get('device_id', '').strip()
    if not device_id:
        return jsonify({'error': 'device_id is required'}), 400

    device = DeviceRegistry.register({
        'device_id': device_id,
        'device_name': data.get('device_name', ''),
        'clinic_id': data.get('clinic_id', ''),
        'fcm_token': data.get('fcm_token', ''),
        'app_version': data.get('app_version', ''),
    })
    logger.info("Device registered: %s for clinic %s", device_id, data.get('clinic_id', ''))
    return jsonify({'device': device, 'message': 'Device registered'}), 200


@sync_bp.route('/heartbeat', methods=['POST'])
def heartbeat():
    data = request.get_json() or {}
    device_id = data.get('device_id', '')
    if device_id:
        DeviceRegistry.update_heartbeat(device_id)
    return jsonify({'message': 'ok'}), 200


# ── Incremental Sync Upload ──────────────────────────

@sync_bp.route('/upload', methods=['POST'])
@jwt_required()
def sync_upload():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    data = request.get_json() or {}
    device_id = data.get('device_id', '')
    now = datetime.utcnow().isoformat()

    logger.info(
        "UPLOAD clinic=%s device=%s patients=%d opd_records=%d appointments=%d deleted=%d",
        clinic_id, device_id,
        len(data.get('patients', [])),
        len(data.get('opd_records', [])),
        len(data.get('appointments', [])),
        len(data.get('deleted_entities', [])),
    )

    results = {'patients': [], 'opd_records': [], 'appointments': []}
    temp_id_map = {}

    # ── Patients (last-write-wins) ──
    for p in data.get('patients', []):
        p['clinic_id'] = clinic_id
        p['device_id'] = device_id
        p['sync_status'] = 'synced'
        p['last_synced_at'] = now
        old_id = p.get('id', '')
        is_temp = old_id.startswith('TEMP_')
        if is_temp:
            p['id'] = Patient.assign_next_id(clinic_id=clinic_id)
            temp_id_map[old_id] = p['id']

        existing = Patient.get(p['id'], clinic_id=clinic_id)
        if existing:
            remote_updated = p.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if remote_updated >= local_updated:
                Patient.update(p['id'], p, clinic_id=clinic_id)
                results['patients'].append(Patient.get(p['id'], clinic_id=clinic_id))
            else:
                results['patients'].append(existing)
        else:
            Patient.create(p)
            results['patients'].append(Patient.get(p['id'], clinic_id=clinic_id))

    # ── OPD Records (last-write-wins) ──
    for r in data.get('opd_records', []):
        r['clinic_id'] = clinic_id
        r['device_id'] = device_id
        r['sync_status'] = 'synced'
        r['last_synced_at'] = now
        pat_id = r.get('patient_id', '')
        if pat_id in temp_id_map:
            r['patient_id'] = temp_id_map[pat_id]

        existing = OPDRecord.get(r['id'], clinic_id=clinic_id)
        if existing:
            remote_updated = r.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if remote_updated >= local_updated:
                OPDRecord.update(r['id'], r, clinic_id=clinic_id)
                result = OPDRecord.get(r['id'], clinic_id=clinic_id)
            else:
                result = existing
        else:
            OPDRecord.create(r)
            result = OPDRecord.get(r['id'], clinic_id=clinic_id)

        results['opd_records'].append(result)
        try:
            _sync_opd_to_sheets(result)
        except Exception as e:
            logger.warning("Sheet sync failed for OPD %s: %s", r.get('id'), e)

    # ── Appointments (last-write-wins) ──
    for a in data.get('appointments', []):
        a['clinic_id'] = clinic_id
        a['device_id'] = device_id
        a['sync_status'] = 'synced'
        a['last_synced_at'] = now

        existing = Appointment.get(a['id'], clinic_id=clinic_id)
        if existing:
            remote_updated = a.get('updated_at', '')
            local_updated = existing.get('updated_at', '')
            if remote_updated >= local_updated:
                Appointment.update(a['id'], a, clinic_id=clinic_id)
                results['appointments'].append(Appointment.get(a['id'], clinic_id=clinic_id))
            else:
                results['appointments'].append(existing)
        else:
            Appointment.create(a)
            results['appointments'].append(Appointment.get(a['id'], clinic_id=clinic_id))

    # ── Deleted Entities ──
    for entry in data.get('deleted_entities', []):
        etype = entry.get('entity_type')
        eid = entry.get('entity_id')
        try:
            if etype == 'patient':
                Patient.delete(eid, clinic_id=clinic_id)
            elif etype == 'opd_visit':
                OPDRecord.delete(eid, clinic_id=clinic_id)
            elif etype == 'appointment':
                Appointment.delete(eid, clinic_id=clinic_id)
        except Exception as exc:
            logger.warning("Delete sync failed for %s %s: %s", etype, eid, exc)

    response = {
        'results': results,
        'server_time': now,
        'clinic_id': clinic_id,
    }
    if temp_id_map:
        response['temp_ids_mapped'] = temp_id_map

    return jsonify(response), 200


# ── Incremental Sync Download ────────────────────────

@sync_bp.route('/download', methods=['POST'])
@jwt_required()
def sync_download():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    data = request.get_json() or {}
    last_sync = data.get('last_sync', '2000-01-01T00:00:00')

    patients = Patient.updated_since(last_sync, clinic_id=clinic_id)
    opd_records = OPDRecord.updated_since(last_sync, clinic_id=clinic_id)
    appointments = Appointment.updated_since(last_sync, clinic_id=clinic_id)
    deleted_entities = DeletedEntity.since(last_sync, clinic_id=clinic_id)

    logger.info(
        "DOWNLOAD clinic=%s since=%s patients=%d opd=%d appts=%d deleted=%d",
        clinic_id, last_sync,
        len(patients), len(opd_records),
        len(appointments), len(deleted_entities),
    )

    return jsonify({
        'patients': patients,
        'opd_records': opd_records,
        'appointments': appointments,
        'deleted_entities': deleted_entities,
        'server_time': datetime.utcnow().isoformat(),
    }), 200


# ── Disaster Recovery: Full Restore ──────────────────

@sync_bp.route('/full-restore', methods=['GET'])
@jwt_required()
def full_restore():
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)
    if not clinic_id:
        return jsonify({'error': 'No clinic assigned to this user'}), 403

    patients = Patient.full_restore(clinic_id)
    opd_records = OPDRecord.full_restore(clinic_id)
    appointments = Appointment.full_restore(clinic_id)

    db = get_db()
    deleted_entities_rows = db.execute(
        "SELECT entity_type, entity_id, deleted_at FROM deleted_entities "
        "WHERE clinic_id = %s ORDER BY deleted_at",
        (clinic_id,)
    ).fetchall()
    db.close()
    deleted_entities = [dict(r) for r in deleted_entities_rows]

    clinic = Clinic.get(clinic_id)

    return jsonify({
        'clinic': clinic,
        'patients': patients,
        'opd_records': opd_records,
        'appointments': appointments,
        'deleted_entities': deleted_entities,
        'server_time': datetime.utcnow().isoformat(),
    }), 200


# ── Mobile Sync: Upload Images ──────────────────────

@sync_bp.route('/upload-images/<opd_id>', methods=['POST'])
@jwt_required()
def sync_upload_images(opd_id):
    user_id = get_jwt_identity()
    clinic_id = _get_user_clinic_id(user_id)

    logger.info("=== IMAGE UPLOAD START === OPD=%s clinic=%s", opd_id, clinic_id)

    opd = OPDRecord.get(opd_id, clinic_id=clinic_id) if clinic_id else OPDRecord.get(opd_id)
    if opd is None:
        logger.warning("OPD record not found: %s", opd_id)
        return jsonify({'error': 'OPD record not found'}), 404

    if 'images' not in request.files:
        logger.warning("No 'images' field in request for OPD %s", opd_id)
        return jsonify({'error': 'No image files provided'}), 400

    files = request.files.getlist('images')
    files = [f for f in files if f.filename]

    if not files:
        logger.warning("No valid image files for OPD %s", opd_id)
        return jsonify({'error': 'No valid image files provided'}), 400

    try:
        visit_date = datetime.fromisoformat(opd['visit_date'])
    except (ValueError, TypeError):
        visit_date = datetime.utcnow()

    from drive_utils import upload_image_fileobj_to_drive, upload_images_to_drive, check_existing_drive_files

    if IS_CLOUD:
        logger.info("CLOUD MODE: uploading %d image(s) directly to Drive for OPD %s",
                    len(files), opd_id)
        drive_urls = []
        for i, f in enumerate(files, 1):
            url = upload_image_fileobj_to_drive(opd_id, f, i)
            if url:
                drive_urls.append(url)
    else:
        logger.info("LOCAL MODE: saving %d image(s) to disk for OPD %s", len(files), opd_id)
        saved_paths = save_images_locally(opd_id, files)

        drive_urls = check_existing_drive_files(opd_id, visit_date, len(saved_paths))
        if not drive_urls:
            image_records = [_ImageRecord(p) for p in saved_paths]
            drive_urls = upload_images_to_drive(opd_id, image_records, visit_date)

    if not drive_urls:
        logger.error("IMAGE UPLOAD FAILED: No Drive URLs generated for OPD %s", opd_id)
        return jsonify({
            'error': 'Image upload to Drive failed',
            'opd_id': opd_id,
            'image_count': 0,
            'drive_urls': [],
            'images_uploaded': False,
        }), 500

    urls_text = "\n".join(drive_urls)
    OPDRecord.set_image_links(opd_id, urls_text, clinic_id=clinic_id)
    logger.info("Image links persisted in DB for OPD %s: %s", opd_id, urls_text)

    sheet_update_ok = True
    try:
        _sync_opd_to_sheets(opd, drive_urls)
        logger.info("Google Sheet update SUCCESS for OPD %s", opd_id)
    except Exception as e:
        logger.error("Sheet update FAILED for OPD %s: %s", opd_id, e)
        sheet_update_ok = False

    response = {
        'opd_id': opd_id,
        'image_count': len(drive_urls),
        'drive_urls': drive_urls,
        'images_uploaded': True,
        'sheet_updated': sheet_update_ok,
    }

    if sheet_update_ok:
        response['message'] = 'Images synced successfully'
        return jsonify(response), 200
    else:
        response['message'] = 'Images uploaded to Drive, but Google Sheet was not updated.'
        return jsonify(response), 207


# ── Clinic Info ─────────────────────────────────────

@sync_bp.route('/clinic-info', methods=['GET'])
@jwt_required()
def clinic_info():
    user_id = get_jwt_identity()
    db = get_db()
    user = db.execute(
        "SELECT clinic_id FROM users WHERE id = %s", (user_id,)
    ).fetchone()
    db.close()

    if user and user['clinic_id']:
        clinic = Clinic.get(user['clinic_id'])
        if clinic:
            return jsonify({'clinic': clinic}), 200
        return jsonify({'error': 'Clinic not found'}), 404

    return jsonify({'error': 'No clinic assigned to this user'}), 404
