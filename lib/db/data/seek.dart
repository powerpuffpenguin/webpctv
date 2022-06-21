import 'package:sqflite/sqlite_api.dart';

class Seek {
  String url;
  Duration duration;
  int at;
  String name;
  Seek({
    required this.url,
    required this.duration,
    required this.name,
  }) : at = DateTime.now().millisecondsSinceEpoch;
  Map<String, dynamic> toMap() => <String, dynamic>{
        SeekHelper.columnURL: url,
        SeekHelper.columnDuration: duration.inMilliseconds,
        SeekHelper.columnAt: at,
        SeekHelper.columnName: name,
      };
  Seek.fromMap(Map<String, dynamic> map)
      : url = map[SeekHelper.columnURL],
        duration = Duration(milliseconds: map[SeekHelper.columnDuration]),
        at = map[SeekHelper.columnAt],
        name = map[SeekHelper.columnName];
}

class SeekHelper {
  static const table = 'playseek';
  static const columnURL = 'url';
  static const columnDuration = 'duration';
  static const columnAt = 'at';
  static const columnName = 'name';
  static const columns = [
    columnURL,
    columnDuration,
    columnAt,
    columnName,
  ];
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS 
$table (
$columnURL TEXT PRIMARY KEY, 
$columnDuration INTEGER DEFAULT 0,
$columnAt INTEGER DEFAULT 0,
$columnName TEXT DEFAULT ''
)''');
  }

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      await db.execute("DROP TABLE IF EXISTS $table");
    }
    await onCreate(db, newVersion);
  }

  final Database db;
  SeekHelper(this.db);
  Future<Duration?> get(String url, String name) async {
    final list = await db.query(
      table,
      columns: columns,
      where: '$columnURL = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (list.isEmpty) {
      return null;
    }
    final data = Seek.fromMap(list.first);
    return data.name == name ? data.duration : null;
  }

  Future<void> put(String url, String name, Duration duration) {
    return db.transaction((txn) async {
      await txn.insert(
        table,
        Seek(url: url, duration: duration, name: name).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final list = await txn.query(
        table,
        orderBy: '$columnAt DESC',
        limit: 1,
        offset: 1000,
      );
      if (list.isEmpty) {
        return;
      }
      final h = Seek.fromMap(list.first);
      await txn.delete(
        table,
        where: '$columnAt < ?',
        whereArgs: [h.at],
      );
    });
  }

  Future<int> clear() {
    return db.delete(table);
  }
}
