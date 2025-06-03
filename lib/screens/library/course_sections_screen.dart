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
    // Fetch sections when the screen is first built (cache-first, then network)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SectionProvider>(context, listen: false)
          .fetchSectionsForCourse(widget.course.id);
    });
  }

  Future<void> _refreshSections() async {
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

    // Show loading indicator if data is being fetched and no data is currently displayed
    if (isLoading && sections.isEmpty) {
      return Scaffold( // Need a Scaffold to show loading indicator
         appBar: AppBar(title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle)),
         body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message and retry button if there's an error and no data
    if (error != null && sections.isEmpty) {
      return Scaffold( // Need a Scaffold to show error message
         appBar: AppBar(title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle)),
         body: Center(
           child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                 const SizedBox(height: 16),
                 Text(
                   l10n.failedToLoadChaptersError(error!),
                   textAlign: TextAlign.center,
                   style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                 ),
                 const SizedBox(height: 20),
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     icon: const Icon(Icons.refresh),
                     label: Text(l10n.refresh),
                     onPressed: _refreshSections,
                   ),
                 )
               ],
             ),
           ),
         ),
      );
    }

    // Show message if no sections are found for the course
    if (sections.isEmpty && !isLoading) {
      return Scaffold( // Need a Scaffold to show "no data" message
         appBar: AppBar(title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle)),
         body: Center(
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
                     onPressed: _refreshSections,
                   )
               ],
             )
           ),
         ),
      );
    }

    // Display the list of sections
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.chaptersTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSections,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: ListView.builder(
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
        ),
      ),
    );
  }
}