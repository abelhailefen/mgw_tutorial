// screens/library/library_content_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/library/course_card.dart';
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
// Import the new animated item widget
import 'package:mgw_tutorial/widgets/common/animated_list_item.dart';


class LibraryContentView extends StatefulWidget {
  const LibraryContentView({super.key});

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Call fetchCourses without forceRefresh.
      // The provider will attempt network first, show loading if needed,
      // and fall back to DB if network fails.
      Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses();
    });
  }

  Future<void> _refreshCourses() async {
    // Pull-to-refresh should force a network refresh
    await Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final courseProvider = Provider.of<ApiCourseProvider>(context);
    final List<ApiCourse> displayCourses = courseProvider.courses;
    final bool isLoading = courseProvider.isLoading;
    final String? error = courseProvider.error;

    // Show loading indicator if currently loading AND there are no courses to display yet
    if (isLoading && displayCourses.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    // Show error message if an error occurred AND there are no courses to display
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
                 l10n.appTitle.contains("መጂወ") && error.contains("Failed to load courses") ?
                 "ኮርሶችን መጫን አልተሳካም።\n$error" :
                 error,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: isLoading ? null : _refreshCourses,
                style: ElevatedButton.styleFrom(
                   backgroundColor: theme.colorScheme.primary,
                   foregroundColor: theme.colorScheme.onPrimary,
                ),
              )
            ],
          ),
        ),
      );
    }

    // Show empty state if no courses are loaded, not loading, and no error
    if (displayCourses.isEmpty && !isLoading && error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noCoursesAvailable,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh),
              onPressed: isLoading ? null : _refreshCourses,
              style: ElevatedButton.styleFrom(
                 backgroundColor: theme.colorScheme.primary,
                 foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    // Display courses if available
    return RefreshIndicator(
      onRefresh: _refreshCourses,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          itemCount: displayCourses.length,
          itemBuilder: (context, index) {
            final course = displayCourses[index];
            // Wrap the item with the animated widget
            return AnimatedListItem(
              // Using ValueKey is good practice in lists with animations/stateful items
              key: ValueKey(course.id),
              child: Padding(
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
              ),
            );
          },
      ),
    );
  }
}