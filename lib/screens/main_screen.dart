import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/account/account_screen.dart';
import 'package:mgw_tutorial/screens/home/home_screen.dart';
import 'package:mgw_tutorial/screens/library/library_screen.dart';
import 'package:mgw_tutorial/screens/notifications/notifications_screen.dart';
import 'package:mgw_tutorial/widgets/app_drawer.dart'; // Import the AppDrawer

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for the Scaffold

  // List of pages to navigate to
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
    
    final List<String> _appBarTitles = <String>[
      l10n.appTitle,       // For HomeScreen (assuming appTitle is your main title)
      l10n.library,        // For LibraryScreen
      l10n.notifications,  // For NotificationsScreen
      l10n.account,        // For AccountScreen
    ];
    final List<String> bottomNavLabels = <String>[
      l10n.home,           // For Home tab
      l10n.library,        // For Library tab
      l10n.notifications,  // For Notifications tab
      l10n.account,        // For Account tab
    ];
    return Scaffold(
      key: _scaffoldKey, // Assign the key to the Scaffold
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]), // Dynamically set AppBar title
        leading: IconButton( // Add hamburger icon to open drawer
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Open drawer using the key
          },
        ),
      ),
      drawer: const AppDrawer(), // Add the AppDrawer to MainScreen's Scaffold
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items:  <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: bottomNavLabels[0],
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: bottomNavLabels[1],
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: bottomNavLabels[2],
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: bottomNavLabels[3],
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        elevation: 8.0,
      ),
    );
  }
}