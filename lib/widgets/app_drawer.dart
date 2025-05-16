import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart'; // For logout and user info
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Import screen routes for navigation
import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/discussion_group_screen.dart';
import 'package:mgw_tutorial/screens/registration/registration_screen.dart'; // For "Register for courses"

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context); // Listen for user changes
    final l10n = AppLocalizations.of(context)!;

    // User data: Use real data from AuthProvider if available, otherwise fallbacks
    String userName = l10n.guestUser; // Default/fallback
    String userEmailOrPhone = l10n.pleaseLoginOrRegister; // Default/fallback
    String? userImageUrl; // Can be null

    if (authProvider.currentUser != null) {
      userName = '${authProvider.currentUser!.firstName} ${authProvider.currentUser!.lastName}'.trim();
      if (userName.isEmpty) userName = l10n.registeredUser; // If names are empty after login
      userEmailOrPhone = authProvider.currentUser!.phone;
      // TODO: Add logic to get user image URL if your User model supports it
      // userImageUrl = authProvider.currentUser!.profileImageUrl;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(userEmailOrPhone),
            currentAccountPicture: CircleAvatar(
              backgroundImage: userImageUrl != null && userImageUrl.isNotEmpty
                  ? NetworkImage(userImageUrl)
                  : null, // Use NetworkImage if URL exists
              backgroundColor: Colors.white,
              child: userImageUrl == null || userImageUrl.isEmpty
                  ? Icon(Icons.person, size: 40, color: Colors.blue[700]) // Fallback icon
                  : null,
            ),
            decoration: BoxDecoration(
              color: Colors.blue[700], // Consider using Theme.of(context).primaryColor
            ),
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            text: l10n.aboutUs,
            onTap: () => _navigateTo(context, AboutUsScreen.routeName),
          ),
          _buildDrawerItem(
            icon: Icons.star_outline,
            text: l10n.testimonials,
            onTap: () => _showNotImplemented(context, l10n.testimonials),
          ),
          ExpansionTile(
            leading: Icon(Icons.language, color: Colors.grey[700]),
            title: Text(l10n.changeLanguage, style: TextStyle(color: Colors.grey[800])),
            children: <Widget>[
              _buildDrawerSubItem(
                context: context, // Pass context for pop
                text: l10n.english,
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.of(context).pop(); // Close drawer
                },
              ),
              _buildDrawerSubItem(
                context: context,
                text: l10n.amharic,
                onTap: () {
                  localeProvider.setLocale(const Locale('am'));
                  Navigator.of(context).pop(); // Close drawer
                },
              ),
              _buildDrawerSubItem( // Assuming Afaan Oromo 'om' is supported
                context: context,
                text: l10n.afaanOromo,
                onTap: () {
                  localeProvider.setLocale(const Locale('om'));
                   Navigator.of(context).pop(); // Close drawer
                },
              ),
                _buildDrawerSubItem( // Assuming Afaan Oromo 'om' is supported
                context: context,
                text: l10n.afaanOromo,
                onTap: () {
                  localeProvider.setLocale(const Locale('tg'));
                   Navigator.of(context).pop(); // Close drawer
                },
              ),
            ],
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.app_registration,
            text: l10n.registerforcourses, // This could lead to RegistrationScreen
            onTap: () {
              Navigator.of(context).pop(); // Close drawer first
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistrationScreen()));
            },
          ),
          _buildDrawerItem(
            icon: Icons.my_library_books_outlined,
            text: l10n.mycourses,
            onTap: () => _showNotImplemented(context, l10n.mycourses),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today_outlined,
            text: l10n.weeklyexam,
            onTap: () => _showNotImplemented(context, l10n.weeklyexam),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.share_outlined,
            text: l10n.sharetheapp,
            onTap: () => _showNotImplemented(context, l10n.sharetheapp), // Implement with `share_plus` package
          ),
          _buildDrawerItem(
            icon: Icons.send_outlined,
            text: l10n.joinourtelegram,
            onTap: () => _showNotImplemented(context, l10n.joinourtelegram), // Implement with `url_launcher`
          ),
          _buildDrawerItem(
            icon: Icons.group_outlined,
            text: l10n.discussiongroup,
            onTap: () => _navigateTo(context, DiscussionGroupScreen.routeName), // Navigate to DiscussionGroupScreen
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.refresh_outlined,
            text: l10n.refresh,
            onTap: () { // Implement a refresh mechanism, e.g., refetch data
              Navigator.of(context).pop();
              // Example: refetch data from a provider
              // Provider.of<YourDataProvider>(context, listen: false).fetchData();
              _showNotImplemented(context, l10n.refresh);
            },
          ),
          _buildDrawerItem(
            icon: Icons.contact_support_outlined,
            text: l10n.contactus,
            onTap: () => _showNotImplemented(context, l10n.contactus), // Implement with `url_launcher` for mail/phone
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: l10n.settings,
            onTap: () => _navigateTo(context, SettingsScreen.routeName),
          ),
          const Divider(),
          // Only show logout if user is logged in
          if (authProvider.currentUser != null)
            _buildDrawerItem(
              icon: Icons.logout,
              text: l10n.logout,
              onTap: () => _handleLogout(context, authProvider),
              color: Colors.red[700],
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(text, style: TextStyle(color: color ?? Colors.grey[800], fontSize: 15)),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildDrawerSubItem({
    required BuildContext context, // Added context here
    required String text,
    required GestureTapCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56.0), // Adjusted indent for sub-items
      title: Text(text, style: TextStyle(color: color ?? Colors.grey[800], fontSize: 14)),
      onTap: onTap, // onTap should handle Navigator.pop(context) if it's closing the drawer
      dense: true,
    );
  }

  // Helper for navigation to named routes
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pop(); // Close the drawer first
    Navigator.of(context).pushNamed(routeName);
  }

  // Helper for showing "Not Implemented"
  void _showNotImplemented(BuildContext context, String featureName) {
    Navigator.of(context).pop(); // Close the drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName: Not Implemented Yet')),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    Navigator.of(context).pop(); // Close the drawer
    await authProvider.logout(); // Call logout method from provider
    // Navigate to LoginScreen and remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false, // This predicate removes all routes
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.logoutSuccess)), // TODO: Add "logoutSuccess" to l10n
    );
  }
}