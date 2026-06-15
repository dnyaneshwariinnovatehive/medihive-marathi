import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/opd_form_data.dart';
import '../models/patient.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';

class PatientProvider extends ChangeNotifier {
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool isSearching = false;
  List<PatientModel> _filteredPatients = [];
  String _sortFilter = 'recent_visit';
  StreamSubscription? _patientSubscription;

  String get sortFilter => _sortFilter;
  void setSortFilter(String val) {
    _sortFilter = val;
    notifyListeners();
  }

  List<PatientModel> get displayedPatients =>
    _searchQuery.isEmpty 
      ? (_sortedPatients)
      : _filteredPatients;

  List<PatientModel> get _sortedPatients {
    final list = Hive.box<PatientModel>('patients').values.toList();
    list.sort((a, b) => 
      (b.lastVisitDate ?? b.createdAt)
        .compareTo(a.lastVisitDate ?? a.createdAt));
    return list;
  }

  PatientProvider() {
    loadPatients();
    _patientSubscription = Hive.box<PatientModel>('patients').watch().listen((_) {
      loadPatients();
    });
  }

  @override
  void dispose() {
    _patientSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void onSearchChanged(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final q = query.toLowerCase();
    final qNum = query.replaceAll(RegExp(r'[^0-9]'), '');
    _filteredPatients = Hive.box<PatientModel>('patients')
      .values
      .where((p) {
        final pNum = p.id.toString().replaceAll(RegExp(r'[^0-9]'), '');
        return p.name.toLowerCase().contains(q) ||
          p.id.toString().toLowerCase().contains(q) ||
          (qNum.isNotEmpty && pNum.contains(qNum)) ||
          p.mobile.contains(q) ||
          (p.lastDiagnosis ?? '').toLowerCase().contains(q);
      }).toList();
    isSearching = false;
    notifyListeners();
  }

  // Backward compatibility fields and methods
  String get searchQuery => _searchQuery;
  List<Patient> _patients = [];

  void loadPatients() {
    try {
      final box = Hive.box<PatientModel>('patients');
      _patients = box.values.map((p) {
        return Patient(
          id: p.id,
          name: p.name,
          age: p.age,
          gender: p.gender.isNotEmpty && p.gender != 'Not Specified' ? p.gender : 'Unknown',
          mobile: p.mobile,
          lastVisit: (p.lastVisitDate ?? p.createdAt).toString().split(' ')[0],
          dob: p.dob,
          diagnosis: p.lastDiagnosis ?? '',
        );
      }).toList();
      // Sort by most recent visit descending
      _patients.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
    } catch (_) {
      _patients = [];
    }
    notifyListeners();
  }

  List<Patient> get patients => _patients;

  List<Patient> get filteredPatients {
    List<Patient> result;
    if (_searchQuery.isEmpty) {
      result = List<Patient>.from(_patients);
    } else {
      final query = _searchQuery.toLowerCase();
      final queryNum = _searchQuery.replaceAll(RegExp(r'[^0-9]'), '');
      result = _patients.where((p) {
        final pNum = p.id.replaceAll(RegExp(r'[^0-9]'), '');
        return p.name.toLowerCase().contains(query) ||
            p.id.toLowerCase().contains(query) ||
            (queryNum.isNotEmpty && pNum.contains(queryNum)) ||
            p.mobile.contains(query) ||
            p.diagnosis.toLowerCase().contains(query);
      }).toList();
    }

    switch (_sortFilter) {
      case 'oldest_visit':
        result.sort((a, b) => a.lastVisit.compareTo(b.lastVisit));
        break;
      case 'name_asc':
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'id_asc':
        result.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'recent_visit':
      default:
        result.sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
        break;
    }
    
    return result;
  }

  Future<void> deletePatientAndRecords(String patientId) async {
    try {
      final patientBox = Hive.box<PatientModel>('patients');
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final opdRecords = opdBox.values.where((r) => r.patientId == patientId).toList();
      for (final record in opdRecords) {
        await opdBox.delete(record.id);
      }
      await patientBox.delete(patientId);
      loadPatients();
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    onSearchChanged(query);
  }

  String generateNextPatientId() {
    int maxIdVal = 0;
    try {
      final box = Hive.box<PatientModel>('patients');
      for (final patient in box.values) {
        if (patient.id.startsWith('P')) {
          final idPart = patient.id.substring(1);
          final val = int.tryParse(idPart);
          if (val != null && val > maxIdVal) {
            maxIdVal = val;
          }
        }
      }
    } catch (_) {}
    final nextVal = maxIdVal + 1;
    return 'P${nextVal.toString().padLeft(3, '0')}';
  }

  int _calculateAgeFromDob(String dobStr) {
    final dob = DateTime.tryParse(dobStr);
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  void addPatientFromOpd(OpdFormData formData) {
    final box = Hive.box<PatientModel>('patients');
    
    // Check if patient already exists in Hive box by ID or Mobile
    PatientModel? existingPatient;
    if (formData.patientId.isNotEmpty) {
      existingPatient = box.values.cast<PatientModel?>().firstWhere(
        (p) => p?.id == formData.patientId,
        orElse: () => null,
      );
    } else if (formData.mobile.isNotEmpty) {
      existingPatient = box.values.cast<PatientModel?>().firstWhere(
        (p) => p?.mobile == formData.mobile,
        orElse: () => null,
      );
    }

    final ageFromDob = _calculateAgeFromDob(formData.dob);

    if (existingPatient != null) {
      formData.patientId = existingPatient.id;
      final updatedPatient = existingPatient.copyWith(
        name: formData.name.isNotEmpty ? formData.name : existingPatient.name,
        dob: formData.dob.isNotEmpty ? formData.dob : existingPatient.dob,
        age: ageFromDob > 0 ? ageFromDob : existingPatient.age,
        gender: formData.gender.isNotEmpty ? formData.gender : existingPatient.gender,
        bloodGroup: formData.bloodGroup.isNotEmpty ? formData.bloodGroup : existingPatient.bloodGroup,
        mobile: formData.mobile.isNotEmpty ? formData.mobile : existingPatient.mobile,
        address: formData.address.isNotEmpty ? formData.address : existingPatient.address,
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      box.put(updatedPatient.id, updatedPatient);
    } else {
      final nextId = generateNextPatientId();
      formData.patientId = nextId;

      final newPatient = PatientModel(
        id: nextId,
        name: formData.name.isEmpty ? 'Unknown' : formData.name,
        dob: formData.dob.isEmpty ? DateTime.now().toIso8601String().split('T')[0] : formData.dob,
        age: ageFromDob > 0 ? ageFromDob : 0,
        gender: formData.gender.isNotEmpty ? formData.gender : 'Not Specified',
        bloodGroup: formData.bloodGroup.isNotEmpty ? formData.bloodGroup : 'Not Specified',
        mobile: formData.mobile,
        address: formData.address.isEmpty ? 'Not specified' : formData.address,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      box.put(newPatient.id, newPatient);
    }

    loadPatients();
  }
}

extension PatientModelExtension on PatientModel {
  DateTime? get lastVisitDate {
    try {
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final records = opdBox.values.where((r) => r.patientId == id).toList();
      if (records.isEmpty) return null;
      records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return records.first.visitDate;
    } catch (_) {
      return null;
    }
  }

  String? get lastDiagnosis {
    try {
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final records = opdBox.values.where((r) => r.patientId == id).toList();
      if (records.isEmpty) return null;
      records.sort((a, b) => b.visitDate.compareTo(a.visitDate));
      return records.first.diagnosis;
    } catch (_) {
      return null;
    }
  }
}
