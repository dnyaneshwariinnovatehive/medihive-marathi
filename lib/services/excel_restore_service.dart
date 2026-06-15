import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';
import '../models/appointment_model.dart';

class ExcelRestoreService {
  static final ExcelRestoreService _instance = ExcelRestoreService._internal();
  factory ExcelRestoreService() => _instance;
  ExcelRestoreService._internal();

  /// Parses date from format DD/MM/YYYY
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final parts = dateStr.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Parses appointment DateTime from Date (DD/MM/YYYY) and Time (hh:mm AM/PM)
  DateTime? _parseDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final date = _parseDate(dateStr);
    if (date == null) return null;
    
    if (timeStr == null || timeStr.trim().isEmpty) return date;
    try {
      final amPmParts = timeStr.trim().split(RegExp(r'\s+'));
      final timeParts = amPmParts[0].split(':');
      if (timeParts.length >= 2) {
        var hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (amPmParts.length == 2) {
          final amPm = amPmParts[1].toUpperCase();
          if (amPm == 'PM' && hour < 12) hour += 12;
          if (amPm == 'AM' && hour == 12) hour = 0;
        }
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (_) {}
    return date;
  }

  /// Restores patients, records, and appointments models from excel bytes
  Future<int> restoreFromExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    
    final patientsBox = Hive.box<PatientModel>('patients');
    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final apptBox = Hive.box<AppointmentModel>('appointments');

    // Clear existing boxes to overwrite
    await patientsBox.clear();
    await opdBox.clear();
    await apptBox.clear();

    int totalRestored = 0;

    // ─── Sheet 1: Patients ─────────────────────────────────────────
    final Sheet? patientsSheet = excel.sheets['Patients'];
    final Map<String, String> patientNameToId = {};

    if (patientsSheet != null && patientsSheet.maxRows > 1) {
      for (int r = 1; r < patientsSheet.maxRows; r++) {
        final row = patientsSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;

        final id = row[0]!.value.toString();
        final name = row[1]?.value?.toString() ?? '';
        final dob = row[2]?.value?.toString() ?? '';
        final age = int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;
        final mobile = row[4]?.value?.toString() ?? '';
        final address = row[5]?.value?.toString() ?? '';
        final createdAt = _parseDate(row[8]?.value?.toString()) ?? DateTime.now();

        patientNameToId[name] = id;

        final patient = PatientModel(
          id: id,
          name: name,
          dob: dob,
          age: age,
          mobile: mobile,
          address: address,
          createdAt: createdAt,
          updatedAt: createdAt,
          isSynced: true,
        );
        await patientsBox.put(id, patient);
        totalRestored++;
      }
    }

    // ─── Sheet 2: OPD Records ──────────────────────────────────────
    final Sheet? opdSheet = excel.sheets['OPD Records'];
    if (opdSheet != null && opdSheet.maxRows > 1) {
      for (int r = 1; r < opdSheet.maxRows; r++) {
        final row = opdSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;

        final id = row[0]!.value.toString();
        final patientId = row[1]?.value?.toString() ?? '';
        final visitType = row[3]?.value?.toString() ?? 'OPD';
        final visitDate = _parseDate(row[4]?.value?.toString()) ?? DateTime.now();
        final symptoms = row[5]?.value?.toString() ?? '';
        final diagnosis = row[6]?.value?.toString() ?? '';
        final medicines = row[7]?.value?.toString() ?? '';
        final isDraft = (row[10]?.value?.toString() ?? '') == 'Draft';

        final record = OPDRecordModel(
          id: id,
          patientId: patientId,
          type: visitType,
          symptoms: symptoms,
          diagnosis: diagnosis,
          medicines: medicines,
          visitDate: visitDate,
          isDraft: isDraft,
          isSynced: true,
          createdAt: visitDate,
          updatedAt: visitDate,
        );
        await opdBox.put(id, record);
        totalRestored++;
      }
    }

    // ─── Sheet 3: Appointments ─────────────────────────────────────
    final Sheet? apptSheet = excel.sheets['Appointments'];
    if (apptSheet != null && apptSheet.maxRows > 1) {
      for (int r = 1; r < apptSheet.maxRows; r++) {
        final row = apptSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;

        final id = row[0]!.value.toString();
        final patientName = row[1]?.value?.toString() ?? '';
        final dateStr = row[2]?.value?.toString();
        final timeStr = row[3]?.value?.toString();
        final notes = row[4]?.value?.toString() ?? '';

        final patientId = patientNameToId[patientName] ?? '';
        final dateTime = _parseDateTime(dateStr, timeStr) ?? DateTime.now();

        final appointment = AppointmentModel(
          id: id,
          patientId: patientId,
          dateTime: dateTime,
          notes: notes,
          isSynced: true,
          createdAt: dateTime,
          updatedAt: dateTime,
        );
        await apptBox.put(id, appointment);
        totalRestored++;
      }
    }

    return totalRestored;
  }
}
