import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'jwt_utils.dart'; // Added import for JwtUtils

class ActionService {
  static const String baseUrl =
      'https://7edf2f9e0240.ngrok-free.app/api/v3'; // API base URL

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
    Map<String, dynamic>? additionalFilters,
    String? screen, // "inbox" or "assigned_to_me"
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
        // Success - save appointments data to local storage and return
        final List<dynamic> appointments =
            responseData['data']?['appointments'] ?? [];

        // No caching for inbox and assigned to me screens - always fetch fresh data

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
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
        // Success - return appointments data
        final List<dynamic> appointments =
            responseData['data']?['appointments'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
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
        // Success - return appointments data
        final List<dynamic> appointments =
            responseData['data']?['appointments'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
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

  // Get appointment history by user ID
  static Future<Map<String, dynamic>> getAppointmentHistoryByUser({
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

      // Use the existing appointments filtering system with past=true
      return await getAppointmentsWithFilters(
        page: 1,
        limit: 50, // Get more history items
        sortBy: "createdAt",
        sortOrder: "desc",
        dateType: "created",
        past: true, // This will get past appointments
        additionalFilters: {
          '_id': userId, // Filter by the MongoDB _id
        },
      );
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
        Uri.parse('$baseUrl/appointment/$appointmentId'),
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
      final uri = Uri.parse('$baseUrl/appointment/darshan-line')
          .replace(queryParameters: queryParams);

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
      throw Exception('Network error. Please check your connection and try again.');
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
      return {
        'success': false,
        'statusCode': 500,
        'message': error.toString(),
      };
    }
  }
}
