// lib/provider/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/user.dart';
import 'package:mgw_tutorial/models/auth_response.dart';
import 'package:mgw_tutorial/models/api_error.dart';
import 'package:mgw_tutorial/models/field_error.dart';
import 'package:mgw_tutorial/services/database_helper.dart';
import 'dart:math';


class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  ApiError? _apiError;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isInitializing = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  ApiError? get apiError => _apiError;
  String? get errorMessage => _apiError?.message;
  List<FieldError>? get errorFields => _apiError?.errors;
  bool get isInitializing => _isInitializing;

  static const String _networkErrorMessage = "Sorry, there seems to be a network error.";
  static const String _timeoutErrorMessage = "The request timed out.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _defaultFailedMessage = "Operation failed. Try again.";
  static const String _invalidCredentialsMessage = "Invalid phone number or password.";
  static const String _defaultRegistrationFailedMessage = "Registration failed. Please check your details and try again.";
  static const String _defaultSignUpFailedMessage = "Sign up failed.";
  // Removed session invalid message constant
  static const String _notAuthenticatedMessage = "Not authenticated. Please log in.";

  static const String _apiBaseUrl = "https://usersservicefx.amtprinting19.com";

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isInitializing = true;
    notifyListeners();

    print("AuthProvider Initialization Start (Offline Persistence Mode)...");
    try {
        final savedSession = await _dbHelper.getLoggedInUser();

        if (savedSession != null && savedSession['user_id'] != null) {
           print("AuthProvider: Found saved session in DB (User ID ${savedSession['user_id']}).");
           _currentUser = User(
             id: savedSession['user_id'] as int,
             firstName: savedSession['first_name'] as String? ?? '',
             lastName: savedSession['last_name'] as String? ?? '',
             phone: savedSession['phone'] as String? ?? '',
           );

           print("AuthProvider: Loaded User ID ${_currentUser!.id} from DB. Considering user logged in (Offline Mode).");

        } else {
          print("AuthProvider: No saved session found in DB or user_id is null. User is not logged in.");
           await logout(clearDb: true);
        }
    } catch (e) {
        print("AuthProvider: FATAL Error during initialization (loading from DB): $e");
         await logout(clearDb: true);
         _apiError = ApiError(message: "An error occurred while trying to restore your session from local data.");
    }


    _isInitializing = false;
    notifyListeners();
    print("AuthProvider Initialization Finished.");
  }


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

     if (cleanedNumber.length >= 9) {
        print("Warning: Could not normalize phone '$rawPhoneNumber' to E.164 using standard patterns. Trying +251 prefix on cleaned number.");
        return '+251$cleanedNumber';
     }
    print("Warning: Could not normalize phone number '$rawPhoneNumber' to E.164. Returning cleaned: $cleanedNumber");
    return cleanedNumber;
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
    required String deviceInfo,
  }) async {
     await logout(clearDb: true);

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

        print("Login successful: User ID=${_currentUser?.id}.");

        if (_currentUser != null && _currentUser!.id != null) {
            await _dbHelper.saveLoggedInUser(_currentUser!);
            print("AuthProvider: Login session successfully saved to database (User ID ${_currentUser!.id}).");
        } else {
             print("AuthProvider: Login succeeded but no user/ID returned. Cannot establish logged-in state.");
             _apiError = ApiError(message: "Login successful but user data missing from API response.");
             await logout(clearDb: true);
             _isLoading = false;
             notifyListeners();
             return false;
        }

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

  Future<void> logout({bool clearDb = true}) async {
    _currentUser = null;
    _apiError = null;

    if (clearDb) {
      await _dbHelper.deleteLoggedInUser();
      print("AuthProvider: Logged out: User and DB session cleared.");
    } else {
       print("AuthProvider: Logged out: User cleared locally (DB session preservation requested, but likely ineffective).");
    }

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
     await logout(clearDb: true);

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

        if (data.containsKey('user') && data['user'] != null) {
             _currentUser = User.fromJson(data['user']);
             print("AuthProvider: Sign up successful: User ID=${_currentUser?.id} (auto-logged in?).");
             if (_currentUser != null && _currentUser!.id != null) {
                 await _dbHelper.saveLoggedInUser(_currentUser!);
                 print("AuthProvider: Sign up session successfully saved to database.");
             } else {
                  print("AuthProvider: Sign up successful, but no user object/ID returned. Cannot establish logged-in state.");
             }
        } else if (data.containsKey('id') && data['id'] != null) {
             print("AuthProvider: Sign up successful, received user ID ${data['id']}, but not auto-logged in. No session saved.");
        } else {
             print("AuthProvider: Sign up successful, no auto-login. No session saved.");
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
     await logout(clearDb: true);

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
         print("AuthProvider: Full registration successful (assuming no auto-login).");
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
      print("AuthProvider: Change name failed: No logged-in user or user ID.");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null; // Clear previous errors
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');

     final updatePayload = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': _currentUser!.phone,
     };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Id': _currentUser!.id!.toString(),
            },
            body: json.encode(updatePayload),
          )
          .timeout(const Duration(seconds: 10));

      print("AuthProvider: Change name response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         if (data.containsKey('user') && data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
            print("AuthProvider: User data updated from API response after name change.");
         } else {
             _currentUser = User(
                id: _currentUser!.id,
                firstName: firstName,
                lastName: lastName,
                phone: _currentUser!.phone,
                allCourses: _currentUser!.allCourses,
                grade: _currentUser!.grade,
                category: _currentUser!.category,
                school: _currentUser!.school,
                gender: _currentUser!.gender,
                region: _currentUser!.region,
                status: _currentUser!.status,
                enrolledAll: _currentUser!.enrolledAll,
                device: _currentUser!.device,
                serviceType: _currentUser!.serviceType,
                enrolledCourseIds: _currentUser!.enrolledCourseIds,
             );
             print("AuthProvider: User data updated locally after name change.");
         }

         if (_currentUser != null && _currentUser!.id != null) {
             await _dbHelper.saveLoggedInUser(_currentUser!);
             print("AuthProvider: Logged in user name updated in database.");
         }

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Name updated successfully.'};

      } else if (response.statusCode == 401 || response.statusCode == 403) {
          print("AuthProvider: API authentication failed during name change (${response.statusCode}). Session likely invalid online.");
           await logout(clearDb: true);
           // FIX: Use a static string or default message instead of the removed constant
           _handleErrorResponse(response, "Your online session appears invalid. Please log in again.");
           _isLoading = false;
           notifyListeners();
           // FIX: Use a static string or default message instead of the removed constant
           return {'success': false, 'message': _apiError?.message ?? "Your online session appears invalid. Please log in again."};
      }
      else {
        _handleErrorResponse(response, 'Failed to update name.');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Name update timed out.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Name update failed: network error.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Name update failed unexpectedly.');
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
       print("AuthProvider: Change phone failed: No logged-in user or user ID.");
       _isLoading = false;
       notifyListeners();
       return {'success': false, 'message': _apiError!.message};
     }

     _isLoading = true;
     _apiError = null;
     notifyListeners();

     final normalizedNewPhone = normalizePhoneNumberToE164(newRawPhoneNumber);
     final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');

      final updatePayload = {
         'phone': normalizedNewPhone,
         'first_name': _currentUser!.firstName,
         'last_name': _currentUser!.lastName,
      };

     try {
       final response = await http
           .put(
             url,
             headers: {
               'Content-Type': 'application/json',
               'User-Id': _currentUser!.id!.toString(),
             },
             body: json.encode(updatePayload),
           )
           .timeout(const Duration(seconds: 10));

       print("AuthProvider: Change phone response: ${response.statusCode}, Body: ${response.body}");

       if (response.statusCode == 200) {
         final data = json.decode(response.body);
         if (data.containsKey('user') && data['user'] != null) {
             _currentUser = User.fromJson(data['user']);
             print("AuthProvider: User data updated from API response after phone change.");
         } else {
             _currentUser = User(
               id: _currentUser!.id,
               firstName: _currentUser!.firstName,
               lastName: _currentUser!.lastName,
               phone: normalizedNewPhone,
               allCourses: _currentUser!.allCourses,
               grade: _currentUser!.grade,
               category: _currentUser!.category,
               school: _currentUser!.school,
               gender: _currentUser!.gender,
               region: _currentUser!.region,
               status: _currentUser!.status,
               enrolledAll: _currentUser!.enrolledAll,
               device: _currentUser!.device,
               serviceType: _currentUser!.serviceType,
               enrolledCourseIds: _currentUser!.enrolledCourseIds,
             );
              print("AuthProvider: User data updated locally after phone change.");
         }

          if (_currentUser != null && _currentUser!.id != null) {
              await _dbHelper.saveLoggedInUser(_currentUser!);
              print("AuthProvider: Logged in user phone updated in database.");
          }

         _isLoading = false;
         notifyListeners();
         return {'success': true, 'message': 'Phone number updated successfully.'};

       } else if (response.statusCode == 401 || response.statusCode == 403) {
          print("AuthProvider: API authentication failed during phone change (${response.statusCode}). Session likely invalid online.");
           await logout(clearDb: true);
            // FIX: Use a static string or default message instead of the removed constant
           _handleErrorResponse(response, "Your online session appears invalid. Please log in again.");
           _isLoading = false;
           notifyListeners();
            // FIX: Use a static string or default message instead of the removed constant
           return {'success': false, 'message': _apiError?.message ?? "Your online session appears invalid. Please log in again."};
      }
       else {
         _handleErrorResponse(response, 'Failed to update phone number.');
         _isLoading = false;
         notifyListeners();
         return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
       }
     } on TimeoutException catch (e) {
       _handleCatchError(e, 'Phone update timed out.');
       _isLoading = false;
       notifyListeners();
       return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
     } on SocketException catch (e) {
       _handleCatchError(e, 'Phone update failed: network error.');
       _isLoading = false;
       notifyListeners();
       return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
     } catch (error) {
       _handleCatchError(error, 'Phone update failed unexpectedly.');
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
      print("AuthProvider: Change password failed: No logged-in user or user ID.");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');

     final updatePayload = {
        'current_password': currentPassword,
        'password': newPassword,
        'first_name': _currentUser!.firstName,
        'last_name': _currentUser!.lastName,
        'phone': _currentUser!.phone,
     };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
               'User-Id': _currentUser!.id!.toString(),
            },
            body: json.encode(updatePayload),
          )
          .timeout(const Duration(seconds: 10));

      print("AuthProvider: Change password response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
         final data = json.decode(response.body);
         if (data.containsKey('user') && data['user'] != null) {
            _currentUser = User.fromJson(data['user']);
            print("AuthProvider: User data updated from API response after password change.");
         }

        print("AuthProvider: Password changed successfully via API. Forcing re-login for security.");
        await logout(clearDb: true); // Force logout and clear local session

        _isLoading = false;
        notifyListeners();

        return {'success': true, 'message': 'Password changed successfully. Please log in again with your new password.'};

      } else if (response.statusCode == 401 || response.statusCode == 403) {
          print("AuthProvider: API authentication failed during password change (${response.statusCode}). Session likely invalid online.");
           await logout(clearDb: true);
           // FIX: Use a static string or default message instead of the removed constant
           _handleErrorResponse(response, "Your online session appears invalid. Please log in again.");
           _isLoading = false;
           notifyListeners();
           // FIX: Use a static string or default message instead of the removed constant
           return {'success': false, 'message': _apiError?.message ?? "Your online session appears invalid. Please log in again."};
      }
      else {
        _handleErrorResponse(response, 'Failed to change password.');
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Password change timed out.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Password change failed: network error.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } catch (error) {
      _handleCatchError(error, 'Password change failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }


  // Removed _validateSession entirely

  void _handleErrorResponse(http.Response response, String defaultMessage, {bool isLogin = false}) {
    String message;
    List<FieldError>? errors;

    print('AuthProvider: Error response (${response.statusCode}): ${response.body}');

    try {
      final data = json.decode(response.body);
      message = data['message'] as String? ?? data['error'] as String? ?? defaultMessage;

      if (isLogin && (response.statusCode == 401 || response.statusCode == 403)) {
        message = _invalidCredentialsMessage;
      }
      if (data['errors'] is List) {
        errors = (data['errors'] as List)
            .map((e) => FieldError(field: e['field'] ?? 'unknown', message: e['message'] ?? ''))
            .toList();
      } else if (data['errors'] is Map) {
         errors = (data['errors'] as Map).entries.map((entry) {
             final field = entry.key;
             final msg = entry.value is List ? (entry.value as List).join(', ') : entry.value.toString();
             return FieldError(field: field, message: msg);
         }).toList();
      }
      _apiError = ApiError(message: message, errors: errors);
    } catch (e) {
      print("AuthProvider: Failed to parse error response body: $e");
      _apiError = ApiError(message: defaultMessage);
    }
    notifyListeners();
  }

  void _handleCatchError(dynamic error, String context) {
    print('AuthProvider: Error in $context: $error');
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