// lib/screens/account/account_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  File? _profileImageFile;
  bool _notificationsEnabled = true;
  final ImagePicker _picker = ImagePicker();

  final _changePasswordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  final _changePhoneFormKey = GlobalKey<FormState>();
  final _newPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpRequested = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _newPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePicture() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (mounted) {
          setState(() {
            _profileImageFile = File(pickedFile.path);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.profilePictureSelectedMessage),
              backgroundColor: theme.colorScheme.primaryContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorPickingImage(e.toString())),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    setState(() {
      _isCurrentPasswordVisible = false;
      _isNewPasswordVisible = false;
      _isConfirmNewPasswordVisible = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(l10n.changePasswordNotImplementedMessage.split(" ")[0] + " " + l10n.accountPasswordLabel, style: theme.textTheme.titleLarge),
              content: Form(
                key: _changePasswordFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PasswordFormField(
                        controller: _currentPasswordController,
                        isPasswordVisible: _isCurrentPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => _isCurrentPasswordVisible = !_isCurrentPasswordVisible),
                        labelText: l10n.appTitle.contains("መጂወ") ? "የአሁኑ የይለፍ ቃል" : "Current Password",
                        hintText: "",
                        l10n: l10n,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.passwordValidationErrorRequired;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordFormField(
                        controller: _newPasswordController,
                        isPasswordVisible: _isNewPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                        labelText: l10n.appTitle.contains("መጂወ") ? "አዲስ የይለፍ ቃል" : "New Password",
                        hintText: "",
                        l10n: l10n,
                         validator: (value) {
                          if (value == null || value.isEmpty) return l10n.passwordValidationErrorRequired;
                          if (value.length < 6) return l10n.passwordValidationErrorLength;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                       PasswordFormField(
                        controller: _confirmNewPasswordController,
                        isPasswordVisible: _isConfirmNewPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => _isConfirmNewPasswordVisible = !_isConfirmNewPasswordVisible),
                        labelText: l10n.appTitle.contains("መጂወ") ? "አዲስ የይለፍ ቃል አረጋግጥ" : "Confirm New Password",
                        hintText: "",
                        l10n: l10n,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.passwordValidationErrorRequired;
                          if (value != _newPasswordController.text) return l10n.appTitle.contains("መጂወ") ? "የይለፍ ቃሎች አይዛመዱም" : "Passwords do not match";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.appTitle.contains("መጂወ") ? "ሰርዝ" : "Cancel", style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: authProvider.isLoading ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (_changePasswordFormKey.currentState!.validate()) {
                      final result = await authProvider.changePassword(
                        currentPassword: _currentPasswordController.text,
                        newPassword: _newPasswordController.text,
                      );
                      if (mounted) {
                         Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? "An error occurred."), // TODO: Localize
                            backgroundColor: result['success'] ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: authProvider.isLoading
                      ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
                      : Text(l10n.changeButton),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showChangePhoneDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _newPhoneController.clear();
    _otpController.clear();
    setState(() {
      _otpRequested = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(l10n.changePhoneNumberNotImplementedMessage.split(" ")[0] + " " + l10n.phoneNumberLabel, style: theme.textTheme.titleLarge),
              content: Form(
                key: _changePhoneFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (!_otpRequested)
                        PhoneFormField(
                          controller: _newPhoneController,
                          labelText: l10n.appTitle.contains("መጂወ") ? "አዲስ ስልክ ቁጥር" : "New Phone Number",
                          hintText: l10n.phoneNumberHint,
                          l10n: l10n,
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.phoneNumberValidationErrorRequired;
                            final normalizedInput = authProvider.normalizePhoneNumberToE164('0$value');
                            final currentUserPhone = authProvider.currentUser?.phone;
                            if (!RegExp(r'^[0-9]{9}$').hasMatch(value)){
                               return l10n.phoneNumberValidationErrorInvalid;
                            }
                            if (currentUserPhone != null && normalizedInput == currentUserPhone) {
                                return l10n.appTitle.contains("መጂወ") ? "አዲስ ስልክ ቁጥር ከአሁኑ ጋር አንድ መሆን የለበትም" : "New phone number cannot be the same as current.";
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: _otpController,
                          decoration: InputDecoration(labelText: l10n.appTitle.contains("መጂወ") ? "OTP ያስገቡ" : "Enter OTP"),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.appTitle.contains("መጂወ") ? "እባክዎ OTP ያስገቡ" : "Please enter OTP";
                            if (value.length != 6) return l10n.appTitle.contains("መጂወ") ? "OTP 6 አሃዝ መሆን አለበት" : "OTP must be 6 digits";
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.appTitle.contains("መጂወ") ? "ሰርዝ" : "Cancel", style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: authProvider.isLoading ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (_changePhoneFormKey.currentState!.validate()) {
                      if (!_otpRequested) {
                        setDialogState(() {});
                        final result = await authProvider.requestPhoneChangeOTP(
                          newRawPhoneNumber: _newPhoneController.text,
                        );
                        if (mounted) {
                           if (result['success']) {
                            setDialogState(() { _otpRequested = true; });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']!), backgroundColor: theme.colorScheme.primaryContainer, behavior: SnackBarBehavior.floating));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']!), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating));
                          }
                        }
                      } else {
                        setDialogState(() {});
                        final result = await authProvider.verifyOtpAndChangePhone(
                          newRawPhoneNumber: _newPhoneController.text,
                          otp: _otpController.text,
                        );
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? "An error occurred."), // TODO: Localize
                              backgroundColor: result['success'] ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          if (result['success']) {
                            setState(() {});
                          }
                        }
                      }
                    }
                  },
                  child: authProvider.isLoading
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary)))
                    : Text(_otpRequested ? (l10n.appTitle.contains("መጂወ") ? "OTP አረጋግጥ" : "Verify OTP") : (l10n.appTitle.contains("መጂወ") ? "OTP ጠይቅ" : "Request OTP")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logoutSuccess), backgroundColor: theme.colorScheme.primaryContainer, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    String displayName = l10n.guestUser;
    String displayPhone = "";
    String? userProfileNetworkUrl;

    if (currentUser != null) {
      displayName = ('${currentUser.firstName} ${currentUser.lastName}').trim();
      if (displayName.isEmpty) {
        displayName = currentUser.phone;
      }
      displayPhone = currentUser.phone;
      // userProfileNetworkUrl = currentUser.profileImageUrl;
    }

    Widget profilePictureWidget;
    if (_profileImageFile != null) {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_profileImageFile!),
        backgroundColor: theme.colorScheme.surfaceVariant,
      );
    } else if (userProfileNetworkUrl != null && userProfileNetworkUrl.isNotEmpty) {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(userProfileNetworkUrl),
        backgroundColor: theme.colorScheme.surfaceVariant,
      );
    } else {
      profilePictureWidget = CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.person,
          size: 70,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      );
    }

    if (currentUser == null) {
      return Scaffold( // Add Scaffold for consistent background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.pleaseLoginOrRegister, style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false);
                },
                child: Text(l10n.signInLink),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  profilePictureWidget,
                  const SizedBox(height: 8),
                  Text(displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground)),
                  if (displayPhone.isNotEmpty)
                     Text(displayPhone, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: Icon(Icons.edit_outlined, size: 20, color: theme.colorScheme.primary),
                    label: Text(l10n.changeProfilePictureButton, style: TextStyle(color: theme.colorScheme.primary)),
                    onPressed: _changeProfilePicture,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              context: context,
              l10n: l10n,
              label: l10n.accountPhoneNumberLabel,
              value: displayPhone.isNotEmpty ? displayPhone : l10n.appTitle.contains("መጂወ") ? "ስልክ አልተገኘም" : "Phone not available",
              onChange: _showChangePhoneDialog,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context: context,
              l10n: l10n,
              label: l10n.accountPasswordLabel,
              value: '••••••••••',
              onChange: _showChangePasswordDialog,
            ),
            const SizedBox(height: 30),
            Card( // Uses CardTheme
              child: SwitchListTile(
                title: Text(
                  l10n.notificationsLabel,
                  style: theme.textTheme.titleMedium,
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(value ? l10n.notificationsEnabledMessage : l10n.notificationsDisabledMessage),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: theme.colorScheme.onError),
              label: Text(l10n.logout, style: TextStyle(color: theme.colorScheme.onError)),
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required String label,
    required String value,
    required VoidCallback onChange,
  }) {
    final theme = Theme.of(context);
    return Card( // Uses CardTheme
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton( // Changed to ElevatedButton for better theming
              onPressed: onChange,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
              ),
              child: Text(l10n.changeButton),
            ),
          ],
        ),
      ),
    );
  }
}