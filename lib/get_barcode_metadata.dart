import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';

//https://world.openfoodfacts.org/api/v3/product/<barcode>.json

///Return { 'product_name': <Product Name>, 'quantity': <Quantity of Product> }
Future<Map<String, String>> getBarcodeMetadata(String barcode) async {
  final Uri url = Uri.parse('https://world.openfoodfacts.org/api/v3/product/$barcode.json');
  try {
    final Response response = await get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
      final String dataStatus = data['status'];
      if (dataStatus == 'success') {
        final String productName = data['product']['product_name'] ?? "";
        final String? quantityWhole = data['product']['quantity'];
        final String? productQuantity = data['product']['product_quantity'];
        final String? productQuantityUnit = data['product']['product_quantity_unit'];
        String quantity = '';
        if (quantityWhole != null) {
          quantity = quantityWhole;
        } else if (productQuantity != null && productQuantityUnit != null) {
          quantity = "$productQuantity $productQuantityUnit";
        }
        return {'product_name': productName, 'quantity': quantity};
      }
    }
    return {'product_name': '', 'quantity': ''};
  } catch (error) {
    log("Error from hitting API endpoint in get_barcode_metadata.dart: $error");
    return {'product_name': '', 'quantity': ''};
  }
}
