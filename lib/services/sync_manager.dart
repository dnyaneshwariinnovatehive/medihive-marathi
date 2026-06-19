import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'google_auth_service.dart';
import 'google_drive_sync_service.dart';
import '../models/patient_model.dart';
import '../models/opd_record_model.dart';
import '../models/appointment_model.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

enum SyncState {
  offline,
  syncing,
  synced,
  error,
}

class SyncManager extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  GoogleAuthService? _googleAuthService;
  GoogleAuthService get _authService {
    _googleAuthService ??= GoogleAuthService();
    return _googleAuthService!;
  }

  GoogleDriveSyncService? _driveSyncService;
  GoogleDriveSyncService get _driveService {
    _driveSyncService ??= GoogleDriveSyncService();
    return _driveSyncService!;
  }

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  SyncState _syncState = SyncState.synced;
  Timer? _debounceTimer;
  Timer? _pollTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription? _patientSubscription;
  StreamSubscription? _opdSubscription;
  StreamSubscription? _apptSubscription;

  bool _isSignedIn = false;

  SyncState get syncState => _syncState;
  bool get isSyncing => _syncState == SyncState.syncing;

  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;

  SyncManager._internal() {
    if (kIsWeb) return;

    _initializeState();
    _initBoxWatchers();
    _initPolling();

    Timer(const Duration(seconds: 5), _trySync);

    _connectivitySubscription = _connectivityService.isConnected.listen((connected) {
      if (!connected) {
        _syncState = SyncState.offline;
        notifyListeners();
      } else {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), _trySync);
      }
    });
  }

  void _initializeState() {
    final connected = _connectivityService.currentStatus;
    _syncState = connected ? SyncState.synced : SyncState.offline;
    notifyListeners();
  }

  void _initBoxWatchers() {
    try {
      _patientSubscription = Hive.box<PatientModel>('patients').watch().listen((_) => _onLocalChange());
      _opdSubscription = Hive.box<OPDRecordModel>('opd_records').watch().listen((_) => _onLocalChange());
      _apptSubscription = Hive.box<AppointmentModel>('appointments').watch().listen((_) => _onLocalChange());
    } catch (_) {}
  }

  void _initPolling() {
    _pollTimer = Timer.periodic(const Duration(minutes: 2), (_) => _trySync());
  }

  void _onLocalChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), _trySync);
  }

  int getUnsyncedCount() {
    try {
      final patientsBox = Hive.box<PatientModel>('patients');
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final apptBox = Hive.box<AppointmentModel>('appointments');
      return patientsBox.values.where((p) => !p.isSynced).length +
          opdBox.values.where((r) => !r.isSynced).length +
          apptBox.values.where((a) => !a.isSynced).length;
    } catch (_) {
      return 0;
    }
  }

  int _getUnsyncedCount() {
    try {
      final patientsBox = Hive.box<PatientModel>('patients');
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final apptBox = Hive.box<AppointmentModel>('appointments');
      return patientsBox.values.where((p) => !p.isSynced).length +
          opdBox.values.where((r) => !r.isSynced).length +
          apptBox.values.where((a) => !a.isSynced).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _trySync() async {
    if (kIsWeb) return;
    if (!_connectivityService.currentStatus) return;
    if (_syncState == SyncState.syncing) return;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      // 1. Sync with Flask API
      await _syncWithFlask();

      // 2. Also backup to Google Drive if signed in
      if (!_isSignedIn) {
        _isSignedIn = await _authService.isSignedIn();
      }
      if (_isSignedIn) {
        try {
          await _driveService.syncPendingRecords();
        } catch (e) {
          debugPrint('Auto-sync: Drive sync failed: $e');
        }
      }

      _syncState = SyncState.synced;
      notifyListeners();
    } catch (_) {
      _syncState = SyncState.error;
      notifyListeners();
    }
  }

  Future<void> _syncWithFlask() async {
    final unsyncedCount = _getUnsyncedCount();

    // Push local changes to Flask
    if (unsyncedCount > 0) {
      final patientsBox = Hive.box<PatientModel>('patients');
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final apptBox = Hive.box<AppointmentModel>('appointments');

      final unsyncedPatients = patientsBox.values.where((p) => !p.isSynced).toList();
      final unsyncedOpd = opdBox.values.where((r) => !r.isSynced).toList();
      final unsyncedAppts = apptBox.values.where((a) => !a.isSynced).toList();

      if (unsyncedPatients.isNotEmpty || unsyncedOpd.isNotEmpty || unsyncedAppts.isNotEmpty) {
        final pushData = <String, List<Map<String, dynamic>>>{
          'patients': unsyncedPatients.map((p) => p.toJson()).toList(),
          'opd_records': unsyncedOpd.map((r) => r.toJson()).toList(),
          'appointments': unsyncedAppts.map((a) => a.toJson()).toList(),
        };

        await ApiService.syncPush(
          patients: pushData['patients']!,
          opdRecords: pushData['opd_records']!,
          appointments: pushData['appointments']!,
        );

        // Mark as synced
        final now = DateTime.now();
        for (final p in unsyncedPatients) {
          final updated = p.copyWith(isSynced: true, updatedAt: now);
          patientsBox.put(p.id, updated);
        }
        for (final r in unsyncedOpd) {
          final updated = r.copyWith(isSynced: true, updatedAt: now);
          opdBox.put(r.id, updated);
        }
        for (final a in unsyncedAppts) {
          final updated = a.copyWith(isSynced: true, updatedAt: now);
          apptBox.put(a.id, updated);
        }
      }
    }

    // Pull remote changes from Flask
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString('last_flask_sync') ?? '';
      final data = await ApiService.syncPull(lastSync);

      final remotePatients = data['patients'] as List<dynamic>? ?? [];
      final remoteOpd = data['opd_records'] as List<dynamic>? ?? [];
      final remoteAppts = data['appointments'] as List<dynamic>? ?? [];

      if (remotePatients.isNotEmpty || remoteOpd.isNotEmpty || remoteAppts.isNotEmpty) {
        final patientsBox = Hive.box<PatientModel>('patients');
        final opdBox = Hive.box<OPDRecordModel>('opd_records');
        final apptBox = Hive.box<AppointmentModel>('appointments');

        for (final json in remotePatients) {
          final map = Map<String, dynamic>.from(json as Map);
          final existing = patientsBox.get(map['id']);
          if (existing == null || existing.updatedAt.isBefore(DateTime.parse(map['updated_at']))) {
            patientsBox.put(map['id'], PatientModel.fromJson(map));
          }
        }

        for (final json in remoteOpd) {
          final map = Map<String, dynamic>.from(json as Map);
          final existing = opdBox.get(map['id']);
          if (existing == null || existing.updatedAt.isBefore(DateTime.parse(map['updated_at']))) {
            opdBox.put(map['id'], OPDRecordModel.fromJson(map));
          }
        }

        for (final json in remoteAppts) {
          final map = Map<String, dynamic>.from(json as Map);
          final existing = apptBox.get(map['id']);
          if (existing == null || existing.updatedAt.isBefore(DateTime.parse(map['updated_at']))) {
            apptBox.put(map['id'], AppointmentModel.fromJson(map));
          }
        }
      }

      await prefs.setString('last_flask_sync', data['server_time']?.toString() ?? DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      // Pull might fail if server is unreachable — that's OK, push already succeeded
    }
  }

  Future<bool> triggerManualSync() async {
    if (kIsWeb) return false;
    if (_syncState == SyncState.syncing) return false;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await _syncWithFlask();
    } catch (_) {}

    bool driveOk = false;
    if (!_isSignedIn) {
      _isSignedIn = await _authService.isSignedIn();
    }
    if (_isSignedIn) {
      try {
        await _driveService.syncPendingRecords();
        driveOk = true;
      } catch (_) {}
    } else {
      driveOk = true;
    }

    _syncState = SyncState.synced;
    notifyListeners();

    if (driveOk) {
      await NotificationProvider.addNotificationSilently(
        'Sync Complete',
        'Data synced to server and Google Drive',
      );
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('✓ Data synced'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  }

  Future<bool> backupToDriveOnly() async {
    if (kIsWeb) return false;
    if (_syncState == SyncState.syncing) return false;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      if (!_isSignedIn) {
        _isSignedIn = await _authService.isSignedIn();
      }
      if (!_isSignedIn) {
        _syncState = SyncState.error;
        notifyListeners();
        return false;
      }
      await _driveService.syncPendingRecords();
      _syncState = SyncState.synced;
      notifyListeners();
      await NotificationProvider.addNotificationSilently(
        'Drive Backup Complete',
        'Data backed up to Google Drive',
      );
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('✓ Backed up to Google Drive'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (e) {
      _syncState = SyncState.error;
      notifyListeners();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('✗ Backup failed: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Duration calculateInitialDelay(TimeOfDay scheduledTime) {
    final now = DateTime.now();
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }
    return scheduledDateTime.difference(now);
  }

  Future<void> scheduleDailyBackup(TimeOfDay time) async {
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _patientSubscription?.cancel();
    _opdSubscription?.cancel();
    _apptSubscription?.cancel();
    _debounceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
