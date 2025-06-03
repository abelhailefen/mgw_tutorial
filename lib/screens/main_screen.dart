//lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/account/account_screen.dart';
import 'package:mgw_tutorial/screens/home/home_screen.dart';
import 'package:mgw_tutorial/screens/library/library_screen.dart';
import 'package:mgw_tutorial/screens/notifications/notifications_screen.dart';
import 'package:mgw_tutorial/widgets/app_drawer.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    LibraryScreen(),
    NotificationsScreen(),
    AccountScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // Get the current theme

    final List<String> _appBarTitles = <String>[
      l10n.appTitle, // Or l10n.home if preferred for the Home tab title
      l10n.library,
      l10n.notifications,
      l10n.account,
    ];
    final List<String> bottomNavLabels = <String>[
      l10n.home,
      l10n.library,
      l10n.notifications,
      l10n.account,
    ];
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar( // AppBarTheme from main.dart will apply
        title: Text(_appBarTitles[_selectedIndex]),
        leading: IconButton(
          icon: const Icon(Icons.menu), // Icon color from AppBarTheme
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const AppDrawer(), // DrawerTheme from main.dart will apply
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar( // BottomNavigationBarTheme from main.dart will apply
        items:  <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: bottomNavLabels[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books_outlined),
            activeIcon: const Icon(Icons.library_books),
            label: bottomNavLabels[1],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications_none_outlined),
            activeIcon: const Icon(Icons.notifications),
            label: bottomNavLabels[2],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: const Icon(Icons.account_circle),
            label: bottomNavLabels[3],
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}