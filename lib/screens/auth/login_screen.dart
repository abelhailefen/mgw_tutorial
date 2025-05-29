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
import 'package:mgw_tutorial/services/device_info.dart'; // <<< KEEP THIS


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
      // Check the state here after initialization finishes OR after a successful login
      print("LoginScreen: AuthProvider listener triggered.");
      if (!authProvider.isInitializing && authProvider.currentUser != null && !_hasNavigatedAfterLogin) {
          print("LoginScreen: AuthProvider initialized and user found/logged in. Checking status.");
          // Check user status before navigating
          // This check is crucial for the "pending approval" message
          if (authProvider.currentUser!.status == "pending") {
              // User is logged in but status is pending. Show message and *do not navigate to MainScreen yet*.
              // For now, let's show a snackbar. Ideally, this would navigate to a dedicated screen.
              if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         // FIX: Use an existing or generic localized string
                         content: Text(
                           
                           AppLocalizations.of(context)!.registrationFailedDefaultMessage, // Using a fallback key
                           // Or a hardcoded string: "Account pending admin approval."
                           style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                         ),
                         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                         behavior: SnackBarBehavior.floating,
                         duration: Duration(seconds: 5), // Keep it visible longer
                       ),
                     );
               }
              print("LoginScreen: User status is pending. Navigation deferred.");
              
              _hasNavigatedAfterLogin = true; // Prevent infinite loop from listener
          } else {
             // Status is not pending (likely active), proceed with navigation
             _performNavigation(); // Call navigation method
          }
      } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: AuthProvider initialized and no user found. Staying on login.");
          
      }
      // If authProvider.isInitializing is true, we wait.
    };

    // Add the listener
    authProvider.addListener(_authListener!);

    // Check initial state after the frame is built, but after setting up listener
     WidgetsBinding.instance.addPostFrameCallback((_) {
       print("LoginScreen: Post-frame callback. Checking initial state.");
       
        if (!authProvider.isInitializing && authProvider.currentUser != null && !_hasNavigatedAfterLogin) {
            print("LoginScreen: Initial state check found user. Checking status.");
            // Check status here too for saved sessions
            if (authProvider.currentUser!.status == "pending") {
               print("LoginScreen: Saved user status is pending. Deferring navigation, showing message.");
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         // FIX: Use an existing or generic localized string
                         content: Text(
                            // Replace with an existing localized string that makes sense,
                            // or hardcode if no suitable one exists.
                           AppLocalizations.of(context)!.registrationFailedDefaultMessage, // Using a fallback key
                            // Or a hardcoded string: "Account pending admin approval."
                           style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                         ),
                         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                         behavior: SnackBarBehavior.floating,
                         duration: Duration(seconds: 5),
                       ),
                     );
                }
                _hasNavigatedAfterLogin = true; // Prevent subsequent navigation attempts
            } else {
              // Status is not pending (likely active), proceed with navigation
              _performNavigation();
            }
       } else if (!authProvider.isInitializing && authProvider.currentUser == null) {
          print("LoginScreen: Initial state check found no user. Staying on login.");
       } else {
          print("LoginScreen: Initial state check: AuthProvider still initializing. Listener will handle navigation.");
       }

       // Initialize device info once the context is available and valid
       _initializeDeviceInfo();
     });
  }

  // Navigation logic moved to a separate method
  void _performNavigation() {
     // Check user status one final time just before navigating
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
     if (mounted && !_hasNavigatedAfterLogin && authProvider.currentUser != null && authProvider.currentUser!.status != "pending") {
          _hasNavigatedAfterLogin = true;
          print("LoginScreen: Navigating to MainScreen.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
           _disposeAuthListener(); // Dispose the listener after successful navigation
     } else if (mounted && !_hasNavigatedAfterLogin && authProvider.currentUser != null && authProvider.currentUser!.status == "pending") {
          print("LoginScreen: Attempted to navigate, but user status is pending. Navigation deferred.");
          // This case might happen if the listener or post-frame callback trigger
          // _performNavigation before the status check logic in the listener itself.
          // Ensure _hasNavigatedAfterLogin is set to true here to prevent looping.
           _hasNavigatedAfterLogin = true;
            if (mounted) { // Show message if not already shown
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     // FIX: Use an existing or generic localized string
                     content: Text(
                        // Replace with an existing localized string that makes sense,
                        // or hardcode if no suitable one exists.
                       AppLocalizations.of(context)!.registrationFailedDefaultMessage, // Using a fallback key
                        // Or a hardcoded string: "Account pending admin approval."
                       style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                     ),
                     backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                     behavior: SnackBarBehavior.floating,
                     duration: Duration(seconds: 5),
                   ),
                 );
            }
     } else {
        print("LoginScreen: _performNavigation called but conditions not met (mounted: $mounted, navigated: $_hasNavigatedAfterLogin, user: ${authProvider.currentUser != null})");
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

    // Use the new service method to get the formatted string
    final formattedInfo = await _deviceInfoService.getFormattedDeviceString(context);

    if (mounted) {
      setState(() {
        _deviceInfoString = formattedInfo;
        _isDeviceInfoFetchedInitially = true;
      });
      print("LoginScreen Device Info Updated: $_deviceInfoString");
    }
  }

   // This method is no longer needed as initialization handles fetching
   // Future<String> _getDeviceInfoForLoginAttempt() async { /* ... simplified/removed ... */ }


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

    // Use the _deviceInfoString state variable directly now
    String currentDeviceInfo = _deviceInfoString;

    // Add a check similar to registration screen's submit logic
    if (currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Failed to get details")) {
        print("Device info not ready or has error before login attempt, trying to refetch.");
         // Re-fetch using the service method if it's still the initial placeholder or an error string
        final refetchedInfo = await _deviceInfoService.getFormattedDeviceString(context);
        if (mounted) {
           setState(() => _deviceInfoString = refetchedInfo);
            currentDeviceInfo = _deviceInfoString; // Use the refetched value
           // Check again after refetch
           if (_deviceInfoString == 'Fetching device info...' || _deviceInfoString.contains("Failed to get details")) {
               print("Device info still not ready or has error after refetch attempt before login.");
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                               // FIX: Use an existing or generic localized string
                               l10n.deviceInfoProceedingDefault, // Using a fallback key
                               style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                            ),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            behavior: SnackBarBehavior.floating,
                        ),
                    );
                }
                 // Optionally prevent login here if device info is critical, or proceed with error string
                 // For now, we proceed with the error string in currentDeviceInfo
           }
        } else {
            // If not mounted after refetch, cannot proceed safely
            return;
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
      deviceInfo: currentDeviceInfo, // Pass the formatted string from state
    );

    if (mounted) {
      if (success) {
        // Login was successful based on credentials and possibly device check.
        // Navigation or pending status message will now be handled by the listener (_authListener).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.loginSuccessMessage, // This confirms credentials worked
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
         // Do NOT navigate here directly. The listener watches authProvider state.
      } else {
        // Login failed (wrong credentials or device mismatch from backend)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // This is where "You are not registered with this device" comes from
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
    // Show form if AuthProvider is not initializing AND user is null AND we haven't navigated away yet.
    bool showLoginForm = !authProvider.isInitializing && authProvider.currentUser == null && !_hasNavigatedAfterLogin;
    // canAttemptLogin determines if the login button should be enabled
    // Button enabled if device info is fetched, AuthProvider is not initializing, and not already loading from a previous attempt
    bool canAttemptLogin = _isDeviceInfoFetchedInitially && _deviceInfoString != 'Fetching device info...' && !authProvider.isInitializing && !authProvider.isLoading;


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

              // Show loading indicator if initializing
              authProvider.isInitializing
              ? Center(
                  child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(l10n.initializing,
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
                                   onPressed: canAttemptLogin ? _handleLogin : null,
                                   child: Text(l10n.signInButton),
                                 ),
                           // Show info message if login button is disabled because of device info
                           if (!canAttemptLogin && !authProvider.isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                 // Check if initial fetch failed
                                _deviceInfoString.contains("Failed to get details") ? "Device info failed. Try again." : "Initializing device info...",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                         ],
                       ),
                     ),
                   )
                 : Center(
                     // This case means !isInitializing && currentUser != null AND _hasNavigatedAfterLogin is false
                     // We are logged in but haven't navigated or are pending approval.
                     // Show a spinner while waiting for the next frame callback or listener to trigger navigation/message.
                     child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(l10n.initializing, style: theme.textTheme.bodyMedium), // Or "Redirecting..." / "Checking Status..."
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