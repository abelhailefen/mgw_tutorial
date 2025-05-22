// lib/screens/sidebar/testimonials_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// CreateTestimonialDialog (remains the same as your working version)
class CreateTestimonialDialog extends StatefulWidget {
  final int userId;
  const CreateTestimonialDialog({super.key, required this.userId});

  @override
  State<CreateTestimonialDialog> createState() => _CreateTestimonialDialogState();
}

class _CreateTestimonialDialogState extends State<CreateTestimonialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTestimonial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    bool success = await testimonialProvider.createTestimonial(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      userId: widget.userId,
    );

    if (mounted) {
      Navigator.of(context).pop(success);
      if (!success && testimonialProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(testimonialProvider.error ?? (l10n.appTitle.contains("መጂወ") ? "ምስክርነት ማስገባት አልተሳካም።" : "Failed to submit testimonial.")),
              backgroundColor: theme.colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final testimonialProvider = Provider.of<TestimonialProvider>(context);
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      title: Text(l10n.shareYourTestimonialTitle, style: theme.textTheme.titleLarge),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.titleLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.titleValidationPrompt;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.yourExperienceLabel,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.experienceValidationPrompt;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)),
          onPressed: testimonialProvider.isLoading ? null : () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          onPressed: testimonialProvider.isLoading ? null : _submitTestimonial,
          child: testimonialProvider.isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
              : Text(l10n.submitButtonGeneral),
        ),
      ],
    );
  }
}


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
    Future.microtask(() {
      print("[Screen] initState (microtask) - Calling _fetchInitialData.");
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    print("[Screen] _fetchInitialData CALLED");
    if (mounted) {
      Provider.of<TestimonialProvider>(context, listen: false).clearError();
      // Fetch ALL testimonials, no client-side filter string needed here for the provider
      await Provider.of<TestimonialProvider>(context, listen: false)
          .fetchTestimonials(forceRefresh: true);
      print("[Screen] _fetchInitialData - Initial fetch call completed.");
    } else {
      print("[Screen] _fetchInitialData - SKIPPED, widget not mounted.");
    }
  }

  Future<void> _handleRefresh() async {
    print("[Screen] _handleRefresh CALLED (Pull-to-refresh)");
    if (mounted) {
      // Fetch ALL testimonials on refresh
      await Provider.of<TestimonialProvider>(context, listen: false)
          .fetchTestimonials(forceRefresh: true);
      print("[Screen] _handleRefresh - Refresh operation completed.");
    } else {
       print("[Screen] _handleRefresh - SKIPPED, widget not mounted.");
    }
  }

  void _showCreateTestimonialDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (authProvider.currentUser == null) {
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
      builder: (_) => CreateTestimonialDialog(userId: authProvider.currentUser!.id!),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.testimonialSubmittedSuccess),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
        ),
      );
      // Provider's createTestimonial now calls fetchTestimonials(forceRefresh: true)
      // which means it will show all, including the new pending one.
    }
  }

  Widget _buildContent(BuildContext context, TestimonialProvider testimonialProvider) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // The provider's `testimonials` list now IS the list of all fetched testimonials
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
                  onPressed: _handleRefresh,
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
                l10n.appTitle.contains("መጂወ") ? "እስካሁን ምንም ምስክርነቶች የሉም።" : "No testimonials yet.", // Simplified message
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
                  onPressed: _handleRefresh,
                ),
              ),
            ],
          )
        ),
      );
    }

    print("[Screen] _buildContent - STATE: Displaying List (${testimonialsToDisplay.length} items), isLoading (for refresh): $isLoading");
    return ListView.separated(
      key: const ValueKey("all_testimonial_list"), // Key for the list
      padding: const EdgeInsets.all(16.0),
      itemCount: testimonialsToDisplay.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (ctx, index) {
        final testimonial = testimonialsToDisplay[index];
        final String authorName = testimonial.author.name.isNotEmpty ? testimonial.author.name : (l10n.appTitle.contains("መጂወ") ? "ስም የለም" : "Anonymous");
        final String testimonialTitle = testimonial.title;
        final String testimonialDescription = testimonial.description;
        final String? displayImageUrl = testimonial.firstFullImageUrl;

        return Card(
          key: ValueKey(testimonial.id),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : "A",
                        style: TextStyle(fontSize: 18, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authorName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (displayImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        displayImageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 180,
                            color: theme.colorScheme.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: theme.colorScheme.surfaceVariant,
                          child: Center(child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant, size: 40)),
                        ),
                      ),
                    ),
                  ),
                Text(
                  testimonialTitle,
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '"${testimonialDescription}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                        height: 1.45
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display status if it's not empty or 'unknown' (you can adjust this logic)
                    if (testimonial.status.isNotEmpty && testimonial.status.toLowerCase() != 'unknown')
                        Chip(
                          label: Text(
                            testimonial.status, // TODO: Localize status strings if needed
                            style: theme.chipTheme.labelStyle?.copyWith(fontSize: 10)
                          ),
                          backgroundColor: testimonial.status.toLowerCase() == 'approved'
                              ? theme.colorScheme.primaryContainer.withOpacity(0.7) // Example color for approved
                              : theme.chipTheme.backgroundColor?.withOpacity(0.7), // Default for others
                          labelStyle: testimonial.status.toLowerCase() == 'approved'
                              ? theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)
                              : theme.chipTheme.labelStyle?.copyWith(fontSize: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )
                    else
                      const SizedBox(),

                    Text(
                      DateFormat.yMMMd().add_jm().format(testimonial.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: _buildContent(context, testimonialProvider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTestimonialDialog,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.shareYourTestimonialTitle),
      ),
    );
  }
}