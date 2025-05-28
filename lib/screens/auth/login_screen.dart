// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
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

  final List<String> _supportedLanguageCodes = ['en', 'am', 'or', 'ti'];
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...';
  bool _isDeviceInfoFetchedInitially = false;

  bool _hasNavigatedAfterLogin = false;
  // Add a listener reference
  VoidCallback? _authListener;


  @override
  void initState() {
    super.initState();
    // Get the AuthProvider instance using listen: false
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Set up the listener *before* checking state initially
    _authListener = () {
      // This listener fires whenever AuthProvider calls notifyListeners()
      // Check the state here after initialization finishes
      print("LoginScreen: AuthProvider listener triggered.");
      if (!authProvider.isInitializing && authProvider.currentUser != null && !_hasNavigatedAfterLogin) {
          print("LoginScreen: AuthProvider initialized and user found. Navigating.");
          _performNavigation(); // Call navigation method
      } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: AuthProvider initialized and no user found. Staying on login.");
          // This case happens after DB lookup finishes and no user was found
          // or validation failed (in the old logic)
          // Ensure the UI updates if needed (the build method already listens)
      }
      // If authProvider.isInitializing is true, we wait.
    };

    // Add the listener
    authProvider.addListener(_authListener!);

    // Check initial state after the frame is built, but after setting up listener
     WidgetsBinding.instance.addPostFrameCallback((_) {
       print("LoginScreen: Post-frame callback. Checking initial state.");
       // This check is necessary for the case where the AuthProvider is *already*
       // initialized and has a user *before* the LoginScreen is ever built.
        if (!authProvider.isInitializing && authProvider.currentUser != null && !_hasNavigatedAfterLogin) {
            print("LoginScreen: Initial state check found user. Navigating.");
           _performNavigation();
       } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: Initial state check found no user. Staying on login.");
       } else {
          print("LoginScreen: Initial state check: AuthProvider still initializing. Listener will handle navigation.");
       }

       _initializeDeviceInfo();
     });
  }

  // Navigation logic moved to a separate method
  void _performNavigation() {
     if (mounted && !_hasNavigatedAfterLogin) { // Ensure widget is mounted and not already navigating
          _hasNavigatedAfterLogin = true;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
          // Optional: Remove the listener after navigating to prevent further calls
          // Provider.of<AuthProvider>(context, listen: false).removeListener(_authListener!);
           _disposeAuthListener(); // Custom dispose
     }
  }

   void _disposeAuthListener() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_authListener != null) {
         authProvider.removeListener(_authListener!);
         _authListener = null;
         print("LoginScreen: AuthProvider listener disposed.");
      }
   }


  Future<void> _initializeDeviceInfo() async {
    if (!mounted) {
       print("_initializeDeviceInfo called when not mounted.");
       return;
    }

    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
    String deviceType = "Unknown";

    if (mounted && ModalRoute.of(context) != null && ModalRoute.of(context)!.isActive) {
        try {
           deviceType = _deviceInfoService.detectDeviceType(context);
        } catch (e) {
            print("Error detecting device type in LoginScreen _getDeviceInfoInternal: $e. Using platform default.");
            deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                         ? "Mobile"
                         : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                           ? "Computer"
                           : "Web Browser";
        }
    } else {
        deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                         ? "Mobile"
                         : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                           ? "Computer"
                           : "Web Browser";
        print("Context not active for MediaQuery in _getDeviceInfoInternal, using platform default for deviceType: $deviceType");
    }

    String finalDeviceInfo = '$deviceType - $brand $model, $os';
    if (mounted) {
      setState(() {
        _deviceInfoString = finalDeviceInfo;
        _isDeviceInfoFetchedInitially = true;
      });
      print("Device Info for Login Updated: $_deviceInfoString");
    }
  }

   Future<String> _getDeviceInfoForLoginAttempt() async {
      if (_isDeviceInfoFetchedInitially && _deviceInfoString != 'Fetching device info...') {
         return _deviceInfoString;
      }

     if (!mounted) return "Mobile - Default, UnknownOS";

      final deviceData = await _deviceInfoService.getDeviceData();
      String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
      String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
      String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
      String deviceType = "Unknown";

      if (mounted && ModalRoute.of(context) != null && ModalRoute.of(context)!.isActive) {
          try {
             deviceType = _deviceInfoService.detectDeviceType(context);
          } catch (e) {
              print("Error detecting device type in LoginScreen _getDeviceInfoInternal: $e. Using platform default.");
              deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                           ? "Mobile"
                           : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                             ? "Computer"
                             : "Web Browser";
          }
      } else {
          deviceType = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                           ? "Mobile"
                           : (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux)
                             ? "Computer"
                             : "Web Browser";
          print("Context not active for MediaQuery in _getDeviceInfoInternal, using platform default for deviceType: $deviceType");
      }

      String finalDeviceInfo = '$deviceType - $brand $model, $os';

       if (mounted && !_isDeviceInfoFetchedInitially) {
            setState(() {
               _deviceInfoString = finalDeviceInfo;
               _isDeviceInfoFetchedInitially = true;
            });
             print("Device Info fetched (fallback) and state updated: $_deviceInfoString");
       } else if (!mounted) {
           print("_getDeviceInfoForLoginAttempt fetched info but not mounted, cannot update state.");
       }

      return finalDeviceInfo;
   }


  @override
  void dispose() {
    _disposeAuthListener(); // Dispose the listener
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

    if (!_formKey.currentState!.validate()) {
        return;
    }

    String currentDeviceInfo = await _getDeviceInfoForLoginAttempt();

    if (currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown")) {
        print("Device info still not ideal after re-fetch/check, proceeding with current value: $currentDeviceInfo");
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                       l10n.deviceInfoProceedingDefault,
                       style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    behavior: SnackBarBehavior.floating,
                ),
            );
        }
         if (currentDeviceInfo == 'Fetching device info...') {
             currentDeviceInfo = "Mobile - Generic, UnknownOS";
         }
    }

    String rawPhoneInput = _phoneController.text.trim();
    String loginPhoneNumber;

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
        return;
    }
    loginPhoneNumber = authProvider.normalizePhoneNumberToE164(rawPhoneInput);

    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(loginPhoneNumber)) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
               content: Text(
                   l10n.phoneNumberValidationErrorInvalid,
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

    bool success = await authProvider.login(
      phoneNumber: loginPhoneNumber,
      password: password,
      deviceInfo: currentDeviceInfo,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.loginSuccessMessage,
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
         // Navigation will be handled by the listener now after notifyListeners() from login success
         // _hasNavigatedAfterLogin is set in _performNavigation()
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.apiError?.message ?? l10n.signInFailedErrorGeneral,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getLanguageDisplayName(String langCode, AppLocalizations l10n) {
    switch (langCode) {
      case 'en': return l10n.english;
      case 'am': return l10n.amharic;
      case 'or': return l10n.afaanOromo;
      case 'ti': return l10n.tigrigna;
      default: return langCode.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen to AuthProvider to react to isInitializing or currentUser changes
    // This ensures the UI rebuilds when state changes, including isInitializing becoming false
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.isNotEmpty ? _supportedLanguageCodes.first : 'en';
    }

    // showLoginForm determines if the login form part should be built
    bool showLoginForm = !authProvider.isInitializing && authProvider.currentUser == null;
    // canAttemptLogin determines if the login button should be enabled
    bool canAttemptLogin = _isDeviceInfoFetchedInitially && !authProvider.isInitializing && !authProvider.isLoading;


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
                      onChanged: authProvider.isLoading || authProvider.isInitializing ? null : (String? newLanguageCode) {
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
                title: l10n.appTitle,
                subtitle: l10n.loginToContinue,
              ),
              const SizedBox(height: 40),

              // Show loading indicator if initializing, or if login is in progress
              // Otherwise, show the login form if not logged in, or a placeholder if logged in but not navigated yet
              authProvider.isInitializing || (authProvider.isLoading && !showLoginForm)
              ? Center(
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        // Message indicates what's happening
                        Text(authProvider.isInitializing ? l10n.initializing : l10n.signInButton, // Can use 'Signing In...' or similar if available
                             style: theme.textTheme.bodyMedium),
                     ],
                   ),
                )
              : showLoginForm // If not initializing/loading AND user is null, show the form
                 ? AuthCardWrapper(
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
                           authProvider.isLoading // Loading state specifically for the login button press
                               ? const Center(child: CircularProgressIndicator())
                               : ElevatedButton(
                                   onPressed: canAttemptLogin ? _handleLogin : null,
                                   child: Text(l10n.signInButton),
                                 ),
                           // Show info message if login button is disabled because of device info
                           if (!canAttemptLogin && !authProvider.isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                l10n.initializing, // Maybe change this l10n key to be more descriptive if needed
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                         ],
                       ),
                     ),
                   )
                 : Center(
                     // This case means !isInitializing && currentUser != null
                     // but _hasNavigatedAfterLogin is false. We are logged in
                     // but haven't navigated yet. Show a spinner while waiting
                     // for the next frame callback or listener to trigger navigation.
                     child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(l10n.initializing, style: theme.textTheme.bodyMedium), // Or "Redirecting..."
                         ],
                       ),
                   ),

              if (showLoginForm)
                 const SizedBox(height: 24),
              if (showLoginForm)
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