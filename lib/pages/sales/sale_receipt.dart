import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos/data_structure.dart';

class Receipt extends StatefulWidget {
  final Sale sale;
  const Receipt({super.key, required this.sale});

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  String shopName = '';
  String merchantName = '';
  String merchantContact = '';
  String upiQRData = '';
  String currencyChar = '💵';

  Future<void> getMerchantData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      shopName = prefs.getString('SETTINGS_MERCHANTDATA_SHOPNAME') ?? shopName;
      merchantName = prefs.getString('SETTINGS_MERCHANTDATA_MERCHANTNAME') ?? merchantName;
      merchantContact = prefs.getString('SETTINGS_MERCHANTDATA_MERCHANTCONTACT') ?? merchantContact;
      upiQRData = prefs.getString('SETTINGS_UPI_QRDATA') ?? upiQRData;
      currencyChar = prefs.getString('SETTINGS_MERCHANTDATA_CURRENCY') ?? currencyChar;
    });
  }

  @override
  void initState() {
    getMerchantData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text("Receipt: ${widget.sale.receiptNumber}"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Your order has been Recorded 📝", style: TextStyle(fontSize: 20)),
              Text(
                "Total bill amount: $currencyChar${widget.sale.totalAmount}",
                style: const TextStyle(fontSize: 20),
              ),
              Visibility(
                key: UniqueKey(),
                visible: (upiQRData != ''),
                child: Column(
                  children: [
                    Text(
                      "Pay $currencyChar${widget.sale.totalAmount} via UPI by scanning this QR",
                      style: const TextStyle(fontSize: 20),
                    ),
                    QrImageView(
                      data: "$upiQRData&am=${widget.sale.totalAmount}",
                      //TODO: add &mam= (min. amount) to QR
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      size: 250,
                      errorStateBuilder: (context, error) {
                        return Text(
                          "Error while building QR: $error",
                          style: const TextStyle(color: Color(0xFFF00000)),
                        );
                      },
                    ),
                    const Text("Verify QR before proceeding", style: TextStyle(fontSize: 25, color: Color(0xFFFF0000))),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', ModalRoute.withName('/')),
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.grey.shade300,
                  foregroundColor: Theme.of(context).secondaryHeaderColor,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text("Done"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //TODO: Function to generate uint8List data (image) of receipt
  //TODO: Share the image to customer
}
