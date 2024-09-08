import 'package:flutter/material.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
