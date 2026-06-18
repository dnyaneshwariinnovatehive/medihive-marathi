import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';
import '../models/appointment_model.dart';

class ExcelMergeService {
  static final ExcelMergeService _instance = ExcelMergeService._internal();
  factory ExcelMergeService() => _instance;
  ExcelMergeService._internal();

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final parts = dateStr.trim().split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return null;
  }

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

  Future<int> mergeFromExcel(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);

    final patientsBox = Hive.box<PatientModel>('patients');
    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final apptBox = Hive.box<AppointmentModel>('appointments');

    int mergedCount = 0;

    final Sheet? patientsSheet = excel.sheets['Patients'];
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
        final updatedAt = _parseDate(row[9]?.value?.toString()) ?? createdAt;

        final existing = patientsBox.get(id);
        if (existing != null && existing.updatedAt.isAfter(updatedAt)) {
          continue;
        }

        await patientsBox.put(id, PatientModel(
          id: id,
          name: name,
          dob: dob,
          age: age,
          mobile: mobile,
          address: address,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isSynced: false,
        ));
        mergedCount++;
      }
    }

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
        final updatedAt = _parseDate(row[11]?.value?.toString()) ?? visitDate;

        final existing = opdBox.get(id);
        if (existing != null && existing.updatedAt.isAfter(updatedAt)) {
          continue;
        }

        await opdBox.put(id, OPDRecordModel(
          id: id,
          patientId: patientId,
          type: visitType,
          symptoms: symptoms,
          diagnosis: diagnosis,
          medicines: medicines,
          visitDate: visitDate,
          isDraft: isDraft,
          isSynced: false,
          createdAt: visitDate,
          updatedAt: updatedAt,
        ));
        mergedCount++;
      }
    }

    final Sheet? apptSheet = excel.sheets['Appointments'];
    if (apptSheet != null && apptSheet.maxRows > 1) {
      final patients = patientsBox.values.toList();

      for (int r = 1; r < apptSheet.maxRows; r++) {
        final row = apptSheet.rows[r];
        if (row.isEmpty || row[0]?.value == null) continue;

        final id = row[0]!.value.toString();
        final patientName = row[1]?.value?.toString() ?? '';
        final dateStr = row[2]?.value?.toString();
        final timeStr = row[3]?.value?.toString();
        final notes = row[4]?.value?.toString() ?? '';
        final updatedAt = _parseDate(row[6]?.value?.toString()) ?? DateTime.now();

        String patientId = '';
        final match = patients.cast<PatientModel?>().firstWhere(
          (p) => p?.name == patientName,
          orElse: () => null,
        );
        if (match != null) patientId = match.id;

        final existing = apptBox.get(id);
        if (existing != null && existing.updatedAt.isAfter(updatedAt)) {
          continue;
        }

        final dateTime = _parseDateTime(dateStr, timeStr) ?? DateTime.now();

        await apptBox.put(id, AppointmentModel(
          id: id,
          patientId: patientId,
          dateTime: dateTime,
          notes: notes,
          isSynced: false,
          createdAt: dateTime,
          updatedAt: updatedAt,
        ));
        mergedCount++;
      }
    }

    return mergedCount;
  }
}
