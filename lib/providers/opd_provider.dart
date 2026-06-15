import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/opd_form_data.dart';
import '../models/opd_record_model.dart';
import '../services/local_storage_service.dart';
import '../models/appointment_model.dart';
import 'dashboard_provider.dart';
import 'appointment_provider.dart';

class OpdProvider extends ChangeNotifier {
  int _currentStep = 0;
  final int totalSteps = 3;
  final OpdFormData _formData = OpdFormData();
  bool hasDraft = false;

  OpdProvider() {
    loadDraftFromHive();
  }

  int get currentStep => _currentStep;
  set currentStep(int val) {
    _currentStep = val;
    notifyListeners();
    _saveDraftToHive();
  }

  String _visitType = 'consultation';
  String get visitType => _visitType;
  set visitType(String val) {
    _visitType = val;
    _formData.opdType = val == 'follow_up' ? 'Follow-up' : 'Consultation';
    notifyListeners();
    _saveDraftToHive();
  }

  DateTime? _previousVisitDate;
  DateTime? get previousVisitDate => _previousVisitDate;
  set previousVisitDate(DateTime? val) {
    _previousVisitDate = val;
    if (val != null) {
      _formData.previousVisitDate = '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    } else {
      _formData.previousVisitDate = '';
    }
    notifyListeners();
    _saveDraftToHive();
  }

  String _followUpReason = '';
  String get followUpReason => _followUpReason;
  set followUpReason(String val) {
    _followUpReason = val;
    _formData.followUpReason = val;
    notifyListeners();
    _saveDraftToHive();
  }

  // Getters and Setters for complete Draft System
  String get patientName => _formData.name;
  set patientName(String val) {
    _formData.name = val;
    notifyListeners();
    _saveDraftToHive();
  }

  DateTime? get dob => DateTime.tryParse(_formData.dob);
  set dob(DateTime? val) {
    if (val != null) {
      _formData.dob = '${val.year}-${val.month.toString().padLeft(2, '0')}-${val.day.toString().padLeft(2, '0')}';
    } else {
      _formData.dob = '';
    }
    notifyListeners();
    _saveDraftToHive();
  }

  String get age => _formData.age;
  set age(String val) {
    _formData.age = val;
    notifyListeners();
    _saveDraftToHive();
  }

  String get mobile => _formData.mobile;
  set mobile(String val) {
    _formData.mobile = val;
    notifyListeners();
    _saveDraftToHive();
  }

  String get address => _formData.address;
  set address(String val) {
    _formData.address = val;
    notifyListeners();
    _saveDraftToHive();
  }

  List<String> get selectedSymptoms => _formData.symptoms.isEmpty ? [] : _formData.symptoms.split(', ');
  set selectedSymptoms(List<String> val) {
    _formData.symptoms = val.join(', ');
    notifyListeners();
    _saveDraftToHive();
  }

  List<String> get selectedDiagnoses => _formData.diagnosis.isEmpty ? [] : _formData.diagnosis.split(', ');
  set selectedDiagnoses(List<String> val) {
    _formData.diagnosis = val.join(', ');
    notifyListeners();
    _saveDraftToHive();
  }

  List<Map<String, dynamic>> get prescribedMedicines {
    if (_formData.medicines.isEmpty) return [];
    try {
      final decoded = jsonDecode(_formData.medicines);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (_) {
      // Fallback for old comma-separated strings
      return _formData.medicines.split(', ').map((e) {
        return {'name': e, 'type': '', 'dosage': '', 'frequency': '', 'duration': ''};
      }).toList();
    }
    return [];
  }

  set prescribedMedicines(List<Map<String, dynamic>> val) {
    _formData.medicines = jsonEncode(val);
    notifyListeners();
    _saveDraftToHive();
  }

  // Explicit setters calling _saveDraftToHive()
  void setPatientName(String name) {
    patientName = name;
  }

  void setDob(String dobStr) {
    updateField('dob', dobStr);
    _saveDraftToHive();
  }

  void setAge(String ageStr) {
    _formData.age = ageStr;
    notifyListeners();
    _saveDraftToHive();
  }

  void setMobile(String mob) {
    mobile = mob;
  }

  void setAddress(String addr) {
    address = addr;
  }

  void setVisitType(String type) {
    visitType = type;
  }

  void setSelectedSymptoms(List<String> symptoms) {
    selectedSymptoms = symptoms;
  }

  void setSelectedDiagnoses(List<String> diagnoses) {
    selectedDiagnoses = diagnoses;
  }

  void setPrescribedMedicines(List<Map<String, dynamic>> medicines) {
    prescribedMedicines = medicines;
  }

  OpdFormData get formData => _formData;

  // Hive Draft System Private & Public Save Methods
  void _saveDraftToHive() {
    try {
      final box = Hive.isBoxOpen('drafts') ? Hive.box('drafts') : null;
      if (box != null) {
        box.put('current_opd_draft', {
          'patientName': patientName,
          'dob': dob?.toIso8601String(),
          'age': age,
          'mobile': mobile,
          'address': address,
          'visitType': visitType,
          'selectedSymptoms': selectedSymptoms,
          'selectedDiagnoses': selectedDiagnoses,
          'prescribedMedicines': prescribedMedicines,
          'currentStep': currentStep,
          'savedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error saving draft to Hive: $e');
    }
  }

  void saveDraft() {
    _saveDraftToHive();
  }

  void loadDraftFromHive() {
    try {
      final box = Hive.isBoxOpen('drafts') ? Hive.box('drafts') : null;
      if (box != null) {
        final draft = box.get('current_opd_draft');
        if (draft != null && draft is Map) {
          final map = Map<String, dynamic>.from(draft);
          _formData.name = map['patientName'] ?? '';
          final dobStr = map['dob'];
          if (dobStr != null) {
            final parsed = DateTime.tryParse(dobStr);
            if (parsed != null) {
              _formData.dob = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
            }
          }
          _formData.age = map['age'] ?? '';
          _formData.mobile = map['mobile'] ?? '';
          _formData.address = map['address'] ?? '';
          
          final savedVisitType = map['visitType'] ?? 'consultation';
          _visitType = savedVisitType;
          _formData.opdType = savedVisitType == 'follow_up' ? 'Follow-up' : 'Consultation';
          
          final symptoms = map['selectedSymptoms'];
          if (symptoms is List) {
            _formData.symptoms = List<String>.from(symptoms).join(', ');
          }
          final diagnoses = map['selectedDiagnoses'];
          if (diagnoses is List) {
            _formData.diagnosis = List<String>.from(diagnoses).join(', ');
          }
          final medicines = map['prescribedMedicines'];
          if (medicines is List) {
            if (medicines.isNotEmpty && medicines.first is Map) {
              prescribedMedicines = List<Map<String, dynamic>>.from(medicines.map((e) => Map<String, dynamic>.from(e)));
            } else {
              _formData.medicines = List<String>.from(medicines).join(', ');
            }
          }
          _currentStep = map['currentStep'] ?? 0;
          hasDraft = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading draft from Hive: $e');
    }
  }

  void clearDraft() {
    try {
      final box = Hive.isBoxOpen('drafts') ? Hive.box('drafts') : null;
      if (box != null) {
        box.delete('current_opd_draft');
      }
    } catch (e) {
      debugPrint('Error clearing draft from Hive: $e');
    }
    reset();
    hasDraft = false;
    notifyListeners();
  }

  bool get hasUnsavedData {
    return patientName.isNotEmpty ||
        _formData.dob.isNotEmpty ||
        age.isNotEmpty ||
        mobile.isNotEmpty ||
        address.isNotEmpty ||
        _formData.symptoms.isNotEmpty ||
        _formData.diagnosis.isNotEmpty ||
        _formData.medicines.isNotEmpty;
  }

  Future<void> autoSaveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = _formData.patientId.isNotEmpty 
          ? 'opd_draft_${_formData.patientId}' 
          : 'opd_draft_new_patient';
      
      final draftData = {
        'step': _currentStep,
        'form': _formData.toJson(),
      };

      await prefs.setString(draftKey, jsonEncode(draftData));

      final Set<String> allDraftKeys = prefs.getStringList('opd_draft_keys')?.toSet() ?? {};
      allDraftKeys.add(draftKey);
      await prefs.setStringList('opd_draft_keys', allDraftKeys.toList());
      notifyListeners();
    } catch (e) {
      debugPrint('Error auto-saving draft: $e');
    }
  }

  Future<void> loadDraft(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final data = jsonDecode(jsonString);
        _currentStep = data['step'] ?? 0;
        _formData.fromJson(data['form'] ?? {});
        
        // Rebuild prescriptions from medicines string
        updateField('medicines', _formData.medicines);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading draft: $e');
    }
  }

  Future<void> discardDraft(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);

      final List<String> allDraftKeys = prefs.getStringList('opd_draft_keys') ?? [];
      allDraftKeys.remove(key);
      await prefs.setStringList('opd_draft_keys', allDraftKeys);
      notifyListeners();
    } catch (e) {
      debugPrint('Error discarding draft: $e');
    }
  }

  static Future<bool> hasDraftForPatient(String patientId) async {
    if (patientId.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('opd_draft_$patientId');
  }

  void updateField(String field, String value) {
    switch (field) {
      case 'patientId':
        _formData.patientId = value;
      case 'name':
        _formData.name = value;
      case 'dob':
        _formData.dob = value;
        // Auto-calculate age (years/months) from DOB
        final birthDate = DateTime.tryParse(value);
        if (birthDate != null) {
          final now = DateTime.now();
          int years = now.year - birthDate.year;
          int months = now.month - birthDate.month;
          if (months < 0 || (months == 0 && now.day < birthDate.day)) {
            years--;
            months += 12;
          }
          if (now.day < birthDate.day) {
            months--;
          }
          if (months < 0) {
            months = 11;
          }
          if (years > 0) {
            _formData.age = '$years yr, $months mo';
          } else {
            _formData.age = '$months mo';
          }
        }
      case 'age':
        _formData.age = value;
      case 'gender':
        _formData.gender = value;
      case 'mobile':
        _formData.mobile = value;
      case 'address':
        _formData.address = value;
      case 'bloodGroup':
        _formData.bloodGroup = value;
      case 'diagnosis':
        _formData.diagnosis = value;
      case 'symptoms':
        _formData.symptoms = value;
      case 'opdType':
        _formData.opdType = value;
      case 'chargeType':
        _formData.chargeType = value;
      case 'medicines':
        _formData.medicines = value;
      case 'clinicalNotes':
        _formData.clinicalNotes = value;
      case 'nextVisit':
        _formData.nextVisit = value;
      case 'consultationFee':
        _formData.consultationFee = value;
      case 'medicineFee':
        _formData.medicineFee = value;
      case 'discount':
        _formData.discount = value;
      case 'paymentMode':
        _formData.paymentMode = value;
      case 'previousVisitDate':
        _formData.previousVisitDate = value;
      case 'followUpReason':
        _formData.followUpReason = value;
    }
    notifyListeners();
    autoSaveDraft();
    _saveDraftToHive();
  }

  String? validateCurrentStep() {
    if (_currentStep == 0) {
      if (_formData.name.trim().isEmpty) return 'Full Name is required.';
      if (_formData.dob.trim().isEmpty) return 'Date of Birth is required.';
      if (_formData.mobile.trim().isEmpty) return 'Mobile Number is required.';
      if (_formData.address.trim().isEmpty) return 'Address is required.';
    }
    return null; // Valid
  }

  void nextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
      autoSaveDraft();
      _saveDraftToHive();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
      autoSaveDraft();
      _saveDraftToHive();
    }
  }

  void reset() {
    final draftKey = _formData.patientId.isNotEmpty 
        ? 'opd_draft_${_formData.patientId}' 
        : 'opd_draft_new_patient';
    discardDraft(draftKey);

    _currentStep = 0;
    _formData.reset();
    notifyListeners();
  }

  Future<bool> submitRecord({DashboardProvider? dashboardProvider, AppointmentProvider? appointmentProvider}) async {
    try {
      // Pre-capture form data before any await to avoid race with form reset
      final nextVisit = _formData.nextVisit;
      final patientId = _formData.patientId;
      final patientName = _formData.name.isEmpty ? 'Unknown' : _formData.name;

      // 1. Save OPD Record
      final recordId = 'R${DateTime.now().millisecondsSinceEpoch}';
      final record = OPDRecordModel(
        id: recordId,
        patientId: patientId,
        type: _formData.opdType == 'Follow-up' ? 'follow_up' : 'consultation',
        symptoms: _formData.symptoms,
        diagnosis: _formData.diagnosis,
        medicines: _formData.medicines,
        visitDate: DateTime.now(),
        isDraft: false,
        isSynced: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await LocalStorageService().saveOPDRecord(record);

      // 2. Auto-create follow-up appointment if nextVisit is set
      if (nextVisit.isNotEmpty && appointmentProvider != null) {
        final nextDate = DateTime.tryParse(nextVisit);
        if (nextDate != null && !nextDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
          final aptBox = Hive.box<AppointmentModel>('appointments');
          final aptId = 'opd_fu_${patientId}_${nextDate.year}_${nextDate.month}_${nextDate.day}';
          final exists = aptBox.values.any((a) => a.id == aptId);
          if (!exists) {
            final displayTime = '9:00 AM';
            appointmentProvider.addAppointment(
              dateTime: nextDate,
              type: 'Follow-up',
              patient: patientName,
              time: displayTime,
            );
            final appointmentModel = AppointmentModel(
              id: aptId,
              patientId: patientId,
              dateTime: nextDate,
              notes: 'Follow-up',
              isSynced: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await aptBox.put(aptId, appointmentModel);
          }
        }
      }

      // 3. Reset form
      reset();

      // 4. Notify dashboard to reload
      if (dashboardProvider != null) {
        await dashboardProvider.loadDashboardData();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  bool saveRecord({DashboardProvider? dashboardProvider, AppointmentProvider? appointmentProvider}) {
    submitRecord(dashboardProvider: dashboardProvider, appointmentProvider: appointmentProvider);
    return true;
  }

}
