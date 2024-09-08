import 'package:flutter/material.dart';
import 'package:mobilepos/pages/onboarding.dart';
import 'package:mobilepos/pages/home.dart';


class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments;
    return MaterialPageRoute(builder: (_) {
      switch (settings.name) {
        case '/':
          return const HomePage();
        case '/onboarding':
          return const OnBoarding();
        default:
          return const HomePage();
      }
    });
  }
}
