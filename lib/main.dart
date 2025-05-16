import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // <<< THIS LINE IS CRUCIAL AND WAS LIKELY MISSING OR INCORRECT

// Providers (these are your specific provider classes)
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';

// Screens
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/discussion_group_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/create_post_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/post_detail_screen.dart';
import 'package:mgw_tutorial/screens/library/subject_chapters_screen.dart';
import 'package:mgw_tutorial/screens/library/chapter_detail_screen.dart';

// Models (only if directly used for arguments like Post)
import 'package:mgw_tutorial/models/post.dart';

// Localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    MultiProvider( // This comes from 'package:provider/provider.dart'
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),     // This too
        ChangeNotifierProvider(create: (context) => SemesterProvider()),   // This too
        ChangeNotifierProvider(create: (context) => AuthProvider()),       // This too
        ChangeNotifierProvider(create: (context) => DepartmentProvider()), // This too
        ChangeNotifierProvider(create: (context) => DiscussionProvider()), // This too
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context); // Provider.of also from 'package:provider/provider.dart'

    return MaterialApp(
      title: 'MGW Tutorial',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE3E8FF),
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1.0,
          iconTheme: const IconThemeData(color: Colors.black),
          actionsIconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardTheme(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        ),
      ),
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('am', ''),
      ],
      home: const LoginScreen(),
      routes: {
        '/main': (ctx) => const MainScreen(),
        AboutUsScreen.routeName: (ctx) => const AboutUsScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
        DiscussionGroupScreen.routeName: (ctx) => const DiscussionGroupScreen(),
        CreatePostScreen.routeName: (ctx) => const CreatePostScreen(),
        '/login': (ctx) => const LoginScreen(),
        PostDetailScreen.routeName: (ctx) {
          final post = ModalRoute.of(ctx)!.settings.arguments as Post;
          return PostDetailScreen(post: post);
        },
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