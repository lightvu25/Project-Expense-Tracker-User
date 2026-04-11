import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._init();
  final Connectivity _connectivity = Connectivity();
  
  final StreamController<NetworkStatus> _statusController = StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService._init();

  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;
  NetworkStatus _currentStatus = NetworkStatus.offline;

  NetworkStatus get currentStatus => _currentStatus;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final newStatus = results.contains(ConnectivityResult.none) 
        ? NetworkStatus.offline 
        : NetworkStatus.online;
    
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<bool> isOffline() async {
    return await isOnline() == false;
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}