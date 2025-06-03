// lib/widgets/testimonials/create_testimonial_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Needed for File to display picked images


// Ensure AuthProvider is imported if you're getting userId from it
// import 'package:mgw_tutorial/provider/auth_provider.dart';


class CreateTestimonialDialog extends StatefulWidget {
  final int userId; // Assuming userId is required for the testimonial

  const CreateTestimonialDialog({
    super.key,
    required this.userId, // Requires userId
  });

  @override
  State<CreateTestimonialDialog> createState() => _CreateTestimonialDialogState();
}

class _CreateTestimonialDialogState extends State<CreateTestimonialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // State variable to hold the single picked image file
  XFile? _pickedImage;

  // State variable to track if the submission is in progress
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image picking method (single image) ---
  Future<void> _pickImage() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70, // Optional: reduce image quality
          maxWidth: 1000, // Optional: limit image width
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _pickedImage = pickedFile;
        });
      }
    } catch (e) {
       // Handle potential errors during picking (e.g., permissions, user cancellation)
       if (e is Exception && e.toString().contains('No file selected')) {
           return; // User cancelled picker, do nothing
       }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(l10n.appTitle.contains("መጂወ") ? "ምስል መምረጥ አልተቻለም።" : "Failed to pick image."), // TODO: Localize
             backgroundColor: theme.colorScheme.error,
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 4),
           ),
         );
      }
    }
  }

  // --- Image removal method (single image) ---
  void _removeImage() {
     if (!mounted) return;
     setState(() {
       _pickedImage = null;
     });
  }


  // --- Submission Method ---
  Future<void> _submitTestimonial() async {
    // Validate the form fields by explicitly calling validate()
    // Validation only triggers NOW, not initially or as the user types, due to AutovalidateMode.disabled
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is invalid
    }

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    // Explicit check for description after trimming (safeguard)
    if (description.isEmpty) {
       if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            final theme = Theme.of(context);
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(l10n.experienceValidationPrompt), // Use your validation message for description
                   backgroundColor: theme.colorScheme.error,
                   behavior: SnackBarBehavior.floating,
                   duration: const Duration(seconds: 4),
                 ),
               );
       }
       return;
    }

    if (_isSubmitting) {
      return; // Prevent double submission
    }

    setState(() {
      _isSubmitting = true; // Set internal submitting state
    });

    // Get provider instances - use listen: false in async methods
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Clear any previous errors from the provider's state
    testimonialProvider.clearError();

    // Call the provider's createTestimonial method
    // The provider expects List<XFile>?, so wrap the single picked image in a list if it exists.
    bool creationSuccess = await testimonialProvider.createTestimonial(
      title: title,
      description: description,
      userId: widget.userId,
      imageFiles: _pickedImage != null ? [_pickedImage!] : null, // Pass a list (or null)
    );

    // Handle Result and update UI if widget is still mounted
    if (mounted) {
      // Ensure _isSubmitting is set back to false after the async operation completes
      setState(() {
         _isSubmitting = false;
      });

      if (creationSuccess) {
         // Pop the dialog, typically passing back 'true' to signal success
         Navigator.of(context).pop(true);
         // Success snackbar usually handled by calling screen
      } else {
         // Show snackbar with the error message from the provider
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(testimonialProvider.error ?? (l10n.appTitle.contains("መጂወ") ? "ምስክርነት ማስገባት አልተካካም።" : "Failed to submit testimonial.")), // TODO: Localize
             backgroundColor: theme.colorScheme.error, // Use a standard error color
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 5),
           ),
         );
         // Don't pop the dialog on failure
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bool isProcessing = _isSubmitting;

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      surfaceTintColor: theme.dialogTheme.surfaceTintColor,
      title: Text(l10n.shareYourTestimonialTitle, style: theme.textTheme.titleLarge),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: Form( // Wrap content in a Form widget for validation
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled, // Validation only triggers on submit
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title Text Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.titleLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.titleValidationPrompt;
                  return null;
                },
                enabled: !isProcessing,
              ),
              const SizedBox(height: 16),
              // Description/Experience Text Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.yourExperienceLabel,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  // This validation only runs on submit due to autovalidateMode
                  if (value == null || value.trim().isEmpty) return l10n.experienceValidationPrompt;
                  return null;
                },
                enabled: !isProcessing,
              ),
              const SizedBox(height: 20),

              // --- Image Selection Button ---
              OutlinedButton.icon(
                onPressed: _pickedImage != null || isProcessing ? null : _pickImage,
                icon: Icon(
                    _pickedImage != null ? Icons.image_outlined : Icons.image,
                    color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary
                ),
                label: Text(
                    _pickedImage == null
                        ? (l10n.appTitle.contains("መጂወ") ? "ምስል ያክሉ" : "Add Image") // TODO: Localize
                        : (l10n.appTitle.contains("መጂወ") ? "ምስል ተመርጧል" : "Image selected"), // TODO: Localize
                    style: TextStyle(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary)
                ),
                style: OutlinedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 48),
                   side: BorderSide(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),

              // --- Display Selected Image Preview ---
              if (_pickedImage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(8),
                         child: Image.file(
                             File(_pickedImage!.path),
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: theme.colorScheme.error)),
                         ),
                       ),
                       // --- Remove Image Button ---
                       Positioned(
                            right: 4,
                            top: 4,
                            child: isProcessing
                                ? const SizedBox.shrink()
                                : InkWell(
                                    onTap: _removeImage,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red[400],
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // Actions row for dialog buttons
      actions: <Widget>[
        // Cancel Button
        TextButton(
          child: Text(l10n.cancelButton, style: TextStyle(color: isProcessing ? theme.disabledColor : theme.colorScheme.primary)),
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(false),
        ),
        // Submit Button
        ElevatedButton(
          onPressed: isProcessing ? null : _submitTestimonial,
          child: isProcessing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)
                  )
                )
              : Text(l10n.submitButtonGeneral),
        ),
      ],
    );
  }
}