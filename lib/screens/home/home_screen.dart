// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/semesters_card.dart';
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
    // Use Future.microtask to avoid calling Provider.of in initState directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<SemesterProvider>(context, listen: false).fetchSemesters();
    });
  }

  Future<void> _refreshSemesters(BuildContext context) async {
     await Provider.of<SemesterProvider>(context, listen: false).fetchSemesters(forceRefresh: true);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Use Consumer directly in the body to control the entire content
    return Scaffold(
      body: Consumer<SemesterProvider>(
        builder: (context, semesterProvider, child) {
          final List<Semester> displaySemesters = semesterProvider.semesters;
          final bool isLoading = semesterProvider.isLoading;
          final String? error = semesterProvider.error;

          // --- Conditional Display Logic ---

          // 1. Show loading indicator if currently loading AND there are no semesters to display yet
          if (isLoading && displaySemesters.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          // 2. Show error message if an error occurred AND there are no semesters to display
          if (error != null && displaySemesters.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                     const SizedBox(height: 16),
                     Text(
                        // Localize the error message if needed, or just display the raw error
                        l10n.appTitle.contains("መጂወ") && error.contains(l10n.noSemestersAvailable) ?
                        "ሴሚስተሮችን መጫን አልተሳካም።\n$error" : // Example translation
                        error,
                       textAlign: TextAlign.center,
                       style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                     ),
                     const SizedBox(height: 20),
                     ElevatedButton.icon( // Using ElevatedButton.icon for consistency
                       icon: const Icon(Icons.refresh),
                       label: Text(l10n.refresh),
                       onPressed: isLoading ? null : () => _refreshSemesters(context), // Pass context
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

          // 3. Show empty state if no semesters are loaded, not loading, and no error
          if (displaySemesters.isEmpty && !isLoading && error == null) {
             return Center(
               child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 16.0), // Add horizontal padding
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)), // Example icon
                       const SizedBox(height: 16),
                        Text(
                            l10n.noSemestersAvailable, // Use localized string
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon( // Using ElevatedButton.icon for consistency
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.refresh),
                          onPressed: isLoading ? null : () => _refreshSemesters(context), // Pass context
                           style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                           ),
                        ),
                     ],
                  ),
               )
             );
          }

          // 4. Display semesters if available (the actual content)
          return RefreshIndicator( // Added RefreshIndicator outside SingleChildScrollView
            onRefresh: () => _refreshSemesters(context), // Pass context
            color: theme.colorScheme.primary, // Match theme
            backgroundColor: theme.colorScheme.surface, // Match theme
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0), // Padding applies to the content inside
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column( // This Column holds the list of semester cards
                    children: displaySemesters.map((semester) {
                      return AnimatedListItem(
                        key: ValueKey(semester.id), // Use ValueKey for list items
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SemestersCard(
                            semester: semester,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Padding( // Keep the text below the list
                    padding: const EdgeInsets.symmetric(horizontal: 16.0), // Added horizontal padding
                    child: Text(
                      l10n.appTitle.contains("መጂወ") ? 'ውጤታቸውን እያሳደጉ ካሉ ከ4,000 በላይ ተማሪዎች ጋር ይቀላቀሉ' : 'Join over 4,000 students who are already boosting their grades',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.8)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}