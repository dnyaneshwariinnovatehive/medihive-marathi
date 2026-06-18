import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:hive/hive.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';
import '../models/appointment_model.dart';

class ExcelExportService {
  // Singleton instance
  static final ExcelExportService _instance = ExcelExportService._internal();
  factory ExcelExportService() => _instance;
  ExcelExportService._internal();

  /// Formats date as DD/MM/YYYY
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Formats time as hh:mm AM/PM
  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:$minute $amPm';
  }

  /// Helper to convert raw dart types into type-safe excel CellValue
  CellValue? _toCellValue(dynamic val) {
    if (val == null) return null;
    if (val is int) return IntCellValue(val);
    if (val is double) return DoubleCellValue(val);
    if (val is bool) return BoolCellValue(val);
    return TextCellValue(val.toString());
  }

  /// Generates the standard file name for Excel export:
  /// "MediHive_[clinicName]_[timestamp].xlsx"
  String generateFileName(String clinicName, {int recordCount = 0}) {
    final cleanClinicName = clinicName.replaceAll(RegExp(r'\s+'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'MediHive_${cleanClinicName}_${recordCount}_records_$timestamp.xlsx';
  }

  /// Exports all local Hive data to Excel bytes
  Future<Uint8List> generateExcelFile({String clinicName = 'Shree Clinic'}) async {
    final patients = Hive.box<PatientModel>('patients').values.toList();
    final opdRecords = Hive.box<OPDRecordModel>('opd_records').values.toList();
    final appointments = Hive.box<AppointmentModel>('appointments').values.toList();

    return _buildExcel(patients, opdRecords, appointments, clinicName);
  }

  /// Exports only today's records (created or modified today)
  Future<Uint8List> generateDailyReport({String clinicName = 'Shree Clinic'}) async {
    final today = DateTime.now();

    bool isToday(DateTime date) {
      return date.year == today.year && date.month == today.month && date.day == today.day;
    }

    final patients = Hive.box<PatientModel>('patients')
        .values
        .where((p) => isToday(p.createdAt))
        .toList();

    final opdRecords = Hive.box<OPDRecordModel>('opd_records')
        .values
        .where((r) => isToday(r.visitDate) || isToday(r.createdAt))
        .toList();

    final appointments = Hive.box<AppointmentModel>('appointments')
        .values
        .where((a) => isToday(a.dateTime) || isToday(a.createdAt))
        .toList();

    return _buildExcel(patients, opdRecords, appointments, clinicName);
  }

  /// Core builder that maps, structures, and formats data into Excel
  Future<Uint8List> _buildExcel(
    List<PatientModel> patients,
    List<OPDRecordModel> opdRecords,
    List<AppointmentModel> appointments,
    String clinicName,
  ) async {
    final excel = Excel.createExcel();

    // ─── Formatting Configurations ────────────────────────────────
    final CellStyle headerStyle = CellStyle(
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle normalStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Left,
    );

    final CellStyle altStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#F5F5F5'),
      horizontalAlign: HorizontalAlign.Left,
    );

    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final dashboardSheetName = 'MediHive_Backup_$day-$month-$year';

    // Rename default Sheet1 to the custom dashboard sheet name
    excel.rename('Sheet1', dashboardSheetName);
    final dashboardSheet = excel[dashboardSheetName];

    // ─── Dashboard Sheet Generation ────────────────────────────────
    _writeRow(dashboardSheet, 0, ['MediHive Clinic Backup Dashboard'], headerStyle);
    
    // Details
    _writeRow(dashboardSheet, 2, ['Clinic Name', clinicName], normalStyle);
    _writeRow(dashboardSheet, 3, ['Backup Date', '$day/$month/$year'], altStyle);
    _writeRow(dashboardSheet, 4, ['Total Patients In File', patients.length.toString()], normalStyle);
    _writeRow(dashboardSheet, 5, ['Total OPD Records In File', opdRecords.length.toString()], altStyle);
    _writeRow(dashboardSheet, 6, ['Total Appointments In File', appointments.length.toString()], normalStyle);

    _autoFitColumns(dashboardSheet);

    // ─── Sheet 1: Patients ─────────────────────────────────────────
    final patientsSheet = excel['Patients'];
    final patientsHeaders = [
      'Patient ID',
      'Full Name',
      'DOB',
      'Age',
      'Mobile',
      'Address',
      'Total Visits',
      'Last Visit',
      'Created At',
      'Updated At',
    ];
    _writeRow(patientsSheet, 0, patientsHeaders, headerStyle);

    for (int i = 0; i < patients.length; i++) {
      final p = patients[i];
      final rowStyle = i % 2 == 1 ? altStyle : normalStyle;

      // Compute total visits and last visit date from OPD records
      final totalVisits = opdRecords.where((r) => r.patientId == p.id).length;
      final patientOpd = opdRecords.where((r) => r.patientId == p.id).toList();
      String lastVisitStr = 'Never';
      if (patientOpd.isNotEmpty) {
        patientOpd.sort((a, b) => b.visitDate.compareTo(a.visitDate));
        lastVisitStr = _formatDate(patientOpd.first.visitDate);
      }

      final data = [
        p.id,
        p.name,
        p.dob,
        p.age.toString(),
        p.mobile,
        p.address,
        totalVisits.toString(),
        lastVisitStr,
        _formatDate(p.createdAt),
        _formatDate(p.updatedAt),
      ];
      _writeRow(patientsSheet, i + 1, data, rowStyle);
    }
    _autoFitColumns(patientsSheet);

    // ─── Sheet 2: OPD Records ──────────────────────────────────────
    final opdSheet = excel['OPD Records'];
    final opdHeaders = [
      'Record ID',
      'Patient ID',
      'Patient Name',
      'Visit Type',
      'Visit Date',
      'Symptoms',
      'Diagnosis',
      'Medicines',
      'Dosage',
      'Notes',
      'Draft Status',
      'Updated At',
    ];
    _writeRow(opdSheet, 0, opdHeaders, headerStyle);

    for (int i = 0; i < opdRecords.length; i++) {
      final r = opdRecords[i];
      final rowStyle = i % 2 == 1 ? altStyle : normalStyle;

      // Look up patient name
      final patient = patients.cast<PatientModel?>().firstWhere(
            (p) => p?.id == r.patientId,
            orElse: () => null,
          );
      final patientName = patient?.name ?? 'Unknown Patient';

      final data = [
        r.id,
        r.patientId,
        patientName,
        r.type,
        _formatDate(r.visitDate),
        r.symptoms,
        r.diagnosis,
        r.medicines,
        'N/A',
        'N/A',
        r.isDraft ? 'Draft' : 'Final',
        _formatDate(r.updatedAt),
      ];
      _writeRow(opdSheet, i + 1, data, rowStyle);
    }
    _autoFitColumns(opdSheet);

    // ─── Sheet 3: Appointments ─────────────────────────────────────
    final apptSheet = excel['Appointments'];
    final apptHeaders = [
      'Appt ID',
      'Patient Name',
      'Date',
      'Time',
      'Notes',
      'Status',
      'Updated At',
    ];
    _writeRow(apptSheet, 0, apptHeaders, headerStyle);

    for (int i = 0; i < appointments.length; i++) {
      final a = appointments[i];
      final rowStyle = i % 2 == 1 ? altStyle : normalStyle;

      // Look up patient name
      final patient = patients.cast<PatientModel?>().firstWhere(
            (p) => p?.id == a.patientId,
            orElse: () => null,
          );
      final patientName = patient?.name ?? 'Unknown Patient';

      final data = [
        a.id,
        patientName,
        _formatDate(a.dateTime),
        _formatTime(a.dateTime),
        a.notes,
        a.isSynced ? 'Synced' : 'Pending Sync',
        _formatDate(a.updatedAt),
      ];
      _writeRow(apptSheet, i + 1, data, rowStyle);
    }
    _autoFitColumns(apptSheet);

    // Return the converted binary bytes
    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Helper to write an entire row of cell data with style
  void _writeRow(Sheet sheet, int rowIndex, List<String> values, CellStyle style) {
    for (int colIndex = 0; colIndex < values.length; colIndex++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
      cell.value = _toCellValue(values[colIndex]);
      cell.cellStyle = style;
    }
  }

  /// Helper to automatically adjust column width to fit largest value content
  void _autoFitColumns(Sheet sheet) {
    final maxCols = sheet.maxColumns;
    final maxRows = sheet.maxRows;
    for (int col = 0; col < maxCols; col++) {
      int maxLength = 0;
      for (int row = 0; row < maxRows; row++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        if (cell.value != null) {
          final strLen = cell.value.toString().length;
          if (strLen > maxLength) {
            maxLength = strLen;
          }
        }
      }
      sheet.setColumnWidth(col, (maxLength + 5).toDouble().clamp(12.0, 45.0));
    }
  }
}
