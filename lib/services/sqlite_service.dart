import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';
import '../models/sync_queue_item.dart';

class SqliteService {
  static final SqliteService instance = SqliteService._init();
  static Database? _database;

  SqliteService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('DROP TABLE IF EXISTS favorites');
          await db.execute('DROP TABLE IF EXISTS sync_queue');
          await db.execute('DROP TABLE IF EXISTS expenses');
          await db.execute('DROP TABLE IF EXISTS projects');
          await db.execute('DROP TABLE IF EXISTS accounts');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Add "IF NOT EXISTS" to every table creation
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        displayName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        budget REAL NOT NULL,
        spent REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        title TEXT,
        description TEXT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        claimant TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        location TEXT,
        date TEXT NOT NULL,
        imageUrl TEXT,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actionType TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retryCount INTEGER NOT NULL DEFAULT 0,
        errorMessage TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId TEXT NOT NULL UNIQUE,
        accountUid TEXT NOT NULL,
        FOREIGN KEY (accountUid) REFERENCES accounts (uid) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_expenses_projectId ON expenses(projectId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorites_projectId ON favorites(projectId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorites_accountUid ON favorites(accountUid)',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> insertProject(Project project) async {
    final db = await database;
    final projectMap = Map<String, dynamic>.from(project.toMap());
    projectMap.remove('isFavorite');
    projectMap.remove('expenses');
    await db.insert(
      'projects',
      projectMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (final expense in project.expenses) {
      await insertExpense(expense);
    }
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final projectMaps = await db.query('projects');
    final projects = <Project>[];

    for (final map in projectMaps) {
      final expenses = await getExpensesByProjectId(map['id'] as String);
      final isFavorite = await isProjectFavorite(map['id'] as String);
      projects.add(
        Project.fromMap(map, expenses: expenses, isFavorite: isFavorite),
      );
    }
    return projects;
  }

  Future<Project?> getProjectById(String id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final expenses = await getExpensesByProjectId(id);
    final isFavorite = await isProjectFavorite(id);
    return Project.fromMap(
      maps.first,
      expenses: expenses,
      isFavorite: isFavorite,
    );
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    final projectMap = Map<String, dynamic>.from(project.toMap());
    projectMap.remove('isFavorite');
    projectMap.remove('expenses');
    await db.update(
      'projects',
      projectMap,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    final map = Map<String, dynamic>.from(expense.toMap());
    map.remove('syncStatus');
    await db.insert(
      'expenses',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _updateProjectSpent(expense.projectId);
  }

  Future<void> insertExpenseAndQueue(Expense expense) async {
    await insertExpense(expense);
    final queueItem = SyncQueueItem(
      actionType: 'CREATE_EXPENSE',
      payload: jsonEncode(expense.toJson()),
      timestamp: DateTime.now(),
    );
    await enqueueAction(queueItem);
  }

  Future<List<Expense>> getExpensesByProjectId(String projectId) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    final expenseMap = Map<String, dynamic>.from(expense.toMap());
    expenseMap.remove('syncStatus');
    await db.update(
      'expenses',
      expenseMap,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await _updateProjectSpent(expense.projectId);
  }

  Future<void> deleteExpense(String id, String projectId) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    await _updateProjectSpent(projectId);
  }

  Future<void> insertExpenseWithSyncStatus(
    Expense expense, {
    int syncStatus = 0,
  }) async {
    final db = await database;
    final map = expense.toMap();
    map['syncStatus'] = syncStatus;
    await db.insert(
      'expenses',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _updateProjectSpent(expense.projectId);
  }

  Future<void> enqueueAction(SyncQueueItem item) async {
    final db = await database;
    await db.insert('sync_queue', item.toMap()..remove('id'));
  }

  Future<List<SyncQueueItem>> getQueueItems() async {
    final db = await database;
    final maps = await db.query('sync_queue', orderBy: 'timestamp ASC');
    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  Future<void> removeFromQueue(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateQueueItemRetry(
    int id,
    int retryCount,
    String? errorMessage,
  ) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'retryCount': retryCount, 'errorMessage': errorMessage},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> _updateProjectSpent(String projectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE projectId = ?',
      [projectId],
    );
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    await db.update(
      'projects',
      {'spent': total},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  Future<void> addFavorite(String projectId, String accountUid) async {
    final db = await database;
    await db.insert('favorites', {
      'projectId': projectId,
      'accountUid': accountUid,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(String projectId, String accountUid) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'projectId = ? AND accountUid = ?',
      whereArgs: [projectId, accountUid],
    );
  }

  Future<bool> isProjectFavorite(String projectId, {String? accountUid}) async {
    final db = await database;
    final query = accountUid != null
        ? 'projectId = ? AND accountUid = ?'
        : 'projectId = ?';
    final args = accountUid != null ? [projectId, accountUid] : [projectId];
    final result = await db.query('favorites', where: query, whereArgs: args);
    return result.isNotEmpty;
  }

  Future<List<String>> getFavoriteProjectIds(String accountUid) async {
    final db = await database;
    final maps = await db.query(
      'favorites',
      columns: ['projectId'],
      where: 'accountUid = ?',
      whereArgs: [accountUid],
    );
    return maps.map((map) => map['projectId'] as String).toList();
  }

  Future<void> saveAccount(Account account) async {
    final db = await database;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Account?> getAccount(String uid) async {
    final db = await database;
    final maps = await db.query('accounts', where: 'uid = ?', whereArgs: [uid]);
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<void> deleteAccount(String uid) async {
    final db = await database;
    await db.delete('accounts', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('favorites');
    await db.delete('expenses');
    await db.delete('projects');
    await db.delete('accounts');
  }

  Future<void> insertProjectsBatch(List<Project> projects) async {
    final db = await database;
    final batch = db.batch();
    for (final project in projects) {
      final projectMap = Map<String, dynamic>.from(project.toMap());
      projectMap.remove('isFavorite');
      projectMap.remove('expenses');
      batch.insert(
        'projects',
        projectMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final expense in project.expenses) {
        final expenseMap = Map<String, dynamic>.from(expense.toMap());
        expenseMap.remove('syncStatus');
        batch.insert(
          'expenses',
          expenseMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
