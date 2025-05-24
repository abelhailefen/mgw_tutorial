// lib/screens/library/not_registered_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class NotRegisteredView extends StatelessWidget {
  final VoidCallback onRegisterNow;

  const NotRegisteredView({super.key, required this.onRegisterNow});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding( // Added padding for better spacing from edges
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 100, color: theme.colorScheme.primary.withOpacity(0.8)),
            const SizedBox(height: 24),
            Text(
               l10n.notRegisteredTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.notRegisteredSubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.75)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRegisterNow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child:  Text(l10n.getRegisteredNowButton),
            ),
          ],
        ),
      ),
    );
  }
}