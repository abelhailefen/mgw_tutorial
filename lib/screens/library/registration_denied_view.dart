//lib/screens/library/registration_denied_view.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class RegistrationDeniedView extends StatelessWidget {
  final VoidCallback onRegisterNow;
  const RegistrationDeniedView({super.key, required this.onRegisterNow});

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
            Icon(Icons.cancel_outlined, size: 100, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              // TODO: Localize this string if not already
              l10n.appTitle.contains("መጂወ") ? 'ጥያቄዎ ውድቅ ተደርጓል!' : 'Your request has been denied!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              // TODO: Localize this string if not already
              l10n.appTitle.contains("መጂወ")
                  ? 'የላኩት ቅጽበታዊ ገጽ እይታ ልክ ስላልነበር ጥያቄዎ ውድቅ ተደርጓል። እባክዎ ትክክለኛ ቅጽበታዊ ገጽ እይታ ያቅርቡ።'
                  : 'Your request has been denied because the screenshot you have sent was invalid. Please provide a valid screenshot.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onBackground.withOpacity(0.75)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRegisterNow,
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(l10n.getRegisteredNowButton), // Use localized string
            ),
          ],
        ),
      ),
    );
  }
}