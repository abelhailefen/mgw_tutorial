import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class NotRegisteredView extends StatelessWidget {
  final VoidCallback onRegisterNow;

  const NotRegisteredView({super.key, required this.onRegisterNow});

  @override
  Widget build(BuildContext context) {
    
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          Icon(Icons.search_off, size: 100, color: Colors.blue[700]),
          const SizedBox(height: 24),
          Text(
             l10n.notRegisteredTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.notRegisteredSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onRegisterNow,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child:  Text(l10n.getRegisteredNowButton),
          ),
        ],
      ),
    );
  }
}