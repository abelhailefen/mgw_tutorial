import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  // Define the routeName for navigation
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  bool _receivePushNotifications = true;
  bool _receiveEmailUpdates = false;

  final List<String> _languages = ['English', 'Amarigna', 'Afaan Oromo'];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView( // ListView is good for settings pages
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable or disable dark theme'),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              // TODO: Implement actual theme switching logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dark Mode ${value ? "Enabled" : "Disabled"} (UI not changed yet)')),
              );
            },
            secondary: Icon(_darkModeEnabled ? Icons.dark_mode : Icons.light_mode),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(), // Hide default underline
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguage = newValue;
                  });
                  // TODO: Implement actual language switching logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language set to $newValue (App not localized yet)')),
                  );
                }
              },
              items: _languages.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive important updates'),
            value: _receivePushNotifications,
            onChanged: (bool value) {
              setState(() {
                _receivePushNotifications = value;
              });
              // TODO: Update notification preferences with backend/Firebase
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          SwitchListTile(
            title: const Text('Email Updates'),
            subtitle: const Text('Receive news and offers via email'),
            value: _receiveEmailUpdates,
            onChanged: (bool value) {
              setState(() {
                _receiveEmailUpdates = value;
              });
              // TODO: Update email preferences with backend
            },
            secondary: const Icon(Icons.email_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Navigate to Privacy Policy screen or web view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Privacy Policy (Not Implemented)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Navigate to Terms of Service screen or web view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View Terms of Service (Not Implemented)')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[700]),
            title: Text('Logout', style: TextStyle(color: Colors.red[700])),
            onTap: () {
              // This should use the same logout logic as in AppDrawer
              // For now, just navigate.
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/signup',
                (Route<dynamic> route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged Out Successfully')),
              );
            },
          ),
        ],
      ),
    );
  }
}