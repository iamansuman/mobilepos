import 'package:flutter/material.dart';
import 'package:mobilepos/route_generator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    bool newUser = false;
    //TODO: New User logic
    return MaterialApp(
      title: 'Mobile PoS',
      theme: ThemeData(useMaterial3: true),
      onGenerateRoute: RouteGenerator.generateRoute,
      initialRoute: (newUser) ? '/onboarding' : '/',
    );
  }
}
