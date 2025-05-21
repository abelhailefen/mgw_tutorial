// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Import AppColors
import 'package:mgw_tutorial/constants/color.dart';

// Providers
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
import 'package:mgw_tutorial/provider/section_provider.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/provider/theme_provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/order_provider.dart';


// Screens
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/discussion_group_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/create_post_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/post_detail_screen.dart';
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/screens/library/lesson_list_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/testimonials_screen.dart';
import 'package:mgw_tutorial/screens/enrollment/order_screen.dart';

// Models
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/models/semester.dart'; // <<< ADDED IMPORT

// Localization
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => SemesterProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => DepartmentProvider()),
        ChangeNotifierProvider(create: (context) => ApiCourseProvider()),
        ChangeNotifierProvider(create: (context) => SectionProvider()),
        ChangeNotifierProvider(create: (context) => LessonProvider()),
        ChangeNotifierProvider(create: (context) => TestimonialProvider()),
        ChangeNotifierProvider(create: (context) => OrderProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DiscussionProvider>(
          create: (context) => DiscussionProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previousDiscussionProvider) =>
              DiscussionProvider(auth),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  TextTheme _poppinsTextTheme(TextTheme base, Color primaryTextColor, Color secondaryTextColor) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      displayMedium: base.displayMedium?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Poppins', color: primaryTextColor, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Poppins', color: primaryTextColor, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Poppins', color: primaryTextColor, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Poppins', color: secondaryTextColor),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Poppins', color: secondaryTextColor),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Poppins', color: primaryTextColor, fontWeight: FontWeight.bold),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Poppins', color: primaryTextColor),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Poppins', color: secondaryTextColor),
    ).apply(
      bodyColor: primaryTextColor,
      displayColor: primaryTextColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    const lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.onPrimaryContainerLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onPrimaryLight,
      secondaryContainer: AppColors.secondaryContainerLight,
      onSecondaryContainer: AppColors.onSecondaryContainerLight,
      tertiary: AppColors.secondaryLight,
      onTertiary: AppColors.onPrimaryLight,
      tertiaryContainer: AppColors.secondaryContainerLight,
      onTertiaryContainer: AppColors.onSecondaryContainerLight,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      background: AppColors.backgroundLight,
      onBackground: AppColors.onSurfaceLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceVariant: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.onSurfaceVariantLight,
      outline: AppColors.outlineLight,
      shadow: Colors.black26,
      inverseSurface: AppColors.surfaceDark,
      onInverseSurface: AppColors.onSurfaceDark,
      inversePrimary: AppColors.primaryDark,
    );

    const darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onPrimaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
      tertiary: AppColors.secondaryDark,
      onTertiary: AppColors.onPrimaryDark,
      tertiaryContainer: AppColors.secondaryContainerDark,
      onTertiaryContainer: AppColors.onSecondaryContainerDark,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      background: AppColors.backgroundDark,
      onBackground: AppColors.onSurfaceDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceVariant: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      shadow: Colors.black45,
      inverseSurface: AppColors.surfaceLight,
      onInverseSurface: AppColors.onSurfaceLight,
      inversePrimary: AppColors.primaryLight,
    );

    final TextTheme typographyLightBase = Typography.material2021(platform: TargetPlatform.android).black.copyWith(
      bodyLarge: Typography.material2021(platform: TargetPlatform.android).black.bodyLarge?.copyWith(color: lightColorScheme.onSurface),
      bodyMedium: Typography.material2021(platform: TargetPlatform.android).black.bodyMedium?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.75)),
      bodySmall: Typography.material2021(platform: TargetPlatform.android).black.bodySmall?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.60)),
    );

    final TextTheme typographyDarkBase = Typography.material2021(platform: TargetPlatform.android).white.copyWith(
      bodyLarge: Typography.material2021(platform: TargetPlatform.android).white.bodyLarge?.copyWith(color: darkColorScheme.onSurface),
      bodyMedium: Typography.material2021(platform: TargetPlatform.android).white.bodyMedium?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.75)),
      bodySmall: Typography.material2021(platform: TargetPlatform.android).white.bodySmall?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.60)),
    );

    final TextTheme poppinsTypographyLight = _poppinsTextTheme(typographyLightBase, lightColorScheme.onSurface, lightColorScheme.onSurface.withOpacity(0.75));
    final TextTheme poppinsTypographyDark = _poppinsTextTheme(typographyDarkBase, darkColorScheme.onSurface, darkColorScheme.onSurface.withOpacity(0.75));

    return MaterialApp(
      title: 'MGW Tutorial',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.from(colorScheme: lightColorScheme, textTheme: poppinsTypographyLight).copyWith(
        scaffoldBackgroundColor: lightColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackgroundLight,
          elevation: 1.0,
          iconTheme: IconThemeData(color: lightColorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: lightColorScheme.onSurface),
          titleTextStyle: poppinsTypographyLight.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: poppinsTypographyLight.labelLarge?.copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: lightColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: lightColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 2.0),
          ),
          filled: true,
          fillColor: AppColors.inputFillLight,
          hintStyle: poppinsTypographyLight.bodyMedium?.copyWith(color: AppColors.inputHintLight),
          labelStyle: poppinsTypographyLight.bodyMedium?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardTheme(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          color: AppColors.cardBackgroundLight,
        ),
         bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          selectedItemColor: lightColorScheme.primary,
          unselectedItemColor: lightColorScheme.onSurface.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: poppinsTypographyLight.bodySmall,
          unselectedLabelStyle: poppinsTypographyLight.bodySmall?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.6)),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surfaceLight,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: AppColors.iconLight,
          textColor: poppinsTypographyLight.bodyLarge?.color,
          titleTextStyle: poppinsTypographyLight.titleMedium,
          subtitleTextStyle: poppinsTypographyLight.bodySmall,
        ),
        dividerColor: lightColorScheme.outline.withOpacity(0.5),
        iconTheme: IconThemeData(color: AppColors.iconLight),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.chipBackgroundLight,
          labelStyle: poppinsTypographyLight.bodySmall?.copyWith(color: AppColors.chipLabelLight, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          secondarySelectedColor: lightColorScheme.secondary,
          selectedColor: lightColorScheme.primary,
          secondaryLabelStyle: poppinsTypographyLight.bodySmall?.copyWith(color: lightColorScheme.onSecondary),
        ),
      ),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme, textTheme: poppinsTypographyDark).copyWith(
        scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackgroundDark,
          elevation: 1.0,
          iconTheme: IconThemeData(color: darkColorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: darkColorScheme.onSurface),
          titleTextStyle: poppinsTypographyDark.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: poppinsTypographyDark.labelLarge?.copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: darkColorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: darkColorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2.0),
          ),
          filled: true,
          fillColor: AppColors.inputFillDark,
          hintStyle: poppinsTypographyDark.bodyMedium?.copyWith(color: AppColors.inputHintDark),
          labelStyle: poppinsTypographyDark.bodyMedium?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardTheme(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          color: AppColors.cardBackgroundDark,
        ),
         bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: darkColorScheme.primary,
          unselectedItemColor: darkColorScheme.onSurface.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: poppinsTypographyDark.bodySmall,
          unselectedLabelStyle: poppinsTypographyDark.bodySmall?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.6)),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surfaceDark,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: AppColors.iconDark,
          textColor: poppinsTypographyDark.bodyLarge?.color,
          titleTextStyle: poppinsTypographyDark.titleMedium,
          subtitleTextStyle: poppinsTypographyDark.bodySmall,
        ),
        dividerColor: darkColorScheme.outline.withOpacity(0.5),
        iconTheme: IconThemeData(color: AppColors.iconDark),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfaceDark,
          textStyle: poppinsTypographyDark.bodyMedium
        ),
        dialogBackgroundColor: AppColors.surfaceDark,
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.chipBackgroundDark,
          labelStyle: poppinsTypographyDark.bodySmall?.copyWith(color: AppColors.chipLabelDark, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          secondarySelectedColor: darkColorScheme.secondary,
          selectedColor: darkColorScheme.primary,
          secondaryLabelStyle: poppinsTypographyDark.bodySmall?.copyWith(color: darkColorScheme.onSecondary),
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
        Locale('or', ''),
      ],
      home: const LoginScreen(),
      routes: {
        '/main': (ctx) => const MainScreen(),
        '/login': (ctx) => const LoginScreen(),
        AboutUsScreen.routeName: (ctx) => const AboutUsScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
        DiscussionGroupScreen.routeName: (ctx) => const DiscussionGroupScreen(),
        CreatePostScreen.routeName: (ctx) => const CreatePostScreen(),
        TestimonialsScreen.routeName: (ctx) => const TestimonialsScreen(),
        OrderScreen.routeName: (ctx) { // Route for OrderScreen
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is Semester) {
            return OrderScreen(semesterToEnroll: args);
          }
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Error: Semester data not provided.")));
        },
        PostDetailScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is Post) {
            return PostDetailScreen(post: args);
          }
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Error: Invalid post data.")));
        },
        CourseSectionsScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is ApiCourse) {
            return CourseSectionsScreen(course: args);
          }
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Error: Invalid course data.")));
        },
        LessonListScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          if (args is Section) {
            return LessonListScreen(section: args);
          }
          return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Error: Invalid section data.")));
        },
      },
    );
  }
}