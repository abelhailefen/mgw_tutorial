import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
  String? get errorMessage => _apiError?.message;
  List<FieldError>? get errorFields => _apiError?.errors;

  static const String _networkErrorMessage = "Sorry, there seems to be a network error.";
  static const String _timeoutErrorMessage = "The request timed out.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _defaultFailedMessage = "Operation failed. Try again.";
  static const String _invalidCredentialsMessage = "Invalid phone number or password.";
  static const String _defaultRegistrationFailedMessage = "Registration failed. Please check your details and try again.";
  static const String _defaultSignUpFailedMessage = "Sign up failed.";
  static const String _sessionInvalidMessage = "Session expired. Please log in again.";
  static const String _notAuthenticatedMessage = "Not authenticated. Please log in.";

  static const String _apiBaseUrl = "https://usersservicefx.amtprinting19.com";

  void clearError() {
    _apiError = null;
    notifyListeners();
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
    print("Warning: Could not normalize phone number '$rawPhoneNumber' to E.164. Returning: $cleanedNumber");
    return cleanedNumber;
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
    required String deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final normalizedPhoneNumber = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/auth/login');
    final loginPayload = User(
      firstName: '',
      lastName: '',
      phone: normalizedPhoneNumber,
      password: password,
      device: deviceInfo,
    );

    try {
      final body = json.encode(loginPayload.toJsonForLogin());
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);
        _currentUser = authResponse.user;
        _token = authResponse.token;
        print("Login successful: User ID=${_currentUser?.id}, Token=${_token?.substring(0, 10)}...");
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _invalidCredentialsMessage, isLogin: true);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Login timed out.');
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Login failed: network error.');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _handleCatchError(error, 'Login failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiError = null;
    print("Logged out: User and token cleared.");
    _isLoading = false;
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

    final normalizedPhone = normalizePhoneNumberToE164(phoneNumber);
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
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data.containsKey('user') && data.containsKey('token')) {
          final authResponse = AuthResponse.fromJson(data);
          _currentUser = authResponse.user;
          _token = authResponse.token;
          print("Sign up successful: User ID=${_currentUser?.id}, Token=${_token?.substring(0, 10)}...");
        } else {
          _currentUser = User.fromJson(data);
          _token = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _defaultSignUpFailedMessage);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Sign up timed out.');
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Sign up failed: network error.');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _handleCatchError(error, 'Sign up failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerUserFull({
    required User registrationData,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final normalizedPhone = normalizePhoneNumberToE164(registrationData.phone);
    final userPayload = User(
      firstName: registrationData.firstName,
      lastName: registrationData.lastName,
      phone: normalizedPhone,
      password: registrationData.password,
      device: registrationData.device,
      allCourses: registrationData.allCourses,
      grade: registrationData.grade,
      category: registrationData.category,
      school: registrationData.school,
      gender: registrationData.gender,
      region: registrationData.region,
      status: registrationData.status,
      enrolledAll: registrationData.enrolledAll,
      serviceType: registrationData.serviceType,
    );

    final url = Uri.parse('$_apiBaseUrl/api/users');
    try {
      final body = json.encode(userPayload.toJsonForFullRegistration());
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _handleErrorResponse(response, _defaultRegistrationFailedMessage);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Registration timed out.');
      _isLoading = false;
      notifyListeners();
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Registration failed: network error.');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (error) {
      _handleCatchError(error, 'Registration failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> changeName({
    required String firstName,
    required String lastName,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) {
      _apiError = ApiError(message: _notAuthenticatedMessage);
      print("Change name failed: User=${_currentUser}, User ID=${_currentUser?.id}");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');
    final previousUser = _currentUser;

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Id': _currentUser!.id!.toString(),
            },
            body: json.encode({
              'first_name': firstName,
              'last_name': lastName,
              'phone': _currentUser!.phone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("Change name response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        // Update user locally to reflect changes
        _currentUser = User(
          id: _currentUser!.id,
          firstName: firstName,
          lastName: lastName,
          phone: _currentUser!.phone,
          device: _currentUser!.device,
          allCourses: _currentUser!.allCourses,
          grade: _currentUser!.grade,
          category: _currentUser!.category,
          school: _currentUser!.school,
          gender: _currentUser!.gender,
          region: _currentUser!.region,
          status: _currentUser!.status,
          enrolledAll: _currentUser!.enrolledAll,
          serviceType: _currentUser!.serviceType,
        );
        // Skip session validation if no token
        bool sessionValid = true;
        if (_token != null) {
          sessionValid = await _validateSession();
        }
        _isLoading = false;
        notifyListeners();
        if (!sessionValid) {
          return {
            'success': true,
            'message': 'Name updated, but session may have expired. Please log in again if issues occur.'
          };
        }
        return {'success': true, 'message': 'Name updated successfully.'};
      } else {
        _currentUser = previousUser;
        _handleErrorResponse(response, 'Failed to update name.');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Name update timed out.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Name update failed: network error.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Name update failed unexpectedly.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) {
      _apiError = ApiError(message: _notAuthenticatedMessage);
      print("Change password failed: User=${_currentUser}, User ID=${_currentUser?.id}");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');
    final previousUser = _currentUser;

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Id': _currentUser!.id!.toString(),
            },
            body: json.encode({
              'current_password': currentPassword,
              'password': newPassword,
              'first_name': _currentUser!.firstName,
              'last_name': _currentUser!.lastName,
              'phone': _currentUser!.phone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("Change password response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final reLoginSuccess = await _reLogin(
          phoneNumber: _currentUser!.phone,
          password: newPassword,
        );
        _isLoading = false;
        notifyListeners();
        if (!reLoginSuccess) {
          _currentUser = previousUser;
          return {
            'success': true,
            'message': 'Password changed, but session refresh failed. Please log in again.'
          };
        }
        return {'success': true, 'message': 'Password changed successfully.'};
      } else {
        _currentUser = previousUser;
        _handleErrorResponse(response, 'Failed to change password.');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Password change timed out.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Password change failed: network error.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Password change failed unexpectedly.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> changePhoneNumber({
    required String newRawPhoneNumber,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) {
      _apiError = ApiError(message: _notAuthenticatedMessage);
      print("Change phone failed: User=${_currentUser}, User ID=${_currentUser?.id}");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final normalizedNewPhone = normalizePhoneNumberToE164(newRawPhoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');
    final previousUser = _currentUser;

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Id': _currentUser!.id!.toString(),
            },
            body: json.encode({
              'phone': normalizedNewPhone,
              'first_name': _currentUser!.firstName,
              'last_name': _currentUser!.lastName,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print("Change phone response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        // Update user locally to reflect changes
        _currentUser = User(
          id: _currentUser!.id,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          phone: normalizedNewPhone,
          device: _currentUser!.device,
          allCourses: _currentUser!.allCourses,
          grade: _currentUser!.grade,
          category: _currentUser!.category,
          school: _currentUser!.school,
          gender: _currentUser!.gender,
          region: _currentUser!.region,
          status: _currentUser!.status,
          enrolledAll: _currentUser!.enrolledAll,
          serviceType: _currentUser!.serviceType,
        );
        // Skip session validation if no token
        bool sessionValid = true;
        if (_token != null) {
          sessionValid = await _validateSession();
        }
        _isLoading = false;
        notifyListeners();
        if (!sessionValid) {
          return {
            'success': true,
            'message': 'Phone number updated, but session may have expired. Please log in again if issues occur.'
          };
        }
        return {'success': true, 'message': 'Phone number updated successfully.'};
      } else {
        _currentUser = previousUser;
        _handleErrorResponse(response, 'Failed to update phone number.');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Phone update timed out.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Phone update failed: network error.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Phone update failed unexpectedly.');
      _currentUser = previousUser;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<bool> _reLogin({
    required String phoneNumber,
    required String? password,
  }) async {
    if (_currentUser == null || password == null) {
      print("Re-login failed: Missing user or password.");
      _apiError = ApiError(message: _sessionInvalidMessage);
      return false;
    }

    try {
      final deviceInfo = _currentUser!.device ?? 'unknown_device';
      final loginSuccess = await login(
        phoneNumber: phoneNumber,
        password: password,
        deviceInfo: deviceInfo,
      );
      if (!loginSuccess) {
        print("Re-login failed: Invalid credentials.");
        _apiError = ApiError(message: _sessionInvalidMessage);
        return false;
      }
      print("Re-login successful: User ID=${_currentUser?.id}, Token=${_token?.substring(0, 10)}...");
      return true;
    } catch (e) {
      print("Re-login error: $e");
      _apiError = ApiError(message: _sessionInvalidMessage);
      return false;
    }
  }

  Future<bool> _validateSession() async {
    if (_currentUser == null || _currentUser!.id == null || _token == null) {
      print("Session validation skipped: User=${_currentUser}, User ID=${_currentUser?.id}, Token=${_token != null}");
      _apiError = ApiError(message: _sessionInvalidMessage);
      return false;
    }

    final url = Uri.parse('$_apiBaseUrl/api/users/me'); // Adjust if endpoint differs
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Id': _currentUser!.id!.toString(),
            },
          )
          .timeout(const Duration(seconds: 5));

      print("Session validation response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = User.fromJson(data);
        if (data.containsKey('token')) {
          _token = data['token'];
          print("Updated token: ${_token?.substring(0, 10)}...");
        }
        notifyListeners();
        return true;
      } else {
        _apiError = ApiError(message: _sessionInvalidMessage);
        return false;
      }
    } on TimeoutException catch (e) {
      print("Session validation timeout: $e");
      _apiError = ApiError(message: _sessionInvalidMessage);
      return false;
    } catch (e) {
      print("Session validation error: $e");
      _apiError = ApiError(message: _sessionInvalidMessage);
      return false;
    }
  }

  void _handleErrorResponse(http.Response response, String defaultMessage, {bool isLogin = false}) {
    String message;
    List<FieldError>? errors;

    print('Error response (${response.statusCode}): ${response.body}');

    try {
      final data = json.decode(response.body);
      message = data['message'] ?? defaultMessage;
      if (isLogin && (response.statusCode == 401 || response.statusCode == 403)) {
        message = _invalidCredentialsMessage;
      }
      if (data['errors'] is List) {
        errors = (data['errors'] as List)
            .map((e) => FieldError(field: e['field'] ?? 'unknown', message: e['message'] ?? ''))
            .toList();
      }
      _apiError = ApiError(message: message, errors: errors);
    } catch (e) {
      _apiError = ApiError(message: defaultMessage);
    }
    notifyListeners();
  }

  void _handleCatchError(dynamic error, String context) {
    print('Error in $context: $error');
    if (error is TimeoutException) {
      _apiError = ApiError(message: _timeoutErrorMessage);
    } else if (error is SocketException) {
      _apiError = ApiError(message: _networkErrorMessage);
    } else {
      _apiError = ApiError(message: _unexpectedErrorMessage);
    }
    notifyListeners();
  }
}