import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:mgw_tutorial/provider/locale_provider.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the LocaleProvider 
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // Access AppLocalizations for drawer text
    final l10n = AppLocalizations.of(context)!;
   
    // Mock user data - 
    const String userName = "Abebe Beso";
    const String userPhone = "+251 912 344 565";
    const String userImageUrl = "https://via.placeholder.com/150/007BFF/FFFFFF?Text=User"; // Placeholder image

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(userPhone),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: NetworkImage(userImageUrl),
              backgroundColor: Colors.white,
            ),
            decoration: BoxDecoration(
              color: Colors.blue[700],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.info_outline,
            text: l10n.aboutUs,
      
            onTap: () => _handleNavigation(context, 'About Us'),
          ),
          _buildDrawerItem(
            icon: Icons.star_outline,
            text: l10n.testimonials,
            onTap: () => _handleNavigation(context, 'Testimonials'),
          ),
          ExpansionTile(
            leading: Icon(Icons.language, color: Colors.grey[700]),
            title: Text(l10n.changeLanguage, style: TextStyle(color: Colors.grey[800])),
            children: <Widget>[
              _buildDrawerSubItem(
                text: l10n.english,
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.of(context).pop(); 
                },
              ),
              _buildDrawerSubItem(
                text: l10n.amharic,
                onTap: () {
                  localeProvider.setLocale(const Locale('am'));
                  Navigator.of(context).pop(); 
                },
              ),
              _buildDrawerSubItem(
                text: l10n.afaanOromo,
                onTap: () => _handleNavigation(context, 'Language: Afaan Oromo'),
              ),
            ],
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.app_registration,
            text: l10n.registerforcourses,
            onTap: () => _handleNavigation(context, 'Register for courses'),
          ),
          _buildDrawerItem(
            icon: Icons.my_library_books_outlined,
            text: l10n.mycourses,
            onTap: () => _handleNavigation(context, 'My courses'),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today_outlined,
            text: l10n.weeklyexam,
            onTap: () => _handleNavigation(context, 'Weekly exams'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.share_outlined,
            text: l10n.sharetheapp,
            onTap: () => _handleNavigation(context, 'Share the app'),
          ),
          _buildDrawerItem(
            icon: Icons.send_outlined, 
            text: l10n.joinourtelegram,
            onTap: () => _handleNavigation(context, 'Join our telegram'),
          ),
          _buildDrawerItem(
            icon: Icons.group_outlined,
            text: l10n.discussiongroup,
            onTap: () => _handleNavigation(context, 'Discussion group'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.refresh_outlined,
            text: l10n.refresh,
            onTap: () => _handleNavigation(context, 'Refresh the app'),
          ),
          _buildDrawerItem(
            icon: Icons.contact_support_outlined,
            text: l10n.contactus,
            onTap: () => _handleNavigation(context, 'Contact us'),
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: l10n.settings,
            onTap: () => _handleNavigation(context, 'Settings'),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            text: l10n.logout,
            onTap: () => _handleLogout(context),
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
      title: Text(text, style: TextStyle(color: color ?? Colors.grey[800])),
      onTap: onTap,
    );
  }

   Widget _buildDrawerSubItem({
    required String text,
    required GestureTapCallback onTap,
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72.0), // Indent sub-items
      title: Text(text, style: TextStyle(color: color ?? Colors.grey[800])),
      onTap: onTap,
    );
  }

  void _handleNavigation(BuildContext context, String itemTitle) {
  Navigator.of(context).pop(); // Close the drawer

  switch (itemTitle) {
    case 'About Us':
      //Navigator.of(context).pushNamed(AboutUsScreen.routeName); // Uses the named route
      break;
    case 'Settings':
      //Navigator.of(context).pushNamed(SettingsScreen.routeName); // Uses the named route
      break;
    // ... other cases
    default:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigate to: $itemTitle (Route Not Implemented)')),
      );
  }
}

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pop(); // Close the drawer
    // Implement actual logout logic here
    // e.g., clear user session, navigate to SignUpScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout Tapped (Not Implemented)')),
    );
   
  }
}