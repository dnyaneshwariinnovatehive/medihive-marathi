import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  Future<void> _trySync() async {
    if (kIsWeb) return;
    if (!_connectivityService.currentStatus) return;

    if (!_isSignedIn) {
      _isSignedIn = await _authService.isSignedIn();
    }
    if (!_isSignedIn) return;

    if (_syncState == SyncState.syncing) return;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await _driveService.syncPendingRecords();
      _syncState = SyncState.synced;
      notifyListeners();
    } catch (_) {
      _syncState = SyncState.error;
      notifyListeners();
    }
  }

  Future<bool> triggerManualSync() async {
    if (kIsWeb) return false;
    if (_syncState == SyncState.syncing) return false;

    _syncState = SyncState.syncing;
    notifyListeners();

    try {
      await _driveService.syncPendingRecords();
      _syncState = SyncState.synced;
      notifyListeners();

      await NotificationProvider.addNotificationSilently(
        'Sync Complete',
        'Backup synced to Google Drive',
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('✓ Data synced to Google Drive'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (_) {
      _syncState = SyncState.error;
      notifyListeners();
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
