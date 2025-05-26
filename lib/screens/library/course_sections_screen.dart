// lib/screens/library/course_sections_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/provider/section_provider.dart';
import 'package:mgw_tutorial/screens/library/lesson_list_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class CourseSectionsScreen extends StatefulWidget {
  static const routeName = '/course-sections';
  final ApiCourse course;

  const CourseSectionsScreen({super.key, required this.course});

  @override
  State<CourseSectionsScreen> createState() => _CourseSectionsScreenState();
}

class _CourseSectionsScreenState extends State<CourseSectionsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch sections when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SectionProvider>(context, listen: false)
          .fetchSectionsForCourse(widget.course.id);
    });
  }

  // Method to refresh sections, used by RefreshIndicator and button
  Future<void> _refreshSections() async {
    await Provider.of<SectionProvider>(context, listen: false)
        .fetchSectionsForCourse(widget.course.id, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Watch the provider for state changes related to this course's sections
    final sectionProvider = Provider.of<SectionProvider>(context);
    final List<Section> sections = sectionProvider.sectionsForCourse(widget.course.id);
    final bool isLoading = sectionProvider.isLoadingForCourse(widget.course.id);
    final String? error = sectionProvider.errorForCourse(widget.course.id);

    return Scaffold(
      appBar: AppBar(
        // Use the course title if available, otherwise use localized "Chapters"
        title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSections,
        color: theme.colorScheme.primary, // Refresh indicator color
        backgroundColor: theme.colorScheme.surface, // Refresh indicator background
        child: Builder( // Builder is good practice inside RefreshIndicator
          builder: (context) {
            // Show loading indicator if data is being fetched and no data is currently displayed
            if (isLoading && sections.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show error message and retry button if there's an error and no data
            if (error != null && sections.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches children horizontally (for button)
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      // Use localized error message with the dynamic error detail
                      Text(
                        l10n.failedToLoadChaptersError(error!), // Pass the error detail as a positional argument
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      SizedBox( // Wrap button in SizedBox to control width
                        width: double.infinity, // Make button fill width of parent Column (due to stretch)
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.refresh), // Use localized refresh text
                          onPressed: _refreshSections,
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
            // Show message if no sections are found for the course
            if (sections.isEmpty && !isLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column( // Added Column for icon + text
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      // Use localized "No chapters found" message
                      Text(
                        l10n.noChaptersForCourse,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  )
                ),
              );
            }

            // Display the list of sections
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sections.length,
              itemBuilder: (ctx, index) {
                final section = sections[index];
                return Card( // Uses CardTheme (defined in your ThemeData)
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  // Card properties like elevation and shape can be inherited from CardTheme
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: Text('${section.order ?? index + 1}'), // Use order if available, otherwise index + 1
                    ),
                    title: Text(
                      section.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.6)),
                    onTap: () {
                      // Navigate to the LessonListScreen for the selected section
                      Navigator.pushNamed(
                        context,
                        LessonListScreen.routeName,
                        arguments: section,
                      );
                      print('Tapped on section: ${section.title} (ID: ${section.id})');
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}