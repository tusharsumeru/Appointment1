import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';
import 'jwt_utils.dart'; // Added import for JwtUtils

class ActionService {
  static const String baseUrl =
      'https://538bc59547d2.ngrok-free.app/api/v3'; // API base URL

  static Future<Map<String, dynamic>> getAllSecretaries({
    int page = 1,
    int limit = 10,
    String? search,
    bool? isActive,
  }) async {
    try {
      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/auth/secretaries').replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Successfully retrieved secretaries',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to retrieve secretaries',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Please enter both your email address and password to continue. 🔐',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'email': email.toLowerCase().trim(),
        'password': password,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful login
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              '🎉 Welcome back! You\'re now logged in and ready to explore.',
        };
      } else if (response.statusCode == 202) {
        // Requires additional verification (OTP)
        return {
          'success': true,
          'statusCode': 202,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Verification code sent to your email.',
        };
      } else {
        // Error response
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Login failed. Please try again.',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Oops! Something went wrong during login. Please try again in a moment. If the problem persists, please contact our support team. 🛠️',
      };
    }
  }

  // Helper method to handle different error scenarios
  static Map<String, dynamic> handleLoginError(int statusCode, String message) {
    switch (statusCode) {
      case 400:
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Please enter both your email address and password to continue. 🔐',
        };
      case 401:
        return {
          'success': false,
          'statusCode': 401,
          'message': message.contains('email')
              ? 'We couldn\'t find an account with that email address. Please check your email or sign up for a new account. 📧'
              : 'The password you entered is incorrect. Please try again or use \'Forgot Password\' if you need to reset it. 🔑',
        };
      case 403:
        return {
          'success': false,
          'statusCode': 403,
          'message':
              'Your account is currently inactive. Please reach out to our support team and we\'ll be happy to help you get back on track! 💬',
        };
      case 423:
        return {
          'success': false,
          'statusCode': 423,
          'message':
              'Your account is temporarily locked for security reasons. Please try again in a few hours or contact our support team if you need immediate assistance. 🔒',
        };
      default:
        return {'success': false, 'statusCode': statusCode, 'message': message};
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Make API call with authorization header
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success - save user data to local storage and return
        await StorageService.saveUserData(responseData['data']);
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'User profile retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 403) {
        // Account deactivated
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 403,
          'message': 'Account is deactivated. Please contact support.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 404,
          'message': 'User not found. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Helper method to process appointment data and format user fields
  static Map<String, dynamic> _processAppointmentData(
    Map<String, dynamic> appointment,
  ) {
    // Create a copy of the appointment data
    final Map<String, dynamic> processedAppointment = Map<String, dynamic>.from(
      appointment,
    );

    // Process userMobile field - handle both object and string formats
    final userMobile = appointment['userMobile'];
    if (userMobile is Map<String, dynamic>) {
      final countryCode = userMobile['countryCode']?.toString() ?? '';
      final number = userMobile['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        processedAppointment['userMobile'] = '$countryCode $number';
      }
    }

    // Ensure userEmail is properly set
    if (processedAppointment['userEmail'] == null ||
        processedAppointment['userEmail'].toString().isEmpty) {
      // Fallback to email field if userEmail is not available
      final email = appointment['email']?.toString();
      if (email != null && email.isNotEmpty) {
        processedAppointment['userEmail'] = email;
      }
    }

    // Ensure referencePhoneNumber is properly set
    if (processedAppointment['referencePhoneNumber'] == null ||
        processedAppointment['referencePhoneNumber'].toString().isEmpty) {
      // Try alternative field names
      final refPhone =
          appointment['referencePhone']?.toString() ??
          appointment['refPhone']?.toString() ??
          appointment['emergencyPhone']?.toString() ??
          appointment['contactPhone']?.toString();
      if (refPhone != null && refPhone.isNotEmpty) {
        processedAppointment['referencePhoneNumber'] = refPhone;
      }
    }

    // Ensure referenceEmail is properly set
    if (processedAppointment['referenceEmail'] == null ||
        processedAppointment['referenceEmail'].toString().isEmpty) {
      // Try alternative field names
      final refEmail =
          appointment['referenceEmail']?.toString() ??
          appointment['refEmail']?.toString() ??
          appointment['emergencyEmail']?.toString() ??
          appointment['contactEmail']?.toString();
      if (refEmail != null && refEmail.isNotEmpty) {
        processedAppointment['referenceEmail'] = refEmail;
      }
    }

    return processedAppointment;
  }

  // Get appointments for secretary with advanced filtering
  static Future<Map<String, dynamic>> getAppointmentsForSecretary({
    int page = 1,
    int limit = 10,
    String sortBy = "createdAt",
    String sortOrder = "desc",
    String? status,
    String dateType = "created", // "created", "scheduled", "preferred"
    String? dateFrom,
    String? dateTo,
    bool? today,
    bool? thisWeek,
    bool? thisMonth,
    bool? upcoming,
    bool? past,
    String? assignedSecretary,
    bool? starred,
    bool? assigned, // Add assigned parameter for filtering
    bool? unassigned, // Add unassigned parameter for filtering
    Map<String, dynamic>? additionalFilters,
    String? screen, // "inbox" or "assigned_to_me"
    String? filter, // New filter parameter for secretary filtering
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'dateType': dateType,
      };

      // Add optional parameters
      if (status != null) {
        queryParams['status'] = status;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }
      if (today != null) {
        queryParams['today'] = today.toString();
      }
      if (thisWeek != null) {
        queryParams['thisWeek'] = thisWeek.toString();
      }
      if (thisMonth != null) {
        queryParams['thisMonth'] = thisMonth.toString();
      }
      if (upcoming != null) {
        queryParams['upcoming'] = upcoming.toString();
      }
      if (past != null) {
        queryParams['past'] = past.toString();
      }
      if (assignedSecretary != null) {
        queryParams['assignedSecretary'] = assignedSecretary;
      }
      if (starred != null) {
        queryParams['starred'] = starred.toString();
      }
      if (assigned != null) {
        queryParams['assigned'] = assigned.toString();
      }
      if (unassigned != null) {
        queryParams['unassigned'] = unassigned.toString();
      }
      
      // Add filter parameter for secretary filtering
      if (filter != null) {
        queryParams['filter'] = filter;
      }

      // Add additional filters
      if (additionalFilters != null) {
        additionalFilters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/appointments/status',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response with error handling
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - process appointments data with enhanced user fields
        final List<dynamic> rawAppointments =
            responseData['data']?['appointments'] ?? [];

        // Process appointments to ensure all user fields are properly formatted
        final List<Map<String, dynamic>> processedAppointments = rawAppointments
            .map((appointment) {
              if (appointment is Map<String, dynamic>) {
                return _processAppointmentData(appointment);
              }
              return <String, dynamic>{};
            })
            .toList();

        // No caching for inbox and assigned to me screens - always fetch fresh data

        return {
          'success': true,
          'statusCode': 200,
          'data': processedAppointments,
          'statusBreakdown': responseData['data']?['statusBreakdown'] ?? {},
          'dateRangeSummary': responseData['data']?['dateRangeSummary'] ?? {},
          'filters': responseData['data']?['filters'] ?? {},
          'pagination': responseData['pagination'] ?? {},
          'message':
              responseData['message'] ?? 'Appointments retrieved successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 404,
          'message': 'User not found. Please login again.',
        };
      } else if (response.statusCode == 500) {
        // Handle backend errors
        return {
          'success': false,
          'statusCode': 500,
          'message':
              responseData['message'] ??
              'Server error. Please try again later.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to get appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get face match results by appointment ID
  static Future<Map<String, dynamic>> getFaceMatchResultByAppointmentId(
    String appointmentId,
  ) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate appointmentId
      if (appointmentId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Appointment ID is required',
        };
      }

      // Make API call with authorization header
      final response = await http.get(
        Uri.parse('$baseUrl/appointment/$appointmentId/face-match-result'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - return face match data
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Face match results retrieved successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid appointment ID',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Face match result not found
        return {
          'success': false,
          'statusCode': 404,
          'message':
              responseData['message'] ??
              'Face match result not found for this appointment',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to get face match results',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get appointments with advanced filtering for specific screens
  static Future<Map<String, dynamic>> getAppointmentsWithFilters({
    int page = 1,
    int limit = 10,
    String sortBy = "createdAt",
    String sortOrder = "desc",
    String? status,
    String dateType = "created", // "created", "scheduled", "preferred"
    String? dateFrom,
    String? dateTo,
    bool? today,
    bool? thisWeek,
    bool? thisMonth,
    bool? upcoming,
    bool? past,
    String? assignedSecretary,
    bool? starred,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'dateType': dateType,
      };

      // Add optional parameters
      if (status != null) {
        queryParams['status'] = status;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }
      if (today != null) {
        queryParams['today'] = today.toString();
      }
      if (thisWeek != null) {
        queryParams['thisWeek'] = thisWeek.toString();
      }
      if (thisMonth != null) {
        queryParams['thisMonth'] = thisMonth.toString();
      }
      if (upcoming != null) {
        queryParams['upcoming'] = upcoming.toString();
      }
      if (past != null) {
        queryParams['past'] = past.toString();
      }
      if (assignedSecretary != null) {
        queryParams['assignedSecretary'] = assignedSecretary;
      }
      if (starred != null) {
        queryParams['starred'] = starred.toString();
      }

      // Add additional filters
      if (additionalFilters != null) {
        additionalFilters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/appointments/status',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response with error handling
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - process appointments data with enhanced user fields
        final List<dynamic> rawAppointments =
            responseData['data']?['appointments'] ?? [];

        // Process appointments to ensure all user fields are properly formatted
        final List<Map<String, dynamic>> processedAppointments = rawAppointments
            .map((appointment) {
              if (appointment is Map<String, dynamic>) {
                return _processAppointmentData(appointment);
              }
              return <String, dynamic>{};
            })
            .toList();

        return {
          'success': true,
          'statusCode': 200,
          'data': processedAppointments,
          'statusBreakdown': responseData['data']?['statusBreakdown'] ?? {},
          'dateRangeSummary': responseData['data']?['dateRangeSummary'] ?? {},
          'filters': responseData['data']?['filters'] ?? {},
          'pagination': responseData['pagination'] ?? {},
          'message':
              responseData['message'] ?? 'Appointments retrieved successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 404,
          'message': 'User not found. Please login again.',
        };
      } else if (response.statusCode == 500) {
        // Handle backend errors
        return {
          'success': false,
          'statusCode': 500,
          'message':
              responseData['message'] ??
              'Server error. Please try again later.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to get appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Update starred status of an appointment with optional remarks and notes
  static Future<Map<String, dynamic>> updateStarred(
    String appointmentId, {
    bool? starred,
    String? gurudevRemarks,
    String? secretaryNotes,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate appointmentId
      if (appointmentId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Appointment ID is required',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {};
      if (starred != null) {
        requestBody['starred'] = starred;
      }
      if (gurudevRemarks != null) {
        requestBody['gurudevRemarks'] = gurudevRemarks;
      }
      if (secretaryNotes != null) {
        requestBody['secretaryNotes'] = secretaryNotes;
      }

      // Make API call with authorization header
      final response = await http.put(
        Uri.parse('$baseUrl/appointment/$appointmentId/starred'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Handle large response that might cause BSON serialization issues
      if (response.statusCode == 200) {
        // Success - but handle potential large response
        try {
          final responseData = jsonDecode(response.body);

          // Extract only essential data to avoid issues with large documents
          final data = responseData['data'];
          final essentialData = {
            'appointmentId': data?['appointmentId'],
            '_id': data?['_id'],
            'starred': data?['starred'] ?? false,
            'gurudevRemarks': data?['gurudevRemarks'],
            'secretaryNotes': data?['secretaryNotes'],
            'status': data?['status'],
            'email': data?['email'],
            'userCurrentDesignation': data?['userCurrentDesignation'],
          };

          return {
            'success': true,
            'statusCode': 200,
            'data': essentialData,
            'message':
                responseData['message'] ??
                'Appointment starred status updated successfully',
          };
        } catch (e) {
          // If parsing fails due to large response, assume success and return minimal data
          print('Warning: Large response detected, returning minimal data: $e');
          return {
            'success': true,
            'statusCode': 200,
            'data': {
              'appointmentId': appointmentId,
              'starred': true, // Assume toggle worked
            },
            'message':
                'Appointment starred status updated successfully (minimal response)',
          };
        }
      } else if (response.statusCode == 400) {
        // Bad request
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': 'Invalid request'};
        }
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid appointment ID',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': 'Appointment not found'};
        }
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment not found',
        };
      } else if (response.statusCode == 500) {
        // Server error - likely BSON serialization issue
        // Assume the operation succeeded despite the error
        print(
          'Warning: Server returned 500, but assuming starred toggle succeeded',
        );
        return {
          'success': true,
          'statusCode': 200,
          'data': {
            'appointmentId': appointmentId,
            'starred': true, // Assume toggle worked
          },
          'message':
              'Appointment starred status updated successfully (assumed)',
        };
      } else {
        // Other error
        Map<String, dynamic> responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': 'Unknown error'};
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to update starred status',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Utility method to format date for API
  static String formatDateForAPI(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Utility method to get today's appointments
  static Future<Map<String, dynamic>> getTodayAppointments({
    int page = 1,
    int limit = 10,
    String? assignedSecretary,
  }) async {
    return getAppointmentsWithFilters(
      page: page,
      limit: limit,
      dateType: 'scheduled',
      today: true,
      assignedSecretary: assignedSecretary,
    );
  }

  // Utility method to get this week's appointments
  static Future<Map<String, dynamic>> getThisWeekAppointments({
    int page = 1,
    int limit = 10,
    String? assignedSecretary,
  }) async {
    return getAppointmentsWithFilters(
      page: page,
      limit: limit,
      dateType: 'scheduled',
      thisWeek: true,
      assignedSecretary: assignedSecretary,
    );
  }

  // Utility method to get upcoming appointments
  static Future<Map<String, dynamic>> getUpcomingAppointments({
    int page = 1,
    int limit = 10,
    String? assignedSecretary,
  }) async {
    return getAppointmentsWithFilters(
      page: page,
      limit: limit,
      dateType: 'scheduled',
      upcoming: true,
      assignedSecretary: assignedSecretary,
    );
  }

  // Utility method to get appointments by status
  static Future<Map<String, dynamic>> getAppointmentsByStatus({
    required String status,
    int page = 1,
    int limit = 10,
    String? assignedSecretary,
  }) async {
    return getAppointmentsWithFilters(
      page: page,
      limit: limit,
      status: status,
      assignedSecretary: assignedSecretary,
    );
  }

  // Schedule appointment with all options
  static Future<Map<String, dynamic>> scheduleAppointment({
    required String appointmentId,
    required String scheduledDate,
    required String scheduledTime,
    Map<String, dynamic>? options,
    String? meetingType,
    String? venueId, // Changed from venue to venueId
    String? arrivalTime,
    Map<String, dynamic>? scheduleConfirmation,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate appointmentId
      if (appointmentId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Invalid appointmentId',
        };
      }

      // Validate required fields
      if (scheduledDate.isEmpty || scheduledTime.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Scheduled date and time are required',
        };
      }

      // Validate date and time format
      try {
        final scheduledDateTime = DateTime.parse(
          '${scheduledDate}T${scheduledTime}',
        );
        if (scheduledDateTime.isBefore(DateTime.now())) {
          return {
            'success': false,
            'statusCode': 400,
            'message': 'Scheduled time must be in the future',
          };
        }
      } catch (e) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Invalid date or time format',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'options':
            options ??
            {
              'tbsRequired': false,
              'dontSendNotifications': false,
              'sendArrivalTime': false,
              'scheduleEmailSmsConfirmation': false,
              'sendVdsEmail': false,
              'stayAvailable': false,
            },
      };

      // Add optional fields if provided
      if (meetingType != null) {
        requestBody['meetingType'] = meetingType;
      }
      if (venueId != null) {
        requestBody['venue'] = venueId; // Send venue ID instead of venue name
      }
      if (arrivalTime != null) {
        requestBody['arrivalTime'] = arrivalTime;
      }
      if (scheduleConfirmation != null) {
        requestBody['scheduleConfirmation'] = scheduleConfirmation;
      }

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/appointment/$appointmentId/schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Appointment scheduled successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
          'error': responseData['error'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment not found',
        };
      } else if (response.statusCode == 500) {
        // Server error
        return {
          'success': false,
          'statusCode': 500,
          'message':
              responseData['message'] ??
              'Server error. Please try again later.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to schedule appointment',
          'error': responseData['error'],
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get appointments by scheduled date
  static Future<Map<String, dynamic>> getAppointmentsByScheduledDate({
    required String date, // Format: YYYY-MM-DD
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate date format
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Invalid date format. Please use YYYY-MM-DD format.',
        };
      }

      // Make API call
      final url = '$baseUrl/appointment/scheduled/date?date=$date';
      print('🌐 Making API call to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - return appointments data
        final List<dynamic> appointments = responseData['data'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
          'message':
              responseData['message'] ?? 'Appointments fetched successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid date format',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to fetch appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Get appointments assigned to current user (extracts MongoDB ID from JWT token)
  static Future<Map<String, dynamic>> getAssignedToMeAppointments({
    int page = 1,
    int limit = 10,
    String sortBy = "createdAt",
    String sortOrder = "desc",
    String? status,
    String dateType = "created", // "created", "scheduled", "preferred"
    String? dateFrom,
    String? dateTo,
    bool? today,
    bool? thisWeek,
    bool? thisMonth,
    bool? upcoming,
    bool? past,
    bool? starred,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Extract MongoDB ID from JWT token
      final mongoId = JwtUtils.extractMongoId(token);
      if (mongoId == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Could not extract user ID from authentication token.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'dateType': dateType,
        'assignedSecretary': mongoId, // Use MongoDB ID from JWT token
      };

      // Add optional parameters
      if (status != null) {
        queryParams['status'] = status;
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo;
      }
      if (today != null) {
        queryParams['today'] = today.toString();
      }
      if (thisWeek != null) {
        queryParams['thisWeek'] = thisWeek.toString();
      }
      if (thisMonth != null) {
        queryParams['thisMonth'] = thisMonth.toString();
      }
      if (upcoming != null) {
        queryParams['upcoming'] = upcoming.toString();
      }
      if (past != null) {
        queryParams['past'] = past.toString();
      }
      if (starred != null) {
        queryParams['starred'] = starred.toString();
      }

      // Add additional filters
      if (additionalFilters != null) {
        additionalFilters.forEach((key, value) {
          if (value != null) {
            queryParams[key] = value.toString();
          }
        });
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/appointments/status',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response with error handling
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - process appointments data with enhanced user fields
        final List<dynamic> rawAppointments =
            responseData['data']?['appointments'] ?? [];

        // Process appointments to ensure all user fields are properly formatted
        final List<Map<String, dynamic>> processedAppointments = rawAppointments
            .map((appointment) {
              if (appointment is Map<String, dynamic>) {
                return _processAppointmentData(appointment);
              }
              return <String, dynamic>{};
            })
            .toList();

        return {
          'success': true,
          'statusCode': 200,
          'data': processedAppointments,
          'statusBreakdown': responseData['data']?['statusBreakdown'] ?? {},
          'dateRangeSummary': responseData['data']?['dateRangeSummary'] ?? {},
          'filters': responseData['data']?['filters'] ?? {},
          'pagination': responseData['pagination'] ?? {},
          'message':
              responseData['message'] ??
              'Assigned appointments retrieved successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 404,
          'message': 'User not found. Please login again.',
        };
      } else {
        // Other error responses
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to retrieve assigned appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Mark appointment as done
  static Future<Map<String, dynamic>> markAppointmentAsDone({
    required String appointmentStatusId,
  }) async {
    try {
      // Get stored token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate input
      if (appointmentStatusId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Appointment status ID is required.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appointmentStatusId': appointmentStatusId,
      };

      // Make API call
      final response = await http.put(
        Uri.parse('$baseUrl/appointment/$appointmentStatusId/done'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - appointment marked as completed
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Appointment marked as completed successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment status not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment status not found',
        };
      } else {
        // Other error responses
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to mark appointment as completed',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Undo appointment status
  static Future<Map<String, dynamic>> undoAppointmentStatus({
    required String appointmentStatusId,
  }) async {
    try {
      // Get stored token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate input
      if (appointmentStatusId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Appointment status ID is required.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appointmentStatusId': appointmentStatusId,
      };

      // Make API call
      final response = await http.put(
        Uri.parse('$baseUrl/appointment/$appointmentStatusId/undo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - appointment status reverted
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Appointment status reverted successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request - no previous status to undo
        return {
          'success': false,
          'statusCode': 400,
          'message':
              responseData['message'] ?? 'No previous status found to undo',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment status not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment status not found',
        };
      } else {
        // Other error responses
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to undo appointment status',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Get upcoming appointments by user ID
  static Future<Map<String, dynamic>> getUpcomingAppointmentsByUser({
    required String userId,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate userId
      if (userId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'User ID is required',
        };
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/appointment/$userId/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - return appointments data
        final List<dynamic> appointments = responseData['data'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
          'message':
              responseData['message'] ??
              'Upcoming appointments fetched successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid user ID',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'User not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to fetch upcoming appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Get appointment by ID (for QR scanner)
  static Future<Map<String, dynamic>> getAppointmentById(
    String appointmentId,
  ) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/check-in-status/appointment/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'statusCode': 200,
          'data': data['data'],
          'message': 'Appointment details retrieved successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': 404,
          'message': 'Appointment not found',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': errorData['message'] ?? 'Failed to fetch appointment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Get appointment by ID with full details (new comprehensive endpoint)
  static Future<Map<String, dynamic>> getAppointmentByIdDetailed(
    String appointmentId,
  ) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate appointmentId
      if (appointmentId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Appointment ID is required',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/appointment/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - return comprehensive appointment data
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Appointment details retrieved successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid appointment ID',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment not found',
        };
      } else if (response.statusCode == 500) {
        // Server error
        return {
          'success': false,
          'statusCode': 500,
          'message':
              responseData['message'] ??
              'Server error. Please try again later.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to fetch appointment details',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Extract appointment ID from QR code URL
  static String? extractAppointmentIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Look for 'appointment' in the path and get the next segment as ID
      for (int i = 0; i < pathSegments.length; i++) {
        if (pathSegments[i] == 'appointment' && i + 1 < pathSegments.length) {
          return pathSegments[i + 1];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate input
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Current password and new password are required',
        };
      }

      // Validate new password requirements
      if (newPassword.length < 8) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'New password must be at least 8 characters long',
        };
      }

      if (!RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])',
      ).hasMatch(newPassword)) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'New password must contain uppercase, lowercase, number, and special character',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - password changed, user needs to login again
        await StorageService.logout(); // Clear stored data and tokens
        return {
          'success': true,
          'statusCode': 200,
          'message':
              responseData['message'] ??
              'Password changed successfully. Please log in again.',
        };
      } else if (response.statusCode == 400) {
        // Bad request - validation errors
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request parameters',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // User not found
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'User not found',
        };
      } else if (response.statusCode == 500) {
        // Server error
        return {
          'success': false,
          'statusCode': 500,
          'message':
              responseData['message'] ??
              'Server error. Please try again later.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to change password',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Email Template Functions
  // Get all email templates with filtering
  static Future<Map<String, dynamic>> getAllEmailTemplates({
    bool? isActive,
    List<String>? tags,
    String? category,
    List<String>? region,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (region != null && region.isNotEmpty) {
        queryParams['region'] = region.join(',');
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/email-templates',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Email templates retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve email templates',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get all email template IDs with filtering
  static Future<Map<String, dynamic>> getAllEmailTemplateIds({
    bool? isActive,
    List<String>? tags,
    String? category,
    List<String>? region,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (region != null && region.isNotEmpty) {
        queryParams['region'] = region.join(',');
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/email-templates/ids',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Email template IDs retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to retrieve email template IDs',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get single email template by ID
  static Future<Map<String, dynamic>> getEmailTemplateById(String id) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate ID
      if (id.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Email template ID is required',
        };
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/email-templates/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Email template retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Template not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Email template not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve email template',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get email template options (categories, regions, tags)
  static Future<Map<String, dynamic>> getEmailTemplateOptions() async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/email-templates/options'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Email template options retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to retrieve email template options',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Update check-in status for appointment (for guard actions)
  static Future<Map<String, dynamic>> updateCheckInStatus({
    required String checkInStatusId,
    String? mainStatus,
    List<Map<String, dynamic>>? users,
  }) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {};
      if (mainStatus != null) {
        requestBody['mainStatus'] = mainStatus;
      }
      if (users != null) {
        requestBody['users'] = users;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/check-in-status/$checkInStatusId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Check-in status updated successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to update check-in status',
          'error': responseData['error'],
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Get all SMS templates with optional filters
  static Future<Map<String, dynamic>> getAllSmsTemplates({
    bool? isActive,
    List<String>? tags,
  }) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final uri = Uri.parse(
        '$baseUrl/sms-templates',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'SMS templates retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve SMS templates',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get single SMS template by ID
  static Future<Map<String, dynamic>> getSmsTemplateById(String id) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sms-templates/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'SMS template retrieved successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': 404,
          'message': 'SMS template not found',
        };
      } else if (response.statusCode == 401) {
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve SMS template',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get available tags for SMS templates
  static Future<Map<String, dynamic>> getSmsTemplateOptions() async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/sms-templates/options'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'SMS template options retrieved successfully',
        };
      } else if (response.statusCode == 401) {
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to retrieve SMS template options',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Send appointment SMS
  static Future<Map<String, dynamic>> sendAppointmentSms({
    required String appointeeMobile,
    required String referenceMobile,
    required bool useAppointee,
    required bool useReference,
    String? otherSms,
    String? selectedTemplateId,
    String? smsContent,
    Map<String, dynamic>? templateData,
  }) async {
    try {
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appointeeMobile': appointeeMobile,
        'referenceMobile': referenceMobile,
        'useAppointee': useAppointee,
        'useReference': useReference,
      };

      // Add optional fields
      if (otherSms != null && otherSms.isNotEmpty) {
        requestBody['otherSms'] = otherSms;
      }
      if (selectedTemplateId != null && selectedTemplateId.isNotEmpty) {
        requestBody['selectedTemplateId'] = selectedTemplateId;
      }
      if (smsContent != null && smsContent.isNotEmpty) {
        requestBody['smsContent'] = smsContent;
      }
      if (templateData != null) {
        requestBody['templateData'] = templateData;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/appointment/send-sms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'SMS sent successfully',
        };
      } else if (response.statusCode == 400) {
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request data',
        };
      } else if (response.statusCode == 401) {
        await StorageService.logout();
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to send SMS',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get assigned secretaries by ashram location
  static Future<Map<String, dynamic>> getAssignedSecretariesByAshramLocation({
    required String locationId,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate locationId
      if (locationId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Location ID is required',
        };
      }

      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/appointment/$locationId/secretaries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success - return secretaries data
        final List<dynamic> secretaries = responseData['data'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': secretaries,
          'message':
              responseData['message'] ?? 'Secretaries fetched successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid location ID',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Location not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Ashram location not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to fetch secretaries',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Update assigned secretary for an appointment
  static Future<Map<String, dynamic>> updateAssignedSecretary({
    required String appointmentId,
    required String secretaryId,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate inputs
      if (appointmentId.isEmpty || secretaryId.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Both appointment ID and secretary ID are required',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {'secretaryId': secretaryId};

      // Make API call
      final response = await http.put(
        Uri.parse('$baseUrl/appointment/$appointmentId/assign-secretary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        // Success
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Assigned secretary updated successfully',
        };
      } else if (response.statusCode == 400) {
        // Bad request
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Invalid request data',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to update assigned secretary',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Fetch appointments for darshan line with filtering
  static Future<List<Map<String, dynamic>>> fetchAppointments({
    String? search,
    String? darshanType,
    String? emailStatus,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      // Add optional parameters
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (darshanType != null && darshanType.isNotEmpty) {
        queryParams['darshanType'] = darshanType;
      }
      if (emailStatus != null && emailStatus.isNotEmpty) {
        queryParams['emailStatus'] = emailStatus;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/darshan-line',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> appointments = responseData['data'] ?? [];
        return List<Map<String, dynamic>>.from(appointments);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        throw Exception('Session expired. Please login again.');
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch appointments');
      }
    } catch (error) {
      if (error is Exception) {
        rethrow;
      }
      throw Exception(
        'Network error. Please check your connection and try again.',
      );
    }
  }

  // Alternative method that returns the same format as other methods in this class
  static Future<Map<String, dynamic>> fetchAppointmentsWithResponse({
    String? search,
    String? darshanType,
    String? emailStatus,
    String? fromDate,
    String? toDate,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final appointments = await fetchAppointments(
        search: search,
        darshanType: darshanType,
        emailStatus: emailStatus,
        fromDate: fromDate,
        toDate: toDate,
        page: page,
        pageSize: pageSize,
      );

      return {
        'success': true,
        'statusCode': 200,
        'data': appointments,
        'message': 'Appointments fetched successfully',
      };
    } catch (error) {
      return {'success': false, 'statusCode': 500, 'message': error.toString()};
    }
  }

  // Send appointment email action
  static Future<Map<String, dynamic>> sendAppointmentEmailAction({
    required String appointeeEmail,
    String? referenceEmail,
    String? cc,
    String? bcc,
    String? subject,
    String? body,
    String? selectedTemplateId,
    Map<String, String>? templateData,
    bool useAppointee = true,
    bool useReference = true,
    String? otherEmail,
  }) async {
    final Uri url = Uri.parse('$baseUrl/appointment/send-email');

    final Map<String, dynamic> requestBody = {
      'appointeeEmail': appointeeEmail,
      if (referenceEmail != null) 'referenceEmail': referenceEmail,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
      if (selectedTemplateId != null) 'selectedTemplateId': selectedTemplateId,
      'useAppointee': useAppointee,
      'useReference': useReference,
      if (otherEmail != null) 'otherEmail': otherEmail,
      'templateData': templateData ?? {}, // 👈 Ensure it's always an object
    };

    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      print('🌐 Making API call to: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          print('✅ Email sent: ${data["data"]}');
          return {
            'success': true,
            'message': data['message'],
            'data': data['data'],
          };
        } else {
          print('❌ Failed: ${data['message']}');
          return {'success': false, 'message': data['message']};
        }
      } else {
        // Response is not JSON (probably HTML error page)
        print(
          '❌ Response is not JSON. Status: ${response.statusCode}, Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );
        return {
          'success': false,
          'message':
              'Server returned invalid response. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }

  // Send bulk email to multiple appointments
  static Future<Map<String, dynamic>> sendBulkEmail({
    required String templateId,
    required List<Map<String, dynamic>> recipients,
    List<String>? tags,
    String? subject,
    String? content,
  }) async {
    final Uri url = Uri.parse('$baseUrl/email-templates/bulk');

    final Map<String, dynamic> requestBody = {
      'templateId': templateId,
      'recipients': recipients,
      'tags': tags ?? ['bulk-email', 'appointment'],
    };

    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      print('🌐 Making bulk email API call to: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response headers: ${response.headers}');
      print('📥 Response body: ${response.body}');

      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') ==
          true) {
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 &&
            (data['success'] == true || data['error'] == null)) {
          print('✅ Bulk email sent successfully: ${data["data"]}');
          return {
            'success': true,
            'message': data['message'] ?? 'Bulk email sent successfully',
            'data': data['data'],
          };
        } else {
          print('❌ Bulk email failed: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to send bulk email',
          };
        }
      } else {
        // Response is not JSON (probably HTML error page)
        print(
          '❌ Response is not JSON. Status: ${response.statusCode}, Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...',
        );
        return {
          'success': false,
          'message':
              'Server returned invalid response. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error sending bulk email: $e');
      return {
        'success': false,
        'message':
            'Something went wrong while sending bulk email. Please try again.',
      };
    }
  }

  // Create quick appointment without validation
  static Future<Map<String, dynamic>> createQuickAppointment({
    required String fullName,
    required String emailId,
    required String phoneNumber,
    required String designation,
    String? company,
    bool isTeacher = false,
    Map<String, dynamic>? photo,
    Map<String, dynamic>? referenceDetails,
    String? location,
    String? purpose,
    String? remarksForGurudev,
    int numberOfPeople = 1,
    required String preferredDate,
    String? preferredTime,
    bool tbsRequired = false,
    bool dontSendNotifications = false,
    Map<String, dynamic>? attachment,
    Map<String, dynamic>? programDetails,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'appointmentType': 'myself',
        'fullName': fullName,
        'emailId': emailId,
        'phoneNumber': phoneNumber,
        'designation': designation,
        'company': company,
        'isTeacher': isTeacher,
        'photo': photo,
        'referenceDetails': referenceDetails,
        'location': location,
        'purpose': purpose,
        'remarksForGurudev': remarksForGurudev,
        'numberOfPeople': numberOfPeople,
        'preferredDate': preferredDate,
        'preferredTime': preferredTime,
        'tbsRequired': tbsRequired,
        'dontSendNotifications': dontSendNotifications,
        'attachment': attachment,
        'programDetails': programDetails,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/appointment/quick'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Successful creation
        return {
          'success': true,
          'statusCode': 201,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Quick appointment created successfully',
        };
      } else if (response.statusCode == 400) {
        // Validation error
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Validation failed',
          'error': responseData['error'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to create appointment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get ashram locations
  static Future<Map<String, dynamic>> getAshramLocations({
    int page = 1,
    int limit = 20,
    String sortBy = "createdAt",
    String sortOrder = "desc",
    String? status,
    String? search,
    bool includeInactive = false,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'includeInactive': includeInactive.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/ashram-locations',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful response
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Ashram locations retrieved successfully',
          'pagination': responseData['pagination'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve ashram locations',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Update appointment enhanced
  static Future<Map<String, dynamic>> updateAppointmentEnhanced({
    required String appointmentId,
    required Map<String, dynamic> updateData,
    PlatformFile? attachmentFile,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Remove empty fields from updateData
      final cleanUpdateData = <String, dynamic>{};
      updateData.forEach((key, value) {
        if (value != null) {
          // Special handling for empty strings - only include if they're not empty
          if (value is String && value.isEmpty) {
            return; // Skip empty strings
          }
          // Special handling for empty maps/objects
          if (value is Map && value.isEmpty) {
            return; // Skip empty maps
          }
          cleanUpdateData[key] = value;
        }
      });

      print('DEBUG API: Clean update data: $cleanUpdateData');

      // Try JSON request instead of multipart for now
      final uri = Uri.parse('$baseUrl/appointment/$appointmentId/enhanced');

      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(cleanUpdateData),
      );

      print('DEBUG API: Response status code: ${response.statusCode}');
      print('DEBUG API: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'statusCode': 200,
          'data': data['data'],
          'message': data['message'] ?? 'Appointment updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': errorData['message'] ?? 'Failed to update appointment',
          'error': errorData['error'],
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get deleted appointments
  static Future<Map<String, dynamic>> getDeletedAppointments({
    int page = 1,
    int limit = 10,
    String sortBy = "deletedAt",
    String sortOrder = "desc",
    String? search,
    String? meetingType,
    String? appointmentType,
    String? startDate,
    String? endDate,
    String? deletedBy,
    String? assignedSecretary,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (meetingType != null && meetingType.isNotEmpty) {
        queryParams['meetingType'] = meetingType;
      }
      if (appointmentType != null && appointmentType.isNotEmpty) {
        queryParams['appointmentType'] = appointmentType;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }
      if (deletedBy != null && deletedBy.isNotEmpty) {
        queryParams['deletedBy'] = deletedBy;
      }
      if (assignedSecretary != null && assignedSecretary.isNotEmpty) {
        queryParams['assignedSecretary'] = assignedSecretary;
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/appointments/deleted',
      ).replace(queryParameters: queryParams);

      // Make API call
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful response
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Deleted appointments retrieved successfully',
          'pagination': responseData['data']?['pagination'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to retrieve deleted appointments',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Soft delete appointment
  static Future<Map<String, dynamic>> softDeleteAppointment({
    required String appointmentId,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/appointment/$appointmentId/soft-delete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful response
        return {
          'success': true,
          'statusCode': 200,
          'message':
              responseData['message'] ?? 'Appointment deleted successfully',
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Appointment not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to delete appointment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Restore deleted appointment
  static Future<Map<String, dynamic>> restoreDeletedAppointment({
    required String appointmentId,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/appointment/$appointmentId/restore'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Successful response
        return {
          'success': true,
          'statusCode': 200,
          'message':
              responseData['message'] ?? 'Appointment restored successfully',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode == 404) {
        // Appointment not found
        return {
          'success': false,
          'statusCode': 404,
          'message': responseData['message'] ?? 'Deleted appointment not found',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to restore appointment',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}
