// lib/provider/auth_provider.dart
import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'dart:async'; // Import for TimeoutException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/auth_response.dart';
import 'package:mgw_tutorial/models/api_error.dart';
import 'package:mgw_tutorial/models/field_error.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  ApiError? _apiError;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  ApiError? get apiError => _apiError;

  static const String _networkErrorMessage = "Sorry, there seems to be a network error. Please check your connection and try again.";
  static const String _timeoutErrorMessage = "The request timed out. Please check your connection or try again later.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred. Please try again later.";
  static const String _defaultFailedMessage = "Operation failed. Please try again.";
  static const String _invalidCredentialsMessage = "Invalid phone number or password. Please try again.";
  static const String _defaultRegistrationFailedMessage = "Registration failed. Please check your details and try again.";
  static const String _defaultSignUpFailedMessage = "Sign up failed. Please try again.";

  static const String _apiBaseUrl = "https://usersservicefx.amtprinting19.com"; // VERIFY THIS URL IS CORRECT AND REACHABLE

  void clearError() {
    _apiError = null;
  }

  void setErrorManually(String message) {
    _apiError = ApiError(message: message);
    notifyListeners();
  }

  String normalizePhoneNumberToE164(String rawPhoneNumber) {
    String cleanedNumber = rawPhoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedNumber.startsWith('251') && cleanedNumber.length == 12) return '+$cleanedNumber';
    if (cleanedNumber.startsWith('0') && cleanedNumber.length == 10) return '+251${cleanedNumber.substring(1)}';
    if (cleanedNumber.length == 9 && !cleanedNumber.startsWith('0')) return '+251$cleanedNumber';
    if (rawPhoneNumber.startsWith('+251') && rawPhoneNumber.length == 13) return rawPhoneNumber;
    if (cleanedNumber.length == 12 && cleanedNumber.startsWith('251')) return '+$cleanedNumber';
    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) return '+251${cleanedNumber.substring(1)}';
    if (cleanedNumber.length == 9) return '+251$cleanedNumber';
    print("Warning: Could not reliably normalize phone number '$rawPhoneNumber' to E.164 strictly. Returning best guess or original.");
    return rawPhoneNumber;
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
    required String deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();
    final String normalizedPhoneNumber = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/auth/login'); // Ensure this URL is correct
    final loginPayload = User(
      firstName: '',
      lastName: '',
      phone: normalizedPhoneNumber,
      password: password,
      device: deviceInfo,
    );
    try {
      final body = json.encode(loginPayload.toJsonForLogin());
      print("Login Request URL: $url");
      print("Login Request Body: $body");
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body)
                                .timeout(const Duration(seconds: 15)); // Reduced timeout for testing
      print("Login API Response Status: ${response.statusCode}");
      print("Login API Response Body: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _invalidCredentialsMessage, isLogin: true);
        return false;
      }
    } on TimeoutException catch (e) { // Catch TimeoutException specifically
      print("Login TimeoutException: $e");
      _handleCatchError(e, 'Login failed due to timeout.'); // Pass more context
      return false;
    } on SocketException catch (e) { // Catch SocketException specifically
       print("Login SocketException: $e");
      _handleCatchError(e, 'Login failed due to network issue.');
      return false;
    } on http.ClientException catch (e) { // Catch other HTTP client errors
      print("Login ClientException: $e");
      _handleCatchError(e, 'Login failed due to client-side HTTP issue.');
      return false;
    }
    catch (error) { // Catch any other errors
      print("Login Generic Catch: $error");
      _handleCatchError(error, 'Login failed unexpectedly.');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiError = null;
    notifyListeners();
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
    final String normalizedPhone = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/users');
    final userPayload = User(
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      phone: normalizedPhone,
      password: password,
      device: deviceInfo,
    );
    try {
      final body = json.encode(userPayload.toJsonForSimpleSignUp());
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body)
                                .timeout(const Duration(seconds: 20));
      print("SignUpSimple API Response Status: ${response.statusCode}");
      print("SignUpSimple API Response Body: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('user') && responseData.containsKey('token')) {
            final authResponse = AuthResponse.fromJson(responseData);
            _currentUser = authResponse.user;
            _token = authResponse.token;
        } else if (responseData.containsKey('id') && responseData.containsKey('phone')) {
            _currentUser = User.fromJson(responseData);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _defaultSignUpFailedMessage);
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Sign up failed due to timeout.');
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Sign up failed due to network issue.');
      return false;
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Sign up failed due to client-side HTTP issue.');
      return false;
    }
    catch (error) {
      _handleCatchError(error, 'Sign up failed unexpectedly.');
      return false;
    }
  }

  Future<bool> registerUserFull({
    required User registrationData,
    XFile? screenshotFile,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();
    final String normalizedPhoneForRegistration = normalizePhoneNumberToE164(registrationData.phone);
    final User updatedRegistrationData = User(
      id: registrationData.id,
      firstName: registrationData.firstName,
      lastName: registrationData.lastName,
      phone: normalizedPhoneForRegistration,
      password: registrationData.password,
      allCourses: registrationData.allCourses,
      grade: registrationData.grade,
      category: registrationData.category,
      school: registrationData.school,
      gender: registrationData.gender,
      region: registrationData.region,
      status: registrationData.status,
      enrolledAll: registrationData.enrolledAll,
      device: registrationData.device,
      serviceType: registrationData.serviceType,
    );
    final url = Uri.parse('$_apiBaseUrl/api/users');
    try {
      final body = json.encode(updatedRegistrationData.toJsonForFullRegistration());
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body)
                                .timeout(const Duration(seconds: 30));
      print("RegisterUserFull API Response Status: ${response.statusCode}");
      print("RegisterUserFull API Response Body: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _defaultRegistrationFailedMessage);
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Registration failed due to timeout.');
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Registration failed due to network issue.');
      return false;
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Registration failed due to client-side HTTP issue.');
      return false;
    }
    catch (error) {
      _handleCatchError(error, 'Registration failed unexpectedly.');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null || _currentUser == null) {
      return {'success': false, 'message': 'User not authenticated. Please log in again.'};
    }
    _isLoading = true;
    _apiError = null;
    notifyListeners();
    final url = Uri.parse('$_apiBaseUrl/api/auth/change-password');
    try {
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 20));
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyListeners();
        return {'success': true, 'message': 'Password changed successfully.'};
      } else {
        _handleErrorResponse(response, 'Failed to change password. Please ensure current password is correct.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
       _handleCatchError(e, 'Failed to change password due to timeout.');
       _isLoading = false; notifyListeners();
       return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to change password due to network issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to change password due to client-side HTTP issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to change password unexpectedly.');
       _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> requestPhoneChangeOTP({
    required String newRawPhoneNumber,
  }) async {
    if (_token == null || _currentUser == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }
    _isLoading = true;
    _apiError = null;
    notifyListeners();
    final normalizedNewPhone = normalizePhoneNumberToE164(newRawPhoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/auth/request-phone-change-otp');
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: json.encode({'newPhoneNumber': normalizedNewPhone}),
      ).timeout(const Duration(seconds: 20));
      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return {'success': true, 'message': 'OTP sent to $normalizedNewPhone.'};
      } else {
        _handleErrorResponse(response, 'Failed to request OTP. Please try again.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to timeout.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to network issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to client-side HTTP issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to request OTP unexpectedly.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> verifyOtpAndChangePhone({
    required String newRawPhoneNumber,
    required String otp,
  }) async {
    if (_token == null || _currentUser == null) {
      return {'success': false, 'message': 'User not authenticated.'};
    }
    _isLoading = true;
    _apiError = null;
    notifyListeners();
    final normalizedNewPhone = normalizePhoneNumberToE164(newRawPhoneNumber);
    final userId = _currentUser!.id;
    if (userId == null) {
        _isLoading = false;
        _apiError = ApiError(message: 'User ID not found.');
        notifyListeners();
        return {'success': false, 'message': _apiError!.message};
    }
    final url = Uri.parse('$_apiBaseUrl/api/users/update/$userId');
    Map<String, dynamic> updatePayload = {
        'phone': normalizedNewPhone,
        'first_name': _currentUser!.firstName,
        'last_name': _currentUser!.lastName,
    };
    try {
      final response = await http.put(
        url,
        headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $_token",
        },
        body: json.encode(updatePayload),
      ).timeout(const Duration(seconds: 20));
      _isLoading = false;
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _currentUser = User.fromJson(responseData);
        notifyListeners();
        return {'success': true, 'message': 'Phone number updated successfully.'};
      } else {
        _handleErrorResponse(response, 'Failed to update phone number. Please check OTP and try again.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to timeout.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to network issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to client-side HTTP issue.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to update phone number unexpectedly.');
      _isLoading = false; notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  void _handleErrorResponse(http.Response response, String defaultUserMessage, {bool isLogin = false}) {
    String errorMessageToShow;
    List<FieldError>? fieldErrorsFromApi;

    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map) {
        if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['message'].toString();
           if (isLogin && (errorMessageToShow.toLowerCase().contains("user not found") || errorMessageToShow.toLowerCase().contains("invalid credentials") || errorMessageToShow.toLowerCase().contains("password does not match"))) {
             errorMessageToShow = _invalidCredentialsMessage;
           }

           if (errorBody.containsKey('errors') && errorBody['errors'] is List && (errorBody['errors'] as List).isNotEmpty) {
             fieldErrorsFromApi = (errorBody['errors'] as List).map((e) {
               if (e is Map<String, dynamic>) {
                 return FieldError.fromJson(e);
               }
               return FieldError(field: 'unknown', message: e.toString());
             }).toList();
             final fieldErrorMessages = fieldErrorsFromApi.map((fe) => "${fe.field}: ${fe.message}").join(', ');
             if (errorMessageToShow != _invalidCredentialsMessage && errorMessageToShow != defaultUserMessage) {
                errorMessageToShow += " ($fieldErrorMessages)";
             }
           }
        } else if (errorBody.containsKey('errorMessage') && errorBody['errorMessage'] != null && errorBody['errorMessage'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['errorMessage'].toString();
            if (isLogin && (errorMessageToShow.toLowerCase().contains("user not found") || errorMessageToShow.toLowerCase().contains("invalid credentials") || errorMessageToShow.toLowerCase().contains("password does not match"))) {
             errorMessageToShow = _invalidCredentialsMessage;
           }
        } else {
          if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
            errorMessageToShow = _invalidCredentialsMessage;
          } else {
            errorMessageToShow = "$defaultUserMessage (Status: ${response.statusCode})";
          }
        }
      } else {
         if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
            errorMessageToShow = _invalidCredentialsMessage;
          } else {
            errorMessageToShow = "$defaultUserMessage (Status: ${response.statusCode})";
          }
      }
      _apiError = ApiError(message: errorMessageToShow, errors: fieldErrorsFromApi);
    } catch (e) {
      if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
         _apiError = ApiError(message: _invalidCredentialsMessage);
      } else {
        _apiError = ApiError(message: '$defaultUserMessage (Status: ${response.statusCode}). Response not parsable.');
      }
    }
    _isLoading = false;
    // No notifyListeners() here, let the calling method decide when to notify.
  }

  void _handleCatchError(dynamic error, String uiContextMessage) {
    // uiContextMessage is for logging purposes, not directly shown to user usually.
    print('AuthProvider Exception during "$uiContextMessage": ${error.toString()}');
    if (error is SocketException || error is http.ClientException) {
      _apiError = ApiError(message: _networkErrorMessage);
    } else if (error is TimeoutException) {
       _apiError = ApiError(message: _timeoutErrorMessage); // Specific message for timeout
    }
    else {
      // For any other unknown error during the HTTP call process
      _apiError = ApiError(message: _unexpectedErrorMessage);
    }
    _isLoading = false;
    // No notifyListeners() here, let the calling method decide.
  }
}