import 'dart:async';
import 'sqlite_service.dart';
import 'firebase_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();

  final SqliteService _sqliteService = SqliteService.instance;
  final FirebaseService _firebaseService = FirebaseService.instance;
  final ConnectivityService _connectivityService = ConnectivityService.instance;

  final StreamController<SyncStatus> _syncController =
      StreamController<SyncStatus>.broadcast();
  StreamSubscription? _connectivitySubscription;

  bool _isInitialized = false;

  SyncService._init();

  Stream<SyncStatus> get onSyncStatusChanged => _syncController.stream;
  bool get isOnline =>
      _connectivityService.currentStatus == NetworkStatus.online;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _connectivityService.initialize();
    await _firebaseService.initialize();

    // Check connectivity and sync if online
    await syncWithCloud();

    _connectivitySubscription = _connectivityService.onStatusChanged.listen((
      status,
    ) {
      if (status == NetworkStatus.online) {
        syncWithCloud();
      }
    });

    _isInitialized = true;
  }

  Future<void> syncWithCloud() async {
    try {
      _syncController.add(SyncStatus.syncing);

      final cloudProjects = await _firebaseService.fetchProjectsFromFirebase();

      if (cloudProjects.isNotEmpty) {
        await _sqliteService.clearAllData();
        await _sqliteService.insertProjectsBatch(cloudProjects);
      }

      _syncController.add(SyncStatus.synced);
    } catch (e) {
      print('SYNC FATAL ERROR: $e');
      _syncController.add(SyncStatus.error);
    }
  }

  Future<void> toggleFavorite(String projectId) async {
    final isFavorite = await _sqliteService.isProjectFavorite(projectId);

    if (isFavorite) {
      await _sqliteService.removeFavorite(projectId, 'local');
    } else {
      await _sqliteService.addFavorite(projectId, 'local');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}

enum SyncStatus { idle, syncing, synced, pending, offline, error }
