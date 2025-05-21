// lib/screens/library/course_sections_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:mgw_tutorial/models/section_model.dart'; // Import Section model
import 'package:mgw_tutorial/provider/section_provider.dart'; // Import SectionProvider
import 'package:mgw_tutorial/screens/library/chapter_detail_screen.dart'; // This will be renamed to LessonListScreen

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
    _fetchCourseSectionsData();
  }

  Future<void> _fetchCourseSectionsData({bool forceRefresh = false}) async {
    // Use Future.microtask if calling from initState directly, otherwise it's fine
    // if context is already available (e.g. from a button press)
    // For initState, it's safer to ensure the first build completes.
    Future.microtask(() {
      Provider.of<SectionProvider>(context, listen: false)
          .fetchSectionsForCourse(widget.course.id, forceRefresh: forceRefresh);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SectionProvider for changes specific to this course's sections
    final sectionProvider = Provider.of<SectionProvider>(context);
    final List<Section> sections = sectionProvider.sectionsForCourse(widget.course.id);
    final bool isLoading = sectionProvider.isLoadingForCourse(widget.course.id);
    final String? error = sectionProvider.errorForCourse(widget.course.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchCourseSectionsData(forceRefresh: true),
        child: Builder( // Use Builder to ensure context for ScaffoldMessenger is correct if needed
          builder: (context) {
            if (isLoading && sections.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && sections.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load sections for this course. Please try again.', // TODO: Localize
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                      ),
                    ),
                    // Text(error, style: TextStyle(fontSize: 12, color: Colors.grey)), // Optional: show detailed error
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Sections'), // TODO: Localize
                      onPressed: () => _fetchCourseSectionsData(forceRefresh: true),
                    ),
                  ],
                ),
              );
            }

            if (sections.isEmpty && !isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_books_outlined, size: 70, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No chapters/sections available for "${widget.course.title}" yet.', // TODO: Localize
                       textAlign: TextAlign.center,
                       style: const TextStyle(fontSize: 16),
                    ),
                  ],
                )
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: sections.length,
              itemBuilder: (ctx, index) {
                final section = sections[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  elevation: 2.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      foregroundColor: Theme.of(context).primaryColor,
                      child: Text('${section.order ?? index + 1}'), // Use section.order if available
                    ),
                    title: Text(
                      section.title,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16.5),
                    ),
                    // You could add a subtitle here if sections have descriptions or lesson counts
                    // subtitle: Text('${section.lessonCount ?? 0} lessons'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      // Navigate to LessonListScreen (currently ChapterDetailScreen)
                      // Pass the actual Section object
                      Navigator.pushNamed(
                        context,
                        ChapterDetailScreen.routeName, // Will be renamed to LessonListScreen.routeName
                        arguments: {
                          // 'subjectTitle': section.title, // Pass section title or course title
                          // For ChapterDetailScreen, it expects 'subjectTitle' and 'chapter' map
                          'subjectTitle': widget.course.title, // Course title as main subject
                          'chapter': { // This is now representing the *Section*
                            'id': section.id.toString(), // Ensure ID is string if ChapterDetailScreen expects it
                            'title': section.title,
                            // Mock data for ChapterDetailScreen's existing structure
                            // This will be replaced when LessonListScreen is implemented
                            'videos': [],
                            'notes': 'Content for ${section.title} will be loaded here.',
                            'pdfs': [],
                            'exams': [],
                          },
                        },
                      );
                      print('Tapped on section: ${section.title} (ID: ${section.id}) for course ${widget.course.id}');
                    },
                  ),
                );
              },
            );
          }
        ),
      ),
    );
  }
}