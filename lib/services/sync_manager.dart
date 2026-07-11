import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import '../models/appointment_model.dart';
import '../repositories/patient_repository.dart';
import '../repositories/opd_record_repository.dart';
import '../repositories/sync_queue_repository.dart';
import '../repositories/patient_images_repository.dart';
import '../repositories/device_registration_repository.dart';
import '../database/database_helper.dart';
import 'dart:math' show Random;

enum SyncState {
  offline,
  syncing,
  synced,
  error,
}

class SyncManager extends ChangeNotifier {
  final ConnectivityService _connectivity = ConnectivityService();
  final PatientRepository _patientRepo = PatientRepository();
  final OpdRecordRepository _opdRepo = OpdRecordRepository();
  final SyncQueueRepository _syncQueueRepo = SyncQueueRepository();
  final PatientImagesRepository _imagesRepo = PatientImagesRepository();
  final DeviceRegistrationRepository _deviceRegRepo = DeviceRegistrationRepository();

  SyncState _syncState = SyncState.synced;
  bool _pendingSyncRequested = false;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  int _syncCount = 0;
  String? _deviceId;

  SyncState get syncState => _syncState;
  bool get isSyncing => _syncState == SyncState.syncing;
  int get syncCount => _syncCount;
  String? get deviceId => _deviceId;

  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal() {
    if (kIsWeb) return;
    _init();
  }

  Future<void> _init() async {
    _deviceId = await _loadOrCreateDeviceId();
    _connectivitySubscription = _connectivity.isConnected.listen((connected) {
      if (!connected) {
        _syncState = SyncState.offline;
        notifyListeners();
      } else {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), _trySync);
      }
    });
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) => _trySync());
    Timer(const Duration(seconds: 5), _trySync);
    await _registerDevice();
  }

  Future<void> _registerDevice() async {
    if (_deviceId == null) return;
    try {
      await ApiService.cloudRegisterDevice(
        deviceId: _deviceId!,
        deviceName: _getDeviceName(),
        clinicId: '',
        appVersion: '1.0.0',
      );
    } catch (_) {}
  }

  Future<void> _trySync() async {
    if (kIsWeb) return;
    if (!_connectivity.currentStatus) return;
    if (_syncState == SyncState.syncing) return;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await ApiService.ensureToken();
      await _syncWithBackend();
      _syncCount++;
      _syncState = SyncState.synced;
      notifyListeners();

      if (_pendingSyncRequested) {
        _pendingSyncRequested = false;
        _trySync();
      }
    } catch (e) {
      debugPrint('SYNC error: $e');
      _syncState = SyncState.error;
      notifyListeners();
    }
  }

  Future<void> _syncWithBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString('last_flask_sync') ?? '';

    // ── Push ──
    final pending = await _syncQueueRepo.getPending();
    final pushPatients = <Map<String, dynamic>>[];
    final pushOpd = <Map<String, dynamic>>[];
    final pushAppts = <Map<String, dynamic>>[];
    final deletedEntities = <Map<String, String>>[];

    for (final entry in pending) {
      final entityType = entry['entity_type'] as String? ?? '';
      final entityId = entry['entity_id'] as String? ?? '';
      final operation = entry['operation'] as String? ?? 'upsert';

      if (operation == 'delete') {
        deletedEntities.add({'entity_type': entityType, 'entity_id': entityId});
        continue;
      }

      if (entityType == 'patient') {
        final row = await _patientRepo.getBySyncId(entityId);
        if (row != null) {
          pushPatients.add(_patientRowToMap(row));
        }
      } else if (entityType == 'opd_visit') {
        final row = await _opdRepo.getByOpdId(entityId);
        if (row != null) {
          pushOpd.add(_opdRowToMap(row));
        }
      }
    }

    try {
      final apptBox = Hive.box<AppointmentModel>('appointments');
      for (final a in apptBox.values) {
        if (!a.isSynced) {
          pushAppts.add(a.toJson());
        }
      }
    } catch (_) {}

    if (pushPatients.isNotEmpty || pushOpd.isNotEmpty || pushAppts.isNotEmpty || deletedEntities.isNotEmpty) {
      final response = await ApiService.syncPush(
        patients: pushPatients,
        opdRecords: pushOpd,
        appointments: pushAppts,
        deletedEntities: deletedEntities,
        deviceId: _deviceId ?? '',
      );

      final tempMapped = response['temp_ids_mapped'] as Map<String, dynamic>? ?? {};
      for (final entry in tempMapped.entries) {
        await _patientRepo.updateSyncId(entry.key, entry.value as String);
      }

      final now = DateTime.now().toIso8601String();
      for (final entry in pending) {
        await _syncQueueRepo.update(entry['id'] as int, {
          'status': 'synced',
          'last_attempt': now,
        });
      }

      try {
        final box = Hive.box<AppointmentModel>('appointments');
        for (final a in pushAppts) {
          final id = a['id'] as String;
          final existing = box.get(id);
          if (existing != null) {
            box.put(id, existing.copyWith(isSynced: true, updatedAt: DateTime.now()));
          }
        }
      } catch (_) {}
    }

    // ── Upload images ──
    await _uploadPendingImages();

    // ── Pull ──
    final pullSync = lastSync.isEmpty ? '2000-01-01T00:00:00' : lastSync;
    try {
      final data = await ApiService.syncPull(pullSync);

      await _applyRemotePatients(data['patients'] as List<dynamic>? ?? []);
      await _applyRemoteOpdRecords(data['opd_records'] as List<dynamic>? ?? []);
      await _applyRemoteAppointments(data['appointments'] as List<dynamic>? ?? []);
      await _applyRemoteDeletes(data['deleted_entities'] as List<dynamic>? ?? []);

      await prefs.setString(
        'last_flask_sync',
        data['server_time']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
    } catch (e) {
      debugPrint('SYNC pull failed (non-fatal): $e');
    }
  }

  Future<void> _uploadPendingImages() async {
    try {
      final docBox = Hive.box('opd_documents');
      for (final key in docBox.keys) {
        final opdId = key.toString();
        final raw = docBox.get(opdId);
        if (raw == null) continue;

        final bytes = base64Decode(raw.toString());
        final tempFile = File('${Directory.systemTemp.path}/${opdId}_${DateTime.now().microsecondsSinceEpoch}.jpg');
        try {
          await tempFile.writeAsBytes(bytes);
          await ApiService.cloudUploadImages(opdId, [tempFile]);
          await docBox.delete(opdId);
        } catch (e) {
          debugPrint('SYNC image upload failed for $opdId: $e');
        } finally {
          if (await tempFile.exists()) await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('SYNC image upload error: $e');
    }
  }

  Future<void> _applyRemotePatients(List<dynamic> remotePatients) async {
    for (final json in remotePatients) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final remoteId = map['id']?.toString() ?? '';
        final remoteUpdated = DateTime.tryParse(map['updated_at']?.toString() ?? '');
        final existing = await _patientRepo.getBySyncId(remoteId);
        final localUpdated = DateTime.tryParse(
          existing?['updated_at'] as String? ?? existing?['created_at'] as String? ?? '',
        );

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          if (existing != null) {
            await _patientRepo.update(existing['id'] as int, _remotePatientToRow(map, existing['id'] as int, remoteId));
          } else {
            final maxId = await _patientRepo.getMaxId();
            await _patientRepo.insert(_remotePatientToRow(map, maxId + 1, remoteId));
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _applyRemoteOpdRecords(List<dynamic> remoteOpd) async {
    for (final json in remoteOpd) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final remoteId = map['id']?.toString() ?? '';
        final remoteUpdated = DateTime.tryParse(map['updated_at']?.toString() ?? '');
        final existing = await _opdRepo.getByOpdId(remoteId);
        final localUpdated = DateTime.tryParse(
          existing?['updated_at'] as String? ?? existing?['created_at'] as String? ?? '',
        );

        if (existing == null || (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated))) {
          final localId = existing != null ? existing['id'] as int : (await _opdRepo.getMaxId()) + 1;
          final row = await _remoteOpdToRow(map, localId);
          if (existing != null) {
            await _opdRepo.update(localId, row);
          } else {
            await _opdRepo.insert(row);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _applyRemoteAppointments(List<dynamic> remoteAppts) async {
    for (final json in remoteAppts) {
      try {
        final map = Map<String, dynamic>.from(json as Map);
        final apptBox = Hive.box<AppointmentModel>('appointments');
        final existing = apptBox.get(map['id']);
        final remoteUpdated = DateTime.tryParse(map['updated_at']?.toString() ?? '');
        if (existing == null ||
            (remoteUpdated != null && existing.updatedAt.isBefore(remoteUpdated))) {
          apptBox.put(map['id'], AppointmentModel.fromJson(map));
        }
      } catch (_) {}
    }
  }

  Future<void> _applyRemoteDeletes(List<dynamic> remoteDeleted) async {
    for (final del in remoteDeleted) {
      try {
        final d = Map<String, dynamic>.from(del as Map);
        final etype = d['entity_type']?.toString() ?? '';
        final eid = d['entity_id']?.toString() ?? '';

        if (etype == 'patient') {
          final local = await _patientRepo.getBySyncId(eid);
          if (local != null) {
            final localId = local['id'] as int;
            await _opdRepo.deleteByPatientId(localId);
            await _patientRepo.delete(localId);
          }
        } else if (etype == 'opd_visit') {
          final local = await _opdRepo.getByOpdId(eid);
          if (local != null) {
            await _opdRepo.delete(local['id'] as int);
          }
        } else if (etype == 'appointment') {
          try {
            final apptBox = Hive.box<AppointmentModel>('appointments');
            if (apptBox.containsKey(eid)) await apptBox.delete(eid);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  Future<void> forceSyncNow() async {
    if (_syncState == SyncState.syncing) {
      _pendingSyncRequested = true;
      return;
    }
    await _trySync();
  }

  Future<bool> fullRestore() async {
    if (!_connectivity.currentStatus) return false;
    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await ApiService.ensureToken();
      final data = await ApiService.fullRestore();
      await _applyRemotePatients(data['patients'] as List<dynamic>? ?? []);
      await _applyRemoteOpdRecords(data['opd_records'] as List<dynamic>? ?? []);
      await _applyRemoteAppointments(data['appointments'] as List<dynamic>? ?? []);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_flask_sync',
        data['server_time']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
      _syncState = SyncState.synced;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('FULL RESTORE error: $e');
      _syncState = SyncState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Data helpers ──

  Map<String, dynamic> _patientRowToMap(Map<String, dynamic> row) {
    final createdAt = row['created_at'] as String? ?? '';
    final createdDt = DateTime.tryParse(createdAt) ?? DateTime.now();
    final syncId = row['sync_id'] as String? ?? 'P${row['id']}';
    return {
      'id': syncId,
      'name': row['full_name'],
      'dob': row['dob'] ?? '',
      'age': row['age'] ?? 0,
      'gender': row['gender'] ?? 'Not Specified',
      'blood_group': row['blood_group'] ?? 'Not Specified',
      'mobile': row['mobile_number'],
      'address': row['address'] ?? '',
      'created_at': createdDt.toIso8601String(),
      'updated_at': _resolveUpdatedAt(row),
    };
  }

  Map<String, dynamic> _opdRowToMap(Map<String, dynamic> row) {
    final createdAt = row['created_at'] as String? ?? '';
    final createdDt = DateTime.tryParse(createdAt) ?? DateTime.now();
    final visitDt = row['visit_datetime'] as String? ?? '';
    final localPatientId = row['patient_id'] as int? ?? 0;
    final patientSyncId = 'P$localPatientId';
    return {
      'id': row['opd_id']?.toString() ?? 'R${row['id']}',
      'patient_id': patientSyncId,
      'type': row['opd_type'] ?? 'consultation',
      'symptoms': row['symptoms'] ?? '',
      'diagnosis': row['diagnosis'] ?? '',
      'medicines': row['medicines'] ?? '',
      'visit_date': DateTime.tryParse(visitDt)?.toIso8601String() ?? createdDt.toIso8601String(),
      'clinical_notes': row['clinical_notes'] ?? '',
      'consultation_fee': (row['consultation_fee'] as num?)?.toString() ?? '',
      'medicine_fee': (row['medicine_fee'] as num?)?.toString() ?? '',
      'panchakarma_fee': (row['panchakarma_fee'] as num?)?.toString() ?? '',
      'total_fee': (row['total_fee'] as num?)?.toString() ?? '',
      'discount': (row['discount_value'] as num?)?.toString() ?? '',
      'discount_type': row['discount_type'] ?? '',
      'payment_mode': row['payment_mode'] ?? '',
      'charge_type': row['charge_type'] ?? '',
      'follow_up_reason': row['followup_status'] ?? '',
      'next_visit': row['next_visit_date'] ?? '',
      'blood_group': row['blood_group'] ?? '',
      'created_at': createdDt.toIso8601String(),
      'updated_at': _resolveUpdatedAt(row),
    };
  }

  Map<String, dynamic> _remotePatientToRow(Map<String, dynamic> remote, int sqliteId, String syncId) {
    return {
      'id': sqliteId,
      'sync_id': syncId,
      'full_name': remote['name']?.toString() ?? '',
      'mobile_number': remote['mobile']?.toString() ?? '',
      'gender': remote['gender']?.toString() ?? 'Not Specified',
      'dob': remote['dob']?.toString() ?? '',
      'age': int.tryParse(remote['age']?.toString() ?? '') ?? 0,
      'blood_group': remote['blood_group']?.toString() ?? 'Not Specified',
      'address': remote['address']?.toString() ?? '',
      'created_at': remote['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': remote['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _remoteOpdToRow(Map<String, dynamic> remote, int sqliteId) async {
    final remotePatientId = remote['patient_id']?.toString() ?? '';
    int localPatientId;
    try {
      final patient = await _patientRepo.getBySyncId(remotePatientId);
      localPatientId = patient?['id'] as int? ?? 0;
    } catch (_) {
      localPatientId = 0;
    }
    return {
      'id': sqliteId,
      'opd_id': remote['id']?.toString() ?? '',
      'patient_id': localPatientId,
      'visit_datetime': remote['visit_date']?.toString() ?? '',
      'opd_type': remote['type']?.toString() ?? 'consultation',
      'charge_type': remote['charge_type']?.toString() ?? '',
      'diagnosis': remote['diagnosis']?.toString() ?? '',
      'symptoms': remote['symptoms']?.toString() ?? '',
      'clinical_notes': remote['clinical_notes']?.toString() ?? '',
      'consultation_fee': double.tryParse(remote['consultation_fee']?.toString() ?? '') ?? 0.0,
      'medicine_fee': double.tryParse(remote['medicine_fee']?.toString() ?? '') ?? 0.0,
      'payment_mode': remote['payment_mode']?.toString() ?? '',
      'next_visit_date': remote['next_visit']?.toString() ?? '',
      'followup_status': remote['follow_up_reason']?.toString() ?? '',
      'discount_value': double.tryParse(remote['discount']?.toString() ?? '') ?? 0.0,
      'created_at': remote['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at': remote['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      'medicines': remote['medicines']?.toString() ?? '',
    };
  }

  String _resolveUpdatedAt(Map<String, dynamic> row) {
    final updatedAt = row['updated_at'] as String?;
    if (updatedAt != null && updatedAt.isNotEmpty) return updatedAt;
    final createdAt = row['created_at'] as String?;
    if (createdAt != null && createdAt.isNotEmpty) return createdAt;
    return DateTime.now().toIso8601String();
  }

  Future<String> _loadOrCreateDeviceId() async {
    final existing = await _deviceRegRepo.get();
    if (existing != null) return existing['device_id'] as String;
    final newId = 'DEV${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';
    await _deviceRegRepo.insert({'device_id': newId, 'device_name': '', 'clinic_id': ''});
    return newId;
  }

  String _getDeviceName() {
    try {
      return Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
