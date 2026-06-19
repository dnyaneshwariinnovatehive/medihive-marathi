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
import '../../services/whatsapp_share_helper.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/section_card.dart';

class _MedicineFieldData {
  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController duration;
  _MedicineFieldData({
    String name = '',
    String dosage = 'As directed',
    String duration = '-',
  }) : name = TextEditingController(text: name),
       dosage = TextEditingController(text: dosage),
       duration = TextEditingController(text: duration);

  Medicine toMedicine() => Medicine(
    name: name.text.trim(),
    dosage: dosage.text.trim(),
    duration: duration.text.trim(),
  );

  void dispose() {
    name.dispose();
    dosage.dispose();
    duration.dispose();
  }
}

class PrescriptionScreen extends StatefulWidget {
  final String patientId;
  const PrescriptionScreen({super.key, required this.patientId});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  bool _isEditing = false;
  bool _dataLoaded = false;
  String _patientPhone = '';
  late TextEditingController _diagnosisController;
  late TextEditingController _notesController;
  late TextEditingController _nextVisitController;
  late List<_MedicineFieldData> _medicineFields;
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
    _patientPhone = pModel.mobile;

    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final records = opdBox.values
        .where((r) => r.patientId == widget.patientId)
        .toList();
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
              medList.add(
                Medicine(
                  name: part.trim(),
                  dosage: 'As directed',
                  duration: '-',
                ),
              );
            }
          }
        }
      } catch (_) {
        final parts = _latestRecord.medicines.split(',');
        for (var part in parts) {
          if (part.trim().isNotEmpty) {
            medList.add(
              Medicine(name: part.trim(), dosage: 'As directed', duration: '-'),
            );
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
      diagnosis: _latestRecord.diagnosis.isNotEmpty
          ? _latestRecord.diagnosis
          : 'Consultation',
      medicines: medList,
      notes: _latestRecord.symptoms.isNotEmpty
          ? _latestRecord.symptoms
          : 'No specific instructions.',
      nextVisit: _latestRecord.nextVisit.isNotEmpty
          ? _latestRecord.nextVisit
          : 'As required',
      doctorName: settings.doctorName.isNotEmpty
          ? settings.doctorName
          : 'Dr. Rajas Gavas',
      clinicName: settings.clinicName.isNotEmpty
          ? settings.clinicName
          : 'Shree Clinic',
      clinicAddress: settings.clinicAddress.isNotEmpty
          ? settings.clinicAddress
          : 'Nirman bhavan, near Milagris school, Sawantwadi',
      clinicPhone: settings.clinicPhone.isNotEmpty
          ? settings.clinicPhone
          : '9067251670',
      licenseNo: settings.doctorLicense.isNotEmpty
          ? settings.doctorLicense
          : 'I-107200-A',
      patientMobile: pModel.mobile.isNotEmpty ? pModel.mobile : '',
    );

    _diagnosisController = TextEditingController(text: _rx.diagnosis);
    _notesController = TextEditingController(text: _rx.notes);
    _nextVisitController = TextEditingController(text: _rx.nextVisit);
    _initMedicineFields();
    _dataLoaded = true;
  }

  void _initMedicineFields() {
    _medicineFields = _rx.medicines
        .map(
          (m) => _MedicineFieldData(
            name: m.name,
            dosage: m.dosage,
            duration: m.duration,
          ),
        )
        .toList();
    if (_medicineFields.isEmpty) {
      _medicineFields.add(_MedicineFieldData());
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _nextVisitController.dispose();
    for (final f in _medicineFields) {
      f.dispose();
    }
    super.dispose();
  }

  List<Medicine> _decodeMedicines(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map(
              (e) => Medicine(
                name: e['name'] ?? '',
                dosage: e['dosage'] ?? 'As directed',
                duration: e['duration'] ?? '-',
              ),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  void _toggleEdit() {
    if (_isEditing) {
      _saveChanges();
    } else {
      _initMedicineFields();
      setState(() => _isEditing = true);
    }
  }

  void _saveChanges() {
    final newDiagnosis = _diagnosisController.text.trim();
    final newNotes = _notesController.text.trim();
    final newNextVisit = _nextVisitController.text.trim();
    final newMedicinesList = _medicineFields
        .map((f) => f.toMedicine())
        .where((m) => m.name.isNotEmpty)
        .toList();
    final newMedicinesRaw = newMedicinesList.map((m) => m.name).join(', ');

    final opdBox = Hive.box<OPDRecordModel>('opd_records');
    final updatedRecord = _latestRecord.copyWith(
      diagnosis: newDiagnosis.isNotEmpty
          ? newDiagnosis
          : _latestRecord.diagnosis,
      symptoms: newNotes.isNotEmpty ? newNotes : _latestRecord.symptoms,
      medicines: newMedicinesRaw.isNotEmpty
          ? newMedicinesRaw
          : _latestRecord.medicines,
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
      const SnackBar(
        content: Text('Prescription saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addMedicine() {
    setState(() {
      _medicineFields.add(_MedicineFieldData());
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicineFields[index].dispose();
      _medicineFields.removeAt(index);
    });
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 56,
            elevation: 0,
            backgroundColor: AppTheme.primary,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/app/patients');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _rx.date,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AnimatedListItem(
                        index: 0,
                        child: SectionCard(
                          shadows: AppTheme.heavyShadow,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _rx.clinicName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _rx.clinicAddress,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              _rx.clinicPhone,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.badge_outlined,
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Lic: ${_rx.licenseNo}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _rx.doctorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _toggleEdit,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isEditing
                                                  ? AppTheme.primary.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: _isEditing
                                                  ? null
                                                  : Border.all(
                                                      color: AppTheme.border,
                                                    ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _isEditing
                                                      ? Icons.check
                                                      : Icons.edit_outlined,
                                                  color: AppTheme.primary,
                                                  size: 20,
                                                ),
                                                if (_isEditing) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      color: AppTheme.primary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              _infoCol(
                                                'Patient Name',
                                                _rx.patientName,
                                              ),
                                              _infoCol(
                                                'Patient ID',
                                                _rx.patientId,
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            children: [
                                              _infoCol(
                                                'Age / Gender',
                                                '${_rx.age} / ${_rx.gender}',
                                              ),
                                              Expanded(
                                                child: _isEditing
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Diagnosis',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme
                                                                  .textSecondary,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          TextField(
                                                            controller:
                                                                _diagnosisController,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: AppTheme
                                                                  .textPrimary,
                                                              fontSize: 13,
                                                            ),
                                                            decoration: InputDecoration(
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical: 6,
                                                                  ),
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : _infoCol(
                                                        'Diagnosis',
                                                        _rx.diagnosis,
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      AnimatedListItem(
                        index: 1,
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Medicines Prescribed'),
                              SizedBox(height: 12),
                              if (_isEditing)
                                ..._medicineFields.asMap().entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceVariant,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Medicine ${e.key + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Spacer(),
                                              GestureDetector(
                                                onTap: () =>
                                                    _removeMedicine(e.key),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.danger
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.delete_outline,
                                                    color: AppTheme.danger,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          TextField(
                                            controller: e.value.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Medicine Name',
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: e.value.dosage,
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Dosage',
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: e.value.duration,
                                                  style: TextStyle(
                                                    color: AppTheme.textPrimary,
                                                    fontSize: 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Duration',
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ..._rx.medicines.asMap().entries.map(
                                  (e) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${e.key + 1}. ${e.value.name}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            _infoCol('Dosage', e.value.dosage),
                                            _infoCol(
                                              'Duration',
                                              e.value.duration,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_isEditing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: OutlinedButton.icon(
                                    onPressed: _addMedicine,
                                    icon: Icon(Icons.add, size: 16),
                                    label: Text(
                                      'Add Medicine',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      AnimatedListItem(
                        index: 2,
                        child: SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Instructions'),
                              SizedBox(height: 8),
                              if (_isEditing)
                                TextField(
                                  controller: _notesController,
                                  maxLines: 3,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.surfaceTint,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceTint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _rx.notes,
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 16),
                              if (_isEditing)
                                TextField(
                                  controller: _nextVisitController,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    color: AppTheme.primary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Next Visit',
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primary.withValues(alpha: 0.1),
                                        AppTheme.primaryLight.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Next Visit',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _rx.nextVisit,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.border,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                    ),
                  ),
                  child: Text(
                    'This is a computer-generated prescription',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final pdfData =
                                  await PrescriptionPdfService.generatePdf(_rx, includePatientDetails: false);
                              final tempDir = await getTemporaryDirectory();
                              final file = File(
                                '${tempDir.path}/Prescription_${_rx.patientId}.pdf',
                              );
                              await file.writeAsBytes(pdfData);
                              if (_patientPhone.isEmpty) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Patient has no phone number'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              final sent = await WhatsAppShareHelper.shareToWhatsApp(
                                file,
                                phoneNumber: _patientPhone,
                              );
                              if (!sent) {
                                await Share.shareXFiles(
                                  [XFile(file.path)],
                                  text: 'Prescription from ${_rx.clinicName}',
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error sharing prescription: $e',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.send, size: 20),
                          label: Text('Share via WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.whatsapp,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: AppTheme.whatsapp.withValues(
                              alpha: 0.3,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final pdfData =
                                      await PrescriptionPdfService.generatePdf(
                                        _rx,
                                      );
                                  final dir = getApplicationDocumentsDirectory();
                                  final docDir = Directory(
                                    '${(await dir).path}/Prescriptions',
                                  );
                                  if (!await docDir.exists()) {
                                    await docDir.create(recursive: true);
                                  }
                                  final file = File(
                                    '${docDir.path}/Prescription_${_rx.patientId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                                  );
                                  await file.writeAsBytes(pdfData);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Saved to ${file.path}',
                                      ),
                                      backgroundColor: AppTheme.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error saving prescription: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.download, size: 20),
                              label: Text('Download / Save'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final pdfData =
                                      await PrescriptionPdfService.generatePdf(
                                        _rx,
                                      );
                                  await Printing.layoutPdf(
                                    onLayout: (_) => pdfData,
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error printing prescription: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(Icons.print, size: 20),
                              label: Text('Print'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: AppTheme.border,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    ],
  );
}
