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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title.isNotEmpty ? widget.course.title : l10n.appTitle.contains("መጂወ") ? "ምዕራፎች" : "Chapters"),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSections,
        color: theme.colorScheme.primary, // Refresh indicator color
        backgroundColor: theme.colorScheme.surface, // Refresh indicator background
        child: Builder(
          builder: (context) {
            if (isLoading && sections.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && sections.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle.contains("መጂወ") ? "ምዕራፎችን መጫን አልተሳካም።\n$error" : "Failed to load chapters.\n$error",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                        onPressed: _refreshSections,
                      )
                    ],
                  ),
                ),
              );
            }
            if (sections.isEmpty && !isLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column( // Added Column for icon + text
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle.contains("መጂወ") ? "ለዚህ ኮርስ ምንም ምዕራፎች አልተገኙም።" : "No chapters found for this course.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  )
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sections.length,
              itemBuilder: (ctx, index) {
                final section = sections[index];
                return Card( // Uses CardTheme
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  // elevation: 2.5, // From CardTheme
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // From CardTheme
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
          },
        ),
      ),
    );
  }
}