// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold( // Added Scaffold for consistent theming
      body: Center(
        child: Column( // For icon + text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.appTitle.contains("መጂወ") ? 'እስካሁን ምንም ማሳወቂያዎች የሉዎትም።' : 'You have no notifications yet',
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        )
      ),
    );
  }
}