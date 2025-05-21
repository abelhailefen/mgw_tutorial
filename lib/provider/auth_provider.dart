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
import 'package:mgw_tutorial/models/field_error.dart'; // Import FieldError model

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
  static const String _unexpectedErrorMessage = "An unexpected error occurred. Please try again later.";
  static const String _defaultFailedMessage = "Operation failed. Please try again.";

  static const String _apiBaseUrl = "https://usersservicefx.amtprinting19.com";

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
    final url = Uri.parse('$_apiBaseUrl/api/auth/login');
    final loginPayload = User(
      firstName: '', lastName: '', phone: normalizedPhoneNumber,
      password: password, device: deviceInfo,
    );
    try {
      final body = json.encode(loginPayload.toJsonForLogin());
      final response = await http.post(url, headers: {"Content-Type": "application/json", "Accept": "application/json"}, body: body)
                                .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, 'Login failed.');
        return false;
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Login request timed out."), 'Login failed.');
      return false;
    } catch (error) {
      _handleCatchError(error, 'Login failed.');
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
        _handleErrorResponse(response, 'Sign up failed.');
        return false;
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Sign up request timed out."), 'Sign up failed.');
      return false;
    } catch (error) {
      _handleCatchError(error, 'Sign up failed.');
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, 'Registration failed.');
        return false;
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Registration request timed out."), 'Registration failed.');
      return false;
    } catch (error) {
      _handleCatchError(error, 'Registration failed.');
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
    print("Changing password at: $url");

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
      print("Change password response: ${response.statusCode}, Body: ${response.body}");

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyListeners();
        return {'success': true, 'message': 'Password changed successfully.'};
      } else {
        _handleErrorResponse(response, 'Failed to change password.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Change password request timed out."), 'Failed to change password.');
       _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Failed to change password.');
       _isLoading = false;
      notifyListeners();
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
    print("Requesting OTP for phone change to $normalizedNewPhone at: $url");

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
      print("Request OTP response: ${response.statusCode}");

      _isLoading = false;
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners();
        return {'success': true, 'message': 'OTP sent to $normalizedNewPhone.'};
      } else {
        _handleErrorResponse(response, 'Failed to request OTP for phone change.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Request OTP timed out."), 'Failed to request OTP for phone change.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Failed to request OTP for phone change.');
      _isLoading = false;
      notifyListeners();
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
    print("Updating phone for user $userId to $normalizedNewPhone at: $url after OTP (OTP: $otp)");

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
      print("Update user (phone) response: ${response.statusCode}, Body: ${response.body}");

      _isLoading = false;
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _currentUser = User.fromJson(responseData);
        notifyListeners();
        return {'success': true, 'message': 'Phone number updated successfully.'};
      } else {
        _handleErrorResponse(response, 'Failed to update phone number.');
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (_) {
      _handleCatchError(TimeoutException("Update phone request timed out."), 'Failed to update phone number.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Failed to update phone number.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  void _handleErrorResponse(http.Response response, String defaultMessagePrefix) {
    String errorMessageToShow;
    List<FieldError>? fieldErrorsFromApi; // Declare here to use in ApiError

    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map) {
        if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['message'].toString();
           if (errorBody.containsKey('errors') && errorBody['errors'] is List && (errorBody['errors'] as List).isNotEmpty) {
             // Parse FieldErrors
             fieldErrorsFromApi = (errorBody['errors'] as List).map((e) {
               if (e is Map<String, dynamic>) { // Ensure 'e' is Map<String, dynamic>
                 return FieldError.fromJson(e);
               }
               // Fallback for unexpected error format in the list
               return FieldError(field: 'unknown', message: e.toString());
             }).toList();

             // Append field errors to the main message for simplicity here
             // Or handle them separately in the UI if needed
             final fieldErrorMessages = fieldErrorsFromApi.map((fe) => "${fe.field}: ${fe.message}").join(', ');
             errorMessageToShow += " ($fieldErrorMessages)";
           }
        } else if (errorBody.containsKey('errorMessage') && errorBody['errorMessage'] != null && errorBody['errorMessage'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['errorMessage'].toString();
        } else if (response.body.isNotEmpty && response.body.length < 200) {
            errorMessageToShow = response.body;
        } else {
            errorMessageToShow = "$defaultMessagePrefix Status: ${response.statusCode}.";
        }
      } else if (response.body.isNotEmpty && response.body.length < 200) {
         errorMessageToShow = response.body;
      } else {
         errorMessageToShow = "$defaultMessagePrefix Status: ${response.statusCode}.";
      }
      _apiError = ApiError(message: errorMessageToShow, errors: fieldErrorsFromApi); // Pass parsed field errors
    } catch (e) {
      _apiError = ApiError(message: '$defaultMessagePrefix Status: ${response.statusCode}. Could not parse error: ${response.body}');
    }
    _isLoading = false;
    notifyListeners();
  }

  void _handleCatchError(dynamic error, String uiContextMessage) {
    print('AuthProvider Exception during "$uiContextMessage": ${error.toString()}');
    if (error is SocketException || error is http.ClientException) { // Removed TimeoutException here as it's caught separately
      _apiError = ApiError(message: _networkErrorMessage);
    } else if (error is TimeoutException) { // Specific handling for TimeoutException
       _apiError = ApiError(message: "$uiContextMessage: Request timed out. $_networkErrorMessage");
    }
    else {
      _apiError = ApiError(message: "$uiContextMessage: $_unexpectedErrorMessage");
    }
    _isLoading = false;
    notifyListeners();
  }
}