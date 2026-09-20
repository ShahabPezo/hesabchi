import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class LocalStore {
  Database? _database;

  Future<Database> get _db async {
    final current = _database;
    if (current != null) return current;
    final directory = await getApplicationDocumentsDirectory();
    final database = await openDatabase(
      path.join(directory.path, 'namayeshyar.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE snapshot (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            payload TEXT NOT NULL,
            imported_at TEXT NOT NULL
          )
        ''');
      },
    );
    _database = database;
    return database;
  }

  Future<BusinessDataset?> loadDataset() async {
    final db = await _db;
    final rows = await db.query(
      'snapshot',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final raw = rows.single['payload'] as String;
    try {
      return BusinessDataset.fromRawJson(raw);
    } on ImportValidationException {
      await clear();
      return null;
    }
  }

  Future<void> saveDataset(BusinessDataset dataset) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('snapshot', {
        'id': 1,
        'payload': dataset.rawJson,
        'imported_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> clear() async {
    final db = await _db;
    await db.delete('snapshot', where: 'id = ?', whereArgs: [1]);
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}
