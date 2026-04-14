import 'dart:async';
import 'dart:convert';
import 'sqlite_service.dart';
import 'firebase_service.dart';
import 'connectivity_service.dart';
import '../models/expense.dart';

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

    try {
      await _connectivityService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => print('Connectivity init timed out'),
      );
    } catch (e) {
      print('Connectivity init failed: $e');
    }

    try {
      await _firebaseService.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () => print('Firebase init timed out'),
      );
    } catch (e) {
      print('Firebase init failed: $e');
    }

    if (isOnline) {
      syncWithCloud().catchError((e) => print('Initial sync failed: $e'));
    }

    _connectivitySubscription = _connectivityService.onStatusChanged.listen((
      status,
    ) {
      if (status == NetworkStatus.online) {
        syncWithCloud().catchError((e) => print('Background sync failed: $e'));
      }
    });

    _isInitialized = true;
  }

  Future<void> syncWithCloud() async {
    try {
      _syncController.add(SyncStatus.syncing);

      final cloudProjects = await _firebaseService
          .fetchProjectsFromFirebase()
          .timeout(const Duration(seconds: 5));

      if (cloudProjects.isNotEmpty) {
        await _sqliteService.clearAllData();
        await _sqliteService.insertProjectsBatch(cloudProjects);
      }

      await processSyncQueue();

      _syncController.add(SyncStatus.synced);
    } on TimeoutException {
      print('SYNC TIMEOUT: Cloud sync exceeded 5s, continuing offline');
      _syncController.add(SyncStatus.offline);
    } catch (e, stackTrace) {
      print('SYNC ERROR: $e');
      print(stackTrace);
      _syncController.add(SyncStatus.error);
    }
  }

  Future<void> processSyncQueue() async {
    if (!isOnline) {
      print('OFFLINE: Cannot process sync queue, device is offline');
      _syncController.add(SyncStatus.offline);
      return;
    }

    try {
      final queueItems = await _sqliteService.getQueueItems();
      if (queueItems.isEmpty) {
        print('Sync queue is empty');
        return;
      }

      print('Processing ${queueItems.length} queue items...');

      for (final item in queueItems) {
        if (item.id == null) continue;

        try {
          if (item.actionType == 'CREATE_EXPENSE') {
            final expenseData =
                jsonDecode(item.payload) as Map<String, dynamic>;
            final expense = Expense.fromJson(expenseData);
            await _firebaseService.pushExpenseToFirebase(expense);
          }

          await _sqliteService.removeFromQueue(item.id!);
          print('Processed queue item: ${item.id} - ${item.actionType}');
        } catch (e) {
          final newRetryCount = item.retryCount + 1;
          if (newRetryCount >= 3) {
            print('Queue item ${item.id} failed after 3 retries, removing: $e');
            await _sqliteService.removeFromQueue(item.id!);
          } else {
            await _sqliteService.updateQueueItemRetry(
              item.id!,
              newRetryCount,
              e.toString(),
            );
            print('Queue item ${item.id} failed, retry ${newRetryCount}: $e');
          }
        }
      }

      _syncController.add(SyncStatus.synced);
    } catch (e) {
      print('SYNC QUEUE ERROR: $e');
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
