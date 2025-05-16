// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:mgw_tutorial/screens/auth/signup_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/screens/registration/registration_screen.dart'; // Adjust the import based on your file structure
// Widgets
import 'package:mgw_tutorial/widgets/auth/auth_screen_header.dart';
import 'package:mgw_tutorial/widgets/auth/auth_card_wrapper.dart';
import 'package:mgw_tutorial/widgets/auth/auth_form_title.dart';
import 'package:mgw_tutorial/widgets/auth/auth_navigation_link.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';

// Import DeviceInfoService
import 'package:mgw_tutorial/services/device_info.dart'; // Ensure this path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _supportedLanguageCodes = ['en', 'am', 'om']; // 'om' for Afaan Oromo
  bool _isPasswordVisible = false;

  // Instantiate DeviceInfoService and state variable for device info string
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...'; // Initial placeholder

  @override
  void initState() {
    super.initState();
    _getDeviceInfo(); // Fetch device info when the screen initializes
  }

  Future<void> _getDeviceInfo() async {
    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
    
    // Assuming _deviceInfoService.detectDeviceType needs context,
    // ensure it's called where context is available or pass it if needed.
    // If `detectDeviceType` is static and context-independent:
    // String deviceType = DeviceInfoService.detectDeviceTypeStatic(); 
    // Or, if it needs context:
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
    authProvider.clearError(); // Clear previous errors

    if (_formKey.currentState!.validate()) {
      String rawPhoneInput = _phoneController.text.trim();
      String loginPhoneNumber;

      if (rawPhoneInput.isEmpty) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.phoneNumberValidationErrorRequired)),
          );
        }
        return;
      }

      // Normalize phone number (adjust if your API expects a different format for login)
      if (rawPhoneInput.startsWith('+251') && rawPhoneInput.length == 13) {
        loginPhoneNumber = '+251${rawPhoneInput.substring(4)}'; // Convert +2519... to 09...
      } else if (rawPhoneInput.length == 9 && !rawPhoneInput.startsWith('0')) {
        loginPhoneNumber = '0$rawPhoneInput'; // Convert 9... to 09...
      } else if (rawPhoneInput.startsWith('0') && rawPhoneInput.length == 10) {
        loginPhoneNumber = rawPhoneInput; // Already 09...
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.phoneNumberValidationErrorInvalid)),
          );
        }
        return;
      }

      final String password = _passwordController.text;

      // Ensure device info has been fetched
      if (_deviceInfoString == 'Fetching device info...' || _deviceInfoString.isEmpty) {
        await _getDeviceInfo(); // Try to fetch it again if not ready
        if (_deviceInfoString == 'Fetching device info...' || _deviceInfoString.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Device information not available. Please wait and try again.")),
            );
          }
          return;
        }
      }

      print("Attempting login with Phone: $loginPhoneNumber, Password: [HIDDEN], Device: $_deviceInfoString");

      bool success = await authProvider.login(
        phoneNumber: loginPhoneNumber,
        password: password,
        deviceInfo: _deviceInfoString, // Pass the fetched device info
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.loginSuccessMessage)),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.apiError?.message ?? l10n.signInFailedErrorGeneral),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    final Map<String, String> languageDisplayNames = {
      'en': l10n.english,
      'am': l10n.amharic,
      'om': l10n.afaanOromo,
    };
    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.first;
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
                    color: Theme.of(context).canvasColor, // Use theme color
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[400] ?? Colors.grey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLanguageCode,
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
                      elevation: 2,
                      style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14),
                      onChanged: (String? newLanguageCode) {
                        if (newLanguageCode != null) {
                          localeProvider.setLocale(Locale(newLanguageCode));
                        }
                      },
                      items: _supportedLanguageCodes
                          .map<DropdownMenuItem<String>>((String langCode) {
                        return DropdownMenuItem<String>(
                          value: langCode,
                          child: Text(languageDisplayNames[langCode] ?? langCode.toUpperCase()),
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
                              style: ElevatedButton.styleFrom( // Consistent with theme or custom
                                // backgroundColor: Colors.blue[700], // Example
                                // foregroundColor: Colors.white, // Example
                                padding: const EdgeInsets.symmetric(vertical: 12), // from your main.dart theme
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold) // from your main.dart theme
                              ),
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
                   // TEMPORARY: Revert this to SignUpScreen when done testing account creation
                  // print("Sign Up link pressed, navigating to MainScreen (TEMPORARY for testing).");
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => const MainScreen()),
                  // );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()), // Original
                  );
                },
              ),
              const SizedBox(height: 20), // Extra padding at the bottom
            ],
          ),
        ),
      ),
    );
  }
}