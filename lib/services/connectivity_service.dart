import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  bool _isConnectedCached = true; // Default to optimistic true until resolved

  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    // Keep cached state updated in real-time
    _connectivity.onConnectivityChanged.listen((results) {
      _isConnectedCached = results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
    });
    // Query initial state
    _connectivity.checkConnectivity().then((results) {
      _isConnectedCached = results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
    });
  }

  /// Broadcasts connection status (true = connected, false = disconnected)
  Stream<bool> get isConnected {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
    });
  }

  /// Synchronously checks the cached network connectivity status
  bool get currentStatus => _isConnectedCached;
}
