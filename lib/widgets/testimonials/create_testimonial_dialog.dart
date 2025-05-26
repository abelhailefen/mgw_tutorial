// lib/widgets/testimonials/create_testimonial_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Needed for File to display picked images

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
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage; // --- Changed to single XFile? ---
  bool _isSubmitting = false; // Internal state for the upload + create process

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Modified Image picking method (single image) ---
  Future<void> _pickImage() async { // Renamed method
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    try {
      // Pick a single image from the gallery
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70, // Optional: reduce image quality
          maxWidth: 1000, // Optional: limit image width
      );
      if (pickedFile != null && mounted) {
        setState(() {
          _pickedImage = pickedFile; // --- Set the single picked image ---
        });
      }
    } catch (e) {
       print("Error picking image: $e"); // Log error
       // Check if the error is simply the user cancelling the picker
       if (e is Exception && e.toString().contains('No file selected')) {
           print("Image picker cancelled by user.");
           return; // Do nothing if user cancelled
       }

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(l10n.appTitle.contains("መጂወ") ? "ምስል መምረጥ አልተቻለም።" : "Failed to pick image."), // Hide technical error detail in UI
             backgroundColor: theme.colorScheme.errorContainer,
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 4),
           ),
         );
      }
    }
  }

  // --- Modified Image removal method (single image) ---
  void _removeImage() { // Renamed method
     setState(() {
       _pickedImage = null; // --- Set the single picked image to null ---
     });
  }

  // --- MODIFIED _submitTestimonial ---
  Future<void> _submitTestimonial() async {
    // Validate the form fields first
    if (!_formKey.currentState!.validate()) {
      print("[Dialog] Form validation failed.");
      // Optional: Trigger validation feedback display if not using autovalidateMode
      // _formKey.currentState!.validate();
      return; // Stop if form is invalid
    }

    // Get trimmed values AFTER validation
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    // --- Explicit Check for Description (based on backend error) ---
    print("[Dialog] Value of description before sending: '$description'"); // <-- Extra Debug Print

    // This check is redundant if the form validator is correct and AutovalidateMode is set,
    // but serves as a final safeguard and helps confirm the value before sending.
    if (description.isEmpty) {
       print("[Dialog] Description is empty after validation/trimming. Showing manual error.");
       if (mounted) {
            final l10n = AppLocalizations.of(context)!; // Need l10n here
            final theme = Theme.of(context);
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(l10n.experienceValidationPrompt), // Use your validation message
                   backgroundColor: theme.colorScheme.errorContainer,
                   behavior: SnackBarBehavior.floating,
                   duration: const Duration(seconds: 4),
                 ),
               );
       }
       // No need to change _isSubmitting as we haven't started API call yet
       return; // Stop submission
    }

    // Optional: Add validation for required image if applicable
    // if (_pickedImage == null) {
    //     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? "እባكዎ ምስል ያያይዙ።" : "Please attach an image."), backgroundColor: Theme.of(context).colorScheme.errorContainer, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4),));
    //     return;
    // }


    if (_isSubmitting) {
      print("[Dialog] Submission already in progress.");
      return; // Prevent double submission
    }

    setState(() {
      _isSubmitting = true; // Set internal submitting state
    });

    // Listen: false is crucial in async methods like this
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Clear provider error *before* starting the sequence
    testimonialProvider.clearError();

    // --- Call the modified createTestimonial directly with the single file ---
    print("[Dialog] _submitTestimonial - Calling createTestimonial with picked image and trimmed data.");
    bool creationSuccess = await testimonialProvider.createTestimonial(
      title: title,           // Use trimmed value
      description: description, // Use trimmed value
      userId: widget.userId,
      imageFile: _pickedImage, // --- Pass the single XFile? ---
    );

    print("[Dialog] _submitTestimonial - createTestimonial returned: $creationSuccess");

    // 3. Handle Result
    if (mounted) {
      if (creationSuccess) {
         print("[Dialog] _submitTestimonial - Testimonial creation successful. Popping dialog.");
         // Popping dialog with 'true' signals success to the caller (TestimonialsScreen)
         Navigator.of(context).pop(true);
         // The success snackbar is shown by TestimonialsScreen after the dialog pops.
         // The list refresh is handled by the provider after creation.
      } else {
         print("[Dialog] _submitTestimonial - Testimonial creation failed. Showing provider error.");
         // Show snackbar with the error message from the provider
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(testimonialProvider.error ?? (l10n.appTitle.contains("መጂወ") ? "ምስክርነት ማስገባት አልተካካም።" : "Failed to submit testimonial.")),
             backgroundColor: theme.colorScheme.errorContainer,
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 5),
           ),
         );
         // Don't pop the dialog, let user see error or try again.
      }
    }

    // Ensure _isSubmitting is set to false if the dialog is still mounted
    if (mounted) {
       setState(() { _isSubmitting = false; });
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
      content: Form(
        key: _formKey,
        // Set autovalidateMode for real-time feedback
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.yourExperienceLabel,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  // Ensure this validator correctly handles trimming
                  if (value == null || value.trim().isEmpty) return l10n.experienceValidationPrompt;
                  return null;
                },
                enabled: !isProcessing,
              ),
              const SizedBox(height: 20),
              // --- Image Selection Button (Single Image) ---
              OutlinedButton.icon(
                // Disable button if an image is already picked OR if processing
                onPressed: _pickedImage != null || isProcessing ? null : _pickImage, // Use _pickImage
                icon: Icon(
                    _pickedImage != null ? Icons.image_outlined : Icons.image, // Icon changes if image picked
                    color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary
                ),
                label: Text(
                    _pickedImage == null
                        ? (l10n.appTitle.contains("መጂወ") ? "ምስል ያክሉ" : "Add Image") // Changed to singular
                        : (l10n.appTitle.contains("መጂወ") ? "ምስል ተመርጧል" : "Image selected"), // Changed to singular
                    style: TextStyle(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary)
                ),
                style: OutlinedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 48),
                   side: BorderSide(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
              ),
              // --- Display Single Selected Image ---
              if (_pickedImage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 100, // Fixed height for the image preview
                  width: 100, // Fixed width for the image preview
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                       ClipRRect( // Clip the image itself
                         borderRadius: BorderRadius.circular(8),
                         child: Image.file(
                             File(_pickedImage!.path),
                             fit: BoxFit.cover,
                             // Handle potential errors loading the local file itself? Less common.
                             errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: theme.colorScheme.error)),
                         ),
                       ),
                       Positioned(
                            right: 4,
                            top: 4,
                            child: isProcessing // Disable remove while processing
                                ? const SizedBox.shrink()
                                : InkWell(
                                    onTap: _removeImage, // Use _removeImage
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
      actions: <Widget>[
        TextButton(
          child: Text(l10n.cancelButton, style: TextStyle(color: isProcessing ? theme.disabledColor : theme.colorScheme.primary)),
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          onPressed: isProcessing ? null : _submitTestimonial,
          child: isProcessing
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
              : Text(l10n.submitButtonGeneral),
        ),
      ],
    );
  }
}