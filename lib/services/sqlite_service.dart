import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

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

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        displayName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
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
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId TEXT NOT NULL UNIQUE,
        accountUid TEXT NOT NULL,
        FOREIGN KEY (accountUid) REFERENCES accounts (uid) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_projectId ON expenses(projectId)',
    );
    await db.execute(
      'CREATE INDEX idx_favorites_projectId ON favorites(projectId)',
    );
    await db.execute(
      'CREATE INDEX idx_favorites_accountUid ON favorites(accountUid)',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toMap(),
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
    await db.update(
      'projects',
      project.toMap(),
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
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _updateProjectSpent(expense.projectId);
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
    await db.update(
      'expenses',
      expense.toMap(),
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
      batch.insert(
        'projects',
        project.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final expense in project.expenses) {
        batch.insert(
          'expenses',
          expense.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
