// lib/screens/sidebar/my_courses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/widgets/library/course_card.dart'; // Reusing CourseCard
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class MyCoursesScreen extends StatefulWidget {
  static const routeName = '/my-courses';
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure all courses are fetched if not already
    // This is important because we need the full course details to display
    Future.microtask(() {
      Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses();
    });
  }

  Future<void> _refreshMyCourses() async {
    // Refreshing all courses might be needed if new enrollments happened elsewhere
    // or if course details changed.
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Optionally, re-fetch user data if enrollment status can change dynamically
    // await authProvider.fetchCurrentUserDetails(); // If you have such a method
    await Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final apiCourseProvider = Provider.of<ApiCourseProvider>(context);

    if (authProvider.currentUser == null) {
      // Should ideally not happen if route is protected, but good to handle
      return Scaffold(
        appBar: AppBar(title: Text(l10n.mycourses)),
        body: Center(child: Text(l10n.pleaseLoginOrRegister)),
      );
    }

    final List<int> enrolledIds = authProvider.currentUser?.enrolledCourseIds ?? [];
    final List<ApiCourse> allCourses = apiCourseProvider.courses;
    final bool isLoadingAllCourses = apiCourseProvider.isLoading;
    final String? errorLoadingAllCourses = apiCourseProvider.error;

    List<ApiCourse> myCourses = [];
    if (allCourses.isNotEmpty && enrolledIds.isNotEmpty) {
      myCourses = allCourses.where((course) => enrolledIds.contains(course.id)).toList();
    }

    Widget content;

    if (isLoadingAllCourses && allCourses.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorLoadingAllCourses != null && allCourses.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
              const SizedBox(height: 16),
              Text(
                "${l10n.appTitle.contains("መጂወ") ? "ኮርሶችን መጫን አልተሳካም።" : "Failed to load course data."}\n$errorLoadingAllCourses",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: _refreshMyCourses,
              )
            ],
          ),
        ),
      );
    } else if (enrolledIds.isEmpty) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.appTitle.contains("መጂወ") ? "እስካሁን ምንም ኮርስ አልተመዘገቡም።" : "You are not enrolled in any courses yet.",
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle.contains("መጂወ") ? "ที่มีอยู่ ኮርሶችን ከቤተ-መጽሐፍት ያስሱ።" : "Explore available courses from the library.", // TODO: Better Amharic for "available"
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              // Optionally add a button to navigate to the Library or Home screen
            ],
          ),
        ),
      );
    } else if (allCourses.isNotEmpty && myCourses.isEmpty && !isLoadingAllCourses) {
        // This case means user has enrolled IDs, but those courses are not in the fetched allCourses list
        content = Center(
           child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.search_off_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                        l10n.appTitle.contains("መጂወ") ? "የተመዘገቡባቸው ኮርሶች በአሁኑ ጊዜ አይገኙም።" : "Your enrolled courses are not currently available.",
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                        l10n.appTitle.contains("መጂወ") ? "እባክዎ ቆይተው እንደገና ይሞክሩ ወይም አስተዳዳሪውን ያግኙ።" : "Please try again later or contact support.",
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                        onPressed: _refreshMyCourses,
                    )
                ],
             ),
           ),
        );
    }
    else {
      content = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: myCourses.length,
        itemBuilder: (context, index) {
          final course = myCourses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CourseCard( // Reusing your existing CourseCard
              course: course,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  CourseSectionsScreen.routeName,
                  arguments: course,
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mycourses),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMyCourses,
        child: content,
      ),
    );
  }
}