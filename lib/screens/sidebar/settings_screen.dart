// lib/screens/sidebar/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/theme_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _supportedLanguageCodes = ['en', 'am', 'or'];
  bool _receivePushNotifications = true;

  String _getLanguageDisplayName(BuildContext context, String langCode) {
    final l10n = AppLocalizations.of(context)!;
    switch (langCode) {
      case 'en': return l10n.english;
      case 'am': return l10n.amharic;
      case 'or': return l10n.afaanOromo;
      default: return langCode.toUpperCase();
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotLaunchUrl(urlString), style: TextStyle(color: theme.colorScheme.onErrorContainer)),
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

    bool isCurrentlyDarkMode;
    switch (themeProvider.themeMode) {
      case ThemeMode.dark: isCurrentlyDarkMode = true; break;
      case ThemeMode.light: isCurrentlyDarkMode = false; break;
      case ThemeMode.system:
        isCurrentlyDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          SwitchListTile(
            title: Text(l10n.darkModeLabel, style: TextStyle(color: theme.listTileTheme.textColor)),
            subtitle: Text(l10n.darkModeSubtitle, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))),
            value: isCurrentlyDarkMode,
            onChanged: (bool value) {
              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(
              isCurrentlyDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: theme.listTileTheme.iconColor,
            ),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.language, color: theme.listTileTheme.iconColor),
            title: Text(l10n.changeLanguage, style: TextStyle(color: theme.listTileTheme.textColor)),
            trailing: DropdownButton<String>(
              value: currentLanguageCode,
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
              dropdownColor: theme.popupMenuTheme.color ?? theme.cardColor,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              onChanged: (String? newLanguageCode) {
                if (newLanguageCode != null) {
                  localeProvider.setLocale(Locale(newLanguageCode));
                }
              },
              items: _supportedLanguageCodes
                  .map<DropdownMenuItem<String>>((String langCode) {
                return DropdownMenuItem<String>(
                  value: langCode,
                  child: Text(_getLanguageDisplayName(context, langCode)),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.notifications, style: TextStyle(color: theme.listTileTheme.textColor)),
            subtitle: Text(l10n.receiveNotificationsSubtitle, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))),
            value: _receivePushNotifications,
            onChanged: (bool value) {
              setState(() {
                _receivePushNotifications = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                      value ? l10n.pushNotificationsEnabled : l10n.pushNotificationsDisabled,
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer)
                    ),
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
            title: Text(l10n.privacyPolicyLink, style: TextStyle(color: theme.listTileTheme.textColor)),
            onTap: () {
              // _launchUrl("https://www.yourwebsite.com/privacy-policy"); 
              ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                content: Text(l10n.actionNotImplemented(l10n.viewPrivacyPolicyAction)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: theme.listTileTheme.iconColor),
            title: Text(l10n.termsAndConditionsLink, style: TextStyle(color: theme.listTileTheme.textColor)),
            onTap: () {
              // _launchUrl("https://www.yourwebsite.com/terms-of-service");
              ScaffoldMessenger.of(context).showSnackBar( SnackBar(
                content: Text(l10n.actionNotImplemented(l10n.viewTermsAction)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
              ));
            },
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
                      content: Text(
                        l10n.logoutSuccess,
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
                      backgroundColor: theme.colorScheme.primary,
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