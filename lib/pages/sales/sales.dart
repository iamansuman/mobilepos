import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/posdatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sales extends StatefulWidget {
  const Sales({super.key});

  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  String currencyChar = '💵';

  Future<void> getCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currencyChar =
          jsonDecode(prefs.getString('CURR_COUNTRY_DATA') ?? "{\"currency\": \"$currencyChar\"}")['currency'];
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
      body: Stack(
        children: [
          FutureBuilder(
            future: PoSDatabase.getPastSales(getTodaySale: true),
            builder: ((context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                List<Sale> sales = snapshot.data!;
                double totalSaleAmount = 0;
                for (var sale in sales) {
                  totalSaleAmount += sale.totalAmount;
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, kFloatingActionButtonMargin + 56),
                  itemCount: sales.length + 1,
                  itemBuilder: (context, index) {
                    Sale sale = (index != 0)
                        ? sales[index - 1]
                        : Sale(
                            receiptNumber: '',
                            timeOfSale: DateTime.now(),
                            saleItems: {},
                            totalAmount: 0,
                          );
                    return (index == 0)
                        ? Text(
                            "Total Sale Amount (today): $currencyChar$totalSaleAmount",
                            key: UniqueKey(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              height: 5,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : ListTile(
                            leading: Text(
                              "$currencyChar${sale.totalAmount.toString()}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              key: UniqueKey(),
                            ),
                            title: Text(sale.receiptNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(DateFormat("hh:mm:ss a on EEEE, MMMM dd, yyyy").format(sale.timeOfSale)),
                            onTap: () => Navigator.pushNamed(context, '/saledetails', arguments: sale),
                          );
                  },
                );
              } else {
                return const Center(
                  child: Text(
                    'Time to sell some stuff 🛒',
                    style: TextStyle(fontSize: 22),
                  ),
                );
              }
            }),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'allsales',
              icon: const Icon(Icons.history_rounded),
              label: const Text("All Sales"),
              onPressed: () => Navigator.pushNamed(context, '/allsales'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newsale',
        icon: const Icon(Icons.add),
        label: const Text("New Sale"),
        onPressed: () => Navigator.pushNamed(context, '/newsale'),
      ),
    );
  }
}
