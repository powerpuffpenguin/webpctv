import 'package:sqflite/sqlite_api.dart';

class History {
  String url;
  String name;
  int at;

  int device;
  String root;
  String path;
  History({
    required this.name,
    required this.device,
    required this.root,
    required this.path,
  })  : at = DateTime.now().millisecondsSinceEpoch,
        url = Uri(queryParameters: <String, dynamic>{
          'slave_id': device.toString(),
          'root': root,
          'path': path,
        }).query;
  Map<String, dynamic> toMap() => <String, dynamic>{
        HistoryHelper.columnURL: url,
        HistoryHelper.columnName: name,
        HistoryHelper.columnAt: at,
        HistoryHelper.columnDevice: device,
        HistoryHelper.columnRoot: root,
        HistoryHelper.columnPath: path,
      };
  History.fromMap(Map<String, dynamic> map)
      : url = map[HistoryHelper.columnURL],
        name = map[HistoryHelper.columnName],
        at = map[HistoryHelper.columnAt],
        device = map[HistoryHelper.columnDevice],
        root = map[HistoryHelper.columnRoot],
        path = map[HistoryHelper.columnPath];
}

class HistoryHelper {
  static const table = 'playhistory';
  static const columnURL = 'url';
  static const columnName = 'name';
  static const columnAt = 'at';
  static const columnDevice = 'device';
  static const columnRoot = 'root';
  static const columnPath = 'path';

  static const columns = [
    columnURL,
    columnName,
    columnAt,
    columnDevice,
    columnRoot,
    columnPath,
  ];
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS 
$table (
$columnURL TEXT PRIMARY KEY DEFAULT '', 
$columnName TEXT DEFAULT '',
$columnAt INTEGER DEFAULT 0,
$columnDevice INTEGER DEFAULT 0,
$columnRoot TEXT DEFAULT '',
$columnPath TEXT DEFAULT ''
)''');

    await db.execute('''CREATE INDEX IF NOT EXISTS 
index_${columnAt}_of_$table
ON $table ($columnAt);
''');
  }

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute("DROP TABLE IF EXISTS $table");
    }
    await onCreate(db, newVersion);
  }

  final Database db;
  HistoryHelper(this.db);

  Future<History?> get(int device, String root, String path) async {
    final url = Uri(queryParameters: <String, dynamic>{
      'slave_id': device.toString(),
      'root': root,
      'path': path,
    }).query;
    final list = await db.query(
      table,
      columns: columns,
      where: '$columnURL = ?',
      whereArgs: [url],
      limit: 1,
    );
    return list.isEmpty ? null : History.fromMap(list.first);
  }

  Future<void> put(History history) async {
    return db.transaction((txn) async {
      await txn.insert(
        table,
        history.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final list = await txn.query(
        table,
        orderBy: '$columnAt DESC',
        limit: 1,
        offset: 100,
      );
      if (list.isEmpty) {
        return;
      }
      final h = History.fromMap(list.first);
      await txn.delete(
        table,
        where: '$columnAt < ?',
        whereArgs: [h.at],
      );
    });
  }

  Future<Iterable<History>?> list() async {
    final list =
        await db.query(table, columns: columns, orderBy: "$columnAt DESC");
    return list.isEmpty ? null : list.map((e) => History.fromMap(e));
  }

  Future<int> clear() {
    return db.delete(table);
  }
}
