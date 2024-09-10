import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/get_barcode.dart';
import 'package:mobilepos/posdatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      currencyChar =
          jsonDecode(prefs.getString('CURR_COUNTRY_DATA') ?? "{\"currency\": \"$currencyChar\"}")['currency'];
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
        title: const Text("Add Product to Inventory"),
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
                    : () {
                        //TODO: Generate Bill
                      },
                child: const Text("Generate Receipt"),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: () {
                  //TODO: Manual Entry
                },
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
                //TODO: Remove these
                String randomBarcode = getRandomBarcode();
                saleItems[randomBarcode] = Item(itemName: "Random Product", barcode: randomBarcode, price: 10);
                //TODO: Manual Entry
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
            const PopupMenuItem<int>(value: 0, child: Text("Set Quantity")),
            const PopupMenuItem<int>(value: 1, child: Text("Increase Quantity by 1")),
            const PopupMenuItem<int>(value: 2, child: Text("Decrease Quantity by 1")),
            const PopupMenuItem<int>(
                value: 3, child: Text("Remove Product", style: TextStyle(color: Color(0xFFFF0000)))),
          ];
        },
        onSelected: (value) async {
          if (value == 1) {
            saleItems[barcode]?.addQty();
            item.quantity = saleItems[barcode]?.quantity ?? item.quantity;
            setState(() {});
          } else if (value == 2) {
            saleItems[barcode]?.removeQty();
            item.quantity = saleItems[barcode]?.quantity ?? item.quantity;
            setState(() {});
          } else if (value == 3) {
            saleItems.remove(barcode);
            setState(() {});
          } else {
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
          }
        },
      ),
    );
  }
}
