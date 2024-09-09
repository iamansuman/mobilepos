import 'package:flutter/material.dart';
import 'package:mobilepos/alertdialog.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/posdatabase.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  String currencyChar = '₹'; //TODO: Change currency denotation in settings

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: PoSDatabase.getItemsFromInventory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            List<Item> items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: ((context, index) {
                Item item = items[index];
                return ListTile(
                  leading: Text(
                    item.quantity.toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  title: Text(item.itemName),
                  subtitle: Text("${item.barcode} | ${item.singleUnitQuantity} | $currencyChar${item.price}"),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem<int>(value: 0, child: Text("Set Quantity")),
                        const PopupMenuItem<int>(
                          value: 1,
                          child: Text("Remove Product", style: TextStyle(color: Color(0xFFFF0000))),
                        ),
                      ];
                    },
                    onSelected: (value) {
                      switch (value) {
                        case 0:
                          {
                            //TODO: set quantity
                          }
                        case 1:
                          {
                            alertUser(
                              context,
                              "Do you want to remove this product from Inventory?",
                              additionalActions: [
                                TextButton(
                                  onPressed: () async {
                                    int status = await PoSDatabase.removeItemFromInventory(item.barcode);
                                    if (status > 0) {
                                      setState(() {});
                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                                  child: const Text(
                                    "Remove Product",
                                    style: TextStyle(
                                      color: Color(0xFFFF0000),
                                    ),
                                  ),
                                )
                              ],
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Item: ${item.itemName}"),
                                  Text("Stock Quantity: ${item.quantity}"),
                                  Text("Barcode: ${item.barcode}"),
                                  Text("Unit Price: ${item.price}"),
                                  Text("Unit Quantity: ${item.singleUnitQuantity}"),
                                ],
                              ),
                            );
                          }
                      }
                    },
                  ),
                );
              }),
            );
          } else {
            return const Center(child: Text('Your warehouse seems empty 🏭'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addtoinventory',
        icon: const Icon(Icons.add),
        label: const Text("Add Item"),
        onPressed: () async {
          final dynamic status = await Navigator.pushNamed(context, '/addtoinventory');
          if (status is String && status == 'success') setState(() {});
        },
      ),
    );
  }
}
