// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/semesters_card.dart';
import 'package:mgw_tutorial/widgets/home/notes_card.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
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

                return Column(
                  children: semesterProvider.semesters.map((semester) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SemestersCard(
                        semester: semester,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            NotesCard( // CORRECTED: Added parameters
              title: l10n.appTitle.contains("መጂወ") ? 'ማስታወሻዎች' : 'Notes',
              description: l10n.appTitle.contains("መጂወ") ? 'ከአገር ዙሪያ ከተማሪዎች የሰበሰብናቸው ማስታወሻዎች።' : 'Notes we have collected from students all around the country.',
              imageUrl: 'https://via.placeholder.com/600x200.png?text=Notes+Preview',
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.appTitle.contains("መጂወ") ? 'የማስታወሻዎች ክፍል በቅርቡ ይመጣል!' : 'Notes section coming soon!', style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
              },
            ),
            const SizedBox(height: 24),
            Padding( // CORRECTED: Added padding
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
  }
}