import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoarding extends StatefulWidget {
  const OnBoarding({super.key});

  @override
  State<OnBoarding> createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameTxTController = TextEditingController();
  final TextEditingController _merchantNameTxTController = TextEditingController();
  Map<String, dynamic> _countryDataList = {};
  late List<DropdownMenuEntry> _countriesNameList = [];
  final List<String> _countriesAcceptingUPI = ["IN"];
  String _currentCountry = "";
  String _qrImageData = "";

  @override
  void initState() {
    super.initState();
    loadCountriesData().whenComplete(() => setState(() {
          _countriesNameList;
        }));
  }

  Future<void> loadCountriesData() async {
    String jsonData = await rootBundle.loadString('assets/countries.json');
    Map<String, dynamic> countryDataList = jsonDecode(jsonData);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(
        () {
          _countryDataList = countryDataList;
          _countriesNameList = countryDataList.values
              .map<DropdownMenuEntry>(
                (countryData) => DropdownMenuEntry(value: countryData['code'], label: countryData['name']),
              )
              .toList();
          _currentCountry = countryDataList.values.first['code'];
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            "Welcome to Mobile PoS",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              fontFamily: 'Caveat',
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 10),
              TextFormField(
                controller: _shopNameTxTController,
                decoration: const InputDecoration(border: OutlineInputBorder(), label: Text("Shop Name")),
                validator: (value) {
                  if (value == null || value == "") return "Shop Name can't be Empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _merchantNameTxTController,
                decoration: const InputDecoration(border: OutlineInputBorder(), label: Text("Merchant Name")),
                validator: (value) {
                  if (value == null || value == "") return "Merchant Name can't be Empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownMenu(
                key: UniqueKey(),
                width: 360,
                menuHeight: 450,
                label: const Text("Select Your Country"),
                dropdownMenuEntries: _countriesNameList,
                enableSearch: true,
                initialSelection: _currentCountry,
                onSelected: (value) {
                  setState(() {
                    _currentCountry = value!;
                    _qrImageData = "";
                  });
                },
              ),
              const SizedBox(height: 20),
              (_countriesAcceptingUPI.contains(_currentCountry))
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text("Scan Your Merchant UPI QR code"),
                      onPressed: () async {
                        String barcode =
                            await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.QR);
                        if (barcode.startsWith('upi://pay')) setState(() => _qrImageData = barcode);
                      },
                    )
                  : const SizedBox(),
              (_countriesAcceptingUPI.contains(_currentCountry) && _qrImageData != "")
                  ? Center(
                      child: Column(
                        children: [
                          QrImageView(
                            data: _qrImageData,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            size: 250,
                            errorStateBuilder: (context, error) {
                              return Text(
                                "Error while building QR: $error",
                                style: const TextStyle(color: Color(0xFFF00000)),
                              );
                            },
                          ),
                          const Text("Verify QR before proceeding",
                              style: TextStyle(fontSize: 25, color: Color(0xFFFF0000))),
                          const Text("Try sending a small amount to this QR",
                              style: TextStyle(color: Color(0xFF404040))),
                        ],
                      ),
                    )
                  : const SizedBox(),
              const SizedBox(height: 30),
              // const Center(child: Text("By clicking 'Finish Setup', you agree to our usage policy")),
              // const SizedBox(height: 10),
              // TextButton(
              //   child: const Text("Usage Policy"),
              //   onPressed: () => Navigator.pushNamed(context, '/usagepolicy'),
              // ),
              // const SizedBox(height: 20),
              //TODO: usage policy
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.grey.shade300,
                  foregroundColor: Theme.of(context).secondaryHeaderColor,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text("Finish Setup"),
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _currentCountry != "" && _countryDataList != {}) {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('NEW_USER', false);
                    await prefs.setString('SHOP_NAME', _shopNameTxTController.text);
                    await prefs.setString('MERCHANT_NAME', _merchantNameTxTController.text);
                    await prefs.setString('CURR_COUNTRY_DATA', jsonEncode(_countryDataList[_currentCountry]));
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
