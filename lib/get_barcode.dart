import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:just_audio/just_audio.dart';

///Returns a barcode or null
Future<String?> getBarcodeData(BuildContext context) async {
  final player = AudioPlayer();
  dynamic barcode = await FlutterBarcodeScanner.scanBarcode('#ff6666', 'Cancel', true, ScanMode.BARCODE);
  await player.setAudioSource(AudioSource.asset('assets/beep.mp3'));

  if (isValidBarcode(int.tryParse(barcode) != null ? barcode : null)) {
    player.play();
    return barcode.toString();
  } else {
    return null;
  }
}

bool isValidBarcode(dynamic barcode) => (barcode != null && barcode is String && barcode != '-1');

String getRandomBarcode() {
  final randomDigits = Random().nextInt(pow(10, 9).toInt());
  final randomBarcode = (952 * pow(10, 9).toInt()) + randomDigits; //always prefix 952 (reserved GS1 for demonstation)
  return randomBarcode.toString();
}
