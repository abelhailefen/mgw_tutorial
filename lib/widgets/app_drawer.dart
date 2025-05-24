// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <<< FOR Provider.of
import 'package:url_launcher/url_launcher.dart'; // <<< FOR launchUrl, LaunchMode
import 'package:share_plus/share_plus.dart'; // <<< FOR Share
import 'package:mgw_tutorial/l10n/app_localizations.dart';
// Import Providers
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:mgw_tutorial/provider/api_course_provider.dart';
import 'package:mgw_tutorial/provider/testimonial_provider.dart';
import 'package:mgw_tutorial/provider/discussion_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart';

// Import Screens
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/about_us_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/settings_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/discussion_group_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/testimonials_screen.dart';
import 'package:mgw_tutorial/screens/sidebar/my_courses_screen.dart'; // <<< IMPORTED MyCoursesScreen


class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Moved these inside the class or make them static if truly global constants
  // For simplicity, keeping them as instance members for now.
  final String _telegramChannelUrl = "https://t.me/YourTelegramChannelNameOrLink";
  final String _appShareMessage = "Check out MGW Tutorial, a great app for learning! ";
  final String _contactEmail = "support@mgwtutorial.com";
  final String _contactPhoneNumber = "+251900000000";
  final String _websiteUrl = "https://www.zsecreteducation.com";


  Future<void> _launchUrl(BuildContext context, String urlString, {bool isMail = false, bool isTel = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Uri uri;
    if (isMail) {
      uri = Uri(scheme: 'mailto', path: urlString, queryParameters: {'subject': l10n.emailSupportSubject});
    } else if (isTel) {
      uri = Uri(scheme: 'tel', path: urlString);
    } else {
      uri = Uri.parse(urlString);
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
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

  Future<void> _shareApp(BuildContext context) async {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      _appShareMessage, // Use instance member
      subject: l10n.shareAppSubject,
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
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
                title: Text(l10n.contactViaEmail, style: TextStyle(color: theme.listTileTheme.textColor)),
                subtitle: Text(_contactEmail, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))), // Use instance member
                onTap: () {
                  Navigator.of(bCtx).pop();
                  _launchUrl(context, _contactEmail, isMail: true); // Use instance member
                },
              ),
              if (_contactPhoneNumber.isNotEmpty) // Use instance member
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: theme.listTileTheme.iconColor),
                  title: Text(l10n.callUs, style: TextStyle(color: theme.listTileTheme.textColor)),
                  subtitle: Text(_contactPhoneNumber, style: TextStyle(color: theme.listTileTheme.textColor?.withOpacity(0.7))), // Use instance member
                  onTap: () {
                    Navigator.of(bCtx).pop();
                    _launchUrl(context, _contactPhoneNumber, isTel: true); // Use instance member
                  },
                ),
              ListTile(
                leading: Icon(Icons.web_outlined, color: theme.listTileTheme.iconColor),
                title: Text(l10n.visitOurWebsite, style: TextStyle(color: theme.listTileTheme.textColor)),
                onTap: () {
                   Navigator.of(bCtx).pop();
                   _launchUrl(context, _websiteUrl); // Use instance member
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
      SnackBar(
        content: Text(l10n.refreshingData, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        backgroundColor: theme.colorScheme.primaryContainer,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final semesterProvider = Provider.of<SemesterProvider>(context, listen: false);
    final apiCourseProvider = Provider.of<ApiCourseProvider>(context, listen: false);
    final testimonialProvider = Provider.of<TestimonialProvider>(context, listen: false);
    final discussionProvider = Provider.of<DiscussionProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);

    List<Future<void>> refreshFutures = [
      semesterProvider.fetchSemesters(forceRefresh: true),
      apiCourseProvider.fetchCourses(forceRefresh: true),
      testimonialProvider.fetchTestimonials(forceRefresh: true),
      discussionProvider.fetchPosts(),
      departmentProvider.fetchDepartments(),
    ];

    try {
      await Future.wait(refreshFutures);

      if (context.mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dataRefreshed, style: TextStyle(color: theme.colorScheme.onPrimary)),
            backgroundColor: theme.colorScheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        print("Error during global refresh: $e");
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorRefreshingData, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            backgroundColor: theme.colorScheme.errorContainer,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  void _showNotImplemented(BuildContext context, String featureName) {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.actionNotImplemented(featureName), style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
        backgroundColor: theme.colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogout(BuildContext context, AuthProvider authProvider) async {
    Navigator.of(context).pop();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    await authProvider.logout();
    if (context.mounted) {
      Provider.of<SemesterProvider>(context, listen: false).clearSemesters();
      Provider.of<ApiCourseProvider>(context, listen: false).clearError();
      Provider.of<TestimonialProvider>(context, listen: false).clearTestimonials();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.logoutSuccess, style: TextStyle(color: theme.colorScheme.onPrimary)),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String userName = l10n.guestUser;
    String userDetail = l10n.pleaseLoginOrRegister;
    String? userImageUrl;

    Color headerBackgroundColor = theme.colorScheme.primaryContainer;
    Color headerTextColor = theme.colorScheme.onPrimaryContainer;
    Color avatarBackgroundColor = theme.colorScheme.surface;
    Color avatarIconColor = theme.colorScheme.primary;

    if (authProvider.currentUser != null) {
      userName = ('${authProvider.currentUser!.firstName} ${authProvider.currentUser!.lastName}').trim();
      if (userName.isEmpty) userName = authProvider.currentUser!.phone;
      userDetail = authProvider.currentUser!.phone;
    }

    return Drawer(
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
            tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            children: <Widget>[
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.english, onTap: () { localeProvider.setLocale(const Locale('en')); Navigator.of(context).pop(); }),
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.amharic, onTap: () { localeProvider.setLocale(const Locale('am')); Navigator.of(context).pop(); }),
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.afaanOromo, onTap: () { localeProvider.setLocale(const Locale('or')); Navigator.of(context).pop(); }),
              _buildDrawerSubItem(context: context, theme: theme, text: l10n.tigrigna, onTap: () { localeProvider.setLocale(const Locale('ti')); Navigator.of(context).pop(); }),
            ],
          ),
          Divider(color: theme.dividerColor),
          if (authProvider.currentUser != null)
            _buildDrawerItem(
              theme: theme, icon: Icons.my_library_books_outlined,
              text: l10n.mycourses,
              onTap: () => _navigateTo(context, MyCoursesScreen.routeName),
            )
          else
             _buildDrawerItem(
              theme: theme, icon: Icons.app_registration,
              text: l10n.registerforcourses,
              onTap: () {
                 Navigator.of(context).pop();
                 _showNotImplemented(context, l10n.registerforcourses); // Changed to use the common method
              },
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
              isError: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required ThemeData theme,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
    );
  }

  Widget _buildDrawerSubItem({
    required BuildContext context,
    required ThemeData theme,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56.0, right: 16.0),
      title: Text(text, style: TextStyle(color: theme.listTileTheme.textColor, fontSize: 14)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}