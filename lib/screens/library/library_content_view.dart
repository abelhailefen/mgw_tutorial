// lib/screens/library/library_content_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/library/course_card.dart';
import 'package:mgw_tutorial/screens/library/course_sections_screen.dart';
import 'package:mgw_tutorial/models/api_course.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// Temporarily remove ApiCourseProvider if using hardcoded data
// import 'package:provider/provider.dart';
// import 'package:mgw_tutorial/provider/api_course_provider.dart';


class LibraryContentView extends StatefulWidget {
  const LibraryContentView({super.key});

  @override
  State<LibraryContentView> createState() => _LibraryContentViewState();
}

class _LibraryContentViewState extends State<LibraryContentView> {

  ApiCourse _createMockCourse(int id, String title, String shortDesc, String thumbnailLetter) {
    // Ensure all required fields for ApiCourse are provided or nullable in the model
    return ApiCourse(
      id: id,
      title: title,
      shortDescription: shortDesc,
      description: "This is a placeholder for course ID $id. Sections and lessons should load if the APIs for sections (course ID $id) and subsequent lessons are working.",
      outcomes: ["Outcome A for $id", "Outcome B for $id"],
      requirements: ["Requirement for $id"],
      price: (id % 2 == 0) ? "0.00" : "50.00",
      status: "published",
      createdAt: DateTime.now().subtract(Duration(days: id + 5)),
      updatedAt: DateTime.now().subtract(Duration(days: id)),
      thumbnail: "https://via.placeholder.com/600x300.png?text=Course+$thumbnailLetter",
      isFreeCourse: id % 2 == 0,
      // Add other nullable or default fields as needed by your ApiCourse model
      // categoryId: null,
      // section: null,
      // language: null,
      // videoUrl: null,
      // discountFlag: null,
      // discountedPrice: null,
      // isTopCourse: null,
      // isVideoCourse: null,
      // multiInstructor: null,
      // creator: null,
      // category: null,
    );
  }

  late List<ApiCourse> _hardcodedCourses;

  @override
  void initState() {
    super.initState();
    _hardcodedCourses = [
      _createMockCourse(38, "Course Alpha (ID 38)", "Content for course 38", "A"),
      _createMockCourse(0, "Course Beta (ID 0)", "Content for course 0", "B"),
      _createMockCourse(40, "Course Gamma (ID 40)", "Content for course 40", "G"),
      _createMockCourse(41, "Course Delta (ID 41)", "Content for course 41", "D"),
    ];

    // Fetching from provider is disabled
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses();
    // });
  }

  // Future<void> _refreshCourses() async { // Disabled
  //   // Provider.of<ApiCourseProvider>(context, listen: false).fetchCourses(forceRefresh: true);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Refresh disabled (using hardcoded courses)."))
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Use hardcoded courses for now
    final List<ApiCourse> displayCourses = _hardcodedCourses;

    // Code for provider (when re-enabled)
    // final courseProvider = Provider.of<ApiCourseProvider>(context);
    // final List<ApiCourse> displayCourses = courseProvider.courses;
    // final bool isLoading = courseProvider.isLoading;
    // final String? error = courseProvider.error;

    // if (isLoading && displayCourses.isEmpty) {
    //   return const Center(child: CircularProgressIndicator());
    // }
    // if (error != null && displayCourses.isEmpty) {
    //   return Center(
    //     child: Padding(
    //       padding: const EdgeInsets.all(20.0),
    //       child: Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
    //           const SizedBox(height: 16),
    //           Text(
    //             "${l10n.appTitle.contains("መጂወ") ? "ኮርሶችን መጫን አልተሳካም።" : "Failed to load courses."}\n$error",
    //             textAlign: TextAlign.center,
    //             style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
    //           ),
    //           const SizedBox(height: 20),
    //           ElevatedButton.icon(
    //             icon: const Icon(Icons.refresh),
    //             label: Text(l10n.refresh),
    //             onPressed: _refreshCourses,
    //           )
    //         ],
    //       ),
    //     ),
    //   );
    // }

    if (displayCourses.isEmpty /*&& !isLoading (when using provider)*/) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle.contains("መጂወ") ? "ምንም ኮርሶች የሉም።" : "No courses available at the moment.",
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    );
  }
}