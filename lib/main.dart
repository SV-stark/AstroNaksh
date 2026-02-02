import 'package:flutter/material.dart';
import 'ui/styles.dart';
import 'ui/home_screen.dart';
import 'ui/input_screen.dart';
import 'ui/chart_screen.dart';

void main() {
  runApp(const AstroNakshApp());
}

class AstroNakshApp extends StatelessWidget {
  const AstroNakshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroNaksh',
      theme: AppStyles.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/input': (context) => const InputScreen(),
        '/chart': (context) => const ChartScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
