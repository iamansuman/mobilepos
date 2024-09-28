import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos/posdatabase.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/get_barcode.dart';
import 'package:mobilepos/get_barcode_metadata.dart';
import 'package:mobilepos/alertdialog.dart';

class NewSale extends StatefulWidget {
  const NewSale({super.key});

  @override
  State<NewSale> createState() => _NewSaleState();
}

class _NewSaleState extends State<NewSale> {
  String currencyChar = '💵';
  final DateTime currentDateTime = DateTime.now();
  Map<String, Item> saleItems = {};
  Sale newSale = Sale(timeOfSale: DateTime.now(), receiptNumber: '', saleItems: {}, totalAmount: 0);

  Future<void> getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencyChar = prefs.getString('SETTINGS_MERCHANTDATA_CURRENCY') ?? currencyChar;
    });
  }

  @override
  void initState() {
    super.initState();
    newSale = Sale(
      timeOfSale: currentDateTime,
      receiptNumber: DateFormat('RyyyyMMdd-HHmmss').format(currentDateTime),
      saleItems: saleItems,
      totalAmount: 0,
    );
    getCurrency();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("New Sale"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.grey.shade300,
                  foregroundColor: Theme.of(context).secondaryHeaderColor,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: (saleItems.isEmpty)
                    ? null
                    : () async {
                        double priceAcc = 0;
                        for (var saleitem in newSale.saleItems.values) {
                          priceAcc += saleitem.price * saleitem.quantity;
                        }
                        newSale.totalAmount = priceAcc;
                        int? status = await PoSDatabase.processSale(newSale);
                        if (context.mounted) {
                          if (status == null) {
                            await alertUser(context, "Selected amount of Items are not available in inventory",
                                cancelButtonText: "Dismiss");
                          } else if (status < 0) {
                            await alertUser(context, "Error", cancelButtonText: "Dismiss");
                          } else {
                            Navigator.pushNamed(context, '/receipt', arguments: newSale);
                          }
                        }
                      },
                child: const Text("Generate Receipt"),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: () => manualEntryDialog(''),
                child: const Text("Manual Entry"),
              ),
            ],
          ),
          Expanded(
            child: (saleItems.isEmpty)
                ? const Center(child: Text("Cart is Empty 🛒", style: TextStyle(fontSize: 25)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: kFloatingActionButtonMargin + 56),
                    itemCount: saleItems.length,
                    itemBuilder: (context, index) {
                      return itemTile(saleItems.values.toList()[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales',
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text("Scan Item"),
        onPressed: () async {
          String? barcodeResult = await getBarcodeData(context);
          if (barcodeResult != null && context.mounted) {
            if (saleItems.containsKey(barcodeResult)) {
              saleItems[barcodeResult]?.addQty();
            } else {
              Item? infoFromDB = await PoSDatabase.getItemInfoFromInventory(barcodeResult);
              if (infoFromDB != null) {
                infoFromDB.quantity = 1;
                saleItems[barcodeResult] = infoFromDB;
              } else {
                manualEntryDialog(barcodeResult);
              }
            }
            setState(() {});
          }
        },
      ),
    );
  }

  ListTile itemTile(Item item) {
    String barcode = item.barcode;
    return ListTile(
      leading: Text(
        item.quantity.toString(),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      title: Text(item.itemName),
      subtitle: Text("$barcode | ${item.singleUnitQuantity} | $currencyChar${item.price}", key: UniqueKey()),
      trailing: PopupMenuButton(
        itemBuilder: (context) {
          return [
            const PopupMenuItem<int>(value: 0, child: Text("Set Price")),
            const PopupMenuItem<int>(value: 1, child: Text("Set Quantity")),
            const PopupMenuItem<int>(value: 2, child: Text("Increase Quantity by 1")),
            const PopupMenuItem<int>(value: 3, child: Text("Decrease Quantity by 1")),
            const PopupMenuItem<int>(
                value: 4, child: Text("Remove Product", style: TextStyle(color: Color(0xFFFF0000)))),
          ];
        },
        onSelected: (value) async {
          if (value == 0) {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                TextEditingController customPriceTextController = TextEditingController(text: item.price.toString());
                return SimpleDialog(
                  contentPadding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 24),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(),
                      textAlign: TextAlign.center,
                      controller: customPriceTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Price",
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.grey.shade300,
                        foregroundColor: Theme.of(context).secondaryHeaderColor,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text("Set Price"),
                      onPressed: () {
                        if (double.tryParse(customPriceTextController.text) != null &&
                            double.tryParse(customPriceTextController.text)! >= 0) {
                          saleItems[barcode]!.price = double.tryParse(customPriceTextController.text) ?? item.price;
                          item.price = saleItems[barcode]?.price ?? item.price;
                          Navigator.pop(context, item.price);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            );
            setState(() {});
          } else if (value == 1) {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                TextEditingController customQuantityTextController =
                    TextEditingController(text: item.quantity.toString());
                return SimpleDialog(
                  contentPadding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 24),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(),
                      textAlign: TextAlign.center,
                      controller: customQuantityTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Quantity",
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.grey.shade300,
                        foregroundColor: Theme.of(context).secondaryHeaderColor,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text("Set Quantity"),
                      onPressed: () {
                        if (int.tryParse(customQuantityTextController.text) != null &&
                            int.tryParse(customQuantityTextController.text)! >= 0) {
                          saleItems[barcode]!.quantity =
                              int.tryParse(customQuantityTextController.text) ?? item.quantity;
                          item.quantity = saleItems[barcode]?.quantity ?? item.quantity;
                          Navigator.pop(context, item.quantity);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            );
            setState(() {});
          } else if (value == 2) {
            saleItems[barcode]?.addQty();
            item.quantity = saleItems[barcode]?.quantity ?? item.quantity;
            setState(() {});
          } else if (value == 3) {
            saleItems[barcode]?.removeQty();
            item.quantity = saleItems[barcode]?.quantity ?? item.quantity;
            setState(() {});
          } else if (value == 4) {
            saleItems.remove(barcode);
            setState(() {});
          }
        },
      ),
    );
  }

  Future manualEntryDialog(String barcode) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController barcodeTextController = TextEditingController();
        final TextEditingController itemNameTextController = TextEditingController();
        final TextEditingController unitQuantityTextController = TextEditingController();
        final TextEditingController unitPriceTextController = TextEditingController();
        final TextEditingController unitsTextController = TextEditingController();

        InputDecoration textFieldDecoration(String label) =>
            InputDecoration(border: const OutlineInputBorder(), labelText: label);
        if (barcode != '') barcodeTextController.text = barcode;
        return SimpleDialog(
          title: const Text('Add Product'),
          contentPadding: const EdgeInsets.all(16),
          children: [
            TextField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: barcodeTextController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Barcode Number (UPC, EAN, GS1, MSI)",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded),
                  onPressed: () async {
                    String? barcode = await getBarcodeData(context);
                    if (barcode != null && mounted) {
                      barcodeTextController.text = barcode.toString();
                      Map<String, String> productInfo = await getBarcodeMetadata(barcode);
                      itemNameTextController.text = productInfo['product_name'].toString();
                      unitQuantityTextController.text = productInfo['quantity'].toString();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text("Check the barcode before proceeding"),
            const SizedBox(height: 15),
            TextField(
              controller: itemNameTextController,
              decoration: textFieldDecoration("Product Name"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: unitQuantityTextController,
              decoration: textFieldDecoration("Unit Quantity"),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: unitPriceTextController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 10),
                  child: Text(
                    currencyChar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
                border: const OutlineInputBorder(),
                labelText: "Unit Price",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: unitsTextController,
              decoration: textFieldDecoration("Units"),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shadowColor: Colors.grey.shade300,
                    foregroundColor: Theme.of(context).secondaryHeaderColor,
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    String barcode = (int.tryParse(barcodeTextController.text) != null)
                        ? barcodeTextController.text
                        : getRandomBarcode();
                    Item item = Item(
                      itemName: itemNameTextController.text,
                      barcode: barcode,
                      price: double.tryParse(unitPriceTextController.text) ?? 1,
                      quantity: int.tryParse(unitsTextController.text) ?? 1,
                    );
                    saleItems[barcode] = item;
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
