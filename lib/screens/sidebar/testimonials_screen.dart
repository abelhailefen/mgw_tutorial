// lib/screens/sidebar/testimonials_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Import the new widgets from the widgets folder
import 'package:mgw_tutorial/widgets/testimonials/create_testimonial_dialog.dart';
import 'package:mgw_tutorial/widgets/testimonials/testimonial_list.dart';


class TestimonialsScreen extends StatefulWidget {
  static const routeName = '/testimonials';
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {

  @override
  void initState() {
    super.initState();
    print("[Screen] initState - TestimonialsScreen");
    WidgetsBinding.instance.addPostFrameCallback((_) {
        print("[Screen] addPostFrameCallback - Calling _fetchInitialData.");
        _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    print("[Screen] _fetchInitialData CALLED");
    if (!mounted) {
       print("[Screen] _fetchInitialData - SKIPPED, widget not mounted.");
       return;
    }
    final provider = Provider.of<TestimonialProvider>(context, listen: false);
    provider.clearError();
    await provider.fetchTestimonials(forceRefresh: true);
    print("[Screen] _fetchInitialData - Initial fetch call completed. Error: ${provider.error}");
  }

  Future<void> _handleRefresh() async {
     print("[Screen] _handleRefresh CALLED (Pull-to-refresh)");
     if (!mounted) {
       print("[Screen] _handleRefresh - SKIPPED, widget not mounted.");
       return;
    }
    final provider = Provider.of<TestimonialProvider>(context, listen: false);
    provider.clearError();
    await provider.fetchTestimonials(forceRefresh: true);
    print("[Screen] _handleRefresh - Refresh operation completed. Error: ${provider.error}");
  }

  void _showCreateTestimonialDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (authProvider.currentUser == null || authProvider.currentUser!.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
               content: Text(l10n.pleaseLoginOrRegister),
               backgroundColor: theme.colorScheme.secondaryContainer,
               behavior: SnackBarBehavior.floating,
           ),
        );
      }
      return;
    }

    final success = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CreateTestimonialDialog(userId: authProvider.currentUser!.id!);
      },
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.testimonialSubmittedSuccess),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
        ),
      );
    } else if (success == false && mounted) {
        print("[Screen] Dialog dismissed with success=false (cancelled or submission failed).");
    } else {
         print("[Screen] Dialog dismissed without boolean result (e.g., backdrop tap).");
    }
  }

  Widget _buildContent(BuildContext context, TestimonialProvider testimonialProvider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Testimonial> testimonialsToDisplay = testimonialProvider.testimonials;
    final bool isLoading = testimonialProvider.isLoading;
    final String? error = testimonialProvider.error;

    print("[Screen] _buildContent REBUILDING - isLoading: $isLoading, error: $error, testimonialsToDisplay count: ${testimonialsToDisplay.length}");

    if (isLoading && testimonialsToDisplay.isEmpty) {
      print("[Screen] _buildContent - STATE: Initial API Loading");
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && testimonialsToDisplay.isEmpty) {
      print("[Screen] _buildContent - STATE: Error and No Data to Display - $error");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
              const SizedBox(height: 16),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _handleRefresh,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (testimonialsToDisplay.isEmpty && !isLoading) {
      print("[Screen] _buildContent - STATE: No Data to Display and Not Loading");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 70, color: theme.iconTheme.color?.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.appTitle.contains("መጂወ") ? "እስካሁን ምንም ምስክርነቶች የሉም።" : "No testimonials yet.",
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle.contains("መጂወ") ? "የእርስዎን በማከል የመጀመሪያው ይሁኑ!" : "Be the first to add yours!",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                  onPressed: isLoading ? null : _handleRefresh,
                ),
              ),
            ],
          )
        ),
      );
    }

    print("[Screen] _buildContent - STATE: Displaying List (${testimonialsToDisplay.length} items), isLoading (for refresh): $isLoading");
    return TestimonialList(
      testimonials: testimonialsToDisplay,
      apiBaseUrl: TestimonialProvider.apiBaseUrl,
      onRefresh: _handleRefresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    print("[Screen] TestimonialsScreen Build method called");

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testimonials),
      ),
      body: Consumer<TestimonialProvider>(
        builder: (context, testimonialProvider, child) {
          return _buildContent(context, testimonialProvider);
        },
      ),
      floatingActionButton: Consumer<TestimonialProvider>(
        builder: (context, testimonialProvider, child) {
          return FloatingActionButton.extended(
            onPressed: testimonialProvider.isLoading ? null : _showCreateTestimonialDialog,
            icon: const Icon(Icons.add_comment_outlined),
            label: Text(l10n.shareYourTestimonialTitle),
          );
        },
      ),
    );
  }
}