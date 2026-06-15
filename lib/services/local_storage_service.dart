import 'package:hive/hive.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';
import '../models/appointment_model.dart';

class LocalStorageService {
  // ─── Patient Methods ──────────────────────────────────────────
  
  /// Saves a patient to local storage.
  /// Sets isSynced to false by default.
  Future<void> savePatient(PatientModel patient) async {
    final box = Hive.box<PatientModel>('patients');
    final exists = box.containsKey(patient.id);
    final now = DateTime.now();
    
    final patientToSave = patient.copyWith(
      isSynced: false,
      createdAt: exists ? (box.get(patient.id)?.createdAt ?? patient.createdAt) : now,
      updatedAt: now,
    );
    await box.put(patientToSave.id, patientToSave);
  }

  /// Gets all patients.
  List<PatientModel> getPatients() {
    final box = Hive.box<PatientModel>('patients');
    return box.values.toList();
  }

  /// Updates a patient in local storage.
  /// Sets isSynced to false by default.
  Future<void> updatePatient(PatientModel patient) async {
    await savePatient(patient);
  }

  /// Deletes a patient from local storage by ID.
  Future<void> deletePatient(String id) async {
    final box = Hive.box<PatientModel>('patients');
    await box.delete(id);
  }

  /// Gets all patients that are not synced yet.
  List<PatientModel> getPendingSyncPatients() {
    final box = Hive.box<PatientModel>('patients');
    return box.values.where((p) => !p.isSynced).toList();
  }

  // ─── OPD Record Methods ───────────────────────────────────────

  /// Saves an OPD record to local storage.
  /// Sets isSynced to false by default.
  Future<void> saveOPDRecord(OPDRecordModel record) async {
    final box = Hive.box<OPDRecordModel>('opd_records');
    final exists = box.containsKey(record.id);
    final now = DateTime.now();

    final recordToSave = record.copyWith(
      isSynced: false,
      createdAt: exists ? (box.get(record.id)?.createdAt ?? record.createdAt) : now,
      updatedAt: now,
    );
    await box.put(recordToSave.id, recordToSave);
  }

  /// Gets all OPD records.
  List<OPDRecordModel> getOPDRecords() {
    final box = Hive.box<OPDRecordModel>('opd_records');
    return box.values.toList();
  }

  /// Gets all OPD records pending synchronization (isSynced = false).
  List<OPDRecordModel> getPendingSyncRecords() {
    final box = Hive.box<OPDRecordModel>('opd_records');
    return box.values.where((r) => !r.isSynced).toList();
  }

  /// Deletes an OPD record from local storage by ID.
  Future<void> deleteOPDRecord(String id) async {
    final box = Hive.box<OPDRecordModel>('opd_records');
    await box.delete(id);
  }

  // ─── Appointment Methods ──────────────────────────────────────

  /// Saves an appointment to local storage.
  /// Sets isSynced to false by default.
  Future<void> saveAppointment(AppointmentModel appointment) async {
    final box = Hive.box<AppointmentModel>('appointments');
    final exists = box.containsKey(appointment.id);
    final now = DateTime.now();

    final appointmentToSave = appointment.copyWith(
      isSynced: false,
      createdAt: exists ? (box.get(appointment.id)?.createdAt ?? appointment.createdAt) : now,
      updatedAt: now,
    );
    await box.put(appointmentToSave.id, appointmentToSave);
  }

  /// Gets all appointments.
  List<AppointmentModel> getAppointments() {
    final box = Hive.box<AppointmentModel>('appointments');
    return box.values.toList();
  }

  /// Updates an appointment in local storage.
  /// Sets isSynced to false by default.
  Future<void> updateAppointment(AppointmentModel appointment) async {
    await saveAppointment(appointment);
  }

  /// Deletes an appointment from local storage by ID.
  Future<void> deleteAppointment(String id) async {
    final box = Hive.box<AppointmentModel>('appointments');
    await box.delete(id);
  }

  /// Gets all appointments that are not synced yet.
  List<AppointmentModel> getPendingSyncAppointments() {
    final box = Hive.box<AppointmentModel>('appointments');
    return box.values.where((a) => !a.isSynced).toList();
  }

  // ─── Draft Methods ────────────────────────────────────────────

  /// Saves a draft as key-value pair.
  Future<void> saveDraft(String key, Map<String, dynamic> draftData) async {
    final box = Hive.box('drafts');
    await box.put(key, draftData);
  }

  /// Retrieves a saved draft by key.
  Map<String, dynamic>? getDraft(String key) {
    final box = Hive.box('drafts');
    final data = box.get(key);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  /// Clears a saved draft by key.
  Future<void> clearDraft(String key) async {
    final box = Hive.box('drafts');
    await box.delete(key);
  }
}
