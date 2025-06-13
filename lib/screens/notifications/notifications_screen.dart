// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart'; // Correct localization import
import 'package:mgw_tutorial/provider/notification_provider.dart'; // CORRECTED: Path adjusted to 'provider'
import 'package:mgw_tutorial/screens/notifications/notification_list_view.dart'; // Correct path
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Correct localization access

    return Scaffold(
    
      body: ChangeNotifierProvider(
        create: (_) => NotificationProvider(),
        child: const NotificationListView(),
      ),
    );
  }
}