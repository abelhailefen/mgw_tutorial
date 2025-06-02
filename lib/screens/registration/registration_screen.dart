// lib/screens/registration/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
// ... other imports
import 'package:mgw_tutorial/provider/auth_provider.dart';
// import 'package:mgw_tutorial/provider/department_provider.dart'; // REMOVED
import 'package:mgw_tutorial/services/device_info.dart';
import 'package:mgw_tutorial/models/user.dart';
// import 'package:mgw_tutorial/models/department.dart'; // REMOVED
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Department? _selectedDepartment; // REMOVED
  String? _selectedCategory;
  String? _selectedInstitution;
  String? _selectedGender;
  String? _selectedYear;

  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...'; // Will store the final formatted string
  bool _isDeviceInfoFetchedInitially = false;

  bool _hasAttemptedSubmit = false;

  final List<String> _categories = ['Natural', 'Social'];

  final List<String> _institutions = [
    'Addis Ababa University', 'Bahir Dar University', 'Hawassa University', 'Other',
  ];
  final List<String> _academicYears = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', '6th Year', '7th Year'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeviceInfo();
      // Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments(); // REMOVED
    });
  }

  Future<void> _initializeDeviceInfo() async {
    if (!mounted) return;
    // Fetch raw data and type, then format the string
    final deviceData = await _deviceInfoService.getDeviceData();
    // Pass nullable context safely
    final deviceType = _deviceInfoService.detectDeviceType(mounted ? context : null);

    // >>> ASSEMBLE THE DEVICE INFO STRING USING THE SPECIFIC FORMAT <<<
    // '$brand $board $model $deviceId $deviceType' - This must match the format used in LoginScreen exactly.
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
      print("RegistrationScreen Device Info Initialized: $_deviceInfoString");

      // Optional: Show a warning if device info couldn't be fully retrieved
       if (_deviceInfoString.contains("Unknown") || _deviceInfoString.contains("Failed to get details")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                   "Could not retrieve full device information. This might affect login on other devices.", // Hardcoded fallback
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
       }
    }
  }


  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() { _isPasswordVisible = !_isPasswordVisible; });
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (!mounted) return;

    authProvider.clearError();
    setState(() { _hasAttemptedSubmit = true; });
    if (!_formKey.currentState!.validate()) return;

     // Re-fetch device info if it's not ready or failed
     String currentDeviceInfo = _deviceInfoString;
     if (!_isDeviceInfoFetchedInitially || currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown") || currentDeviceInfo.contains("Failed to get details")) {
        print("Device info not ready/failed before registration submit, trying to refetch.");
         // Fetch raw data and type, then format the string
        final deviceData = await _deviceInfoService.getDeviceData();
        // Pass nullable context safely
        final deviceType = _deviceInfoService.detectDeviceType(mounted ? context : null);

        // >>> ASSEMBLE THE DEVICE INFO STRING USING THE SPECIFIC FORMAT <<<
        // '$brand $board $model $deviceId $deviceType' - This must match the format used in LoginScreen exactly.
        // Use null-aware operators and provide fallbacks for fields that may not exist on all platforms.
        String brand = deviceData['brand']?.toString() ?? deviceData['manufacturer']?.toString() ?? 'UnknownBrand';
        String board = deviceData['board']?.toString() ?? 'UnknownBoard'; // Primarily Android
        String model = deviceData['model']?.toString() ?? deviceData['localizedModel']?.toString() ?? deviceData['prettyName']?.toString() ?? 'UnknownModel'; // Use various sources
        String deviceId = deviceData['id']?.toString() ?? deviceData['deviceId']?.toString() ?? deviceData['utsname.machine:']?.toString() ?? deviceData['systemGUID']?.toString() ?? deviceData['machineId']?.toString() ?? 'UnknownId'; // Use various sources

        currentDeviceInfo = '$brand $board $model $deviceId $deviceType'.trim();

        if(mounted) {
            setState(() => _deviceInfoString = currentDeviceInfo); // Update state if successful
            // If refetch still results in unknown/failed, show a warning but proceed
            if (currentDeviceInfo.contains("Unknown") || currentDeviceInfo.contains("Failed to get details")) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text("Device info issue. Using partial info for registration.", style: TextStyle(color: theme.colorScheme.onSecondaryContainer)), // Hardcoded fallback
                 backgroundColor: theme.colorScheme.secondaryContainer,
                 behavior: SnackBarBehavior.floating,
               ));
             }
        } else {
             print("_submitForm refetch finished but RegistrationScreen was already disposed.");
             return; // Don't proceed if screen disposed during async call
        }
     }


    if (_selectedCategory == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDepartmentError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedInstitution == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectInstitutionError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedYear == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectYearError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedGender == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectGenderError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (!_agreedToTerms) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }

    String rawPhoneInput = _phoneController.text.trim();
    String? finalPhoneNumberForUser;

     // Use AuthProvider's normalization logic for consistency
    finalPhoneNumberForUser = authProvider.normalizePhoneNumberToE164(rawPhoneInput);

    // Basic validation check after normalization
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(finalPhoneNumberForUser ?? '')) { // Check against normalized phone
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhoneNumberFormatError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,));
      return;
    }


    // Pass the assembled device info string
    final User registrationPayload = User(
      firstName: _studentNameController.text.trim(),
      lastName: _fatherNameController.text.trim(),
      phone: finalPhoneNumberForUser!,
      password: _passwordController.text,
      grade: _selectedYear!,
      category: _selectedCategory!,
      school: _selectedInstitution!,
      gender: _selectedGender!,
      device: currentDeviceInfo, // Use the assembled string
      status: "pending", // Assuming this is the initial status
      allCourses: false, // Default value
      enrolledAll: false, // Default value
      region: "Not Specified", // Default value or collect from user
       // serviceType and enrolledCourseIds likely not for registration payload
    );

     // Pass the payload object to AuthProvider
    bool userRegistrationSuccess = await authProvider.registerUserFull(
        registrationData: registrationPayload, // Pass the User object
    );

    if (!mounted) return;

    if (userRegistrationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.registrationSuccessMessage, style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          backgroundColor: theme.colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to LoginScreen after successful registration
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.apiError?.message ?? l10n.registrationFailedDefaultMessage, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // Allow submit if device info is fetched, even if it contains "Unknown" or "Failed"
    bool canAttemptSubmit = _isDeviceInfoFetchedInitially;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUpTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _hasAttemptedSubmit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(controller: _studentNameController, decoration: InputDecoration(labelText: l10n.studentNameLabel), validator: (v) => (v == null || v.trim().isEmpty) ? l10n.studentNameValidationError : null),
              const SizedBox(height: 16),
              TextFormField(controller: _fatherNameController, decoration: InputDecoration(labelText: l10n.fatherNameLabel), validator: (v) => (v == null || v.trim().isEmpty) ? l10n.fatherNameValidationError : null),
              const SizedBox(height: 16),
              PhoneFormField(controller: _phoneController, l10n: l10n),
              const SizedBox(height: 16),
              PasswordFormField(controller: _passwordController, isPasswordVisible: _isPasswordVisible, onToggleVisibility: _togglePasswordVisibility, l10n: l10n),
              const SizedBox(height: 20),

              Text(l10n.departmentLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(hintText: l10n.selectDepartmentHint, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
                onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
                validator: (value) => value == null ? l10n.pleaseSelectDepartmentError : null,
              ),
              const SizedBox(height: 20),

              Text(l10n.institutionLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(hintText: l10n.selectInstitutionHint, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                value: _selectedInstitution,
                isExpanded: true,
                items: _institutions.map((String institution) => DropdownMenuItem<String>(value: institution, child: Text(institution))).toList(),
                onChanged: (newValue) => setState(() => _selectedInstitution = newValue),
                validator: (value) => value == null ? l10n.institutionValidationError : null,
              ),
              const SizedBox(height: 20),

              Text(l10n.yearLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(hintText: l10n.selectYearHint, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                value: _selectedYear,
                isExpanded: true,
                items: _academicYears.map((String year) => DropdownMenuItem<String>(value: year, child: Text(year))).toList(),
                onChanged: (String? newValue) => setState(() => _selectedYear = newValue),
                validator: (value) => value == null ? l10n.pleaseSelectYearError : null,
              ),
              const SizedBox(height: 20),

              Text(l10n.genderLabel, style: theme.textTheme.titleMedium),
              Row(children: [
                Expanded(child: RadioListTile<String>(title: Text(l10n.maleGender), value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: theme.colorScheme.primary)),
                Expanded(child: RadioListTile<String>(title: Text(l10n.femaleGender), value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: theme.colorScheme.primary))
              ]),
              if (_hasAttemptedSubmit && _selectedGender == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 0.0, left: 12.0, bottom: 10.0),
                   child: Text(l10n.pleaseSelectGenderError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 24),

              CheckboxListTile(
                title: RichText(
                    text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                      TextSpan(text: l10n.termsAndConditionsAgreement),
                      TextSpan(text: l10n.termsAndConditionsLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline)),
                      TextSpan(text: l10n.termsAndConditionsAnd),
                      TextSpan(text: l10n.privacyPolicyLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline))
                    ])),
                value: _agreedToTerms,
                onChanged: (bool? value) => setState(() => _agreedToTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasAttemptedSubmit && !_agreedToTerms)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 24),

              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return (auth.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: canAttemptSubmit ? _submitForm : null,
                          child: Text(l10n.createAccountButton)
                        );
                },
              ),
               // Show initializing message if device info isn't ready
               if (!canAttemptSubmit && !Provider.of<AuthProvider>(context, listen: false).isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                     _deviceInfoString.contains("Failed to get details") || _deviceInfoString.contains("Unknown")
                                    ? "Device info failed. Try again." // Hardcoded fallback
                                    : "Initializing device info...", // Hardcoded fallback
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}