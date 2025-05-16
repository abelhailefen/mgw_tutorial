// lib/provider/auth_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/auth_response.dart';
import 'package:mgw_tutorial/models/api_error.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  ApiError? _apiError;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  ApiError? get apiError => _apiError;

  static const String _apiBaseUrl = "https://usersservicefx.amtprinting19.com";

  void clearError() {
    _apiError = null;
  }

  void setErrorManually(String message) {
    _apiError = ApiError(message: message);
    notifyListeners();
  }

  // --- Phone Number Normalization Helper (can be static or instance method) ---
  String normalizePhoneNumberToE164(String rawPhoneNumber) {
    String cleanedNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), ''); // Remove non-digits

    if (cleanedNumber.startsWith('251') && cleanedNumber.length == 12) { // Already 2519...
      return '+$cleanedNumber';
    } else if (cleanedNumber.startsWith('0') && cleanedNumber.length == 10) { // 09...
      return '+251${cleanedNumber.substring(1)}'; // Convert 09... to +2519...
    } else if (cleanedNumber.length == 9 && !cleanedNumber.startsWith('0')) { // 9...
      return '+251$cleanedNumber'; // Convert 9... to +2519...
    }
    // If it's already in +251 format and valid length, or if it's an unknown format, return as is or handle error
    // For simplicity, if it starts with + and looks somewhat valid, assume it's okay.
    // More robust validation might be needed for edge cases.
    if (rawPhoneNumber.startsWith('+251') && rawPhoneNumber.length == 13) {
        return rawPhoneNumber;
    }
    // Fallback or error for unrecognized formats if strictness is required.
    // For now, if it doesn't match known patterns to convert, we'll send it as received from LoginScreen,
    // but LoginScreen should ideally send something parseable.
    // Or, more strictly, throw an error if format is not convertible.
    print("Warning: Could not normalize phone number '$rawPhoneNumber' to E.164 strictly. Sending as is or potentially modified.");
    if (cleanedNumber.length >= 9) { // Attempt a best guess if just digits remain
        if (cleanedNumber.length == 12 && cleanedNumber.startsWith('251')) return '+$cleanedNumber';
        if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) return '+251${cleanedNumber.substring(1)}';
        if (cleanedNumber.length == 9) return '+251$cleanedNumber';
    }
    return rawPhoneNumber; // Fallback to original if no clear rule applies (less ideal)
  }


  Future<bool> signUpSimple({
    required String phoneNumber,
    required String password,
    String? firstName,
    String? lastName,
    String? languageCode,
    String? deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final String normalizedPhone = normalizePhoneNumberToE164(phoneNumber); // Normalize for signup too

    final url = Uri.parse('$_apiBaseUrl/api/users');
    final userPayload = User(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      phone: normalizedPhone, // Use normalized phone
      password: password,
      device: deviceInfo,
    );
    try {
      final body = json.encode(userPayload.toJsonForSimpleSignUp());
      print('Simple SignUp Request Body: $body');
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body);
      print('Simple SignUp Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        try {
          final authResponse = AuthResponse.fromJson(responseData);
          _currentUser = authResponse.user;
          _token = authResponse.token;
        } catch (e) {
          print("Could not parse AuthResponse from simple signup: $e. Assuming User object or custom success.");
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, 'Sign up failed.');
        return false;
      }
    } catch (error) {
      _handleCatchError(error, 'Exception during simple sign up');
      return false;
    }
  }

  Future<bool> login({
    required String phoneNumber, // This will be the raw input from LoginScreen
    required String password,
    required String deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    // Normalize the phone number to +251 format HERE
    final String normalizedPhoneNumber = normalizePhoneNumberToE164(phoneNumber);

    final url = Uri.parse('$_apiBaseUrl/api/auth/login');
    final loginPayload = User(
      firstName: '',
      lastName: '',
      phone: normalizedPhoneNumber, // Use the normalized phone number
      password: password,
      device: deviceInfo,
    );

    try {
      final body = json.encode(loginPayload.toJsonForLogin());
      print('Login Request Body: $body'); // This will now show phone in +251... format
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body);
      print('Login Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("[AuthProvider] Raw Login Response JSON for AuthResponse: $responseData");
        final authResponse = AuthResponse.fromJson(responseData);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        print("[AuthProvider] Login Success: User ID - ${_currentUser?.id}, User Name - ${_currentUser?.firstName}. Token received: '${_token}'. Token is null or empty: ${_token == null || _token!.isEmpty}");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, 'Login failed.');
        return false;
      }
    } catch (error) {
      _handleCatchError(error, 'Exception during login');
      return false;
    }
  }

  Future<bool> registerUserFull({
    required User registrationData, // registrationData.phone should already be normalized in RegistrationScreen
    XFile? screenshotFile,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    // Assuming registrationData.phone is ALREADY in +251 format from RegistrationScreen's logic
    // If not, you could normalize it here too:
    // final String normalizedPhoneForRegistration = normalizePhoneNumberToE164(registrationData.phone);
    // final User updatedRegistrationData = registrationData.copyWith(phone: normalizedPhoneForRegistration); // Assuming a copyWith method

    final url = Uri.parse('$_apiBaseUrl/api/users');
    if (screenshotFile != null) {
      print('Screenshot was picked: ${screenshotFile.name}, but it will NOT be uploaded in this JSON request version.');
    }
    try {
      // Use registrationData directly if its phone is already normalized
      final body = json.encode(registrationData.toJsonForFullRegistration());
      print('Sending JSON registration data: $body'); // This will show the phone format being sent
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body);
      print('Full Registration Response (JSON): ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, 'Registration failed.');
        return false;
      }
    } catch (error) {
      _handleCatchError(error, 'Exception during full registration');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiError = null;
    notifyListeners();
  }

  void _handleErrorResponse(http.Response response, String defaultMessagePrefix) {
    // ... (error handling logic - no change needed here for phone normalization)
    String errorMessageToShow = '$defaultMessagePrefix. Status: ${response.statusCode}';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map) {
        if (errorBody.containsKey('message') && errorBody['message'] != null) {
           errorMessageToShow = errorBody['message'];
           if (errorBody.containsKey('code') && errorBody['code'] != null) {
             errorMessageToShow += ' (Code: ${errorBody['code']})';
           }
        } else if (errorBody.containsKey('errorMessage') && errorBody['errorMessage'] != null) {
           errorMessageToShow = errorBody['errorMessage'];
        } else if (response.body.isNotEmpty) {
            errorMessageToShow = '$defaultMessagePrefix: ${response.body}';
        }
      } else if (response.body.isNotEmpty) {
         errorMessageToShow = '$defaultMessagePrefix: ${response.body}';
      }
      _apiError = ApiError(message: errorMessageToShow);
    } catch (e) {
      _apiError = ApiError(message: '$defaultMessagePrefix. Status: ${response.statusCode}. Could not parse error response: ${response.body}');
    }
    _isLoading = false;
    notifyListeners();
  }

  void _handleCatchError(dynamic error, String messagePrefix) {
    // ... (error handling logic - no change needed here for phone normalization)
    print('$messagePrefix: ${error.toString()}');
    _apiError = ApiError(message: '$messagePrefix: An unexpected error occurred. Please try again.');
    _isLoading = false;
    notifyListeners();
  }
}