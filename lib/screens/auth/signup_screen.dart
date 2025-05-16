// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/locale_provider.dart';
import 'package:mgw_tutorial/provider/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Widgets from lib/widgets/auth/ (or wherever they are)
import 'package:mgw_tutorial/widgets/auth/auth_screen_header.dart';
import 'package:mgw_tutorial/widgets/auth/auth_card_wrapper.dart';
import 'package:mgw_tutorial/widgets/auth/auth_form_title.dart';
import 'package:mgw_tutorial/widgets/auth/auth_navigation_link.dart';

// Widgets moved to lib/widgets/
import 'package:mgw_tutorial/widgets/phone_form_field.dart';
import 'package:mgw_tutorial/widgets/password_form_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> _supportedLanguageCodes = ['en', 'am', 'om'];
  bool _isPasswordVisible = false;

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

  Future<void> _handleSignUp() async {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    authProvider.clearError();

    if (_formKey.currentState!.validate()) {
      final String phoneNumber = _phoneController.text.trim();
      final String password = _passwordController.text;
      final String languageCode = localeProvider.locale?.languageCode ?? 'en';

      bool success = await authProvider.signUpSimple(
        phoneNumber: '+251$phoneNumber',
        password: password,
        languageCode: languageCode,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.signUpSuccessMessage)),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.apiError?.message ?? l10n.signUpFailedErrorGeneral),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context); // For language dropdown

    // Prepare for language dropdown
    final Map<String, String> languageDisplayNames = {
      'en': l10n.english,
      'am': l10n.amharic,
      'om': l10n.afaanOromo,
    };
    String currentLanguageCode = localeProvider.locale?.languageCode ?? 'en';
    if (!_supportedLanguageCodes.contains(currentLanguageCode)) {
      currentLanguageCode = _supportedLanguageCodes.first;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                // Using Flutter's built-in DropdownButtonFormField for simplicity here
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLanguageCode,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                      elevation: 2,
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      onChanged: (String? newLanguageCode) {
                        if (newLanguageCode != null) {
                          localeProvider.setLocale(Locale(newLanguageCode));
                        }
                      },
                      items: _supportedLanguageCodes
                          .map<DropdownMenuItem<String>>((String langCode) {
                        return DropdownMenuItem<String>(
                          value: langCode,
                          child: Text(languageDisplayNames[langCode] ?? langCode.toUpperCase()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AuthScreenHeader(
                title: l10n.mgwTutorialTitle,
                subtitle: l10n.signUpToStartLearning,
              ),
              const SizedBox(height: 40),
              AuthCardWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AuthFormTitle(title: l10n.signUpTitle),
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
                      authProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _handleSignUp,
                              child: Text(l10n.createAccountButton),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthNavigationLink(
                leadingText: l10n.alreadyHaveAccount,
                linkText: l10n.signInLink,
                onLinkPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}