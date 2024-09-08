class Sale {
  final DateTime timeOfSale;
  final String receiptNumber;
  final Map<String, Item> saleItems;
  double totalAmount;
  Sale({required this.timeOfSale, required this.receiptNumber, required this.saleItems, required this.totalAmount});
}

class Item {
  final String itemName;
  final String barcode;
  final double price;
  String singleUnitQuantity;
  int quantity;
  Item({
    required this.itemName,
    required this.barcode,
    required this.price,
    this.singleUnitQuantity = "1 Unit",
    this.quantity = 1,
  });

  void addQty({int qty = 1}) {
    quantity += qty;
  }

  void removeQty({int qty = 1}) {
    if (quantity - qty >= 0) {
      quantity -= qty;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'itemname': itemName,
      'price': price,
      'single_unit_quantity': singleUnitQuantity,
      'stock_quantity': quantity,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) => Item(
        itemName: map['itemname'] as String,
        barcode: map['barcode'] as String,
        price: map['price'] as double,
        singleUnitQuantity: map['single_unit_quantity'] as String,
        quantity: map['stock_quantity'] as int,
      );
}
