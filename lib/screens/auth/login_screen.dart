// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show defaultTargetPlatform; // OLD IMPORT
import 'package:flutter/foundation.dart'; // CORRECTED IMPORT to include kDebugMode and defaultTargetPlatform
import 'package:mgw_tutorial/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';import 'package:mgw_tutorial/screens/registration/registration_screen.dart';
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

  // UPDATED: Add 'ti' for Tigrigna
  final List<String> _supportedLanguageCodes = ['en', 'am', 'or', 'ti'];
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...';
  bool _isDeviceInfoFetchedInitially = false;

  @override
  void initState() {
    super.initState();
    // Using addPostFrameCallback to ensure context is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeviceInfo();
    });
  }

  // Separate method for async device info initialization
  Future<void> _initializeDeviceInfo() async {
    // Check if the widget is still mounted before calling setState
    if (!mounted) return;
    await _getDeviceInfoInternal();
    if (mounted) {
      setState(() {
        _isDeviceInfoFetchedInitially = true;
      });
    }
  }

  // Internal helper to fetch device info safely
  Future<String> _getDeviceInfoInternal() async {
    // Provide a default if context is not available or mounted
    if (!mounted) return "Mobile - Default, UnknownOS";

    String deviceType = "Unknown";

    // Try to get device type using MediaQuery only if context is active and mounted
    if (mounted && ModalRoute.of(context) != null && ModalRoute.of(context)!.isActive) {
        try {
           deviceType = _deviceInfoService.detectDeviceType(context);
        } catch (e) {
            print("Error detecting device type in LoginScreen _getDeviceInfoInternal: $e. Using platform default.");
             // Fallback to platform-based guess if MediaQuery fails
             deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                         ? "Mobile"
                         : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                           ? "Computer"
                           : "Web Browser";
        }
    } else {
        // Fallback if context isn't fully active (e.g., during initial build phase)
        deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                         ? "Mobile"
                         : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                           ? "Computer"
                           : "Web Browser";
        print("Context not active for MediaQuery in _getDeviceInfoInternal, using platform default for deviceType: $deviceType");
    }

    // Get other device data (brand, model, os) which doesn't require MediaQuery
    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';


    String finalDeviceInfo = '$deviceType - $brand $model, $os';
    if (mounted) {
      _deviceInfoString = finalDeviceInfo;
      print("Device Info for Login Updated: $_deviceInfoString");
    }
    return finalDeviceInfo;
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
    // Check if the widget is still mounted before proceeding
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    // Use listen: false for calling methods on the provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    // Clear previous errors from the provider
    authProvider.clearError();

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
        // If validation fails, don't proceed with login
        return;
    }

    // Ensure device info is fetched before attempting login
    String currentDeviceInfo = _deviceInfoString;
    // If device info hasn't been fetched initially or is still a placeholder, try fetching it now
    if (!_isDeviceInfoFetchedInitially || currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown")) {
        print("Device info not ready or unknown, attempting one more fetch before login.");
        // Fetch device info, await the result
        currentDeviceInfo = await _getDeviceInfoInternal();

        // Check mounted after async call
        if (!mounted) return;

        // Update state with fetched info if mounted
        setState(() {
            _deviceInfoString = currentDeviceInfo;
            // Set this to true here as we've made a conscious effort to fetch it
            _isDeviceInfoFetchedInitially = true;
        });

        // If info is still not ideal after re-fetch, show a warning but proceed with the best available info
        if (currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown")) {
            print("Device info still not ideal after re-fetch, proceeding with current value: $currentDeviceInfo");
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                           l10n.deviceInfoProceedingDefault, // Use localization
                           style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                        ),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        behavior: SnackBarBehavior.floating,
                    ),
                );
            }
            // Use a generic default if it's still 'Fetching...'
            if (currentDeviceInfo == 'Fetching device info...') {
                currentDeviceInfo = "Mobile - Generic, UnknownOS";
                 if(mounted) setState(() => _deviceInfoString = currentDeviceInfo); // Update state if proceeding with default
            }
        }
    }

    // Process phone number input
    String rawPhoneInput = _phoneController.text.trim();
    String loginPhoneNumber;

    // Basic phone number formatting validation
    if (rawPhoneInput.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.phoneNumberValidationErrorRequired, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return; // Stop if phone is empty
    }
    // Normalize phone number - use the logic consistently
    // The AuthProvider also normalizes, but doing it here helps ensure UI validation aligns
    // Consider using a validator in PhoneFormField that returns the normalized number or null/error
     try {
        loginPhoneNumber = authProvider.normalizePhoneNumberToE164(rawPhoneInput);
         // Add a check to ensure the normalized number looks valid if required
         // This is a basic check, you might need more robust validation
         if (loginPhoneNumber.isEmpty || !(loginPhoneNumber.startsWith('+') && loginPhoneNumber.length > 10)) {
              // If normalization didn't result in a typical E.164 or failed significantly
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                         content: Text(
                             l10n.phoneNumberValidationErrorInvalid, // Re-use invalid message
                             style: TextStyle(color: theme.colorScheme.onErrorContainer),
                         ),
                         backgroundColor: theme.colorScheme.errorContainer,
                         behavior: SnackBarBehavior.floating,
                     ),
                   );
                 }
                 return;
         }
     } catch (e) {
        print("Phone number normalization failed: $e");
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text(
                     l10n.phoneNumberValidationErrorInvalid, // Re-use invalid message
                     style: TextStyle(color: theme.colorScheme.onErrorContainer),
                 ),
                 backgroundColor: theme.colorScheme.errorContainer,
                 behavior: SnackBarBehavior.floating,
             ),
           );
         }
        return;
     }


    final String password = _passwordController.text;

    print("Attempting login with Phone: $loginPhoneNumber, Password: [HIDDEN], Device: $currentDeviceInfo");

    // Call the login method on the provider
    // The provider will set its isLoading state and notify listeners
    bool success = await authProvider.login(
      phoneNumber: loginPhoneNumber,
      password: password,
      deviceInfo: currentDeviceInfo,
    );

    // Check mounted again after the awaited async operation
    if (!mounted) return;

    // Provider's state (isLoading, apiError) is updated and listeners notified *within* the provider's login method now.
    // We just need to react to the success/failure result.
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.loginSuccessMessage, // Use localization
            style: TextStyle(color: theme.colorScheme.onPrimary),
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate on success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // On failure, the provider's apiError should be set.
      // Show the error message from the provider.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.apiError?.message ?? l10n.signInFailedErrorGeneral, // Use provider error or a general fallback
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Helper for displaying language names using l10n
  String _getLanguageDisplayName(String langCode, AppLocalizations l10n) {
    switch (langCode) {
      case 'en': return l10n.english;
      case 'am': return l10n.amharic;
      case 'or': return l10n.afaanOromo;
      case 'ti': return l10n.tigrigna; // UPDATED: Add case for Tigrigna
      default: return langCode.toUpperCase(); // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use Provider.of with listen: true here to react to changes in AuthProvider's state (like isLoading or apiError)
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    // Ensure the current language code is one of the supported ones for the dropdown
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.isNotEmpty ? _supportedLanguageCodes.first : 'en';
    }

    // Disable the login button if device info hasn't been fetched yet
    bool canAttemptLogin = _isDeviceInfoFetchedInitially;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Language Dropdown
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color, // Use theme color
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.colorScheme.outline), // Use theme color
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLanguageCode,
                      icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary), // Use theme color
                      elevation: 2,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14), // Use theme text color
                      dropdownColor: theme.cardTheme.color, // Use theme color
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
              // Header
              AuthScreenHeader(
                title: l10n.mgwTutorialTitle,
                subtitle: l10n.loginToContinue,
              ),
              const SizedBox(height: 40),
              // Login Form Card
              AuthCardWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AuthFormTitle(title: l10n.loginTitle),
                      const SizedBox(height: 24),
                      // Phone Number Field
                      PhoneFormField(
                        controller: _phoneController,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      PasswordFormField(
                        controller: _passwordController,
                        isPasswordVisible: _isPasswordVisible,
                        onToggleVisibility: _togglePasswordVisibility,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 30),
                      // Login Button / Loading Indicator
                      // This checks the isLoading state from the provider
                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              // Disable button if device info is not ready or provider is loading (redundant check due to ternary)
                              // The ternary handles the loading state, so just check canAttemptLogin here
                              onPressed: canAttemptLogin ? _handleLogin : null,
                              child: Text(l10n.signInButton),
                            ),
                       // Message if device info is not ready
                       if (!canAttemptLogin && !authProvider.isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            l10n.initializing, // Use localization
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                          ),
                        ),
                        // Display API error message if present
                       if (authProvider.apiError != null && !authProvider.isLoading)
                         Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                                authProvider.apiError!.message,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.error), // Use error color
                            ),
                         ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Navigation Link to Registration
              AuthNavigationLink(
                leadingText: l10n.dontHaveAccount,
                linkText: l10n.signUpLinkText,
                onLinkPressed: () {
                  // Navigate to Registration screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
               // Display device info string for debugging (optional)
               // kDebugMode is now available due to the updated import
               if (kDebugMode)
                 Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'Device Info: $_deviceInfoString',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      textAlign: TextAlign.center,
                    ),
                 ),
            ],
          ),
        ),
      ),
    );
  }
}