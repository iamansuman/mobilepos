import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';

enum DBTables { inventory, sales }

class PoSDatabase {
  static const _dbName = "mobileposdata.db";
  static const _dbVersion = 1;
  static const Map<DBTables, String> _tables = {DBTables.inventory: 'inventory', DBTables.sales: 'sales'};

  //singleton class
  PoSDatabase._init();
  static final PoSDatabase instance = PoSDatabase._init();

  static sql.Database? _database;
  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB(_dbName);
    return _database!;
  }

  Future _createDB(sql.Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.sales]}(
      receipt_number TEXT PRIMARY KEY,
      time_of_sale INTEGER,
      total_amount REAL,
      sale_items BLOB
    );
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.inventory]}(
      barcode INTEGER PRIMARY KEY,
      itemname TEXT,
      price REAL,
      single_unit_quantity TEXT,
      stock_quantity INTEGER,
      last_modified INTEGER
    );
    ''');
  }

  Future<sql.Database> _initializeDB(String fileName) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, fileName);
    return await sql.openDatabase(path, version: _dbVersion, onCreate: _createDB);
  }
}