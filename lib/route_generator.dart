import 'package:flutter/material.dart';
import 'package:mobilepos/data_structure.dart';
import 'package:mobilepos/pages/home.dart';
import 'package:mobilepos/pages/onboarding/onboarding.dart';
import 'package:mobilepos/pages/inventory/inventory_add.dart';
import 'package:mobilepos/pages/onboarding/usage_policy.dart';
import 'package:mobilepos/pages/sales/sale_details.dart';
import 'package:mobilepos/pages/sales/sale_new.dart';
import 'package:mobilepos/pages/sales/sale_receipt.dart';
import 'package:mobilepos/pages/sales/sales_all.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    return MaterialPageRoute(builder: (_) {
      switch (settings.name) {
        case '/':
          return const HomePage();
        case '/onboarding':
          return const OnBoarding();
        case '/usagepolicy':
          return const UsagePolicy();
        case '/inventory':
          return const HomePage(selScreen: 0);
        case '/addtoinventory':
          return const AddInventory();
        case '/sales':
          return const HomePage(selScreen: 1);
        case '/allsales':
          return const AllSales();
        case '/newsale':
          return const NewSale();
        case '/receipt':
          {
            if (args is Sale) return Receipt(sale: args);
            return SaleDetails(
                sale: Sale(timeOfSale: DateTime.now(), receiptNumber: '<N/A>', saleItems: {}, totalAmount: 0));
          }
        case '/saledetails':
          {
            if (args is Sale) return SaleDetails(sale: args);
            return SaleDetails(
                sale: Sale(timeOfSale: DateTime.now(), receiptNumber: '<N/A>', saleItems: {}, totalAmount: 0));
          }
        // case '/settings':
        //   return const HomePage(selScreen: 2);
        //TODO: Undo this
        default:
          return const HomePage();
      }
    });
  }
}
