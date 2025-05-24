// lib/screens/library/library_content_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/library/course_card.dart';
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';import 'package:provider/provider.dart'; // Import Provider
import 'package:mgw_tutorial/provider/api_course_provider.dart'; // Import ApiCourseProvider


class LibraryContentView extends StatefulWidget {
  const LibraryContentView({super.key});

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView> {

  // Hardcoded data removed
  // late List<ApiCourse> _hardcodedCourses;

  @override
  void initState() {
    super.initState();
    // Fetching from provider is now enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses();
    });
  }

  Future<void> _refreshCourses() async {
    // Call provider to refresh
    await Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Use ApiCourseProvider
    final courseProvider = Provider.of<ApiCourseProvider>(context);
    final List<ApiCourse> displayCourses = courseProvider.courses;
    final bool isLoading = courseProvider.isLoading;
    final String? error = courseProvider.error;

    if (isLoading && displayCourses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && displayCourses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
              const SizedBox(height: 16),
              Text(
                "${l10n.appTitle.contains("መጂወ") ? "ኮርሶችን መጫን አልተሳካም።" : "Failed to load courses."}\n$error",
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: _refreshCourses,
              )
            ],
          ),
        ),
      );
    }

    if (displayCourses.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noCoursesAvailable, // Using existing localized string
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon( // Add refresh button here too for convenience
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
              onPressed: _refreshCourses,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator( // Added RefreshIndicator
      onRefresh: _refreshCourses,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          itemCount: displayCourses.length,
          itemBuilder: (context, index) {
            final course = displayCourses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: CourseCard(
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
      ),
    );
  }
}