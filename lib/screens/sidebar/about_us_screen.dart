// lib/screens/sidebar/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // For localization
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

class AboutUsScreen extends StatelessWidget {
  static const String routeName = '/about-us';
  const AboutUsScreen({super.key});

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

  Future<void> _launchEmail(BuildContext context, String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'MGW Tutorial App Inquiry'}, // TODO: Localize subject
    );
    await _launchExternalUrl(context, emailLaunchUri.toString());
  }

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: phoneNumber);
    await _launchExternalUrl(context, phoneLaunchUri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // For localization
    final theme = Theme.of(context);

    // TODO: Replace with actual contact info and localize texts
    final String contactEmail = "info@mgwtutorial.com";
    final String contactPhone = "+251 9XX XXX XXX";
    final String websiteUrl = "https://www.zsecreteducation.com"; // Example

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutUs),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.welcomeMessage, // Assuming this is suitable
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              // TODO: Localize this paragraph
              l10n.appTitle.contains("መጂወ")
                  ? 'መጂወ አስጠኚ ተማሪዎች በትምህርታቸው የላቀ ውጤት እንዲያስመዘግቡ ለመርዳት ከፍተኛ ጥራት ያላቸውን የትምህርት መርጃዎች ለማቅረብ ቁርጠኛ ነው። የእኛ መድረክ ሰፊ የሆኑ ትምህርቶችን፣ ማስታወሻዎችን፣ የተግባር ፈተናዎችን እና ሌሎችንም ከሥርዓተ ትምህርቱ ጋር የተጣጣሙ ያቀርባል።'
                  : 'MGW Tutorial is dedicated to providing high-quality educational resources to help students excel in their studies. Our platform offers a wide range of tutorials, notes, practice exams, and more, tailored to the curriculum.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              // TODO: Localize "Our Mission"
              l10n.appTitle.contains("መጂወ") ? 'የእኛ ተልዕኮ' : 'Our Mission',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              // TODO: Localize this paragraph
              l10n.appTitle.contains("መጂወ")
                  ? 'ተማሪዎችን የአካዳሚክ ስኬት እንዲያገኙ እና ሙሉ አቅማቸውን እንዲከፍቱ የሚያስፈልጋቸውን እውቀትና መሳሪያዎች ማስታጠቅ።'
                  : 'To empower students with the knowledge and tools they need to achieve academic success and unlock their full potential.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.contactus,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.email_outlined, color: theme.listTileTheme.iconColor),
              title: Text(contactEmail, style: TextStyle(color: theme.listTileTheme.textColor)),
              onTap: () => _launchEmail(context, contactEmail),
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined, color: theme.listTileTheme.iconColor),
              title: Text(contactPhone, style: TextStyle(color: theme.listTileTheme.textColor)),
              onTap: () => _launchPhone(context, contactPhone),
            ),
            ListTile(
              leading: Icon(Icons.web_outlined, color: theme.listTileTheme.iconColor),
              title: Text(l10n.appTitle.contains("መጂወ") ? "ድረ-ገጻችንን ይጎብኙ" : "Visit our Website", style: TextStyle(color: theme.listTileTheme.textColor)), // TODO: Localize
              onTap: () => _launchExternalUrl(context, websiteUrl),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© ${DateTime.now().year} MGW Tutorial. All rights reserved.', // TODO: Localize
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            )
          ],
        ),
      ),
    );
  }
}