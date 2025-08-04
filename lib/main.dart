import 'package:flutter/material.dart';
import 'package:girisim/splash_screen.dart';
import 'package:girisim/theme/girisim_flutter_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: GirisimTheme.lightTheme,
      darkTheme: GirisimTheme.darkTheme,
      home: SplashScreen(), // İlk açılış
      routes: {'/home': (context) => const HomePage()},
    );
  }
}
