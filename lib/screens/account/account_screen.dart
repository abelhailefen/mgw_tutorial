import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _notificationsEnabled = true;

  final _changePasswordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;

  final _changePhoneFormKey = GlobalKey<FormState>();
  final _newPhoneController = TextEditingController();

  final _changeNameFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _newPhoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _showThemedSuccessSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemedErrorSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
        backgroundColor: theme.colorScheme.errorContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangeNameDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _firstNameController.text = authProvider.currentUser?.firstName ?? '';
    _lastNameController.text = authProvider.currentUser?.lastName ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: true);

            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text('Change Name', style: theme.textTheme.titleLarge),
              content: Form(
                key: _changeNameFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'First name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Last name is required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: authProvider.isLoading ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_changeNameFormKey.currentState!.validate()) {
                            final result = await authProvider.changeName(
                              firstName: _firstNameController.text,
                              lastName: _lastNameController.text,
                            );
                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            if (result['success']) {
                              _showThemedSuccessSnackBar(result['message'] ?? 'Name changed successfully');
                            } else {
                              _showThemedErrorSnackBar(result['message'] ?? 'Failed to change name');
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                          ))
                      : Text(l10n.changeButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    bool localIsCurrentPasswordVisible = false;
    bool localIsNewPasswordVisible = false;
    bool localIsConfirmNewPasswordVisible = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: true);

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
                        isPasswordVisible: localIsCurrentPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => localIsCurrentPasswordVisible = !localIsCurrentPasswordVisible),
                        labelText: l10n.currentPasswordLabel,
                        l10n: l10n,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.passwordValidationErrorRequired;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordFormField(
                        controller: _newPasswordController,
                        isPasswordVisible: localIsNewPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => localIsNewPasswordVisible = !localIsNewPasswordVisible),
                        labelText: l10n.newPasswordLabel,
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
                        isPasswordVisible: localIsConfirmNewPasswordVisible,
                        onToggleVisibility: () => setDialogState(() => localIsConfirmNewPasswordVisible = !localIsConfirmNewPasswordVisible),
                        labelText: l10n.confirmNewPasswordLabel,
                        l10n: l10n,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.passwordValidationErrorRequired;
                          if (value != _newPasswordController.text) return l10n.passwordsDoNotMatch;
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: authProvider.isLoading ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_changePasswordFormKey.currentState!.validate()) {
                            final result = await authProvider.changePassword(
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                            );
                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            if (result['success']) {
                              _showThemedSuccessSnackBar(result['message'] ?? l10n.passwordChangedSuccess);
                            } else {
                              _showThemedErrorSnackBar(result['message'] ?? l10n.passwordChangeFailed);
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                          ))
                      : Text(l10n.changeButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePhoneDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    _newPhoneController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final authProvider = Provider.of<AuthProvider>(context, listen: true);

            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text(l10n.changePhoneNumberNotImplementedMessage.split(" ")[0] + " " + l10n.phoneNumberLabel, style: theme.textTheme.titleLarge),
              content: Form(
                key: _changePhoneFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      PhoneFormField(
                        controller: _newPhoneController,
                        labelText: l10n.newPhoneNumberLabel,
                        hintText: l10n.phoneNumberHint,
                        l10n: l10n,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.phoneNumberValidationErrorRequired;
                          final normalizedInput = authProvider.normalizePhoneNumberToE164('0$value');
                          final currentUserPhone = authProvider.currentUser?.phone;
                          if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
                            return l10n.phoneNumberValidationErrorInvalid;
                          }
                          if (currentUserPhone != null && normalizedInput == currentUserPhone) {
                            return l10n.otpNewPhoneSameAsCurrentError;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancelButton, style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: authProvider.isLoading ? null : () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_changePhoneFormKey.currentState!.validate()) {
                            final result = await authProvider.changePhoneNumber(
                              newRawPhoneNumber: _newPhoneController.text,
                            );
                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            if (result['success']) {
                              _showThemedSuccessSnackBar(result['message'] ?? l10n.phoneUpdateSuccess);
                            } else {
                              _showThemedErrorSnackBar(result['message'] ?? l10n.phoneUpdateFailed);
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
                          ))
                      : Text(l10n.changeButton),
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

    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      _showThemedSuccessSnackBar(l10n.logoutSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context); // Listen to AuthProvider changes
    final currentUser = authProvider.currentUser;

    String displayName = l10n.guestUser;
    String displayPhone = "";

    if (currentUser != null) {
      final name = ('${currentUser.firstName} ${currentUser.lastName}').trim();
      displayName = name.isNotEmpty ? name : currentUser.phone;
      displayPhone = currentUser.phone;
    }

    Widget profilePictureWidget = CircleAvatar(
      radius: 60,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 70,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );

    if (currentUser == null) {
      return Scaffold(
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
                    (route) => false,
                  );
                },
                child: Text(l10n.signInLink),
              ),
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
                  Text(displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (displayPhone.isNotEmpty)
                    Text(
                      displayPhone,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              context: context,
              l10n: l10n,
              label: 'Name',
              value: displayName,
              onChange: _showChangeNameDialog,
            ),
            const SizedBox(height: 16),
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
            Card(
              child: SwitchListTile(
                title: Text(
                  l10n.notifications,
                  style: theme.textTheme.titleMedium,
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _showThemedSuccessSnackBar(value ? l10n.notificationsEnabledMessage : l10n.notificationsDisabledMessage);
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
    return Card(
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
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
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