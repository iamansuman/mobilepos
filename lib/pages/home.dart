import 'package:flutter/material.dart';
import 'package:mobilepos/pages/inventory/inventory.dart';
import 'package:mobilepos/pages/sales/sales.dart';
import 'package:mobilepos/pages/settings/settings.dart';

class HomePage extends StatefulWidget {
  final int selScreen;
  const HomePage({super.key, this.selScreen = 1});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<Widget> screenNavs = [Inventory(), Sales(), Settings()];
  int currScreen = 1;

  @override
  void initState() {
    super.initState();
    currScreen = widget.selScreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.business_rounded),
        //TODO: Change this to dynamic name
        title: const Text("Your Shop"),
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
