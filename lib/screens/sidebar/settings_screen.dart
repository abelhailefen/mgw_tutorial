// lib/screens/sidebar/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/theme_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart'; // For T&C and Privacy Policy

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _supportedLanguageCodes = ['en', 'am', 'or'];
  bool _receivePushNotifications = true; // Local UI state

  // TODO: Replace with actual URLs
  final String _privacyPolicyUrl = "https://www.zsecreteducation.com/privacy-policy";
  final String _termsAndConditionsUrl = "https://www.zsecreteducation.com/terms-conditions";

  String _getLanguageDisplayName(BuildContext context, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    switch (langCode) {
      case 'en': return l10n.english;
      case 'am': return l10n.amharic;
      case 'or': return l10n.afaanOromo;
      default: return langCode.toUpperCase();
    }
  }

   Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appTitle.contains("መጂወ") ? "$urlString መክፈት አልተቻለም።" : 'Could not launch $urlString'),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.first;
    }
    bool isCurrentlyDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          SwitchListTile(
            title: Text(l10n.appTitle.contains("መጂወ") ? "ጨለማ ገፅታ" : "Dark Mode", style: theme.listTileTheme.titleTextStyle),
            subtitle: Text(l10n.appTitle.contains("መጂወ") ? "የጨለማ ገፅታን አንቃ ወይም አሰናክል" : "Enable or disable dark theme", style: theme.listTileTheme.subtitleTextStyle),
            value: isCurrentlyDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme(value);
            },
            secondary: Icon(isCurrentlyDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: theme.listTileTheme.iconColor),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.language_outlined, color: theme.listTileTheme.iconColor),
            title: Text(l10n.changeLanguage, style: theme.listTileTheme.titleTextStyle),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentLanguageCode,
                icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                dropdownColor: theme.cardTheme.color, // Use card color for dropdown menu
                onChanged: (String? newLanguageCode) {
                  if (newLanguageCode != null) {
                    localeProvider.setLocale(Locale(newLanguageCode));
                  }
                },
                items: _supportedLanguageCodes
                    .map<DropdownMenuItem<String>>((String langCode) {
                  return DropdownMenuItem<String>(
                    value: langCode,
                    child: Text(_getLanguageDisplayName(context, langCode), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.notifications, style: theme.listTileTheme.titleTextStyle),
            subtitle: Text(l10n.appTitle.contains("መጂወ") ? "ጠቃሚ ዝመናዎችን ተቀበል" : "Receive important updates", style: theme.listTileTheme.subtitleTextStyle),
            value: _receivePushNotifications,
            onChanged: (bool value) {
              setState(() {
                _receivePushNotifications = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.appTitle.contains("መጂወ") ? 'የግፋ ማሳወቂያዎች ${value ? "ነቅተዋል" : "ቆመዋል"}' : 'Push Notifications ${value ? "Enabled" : "Disabled"}'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    behavior: SnackBarBehavior.floating,
                ),
              );
            },
            secondary: Icon(Icons.notifications_active_outlined, color: theme.listTileTheme.iconColor),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.policy_outlined, color: theme.listTileTheme.iconColor),
            title: Text(l10n.privacyPolicyLink, style: theme.listTileTheme.titleTextStyle),
            onTap: () => _launchExternalUrl(context, _privacyPolicyUrl),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: theme.listTileTheme.iconColor),
            title: Text(l10n.termsAndConditionsLink, style: theme.listTileTheme.titleTextStyle),
            onTap: () => _launchExternalUrl(context, _termsAndConditionsUrl),
          ),
          const Divider(),
          if (authProvider.currentUser != null)
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(l10n.logout, style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(l10n.logoutSuccess),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}