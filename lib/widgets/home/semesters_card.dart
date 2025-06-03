// lib/widgets/home/semesters_card.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/screens/enrollment/order_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class SemestersCard extends StatelessWidget {
  final Semester semester;
  final VoidCallback? customOnTap;

  const SemestersCard({
    super.key,
    required this.semester,
    this.customOnTap,
  });

  void _handleEnrollAction(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (authProvider.currentUser != null) {
      Navigator.pushNamed(
        context,
        OrderScreen.routeName,
        arguments: semester,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseLoginOrRegister, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.signInLink.toUpperCase(),
            textColor: theme.colorScheme.onErrorContainer,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        )
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String displayTitle = '${semester.name} - ${semester.year}';
    String displayImageUrl = semester.firstImageUrl ?? 'https://via.placeholder.com/600x300.png?text=Semester+Image';
    List<String> displaySubjectsLeft = [];
    List<String> displaySubjectsRight = [];
    for (int i = 0; i < semester.courses.length; i++) {
      if (i.isEven) {
        displaySubjectsLeft.add(semester.courses[i].name);
      } else {
        displaySubjectsRight.add(semester.courses[i].name);
      }
    }
    if (semester.courses.isEmpty) {
      displaySubjectsLeft.add(l10n.coursesDetailsComingSoon);
    }
    String displayPrice = semester.price;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: customOnTap ?? () => _handleEnrollAction(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      displayImageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: theme.colorScheme.surfaceVariant,
                        child: Center(child: Icon(Icons.broken_image, color: theme.colorScheme.onSurfaceVariant, size: 50)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: displaySubjectsLeft
                              .map((subject) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text('• $subject', style: theme.textTheme.bodyMedium),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: displaySubjectsRight
                              .map((subject) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text('• $subject', style: theme.textTheme.bodyMedium),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Chip(
                  label: Text('$displayPrice ${l10n.currencySymbol}', style: theme.chipTheme.labelStyle?.copyWith(fontSize: 14)),
                  backgroundColor: theme.chipTheme.backgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.shopping_cart_checkout_outlined, size: 18, color: theme.colorScheme.onPrimary),
                  label: Text(
                    l10n.enrollNowButton,
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onPrimary)
                  ),
                  onPressed: () => _handleEnrollAction(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}