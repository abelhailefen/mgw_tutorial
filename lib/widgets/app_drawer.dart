// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/theme_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// Import screen routes for navigation
import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/discussion_group_screen.dart';
import 'package:mgw_tutorial/screens/registration/registration_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/testimonials_screen.dart';

// Import Providers to call their fetch methods
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  final String _telegramChannelUrl = "https://t.me/YourTelegramChannelNameOrLink"; // Replace
  final String _appShareLink = "https://play.google.com/store/apps/details?id=com.example.mgw_tutorial"; // Replace
  final String _appShareMessage = "Check out MGW Tutorial, a great app for learning! ";
  final String _contactEmail = "support@mgwtutorial.com"; // Replace
  final String _contactPhoneNumber = "+251900000000"; // Replace
  final String _websiteUrl = "https://www.zsecreteducation.com"; // Replace


  Future<void> _launchUrl(BuildContext context, String urlString, {bool isMail = false, bool isTel = false}) async {
    final l10n = AppLocalizations.of(context)!;
    Uri uri;
    if (isMail) {
      uri = Uri(scheme: 'mailto', path: urlString, queryParameters: {'subject': 'App Support Query'});
    } else if (isTel) {
      uri = Uri(scheme: 'tel', path: urlString);
    } else {
      uri = Uri.parse(urlString);
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? "$urlString መክፈት አልተቻለም።" : 'Could not launch $urlString')),
        );
      }
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    Navigator.of(context).pop();
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _appShareMessage + _appShareLink,
      subject: 'MGW Tutorial App', // TODO: Localize
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void _showContactOptions(BuildContext context) {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      builder: (BuildContext bCtx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.email_outlined, color: theme.listTileTheme.iconColor),
                title: Text(l10n.appTitle.contains("መጂወ") ? "በኢሜል ያግኙን" : "Contact via Email", style: TextStyle(color: theme.listTileTheme.textColor)),
                subtitle: Text(_contactEmail, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))),
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _launchUrl(context, _contactEmail, isMail: true);
                },
              ),
              if (_contactPhoneNumber.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: theme.listTileTheme.iconColor),
                  title: Text(l10n.appTitle.contains("መጂወ") ? "በስልክ ይደውሉ" : "Call Us", style: TextStyle(color: theme.listTileTheme.textColor)),
                  subtitle: Text(_contactPhoneNumber, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))),
                  onTap: () {
                    Navigator.of(bCtx).pop();
                    _launchUrl(context, _contactPhoneNumber, isTel: true);
                  },
                ),
              ListTile(
                leading: Icon(Icons.web_outlined, color: theme.listTileTheme.iconColor),
                title: Text(l10n.appTitle.contains("መጂወ") ? "የእኛን ድረ-ገጽ ይጎብኙ" : "Visit our Website", style: TextStyle(color: theme.listTileTheme.textColor)),
                onTap: () {
                   Navigator.of(bCtx).pop();
                   _launchUrl(context, _websiteUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? "ዳታ እየታደሰ ነው..." : 'Refreshing data...'), duration: const Duration(seconds: 2)),
    );
    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
    final apiCourseProvider = Provider.of<ApiCourseProvider>(context, listen: false);
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    try {
      await semesterProvider.fetchSemesters(forceRefresh: true);
      await apiCourseProvider.fetchCourses();
      await testimonialProvider.fetchTestimonials(forceRefresh: true);
      await discussionProvider.fetchPosts();
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? "ዳታ ታድሷል!" : 'Data refreshed!'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.appTitle.contains("መጂወ") ? "ዳታ በማደስ ላይ ስህተት፡ " : "Error refreshing data: "}${e.toString()}'),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating), // Optional: for better visibility
        );
      }
    }
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(routeName);
  }

  void _showNotImplemented(BuildContext context, String featureName) {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName: ${l10n.appTitle.contains("መጂወ") ? "ገና አልተተገበረም" : "Not Implemented Yet"}')),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    await authProvider.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logoutSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false); // No need to listen if only reading once
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context); // Get the current theme

    String userName = l10n.guestUser;
    String userDetail = l10n.pleaseLoginOrRegister;
    String? userImageUrl; // Placeholder for user profile image URL

    Color headerBackgroundColor = theme.colorScheme.primaryContainer;
    Color headerTextColor = theme.colorScheme.onPrimaryContainer;
    Color avatarBackgroundColor = theme.colorScheme.surface;
    Color avatarIconColor = theme.colorScheme.primary;


    if (authProvider.currentUser != null) {
      userName = ('${authProvider.currentUser!.firstName} ${authProvider.currentUser!.lastName}').trim();
      if (userName.isEmpty) userName = authProvider.currentUser!.phone;
      userDetail = authProvider.currentUser!.phone;
      // userImageUrl = authProvider.currentUser?.profilePictureUrl; // If you have this
    }

    return Drawer(
      // backgroundColor will be set by theme.drawerTheme.backgroundColor
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
             accountName: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: headerTextColor)),
             accountEmail: Text(userDetail, style: TextStyle(color: headerTextColor.withOpacity(0.85))),
             currentAccountPicture: CircleAvatar(
               backgroundImage: userImageUrl != null && userImageUrl.isNotEmpty ? NetworkImage(userImageUrl) : null,
               backgroundColor: avatarBackgroundColor,
               child: (userImageUrl == null || userImageUrl.isEmpty) ? Icon(Icons.person, size: 40, color: avatarIconColor) : null,
             ),
             decoration: BoxDecoration(color: headerBackgroundColor),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.info_outline, text: l10n.aboutUs,
            onTap: () => _navigateTo(context, AboutUsScreen.routeName),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.star_border_purple500_outlined, text: l10n.testimonials,
            onTap: () => _navigateTo(context, TestimonialsScreen.routeName),
          ),
          ExpansionTile(
            leading: Icon(Icons.language, color: theme.listTileTheme.iconColor, size: 22),
            title: Text(l10n.changeLanguage, style: TextStyle(color: theme.listTileTheme.textColor, fontSize: 14.5)),
            iconColor: theme.listTileTheme.iconColor,
            collapsedIconColor: theme.listTileTheme.iconColor,
            childrenPadding: const EdgeInsets.only(left: 16.0),
            children: <Widget>[
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.english, onTap: () { localeProvider.setLocale(const Locale('en')); Navigator.of(context).pop(); }),
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.amharic, onTap: () { localeProvider.setLocale(const Locale('am')); Navigator.of(context).pop(); }),
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.afaanOromo, onTap: () { localeProvider.setLocale(const Locale('or')); Navigator.of(context).pop(); }),
            ],
          ),
          Divider(color: theme.dividerColor),
          _buildDrawerItem(
            theme: theme, icon: Icons.app_registration, text: l10n.registerforcourses,
            onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegistrationScreen())); },
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.school_outlined, text: l10n.mycourses,
            onTap: () => _showNotImplemented(context, l10n.mycourses),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.assignment_turned_in_outlined, text: l10n.weeklyexam,
            onTap: () => _showNotImplemented(context, l10n.weeklyexam),
          ),
          Divider(color: theme.dividerColor),
          _buildDrawerItem(
            theme: theme, icon: Icons.share_outlined, text: l10n.sharetheapp,
            onTap: () => _shareApp(context),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.telegram, text: l10n.joinourtelegram,
            onTap: () {
              Navigator.of(context).pop();
              _launchUrl(context, _telegramChannelUrl);
            },
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.forum_outlined, text: l10n.discussiongroup,
            onTap: () => _navigateTo(context, DiscussionGroupScreen.routeName),
          ),
          Divider(color: theme.dividerColor),
          _buildDrawerItem(
            theme: theme, icon: Icons.refresh_outlined, text: l10n.refresh,
            onTap: () => _handleRefresh(context),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.contact_phone_outlined, text: l10n.contactus,
            onTap: () => _showContactOptions(context),
          ),
          _buildDrawerItem(
            theme: theme, icon: Icons.settings_outlined, text: l10n.settings,
            onTap: () => _navigateTo(context, SettingsScreen.routeName),
          ),
          Divider(color: theme.dividerColor),
          if (authProvider.currentUser != null)
            _buildDrawerItem(
              theme: theme, icon: Icons.logout, text: l10n.logout,
              onTap: () => _handleLogout(context, authProvider),
              isError: true, // Special flag for logout color
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required ThemeData theme, // Pass theme
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
    bool isError = false,
  }) {
    Color? iconColor = isError ? theme.colorScheme.error : theme.listTileTheme.iconColor;
    Color? textColor = isError ? theme.colorScheme.error : theme.listTileTheme.textColor;

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(text, style: TextStyle(color: textColor, fontSize: 14.5)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDrawerSubItem({
    required BuildContext context,
    required ThemeData theme, // Pass theme
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56.0),
      title: Text(text, style: TextStyle(color: theme.listTileTheme.textColor, fontSize: 14)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}