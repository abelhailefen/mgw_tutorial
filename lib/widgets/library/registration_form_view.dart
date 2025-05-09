
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
class RegistrationFormView extends StatefulWidget {
  final VoidCallback onSubmit; 

  const RegistrationFormView({super.key, required this.onSubmit});

  @override
  State<RegistrationFormView> createState() => _RegistrationFormViewState();
}

class _RegistrationFormViewState extends State<RegistrationFormView> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  final _studentNameController = TextEditingController();
  final _fatherNameController = TextEditingController();

  // State variables for selections
  String? _selectedStream; // 'Natural' or 'Social'
  String? _selectedInstitution; // Will be a dropdown
  String? _selectedGender; // 'Male' or 'Female'
  String? _selectedService; // Will be a dropdown

  XFile? _pickedXFile; // Stores the picked XFile


  final ImagePicker _picker = ImagePicker();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  // Mock data for dropdowns - replace with actual data source
  final List<String> _institutions = [
    'Addis Ababa University',
    'Bahir Dar University',
    'Hawassa University',
    'Other',
  ];
  final List<String> _services = [
    'Freshman First Semester',
    'Freshman Second Semester',
    'Remedial Program',
  ];

  @override
  void dispose() {
    _studentNameController.dispose();
    _fatherNameController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedXFile = pickedFile; // Store the XFile, works for web and mobile
          // if (!kIsWeb) {
          //   // Optionally create a File object for mobile-specific operations
          //   _screenshotFile = File(pickedFile.path);
          // }
        });
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still in the tree
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorPickingImage(e.toString()))),
        );
      }
    }
  }


  void _submitForm() {


    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      if (_selectedStream == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectStreamError)),
        );
        return;
      }
      if (_selectedInstitution == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectInstitutionError)),
        );
        return;
      }
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectGenderError)),
        );
        return;
      }
      if (_selectedService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseSelectServiceError)),
        );
        return;
      }
      // Check using _pickedXFile
      if (_pickedXFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseAttachScreenshotError)),
        );
        return;
      }
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.pleaseAgreeToTermsError)),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate API call and form processing
      print('Student Name: ${_studentNameController.text}');
      print('Father Name: ${_fatherNameController.text}');
      print('Stream: $_selectedStream');
      print('Institution: $_selectedInstitution');
      print('Gender: $_selectedGender');
      print('Service: $_selectedService');
      // For actual upload, you'd use _pickedXFile.readAsBytes()
      print('Screenshot Name: ${_pickedXFile?.name}');
      print('Screenshot Path (can be blob URL on web): ${_pickedXFile?.path}');
      print('Agreed to Terms: $_agreedToTerms');

      // Call the onSubmit callback passed from LibraryScreen
      widget.onSubmit();
    }
  }

  Widget _buildPaymentInfoTile(AppLocalizations l10n, String bankName, String accountNumber, String accountHolder) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
        title: Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('${l10n.bankAccountLabel}: $accountNumber'),
            Text('${l10n.bankHolderNameLabel}: $accountHolder'), 
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () {
            // Implement copy functionality (e.g., using clipboard package)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.copiedToClipboardMessage(accountNumber))),
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
   final l10n = AppLocalizations.of(context)!;
   
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.getRegisteredTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark
              ),
            ),
            const SizedBox(height: 20),

            // Student's Name
            TextFormField(
              controller: _studentNameController,
              decoration:  InputDecoration(labelText: l10n.studentNameLabel),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.studentNameValidationError;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Father's Name
            TextFormField(
              controller: _fatherNameController,
              decoration:  InputDecoration(labelText: l10n.fatherNameLabel),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.fatherNameValidationError;;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Stream (Natural/Social) - Using ToggleButtons
            Text(l10n.streamLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ToggleButtons(
              isSelected: [_selectedStream == 'Natural', _selectedStream == 'Social'],
              onPressed: (int index) {
                setState(() {
                  _selectedStream = index == 0 ? 'Natural' : 'Social';
                });
              },
              borderRadius: BorderRadius.circular(8.0),
              selectedColor: Colors.white,
              fillColor: Theme.of(context).primaryColor,
              color: Theme.of(context).primaryColor,
              constraints: BoxConstraints(minHeight: 40.0, minWidth: (MediaQuery.of(context).size.width - 48) / 2), // -padding, -spacing
              children:  <Widget>[
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.naturalStream)),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(l10n.socialStream)),
              ],
            ),
            const SizedBox(height: 20),

            // Institution Dropdown
           Text(l10n.institutionLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration:  InputDecoration(
                hintText: l10n.selectInstitutionHint,
                border: const OutlineInputBorder(),
              ),
              value: _selectedInstitution,
              items: _institutions.map((String institution) {
                return DropdownMenuItem<String>(
                  value: institution,
                  child: Text(institution),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedInstitution = newValue;
                });
              },
              validator: (value) => value == null ? l10n.institutionValidationError : null,
            ),
            const SizedBox(height: 20),

            // Gender Radio Buttons
            Text(l10n.genderLabel, style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    title:  Text(l10n.maleGender),
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title:  Text(l10n.femaleGender),
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Select Service Dropdown
             Text(l10n.selectServiceLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration:  InputDecoration(
                hintText: l10n.selectServiceHint,
                border: const OutlineInputBorder(),
              ),
              value: _selectedService,
              items: _services.map((String service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedService = newValue;
                });
              },
              validator: (value) => value == null ? l10n.serviceValidationError : null,
            ),
            const SizedBox(height: 24),

            // Payment Information Section
            Text(
              l10n.paymentInstruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildPaymentInfoTile(l10n,'CBE', '1000 123 4587 4584', 'Debebe Workabeb Tessema'),
            _buildPaymentInfoTile(l10n,'Telebirr', '09 45 45 78 45', 'Debebe Workabeb Tessema'),
            _buildPaymentInfoTile(l10n,'Abyssinia', '0147 2145 1458', 'Debebe Workabeb Tessema'),
            const SizedBox(height: 20),

            // Attach Screenshot Button
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: Text(_pickedXFile == null ? l10n.attachScreenshotButton : l10n.screenshotAttachedButton),
              onPressed: _pickScreenshot,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            // Display the picked file name using _pickedXFile.name
            if (_pickedXFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${l10n.fileNamePrefix}: ${_pickedXFile!.name}', // Corrected to use _pickedXFile.name
                  style: TextStyle(color: Colors.green[700]),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 24),

            // Terms and Conditions Checkbox
            CheckboxListTile(
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: <TextSpan>[
                     TextSpan(text: l10n.termsAndConditionsAgreement),
                    TextSpan(
                      text: l10n.termsAndConditionsLink,
                      style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                      ),
                     TextSpan(text: l10n.termsAndConditionsAnd),
                     TextSpan(
                      text: l10n.privacyPolicyLink,
                      style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                      // recognizer: TapGestureRecognizer()..onTap = () { /* TODO */ },
                    ),
                  ],
                ),
              ),
              value: _agreedToTerms,
              onChanged: (bool? value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitForm,
                    child:  Text(l10n.submitButton),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}