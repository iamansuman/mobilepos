import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilepos/route_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App(isNewUser: (await SharedPreferences.getInstance()).getBool('NEW_USER') ?? true));
}

class App extends StatelessWidget {
  final bool isNewUser;
  const App({super.key, this.isNewUser = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile PoS',
      theme: ThemeData(useMaterial3: true),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: (isNewUser) ? '/onboarding' : '/',
    );
  }
}