import 'package:sqflite/sqflite.dart';
import './helper.dart';

List<int> paraseListInt(String str) {
  final set = <int>{};
  var items = <int>[];
  str.split(',').forEach((element) {
    try {
      var v = int.parse(element);
      if (v.isFinite) {
        if (!set.contains(v)) {
          set.add(v);
          items.add(v);
        }
      }
    } catch (_) {}
  });
  items.sort(((a, b) => a - b));
  return items;
}

/// 帳戶
class Account {
  int id;
  String url;
  String name;
  String password;
  List<int> devices;
  Account({
    required this.id,
    required this.url,
    required this.name,
    required this.password,
    required this.devices,
  });
  Map<String, dynamic> toMap() => <String, dynamic>{
        AccountHelper.columnID: id,
        AccountHelper.columnURL: url,
        AccountHelper.columnName: name,
        AccountHelper.columnPassword: password,
        AccountHelper.columnDevices: devices.join(','),
      };
  Account.fromMap(Map<String, dynamic> map)
      : id = map[AccountHelper.columnID] ?? 0,
        url = map[AccountHelper.columnURL] ?? '',
        name = map[AccountHelper.columnName] ?? '',
        password = map[AccountHelper.columnPassword] ?? '',
        devices = paraseListInt(map[AccountHelper.columnDevices]);
}

class AccountHelper extends Helper<Account>
    with Executor, HasId, HasName, ById<Account, int>, ByName<Account, String> {
  static const table = 'account';
  static const columnID = 'id';
  static const columnURL = 'url';
  static const columnName = 'name';
  static const columnPassword = 'password';
  static const columnDevices = 'devices';
  static const columns = [
    columnID,
    columnURL,
    columnName,
    columnPassword,
    columnDevices,
  ];
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS 
$table (
$columnID INTEGER PRIMARY KEY AUTOINCREMENT, 
$columnURL TEXT DEFAULT '',
$columnName TEXT DEFAULT '',
$columnPassword TEXT DEFAULT '',
$columnDevices TEXT DEFAULT ''
)''');
  }

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute("DROP TABLE IF EXISTS $table");
    }
    await onCreate(db, newVersion);
  }

  AccountHelper(Database db) : super(db);
  @override
  String get tableName => table;
  @override
  Account fromMap(Map<String, dynamic> map) => Account.fromMap(map);
  @override
  Map<String, dynamic> toMap(Account data, {bool insert = false}) {
    final m = data.toMap();
    if (insert && data.id == 0) {
      m.remove(columnID);
    }
    return m;
  }
}
