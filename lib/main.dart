import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiniPlayApp());
}

class MiniPlayApp extends StatelessWidget {
  const MiniPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Play',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4ECCA3),
          secondary: Color(0xFFF0C040),
          surface: Color(0xFF16213E),
          error: Color(0xFFE84545),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(child: Text('Mini Play - Coming Soon')),
          ),
        );
      },
    );
  }
}
