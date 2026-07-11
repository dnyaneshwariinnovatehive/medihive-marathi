from database import get_db
from datetime import datetime


class OPDRecord:
    TABLE = 'opd_records'

    @staticmethod
    def dict_from_row(row):
        if row is None:
            return None
        return dict(row)

    @staticmethod
    def all(patient_id=None, clinic_id=None):
        db = get_db()
        if patient_id and clinic_id:
            rows = db.execute(
                "SELECT * FROM opd_records WHERE patient_id = %s AND clinic_id = %s ORDER BY visit_date DESC",
                (patient_id, clinic_id)
            ).fetchall()
        elif patient_id:
            rows = db.execute(
                "SELECT * FROM opd_records WHERE patient_id = %s ORDER BY visit_date DESC",
                (patient_id,)
            ).fetchall()
        elif clinic_id:
            rows = db.execute(
                "SELECT * FROM opd_records WHERE clinic_id = %s ORDER BY visit_date DESC",
                (clinic_id,)
            ).fetchall()
        else:
            rows = db.execute("SELECT * FROM opd_records ORDER BY visit_date DESC").fetchall()
        db.close()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def get(record_id, clinic_id=None):
        db = get_db()
        if clinic_id:
            row = db.execute(
                "SELECT * FROM opd_records WHERE id = %s AND clinic_id = %s",
                (record_id, clinic_id)
            ).fetchone()
        else:
            row = db.execute("SELECT * FROM opd_records WHERE id = %s", (record_id,)).fetchone()
        db.close()
        return OPDRecord.dict_from_row(row)

    @staticmethod
    def create(data):
        now = datetime.utcnow().isoformat()
        db = get_db()
        db.execute("""
            INSERT INTO opd_records (id, patient_id, type, symptoms, diagnosis, medicines,
                visit_date, clinical_notes, consultation_fee, medicine_fee, panchakarma_fee,
                total_fee, discount, discount_type, payment_mode, charge_type,
                previous_visit_date, follow_up_reason,
                next_visit, blood_group, image_links, panchakarma_notes, created_at, updated_at,
                user_id, clinic_id, device_id, sync_status, last_synced_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data['id'], data['patient_id'], data.get('type', 'consultation'),
            data.get('symptoms', ''), data.get('diagnosis', ''),
            data.get('medicines', ''), data.get('visit_date', now),
            data.get('clinical_notes', ''), data.get('consultation_fee', '0'),
            data.get('medicine_fee', '0'), data.get('panchakarma_fee', '0'),
            data.get('total_fee', '0'), data.get('discount', '0'),
            data.get('discount_type', 'None'),
            data.get('payment_mode', ''), data.get('charge_type', ''),
            data.get('previous_visit_date', ''), data.get('follow_up_reason', ''),
            data.get('next_visit', ''), data.get('blood_group', ''),
            data.get('image_links', ''),
            data.get('panchakarma_notes', ''),
            now, now,
            data.get('user_id', ''),
            data.get('clinic_id', ''),
            data.get('device_id', ''),
            data.get('sync_status', 'pending'),
            data.get('last_synced_at', ''),
        ))
        db.commit()
        db.close()
        return OPDRecord.get(data['id'])

    @staticmethod
    def update(record_id, data, clinic_id=None):
        now = datetime.utcnow().isoformat()
        allowed = ('type', 'symptoms', 'diagnosis', 'medicines', 'visit_date',
                   'clinical_notes', 'consultation_fee', 'medicine_fee',
                   'panchakarma_fee', 'total_fee', 'discount', 'discount_type',
                   'payment_mode', 'charge_type', 'previous_visit_date',
                   'follow_up_reason', 'next_visit', 'blood_group',
                   'image_links', 'user_id', 'clinic_id',
                   'panchakarma_notes', 'device_id', 'sync_status', 'last_synced_at')
        fields = []
        values = []
        for k in allowed:
            if k in data:
                fields.append(f"{k} = %s")
                values.append(data[k])
        if not fields:
            return OPDRecord.get(record_id, clinic_id=clinic_id)
        fields.append("updated_at = %s")
        values.append(now)
        values.append(record_id)
        if clinic_id:
            values.append(clinic_id)
            db = get_db()
            db.execute(
                f"UPDATE opd_records SET {', '.join(fields)} WHERE id = %s AND clinic_id = %s",
                values
            )
        else:
            db = get_db()
            db.execute(f"UPDATE opd_records SET {', '.join(fields)} WHERE id = %s", values)
        db.commit()
        db.close()
        return OPDRecord.get(record_id, clinic_id=clinic_id)

    @staticmethod
    def delete(record_id, clinic_id=None):
        from models.deleted_entity import DeletedEntity
        DeletedEntity.record('opd_visit', record_id, clinic_id=clinic_id or '')
        db = get_db()
        if clinic_id:
            db.execute(
                "DELETE FROM opd_records WHERE id = %s AND clinic_id = %s",
                (record_id, clinic_id)
            )
        else:
            db.execute("DELETE FROM opd_records WHERE id = %s", (record_id,))
        db.commit()
        db.close()

    @staticmethod
    def upsert(data, clinic_id=None):
        existing = OPDRecord.get(data['id'], clinic_id=clinic_id)
        if existing:
            return OPDRecord.update(data['id'], data, clinic_id=clinic_id)
        return OPDRecord.create(data)

    @staticmethod
    def set_image_links(record_id, links_text, clinic_id=None):
        now = datetime.utcnow().isoformat()
        db = get_db()
        if clinic_id:
            db.execute(
                "UPDATE opd_records SET image_links = %s, updated_at = %s WHERE id = %s AND clinic_id = %s",
                (links_text, now, record_id, clinic_id)
            )
        else:
            db.execute(
                "UPDATE opd_records SET image_links = %s, updated_at = %s WHERE id = %s",
                (links_text, now, record_id)
            )
        db.commit()
        db.close()

    @staticmethod
    def by_clinic(clinic_id):
        db = get_db()
        rows = db.execute(
            "SELECT * FROM opd_records WHERE clinic_id = %s ORDER BY updated_at DESC",
            (clinic_id,)
        ).fetchall()
        db.close()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def updated_since(timestamp, clinic_id=None):
        db = get_db()
        if clinic_id:
            rows = db.execute(
                "SELECT * FROM opd_records WHERE updated_at > %s AND clinic_id = %s ORDER BY updated_at",
                (timestamp, clinic_id)
            ).fetchall()
        else:
            rows = db.execute(
                "SELECT * FROM opd_records WHERE updated_at > %s ORDER BY updated_at",
                (timestamp,)
            ).fetchall()
        db.close()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def full_restore(clinic_id):
        db = get_db()
        rows = db.execute(
            "SELECT * FROM opd_records WHERE clinic_id = %s ORDER BY updated_at",
            (clinic_id,)
        ).fetchall()
        db.close()
        return [OPDRecord.dict_from_row(r) for r in rows]

    @staticmethod
    def mark_synced(record_id, clinic_id, synced_at):
        db = get_db()
        db.execute(
            "UPDATE opd_records SET sync_status = 'synced', last_synced_at = %s, updated_at = %s "
            "WHERE id = %s AND clinic_id = %s",
            (synced_at, synced_at, record_id, clinic_id)
        )
        db.commit()
        db.close()
