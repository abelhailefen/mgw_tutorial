// lib/screens/registration/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/provider/department_provider.dart';
import 'package:mgw_tutorial/provider/semester_provider.dart';
import 'package:mgw_tutorial/provider/order_provider.dart';
import 'package:mgw_tutorial/services/device_info.dart';
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/department.dart';
import 'package:mgw_tutorial/models/semester.dart';
import 'package:mgw_tutorial/models/order.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';
import 'package:flutter/gestures.dart'; // For RichText tap recognizer

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
  String? _selectedBankName;
  Semester? _selectedSemester;

  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = 'Fetching device info...';

  bool _hasAttemptedSubmit = false;

  final List<String> _institutions = [
    'Addis Ababa University', 'Bahir Dar University', 'Hawassa University', 'Other', // TODO: Localize these if needed or fetch from API
  ];
  final List<String> _academicYears = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', '6th Year', '7th Year' // TODO: Localize
  ];
  final List<Map<String, String>> _bankAccounts = [ // TODO: Consider making these configurable or API-driven
    {'name': 'CBE', 'accountNumber': '1000 123 4587 4584', 'holder': 'Debebe Workabeb Tessema'},
    {'name': 'Telebirr', 'accountNumber': '09 45 45 78 45', 'holder': 'Debebe Workabeb Tessema'},
  ];

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    Future.microtask(() {
      Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments();
      Provider.of<SemesterProvider>(context, listen: false).fetchSemesters();
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _getDeviceInfo() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';

    String deviceType = "Unknown Device";
    if (mounted) {
        try {
             deviceType = _deviceInfoService.detectDeviceType(context);
        } catch (e) {
            print("Error detecting device type in RegistrationScreen initState: $e.");
        }
    }

    if (mounted) {
      setState(() {
        _deviceInfoString = '$deviceType - $brand $model, $os';
        print("Device Info for Registration: $_deviceInfoString");
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() { _isPasswordVisible = !_isPasswordVisible; });
  }

  Future<void> _pickScreenshot() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() { _pickedXFile = pickedFile; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.errorPickingImage(e.toString())),
                backgroundColor: theme.colorScheme.errorContainer,
                behavior: SnackBarBehavior.floating,
            ));
      }
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final theme = Theme.of(context);

    if (!mounted) return;

    authProvider.clearError();
    orderProvider.clearError();

    setState(() { _hasAttemptedSubmit = true; });
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDepartmentError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_selectedInstitution == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectInstitutionError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_selectedYear == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectYearError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_selectedGender == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectGenderError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_selectedSemester == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectSemesterError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_selectedBankName == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.appTitle.contains("መጂወ") ? 'እባክዎ የክፍያ ማጣቀሻ ባንክ ይምረጡ።' : 'Please select a bank for payment reference.'), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (_pickedXFile == null) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAttachScreenshotError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }
    if (!_agreedToTerms) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating)); return; }

    String rawPhoneInput = _phoneController.text.trim();
    String? finalPhoneNumberForUser;
    String phoneForOrder;

    if (rawPhoneInput.startsWith('0') && rawPhoneInput.length == 10) {
        finalPhoneNumberForUser = '+251${rawPhoneInput.substring(1)}';
        phoneForOrder = rawPhoneInput;
    } else if (rawPhoneInput.length == 9 && int.tryParse(rawPhoneInput) != null && !rawPhoneInput.startsWith('+')) {
        finalPhoneNumberForUser = '+251$rawPhoneInput';
        phoneForOrder = '0$rawPhoneInput';
    } else if (rawPhoneInput.startsWith('+251') && rawPhoneInput.length == 13) {
        finalPhoneNumberForUser = rawPhoneInput;
        phoneForOrder = '0${rawPhoneInput.substring(4)}';
    } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.invalidPhoneNumberFormatError), backgroundColor: theme.colorScheme.errorContainer, behavior: SnackBarBehavior.floating));
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
      device: _deviceInfoString,
      status: "pending",
      allCourses: false,
      enrolledAll: false,
      region: "Not Specified", // TODO: Add region field if needed
    );

    bool userRegistrationSuccess = await authProvider.registerUserFull(
        registrationData: registrationPayload,
        screenshotFile: _pickedXFile,
    );

    if (!userRegistrationSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.apiError?.message ?? l10n.registrationFailedDefaultMessage),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("${l10n.registrationSuccessMessage} ${l10n.appTitle.contains("መጂወ") ? "አሁን የሴሚስተር ምርጫዎን በማስገባት ላይ..." : "Now submitting your semester selection..."}"),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
        ),
      );

      List<OrderSelectionItem> orderSelections = [];
      if (_selectedSemester != null) {
        orderSelections.add(OrderSelectionItem(
          id: _selectedSemester!.id.toString(),
          name: _selectedSemester!.name,
        ));
      }

      final Order orderPayloadForFields = Order(
        fullName: '${_studentNameController.text.trim()} ${_fatherNameController.text.trim()}',
        bankName: _selectedBankName,
        phone: phoneForOrder,
        type: "semester_enrollment",
        status: "pending",
        selections: orderSelections,
      );

      bool orderCreationSuccess = await orderProvider.createOrder(
        orderData: orderPayloadForFields,
        screenshotFile: _pickedXFile,
      );

      if (mounted) {
        if (orderCreationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
                 content: Text(l10n.appTitle.contains("መጂወ") ? 'ተጠቃሚ ተመዝግቧል እና የሴሚስተር ምርጫ በተሳካ ሁኔታ ገብቷል! ማረጋገጫ በመጠበቅ ላይ።' : 'User registered and semester selection submitted successfully! Awaiting approval.'),
                 backgroundColor: theme.colorScheme.primaryContainer,
                 behavior: SnackBarBehavior.floating,
             ),
          );
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${l10n.appTitle.contains("መጂወ") ? "ተጠቃሚ ተመዝግቧል፣ ነገር ግን የሴሚስተር ምርጫ አልተሳካም፡ " : "User registered, but semester selection failed: "}${orderProvider.error ?? (l10n.appTitle.contains("መጂወ") ? 'ያልታወቀ የስህተት ስህተት።' : 'Unknown order error.')}"),
              backgroundColor: theme.colorScheme.tertiaryContainer, // Using tertiary as a warning
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildPaymentInfoTile(AppLocalizations l10n, String bankName, String accountNumber, String accountHolder) {
    final theme = Theme.of(context);
    bool isSelected = _selectedBankName == bankName;
    return Card(
      elevation: isSelected ? 4.0 : 1.0, // Keep elevation difference
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, width: isSelected ? 2 : 1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBankName = bankName;
          });
        },
        borderRadius: BorderRadius.circular(8.0),
        child: ListTile(
          leading: Icon(Icons.account_balance, color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color),
          title: Text(bankName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.primary : theme.textTheme.titleMedium?.color)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.bankAccountLabel}: $accountNumber', style: theme.textTheme.bodySmall),
              Text('${l10n.bankHolderNameLabel}: $accountHolder', style: theme.textTheme.bodySmall),
            ],
          ),
          trailing: IconButton( // Consider making copy less prominent or part of the tap action
            icon: Icon(Icons.copy, size: 20, color: theme.iconTheme.color?.withOpacity(0.7)),
            onPressed: () {
              // Clipboard.setData(ClipboardData(text: accountNumber)); // Requires services import
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedToClipboardMessage(accountNumber)), backgroundColor: theme.colorScheme.secondaryContainer, behavior: SnackBarBehavior.floating));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    InputDecoration dropdownDecoration(String hintText) => InputDecoration(
      hintText: hintText,
      border: const OutlineInputBorder(),
      // fillColor will be from global theme
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.getRegisteredTitle),
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
                        Text(l10n.appTitle.contains("መጂወ") ? 'ዲፓርትመንቶችን መጫን አልተሳካም። እባክዎ ግንኙነትዎን ያረጋግጡ።' : 'Failed to load departments. Please check connection.', style: TextStyle(color: theme.colorScheme.error)),
                        ElevatedButton.icon(icon: const Icon(Icons.refresh, size: 18), label: Text(l10n.refresh), onPressed: () => deptProvider.fetchDepartments(), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer,foregroundColor: theme.colorScheme.onErrorContainer, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 14))),
                      ],
                    );
                  }
                  if (deptProvider.departments.isEmpty && !deptProvider.isLoading) {
                    return Text(l10n.appTitle.contains("መጂወ") ? 'ምንም ዲፓርትመንቶች የሉም።' : 'No departments available.', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)));
                  }
                  return DropdownButtonFormField<Department>(
                    decoration: dropdownDecoration(l10n.selectDepartmentHint),
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
                decoration: dropdownDecoration(l10n.selectInstitutionHint),
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
                decoration: dropdownDecoration(l10n.selectYearHint),
                value: _selectedYear,
                isExpanded: true,
                items: _academicYears.map((String year) => DropdownMenuItem<String>(value: year, child: Text(year))).toList(),
                onChanged: (String? newValue) => setState(() => _selectedYear = newValue),
                validator: (value) => value == null ? l10n.pleaseSelectYearError : null,
              ),
              const SizedBox(height: 20),

              Text(l10n.genderLabel, style: theme.textTheme.titleMedium),
              Row(children: [ // Consider using SegmentedButton for a more modern look if Flutter version allows
                Expanded(child: RadioListTile<String>(title: Text(l10n.maleGender), value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: theme.colorScheme.primary, contentPadding: EdgeInsets.zero)),
                Expanded(child: RadioListTile<String>(title: Text(l10n.femaleGender), value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v), activeColor: theme.colorScheme.primary, contentPadding: EdgeInsets.zero))
              ]),
              if (_hasAttemptedSubmit && _selectedGender == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseSelectGenderError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 20),

              Text(l10n.selectSemesterLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Consumer<SemesterProvider>(
                builder: (context, semesterProvider, child) {
                  if (semesterProvider.isLoading && semesterProvider.semesters.isEmpty) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (semesterProvider.error != null && semesterProvider.semesters.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.appTitle.contains("መጂወ") ? 'ሴሚስተሮችን መጫን አልተሳካም። እባክዎ ግንኙነትዎን ያረጋግጡ።' : 'Failed to load semesters. Please check connection.', style: TextStyle(color: theme.colorScheme.error)),
                        ElevatedButton.icon(icon: const Icon(Icons.refresh, size: 18), label: Text(l10n.refresh), onPressed: () => semesterProvider.fetchSemesters(), style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.errorContainer,foregroundColor: theme.colorScheme.onErrorContainer, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), textStyle: const TextStyle(fontSize: 14))),
                      ],
                    );
                  }
                  if (semesterProvider.semesters.isEmpty && !semesterProvider.isLoading) {
                    return Text(l10n.appTitle.contains("መጂወ") ? "ምንም ሴሚስተሮች የሉም።" : "No semesters available.", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)));
                  }

                  if (_selectedSemester != null && !semesterProvider.semesters.any((s) => s.id == _selectedSemester!.id)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if(mounted) {
                           setState(() { _selectedSemester = null; });
                        }
                      });
                  }

                  return DropdownButtonFormField<Semester>(
                    decoration: dropdownDecoration(l10n.selectSemesterHint),
                    value: _selectedSemester,
                    isExpanded: true,
                    items: semesterProvider.semesters.map((Semester semester) {
                      return DropdownMenuItem<Semester>(
                        value: semester,
                        child: Text("${semester.name} - ${semester.year} (${semester.price} ETB)"),
                      );
                    }).toList(),
                    onChanged: (Semester? newValue) {
                      setState(() {
                        _selectedSemester = newValue;
                      });
                    },
                    validator: (value) => value == null ? l10n.pleaseSelectSemesterError : null,
                  );
                },
              ),
              if (_hasAttemptedSubmit && _selectedSemester == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseSelectSemesterError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 20),

              Text(l10n.paymentInstruction, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              ..._bankAccounts.map((bank) => _buildPaymentInfoTile(l10n, bank['name']!, bank['accountNumber']!, bank['holder']!)).toList(),
               if (_hasAttemptedSubmit && _selectedBankName == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.appTitle.contains("መጂወ") ? 'እባክዎ የክፍያ ማጣቀሻ ባንክ ይምረጡ።' : "Please select a bank for payment reference.", style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                  icon: Icon(Icons.attach_file, color: theme.colorScheme.primary),
                  label: Text(_pickedXFile == null ? l10n.attachScreenshotButton : l10n.screenshotAttachedButton, style: TextStyle(color: theme.colorScheme.primary)),
                  onPressed: _pickScreenshot,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                      side: BorderSide(color: theme.colorScheme.primary)
                  )
              ),
              if (_pickedXFile != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${l10n.fileNamePrefix}: ${_pickedXFile!.name}', style: TextStyle(color: theme.colorScheme.secondary), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
              if (_hasAttemptedSubmit && _pickedXFile == null)
                 Padding(
                   padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                   child: Text(l10n.pleaseAttachScreenshotError, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                 ),
              const SizedBox(height: 24),

              CheckboxListTile(
                title: RichText(
                    text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                      TextSpan(text: l10n.termsAndConditionsAgreement),
                      TextSpan(text: l10n.termsAndConditionsLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Open T&C link */ print("T&C Tapped"); }),
                      TextSpan(text: l10n.termsAndConditionsAnd),
                      TextSpan(text: l10n.privacyPolicyLink, style: TextStyle(color: theme.colorScheme.primary, decoration: TextDecoration.underline), recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Open Privacy Policy link */ print("Privacy Policy Tapped"); })
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

              Consumer2<AuthProvider, OrderProvider>(
                builder: (context, auth, order, child) {
                  return (auth.isLoading || order.isLoading)
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(onPressed: _submitForm, child: Text(l10n.submitButton));
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