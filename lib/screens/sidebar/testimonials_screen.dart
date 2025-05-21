// lib/screens/sidebar/testimonials_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/models/testimonial.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:image_picker/image_picker.dart'; // Uncomment for image picking
// import 'dart:io'; // Uncomment for File

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
    final l10n = AppLocalizations.of(context)!; // For potential error messages
    final theme = Theme.of(context);

    bool success = await testimonialProvider.createTestimonial(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      userId: widget.userId,
    );

    if (mounted) {
      Navigator.of(context).pop(success); // Pop with success status
      if (!success && testimonialProvider.error != null) { // Show error if submission failed
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
      title: Text(l10n.appTitle.contains("መጂወ") ? "ምስክርነትዎን ያጋሩ" : "Share Your Testimonial", style: theme.textTheme.titleLarge),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.appTitle.contains("መጂወ") ? "ርዕስ" : "Title"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.appTitle.contains("መጂወ") ? "እባክዎ ርዕስ ያስገቡ" : "Please enter a title";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.appTitle.contains("መጂወ") ? "የእርስዎ ተሞክሮ" : "Your Experience",
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.appTitle.contains("መጂወ") ? "እባክዎ ተሞክሮዎን ያስገቡ" : "Please describe your experience";
                  return null;
                },
              ),
              // TODO: Add image picker UI if needed
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.appTitle.contains("መጂወ") ? "ሰርዝ" : "Cancel", style: TextStyle(color: theme.colorScheme.primary)),
          onPressed: testimonialProvider.isLoading ? null : () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          onPressed: testimonialProvider.isLoading ? null : _submitTestimonial,
          child: testimonialProvider.isLoading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
              : Text(l10n.appTitle.contains("መጂወ") ? "አስገባ" : "Submit"),
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
  String _currentStatusFilter = "approved"; // Default filter

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(statusFilter: _currentStatusFilter);
    });
  }

  Future<void> _fetchData({bool forceRefresh = false, String? statusFilter}) async {
    if (mounted) {
      Provider.of<TestimonialProvider>(context, listen: false)
          .fetchTestimonials(forceRefresh: forceRefresh, statusFilter: statusFilter);
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
            content: Text(l10n.appTitle.contains("መጂወ") ? "ምስክርነት ገብቷል! ከማረጋገጫ በኋላ ይታያል።" : "Testimonial submitted! It will appear after approval."),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
        ),
      );
      // Optionally refresh the list if you want to show "pending" testimonials to the user
      // _fetchData(statusFilter: null, forceRefresh: true); // To show all, including pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final testimonialProvider = Provider.of<TestimonialProvider>(context);
    final List<Testimonial> testimonials = testimonialProvider.testimonials;
    final bool isLoading = testimonialProvider.isLoading;
    final String? error = testimonialProvider.error;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testimonials),
        // Optional: Add filter if you want users to see pending/rejected ones they submitted
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: (value) {
        //       setState(() { _currentStatusFilter = value; });
        //       _fetchData(statusFilter: value, forceRefresh: true);
        //     },
        //     itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        //       const PopupMenuItem<String>(value: 'approved', child: Text('Approved')),
        //       const PopupMenuItem<String>(value: 'pending', child: Text('My Pending')), // Needs logic for "My"
        //     ],
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(statusFilter: _currentStatusFilter, forceRefresh: true),
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: Builder(
          builder: (BuildContext scaffoldContext) {
            if (isLoading && testimonials.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && testimonials.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        "${l10n.appTitle.contains("መጂወ") ? "ምስክርነቶችን መጫን አልተሳካም።" : "Failed to load testimonials."}\n$error",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.refresh),
                        onPressed:() => _fetchData(statusFilter: _currentStatusFilter, forceRefresh: true),
                      )
                    ],
                  ),
                ),
              );
            }

            if (testimonials.isEmpty && !isLoading) {
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
                    ],
                  )
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: testimonials.length,
              itemBuilder: (ctx, index) {
                final testimonial = testimonials[index];
                final String authorName = testimonial.author.name.isNotEmpty ? testimonial.author.name : (l10n.appTitle.contains("መጂወ") ? "ስም የለም" : "Anonymous");
                final String testimonialTitle = testimonial.title;
                final String testimonialDescription = testimonial.description;
                final String? displayImageUrl = testimonial.firstFullImageUrl;

                return Card( // Uses CardTheme
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
                          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary), // Make title stand out
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
                            if (testimonial.status != 'approved' && testimonial.status.isNotEmpty && testimonial.status != 'unknown')
                                Chip(
                                  label: Text(testimonial.status, style: theme.chipTheme.labelStyle?.copyWith(fontSize: 10)), // TODO: Localize status
                                  backgroundColor: theme.chipTheme.backgroundColor?.withOpacity(0.7),
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTestimonialDialog,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.appTitle.contains("መጂወ") ? "ምስክርነት አክል" : "Add Testimonial"),
        // Theming will be applied by FloatingActionButtonTheme in main.dart if defined, or defaults.
      ),
    );
  }
}