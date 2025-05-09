import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
//import 'package:flutter_localizations/flutter_localizations.dart';
//import 'packagepackage:mgw_tutorial/generated/app_localizations.dart';
// App Screens
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:mgw_tutorial/screens/auth/signup_screen.dart';


import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';

// Library Screens
import 'package:mgw_tutorial/screens/library/subject_chapters_screen.dart';
import 'package:mgw_tutorial/screens/library/chapter_detail_screen.dart';

import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';


import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => LocaleProvider(), // Provide the LocaleProvider
      child: const MyApp(),
    ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    final localeProvider = Provider.of<LocaleProvider>(context);
    // Access the LocaleProvider 
    //final l10n = AppLocalizations.of(context)!;
   
    return MaterialApp(
      title: 'MGW Tutorial',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Accent color
        scaffoldBackgroundColor: const Color(0xFFE3E8FF), // Main background
        fontFamily: 'Poppins', // Default font

        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, 
          elevation: 1.0, 
          iconTheme: const IconThemeData(
            color: Colors.black, // Icons like back arrow, menu icon
          ),
          actionsIconTheme: const IconThemeData(
            color: Colors.black, // Action icons on the right
          ),
          titleTextStyle: const TextStyle(
            color: Colors.black, // Title text color
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          // Ensures status bar icons are visible on a light AppBar
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent, // Make status bar blend with AppBar
            statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
            statusBarBrightness: Brightness.light,   // For iOS (dark icons on light background)
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardTheme(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        ),
        
      ),
      debugShowCheckedModeBanner: false,
      
       // === Localization Setup ===
      locale: localeProvider.locale, // Use the locale from the provider
      localizationsDelegates: const [
        AppLocalizations.delegate, // Your app's specific localizations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('am', ''), // Amharic
        // Locale('om', ''), // Afaan Oromo 
      ],
      // ==========================
      
      home: const SignUpScreen(), // Start with MainScreen which includes BottomNav

      routes: {
        // Routes for Sidebar/Drawer items
        AboutUsScreen.routeName: (ctx) => const AboutUsScreen(),   
        SettingsScreen.routeName: (ctx) => const SettingsScreen(), 

        // Route for authentication flow (e.g., logout)
        '/signup': (ctx) => const SignUpScreen(),

        // Routes for Library content flow
        SubjectChaptersScreen.routeName: (ctx) {
          final subjectTitle = ModalRoute.of(ctx)!.settings.arguments as String;
          return SubjectChaptersScreen(subjectTitle: subjectTitle);
        },
        ChapterDetailScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return ChapterDetailScreen(
            subjectTitle: args['subjectTitle'] as String,
            chapter: args['chapter'] as Map<String, dynamic>,
          );
        },
      },
    );
  }
}