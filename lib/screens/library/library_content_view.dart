// lib/screens/library/library_content_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/library/course_card.dart';
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/models/api_course.dart'; // Import your ApiCourse model
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';


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
      // Fetch courses when the view is first built, will load from DB then network
      // listen: false is correct in initState
      Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses();
    });
  }

  Future<void> _refreshCourses() async {
    // forceRefresh: true ensures it bypasses initial DB load check and fetches from network
    await Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Use Provider.of to listen for state changes
    final courseProvider = Provider.of<ApiCourseProvider>(context);
    // Use the courses list directly from the provider
    final List<ApiCourse> displayCourses = courseProvider.courses;
    final bool isLoading = courseProvider.isLoading;
    final String? error = courseProvider.error;

    // Display loading indicator ONLY if courses list is currently empty AND we are loading
    // This allows cached data to remain visible while a background refresh happens
    if (isLoading && displayCourses.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    // Display error message ONLY if courses list is currently empty AND there's an error
    // If error is NOT null but displayCourses is NOT empty, it means a network
    // error occurred AFTER loading cached data. The UI can handle this differently
    // (e.g., a transient banner) but here we only show the full error screen
    // if no data is available at all.
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
                // Display the error string from the provider.
                // The provider should format it using l10n if it has access,
                // otherwise it's a generic message + API detail.
                // Keeping your language check logic for robustness with old error strings
                 l10n.appTitle.contains("መጂወ") && error!.contains("Failed to load courses") ?
                 "ኮርሶችን መጫን አልተሳካም።\n$error" :
                 error!, // Use error directly if not matching the specific Amharic case
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
                onPressed: isLoading ? null : _refreshCourses, // Disable refresh button if already loading
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

    // Display message if no courses are available (neither from DB nor successful network fetch)
    // and we are not currently loading, and there is no error (meaning loaded empty)
    if (displayCourses.isEmpty && !isLoading && error == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noCoursesAvailable, // Existing key
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refresh), // Existing key
              onPressed: isLoading ? null : _refreshCourses, // Disable refresh button if already loading
              style: ElevatedButton.styleFrom(
                 backgroundColor: theme.colorScheme.primary,
                 foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    // Display the list of courses if there are any
    // The RefreshIndicator allows pulling down to trigger _refreshCourses
    return RefreshIndicator(
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
                course: course, // Pass the ApiCourse object
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    CourseSectionsScreen.routeName,
                    arguments: course, // Pass the course object to sections screen
                  );
                },
              ),
            );
          },
      ),
    );
  }
}