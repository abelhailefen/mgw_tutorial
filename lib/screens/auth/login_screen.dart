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
  String _deviceInfoString = 'Fetching device info...'; // Will store the final formatted string
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
      // Check the state here after initialization finishes OR after a successful login
      print("LoginScreen: AuthProvider listener triggered.");
      // Only proceed if the provider is not initializing and there's a user
      if (!authProvider.isInitializing && authProvider.currentUser != null) {
         print("LoginScreen: AuthProvider user state changed. Checking status...");
         if (authProvider.currentUser!.status == "pending") {
            // User is logged in but status is pending. Show message.
             print("LoginScreen: User status is pending. Showing message.");
             // Avoid showing the snackbar multiple times if the listener fires rapidly
             if (mounted && !_hasNavigatedAfterLogin) { // Use _hasNavigatedAfterLogin flag
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         // Reverted to hardcoded string as per request
                         content: Text(
                           "Your account is pending approval by an administrator.", // Hardcoded fallback message
                           style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                         ),
                         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                         behavior: SnackBarBehavior.floating,
                         duration: const Duration(seconds: 5),
                       ),
                     );
                   // Set flag to prevent further actions until the state changes
                   _hasNavigatedAfterLogin = true;
               }
         } else if (!_hasNavigatedAfterLogin) { // If status is not pending AND we haven't navigated
            // Status is likely active, proceed with navigation
            _performNavigation(); // Call navigation method
         }
      } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: AuthProvider initialized and no user found. Staying on login.");
           // Ensure _hasNavigatedAfterLogin is false when there's no user,
           // so navigation can happen *after* a successful login.
          _hasNavigatedAfterLogin = false;
      }
      // If authProvider.isInitializing is true, we wait.
    };

    // Add the listener
    authProvider.addListener(_authListener!);

    // Check initial state after the frame is built, but after setting up listener
     WidgetsBinding.instance.addPostFrameCallback((_) {
       print("LoginScreen: Post-frame callback. Checking initial state.");

       // Re-check state using the provider instance *after* listener is added
       if (!authProvider.isInitializing && authProvider.currentUser != null) {
            print("LoginScreen: Initial state check found user. Checking status.");
            // Check status here too for saved sessions
            if (authProvider.currentUser!.status == "pending") {
               print("LoginScreen: Saved user status is pending. Deferring navigation, showing message.");
                if (mounted && !_hasNavigatedAfterLogin) { // Use the flag
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         // Reverted to hardcoded string as per request
                         content: Text(
                           "Your account is pending approval by an administrator.", // Hardcoded fallback message
                           style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                         ),
                         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                         behavior: SnackBarBehavior.floating,
                         duration: const Duration(seconds: 5),
                       ),
                     );
                     // Set flag to prevent further actions
                     _hasNavigatedAfterLogin = true;
                }
            } else if (!_hasNavigatedAfterLogin) { // If status is not pending AND we haven't navigated
              // Status is likely active, proceed with navigation
              _performNavigation();
            }
       } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: Initial state check found no user. Staying on login.");
           // Ensure _hasNavigatedAfterLogin is false here too
          _hasNavigatedAfterLogin = false;
       } else {
          print("LoginScreen: Initial state check: AuthProvider still initializing. Listener will handle state change.");
       }

       // Initialize device info once the context is available and valid
       _initializeDeviceInfo();
     });
  }

  // Navigation logic moved to a separate method
  void _performNavigation() {
     // Check user status one final time just before navigating
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
     // Only navigate if mounted, haven't navigated, user exists, AND status is not pending
     if (mounted && !_hasNavigatedAfterLogin && authProvider.currentUser != null && authProvider.currentUser!.status != "pending") {
          _hasNavigatedAfterLogin = true; // Set flag immediately before navigation
          print("LoginScreen: Navigating to MainScreen.");
          // Use pushReplacement to prevent going back to LoginScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
           _disposeAuthListener(); // Dispose the listener after successful navigation
     } else {
        print("LoginScreen: _performNavigation called but conditions not met (mounted: $mounted, navigated: $_hasNavigatedAfterLogin, user exists: ${authProvider.currentUser != null}, status != pending: ${authProvider.currentUser?.status != "pending"})");
         // If navigation failed because status was pending, ensure the flag is set and the message is shown
         if (mounted && authProvider.currentUser?.status == "pending" && !_hasNavigatedAfterLogin) {
              _hasNavigatedAfterLogin = true;
               ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                      // Reverted to hardcoded string as per request
                     content: Text(
                       "Your account is pending approval by an administrator.", // Hardcoded fallback message
                       style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                     ),
                     backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                     behavior: SnackBarBehavior.floating,
                     duration: const Duration(seconds: 5),
                   ),
                 );
         }
     }
  }

   void _disposeAuthListener() {
      // Safely get provider, handle potential error if context is disposed
      try {
         // Check if context is still valid before accessing provider
         if (!mounted) return;
         final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (_authListener != null) {
             authProvider.removeListener(_authListener!);
             _authListener = null;
             print("LoginScreen: AuthProvider listener disposed.");
          }
      } catch (e) {
         // Context might be gone if dispose happens during rapid screen changes
         print("LoginScreen: Error disposing AuthProvider listener: $e. Context probably not available.");
      }
   }


  Future<void> _initializeDeviceInfo() async {
    print("_initializeDeviceInfo called.");
    // Fetch raw data and type, then format the string
    final deviceData = await _deviceInfoService.getDeviceData();
    // Pass nullable context safely
    final deviceType = _deviceInfoService.detectDeviceType(mounted ? context : null);

    // >>> ASSEMBLE THE DEVICE INFO STRING USING THE SPECIFIC FORMAT <<<
    // '$brand $board $model $deviceId $deviceType' - This must match the format used in RegistrationScreen exactly.
     // Use null-aware operators and provide fallbacks for fields that may not exist on all platforms.
    String brand = deviceData['brand']?.toString() ?? deviceData['manufacturer']?.toString() ?? 'UnknownBrand';
    String board = deviceData['board']?.toString() ?? 'UnknownBoard'; // Primarily Android
    String model = deviceData['model']?.toString() ?? deviceData['localizedModel']?.toString() ?? deviceData['prettyName']?.toString() ?? 'UnknownModel'; // Use various sources
    String deviceId = deviceData['id']?.toString() ?? deviceData['deviceId']?.toString() ?? deviceData['utsname.machine:']?.toString() ?? deviceData['systemGUID']?.toString() ?? deviceData['machineId']?.toString() ?? 'UnknownId'; // Use various sources


    String finalDeviceInfo = '$brand $board $model $deviceId $deviceType'.trim();


    if (mounted) {
      setState(() {
        _deviceInfoString = finalDeviceInfo;
        _isDeviceInfoFetchedInitially = true;
      });
      print("LoginScreen Device Info Initialized: $_deviceInfoString");

       // Optional: Show a warning if device info couldn't be fully retrieved
       if (_deviceInfoString.contains("Unknown") || _deviceInfoString.contains("Failed to get details")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                // Reverted to hardcoded string as per request
                content: Text(
                  "Could not retrieve full device information. Login might not work.", // Hardcoded fallback
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
       }
    } else {
         print("_initializeDeviceInfo finished but LoginScreen was already disposed.");
    }
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
    authProvider.clearError(); // Clear previous errors

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Re-fetch device info if it's not ready or failed
    String currentDeviceInfo = _deviceInfoString;
     if (!_isDeviceInfoFetchedInitially || currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown") || currentDeviceInfo.contains("Failed to get details")) {
      print("Device info not ready/failed before login attempt, trying to refetch.");
       // Fetch raw data and type, then format the string
      final deviceData = await _deviceInfoService.getDeviceData();
      // Pass nullable context safely
      final deviceType = _deviceInfoService.detectDeviceType(mounted ? context : null);

      // >>> ASSEMBLE THE DEVICE INFO STRING USING THE SPECIFIC FORMAT <<<
      // '$brand $board $model $deviceId $deviceType' - This must match the format used in RegistrationScreen exactly.
       // Use null-aware operators and provide fallbacks for fields that may not exist on all platforms.
      String brand = deviceData['brand']?.toString() ?? deviceData['manufacturer']?.toString() ?? 'UnknownBrand';
      String board = deviceData['board']?.toString() ?? 'UnknownBoard'; // Primarily Android
      String model = deviceData['model']?.toString() ?? deviceData['localizedModel']?.toString() ?? deviceData['prettyName']?.toString() ?? 'UnknownModel'; // Use various sources
      String deviceId = deviceData['id']?.toString() ?? deviceData['deviceId']?.toString() ?? deviceData['utsname.machine:']?.toString() ?? deviceData['systemGUID']?.toString() ?? deviceData['machineId']?.toString() ?? 'UnknownId'; // Use various sources

      currentDeviceInfo = '$brand $board $model $deviceId $deviceType'.trim();


      if (mounted) {
        setState(() => _deviceInfoString = currentDeviceInfo); // Update state with potentially fixed info
        // If refetch still failed, show a warning but proceed with the failed string
        if (currentDeviceInfo.contains("Unknown") || currentDeviceInfo.contains("Failed to get details")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
               // Reverted to hardcoded string as per request
              content: Text(
                 "Device info could not be fully retrieved. Proceeding with limited info.", // Hardcoded fallback
                style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
              ),
              backgroundColor: theme.colorScheme.secondaryContainer,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
         print("_handleLogin refetch finished but LoginScreen was already disposed.");
        return; // Don't proceed if screen is disposed
      }
    }


    String rawPhoneInput = _phoneController.text.trim();
    String loginPhoneNumber;

    if (rawPhoneInput.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.phoneNumberValidationErrorRequired,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    // Use AuthProvider's normalization logic for consistency
    loginPhoneNumber = authProvider.normalizePhoneNumberToE164(rawPhoneInput);

    // Basic validation check *after* normalization
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(loginPhoneNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.phoneNumberValidationErrorInvalid, // Use invalid format error
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

    // Make the login API call
    bool success = await authProvider.login(
      phoneNumber: loginPhoneNumber,
      password: password,
      deviceInfo: currentDeviceInfo, // Use the assembled string
    );

    // >>> RE-ENABLED SNACKBAR DISPLAY LOGIC <<<
    if (mounted) {
       // Check authProvider.currentUser AFTER the login attempt finishes to see if it was successful
       // The login method sets _currentUser on success and clears it on failure
       // It also sets _apiError on API failure.
      if (authProvider.currentUser != null) {
        // This block will be hit if authProvider.login returned true AND _currentUser was set
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.loginSuccessMessage, // Assuming this key exists for success
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigation is now handled by the listener if status is not pending
      } else {
        // This block will be hit if authProvider.login returned false OR
        // if it returned true but _currentUser was not set properly (invalid user data).
        // Use the _apiError message set by the AuthProvider or a default fallback.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.apiError?.message ?? l10n.loginFailedNoUserData, // Default fallback
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    // The listener attached in initState/postFrameCallback will now react
    // to authProvider.isLoading becoming false and check authProvider.currentUser
    // and its status ('pending'). The snackbar above handles the failure message
    // specifically after the button press.
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
    // Show form if AuthProvider is not initializing AND user is null AND we haven't successfully navigated/handled login.
    // The _hasNavigatedAfterLogin flag prevents showing the form briefly after a successful login before navigation completes.
    bool showLoginForm = !authProvider.isInitializing && authProvider.currentUser == null && !_hasNavigatedAfterLogin;

    // canAttemptLogin determines if the login button should be enabled
    // Button enabled if device info is fetched (even if it contains "Unknown" or "Failed"), AuthProvider is not initializing, and not already loading from a previous attempt
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
                      // Disable language change while auth provider is busy
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

              // Show loading indicator if initializing or if user is logged in but navigation hasn't happened yet
              (authProvider.isInitializing || (authProvider.currentUser != null && !_hasNavigatedAfterLogin))
              ? Center(
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        // Reverted to hardcoded strings as per request
                        Text(authProvider.isInitializing ? "Initializing..." : "Checking Status...",
                             style: theme.textTheme.bodyMedium),
                     ],
                   ),
                )
              : showLoginForm // If not initializing AND user is null AND hasn't navigated, show the form
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
                                   // Button is enabled if device info is ready AND authProvider is not busy
                                   onPressed: canAttemptLogin ? _handleLogin : null,
                                   child: Text(l10n.signInButton),
                                 ),
                           // Show info message if login button is disabled because of device info not being ready
                           if (!canAttemptLogin && !authProvider.isLoading && !authProvider.isInitializing)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                 // Check the actual device info string state
                                // Reverted to hardcoded strings as per request
                                _deviceInfoString.contains("Failed to get details") || _deviceInfoString.contains("Unknown")
                                    ? "Device info failed. Try again."
                                    : "Initializing device info...",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                         ],
                       ),
                     ),
                   )
                 : const SizedBox.shrink(), // Hide the form entirely if showLoginForm is false

              // Only show the "Don't have an account" link if showing the login form
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