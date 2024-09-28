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
  final TextEditingController _merchantContactTxTController = TextEditingController();
  Map<String, dynamic> _countryDataList = {};
  late List<DropdownMenuItem> _countriesNameList = [];
  late List _countriesAcceptingUPI = [];
  String _currentCountry = "";
  String _qrImageData = "";

  @override
  void initState() {
    super.initState();
    loadCountriesData().whenComplete(() => setState(() {
          _countriesNameList;
        }));
    loadCountriesAcceptingUPI().whenComplete(() => setState(
          () {
            _countriesAcceptingUPI;
          },
        ));
  }

  Future<void> loadCountriesData() async {
    String jsonData = await rootBundle.loadString('assets/countries.json');
    Map<String, dynamic> countryDataList = jsonDecode(jsonData);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => setState(
        () {
          _countryDataList = countryDataList;
          _countriesNameList = countryDataList.values
              .map<DropdownMenuItem>(
                (countryData) => DropdownMenuItem(
                    value: countryData['code'], child: Text("(${countryData['code']}) ${countryData['name']}")),
              )
              .toList();
          _currentCountry = countryDataList.values.first['code'];
        },
      ),
    );
  }

  Future<void> loadCountriesAcceptingUPI() async {
    String jsonData = await rootBundle.loadString('assets/upi_acceptance.json');
    List countriesAcceptingUPI = jsonDecode(jsonData);
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {
          _countriesAcceptingUPI = countriesAcceptingUPI;
        }));
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                  label: Text("Shop Name"),
                ),
                validator: (value) {
                  if (value == null || value == "") return "Shop Name can't be Empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                keyboardType: TextInputType.name,
                controller: _merchantNameTxTController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_4_rounded),
                  label: Text("Merchant Name"),
                ),
                validator: (value) {
                  if (value == null || value == "") return "Merchant Name can't be Empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                keyboardType: TextInputType.phone,
                controller: _merchantContactTxTController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_rounded),
                  label: Text("Merchant Contact (Phone)"),
                ),
                validator: (value) {
                  if (value == null || value == "") return "Merchant Contact can't be Empty";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField(
                key: UniqueKey(),
                menuMaxHeight: 350,
                items: _countriesNameList,
                value: _currentCountry,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public),
                  labelText: 'Select Your Country',
                ),
                onChanged: (value) {
                  setState(() {
                    _currentCountry = value!;
                    _qrImageData = "";
                  });
                },
                isExpanded: true,
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
                    await prefs.setString('SETTINGS_MERCHANTDATA_SHOPNAME', _shopNameTxTController.text);
                    await prefs.setString('SETTINGS_MERCHANTDATA_MERCHANTNAME', _merchantNameTxTController.text);
                    await prefs.setString('SETTINGS_MERCHANTDATA_MERCHANTCONTACT', _merchantContactTxTController.text);
                    await prefs.setString('SETTINGS_MERCHANTDATA_COUNTRY', _currentCountry);
                    await prefs.setString(
                        'SETTINGS_MERCHANTDATA_CURRENCY', _countryDataList[_currentCountry]['currency']);
                    await prefs.setString('SETTINGS_MERCHANTDATA_GS1', _countryDataList[_currentCountry]['GS1']);
                    await prefs.setString('SETTINGS_UPI_QRDATA', _qrImageData);
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/inventory', (route) => false);
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
