// lib/provider/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mgw_tutorial/models/user.dart'; // Assuming User model exists and is complete
import 'package:mgw_tutorial/models/auth_response.dart'; // Assuming AuthResponse model exists
import 'package:mgw_tutorial/models/api_error.dart'; // Assuming ApiError model exists
import 'package:mgw_tutorial/models/field_error.dart'; // Assuming FieldError model exists
import 'package:mgw_tutorial/services/database_helper.dart'; // Assuming DatabaseHelper exists

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

  static const String _networkErrorMessage =
      "Sorry, there seems to be a network error.";
  static const String _timeoutErrorMessage = "The request timed out.";
  static const String _unexpectedErrorMessage = "An unexpected error occurred.";
  static const String _defaultFailedMessage = "Operation failed. Try again.";
  static const String _invalidCredentialsMessage =
      "Invalid phone number or password.";
  static const String _defaultRegistrationFailedMessage =
      "Registration failed. Please check your details and try again.";
  static const String _defaultSignUpFailedMessage = "Sign up failed.";
  static const String _notAuthenticatedMessage =
      "Not authenticated. Please log in.";

  static const String _apiBaseUrl = "https://userservice.mgwcommunity.com";

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
        print(
            "AuthProvider: Found saved session in DB (User ID ${savedSession['user_id']}).");
        // Reconstruct the User object as fully as possible from saved data
        // Ensure all potentially saved fields are included if available in your DB schema
        _currentUser = User(
          id: savedSession['user_id'] as int,
          firstName: savedSession['first_name'] as String? ?? '',
          lastName: savedSession['last_name'] as String? ?? '',
          phone: savedSession['phone'] as String? ?? '',
          // *** IMPORTANT ***
          // Add other fields here if they are saved in your 'logged_in_user' table
          // Otherwise, the _currentUser object might be incomplete after offline restore.
          // Example (adjust based on your DatabaseHelper and User model):
          grade: savedSession['grade'] as String? ?? 'Not Specified',
          category: savedSession['category'] as String? ?? 'Not Specified',
          school: savedSession['school'] as String? ?? 'Not Specified',
          gender: savedSession['gender'] as String? ?? 'Not Specified',
          region: savedSession['region'] as String? ?? 'Not Specified',
          status: savedSession['status'] as String? ?? 'unknown',
          device: savedSession['device'] as String? ?? 'Unknown Device',
          allCourses: (savedSession['all_courses'] as int? ?? 0) ==
              1, // SQLite INT to bool
          enrolledAll: (savedSession['enrolled_all'] as int? ?? 0) ==
              1, // SQLite INT to bool
          serviceType:
              savedSession['service_type'] as String? ?? 'Not Specified',
          // enrolledCourseIds: (jsonDecode(savedSession['enrolled_course_ids'] ?? '[]') as List).cast<int>(), // Decode JSON list if saved as JSON
        );

        print(
            "AuthProvider: Loaded User ID ${_currentUser!.id} from DB. Considering user logged in (Offline Mode). Status: ${_currentUser!.status}.");
      } else {
        print(
            "AuthProvider: No saved session found in DB or user_id is null. User is not logged in.");
        await logout(
            clearDb: true); // Ensure clean state if DB is empty or corrupt
      }
    } catch (e) {
      print(
          "AuthProvider: FATAL Error during initialization (loading from DB): $e");
      // Critical error loading from DB, assume no user and clear state
      await logout(clearDb: true);
      _apiError = ApiError(
          message:
              "An error occurred while trying to restore your session from local data. Please log in.");
    }

    _isInitializing = false;
    notifyListeners();
    print(
        "AuthProvider Initialization Finished. Current User: ${_currentUser?.id}");
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
    // Ethiopia +251 format
    if (cleanedNumber.startsWith('251') && cleanedNumber.length == 12)
      return '+$cleanedNumber';
    // Ethiopia 09... format
    if (cleanedNumber.startsWith('0') && cleanedNumber.length == 10)
      return '+251${cleanedNumber.substring(1)}';
    // Ethiopia 9... format (common input without leading 0)
    if (cleanedNumber.length == 9 &&
        (cleanedNumber.startsWith('9') || cleanedNumber.startsWith('7')))
      return '+251$cleanedNumber';
    // If it's already in +251... format
    if (rawPhoneNumber.startsWith('+251') && rawPhoneNumber.length == 13)
      return rawPhoneNumber;

    // Fallback for potentially valid numbers not matching strict E.164 Ethiopian format
    // If the cleaned number is 9 digits or longer and consists only of digits,
    // assume it might need a +251 prefix as a best guess, especially if it doesn't start with 0 or +251.
    if (cleanedNumber.length >= 9 && int.tryParse(cleanedNumber) != null) {
      print(
          "Warning: Phone '$rawPhoneNumber' doesn't match standard ET patterns. Guessing +251 prefix.");
      // If it doesn't start with 251 already, prepend +251
      if (!cleanedNumber.startsWith('251')) {
        return '+251$cleanedNumber';
      }
      // If it already started with 251 but wasn't 12 digits long, return as is after cleanup
      return '+$cleanedNumber'; // Assuming it might be an international number or slightly off
    }

    print(
        "Warning: Could not confidently normalize phone number '$rawPhoneNumber' to E.164. Returning cleaned: $cleanedNumber");
    return cleanedNumber; // Return the cleaned version if unable to normalize
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
    required String deviceInfo,
  }) async {
    // Clear existing user from DB *before* attempting login to ensure a clean state
    // if a previous session was incomplete or invalid.
    await _dbHelper.deleteLoggedInUser();

    _isLoading = true;
    _apiError = null;
    notifyListeners(); // Notify that loading has started

    final normalizedPhoneNumber = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse('$_apiBaseUrl/api/auth/login');

    // Minimal payload needed for login endpoint based on common API design
    final loginPayload = {
      'phone': normalizedPhoneNumber,
      'password': password,
      'device': deviceInfo, // Use the deviceInfo string provided
    };

    try {
      final body = json.encode(loginPayload);
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Login response - Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print("AuthProvider: Login failed - Empty response body.");
          _apiError = ApiError(
              message: "Login failed: Server returned empty response.");
          _isLoading = false;
          notifyListeners();
          return false;
        }

        try {
          final data = json.decode(response.body);
          if (data == null || data is! Map<String, dynamic>) {
            print("AuthProvider: Login failed - Invalid JSON response: $data");
            _apiError = ApiError(
                message: "Login failed: Invalid server response format.");
            _isLoading = false;
            notifyListeners();
            return false;
          }

          final authResponse = AuthResponse.fromJson(data);
          if (authResponse.user == null) {
            print(
                "AuthProvider: Login failed - No user data in response: ${authResponse.message}");
            // Use authResponse.message if available, fallback to default
            _apiError = ApiError(
              message: authResponse.message?.isNotEmpty == true
                  ? authResponse.message!
                  : "Login failed: No user data returned by server.",
            );
            _isLoading = false;
            notifyListeners();
            return false;
          }

          _currentUser = authResponse.user;
          print(
              "Login successful: User ID=${_currentUser?.id}. Status: ${_currentUser?.status}.");

          // Check for valid user ID after successful API response
          if (_currentUser != null &&
              _currentUser!.id != null &&
              _currentUser!.id! > 0) {
            try {
              // Save the full user object returned by the API
              await _dbHelper.saveLoggedInUser(_currentUser!);
              print(
                  "AuthProvider: Login session successfully saved to database (User ID ${_currentUser!.id}).");
            } catch (e) {
              print(
                  "AuthProvider: Failed to save user session to database: $e");
              // Login was successful on the API, but local save failed.
              // Set an error message about the local failure, but return true as online login succeeded.
              _apiError = ApiError(
                  message:
                      "Login successful, but failed to save session locally.");
              notifyListeners(); // Notify about the local save error immediately
            }
            _isLoading = false;
            notifyListeners(); // Notify about successful login and user update
            return true; // API login succeeded
          } else {
            print(
                "AuthProvider: Login succeeded but invalid user ID in API response. Cannot establish logged-in state.");
            _apiError = ApiError(
                message: "Login failed: Invalid user data returned by server.");
            // Ensure _currentUser is null if the ID is invalid, even if API returned *something*.
            _currentUser = null;
            await _dbHelper
                .deleteLoggedInUser(); // Ensure local session is also clean
            _isLoading = false;
            notifyListeners();
            return false; // API login response was invalid
          }
        } catch (e) {
          print("AuthProvider: Error parsing login response body JSON: $e");
          _apiError = ApiError(
              message: "Login failed: Invalid server response format.");
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        // Handle API errors based on status code
        // This is where a device mismatch error from the API would likely be caught (e.g., 400, 403)
        _handleErrorResponse(response, _invalidCredentialsMessage,
            isLogin: true);
        _isLoading = false;
        notifyListeners();
        return false; // Login failed
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
      print("AuthProvider: Unexpected error during login: $error");
      _handleCatchError(error, 'Login failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({bool clearDb = true}) async {
    _currentUser = null;
    _apiError = null; // Clear any existing errors on logout

    if (clearDb) {
      try {
        await _dbHelper.deleteLoggedInUser();
        print("AuthProvider: Logged out: User and DB session cleared.");
      } catch (e) {
        print(
            "AuthProvider: Failed to clear user session from database on logout: $e");
        // Optional: set a local error message about the DB failure
        // _apiError = ApiError(message: "Logout successful, but failed to clear local data.");
      }
    } else {
      print(
          "AuthProvider: Logged out: User cleared locally (DB session preservation requested, but likely ineffective).");
    }

    _isLoading = false; // Ensure loading is false on logout
    notifyListeners();
  }

  Future<bool> signUpSimple({
    required String phoneNumber,
    required String password,
    String? firstName,
    String? lastName,
    String?
        languageCode, // Although not used in User model, keep for potential future use
    String? deviceInfo,
  }) async {
    // Simple sign up shouldn't necessarily log the user in or clear existing sessions.
    // It just registers the user. The user will then need to log in.
    // Ensure no old session interferes before attempting signup.
    await logout(clearDb: true);

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final normalizedPhone = normalizePhoneNumberToE164(phoneNumber);
    final url = Uri.parse(
        '$_apiBaseUrl/api/users'); // Assuming /api/users endpoint for simple signup

    // Construct payload with only required fields for simple signup
    // Check your API documentation for what fields are *truly* mandatory for simple signup.
    // Assuming phone, password, device, and maybe name are standard.
    final simpleSignupPayload = {
      'phone': normalizedPhone,
      'password': password,
      'device': deviceInfo, // Use deviceInfo provided
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      // Include any other minimum mandatory fields required by your /api/users POST endpoint
      // For example, if status is mandatory, provide a default like 'pending'.
      // 'status': 'pending', // Example if mandatory
      // 'category': 'Not Specified', // Example if mandatory
      // etc.
    };

    try {
      final body = json.encode(simpleSignupPayload);
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Simple sign up response - Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Simple sign up usually doesn't return a full user object or token for auto-login.
        // The user needs to perform a separate login after registration.
        // Do NOT set _currentUser or save to DB here unless API docs explicitly state auto-login
        // and provide a full user object in the response body.
        _currentUser = null; // Ensure _currentUser is null after simple signup
        // No need to clear DB again, was cleared at the start of the method

        print("AuthProvider: Simple sign up successful.");
        _isLoading = false;
        notifyListeners(); // Notify loading is done
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
    // Full registration typically does not auto-login. User needs to login afterwards.
    // Ensure no old session interferes before attempting registration.
    await logout(clearDb: true);

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final normalizedPhone = normalizePhoneNumberToE164(registrationData.phone);

    // Prepare the full payload using data from the User object passed in
    final Map<String, dynamic> fullRegistrationPayload = {
      'first_name': registrationData.firstName,
      'last_name': registrationData.lastName,
      'phone': normalizedPhone,
      'password': registrationData.password,
      'device': registrationData.device, // Use the device string passed in
      'grade': registrationData.grade,
      'category': registrationData.category,
      'school': registrationData.school,
      'gender': registrationData.gender,
      'region': registrationData.region,
      'status': registrationData
          .status, // Use the status from the User object (likely "pending")
      'all_courses': registrationData.allCourses,
      'enrolled_all': registrationData.enrolledAll,
      // serviceType and enrolledCourseIds are typically NOT part of a registration payload
      // as they relate to enrollment or service plans after registration.
      // Remove if your API doesn't expect them during initial user creation.
      // 'service_type': registrationData.serviceType,
      // 'enrolled_course_ids': jsonEncode(registrationData.enrolledCourseIds ?? []),
    };

    final url = Uri.parse(
        '$_apiBaseUrl/api/users'); // Assuming this is the endpoint for full user creation
    try {
      final body =
          json.encode(fullRegistrationPayload); // Encode the map directly
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Full registration response - Status: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("AuthProvider: Full registration successful.");
        // Full registration typically does not auto-login, user needs to login afterwards.
        _currentUser = null; // Ensure no user is set after registration
        _isLoading = false;
        notifyListeners(); // Notify loading is done
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

    // Include *only* the fields being changed, along with phone and potentially user ID in payload,
    // if the API supports partial PUT or requires phone for updates.
    // Check your API documentation for the exact expected payload for PUT /api/users/update/{id}
    final updatePayload = {
      'first_name': firstName, // Field being changed
      'last_name': lastName, // Field being changed
      // Include other potentially mandatory fields if API requires them in payload
      'phone': _currentUser!.phone, // Common to include phone
      // 'id': _currentUser!.id, // Include if API requires ID in payload as well as path
      // Include device if updating device info is part of this endpoint, otherwise omit
      // 'device': _currentUser!.device,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              // Assuming the API uses a custom header 'User-Id' for authorization/identification
              'User-Id': _currentUser!.id!.toString(),
              // Include other headers like authorization tokens if needed by your API
              // 'Authorization': 'Bearer your_token_here',
            },
            body: json.encode(updatePayload),
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Change name response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('user') && data['user'] != null) {
          // Update _currentUser with potentially richer data from API
          _currentUser = User.fromJson(data['user']);
          print(
              "AuthProvider: User data updated from API response after name change.");
        } else {
          // Fallback to updating locally if API doesn't return full user
          // Ensure all fields are copied from the old _currentUser except the ones changed
          _currentUser = User(
            id: _currentUser!.id,
            firstName: firstName, // Updated
            lastName: lastName, // Updated
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

        // Save updated user data to the local database
        if (_currentUser != null &&
            _currentUser!.id != null &&
            _currentUser!.id! > 0) {
          try {
            await _dbHelper.saveLoggedInUser(_currentUser!);
            print("AuthProvider: Logged in user name updated in database.");
          } catch (e) {
            print(
                "AuthProvider: Failed to save user session to database after name change: $e");
            // Set an error message about the local failure, but the API call succeeded.
            _apiError =
                ApiError(message: "Name updated, but failed to save locally.");
            notifyListeners(); // Notify immediately about the local save error
          }
        }

        _isLoading = false;
        notifyListeners(); // Notify about successful update or local save error
        return {'success': true, 'message': 'Name updated successfully.'};
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
            "AuthProvider: API authentication failed during name change (${response.statusCode}). Session likely invalid online.");
        await logout(clearDb: true); // Force logout on auth failure
        // Use a static string for the error message
        String authErrorMessage =
            "Your online session appears invalid. Please log in again.";
        _apiError = ApiError(message: authErrorMessage);
        _isLoading = false;
        notifyListeners();
        // Return the same message
        return {'success': false, 'message': authErrorMessage};
      } else {
        // Handle other API error status codes
        _handleErrorResponse(response, 'Failed to update name.');
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _apiError?.message ?? _defaultFailedMessage
        };
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Name update timed out.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _timeoutErrorMessage
      };
    } on SocketException catch (e) {
      _handleCatchError(e, 'Name update failed: network error.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _networkErrorMessage
      };
    } catch (error) {
      _handleCatchError(error, 'Name update failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _unexpectedErrorMessage
      };
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

    // Include *only* the phone field, along with potentially name/ID
    // Check your API documentation for the exact expected payload for PUT /api/users/update/{id} for phone changes.
    final updatePayload = {
      'phone': normalizedNewPhone, // Field being changed
      // Include other potentially mandatory fields if API requires them in payload
      // 'first_name': _currentUser!.firstName, // Include if API requires name in payload
      // 'last_name': _currentUser!.lastName, // Include if API requires name in payload
      // 'id': _currentUser!.id, // Include if API requires ID in payload
      // Include device if updating device info is part of this endpoint, otherwise omit
      // 'device': _currentUser!.device,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              // Assuming the API uses a custom header 'User-Id'
              'User-Id': _currentUser!.id!.toString(),
              // Include other headers like authorization tokens if needed by your API
              // 'Authorization': 'Bearer your_token_here',
            },
            body: json.encode(updatePayload),
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Change phone response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('user') && data['user'] != null) {
          // Update _currentUser with potentially richer data from API
          _currentUser = User.fromJson(data['user']);
          print(
              "AuthProvider: User data updated from API response after phone change.");
        } else {
          // Fallback to updating locally if API doesn't return full user
          // Ensure all fields are copied from the old _currentUser except the one changed
          _currentUser = User(
            id: _currentUser!.id,
            firstName: _currentUser!.firstName,
            lastName: _currentUser!.lastName,
            phone: normalizedNewPhone, // Use the new phone number
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

        // Save updated user data to the local database
        if (_currentUser != null &&
            _currentUser!.id != null &&
            _currentUser!.id! > 0) {
          try {
            await _dbHelper.saveLoggedInUser(_currentUser!);
            print("AuthProvider: Logged in user phone updated in database.");
          } catch (e) {
            print(
                "AuthProvider: Failed to save user session to database after phone change: $e");
            _apiError = ApiError(
                message:
                    "Phone number updated, but failed to save locally."); // Notify about DB save error
            notifyListeners(); // Notify immediately about the local save error
          }
        }

        _isLoading = false;
        notifyListeners(); // Notify about successful update or local save error
        return {
          'success': true,
          'message': 'Phone number updated successfully.'
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
            "AuthProvider: API authentication failed during phone change (${response.statusCode}). Session likely invalid online.");
        await logout(clearDb: true); // Force logout on auth failure
        // Use a static string for the error message
        String authErrorMessage =
            "Your online session appears invalid. Please log in again.";
        _apiError = ApiError(message: authErrorMessage);
        _isLoading = false;
        notifyListeners();
        // Return the same message
        return {'success': false, 'message': authErrorMessage};
      } else {
        // Handle other API error status codes
        _handleErrorResponse(response, 'Failed to update phone number.');
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _apiError?.message ?? _defaultFailedMessage
        };
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Phone update timed out.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _timeoutErrorMessage
      };
    } on SocketException catch (e) {
      _handleCatchError(e, 'Phone update failed: network error.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _networkErrorMessage
      };
    } catch (error) {
      _handleCatchError(error, 'Phone update failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _unexpectedErrorMessage
      };
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null || _currentUser!.id == null) {
      _apiError = ApiError(message: _notAuthenticatedMessage);
      print(
          "AuthProvider: Change password failed: No logged-in user or user ID.");
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _apiError!.message};
    }

    _isLoading = true;
    _apiError = null;
    notifyListeners();

    final url = Uri.parse('$_apiBaseUrl/api/users/update/${_currentUser!.id}');

    // Include current_password and new password in the payload.
    // Check your API documentation for the exact expected payload for password changes.
    final updatePayload = {
      'current_password': currentPassword,
      'password': newPassword, // Field being changed
      // Include other potentially mandatory fields if API requires them in payload
      // 'first_name': _currentUser!.firstName, // Include if API requires name
      // 'last_name': _currentUser!.lastName,   // Include if API requires name
      // 'phone': _currentUser!.phone, // Include if API requires phone
      // 'id': _currentUser!.id, // Include if API requires ID in payload
      // Include device if updating device info is part of this endpoint, otherwise omit
      // 'device': _currentUser!.device,
    };

    try {
      final response = await http
          .put(
            url,
            headers: {
              'Content-Type': 'application/json',
              // Assuming the API uses a custom header 'User-Id'
              'User-Id': _currentUser!.id!.toString(),
              // Include other headers like authorization tokens if needed by your API
              // 'Authorization': 'Bearer your_token_here',
            },
            body: json.encode(updatePayload),
          )
          .timeout(const Duration(seconds: 10));

      print(
          "AuthProvider: Change password response: ${response.statusCode}, Body: ${response.body}");

      if (response.statusCode == 200) {
        // API password change was successful. Forcing re-login for security is standard practice.
        print(
            "AuthProvider: Password changed successfully via API. Forcing re-login for security.");
        // Clear local session immediately as it's now invalid with the old password
        await logout(clearDb: true);

        _isLoading = false;
        notifyListeners(); // Notify that logout/state change happened

        return {
          'success': true,
          'message':
              'Password changed successfully. Please log in again with your new password.'
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print(
            "AuthProvider: API authentication failed during password change (${response.statusCode}). Session likely invalid online.");
        await logout(clearDb: true); // Force logout on auth failure
        // Use a static string for the error message
        String authErrorMessage =
            "Your online session appears invalid. Please log in again.";
        _apiError = ApiError(message: authErrorMessage);
        _isLoading = false;
        notifyListeners();
        // Return the same message
        return {'success': false, 'message': authErrorMessage};
      } else {
        // Handle other API error status codes
        _handleErrorResponse(response, 'Failed to change password.');
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': _apiError?.message ?? _defaultFailedMessage
        };
      }
    } on TimeoutException catch (e) {
      _handleCatchError(e, 'Password change timed out.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _timeoutErrorMessage
      };
    } on SocketException catch (e) {
      _handleCatchError(e, 'Password change failed: network error.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _networkErrorMessage
      };
    } catch (error) {
      _handleCatchError(error, 'Password change failed unexpectedly.');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _apiError?.message ?? _unexpectedErrorMessage
      };
    }
  }

  void _handleErrorResponse(http.Response response, String defaultMessage,
      {bool isLogin = false}) {
    String message;
    List<FieldError>? errors;

    print(
        'AuthProvider: Error response (${response.statusCode}): ${response.body}');

    try {
      final data = json.decode(response.body);
      // Prioritize 'message' or 'error' from API, fallback to default message
      message = data['message'] as String? ??
          data['error'] as String? ??
          defaultMessage;

      // Override message specifically for login 401/403 if needed
      if (isLogin &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        message = _invalidCredentialsMessage;
      }
      // Handle errors list/map from API response
      if (data['errors'] is List) {
        errors = (data['errors'] as List)
            .map((e) => FieldError(
                field: e['field'] ?? 'unknown', message: e['message'] ?? ''))
            .toList();
      } else if (data['errors'] is Map) {
        errors = (data['errors'] as Map).entries.map((entry) {
          final field = entry.key;
          final msg = entry.value is List
              ? (entry.value as List).join(', ')
              : entry.value.toString();
          return FieldError(field: field, message: msg);
        }).toList();
      }

      // Create ApiError object
      _apiError = ApiError(
          message: message,
          errors: errors != null && errors.isNotEmpty
              ? errors
              : null // Only include errors if the list is not empty
          );
    } catch (e) {
      print("AuthProvider: Failed to parse error response body: $e");
      // If parsing the error body fails, use the default message
      _apiError = ApiError(message: defaultMessage);
    }
    notifyListeners(); // Notify listeners about the error change
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
    notifyListeners(); // Notify listeners about the error change
  }
}
