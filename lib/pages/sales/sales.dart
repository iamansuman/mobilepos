import 'package:flutter/material.dart';

class Sales extends StatefulWidget {
  const Sales({super.key});

  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newsale',
        icon: const Icon(Icons.add),
        label: const Text("New Sale"),
        onPressed: () => Navigator.pushNamed(context, '/newsale'),
      ),
    );
  }
}
