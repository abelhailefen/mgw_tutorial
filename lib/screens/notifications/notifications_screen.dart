// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

// Assuming your AppLocalizations has keys like:
// "notificationsTitle": "Notifications" (and its translated versions)
// "noNotificationsMessage": "You have no notifications yet" (and its translated versions)

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // In a real app, you would fetch the actual notifications here.
    // For this example, we'll assume there are no notifications
    // and only show the empty state as your original code did.
    final bool notificationsListIsEmpty = true; // Replace with your actual list check

    return Scaffold(
      // Added AppBar for standard screen title
      appBar: AppBar(
        title: Text(l10n.notificationsTitle), // Use dedicated localization key for title
        // You can customize the title style if needed:
        // titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary),
      ),
      // Using FutureBuilder or similar would go here to load notifications
      body: notificationsListIsEmpty
          ? Padding( // Added padding around the content
              padding: const EdgeInsets.all(24.0), // Standard padding
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Ensure column doesn't take up unnecessary width if content is small
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 80, // Kept original size
                      // Using colorScheme for better theme integration
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: 20), // Increased spacing slightly
                    Text(
                      // FIXED: Use a dedicated localization key for the message
                      l10n.noNotificationsMessage, // This key should exist in your ARB files
                      style: theme.textTheme.titleMedium?.copyWith(
                        // Using colorScheme for text color
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Optional: Add a button to open settings, etc.
                  ],
                ),
              ),
            )
          : const Text("TODO: Display the list of notifications here"), // Placeholder for actual list view
    );
  }
}

