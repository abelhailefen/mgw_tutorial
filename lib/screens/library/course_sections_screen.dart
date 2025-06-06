// lib/screens/library/course_sections_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/section.dart';
import 'package:mgw_tutorial/provider/section_provider.dart';
import 'package:mgw_tutorial/screens/library/lesson_list_screen.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';


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
    // Fetch sections when the screen is first built (cache-first display, then network fetch)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SectionProvider>(context, listen: false)
          .fetchSectionsForCourse(widget.course.id);
    });
  }

  Future<void> _refreshSections() async {
    print("CourseSectionsScreen: Swipe refresh triggered.");
    await Provider.of<SectionProvider>(context, listen: false)
        .fetchSectionsForCourse(widget.course.id, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final List<Section> sections = sectionProvider.sectionsForCourse(widget.course.id);
    final bool isLoading = sectionProvider.isLoadingForCourse(widget.course.id);
    final String? error = sectionProvider.errorForCourse(widget.course.id);

    // Determine if we should show a full-screen loading/error/empty state
    // This happens when the 'sections' list is empty AND we are loading or have a critical error.
    // If 'sections' is NOT empty, we show the list regardless, potentially with a refresh indicator showing loading.
    bool showFullScreenMessage = sections.isEmpty && (isLoading || error != null);
    bool showEmptyState = sections.isEmpty && !isLoading && error == null;

    Widget bodyContent;

    if (showFullScreenMessage) {
       if (isLoading) {
          bodyContent = Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
       } else if (error != null) {
          bodyContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    l10n.failedToLoadChaptersError(error), // Use the provided error message
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.refresh),
                      onPressed: isLoading ? null : _refreshSections, // Disable if already loading
                    ),
                  )
                ],
              ),
            ),
         );
       } else {
          // This case should ideally not happen if showFullScreenMessage is true
          bodyContent = const SizedBox.shrink();
       }
    } else if (showEmptyState) {
       bodyContent = Center(
         child: Padding(
           padding: const EdgeInsets.all(20.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(Icons.search_off_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
               const SizedBox(height: 16),
               Text(
                 l10n.noChaptersForCourse,
                 textAlign: TextAlign.center,
                 style: theme.textTheme.titleMedium,
               ),
                const SizedBox(height: 20),
                 ElevatedButton.icon( // Add refresh button here too
                   icon: const Icon(Icons.refresh),
                   label: Text(l10n.refresh),
                   onPressed: isLoading ? null : _refreshSections, // Disable if already loading
                 )
             ],
           )
         ),
       );
    }
    else {
      // Display the list of sections (even if isLoading is true, the RefreshIndicator will show)
      bodyContent = ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: sections.length,
        itemBuilder: (ctx, index) {
          final section = sections[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Text('${section.order ?? index + 1}'),
              ),
              title: Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.6)),
              onTap: () {
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
    }


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSections,
        color: theme.colorScheme.primary, // Color of the spinning indicator
        backgroundColor: theme.colorScheme.surface, // Background color of the indicator area
        notificationPredicate: (notification) {
           // Add condition to allow refresh only if not already loading
           // This prevents multiple refreshes while one is in progress
           return notification.depth == 0 && !sectionProvider.isLoadingForCourse(widget.course.id);
        },
        child: bodyContent, // Wrap the determined body content
      ),
    );
  }
}