import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart';
import 'package:mobilepos/data_structure.dart';

enum DBTables { inventory, sales, saleitems }

class PoSDatabase {
  static const _dbName = "mobileposdata.db";
  static const _dbVersion = 1;
  static const Map<DBTables, String> _tables = {
    DBTables.inventory: 'inventory',
    DBTables.sales: 'sales',
    DBTables.saleitems: 'saleitems',
  };

  //singleton class
  PoSDatabase._init();
  static final PoSDatabase instance = PoSDatabase._init();

  static sql.Database? _database;
  Future<sql.Database> get database async {
    if (_database == null || (await _database!.getVersion()) != _dbVersion) _database = await _initializeDB(_dbName);
    return _database!;
  }

  Future _createDB(sql.Database db, int version) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.inventory]}(
      barcode TEXT PRIMARY KEY,
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

    await db.execute('''   
    CREATE TABLE IF NOT EXISTS ${_tables[DBTables.saleitems]}(
      receipt_number TEXT,
      barcode TEXT,
      itemname TEXT,
      price REAL,
      single_unit_quantity TEXT,
      quantity_purchased INTEGER
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

  static Future<bool> itemExistsWithBarcode(String barcode) async {
    final db = await instance.database;
    final result = await db.query(
      _tables[DBTables.inventory]!,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<Item?> getItemInfoFromInventory(String barcode) async {
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

  static void updateItemQuantityInInventory(String barcode, int newQuantity) async {
    final db = await instance.database;
    await db.update(
      _tables[DBTables.inventory]!,
      {'stock_quantity': newQuantity, 'last_modified': DateTime.now().millisecondsSinceEpoch},
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
  }

  static Future<int> removeItemFromInventory(String barcode) async {
    final db = await instance.database;
    return await db.delete(_tables[DBTables.inventory]!, where: 'barcode = ?', whereArgs: [barcode]);
  }

  //Sales
  static Future<int?> processSale(Sale sale) async {
    final db = await instance.database;
    final List<Item> saleItems = sale.saleItems.values.toList();

    for (var saleItem in saleItems) {
      final query = await db.query(
        _tables[DBTables.inventory]!,
        where: 'barcode = ? AND stock_quantity >= ?',
        whereArgs: [saleItem.barcode, saleItem.quantity],
      );
      if (query.isEmpty) return null;
    }

    for (var saleItem in saleItems) {
      final result = await db.query(_tables[DBTables.inventory]!, where: 'barcode = ?', whereArgs: [saleItem.barcode]);
      int existingQuantity = int.parse(result.first['stock_quantity'].toString());
      await db.update(
        _tables[DBTables.inventory]!,
        {
          'stock_quantity': (existingQuantity - saleItem.quantity),
          'last_modified': DateTime.now().millisecondsSinceEpoch
        },
        where: 'barcode = ?',
        whereArgs: [saleItem.barcode],
      );
      await db.insert(_tables[DBTables.saleitems]!, {
        'receipt_number': sale.receiptNumber,
        'barcode': saleItem.barcode,
        'itemname': saleItem.itemName,
        'price': saleItem.price,
        'single_unit_quantity': saleItem.singleUnitQuantity,
        'quantity_purchased': saleItem.quantity,
      });
    }

    return await db.insert(
        _tables[DBTables.sales]!,
        {
          'receipt_number': sale.receiptNumber,
          'time_of_sale': sale.timeOfSale.millisecondsSinceEpoch,
          'total_amount': sale.totalAmount,
        },
        conflictAlgorithm: sql.ConflictAlgorithm.ignore);
  }

  static Future<List<Sale>?> getPastSales({bool getTodaySale = false}) async {
    final db = await instance.database;
    final result = (getTodaySale)
        ? await db.query(
            _tables[DBTables.sales]!,
            orderBy: 'time_of_sale DESC',
            where: 'time_of_sale > ?',
            whereArgs: [
              (DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).millisecondsSinceEpoch)
            ],
          )
        : await db.query(_tables[DBTables.sales]!, orderBy: 'time_of_sale DESC');
    if (result.isNotEmpty) {
      List<Sale> sales = [];
      for (var sale in result) {
        sales.add(
          Sale(
            receiptNumber: sale['receipt_number'].toString(),
            timeOfSale: DateTime.fromMillisecondsSinceEpoch(int.parse(sale['time_of_sale'].toString())),
            totalAmount: double.parse(sale['total_amount'].toString()),
            saleItems: {},
          ),
        );
      }
      return sales;
    } else {
      return null;
    }
  }

  static Future<List<Item>?> getPastSaleItems(String receiptNumber) async {
    final db = await instance.database;
    final result =
        await db.query(_tables[DBTables.saleitems]!, where: 'receipt_number = ?', whereArgs: [receiptNumber]);
    if (result.isNotEmpty) {
      List<Item> inventoryItems = [];
      for (var item in result) {
        inventoryItems.add(Item(
          itemName: item['itemname'] as String,
          barcode: item['barcode'] as String,
          price: item['price'] as double,
          singleUnitQuantity: item['single_unit_quantity'] as String,
          quantity: item['quantity_purchased'] as int,
        ));
      }
      return inventoryItems;
    } else {
      return null;
    }
  }
}
