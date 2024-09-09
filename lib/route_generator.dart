import 'package:flutter/material.dart';
import 'package:mobilepos/pages/home.dart';
import 'package:mobilepos/pages/onboarding/onboarding.dart';
import 'package:mobilepos/pages/inventory/inventory_add.dart';
import 'package:mobilepos/pages/onboarding/usage_policy.dart';
import 'package:mobilepos/pages/sales/sale_new.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments;
    return MaterialPageRoute(builder: (_) {
      switch (settings.name) {
        case '/':
          return const HomePage();
        case '/onboarding':
          return const OnBoarding();
        case '/usagepolicy':
          return const UsagePolicy();
        case '/addtoinventory':
          return const AddInventory();
        case '/newsale':
          return const NewSale();
        default:
          return const HomePage();
      }
    });
  }
}
