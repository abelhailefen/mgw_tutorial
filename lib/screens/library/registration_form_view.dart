// lib/screens/library/registration_form_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // Already imported in AuthProvider
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:mgw_tutorial/services/device_info.dart';
import 'package:mgw_tutorial/models/user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Widgets from lib/widgets/ - Ensure these paths are correct
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';

class RegistrationFormView extends StatefulWidget {
  final VoidCallback? onSuccessfulRegistration;

  const RegistrationFormView({super.key, this.onSuccessfulRegistration});

  @override
  State<RegistrationFormView> createState() => _RegistrationFormViewState();
}

class _RegistrationFormViewState extends State<RegistrationFormView> {
  final _formKey = GlobalKey<FormState>();

  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _yearController = TextEditingController();

  String? _selectedCategory;
  String? _selectedInstitution;
  String? _selectedGender;
  String? _selectedService;

  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;

  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  String _deviceInfoString = '';

  final List<String> _categories = ['Natural', 'Social', 'Remedial', 'Other Department'];
  final List<String> _institutions = [
    'Addis Ababa University', 'Bahir Dar University', 'Hawassa University', 'Other',
  ];
  final List<String> _services = [
    'Freshman First Semester', 'Freshman Second Semester', 'Remedial Program',
  ];

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _getDeviceInfo() async {
    final deviceData = await _deviceInfoService.getDeviceData();
    String brand = deviceData['brand'] ?? deviceData['name'] ?? 'UnknownBrand';
    String model = deviceData['model'] ?? deviceData['localizedModel'] ?? 'UnknownModel';
    String os = deviceData['systemName'] ?? deviceData['platform'] ?? 'UnknownOS';
    String deviceType = _deviceInfoService.detectDeviceType(context);

    setState(() {
      _deviceInfoString = '$deviceType - $brand $model, $os';
    });
  }

  void _togglePasswordVisibility() {
    setState(() { _isPasswordVisible = !_isPasswordVisible; });
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) setState(() { _pickedXFile = pickedFile; });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorPickingImage(e.toString()))));
      }
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectStreamError))); return; }
    if (_selectedInstitution == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectInstitutionError))); return; }
    if (_selectedGender == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectGenderError))); return; }
    if (_selectedService == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectServiceError))); return; }
    if (_pickedXFile == null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAttachScreenshotError))); return; }
    if (!_agreedToTerms) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseAgreeToTermsError))); return; }

    final User registrationPayload = User(
      firstName: _studentNameController.text.trim(),
      lastName: _fatherNameController.text.trim(),
      phone: '+251${_phoneController.text.trim()}',
      password: _passwordController.text, // Ensure password is not null
      grade: _yearController.text.trim(),
      category: _selectedCategory!,
      school: _selectedInstitution!,
      gender: _selectedGender!,
      device: _deviceInfoString,
      serviceType: _selectedService!,
      status: "pending",
      allCourses: false,
      enrolledAll: false,
      region: "Not Specified",
    );
    bool success = await authProvider.registerUserFull(
        registrationData: registrationPayload,
        screenshotFile: _pickedXFile,
    );

    if(mounted){
        if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful! Please await admin approval.')), // TODO: Localize
            );
            widget.onSuccessfulRegistration?.call();
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(authProvider.apiError?.message ?? 'Registration failed. Please try again.'), // TODO: Localize
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.getRegisteredTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark)),
            const SizedBox(height: 20),

            TextFormField(controller: _studentNameController, decoration: InputDecoration(labelText: l10n.studentNameLabel), validator: (v) => (v==null || v.trim().isEmpty) ? l10n.studentNameValidationError : null),
            const SizedBox(height: 16),
            TextFormField(controller: _fatherNameController, decoration: InputDecoration(labelText: l10n.fatherNameLabel), validator: (v) => (v==null || v.trim().isEmpty) ? l10n.fatherNameValidationError : null),
            const SizedBox(height: 16),

            PhoneFormField(controller: _phoneController, l10n: l10n),
            const SizedBox(height: 16),
            PasswordFormField(controller: _passwordController, isPasswordVisible: _isPasswordVisible, onToggleVisibility: _togglePasswordVisibility, l10n: l10n),
            const SizedBox(height: 20),

            // Category (Stream/Department) Dropdown - Using built-in DropdownButtonFormField
            Text(l10n.streamLabel, style: Theme.of(context).textTheme.titleMedium), // Or a new "Department" label
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: "Select Department/Stream", // TODO: Localize hint
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              ),
              value: _selectedCategory,
              isExpanded: true,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(value: category, child: Text(category));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedCategory = newValue),
              validator: (value) => value == null ? l10n.pleaseSelectStreamError : null,
            ),
            const SizedBox(height: 20),

            // Institution Dropdown - Using built-in DropdownButtonFormField
            Text(l10n.institutionLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: l10n.selectInstitutionHint,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              ),
              value: _selectedInstitution,
              isExpanded: true,
              items: _institutions.map((String institution) {
                return DropdownMenuItem<String>(value: institution, child: Text(institution));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedInstitution = newValue),
              validator: (value) => value == null ? l10n.institutionValidationError : null,
            ),
            const SizedBox(height: 20),

            TextFormField(controller: _yearController, decoration: InputDecoration(labelText: "Year / Grade" /* TODO: l10n.yearGradeLabel */), keyboardType: TextInputType.number, validator: (v) { if(v==null || v.trim().isEmpty) return "Please enter year/grade" /* TODO: l10n */; if(int.tryParse(v)==null) return "Please enter valid year" /* TODO: l10n */; return null; }),
            const SizedBox(height: 20),

            Text(l10n.genderLabel, style: Theme.of(context).textTheme.titleMedium),
            Row(children: [ Expanded(child: RadioListTile<String>(title: Text(l10n.maleGender), value: 'Male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v))), Expanded(child: RadioListTile<String>(title: Text(l10n.femaleGender), value: 'Female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)))]),
            const SizedBox(height: 20),

            // Select Service Dropdown - Using built-in DropdownButtonFormField
            Text(l10n.selectServiceLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: l10n.selectServiceHint,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              ),
              value: _selectedService,
              isExpanded: true,
              items: _services.map((String service) {
                return DropdownMenuItem<String>(value: service, child: Text(service));
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedService = newValue),
              validator: (value) => value == null ? l10n.serviceValidationError : null,
            ),
            const SizedBox(height: 24),

            Text(l10n.paymentInstruction, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _buildPaymentInfoTile(l10n,'CBE', '1000 123 4587 4584', 'Debebe Workabeb Tessema'),
            _buildPaymentInfoTile(l10n,'Telebirr', '09 45 45 78 45', 'Debebe Workabeb Tessema'),
            const SizedBox(height: 20),

            OutlinedButton.icon(icon: const Icon(Icons.attach_file), label: Text(_pickedXFile == null ? l10n.attachScreenshotButton : l10n.screenshotAttachedButton), onPressed: _pickScreenshot, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),textStyle: const TextStyle(fontSize: 16), side: BorderSide(color: Theme.of(context).primaryColor))),
            if (_pickedXFile != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('${l10n.fileNamePrefix}: ${_pickedXFile!.name}', style: TextStyle(color: Colors.green[700]), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 24),

            CheckboxListTile(
              title: RichText(text: TextSpan(style: Theme.of(context).textTheme.bodyMedium, children: [ TextSpan(text: l10n.termsAndConditionsAgreement), TextSpan(text: l10n.termsAndConditionsLink, style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline)), TextSpan(text: l10n.termsAndConditionsAnd), TextSpan(text: l10n.privacyPolicyLink, style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline))])),
              value: _agreedToTerms,
              onChanged: (bool? value) => setState(() => _agreedToTerms = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            authProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(onPressed: _submitForm, child: Text(l10n.submitButton)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}