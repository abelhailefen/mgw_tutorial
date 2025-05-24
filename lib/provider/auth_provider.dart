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
    // More robust checks might be needed depending on expected formats
    if (cleanedNumber.length == 12 && cleanedNumber.startsWith('251')) return '+$cleanedNumber';
    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) return '+251${cleanedNumber.substring(1)}';
    if (cleanedNumber.length == 9) return '+251$cleanedNumber';

    // Fallback for potentially unusual formats or if strict E.164 can't be determined
    // Depending on backend requirements, you might need stricter validation
    print("Warning: Could not reliably normalize phone number '$rawPhoneNumber' to E.164 strictly. Returning processed version: $cleanedNumber");
    return cleanedNumber; // Return the cleaned number or consider throwing an error if format is strictly required
  }


  Future<bool> login({
    required String phoneNumber,
    required String password,
    required String deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null; // Clear previous errors before new attempt
    notifyListeners(); // Notify to show loading spinner

    final String normalizedPhoneNumber = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/auth/login'); // Ensure this URL is correct
    final loginPayload = User(
      firstName: '', // Not needed for login, but part of User model
      lastName: '', // Not needed for login, but part of User model
      phone: normalizedPhoneNumber,
      password: password,
      device: deviceInfo,
    );
    try {
      final body = json.encode(loginPayload.toJsonForLogin());
      print("Login Request URL: $url");
      print("Login Request Body: ${body}"); // Be cautious logging sensitive data like password
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
        notifyListeners(); // Notify success state (user logged in, loading false)
        return true;
      } else {
        // Handle API errors (e.g., 401, 403, 404, 500 etc.)
        _handleErrorResponse(response, _invalidCredentialsMessage, isLogin: true);
        _isLoading = false; // Set loading false on API error
        notifyListeners(); // Notify failure state (error set, loading false)
        return false;
      }
    } on TimeoutException catch (e) { // Catch TimeoutException specifically
      print("Login TimeoutException: $e");
      _handleCatchError(e, 'Login failed due to timeout.'); // Pass more context
      _isLoading = false; // Set loading false on timeout
      notifyListeners(); // Notify failure state (error set, loading false)
      return false;
    } on SocketException catch (e) { // Catch SocketException specifically (network issues)
       print("Login SocketException: $e");
      _handleCatchError(e, 'Login failed due to network issue.');
      _isLoading = false; // Set loading false on network error
      notifyListeners(); // Notify failure state (error set, loading false)
      return false;
    } on http.ClientException catch (e) { // Catch other HTTP client errors
      print("Login ClientException: $e");
      _handleCatchError(e, 'Login failed due to client-side HTTP issue.');
      _isLoading = false; // Set loading false on client error
      notifyListeners(); // Notify failure state (error set, loading false)
      return false;
    }
    catch (error) { // Catch any other errors during the process
      print("Login Generic Catch: $error");
      _handleCatchError(error, 'Login failed unexpectedly.');
      _isLoading = false; // Set loading false on unexpected error
      notifyListeners(); // Notify failure state (error set, loading false)
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiError = null; // Clear error on logout
    notifyListeners();
  }

  Future<bool> signUpSimple({
    required String phoneNumber,
    required String password,
    String? firstName,
    String? lastName,
    String? languageCode, // Unused in current payload logic but kept from original
    String? deviceInfo,
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners(); // Notify to show loading spinner

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
        // API might return AuthResponse (user+token) or just User object on success
        if (responseData.containsKey('user') && responseData.containsKey('token')) {
            final authResponse = AuthResponse.fromJson(responseData);
            _currentUser = authResponse.user;
            _token = authResponse.token;
        } else if (responseData.containsKey('id') && responseData.containsKey('phone')) {
            _currentUser = User.fromJson(responseData);
            _token = null; // No token returned, might need separate login after signup
        } else {
             // Handle unexpected success response structure
             print("Warning: SignUpSimple success but unexpected response structure.");
             _currentUser = null;
             _token = null;
             // Potentially still return true if API indicated success, but user state might be incomplete
        }
        _isLoading = false;
        notifyListeners(); // Notify success state
        return true;
      } else {
        // Handle API errors
        _handleErrorResponse(response, _defaultSignUpFailedMessage);
        _isLoading = false; // Set loading false on API error
        notifyListeners(); // Notify failure state
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Sign up failed due to timeout.');
      _isLoading = false; // Set loading false on timeout
      notifyListeners(); // Notify failure state
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Sign up failed due to network issue.');
      _isLoading = false; // Set loading false on network error
      notifyListeners(); // Notify failure state
      return false;
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Sign up failed due to client-side HTTP issue.');
      _isLoading = false; // Set loading false on client error
      notifyListeners(); // Notify failure state
      return false;
    }
    catch (error) {
      _handleCatchError(error, 'Sign up failed unexpectedly.');
      _isLoading = false; // Set loading false on unexpected error
      notifyListeners(); // Notify failure state
      return false;
    }
  }

  Future<bool> registerUserFull({
    required User registrationData,
    XFile? screenshotFile, // Assuming screenshot is handled elsewhere or optional
  }) async {
    _isLoading = true;
    _apiError = null;
    notifyListeners(); // Notify to show loading spinner

    final String normalizedPhoneForRegistration = normalizePhoneNumberToE164(registrationData.phone);
    // Create a new User object with potentially normalized phone number
    final User updatedRegistrationData = User(
      id: registrationData.id,
      firstName: registrationData.firstName,
      lastName: registrationData.lastName,
      phone: normalizedPhoneForRegistration, // Use normalized number
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
                                .timeout(const Duration(seconds: 30)); // Registration might take longer

      print("RegisterUserFull API Response Status: ${response.statusCode}");
      print("RegisterUserFull API Response Body: ${response.body.substring(0, (response.body.length > 500 ? 500 : response.body.length))}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        
        _isLoading = false;
        notifyListeners(); // Notify success state
        return true;
      } else {
        // Handle API errors
        _handleErrorResponse(response, _defaultRegistrationFailedMessage);
        _isLoading = false; // Set loading false on API error
        notifyListeners(); // Notify failure state
        return false;
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Registration failed due to timeout.');
      _isLoading = false; // Set loading false on timeout
      notifyListeners(); // Notify failure state
      return false;
    } on SocketException catch (e) {
      _handleCatchError(e, 'Registration failed due to network issue.');
      _isLoading = false; // Set loading false on network error
      notifyListeners(); // Notify failure state
      return false;
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Registration failed due to client-side HTTP issue.');
      _isLoading = false; // Set loading false on client error
      notifyListeners(); // Notify failure state
      return false;
    }
    catch (error) {
      _handleCatchError(error, 'Registration failed unexpectedly.');
      _isLoading = false; // Set loading false on unexpected error
      notifyListeners(); // Notify failure state
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null || _currentUser == null) {
      _apiError = ApiError(message: 'User not authenticated. Please log in again.');
      notifyListeners(); // Notify the authentication state change
      return {'success': false, 'message': _apiError!.message};
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

      _isLoading = false; // Set loading false after response
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyListeners(); // Notify success state
        return {'success': true, 'message': 'Password changed successfully.'};
      } else {
        _handleErrorResponse(response, 'Failed to change password. Please ensure current password is correct.');
        notifyListeners(); // Notify failure state
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
       _handleCatchError(e, 'Failed to change password due to timeout.');
       _isLoading = false;
       notifyListeners(); // Notify failure state
       return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to change password due to network issue.');
      _isLoading = false;
      notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to change password due to client-side HTTP issue.');
      _isLoading = false;
      notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to change password unexpectedly.');
       _isLoading = false;
       notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> requestPhoneChangeOTP({
    required String newRawPhoneNumber,
  }) async {
    if (_token == null || _currentUser == null) {
       _apiError = ApiError(message: 'User not authenticated.');
       notifyListeners(); // Notify authentication state change
       return {'success': false, 'message': _apiError!.message};
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

      _isLoading = false; // Set loading false after response
      if (response.statusCode == 200 || response.statusCode == 201) {
        notifyListeners(); // Notify success state
        return {'success': true, 'message': 'OTP sent to $normalizedNewPhone.'};
      } else {
        _handleErrorResponse(response, 'Failed to request OTP. Please try again.');
        notifyListeners(); // Notify failure state
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to timeout.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to network issue.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to request OTP due to client-side HTTP issue.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to request OTP unexpectedly.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }

  Future<Map<String, dynamic>> verifyOtpAndChangePhone({
    required String newRawPhoneNumber,
    required String otp, // This OTP might need to be sent in the body or headers depending on API
    
  }) async {
    if (_token == null || _currentUser == null) {
       _apiError = ApiError(message: 'User not authenticated.');
       notifyListeners(); // Notify authentication state change
       return {'success': false, 'message': _apiError!.message};
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
        // Include other required fields from the user object if the API expects a full or partial user update
        'first_name': _currentUser!.firstName, // Example: Include other existing fields
        'last_name': _currentUser!.lastName, // Example: Include other existing fields
        
    };

    try {
      final response = await http.put(
        url,
        headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $_token", // Requires authentication
        },
        body: json.encode(updatePayload),
      ).timeout(const Duration(seconds: 20));

      _isLoading = false; // Set loading false after response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Assuming the response contains the updated user object
        _currentUser = User.fromJson(responseData);
        notifyListeners(); // Notify success state (user state updated)
        return {'success': true, 'message': 'Phone number updated successfully.'};
      } else {
        // Handle API errors
        _handleErrorResponse(response, 'Failed to update phone number. Please check OTP and try again.');
        notifyListeners(); // Notify failure state
        return {'success': false, 'message': _apiError?.message ?? _defaultFailedMessage};
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to timeout.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _timeoutErrorMessage};
    } on SocketException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to network issue.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _networkErrorMessage};
    } on http.ClientException catch (e) {
      _handleCatchError(e, 'Failed to update phone number due to client-side HTTP issue.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
    catch (error) {
      _handleCatchError(error, 'Failed to update phone number unexpectedly.');
      _isLoading = false; notifyListeners(); // Notify failure state
      return {'success': false, 'message': _apiError?.message ?? _unexpectedErrorMessage};
    }
  }


  // Helper method for handling API response errors (non-2xx status codes)
  void _handleErrorResponse(http.Response response, String defaultUserMessage, {bool isLogin = false}) {
    String errorMessageToShow;
    List<FieldError>? fieldErrorsFromApi;

    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map) {
        // Common API structure: {'message': '...', 'errors': [...]}
        if (errorBody.containsKey('message') && errorBody['message'] != null && errorBody['message'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['message'].toString();

           // Special handling for login credentials
           if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
              // Override generic messages with a specific invalid credentials message
              final lowerMessage = errorMessageToShow.toLowerCase();
              if (lowerMessage.contains("user not found") || lowerMessage.contains("invalid credentials") || lowerMessage.contains("password does not match") || lowerMessage.contains("phone number") || lowerMessage.contains("password")) {
                 errorMessageToShow = _invalidCredentialsMessage;
              }
           }

           if (errorBody.containsKey('errors') && errorBody['errors'] is List && (errorBody['errors'] as List).isNotEmpty) {
             fieldErrorsFromApi = (errorBody['errors'] as List).map((e) {
               if (e is Map<String, dynamic>) {
                 return FieldError.fromJson(e);
               }
               // Handle cases where errors list contains simple strings or unexpected types
               return FieldError(field: 'unknown', message: e.toString());
             }).toList();
            
           }
        }
        // Alternative API structure: {'errorMessage': '...'}
        else if (errorBody.containsKey('errorMessage') && errorBody['errorMessage'] != null && errorBody['errorMessage'].toString().isNotEmpty) {
           errorMessageToShow = errorBody['errorMessage'].toString();
           // Apply login-specific override here as well if needed
            if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
               final lowerMessage = errorMessageToShow.toLowerCase();
                if (lowerMessage.contains("user not found") || lowerMessage.contains("invalid credentials") || lowerMessage.contains("password does not match") || lowerMessage.contains("phone number") || lowerMessage.contains("password")) {
                   errorMessageToShow = _invalidCredentialsMessage;
                }
            }
        }
        // Fallback if message/errorMessage is missing but body is a map
        else {
          if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
            errorMessageToShow = _invalidCredentialsMessage;
          } else {
            // Provide a default message including status code if no specific message found in body
            errorMessageToShow = "$defaultUserMessage (Status: ${response.statusCode})";
          }
        }
      }
      // Fallback if response body is not a map or cannot be decoded
      else {
         if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
            errorMessageToShow = _invalidCredentialsMessage;
          } else {
            errorMessageToShow = "$defaultUserMessage (Status: ${response.statusCode}). Could not parse error response.";
          }
      }
      _apiError = ApiError(message: errorMessageToShow, errors: fieldErrorsFromApi);
    } catch (e) {
      // Handle errors during parsing the error response body
      print("Error parsing error response: $e");
      if (isLogin && (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403)) {
         _apiError = ApiError(message: _invalidCredentialsMessage);
      } else {
        _apiError = ApiError(message: '$defaultUserMessage (Status: ${response.statusCode}). Failed to process error details.');
      }
    }
    // _isLoading is set to false by the calling method (e.g. login, signUpSimple)
    // notifyListeners is called by the calling method (e.g. login, signUpSimple)
  }

  // Helper method for handling network/timeout/client exceptions
  void _handleCatchError(dynamic error, String uiContextMessage) {
    // uiContextMessage is for logging and debugging, not directly shown to user usually.
    print('AuthProvider Exception during "$uiContextMessage": ${error.toString()}');
    if (error is SocketException || (error is http.ClientException && error.message.contains('Failed host lookup'))) {
      // Treat SocketException and certain ClientExceptions (like host lookup failure) as network errors
      _apiError = ApiError(message: _networkErrorMessage);
    } else if (error is TimeoutException) {
       _apiError = ApiError(message: _timeoutErrorMessage); // Specific message for timeout
    } else if (error is http.ClientException) {
       // Other client exceptions (e.g., response body not JSON)
       _apiError = ApiError(message: 'Client error: ${error.message}'); // Maybe more specific error message or just unexpected error
       print("Specific HTTP Client Exception: ${error.message}");
    }
    else {
      // For any other unknown error during the HTTP call process (e.g., format exceptions in parsing)
      _apiError = ApiError(message: _unexpectedErrorMessage);
       print("Unexpected Catch Error Type: ${error.runtimeType}");
    }
   }
}