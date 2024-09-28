import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/posdatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaleDetails extends StatefulWidget {
  final Sale sale;
  const SaleDetails({super.key, required this.sale});

  @override
  State<SaleDetails> createState() => _SaleDetailsState();
}

class _SaleDetailsState extends State<SaleDetails> {
  String currencyChar = '💵';

  Future<void> getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencyChar = prefs.getString('SETTINGS_MERCHANTDATA_CURRENCY') ?? currencyChar;
    });
  }

  @override
  void initState() {
    getCurrency();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Sale: ${widget.sale.receiptNumber}"),
      ),
      body: Column(
        children: [
          Text("Total Sale Amount: ${widget.sale.totalAmount.toString()}"),
          Text("Time of Sale: ${DateFormat("hh:mm:ss a on EEEE, MMMM dd, yyyy").format(widget.sale.timeOfSale)}"),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder(
              future: PoSDatabase.getPastSaleItems(widget.sale.receiptNumber),
              builder: ((context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData) {
                  List<Item> saleItems = snapshot.data!;
                  return ListView.builder(
                    itemCount: saleItems.length,
                    itemBuilder: (context, index) {
                      final Item item = saleItems[index];
                      return ListTile(
                        leading: Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                        title: Text(item.itemName),
                        subtitle: Text(
                          "${item.barcode} | ${item.singleUnitQuantity} | $currencyChar${item.price}",
                          key: UniqueKey(),
                        ),
                      );
                    },
                  );
                } else {
                  return const Text("Something went wrong :(");
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}
