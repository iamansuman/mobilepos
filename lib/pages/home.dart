import 'package:flutter/material.dart';
import 'package:mobilepos/pages/inventory/inventory.dart';
import 'package:mobilepos/pages/sales/sales.dart';
import 'package:mobilepos/pages/settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  final int selScreen;
  const HomePage({super.key, this.selScreen = 1});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<Widget> screenNavs = [Inventory(), Sales(), Settings()];
  int currScreen = 1;
  String shopName = "Your Shop";

  Future<void> getShopName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => shopName = prefs.getString('SHOP_NAME') ?? shopName);
  }

  @override
  void initState() {
    super.initState();
    currScreen = widget.selScreen;
    getShopName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.business_rounded),
        title: Text(shopName, key: UniqueKey()),
        backgroundColor: Theme.of(context).secondaryHeaderColor,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currScreen,
          children: screenNavs,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currScreen,
        destinations: const [
          NavigationDestination(
            label: "Inventory",
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
          ),
          NavigationDestination(
            label: "Sales",
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
          ),
          NavigationDestination(
            label: "Settings",
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
          ),
        ],
        onDestinationSelected: (int index) => setState(() => currScreen = index),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}
