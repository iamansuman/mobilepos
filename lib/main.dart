import 'package:flutter/material.dart';
import 'package:mobilepos/route_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(App(isNewUser: prefs.getBool('NEW_USER') ?? true));
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
