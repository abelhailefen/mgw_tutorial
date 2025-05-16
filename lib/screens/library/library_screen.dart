import 'package:flutter/material.dart';

import 'package:mgw_tutorial/screens/library/library_content_view.dart';
import 'package:mgw_tutorial/screens/library/registration_denied_view.dart';
import 'package:mgw_tutorial/screens/library/registration_form_view.dart';
import 'package:mgw_tutorial/screens/library/registration_pending_view.dart';
import 'package:mgw_tutorial/screens/library/not_registered_view.dart';
import 'package:mgw_tutorial/screens/registration/registration_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum LibraryState {
  notRegistered,
  registrationForm,
  underVerification,
  requestDenied,
  registeredAndContentVisible,
}

class LibraryScreen extends StatefulWidget {
  final LibraryState initialState;

  const LibraryScreen({
    Key? key,
    this.initialState = LibraryState.notRegistered,
  }) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryState _currentLibraryState;

  @override
  void initState() {
    super.initState();
    _currentLibraryState = widget.initialState;
  }

  void _changeLibraryState(LibraryState newState) {
    if (mounted) {
      setState(() {
        _currentLibraryState = newState;
      });
    }
  }

  void _navigateToRegistrationForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
    );
  }

  void _submitRegistrationForm() {
    _changeLibraryState(LibraryState.underVerification);

    Future.delayed(const Duration(seconds: 3), () {
      _changeLibraryState(LibraryState.registeredAndContentVisible);
      // Or use below to simulate denial:
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
          onSuccessfulRegistration: _submitRegistrationForm,
        );
        break;
      case LibraryState.underVerification:
        currentView = const RegistrationPendingView();
        break;
      case LibraryState.requestDenied:
        currentView = RegistrationDeniedView(
          onRegisterNow: _navigateToRegistrationForm,
        );
        break;
      case LibraryState.registeredAndContentVisible:
        currentView = const LibraryContentView();
        break;
      default:
        currentView = const Center(child: Text('Error: Unknown library state'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: currentView,
    );
  }
}
