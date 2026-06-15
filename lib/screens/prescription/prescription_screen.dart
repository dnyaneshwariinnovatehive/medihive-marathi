import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/prescription.dart';
import '../../models/patient_model.dart';
import '../../models/opd_record_model.dart';
import '../../providers/settings_provider.dart';
import '../../services/prescription_pdf_service.dart';

class PrescriptionScreen extends StatefulWidget {
  final String patientId;
  const PrescriptionScreen({super.key, required this.patientId});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isEditing = false;
  bool _dataLoaded = false;
  late TextEditingController _diagnosisController;
  late TextEditingController _notesController;
  late TextEditingController _nextVisitController;
  late TextEditingController _medicinesController;
  late OPDRecordModel _latestRecord;
  late Prescription _rx;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final patientBox = Hive.box<PatientModel>('patients');
    final pModel = patientBox.values.cast<PatientModel?>().firstWhere(
      (p) => p?.id == widget.patientId,
      orElse: () => null,
    );

    if (pModel == null) return;

    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final records = opdBox.values.where((r) => r.patientId == widget.patientId).toList();
    records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    if (records.isEmpty) return;
    _latestRecord = records.first;

    final settings = context.read<SettingsProvider>();

    final List<Medicine> medList = [];
    if (_latestRecord.medicines.isNotEmpty) {
      try {
        final decoded = _decodeMedicines(_latestRecord.medicines);
        if (decoded.isNotEmpty) {
          medList.addAll(decoded);
        } else {
          final parts = _latestRecord.medicines.split(',');
          for (var part in parts) {
            if (part.trim().isNotEmpty) {
              medList.add(Medicine(name: part.trim(), dosage: 'As directed', duration: '-'));
            }
          }
        }
      } catch (_) {
        final parts = _latestRecord.medicines.split(',');
        for (var part in parts) {
          if (part.trim().isNotEmpty) {
            medList.add(Medicine(name: part.trim(), dosage: 'As directed', duration: '-'));
          }
        }
      }
    }

    _rx = Prescription(
      date: DateFormat('dd MMM yyyy').format(_latestRecord.visitDate),
      patientName: pModel.name,
      patientId: pModel.id,
      age: pModel.age,
      gender: pModel.gender.isNotEmpty ? pModel.gender : 'Unknown',
      diagnosis: _latestRecord.diagnosis.isNotEmpty ? _latestRecord.diagnosis : 'Consultation',
      medicines: medList,
      notes: _latestRecord.symptoms.isNotEmpty ? _latestRecord.symptoms : 'No specific instructions.',
      nextVisit: 'As required',
      doctorName: settings.doctorName.isNotEmpty ? settings.doctorName : 'Dr. Rajas Gavas',
      clinicName: settings.clinicName.isNotEmpty ? settings.clinicName : 'Shree Clinic',
      clinicAddress: settings.clinicAddress.isNotEmpty ? settings.clinicAddress : 'Nirman bhavan, near Milagris school, Sawantwadi',
      clinicPhone: settings.clinicPhone.isNotEmpty ? settings.clinicPhone : '9067251670',
      licenseNo: settings.doctorLicense.isNotEmpty ? settings.doctorLicense : 'I-107200-A',
    );

    _diagnosisController = TextEditingController(text: _rx.diagnosis);
    _notesController = TextEditingController(text: _rx.notes);
    _nextVisitController = TextEditingController(text: _rx.nextVisit);
    _medicinesController = TextEditingController(text: _medicinesToText(_rx.medicines));
    _dataLoaded = true;
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _nextVisitController.dispose();
    _medicinesController.dispose();
    super.dispose();
  }

  List<Medicine> _decodeMedicines(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Medicine(
          name: e['name'] ?? '',
          dosage: e['dosage'] ?? 'As directed',
          duration: e['duration'] ?? '-',
        )).toList();
      }
    } catch (_) {}
    return [];
  }

  String _medicinesToText(List<Medicine> meds) {
    return meds.map((m) => '${m.name}|${m.dosage}|${m.duration}').join('\n');
  }

  List<Medicine> _textToMedicines(String text) {
    return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
      final parts = line.split('|');
      return Medicine(
        name: parts.isNotEmpty ? parts[0].trim() : '',
        dosage: parts.length > 1 ? parts[1].trim() : 'As directed',
        duration: parts.length > 2 ? parts[2].trim() : '-',
      );
    }).toList();
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _saveChanges() {
    final newDiagnosis = _diagnosisController.text.trim();
    final newNotes = _notesController.text.trim();
    final newNextVisit = _nextVisitController.text.trim();
    final newMedicinesList = _textToMedicines(_medicinesController.text);
    final newMedicinesRaw = newMedicinesList.map((m) => m.name).join(', ');

    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final updatedRecord = _latestRecord.copyWith(
      diagnosis: newDiagnosis.isNotEmpty ? newDiagnosis : _latestRecord.diagnosis,
      symptoms: newNotes.isNotEmpty ? newNotes : _latestRecord.symptoms,
      medicines: newMedicinesRaw.isNotEmpty ? newMedicinesRaw : _latestRecord.medicines,
      updatedAt: DateTime.now(),
    );
    opdBox.put(updatedRecord.id, updatedRecord);
    _latestRecord = updatedRecord;

    final updatedRx = Prescription(
      date: _rx.date,
      patientName: _rx.patientName,
      patientId: _rx.patientId,
      age: _rx.age,
      gender: _rx.gender,
      diagnosis: newDiagnosis.isNotEmpty ? newDiagnosis : _rx.diagnosis,
      medicines: newMedicinesList.isNotEmpty ? newMedicinesList : _rx.medicines,
      notes: newNotes.isNotEmpty ? newNotes : _rx.notes,
      nextVisit: newNextVisit.isNotEmpty ? newNextVisit : _rx.nextVisit,
      doctorName: _rx.doctorName,
      clinicName: _rx.clinicName,
      clinicAddress: _rx.clinicAddress,
      clinicPhone: _rx.clinicPhone,
      licenseNo: _rx.licenseNo,
    );
    _rx = updatedRx;

    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription saved'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prescription')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/app/patients');
                    }
                  },
                ),
                SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Prescription', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  Text(_rx.date, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (_isEditing) ...[
                          const SizedBox(width: 4),
                          Text('Save', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            )),
          ),
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Container(
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.heavyShadow),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_rx.clinicName, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(_rx.clinicAddress, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                    SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Phone: ${_rx.clinicPhone}', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text('Lic: ${_rx.licenseNo}', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ]),
                ),
                Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(_rx.doctorName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
                    Text(_rx.date, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ]),
                  SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Row(children: [
                        _infoCol('Patient Name', _rx.patientName),
                        _infoCol('Patient ID', _rx.patientId),
                      ]),
                      SizedBox(height: 12),
                      Row(children: [
                        _infoCol('Age / Gender', '${_rx.age} / ${_rx.gender}'),
                        Expanded(
                          child: _isEditing
                              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('Diagnosis', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  SizedBox(height: 2),
                                  TextField(
                                    controller: _diagnosisController,
                                    style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ])
                              : _infoCol('Diagnosis', _rx.diagnosis),
                        ),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 20),
                  _sectionTitle('Medicines Prescribed'),
                  SizedBox(height: 12),
                  if (_isEditing)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Enter each medicine as: Name|Dosage|Duration (one per line)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        SizedBox(height: 8),
                        TextField(
                          controller: _medicinesController,
                          maxLines: 5,
                          style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Medicine1|Dosage|Duration\nMedicine2|Dosage|Duration',
                            isDense: true,
                            contentPadding: EdgeInsets.all(10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ]),
                    )
                  else
                    ..._rx.medicines.asMap().entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${e.key + 1}. ${e.value.name}', style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                        SizedBox(height: 8),
                        Row(children: [
                          _infoCol('Dosage', e.value.dosage),
                          _infoCol('Duration', e.value.duration),
                        ]),
                      ]),
                    )),
                  SizedBox(height: 12),
                  _sectionTitle('Instructions'),
                  SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.surfaceTint,
                      ),
                    )
                  else
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.surfaceTint, borderRadius: BorderRadius.circular(12)),
                      child: Text(_rx.notes, style: TextStyle(color: AppTheme.textPrimary))),
                  SizedBox(height: 16),
                  if (_isEditing)
                    TextField(
                      controller: _nextVisitController,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.primary),
                      decoration: InputDecoration(
                        labelText: 'Next Visit',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                    )
                  else
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primaryLight.withValues(alpha: 0.1)]),
                      borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Next Visit', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text(_rx.nextVisit, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.primary)),
                      ]),
                    ),
                ])),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border, width: 2, strokeAlign: BorderSide.strokeAlignCenter))),
                  child: Text('This is a computer-generated prescription', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ]),
            ),
            SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final pdfData = await PrescriptionPdfService.generatePdf(_rx);
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/Prescription_${_rx.patientId}.pdf');
                  await file.writeAsBytes(pdfData);
                  await Share.shareXFiles([XFile(file.path)], text: 'Prescription for ${_rx.patientName} from ${_rx.clinicName}');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sharing prescription: $e')));
                }
              },
              icon: Icon(Icons.send, size: 20),
              label: Text('Share via WhatsApp'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.whatsapp, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
            )),
            SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final pdfData = await PrescriptionPdfService.generatePdf(_rx);
                    await Printing.sharePdf(bytes: pdfData, filename: 'Prescription_${_rx.patientId}.pdf');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading prescription: $e')));
                  }
                },
                icon: Icon(Icons.download, size: 20), label: Text('Download / Save'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.primary, width: 2)),
              )),
              SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final pdfData = await PrescriptionPdfService.generatePdf(_rx);
                    await Printing.layoutPdf(onLayout: (_) => pdfData);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing prescription: $e')));
                  }
                },
                icon: Icon(Icons.print, size: 20), label: Text('Print'),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textPrimary, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: AppTheme.border, width: 2)),
              )),
            ]),
            SizedBox(height: 80),
          ])),
        ]),
      ),
    );
  }

  Widget _infoCol(String label, String value) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
    SizedBox(height: 2),
    Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  ]));

  Widget _sectionTitle(String title) => Row(children: [
    Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
    SizedBox(width: 8),
    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
  ]);
}


