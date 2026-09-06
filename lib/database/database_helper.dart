import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/blocking_period.dart';
import '../models/preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ptask.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        priority INTEGER NOT NULL,
        category TEXT NOT NULL,
        lockedStartTime TEXT,
        status TEXT NOT NULL,
        dependsOnTaskId INTEGER,
        isFlexible INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        scheduledStartTime TEXT,
        completedAt TEXT
      )
    ''');

    // Blocking periods table
    await db.execute('''
      CREATE TABLE blocking_periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        isRecurring INTEGER NOT NULL,
        recurrencePattern TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Preferences table (single row)
    await db.execute('''
      CREATE TABLE preferences (
        id INTEGER PRIMARY KEY,
        addBufferBetweenTasks INTEGER NOT NULL,
        overflowHandling TEXT NOT NULL,
        defaultTaskStartDay TEXT NOT NULL,
        defaultCategory TEXT NOT NULL,
        use24HourFormat INTEGER NOT NULL,
        defaultViewMode TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Insert default preferences
    await db.insert('preferences', Preferences.defaultPreferences().toMap());
  }

  // ========== TASK OPERATIONS ==========

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<Task?> getTask(int id) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'priority DESC, createdAt ASC');
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'priority DESC, scheduledStartTime ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> getTasksForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final maps = await db.query(
      'tasks',
      where: 'scheduledStartTime >= ? AND scheduledStartTime <= ? AND status != ?',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        'complete',
      ],
      orderBy: 'scheduledStartTime ASC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'priority DESC, createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== BLOCKING PERIOD OPERATIONS ==========

  Future<int> insertBlockingPeriod(BlockingPeriod period) async {
    final db = await database;
    return await db.insert('blocking_periods', period.toMap());
  }

  Future<BlockingPeriod?> getBlockingPeriod(int id) async {
    final db = await database;
    final maps = await db.query(
      'blocking_periods',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return BlockingPeriod.fromMap(maps.first);
  }

  Future<List<BlockingPeriod>> getAllBlockingPeriods() async {
    final db = await database;
    final maps = await db.query('blocking_periods', orderBy: 'startTime ASC');
    return maps.map((map) => BlockingPeriod.fromMap(map)).toList();
  }

  Future<List<BlockingPeriod>> getBlockingPeriodsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final maps = await db.query(
      'blocking_periods',
      where: '(startTime >= ? AND startTime <= ?) OR isRecurring = 1',
      whereArgs: [
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
    );
    return maps.map((map) => BlockingPeriod.fromMap(map)).toList();
  }

  Future<int> updateBlockingPeriod(BlockingPeriod period) async {
    final db = await database;
    return await db.update(
      'blocking_periods',
      period.toMap(),
      where: 'id = ?',
      whereArgs: [period.id],
    );
  }

  Future<int> deleteBlockingPeriod(int id) async {
    final db = await database;
    return await db.delete(
      'blocking_periods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== PREFERENCES OPERATIONS ==========

  Future<Preferences> getPreferences() async {
    final db = await database;
    final maps = await db.query('preferences', limit: 1);

    if (maps.isEmpty) {
      // Insert default if not exists
      final defaultPrefs = Preferences.defaultPreferences();
      await db.insert('preferences', defaultPrefs.toMap());
      return defaultPrefs;
    }

    return Preferences.fromMap(maps.first);
  }

  Future<int> updatePreferences(Preferences preferences) async {
    final db = await database;
    return await db.update(
      'preferences',
      preferences.toMap(),
      where: 'id = ?',
      whereArgs: [preferences.id ?? 1],
    );
  }

  // ========== UTILITY ==========

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Returns the full file-system path to the app database file.
  ///
  /// This is provided as a safe debug helper only. Do NOT use this to
  /// perform destructive operations in production.
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ptask.db');
    return path;
  }

  // Delete database (for testing/reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ptask.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
