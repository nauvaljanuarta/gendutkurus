import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'screens/map_screen.dart';
import 'screens/splash_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const GendutKurusApp());
}

class GendutKurusApp extends StatelessWidget {
  const GendutKurusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gendut Kurus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        MainNavigation.routeName: (context) => const MainNavigation(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
