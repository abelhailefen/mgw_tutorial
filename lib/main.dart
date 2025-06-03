// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // For initializeDateFormatting
import 'package:media_kit/media_kit.dart';
// Import AppColors
import 'package:mgw_tutorial/constants/color.dart';

// Providers
import 'package:mgw_tutorial/provider/faq_provider.dart'; 
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
import 'package:mgw_tutorial/screens/sidebar/faq_screen.dart';
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
import 'package:mgw_tutorial/screens/sidebar/my_courses_screen.dart'; // <<< ADD THIS IMPORT

// Models
import 'package:mgw_tutorial/models/post.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/models/semester.dart';

// Localization
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mgw_tutorial/l10n/ti_material_localizations.dart';

// ... rest of your main.dart code ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('am', null);
  await initializeDateFormatting('ti', null);
  await initializeDateFormatting('or', null);
  
  MediaKit.ensureInitialized();

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
        ChangeNotifierProvider(create: (context) => FaqProvider()),
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

  TextTheme _getTextThemeForLocale(TextTheme base, Color primaryTextColor, Color secondaryTextColor, Locale? currentLocale) {
    String fontFamily = 'Poppins';
    if (currentLocale != null) {
      if (['am', 'ti', 'or'].contains(currentLocale.languageCode)) {
        fontFamily = 'NotoSansEthiopic';
      }
    }

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      displayMedium: base.displayMedium?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      displaySmall: base.displaySmall?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      titleLarge: base.titleLarge?.copyWith(fontFamily: fontFamily, color: primaryTextColor, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontFamily: fontFamily, color: primaryTextColor, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(fontFamily: fontFamily, color: primaryTextColor, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontFamily, color: secondaryTextColor),
      bodySmall: base.bodySmall?.copyWith(fontFamily: fontFamily, color: secondaryTextColor),
      labelLarge: base.labelLarge?.copyWith(fontFamily: fontFamily, color: primaryTextColor, fontWeight: FontWeight.bold),
      labelMedium: base.labelMedium?.copyWith(fontFamily: fontFamily, color: primaryTextColor),
      labelSmall: base.labelSmall?.copyWith(fontFamily: fontFamily, color: secondaryTextColor),
    ).apply(
      bodyColor: primaryTextColor,
      displayColor: primaryTextColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentLocale = localeProvider.locale;

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

    final TextTheme finalTypographyLight = _getTextThemeForLocale(typographyLightBase, lightColorScheme.onSurface, lightColorScheme.onSurface.withOpacity(0.75), currentLocale);
    final TextTheme finalTypographyDark = _getTextThemeForLocale(typographyDarkBase, darkColorScheme.onSurface, darkColorScheme.onSurface.withOpacity(0.75), currentLocale);

    return MaterialApp(
      title: 'MGW Tutorial',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.from(colorScheme: lightColorScheme, textTheme: finalTypographyLight).copyWith(
        scaffoldBackgroundColor: lightColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackgroundLight,
          elevation: 1.0,
          iconTheme: IconThemeData(color: lightColorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: lightColorScheme.onSurface),
          titleTextStyle: finalTypographyLight.titleLarge?.copyWith(
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
            textStyle: finalTypographyLight.labelLarge?.copyWith(fontSize: 16),
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
          hintStyle: finalTypographyLight.bodyMedium?.copyWith(color: AppColors.inputHintLight),
          labelStyle: finalTypographyLight.bodyMedium?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardThemeData(
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
          selectedLabelStyle: finalTypographyLight.bodySmall,
          unselectedLabelStyle: finalTypographyLight.bodySmall?.copyWith(color: lightColorScheme.onSurface.withOpacity(0.6)),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surfaceLight,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: AppColors.iconLight,
          textColor: finalTypographyLight.bodyLarge?.color,
          titleTextStyle: finalTypographyLight.titleMedium,
          subtitleTextStyle: finalTypographyLight.bodySmall,
        ),
        dividerColor: lightColorScheme.outline.withOpacity(0.5),
        iconTheme: IconThemeData(color: AppColors.iconLight),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.chipBackgroundLight,
          labelStyle: finalTypographyLight.bodySmall?.copyWith(color: AppColors.chipLabelLight, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          secondarySelectedColor: lightColorScheme.secondary,
          selectedColor: lightColorScheme.primary,
          secondaryLabelStyle: finalTypographyLight.bodySmall?.copyWith(color: lightColorScheme.onSecondary),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfaceLight,
          textStyle: finalTypographyLight.bodyMedium
        ),
        dialogBackgroundColor: AppColors.surfaceLight,
      ),
      darkTheme: ThemeData.from(colorScheme: darkColorScheme, textTheme: finalTypographyDark).copyWith(
         scaffoldBackgroundColor: darkColorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackgroundDark,
          elevation: 1.0,
          iconTheme: IconThemeData(color: darkColorScheme.onSurface),
          actionsIconTheme: IconThemeData(color: darkColorScheme.onSurface),
          titleTextStyle: finalTypographyDark.titleLarge?.copyWith(
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
            textStyle: finalTypographyDark.labelLarge?.copyWith(fontSize: 16),
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
          hintStyle: finalTypographyDark.bodyMedium?.copyWith(color: AppColors.inputHintDark),
          labelStyle: finalTypographyDark.bodyMedium?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        ),
        cardTheme: CardThemeData(
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
          selectedLabelStyle: finalTypographyDark.bodySmall,
          unselectedLabelStyle: finalTypographyDark.bodySmall?.copyWith(color: darkColorScheme.onSurface.withOpacity(0.6)),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.surfaceDark,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: AppColors.iconDark,
          textColor: finalTypographyDark.bodyLarge?.color,
          titleTextStyle: finalTypographyDark.titleMedium,
          subtitleTextStyle: finalTypographyDark.bodySmall,
        ),
        dividerColor: darkColorScheme.outline.withOpacity(0.5),
        iconTheme: IconThemeData(color: AppColors.iconDark),
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surfaceDark,
          textStyle: finalTypographyDark.bodyMedium
        ),
        dialogBackgroundColor: AppColors.surfaceDark,
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.chipBackgroundDark,
          labelStyle: finalTypographyDark.bodySmall?.copyWith(color: AppColors.chipLabelDark, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          secondarySelectedColor: darkColorScheme.secondary,
          selectedColor: darkColorScheme.primary,
          secondaryLabelStyle: finalTypographyDark.bodySmall?.copyWith(color: darkColorScheme.onSecondary),
        ),
      ),
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        TiMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
      routes: {
        '/main': (ctx) => const MainScreen(),
        '/login': (ctx) => const LoginScreen(),
        AboutUsScreen.routeName: (ctx) => const AboutUsScreen(),
        SettingsScreen.routeName: (ctx) => const SettingsScreen(),
        DiscussionGroupScreen.routeName: (ctx) => const DiscussionGroupScreen(),
        CreatePostScreen.routeName: (ctx) => const CreatePostScreen(),
        TestimonialsScreen.routeName: (ctx) => const TestimonialsScreen(),
        MyCoursesScreen.routeName: (ctx) => const MyCoursesScreen(), // <<< ROUTE IS CORRECTLY DEFINED
        FaqScreen.routeName: (ctx) => const FaqScreen(),
        OrderScreen.routeName: (ctx) {
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