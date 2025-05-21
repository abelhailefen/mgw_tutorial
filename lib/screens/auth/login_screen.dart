// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/screens/registration/registration_screen.dart';
// Widgets
import 'package:mgw_tutorial/widgets/auth/auth_screen_header.dart';
import 'package:mgw_tutorial/widgets/auth/auth_card_wrapper.dart';
import 'package:mgw_tutorial/widgets/auth/auth_form_title.dart';
import 'package:mgw_tutorial/widgets/auth/auth_navigation_link.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';
// Import DeviceInfoService
import 'package:mgw_tutorial/services/device_info.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _supportedLanguageCodes = ['en', 'am', 'or'];
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...';

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  Future<void> _getDeviceInfo() async {
    if (!mounted) return;

    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
    String deviceType = _deviceInfoService.detectDeviceType(context);


    if (mounted) {
      setState(() {
        _deviceInfoString = '$deviceType - $brand $model, $os';
        print("Device Info for Login: $_deviceInfoString");
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    authProvider.clearError();

    if (_formKey.currentState!.validate()) {
      String rawPhoneInput = _phoneController.text.trim();
      String loginPhoneNumber;

      if (rawPhoneInput.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.phoneNumberValidationErrorRequired),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Phone number normalization logic (remains the same)
      if (rawPhoneInput.startsWith('+251') && rawPhoneInput.length == 13) {
        loginPhoneNumber = rawPhoneInput;
      } else if (rawPhoneInput.length == 9 && !rawPhoneInput.startsWith('0')) {
        loginPhoneNumber = '+251$rawPhoneInput';
      } else if (rawPhoneInput.startsWith('0') && rawPhoneInput.length == 10) {
        loginPhoneNumber = '+251${rawPhoneInput.substring(1)}';
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.phoneNumberValidationErrorInvalid),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }


      final String password = _passwordController.text;

      if (_deviceInfoString == 'Fetching device info...' || _deviceInfoString.isEmpty) {
        await _getDeviceInfo();
        if (_deviceInfoString == 'Fetching device info...' || _deviceInfoString.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                   // TODO: Localize this specific message if needed
                   content: const Text("Device information not available. Please wait and try again."),
                   backgroundColor: theme.colorScheme.errorContainer,
                   behavior: SnackBarBehavior.floating,
               ),
            );
          }
          return;
        }
      }

      print("Attempting login with Phone: $loginPhoneNumber, Password: [HIDDEN], Device: $_deviceInfoString");

      bool success = await authProvider.login(
        phoneNumber: loginPhoneNumber,
        password: password,
        deviceInfo: _deviceInfoString,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.loginSuccessMessage),
                backgroundColor: theme.colorScheme.primaryContainer, // Use a success-indicating color
                behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // Display the user-friendly message from AuthProvider
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.apiError?.message ?? l10n.signInFailedErrorGeneral),
              backgroundColor: theme.colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  String _getLanguageDisplayName(String langCode, AppLocalizations l10n) {
    switch (langCode) {
      case 'en':
        return l10n.english;
      case 'am':
        return l10n.amharic;
      case 'or':
        return l10n.afaanOromo;
      default:
        return langCode.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.isNotEmpty ? _supportedLanguageCodes.first : 'en';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLanguageCode,
                      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                      elevation: 2,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                      dropdownColor: theme.cardTheme.color,
                      onChanged: (String? newLanguageCode) {
                        if (newLanguageCode != null) {
                          localeProvider.setLocale(Locale(newLanguageCode));
                        }
                      },
                      items: _supportedLanguageCodes
                          .map<DropdownMenuItem<String>>((String langCode) {
                        return DropdownMenuItem<String>(
                          value: langCode,
                          child: Text(_getLanguageDisplayName(langCode, l10n)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthScreenHeader(
                title: l10n.mgwTutorialTitle,
                subtitle: l10n.loginToContinue,
              ),
              const SizedBox(height: 40),
              AuthCardWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AuthFormTitle(title: l10n.loginTitle),
                      const SizedBox(height: 24),
                      PhoneFormField(
                        controller: _phoneController,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                      PasswordFormField(
                        controller: _passwordController,
                        isPasswordVisible: _isPasswordVisible,
                        onToggleVisibility: _togglePasswordVisibility,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 30),
                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              child: Text(l10n.signInButton),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthNavigationLink(
                leadingText: l10n.dontHaveAccount,
                linkText: l10n.signUpLinkText,
                onLinkPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}