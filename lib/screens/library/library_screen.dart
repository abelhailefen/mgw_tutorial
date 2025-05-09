import 'package:flutter/material.dart';

import 'package:mgw_tutorial/widgets/library/library_content_view.dart';
import 'package:mgw_tutorial/widgets/library/registration_denied_view.dart';
import 'package:mgw_tutorial/widgets/library/registration_form_view.dart';
import 'package:mgw_tutorial/widgets/library/registration_pending_view.dart';
import 'package:mgw_tutorial/screens/library/not_registered_view.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum LibraryState {
  notRegistered,
  registrationForm,
  underVerification,
  requestDenied,
  registeredAndContentVisible,
}


class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  // Default state is notRegistered
  LibraryState _currentLibraryState = LibraryState.notRegistered;

  void _changeLibraryState(LibraryState newState) {
    // Ensure the widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _currentLibraryState = newState;
      });
    }
  }

  void _navigateToRegistrationForm() {
    _changeLibraryState(LibraryState.registrationForm);
  }

  void _submitRegistrationForm() {
    // 1. Immediately change state to show "Under Verification"
    _changeLibraryState(LibraryState.underVerification);

    // 2. Simulate an API call or processing delay
    Future.delayed(const Duration(seconds: 3), () {
      // After the delaydecide the outcome.
      
      // to simulate a successful registration 
      _changeLibraryState(LibraryState.registeredAndContentVisible);

      // Or simulate denial:
     // _changeLibraryState(LibraryState.requestDenied);

    });
  }


  @override
  Widget build(BuildContext context) {
    Widget currentView;

    switch (_currentLibraryState) {
      case LibraryState.notRegistered:
        currentView = NotRegisteredView(
          onRegisterNow: _navigateToRegistrationForm,
        );
        break;
       case LibraryState.registrationForm:
        currentView = RegistrationFormView( 
          onSubmit: _submitRegistrationForm, 
        );
        break; 
      case LibraryState.underVerification:
        currentView = const RegistrationPendingView();
        break;
      case LibraryState.requestDenied:
        currentView = RegistrationDeniedView(
          onRegisterNow: _navigateToRegistrationForm, // Allow re-registration
        );
        break;
      case LibraryState.registeredAndContentVisible:
        currentView = const LibraryContentView();
        break;
      default: // Should not happen with a well-defined enum
        currentView = const Center(child: Text('Error: Unknown library state'));
    }

    // As per previous discussion, LibraryScreen only returns its body content.
    // The Scaffold and AppBar are in MainScreen.
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: currentView, // UNCOMMENTED
    );
  }
}