import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:mobilepos/data_structure.dart';

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
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.inventory]}(
      barcode INTEGER PRIMARY KEY,
      itemname TEXT,
      price REAL,
      single_unit_quantity TEXT,
      stock_quantity INTEGER,
      last_modified INTEGER
    );
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.sales]}(
      receipt_number TEXT PRIMARY KEY,
      time_of_sale INTEGER,
      total_amount REAL,
      sale_items BLOB
    );
    ''');
  }

  Future<sql.Database> _initializeDB(String fileName) async {
    final dbPath = await sql.getDatabasesPath();
    final path = join(dbPath, fileName);
    return await sql.openDatabase(path, version: _dbVersion, onCreate: _createDB);
  }

  //Inventory
  static Future<int> addItemToInventory(Item item) async {
    final db = await instance.database;
    Map<String, dynamic> dbitem = item.toMap();
    dbitem['last_modified'] = DateTime.now().millisecondsSinceEpoch;
    return await db.insert(
      _tables[DBTables.inventory]!,
      dbitem,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<bool> itemExistsWithBarcode(int barcode) async {
    final db = await instance.database;
    final result = await db.query(
      _tables[DBTables.inventory]!,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<Item?> getItemInfoFromInventory(int barcode) async {
    final db = await instance.database;
    final result = await db.query(_tables[DBTables.inventory]!,
        where: 'barcode = ?', whereArgs: [barcode], orderBy: 'last_modified DESC', limit: 1);
    return (result.isNotEmpty) ? Item.fromMap(result.first) : null;
  }

  static Future<List<Item>?> getItemsFromInventory() async {
    final db = await instance.database;
    final result = await db.query(_tables[DBTables.inventory]!, orderBy: 'last_modified DESC');
    if (result.isNotEmpty) {
      List<Item> inventoryItems = [];
      for (var item in result) {
        inventoryItems.add(Item.fromMap(item));
      }
      return inventoryItems;
    } else {
      return null;
    }
  }

  static void updateItemQuantityInInventory(int barcode, int newQuantity) async {
    final db = await instance.database;
    db.update(
      _tables[DBTables.inventory]!,
      {'stock_quantity': newQuantity, 'last_modified': DateTime.now().millisecondsSinceEpoch},
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  static Future<int> removeItemFromInventory(int barcode) async {
    final db = await instance.database;
    return await db.delete(_tables[DBTables.inventory]!, where: 'barcode = ?', whereArgs: [barcode]);
  }

  //Sales
}
