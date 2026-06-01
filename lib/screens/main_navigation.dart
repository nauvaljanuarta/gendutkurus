import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'favorite_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  static const routeName = '/main';

  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_currentIndex) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const MapScreen();
        break;
      case 2:
        page = const FavoriteScreen();
        break;
      case 3:
        page = const ProfileScreen();
        break;
      default:
        page = const HomeScreen();
    }

    return Scaffold(
      body: page,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
