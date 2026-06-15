import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'connectivity_service.dart';
import 'google_auth_service.dart';
import 'google_drive_sync_service.dart';
import 'excel_export_service.dart';
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

// ─── Background Workmanager Callback ──────────────────────────

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();

      // Register Hive adapters if needed
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PatientModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(OPDRecordModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(AppointmentModelAdapter());
      }

      // Open required boxes
      await Hive.openBox<PatientModel>('patients');
      await Hive.openBox<OPDRecordModel>('opd_records');
      await Hive.openBox<AppointmentModel>('appointments');

      final syncService = GoogleDriveSyncService();
      final totalCount = Hive.box<PatientModel>('patients').length +
          Hive.box<OPDRecordModel>('opd_records').length +
          Hive.box<AppointmentModel>('appointments').length;
      final excelBytes = await ExcelExportService().generateExcelFile();
      final fileName = ExcelExportService().generateFileName('Shree_Clinic', recordCount: totalCount);

      await syncService.uploadBackup(excelBytes, fileName);
      return Future.value(true);
    } catch (_) {
      return Future.value(false);
    }
  });
}

// ─── Sync Manager ──────────────────────────────────────────────

class SyncManager extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  // Lazy — only created on non-web platforms
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
  StreamSubscription<bool>? _connectivitySubscription;

  SyncState get syncState => _syncState;
  bool get isSyncing => _syncState == SyncState.syncing;

  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;

  SyncManager._internal() {
    // Skip sync-related initialization entirely on web
    if (kIsWeb) return;

    _initializeState();

    // Monitor connectivity status
    _connectivitySubscription = _connectivityService.isConnected.listen((connected) {
      if (!connected) {
        _syncState = SyncState.offline;
        notifyListeners();
      } else {
        // Restore: trigger 3s debounced silent sync
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 3), () {
          _autoSyncOnRestored();
        });
      }
    });
  }

  void _initializeState() {
    final connected = _connectivityService.currentStatus;
    if (!connected) {
      _syncState = SyncState.offline;
    } else {
      final unsynced = getUnsyncedCount();
      _syncState = unsynced > 0 ? SyncState.error : SyncState.synced;
    }
    notifyListeners();
  }

  /// Calculates number of currently unsynced records
  int getUnsyncedCount() {
    try {
      final patientsBox = Hive.box<PatientModel>('patients');
      final opdBox = Hive.box<OPDRecordModel>('opd_records');
      final apptBox = Hive.box<AppointmentModel>('appointments');

      final pendingPatients = patientsBox.values.where((p) => !p.isSynced).length;
      final pendingOpd = opdBox.values.where((r) => !r.isSynced).length;
      final pendingAppt = apptBox.values.where((a) => !a.isSynced).length;

      return pendingPatients + pendingOpd + pendingAppt;
    } catch (_) {
      return 0;
    }
  }

  /// Silent automatic backup trigger when network recovers
  Future<void> _autoSyncOnRestored() async {
    if (kIsWeb) return;
    final signedIn = await _authService.isSignedIn();
    if (!signedIn) return;

    final unsynced = getUnsyncedCount();
    if (unsynced == 0) {
      _syncState = SyncState.synced;
      notifyListeners();
      return;
    }

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

      // Show a subtle green success notification
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text('✓ Data synced to Google Drive'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      _syncState = SyncState.error;
      notifyListeners();
    }
  }

  /// Explicitly trigger sync from settings
  Future<bool> triggerManualSync() async {
    if (kIsWeb) return false;
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

      return true;
    } catch (_) {
      _syncState = SyncState.error;
      notifyListeners();
      return false;
    }
  }

  /// Calculates duration until next occurrence of selected backup hour
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

  /// Registers daily backup task with Workmanager
  Future<void> scheduleDailyBackup(TimeOfDay time) async {
    if (kIsWeb) return; // Workmanager not supported on web
    final initialDelay = calculateInitialDelay(time);

    await Workmanager().cancelAll();
    await Workmanager().registerPeriodicTask(
      'medihive_daily_backup',
      'medihive_backup_task',
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
