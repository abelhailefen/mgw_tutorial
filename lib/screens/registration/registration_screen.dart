// lib/screens/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart'; // Import DepartmentProvider
import 'package:mgw_tutorial/services/device_info.dart';
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/department.dart'; // Import Department model
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Widgets
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';

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
  // _yearController is removed, will use _selectedYear

  Department? _selectedDepartment; // Changed from _selectedCategory to _selectedDepartment
  String? _selectedInstitution; // Keep this
  String? _selectedGender;
  String? _selectedYear; // For the new year dropdown

  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = '';

  bool _hasAttemptedSubmit = false;

  // Static list for institutions (can also be fetched from API if needed)
  final List<String> _institutions = [
    'Addis Ababa University', 'Bahir Dar University', 'Hawassa University', 'Other',
  ];

  // Years for the dropdown
  final List<String> _academicYears = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', '6th Year', '7th Year'
  ];


  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    // Fetch departments when the screen initializes
    Future.microtask(() =>
        Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments());
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    // _yearController.dispose(); // Removed
    super.dispose();
  }

  Future<void> _getDeviceInfo() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
    String deviceType = _deviceInfoService.detectDeviceType(context);

    if (mounted) {
      setState(() {
        _deviceInfoString = '$deviceType - $brand $model, $os';
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() { _isPasswordVisible = !_isPasswordVisible; });
  }

  Future<void> _pickScreenshot() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() { _pickedXFile = pickedFile; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
      }
    }
  }

  Future<void> _submitForm() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Custom validations
    if (_selectedDepartment == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDepartmentError))); return; } // New l10n string
    if (_selectedInstitution == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectInstitutionError))); return; }
    if (_selectedYear == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectYearError))); return; } // New l10n string
    if (_selectedGender == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectGenderError))); return; }
    if (_pickedXFile == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAttachScreenshotError))); return; }
    if (!_agreedToTerms) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError))); return; }

    String rawPhoneInput = _phoneController.text.trim();
    String? finalPhoneNumber;
    // ... (phone normalization logic - keep as is)
    if (rawPhoneInput.startsWith('0') && rawPhoneInput.length == 10) {
        finalPhoneNumber = '+251${rawPhoneInput.substring(1)}';
    } else if (rawPhoneInput.length == 9 && int.tryParse(rawPhoneInput) != null && !rawPhoneInput.startsWith('+')) {
        finalPhoneNumber = '+251$rawPhoneInput';
    } else if (rawPhoneInput.startsWith('+251') && rawPhoneInput.length == 13) {
        finalPhoneNumber = rawPhoneInput;
    } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhoneNumberFormatError)));
        return;
    }
    if (finalPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhoneNumberFormatError)));
      return;
    }

    final User registrationPayload = User(
      firstName: _studentNameController.text.trim(),
      lastName: _fatherNameController.text.trim(),
      phone: finalPhoneNumber,
      password: _passwordController.text,
      grade: _selectedYear!,        // Using selected year
      category: _selectedDepartment!.name, // Using selected department's name
      school: _selectedInstitution!,
      gender: _selectedGender!,
      device: _deviceInfoString,
      // serviceType: _selectedService!, // REMOVED serviceType
      status: "pending",
      allCourses: false,
      enrolledAll: false,
      region: "Not Specified",
    );

    bool success = await authProvider.registerUserFull(
        registrationData: registrationPayload,
        screenshotFile: _pickedXFile,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registrationSuccessMessage)),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.apiError?.message ?? l10n.registrationFailedDefaultMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildPaymentInfoTile(AppLocalizations l10n, String bankName, String accountNumber, String accountHolder) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
        title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             Text('${l10n.bankAccountLabel}: $accountNumber'),
            Text('${l10n.bankHolderNameLabel}: $accountHolder'),
          ],),
        trailing: IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboardMessage(accountNumber))));
          },),),);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context); // Get DepartmentProvider

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getRegisteredTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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

              // --- Department Dropdown ---
              Text(l10n.departmentLabel, style: Theme.of(context).textTheme.titleMedium), // New l10n string
              const SizedBox(height: 8),
              Consumer<DepartmentProvider>( // Use Consumer to rebuild when departments load
                builder: (context, deptProvider, child) {
                  if (deptProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2.0,));
                  }
                  if (deptProvider.error != null) {
                    return Text('Error loading departments: ${deptProvider.error}', style: TextStyle(color: Colors.red));
                  }
                  if (deptProvider.departments.isEmpty) {
                    return Text('No departments available.', style: TextStyle(color: Colors.grey));
                  }
                  return DropdownButtonFormField<Department>(
                    decoration: InputDecoration(hintText: l10n.selectDepartmentHint, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                    value: _selectedDepartment,
                    isExpanded: true,
                    items: deptProvider.departments.map((Department department) {
                      return DropdownMenuItem<Department>(
                        value: department,
                        child: Text(department.name),
                      );
                    }).toList(),
                    onChanged: (Department? newValue) {
                      setState(() {
                        _selectedDepartment = newValue;
                      });
                    },
                    validator: (value) => value == null ? l10n.pleaseSelectDepartmentError : null, // New l10n string
                  );
                },
              ),
              const SizedBox(height: 20),

              Text(l10n.institutionLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(hintText: l10n.selectInstitutionHint, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)),
                value: _selectedInstitution,
                isExpanded: true,
                items: _institutions.map((String institution) => DropdownMenuItem<String>(value: institution, child: Text(institution))).toList(),
                onChanged: (newValue) => setState(() => _selectedInstitution = newValue),
                validator: (value) => value == null ? l10n.institutionValidationError : null,
              ),
              const SizedBox(height: 20),

              // --- Year Dropdown ---
              Text(l10n.yearLabel, style: Theme.of(context).textTheme.titleMedium), // Re-use if appropriate, or new l10n for "Academic Year"
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(hintText: l10n.selectYearHint, border: const OutlineInputBorder(), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0)), // New l10n string
                value: _selectedYear,
                isExpanded: true,
                items: _academicYears.map((String year) {
                  return DropdownMenuItem<String>(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedYear = newValue;
                  });
                },
                validator: (value) => value == null ? l10n.pleaseSelectYearError : null, // New l10n string
              ),
              const SizedBox(height: 20),


              Text(l10n.genderLabel, style: Theme.of(context).textTheme.titleMedium),
              Row(children: [
                Expanded(child: RadioListTile<String>(title: Text(l10n.maleGender), value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v))),
                Expanded(child: RadioListTile<String>(title: Text(l10n.femaleGender), value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)))
              ]),
              if (_hasAttemptedSubmit && _selectedGender == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseSelectGenderError, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 20),

              // REMOVED Select Service Dropdown

              Text(l10n.paymentInstruction, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              _buildPaymentInfoTile(l10n, 'CBE', '1000 123 4587 4584', 'Debebe Workabeb Tessema'),
              _buildPaymentInfoTile(l10n, 'Telebirr', '09 45 45 78 45', 'Debebe Workabeb Tessema'),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(_pickedXFile == null ? l10n.attachScreenshotButton : l10n.screenshotAttachedButton),
                  onPressed: _pickScreenshot,
                  style: OutlinedButton.styleFrom( padding: const EdgeInsets.symmetric(vertical: 12), textStyle: const TextStyle(fontSize: 16), side: BorderSide(color: Theme.of(context).primaryColor))),
              if (_pickedXFile != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${l10n.fileNamePrefix}: ${_pickedXFile!.name}', style: TextStyle(color: Colors.green[700]), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
              const SizedBox(height: 24),

              CheckboxListTile(
                title: RichText(
                    text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                        children: [
                      TextSpan(text: l10n.termsAndConditionsAgreement),
                      TextSpan(text: l10n.termsAndConditionsLink, style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)),
                      TextSpan(text: l10n.termsAndConditionsAnd),
                      TextSpan(text: l10n.privacyPolicyLink, style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline))
                    ])),
                value: _agreedToTerms,
                onChanged: (bool? value) => setState(() => _agreedToTerms = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_hasAttemptedSubmit && !_agreedToTerms)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseAgreeToTermsError, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 24),

              authProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _submitForm, child: Text(l10n.submitButton)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}