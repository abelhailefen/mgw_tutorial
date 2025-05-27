// lib/widgets/testimonials/create_testimonial_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart'; // Make sure this path is correct
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Assuming this import is correct due to localization setup
import 'package:image_picker/image_picker.dart'; // Required for image picking
import 'dart:io'; // Needed for File to display picked images


// Assuming you have an AuthProvider to get the user ID
// import 'package:mgw_tutorial/provider/auth_provider.dart';


class CreateTestimonialDialog extends StatefulWidget {
  // It's better to pass the actual userId here if it's available in the calling widget
  // Or, get it from an AuthProvider inside the _submitTestimonial method.
  // Let's keep userId parameter for clarity if it's easily available.
  // If you get it from provider, you can remove this parameter.
  final int userId; // Assuming userId is required for the testimonial

  const CreateTestimonialDialog({
    super.key,
    required this.userId, // Requires userId
  });

  @override
  State<CreateTestimonialDialog> createState() => _CreateTestimonialDialogState();
}

class _CreateTestimonialDialogState extends State<CreateTestimonialDialog> {
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final _titleController = TextEditingController(); // Controller for title text field
  final _descriptionController = TextEditingController(); // Controller for description text field
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  // State variable to hold the single picked image file
  XFile? _pickedImage; // --- Changed to single XFile? ---

  // State variable to track if the submission is in progress
  bool _isSubmitting = false; // Internal state for the upload + create process

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the tree
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Image picking method (single image) ---
  Future<void> _pickImage() async {
    // Check if the widget is still mounted before performing async operations that might update UI state
    if (!mounted) return;

    // Get localization and theme
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    try {
      // Pick a single image from the gallery using ImagePicker
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, // Use gallery source
          imageQuality: 70, // Optional: reduce image quality to save data/size
          maxWidth: 1000, // Optional: limit image width
      );

      // If a file was picked AND the widget is still mounted
      if (pickedFile != null && mounted) {
        setState(() {
          _pickedImage = pickedFile; // --- Set the single picked image ---
        });
        print("[Dialog] Image picked: ${_pickedImage!.path}"); // Log success
      } else {
         print("[Dialog] Image picking cancelled or failed (pickedFile is null)."); // Log cancellation
      }
    } catch (e) {
       print("Error picking image: $e"); // Log any exception during picking
       // Handle specific exceptions if necessary (e.g., permissions)
       // if (e is PlatformException && e.code == 'photo_access_denied') {
       //    // Show a message asking the user to grant permission in settings
       // } else { ... }

      // Check if the widget is still mounted before showing a SnackBar
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             // Provide a user-friendly message, hide technical error detail
             content: Text(l10n.appTitle.contains("መጂወ") ? "ምስል መምረጥ አልተቻለም።" : "Failed to pick image."), // TODO: Localize
             backgroundColor: theme.colorScheme.errorContainer, // Use error color
             behavior: SnackBarBehavior.floating, // Floating behavior
             duration: const Duration(seconds: 4), // Duration
           ),
         );
      }
    }
  }

  // --- Image removal method (single image) ---
  void _removeImage() {
     // Check if the widget is still mounted before updating state
     if (!mounted) return;
     setState(() {
       _pickedImage = null; // --- Set the single picked image to null ---
     });
     print("[Dialog] Picked image removed."); // Log removal
  }


  // --- MODIFIED _submitTestimonial ---
  // This method handles validation, prepares data, and calls the provider's createTestimonial
  Future<void> _submitTestimonial() async {
    // 1. Validate the form fields first
    if (!_formKey.currentState!.validate()) {
      print("[Dialog] Form validation failed. Not submitting.");
      // No need to show a generic error here, validation messages appear directly on fields.
      return; // Stop if form is invalid
    }

    // Get trimmed values AFTER validation to remove leading/trailing whitespace
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    // --- Explicit Check for Description (based on backend error observed previously) ---
    // Although validation *should* catch empty, this is a safeguard.
    print("[Dialog] Value of description before sending: '$description'"); // <-- Extra Debug Print
    if (description.isEmpty) {
       print("[Dialog] Description is empty after validation/trimming. Showing manual error.");
       if (mounted) { // Check mounted before showing snackbar
            final l10n = AppLocalizations.of(context)!; // Need l10n here
            final theme = Theme.of(context); // Need theme here
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(l10n.experienceValidationPrompt), // Use your validation message for description
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
    //     if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? "እባكዎ ምስል ያያይዙ።" : "Please attach an image."), backgroundColor: Theme.of(context).colorScheme.errorContainer, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4),)); // TODO: Localize
    //     return;
    // }


    // Prevent double submission if a call is already in progress
    if (_isSubmitting) {
      print("[Dialog] Submission already in progress. Ignoring button tap.");
      return;
    }

    // 2. Set submitting state and notify listeners
    setState(() {
      _isSubmitting = true; // Set internal submitting state to true
    });

    // Get provider instances - use listen: false in async methods like this
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    final theme = Theme.of(context); // Get theme instance

    // Clear any previous errors from the provider's state before starting a new request
    testimonialProvider.clearError();
    print("[Dialog] Cleared provider error."); // Added log

    // --- Call the modified createTestimonial in the provider ---
    print("[Dialog] Calling provider.createTestimonial with trimmed data and image list.");
    // The provider expects List<XFile>?, so wrap the single picked image in a list if it exists.
    bool creationSuccess = await testimonialProvider.createTestimonial(
      title: title,             // Pass trimmed title
      description: description,   // Pass trimmed description
      userId: widget.userId,      // Pass the userId received by the dialog widget
      imageFiles: _pickedImage != null ? [_pickedImage!] : null, // --- PASS A LIST ---
    );

    print("[Dialog] provider.createTestimonial returned: $creationSuccess");

    // 3. Handle Result and update UI
    // Check if the widget is still mounted before attempting to interact with UI state or Navigator/ScaffoldMessenger
    if (mounted) {
      if (creationSuccess) {
         print("[Dialog] Testimonial creation successful. Popping dialog.");
         // Pop the dialog, optionally passing back a result (e.g., true for success)
         Navigator.of(context).pop(true);
         // The success snackbar is typically shown by the *calling* widget (TestimonialsScreen)
         // after it receives the 'true' result from Navigator.pop.
         // The list refresh is handled by the provider after successful creation.
      } else {
         print("[Dialog] Testimonial creation failed. Showing provider error snackbar.");
         // Show snackbar with the error message obtained from the provider's state
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             // Display the specific error from the provider, or a generic one if null
             content: Text(testimonialProvider.error ?? (l10n.appTitle.contains("መጂወ") ? "ምስክርነት ማስገባት አልተካካም።" : "Failed to submit testimonial.")), // TODO: Localize
             backgroundColor: theme.colorScheme.errorContainer, // Use error color
             behavior: SnackBarBehavior.floating,
             duration: const Duration(seconds: 5),
           ),
         );
         // Don't pop the dialog on failure, allow the user to correct/retry.
      }

      // Ensure _isSubmitting is set back to false after the async operation completes
      setState(() {
         _isSubmitting = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get localization and theme instances
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Determine if the form should be disabled
    final bool isProcessing = _isSubmitting; // Controls button and field enabled state

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor, // Use theme color
      surfaceTintColor: theme.dialogTheme.surfaceTintColor, // Use theme color
      title: Text(l10n.shareYourTestimonialTitle, style: theme.textTheme.titleLarge), // Localized title
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0), // Adjust padding
      content: Form( // Wrap content in a Form widget for validation
        key: _formKey, // Assign the form key
        // Set autovalidateMode to get real-time validation feedback as the user types
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView( // Allow content to scroll if it exceeds dialog height
          child: Column(
            mainAxisSize: MainAxisSize.min, // Column takes minimum vertical space
            crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
            children: <Widget>[
              // Title Text Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: l10n.titleLabel), // Localized label
                validator: (value) {
                  // Validation: Check if value is null, empty, or only whitespace after trimming
                  if (value == null || value.trim().isEmpty) {
                    return l10n.titleValidationPrompt; // Localized validation message
                  }
                  return null; // Return null if valid
                },
                enabled: !isProcessing, // Disable field while submitting
              ),
              const SizedBox(height: 16), // Spacing
              // Description/Experience Text Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.yourExperienceLabel, // Localized label
                  alignLabelWithHint: true, // Align label to the top for multiline
                ),
                maxLines: 4, // Allow multiple lines
                minLines: 2, // Start with at least 2 lines visible
                validator: (value) {
                  // Validation: Check if value is null, empty, or only whitespace after trimming
                  if (value == null || value.trim().isEmpty) {
                    return l10n.experienceValidationPrompt; // Localized validation message
                  }
                  return null; // Return null if valid
                },
                enabled: !isProcessing, // Disable field while submitting
              ),
              const SizedBox(height: 20), // Spacing

              // --- Image Selection Button (Single Image) ---
              OutlinedButton.icon(
                // Disable button if an image is already picked OR if processing
                // Use the _pickImage method
                onPressed: _pickedImage != null || isProcessing ? null : _pickImage,
                icon: Icon(
                    // Icon changes based on whether an image is picked
                    _pickedImage != null ? Icons.image_outlined : Icons.image,
                    // Color is disabled if button is disabled
                    color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary
                ),
                label: Text(
                    // Text changes based on whether an image is picked
                    _pickedImage == null
                        ? (l10n.appTitle.contains("መጂወ") ? "ምስል ያክሉ" : "Add Image") // TODO: Localize "Add Image"
                        : (l10n.appTitle.contains("መጂወ") ? "ምስል ተመርጧል" : "Image selected"), // TODO: Localize "Image selected"
                    // Text color is disabled if button is disabled
                    style: TextStyle(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary)
                ),
                style: OutlinedButton.styleFrom(
                   minimumSize: const Size(double.infinity, 48), // Full width
                   side: BorderSide(color: _pickedImage != null || isProcessing ? theme.disabledColor : theme.colorScheme.primary), // Border color
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Rounded corners
                   padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding
                ),
              ),

              // --- Display Single Selected Image Preview ---
              // Conditionally display this container only if an image has been picked
              if (_pickedImage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16), // Spacing from button
                  height: 100, // Fixed height for the image preview container
                  width: 100, // Fixed width for the image preview container
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    border: Border.all(color: theme.dividerColor), // Border
                  ),
                  child: Stack( // Use Stack to place the remove button over the image
                    fit: StackFit.expand, // Stack children expand to fill the container
                    children: [
                       ClipRRect( // Clip the image itself to match container's border radius
                         borderRadius: BorderRadius.circular(8),
                         child: Image.file(
                             // Display the picked image using File from dart:io
                             // Use ! on _pickedImage because the 'if' check ensures it's not null
                             File(_pickedImage!.path),
                             fit: BoxFit.cover, // Cover the container, cropping if necessary
                             // Optional: Handle potential errors loading the local file itself
                             errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, color: theme.colorScheme.error)),
                         ),
                       ),
                       // --- Remove Image Button ---
                       Positioned( // Position the remove button
                            right: 4, // Offset from the right
                            top: 4, // Offset from the top
                            child: isProcessing // Hide the remove button while processing
                                ? const SizedBox.shrink() // Hide button
                                : InkWell( // Make the button tappable
                                    onTap: _removeImage, // Call _removeImage when tapped
                                    child: CircleAvatar( // A circular button
                                      radius: 12, // Size of the circle
                                      backgroundColor: Colors.red[400], // Background color
                                      child: const Icon(Icons.close, size: 16, color: Colors.white), // Close icon
                                    ),
                                  ),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 24), // Spacing before actions
            ],
          ),
        ),
      ),
      // Actions row for dialog buttons
      actions: <Widget>[
        // Cancel Button
        TextButton(
          child: Text(l10n.cancelButton, style: TextStyle(color: isProcessing ? theme.disabledColor : theme.colorScheme.primary)), // Localized text, disabled color when processing
          onPressed: isProcessing ? null : () => Navigator.of(context).pop(false), // Disable when processing, pop with false result
        ),
        // Submit Button
        ElevatedButton(
          // Disable button when processing
          onPressed: isProcessing ? null : _submitTestimonial, // Use _submitTestimonial method
          child: isProcessing
              // Show a loading indicator when processing
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary) // Color of indicator
                  )
                )
              // Show localized text when not processing
              : Text(l10n.submitButtonGeneral), // Localized text
        ),
      ],
    );
  }
}