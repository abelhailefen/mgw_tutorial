// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/semesters_card.dart';
import 'package:mgw_tutorial/widgets/home/notes_card.dart'; // This import seems unused in the provided code
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
// Import the new animated item widget
import 'package:mgw_tutorial/widgets/common/animated_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SemesterProvider>(context, listen: false).fetchSemesters());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<SemesterProvider>(
              builder: (context, semesterProvider, child) {
                if (semesterProvider.isLoading && semesterProvider.semesters.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (semesterProvider.error != null && semesterProvider.semesters.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            semesterProvider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => semesterProvider.fetchSemesters(forceRefresh: true),
                            child: Text(l10n.refresh),
                          )
                        ],
                      ),
                    ),
                  );
                }
                if (semesterProvider.semesters.isEmpty && !semesterProvider.isLoading) {
                  return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50.0),
                        child: Text(
                            l10n.appTitle.contains("መጂወ") ? "በአሁኑ ሰዓት ምንም ሴሚስተሮች የሉም።" : 'No semesters available at the moment.',
                            style: theme.textTheme.titleMedium
                        ),
                      ));
                }

                // Wrap each SemesterCard with AnimatedListItem
                return Column(
                  children: semesterProvider.semesters.map((semester) {
                    // Use ValueKey for proper list item animation state management
                    return AnimatedListItem(
                      key: ValueKey(semester.id), // Assuming Semester model has an 'id'
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SemestersCard(
                          semester: semester,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
           
           
          ],
        ),
      ),
    );
  }
}