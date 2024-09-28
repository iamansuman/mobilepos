import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/posdatabase.dart';
import 'package:mobilepos/get_barcode.dart';
import 'package:mobilepos/get_barcode_metadata.dart';
import 'package:mobilepos/alertdialog.dart';

class AddInventory extends StatefulWidget {
  const AddInventory({super.key});

  @override
  State<AddInventory> createState() => _AddInventoryState();
}

class _AddInventoryState extends State<AddInventory> {
  String currencyChar = '💵';
  String gs1Prefix = '';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeTextController = TextEditingController();
  final TextEditingController _itemNameTextController = TextEditingController();
  final TextEditingController _unitQuantityTextController = TextEditingController();
  final TextEditingController _unitPriceTextController = TextEditingController();
  final TextEditingController _stockQuantityTextController = TextEditingController();
  InputDecoration textFieldDecoration(String label) =>
      InputDecoration(border: const OutlineInputBorder(), labelText: label);
  Text descTextBox(String label, {Color? color}) =>
      Text(label, style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade600));

  Future<void> getCurrecyAndGS1() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    gs1Prefix = prefs.getString('SETTINGS_MERCHANTDATA_GS1') ?? currencyChar;
    currencyChar = prefs.getString('SETTINGS_MERCHANTDATA_CURRENCY') ?? currencyChar;
    setState(() {
      currencyChar;
      gs1Prefix;
    });
  }

  @override
  void initState() {
    getCurrecyAndGS1();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _barcodeTextController.text = gs1Prefix;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Product to Inventory"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: _barcodeTextController,
              validator: (value) {
                if (value == null || value == "") return "Barcode Cannot be empty";
                if (int.tryParse(value) == null) return "Barcode Must be UPC, EAN, GS1, MSI (linear barcodes)";
                return null;
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Barcode Number (UPC, EAN, GS1, MSI)",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded),
                  onPressed: () async {
                    String? barcode = await getBarcodeData(context);
                    if (barcode != null) {
                      _barcodeTextController.text = barcode.toString();
                      final Map<String, String> barcodeMetaData = await getBarcodeMetadata(barcode);
                      _itemNameTextController.text = barcodeMetaData['product_name'] ?? '';
                      _unitQuantityTextController.text = barcodeMetaData['quantity'] ?? '';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 5),
            descTextBox(
              "Double check with Barcode number present right below the Code",
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _itemNameTextController,
              decoration: textFieldDecoration("Product Name"),
              validator: (value) {
                if (value == null || value == "") return "Product Name cannot be empty";
                return null;
              },
            ),
            const SizedBox(height: 5),
            descTextBox("Be little Descriptive about the Product"),
            descTextBox("Recommendation: Do Not add Price or quantity with the name"),
            const SizedBox(height: 30),
            TextFormField(
              controller: _unitQuantityTextController,
              decoration: textFieldDecoration("Unit Quantity"),
              validator: (value) {
                if (value == null || value == "") return "Unit Quantity cannot be empty";
                return null;
              },
            ),
            const SizedBox(height: 5),
            descTextBox(
                "Quantity of each individual item in kg, g, lbs, ton, L, ml, gallons, ounce, pint, m, cm, mm, feet, inches etc"),
            descTextBox("In case of items which are sold in terms of units, mention '1 unit'"),
            const SizedBox(height: 30),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: _unitPriceTextController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 10),
                  child: Text(
                    currencyChar,
                    style: const TextStyle(fontSize: 24),
                    key: UniqueKey(),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
                border: const OutlineInputBorder(),
                labelText: "Unit Price",
              ),
              validator: (value) {
                if (value == null || value == "") {
                  return "Price cannot be empty";
                } else if (double.tryParse(value) == null) {
                  return "Price can only be numberical";
                } else if (double.parse(value) <= 0) {
                  return "Price must be greater than 0";
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            descTextBox("Price of each individual item"),
            const SizedBox(height: 30),
            TextFormField(
              keyboardType: const TextInputType.numberWithOptions(),
              controller: _stockQuantityTextController,
              decoration: textFieldDecoration("Stock Quantity"),
              validator: (value) {
                if (value == null || value == "") {
                  return "Stock Quantity cannot be empty";
                } else if (double.tryParse(value) == null) {
                  return "Stock Quantity can only be numberical";
                } else if (double.parse(value) < 1) {
                  return "Stock Quantity must be greater or equal to than 1";
                }
                return null;
              },
            ),
            const SizedBox(height: 5),
            descTextBox("Number of individual items in the batch"),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shadowColor: Colors.grey.shade300,
                foregroundColor: Theme.of(context).secondaryHeaderColor,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text("Add to Inventory"),
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    await PoSDatabase.itemExistsWithBarcode(_barcodeTextController.text.toString())) {
                  if (context.mounted) {
                    alertUser(context, "Item already exists in Inventory", cancelButtonText: "Dismiss");
                  }
                } else if (_formKey.currentState!.validate()) {
                  int status = await PoSDatabase.addItemToInventory(
                    Item(
                      itemName: _itemNameTextController.text,
                      barcode: _barcodeTextController.text.toString(),
                      price: double.parse(_unitPriceTextController.text),
                      singleUnitQuantity: _unitQuantityTextController.text,
                      quantity: int.parse(_stockQuantityTextController.text),
                    ),
                  );
                  if (status > 0 && context.mounted) {
                    Navigator.pop(context, 'success');
                    setState(() {});
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
