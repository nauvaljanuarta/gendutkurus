import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_navigation.dart';
import 'screens/gym/map_screen.dart';
import 'screens/splash_screen.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmnldnlneatsyapvwwsb.supabase.co',
    anonKey: 'sb_publishable_hO6pqJLJ4StR_QXNPX4ArA_ueeW_dyn',
  );

  runApp(const GendutKurusApp());
}

class GendutKurusApp extends StatelessWidget {
  const GendutKurusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gendut Kurus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        MainNavigation.routeName: (context) => const MainNavigation(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
