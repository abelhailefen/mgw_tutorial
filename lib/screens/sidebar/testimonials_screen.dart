// lib/screens/sidebar/testimonials_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart'; // Assuming AuthProvider exists and path is correct
import 'package:mgw_tutorial/models/testimonial.dart'; // Assuming Testimonial model exists and path is correct
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Assuming localization is set up


import 'package:mgw_tutorial/widgets/testimonials/create_testimonial_dialog.dart'; // Assuming this widget exists and path is correct
import 'package:mgw_tutorial/widgets/testimonials/testimonial_list.dart'; // Assuming this widget exists and path is correct


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
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    final provider = Provider.of<TestimonialProvider>(context, listen: false);
    provider.clearError();
    await provider.fetchTestimonials(forceRefresh: true);
  }

  Future<void> _handleRefresh() async {
     if (!mounted) return;
    final provider = Provider.of<TestimonialProvider>(context, listen: false);
    provider.clearError();
    await provider.fetchTestimonials(forceRefresh: true);
  }

  void _showCreateTestimonialDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Check if user is logged in before showing the dialog
    if (authProvider.currentUser == null || authProvider.currentUser!.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
               content: Text(l10n.pleaseLoginOrRegister), // Localized message
               backgroundColor: theme.colorScheme.secondaryContainer, // Using themed color
               behavior: SnackBarBehavior.floating,
           ),
        );
      }
      return;
    }

    // Show the create testimonial dialog and await its result
    // The dialog is expected to pop with `true` on success, `false` on cancellation, or null
    final success = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Pass the user ID to the dialog
        return CreateTestimonialDialog(userId: authProvider.currentUser!.id!);
      },
    );

    // Handle the result returned from the dialog
    if (success == true && mounted) {
       // === Custom Success SnackBar Color Logic ===
       // Light blue for dark mode, dark blue for light mode
       final snackBarBackgroundColor = theme.brightness == Brightness.dark
           ? const Color(0xFF81D4FA) // Light blue (similar to primaryDark)
           : const Color(0xFF0D47A1); // Dark blue (similar to onPrimaryContainerLight)

       final snackBarTextColor = theme.brightness == Brightness.dark
           ? Colors.black // Text on light blue
           : Colors.white; // Text on dark blue

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                l10n.testimonialSubmittedSuccess, // Localized success message
                style: TextStyle(color: snackBarTextColor), // Apply custom text color
            ),
            backgroundColor: snackBarBackgroundColor, // Apply custom background color
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
        ),
      );
    } else if (success == false) {
        // Dialog was cancelled or returned false (e.g., submission failed within dialog)
        // The dialog itself should show an error snackbar for failure.
         print("[Screen] Dialog dismissed with result false (submission likely failed in dialog or cancelled).");
    } else {
         // Dialog dismissed without a boolean result (e.g., tapping outside, back button)
         print("[Screen] Dialog dismissed without boolean result (e.g., backdrop tap).");
    }
  }

  Widget _buildContent(BuildContext context, TestimonialProvider testimonialProvider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<Testimonial> testimonialsToDisplay = testimonialProvider.testimonials;
    final bool isLoading = testimonialProvider.isLoading;
    final String? error = testimonialProvider.error;


    if (isLoading && testimonialsToDisplay.isEmpty) {
      return const Center(child: CircularProgressIndicator()); // Show loading for initial fetch
    }

    if (error != null && testimonialsToDisplay.isEmpty) {
      return Center( // Show error state if initial fetch failed
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50), // Error icon
              const SizedBox(height: 16),
              Text(
                error, // Display the specific error message from the provider
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)), // Themed text color
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6, // Button width relative to screen
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh), // Localized refresh text
                  onPressed: isLoading ? null : _handleRefresh, // Disable button while loading
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (testimonialsToDisplay.isEmpty && !isLoading) {
      return Center( // Show empty state message if no testimonials are available
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 70, color: theme.iconTheme.color?.withOpacity(0.5)), // Empty state icon
              const SizedBox(height: 16),
              Text(
                l10n.appTitle.contains("መጂወ") ? "እስካሁን ምንም ምስክርነቶች የሉም።" : "No testimonials yet.", // TODO: Localize
                style: theme.textTheme.titleMedium, // Themed text style
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTitle.contains("መጂወ") ? "የእርስዎን በማከል የመጀመሪያው ይሁኑ!" : "Be the first to add yours!", // TODO: Localize
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)), // Themed text color
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6, // Button width relative to screen
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh), // Localized refresh text
                  onPressed: isLoading ? null : _handleRefresh, // Disable button while loading
                ),
              ),
            ],
          )
        ),
      );
    }

    // If testimonials are available, display the list
    return TestimonialList(
      testimonials: testimonialsToDisplay, // Pass the list of testimonials
      apiBaseUrl: TestimonialProvider.apiBaseUrl, // Pass the API base URL (if needed by list items for images)
      onRefresh: _handleRefresh, // Pass the refresh function for pull-to-refresh
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localization instance
    final theme = Theme.of(context); // Get theme instance

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testimonials), // Localized app bar title
      ),
      body: Consumer<TestimonialProvider>( // Use Consumer to listen to TestimonialProvider changes
        builder: (context, testimonialProvider, child) {
          // Build the main content based on provider state (loading, error, data)
          return _buildContent(context, testimonialProvider);
        },
      ),
      // Floating Action Button to create a new testimonial
      floatingActionButton: Consumer<TestimonialProvider>( // Use Consumer to control FAB enabled state based on loading
        builder: (context, testimonialProvider, child) {
           // === Custom FAB Label Color Logic ===
           // Light blue for dark mode, dark blue for light mode
           final fabLabelColor = theme.brightness == Brightness.dark
               ? const Color(0xFF81D4FA) // Light blue
               : const Color(0xFF0D47A1); // Dark blue

          return FloatingActionButton.extended(
            // Disable FAB while testimonial provider is loading (e.g., refreshing)
            onPressed: testimonialProvider.isLoading ? null : _showCreateTestimonialDialog, // Call method to show dialog
            icon: const Icon(Icons.add_comment_outlined), // FAB icon
            label: Text(
                 l10n.shareYourTestimonialTitle, // Localized label text
                 style: TextStyle(color: fabLabelColor), // Apply custom color
             ),
          );
        },
      ),
    );
  }
}