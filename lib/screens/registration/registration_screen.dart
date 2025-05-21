// lib/screens/registration/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform; // <<< ADD THIS IMPORT
// ... other imports
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart';
import 'package:mgw_tutorial/services/device_info.dart';
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/department.dart';
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

  Department? _selectedDepartment;
  String? _selectedInstitution;
  String? _selectedGender;
  String? _selectedYear;

  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...';
  bool _isDeviceInfoFetchedInitially = false;

  bool _hasAttemptedSubmit = false;

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
      Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments();
    });
  }

  Future<void> _initializeDeviceInfo() async {
    if (!mounted) return;
    await _getDeviceInfoInternal();
    if (mounted) {
      setState(() {
        _isDeviceInfoFetchedInitially = true;
      });
    }
  }

  Future<String> _getDeviceInfoInternal() async {
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
            print("Error detecting device type in RegistrationScreen _getDeviceInfoInternal: $e. Using platform default.");
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
        print("Context not active for MediaQuery in RegistrationScreen _getDeviceInfoInternal, using platform default for deviceType: $deviceType");
    }

    String finalDeviceInfo = '$deviceType - $brand $model, $os';
    if (mounted) {
      _deviceInfoString = finalDeviceInfo;
      print("Device Info for Registration Updated: $_deviceInfoString");
    }
    return finalDeviceInfo;
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

    String currentDeviceInfo = _deviceInfoString;
    if (!_isDeviceInfoFetchedInitially || currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown")) {
        currentDeviceInfo = await _getDeviceInfoInternal();
        if(mounted) setState(() => _deviceInfoString = currentDeviceInfo);
        if (currentDeviceInfo == 'Fetching device info...' || currentDeviceInfo.contains("Unknown")) {
            if(mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Device info issue. Using default.", style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                backgroundColor: theme.colorScheme.secondaryContainer,
                behavior: SnackBarBehavior.floating,
              ));
            }
            currentDeviceInfo = "Mobile - Generic Registration, UnknownOS";
            if(mounted) setState(() => _deviceInfoString = currentDeviceInfo);
        }
    }

    if (_selectedDepartment == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDepartmentError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedInstitution == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectInstitutionError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedYear == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectYearError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (_selectedGender == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectGenderError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }
    if (!_agreedToTerms) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,)); return; }

    String rawPhoneInput = _phoneController.text.trim();
    String? finalPhoneNumberForUser;

    if (rawPhoneInput.startsWith('0') && rawPhoneInput.length == 10) {
        finalPhoneNumberForUser = '+251${rawPhoneInput.substring(1)}';
    } else if (rawPhoneInput.length == 9 && int.tryParse(rawPhoneInput) != null && !rawPhoneInput.startsWith('+')  && !rawPhoneInput.startsWith('0')) {
        finalPhoneNumberForUser = '+251$rawPhoneInput';
    } else if (rawPhoneInput.startsWith('+251') && rawPhoneInput.length == 13) {
        finalPhoneNumberForUser = rawPhoneInput;
    } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhoneNumberFormatError, style: TextStyle(color: theme.colorScheme.onErrorContainer)), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating,));
        return;
    }

    final User registrationPayload = User(
      firstName: _studentNameController.text.trim(),
      lastName: _fatherNameController.text.trim(),
      phone: finalPhoneNumberForUser!,
      password: _passwordController.text,
      grade: _selectedYear!,
      category: _selectedDepartment!.name,
      school: _selectedInstitution!,
      gender: _selectedGender!,
      device: currentDeviceInfo,
      status: "pending",
      allCourses: false,
      enrolledAll: false,
      region: "Not Specified",
    );

    bool userRegistrationSuccess = await authProvider.registerUserFull(
        registrationData: registrationPayload,
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
    bool canAttemptSubmit = _isDeviceInfoFetchedInitially;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signUpTitle), // Changed from getRegisteredTitle
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
              Consumer<DepartmentProvider>(
                builder: (context, deptProvider, child) {
                   if (deptProvider.isLoading && deptProvider.departments.isEmpty) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                  }
                  if (deptProvider.error != null && deptProvider.departments.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deptProvider.error!, style: TextStyle(color: theme.colorScheme.error)),
                        ElevatedButton.icon(icon: const Icon(Icons.refresh, size: 18), label: Text(l10n.refresh), onPressed: () => deptProvider.fetchDepartments(), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer,foregroundColor: theme.colorScheme.onErrorContainer, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 14))),
                      ],
                    );
                  }
                  if (deptProvider.departments.isEmpty && !deptProvider.isLoading) {
                    return Text(l10n.appTitle.contains("መጂወ") ? "ምንም ዲፓርትመንቶች የሉም።" : 'No departments available.', style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)));
                  }
                  return DropdownButtonFormField<Department>(
                    decoration: InputDecoration(hintText: l10n.selectDepartmentHint, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                    value: _selectedDepartment,
                    isExpanded: true,
                    items: deptProvider.departments.map((Department department) => DropdownMenuItem<Department>(value: department, child: Text(department.name))).toList(),
                    onChanged: (Department? newValue) => setState(() => _selectedDepartment = newValue),
                    validator: (value) => value == null ? l10n.pleaseSelectDepartmentError : null,
                  );
                },
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
               if (!canAttemptSubmit && !Provider.of<AuthProvider>(context, listen: false).isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Initializing...",
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