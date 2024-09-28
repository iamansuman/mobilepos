import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/posdatabase.dart';

class AllSales extends StatefulWidget {
  const AllSales({super.key});

  @override
  State<AllSales> createState() => _AllSalesState();
}

class _AllSalesState extends State<AllSales> {
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
        title: const Text("All Sales"),
      ),
      body: FutureBuilder(
        future: PoSDatabase.getPastSales(getTodaySale: false),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            List<Sale> sales = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, kFloatingActionButtonMargin + 56),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                Sale sale = sales[index];
                return ListTile(
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
    );
  }
}
