import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/main_screen.dart'; // For navigation
import 'package:provider/provider.dart';               // For LocaleProvider
import 'package:mgw_tutorial/provider/locale_provider.dart'; // Your LocaleProvider
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Generated localizations

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

 
  final List<String> _languageCodes = ['en', 'am', 'om'];
 
  bool _isPasswordVisible = false;
  bool _isLoading = false;

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

  Future<void> _createAccount() async {
    final l10n = AppLocalizations.of(context)!; // Get l10n for messages
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      print('Phone: +251${_phoneController.text}');
      print('Password: ${_passwordController.text}');
      print('Language from Provider: ${localeProvider.locale?.languageCode ?? 'en'}'); // Example
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountCreationSimulatedMessage)),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!; // Get l10n instance
    final localeProvider = Provider.of<LocaleProvider>(context); // listen: true to rebuild on locale change

    // Map language codes to display names
    final Map<String, String> languageDisplayNames = {
      'en': l10n.english,
      'am': l10n.amharic,
      'om': l10n.afaanOromo, 
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: _buildLanguageDropdown(theme, l10n, localeProvider, languageDisplayNames),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.mgwTutorialTitle, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signUpToStartLearning, 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          l10n.signUpTitle, 
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: l10n.phoneNumberLabel, 
                            hintText: l10n.phoneNumberHint,  
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                              child: Text(
                                '+251 ',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.phoneNumberValidationErrorRequired; 
                            }
                            if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
                              return l10n.phoneNumberValidationErrorInvalid; 
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: l10n.passwordLabel, 
                            hintText: l10n.passwordHint,  
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: _togglePasswordVisibility,
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.passwordValidationErrorRequired; 
                            }
                            if (value.length < 6) {
                              return l10n.passwordValidationErrorLength; 
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _createAccount,
                                child: Text(l10n.createAccountButton), 
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    l10n.alreadyHaveAccount, 
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainScreen()),
                      );
                    },
                    child: Text(
                      l10n.signInLink, // Localized
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50,30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft
                      )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(ThemeData theme, AppLocalizations l10n, LocaleProvider localeProvider, Map<String, String> languageDisplayNames) {

    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_languageCodes.contains(currentLanguageCode)) {
        currentLanguageCode = 'en';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguageCode, // Use the language code from provider
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
          elevation: 2,
          style: TextStyle(color: Colors.blue[700], fontSize: 14),
          onChanged: (String? newLanguageCode) {
            if (newLanguageCode != null) {
              localeProvider.setLocale(Locale(newLanguageCode));
            }
          },
          items: _languageCodes.map<DropdownMenuItem<String>>((String langCode) {
            return DropdownMenuItem<String>(
              value: langCode,
              child: Text(languageDisplayNames[langCode] ?? langCode.toUpperCase()), // Display localized name
            );
          }).toList(),
        ),
      ),
    );
  }
}