import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import AppLocalizations

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _userName = "Abebe Beso";
  String _phoneNumber = "0930131133";
  String _profileImageUrl = "";
  File? _profileImageFile;
  bool _notificationsEnabled = true;
  final ImagePicker _picker = ImagePicker();

  Future<void> _changeProfilePicture() async {
    // No need for l10n instance here if context is available when calling ScaffoldMessenger
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
          _profileImageUrl = "";
        });
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profilePictureSelectedMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPickingImage(e.toString()))),
        );
      }
    }
  }

  void _handleChangePhoneNumber() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.changePhoneNumberNotImplementedMessage)),
    );
  }

  void _handleChangePassword() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.changePasswordNotImplementedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    Widget profilePictureWidget;
    if (_profileImageFile != null) {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImageFile!),
        backgroundColor: Colors.grey[300],
      );
    } else if (_profileImageUrl.isNotEmpty) {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(_profileImageUrl),
        backgroundColor: Colors.grey[300],
      );
    } else {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blueGrey[100],
        child: Icon(
          Icons.person,
          size: 70,
          color: Colors.blueGrey[400],
        ),
      );
    }
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  profilePictureWidget,
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _changeProfilePicture,
                    child: Text(
                      l10n.changeProfilePictureButton, // Localized
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildInfoRow(
              context: context,
              l10n: l10n, // Pass l10n
              label: l10n.accountPhoneNumberLabel, // Localized
              value: _phoneNumber,
              onChange: _handleChangePhoneNumber,
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              context: context,
              l10n: l10n, // Pass l10n
              label: l10n.accountPasswordLabel, // Localized
              value: '**********',
              onChange: _handleChangePassword,
            ),
            const SizedBox(height: 30),

            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: SwitchListTile(
                title: Text(
                  l10n.notificationsLabel, // Localized
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(value ? l10n.notificationsEnabledMessage : l10n.notificationsDisabledMessage)), // Localized
                  );
                },
                activeColor: theme.primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required AppLocalizations l10n, // Add l10n parameter
    required String label,
    required String value,
    required VoidCallback onChange,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, // Already localized when passed
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              child: Text(l10n.changeButton), // Localized
            ),
          ],
        ),
      ),
    );
  }
}