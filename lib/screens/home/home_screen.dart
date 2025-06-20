import 'package:flutter/material.dart';
import 'package:mgw_tutorial/widgets/home/semesters_card.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/common/animated_list_item.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Initial connectivity check
    _connectivity.checkConnectivity().then((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() => _connectivityStatus = result);
    });
    // Subscribe to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() => _connectivityStatus = result);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SemesterProvider>(context, listen: false).fetchSemesters();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _refreshSemesters(BuildContext context) async {
    await Provider.of<SemesterProvider>(context, listen: false).fetchSemesters(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          if (_connectivityStatus == ConnectivityResult.none)
            // Container(
            //   width: double.infinity,
            //   color: Colors.orange,
            //   padding: const EdgeInsets.symmetric(vertical: 8),
            //   child: Center(
            //     // child: Text(
            //     //   l10n.appTitle.contains("መጂወ")
            //     //       ? "ኦፍላይን ሁኔታ ፡ መረጃው ከመቀየሩ በፊት የተቀመጠ ነው።"
            //     //       : "Offline mode: Showing previously cached data.",
            //     //   style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            //     // ),
            //   ),
            // ),
          Expanded(
            child: Consumer<SemesterProvider>(
              builder: (context, semesterProvider, child) {
                final List<Semester> displaySemesters = semesterProvider.semesters;
                final bool isLoading = semesterProvider.isLoading;
                final String? error = semesterProvider.error;

                // --- Conditional Display Logic ---

                if (isLoading && displaySemesters.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }

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
                            l10n.appTitle.contains("መጂወ") && error.contains(l10n.noSemestersAvailable)
                                ? "ሴሚስተሮችን መጫን አልተሳካም።\n$error"
                                : error,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.refresh),
                            onPressed: isLoading ? null : () => _refreshSemesters(context),
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

                if (displaySemesters.isEmpty && !isLoading && error == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noSemestersAvailable,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.refresh),
                            onPressed: isLoading ? null : () => _refreshSemesters(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _refreshSemesters(context),
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: displaySemesters.map((semester) {
                            return AnimatedListItem(
                              key: ValueKey(semester.id),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            l10n.appTitle.contains("መጂወ")
                                ? 'ውጤታቸውን እያሳደጉ ካሉ ከ4,000 በላይ ተማሪዎች ጋር ይቀላቀሉ'
                                : 'Join over 4,000 students who are already boosting their grades',
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
          ),
        ],
      ),
    );
  }
}