//lib/screens/library/registration_pending_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class RegistrationPendingView extends StatelessWidget {
  const RegistrationPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // For localization
    final theme = Theme.of(context);

    return Center(
      child: Padding( // Added padding
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_outlined, size: 100, color: theme.colorScheme.secondary), // Changed icon
            const SizedBox(height: 24),
            Text(
              // TODO: Localize this string if not already
              l10n.appTitle.contains("መጂወ") ? 'ጥያቄዎ በማረጋገጥ ላይ ነው።' : 'Your request is under verification.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              // TODO: Localize this string if not already
              l10n.appTitle.contains("መጂወ")
                  ? 'ጥያቄዎ ከተረጋገጠ በኋላ ሰፊ የፒዲኤፎች፣ ማስታወሻዎች እና የቪዲዮ ትምህርቶች ቤተ-መጽሐፍታችንን ማግኘት ይችላሉ።'
                  : 'You will gain access to our extensive library of pdfs, notes and video tutorials once your request is verified.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.75)),
            ),
          ],
        ),
      ),
    );
  }
}