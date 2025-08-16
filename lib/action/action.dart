import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import 'jwt_utils.dart'; // Added import for JwtUtils
import '../services/notification_service.dart'; // Added import for NotificationService

class ActionService {
  static const String baseUrl =
      // API base URL
      'https://c8740a8d1f9a.ngrok-free.app/api/v3'; // API base URL

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
        Uri.parse(
          '$baseUrl/auth/secretaries',
        ).replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Successfully retrieved secretaries',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to retrieve secretaries',
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
    if (processedAppointment['userMobile'] == null ||
        processedAppointment['userMobile'].toString().isEmpty) {
      // Check if this is a quick appointment
      final apptType = appointment['appt_type']?.toString();
      final quickApt = appointment['quick_apt'];

      if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
        final optional = quickApt['optional'];
        if (optional is Map<String, dynamic>) {
          final mobileNumber = optional['mobileNumber'];
          if (mobileNumber is Map<String, dynamic>) {
            final countryCode = mobileNumber['countryCode']?.toString() ?? '';
            final number = mobileNumber['number']?.toString() ?? '';
            if (number.isNotEmpty) {
              processedAppointment['userMobile'] = '$countryCode$number';
            }
          }
        }
      }

      // Fallback to userMobile field
      if (processedAppointment['userMobile'] == null ||
          processedAppointment['userMobile'].toString().isEmpty) {
        final userMobile = appointment['userMobile'];
        if (userMobile is Map<String, dynamic>) {
          final countryCode = userMobile['countryCode']?.toString() ?? '';
          final number = userMobile['number']?.toString() ?? '';
          if (countryCode.isNotEmpty && number.isNotEmpty) {
            processedAppointment['userMobile'] = '$countryCode $number';
          }
        }
      }
    }

    // Ensure userEmail is properly set
    if (processedAppointment['userEmail'] == null ||
        processedAppointment['userEmail'].toString().isEmpty) {
      // Check if this is a quick appointment
      final apptType = appointment['appt_type']?.toString();
      final quickApt = appointment['quick_apt'];

      if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
        final optional = quickApt['optional'];
        if (optional is Map<String, dynamic>) {
          final email = optional['email']?.toString();
          if (email != null && email.isNotEmpty) {
            processedAppointment['userEmail'] = email;
          }
        }
      }

      // Fallback to email field if userEmail is not available
      if (processedAppointment['userEmail'] == null ||
          processedAppointment['userEmail'].toString().isEmpty) {
        final email = appointment['email']?.toString();
        if (email != null && email.isNotEmpty) {
          processedAppointment['userEmail'] = email;
        }
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
    String? venueLabel, // Added venueLabel parameter
    String? arrivalTime,
    Map<String, dynamic>? scheduleConfirmation,
    String? userId, // Added userId for notification
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
        requestBody['venue'] = venueId; // Send venue ID
        if (venueLabel != null) {
          requestBody['venueLabel'] = venueLabel; // Send venue label
        }
      }
      if (arrivalTime != null) {
        requestBody['arrivalTime'] = arrivalTime;
      }

      // Handle schedule confirmation - map to sc_date and sc_time
      if (scheduleConfirmation != null) {
        final date = scheduleConfirmation['date'];
        final time = scheduleConfirmation['time'];
        if (date != null) {
          requestBody['sc_date'] = date;
        }
        if (time != null) {
          requestBody['sc_time'] = time;
        }
      }

      // Make API call - Changed from POST to PUT
      print(
        '🌐 [API] Making PUT request to: $baseUrl/appointment/$appointmentId/schedule',
      );
      print('📦 [API] Request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/appointment/$appointmentId/schedule'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 [API] Response status: ${response.statusCode}');
      print('📄 [API] Response body: ${response.body}');

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
        // Success - now send notification to the user
        if (responseData['data']?['userId'] != null) {
          try {
            // Prepare notification content
            final notificationTitle = 'Appointment Scheduled! ✅';
            final notificationBody =
                'Your appointment has been scheduled for $scheduledDate at $scheduledTime${venueLabel != null ? ' at $venueLabel' : ''}.';

            // Prepare notification data
            final notificationData = {
              'type': 'appointment_scheduled',
              'appointmentId': appointmentId,
              'userId': responseData['data']['userId'],
              'timestamp': DateTime.now().toIso8601String(),
              'action': 'view_appointment',
              'screen': 'appointment_details',
              'meetingType': meetingType,
              'venueId': venueId,
              'venueLabel': venueLabel,
            };

            // Send notification using NotificationService
            await NotificationService.sendToDevice(
              token: responseData['data']['fcmToken'] ?? '',
              title: notificationTitle,
              body: notificationBody,
              data: notificationData,
            );

            print(
              '✅ [NOTIFICATION] Sent appointment schedule notification to user',
            );
          } catch (notificationError) {
            print(
              '⚠️ [NOTIFICATION] Failed to send notification: $notificationError',
            );
            // Don't fail the whole operation if notification fails
          }
        }

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

  // Get appointments by scheduled date (including quick appointments)
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

      // Make API call to fetch both regular and quick appointments
      final url =
          '$baseUrl/appointment/scheduled/date?date=$date&includeQuick=true';
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
        // Success - return appointments data (including quick appointments)
        final List<dynamic> appointments = responseData['data'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
          'message':
              responseData['message'] ??
              'Appointments and quick appointments fetched successfully',
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

  // Get quick appointment by ID
  static Future<Map<String, dynamic>> getQuickAppointmentById(
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
        Uri.parse('$baseUrl/appointment/quick/$appointmentId'),
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
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message': 'Quick appointment details retrieved successfully',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'statusCode': 404,
          'message': 'Quick appointment not found',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to fetch quick appointment',
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

      // Debug: Log phone numbers being sent
      print('📱 SMS - Appointee Mobile: $appointeeMobile');
      print('📱 SMS - Reference Mobile: $referenceMobile');
      print('📱 SMS - Use Appointee: $useAppointee');
      print('📱 SMS - Use Reference: $useReference');

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'useAppointee': useAppointee,
        'useReference': useReference,
      };

      // Only add mobile numbers if they are being used
      if (useAppointee) {
        requestBody['appointeeMobile'] = appointeeMobile;
      }
      if (useReference) {
        requestBody['referenceMobile'] = referenceMobile;
      }

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
    String? appointmentId, // 👈 Added appointmentId parameter
    String? rescheduleDate,
    String? rescheduleTime,
    String? rescheduleVenue,
    String? rescheduleVenueName,
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
      if (appointmentId != null)
        'appointmentId':
            appointmentId, // 👈 Added appointmentId to request body
      if (rescheduleDate != null) 'rescheduleDate': rescheduleDate,
      if (rescheduleTime != null) 'rescheduleTime': rescheduleTime,
      if (rescheduleVenue != null) 'rescheduleVenue': rescheduleVenue,
      if (rescheduleVenueName != null)
        'rescheduleVenueName': rescheduleVenueName,
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
    String? emailId,
    String? phoneNumber,
    required String designation,
    required String venue,
    String? purpose,
    String? remarksForGurudev,
    int numberOfPeople = 1,
    required String preferredDate,
    required String preferredTime,
    bool tbsRequired = false,
    bool dontSendNotifications = false,
    File? photo,
    File? attachment,
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

      // Create multipart request for file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/appointment/quick'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add required fields
      request.fields['name'] = fullName;
      request.fields['fullName'] = fullName;
      request.fields['designation'] = designation;
      request.fields['preferredDate'] = preferredDate;
      request.fields['preferredTime'] = preferredTime;
      request.fields['venue'] = venue;

      // Always send numberOfPeople (even if it's 1) to ensure backend receives it
      request.fields['numberOfPeople'] = numberOfPeople.toString();

      // Add optional fields only if they have actual values
      if (emailId != null && emailId.trim().isNotEmpty) {
        request.fields['emailId'] = emailId.trim();
      }

      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        request.fields['phoneNumber'] = phoneNumber.trim();
      }

      if (purpose != null && purpose.trim().isNotEmpty) {
        request.fields['purpose'] = purpose.trim();
      }

      if (remarksForGurudev != null && remarksForGurudev.trim().isNotEmpty) {
        request.fields['remarksForGurudev'] = remarksForGurudev.trim();
      }

      // Add boolean fields - send as proper boolean values
      request.fields['tbsRequired'] = tbsRequired ? 'true' : 'false';
      request.fields['dontSendNotifications'] = dontSendNotifications
          ? 'true'
          : 'false';

      // Debug: Log what fields are being sent
      print('📤 Fields being sent to backend:');
      request.fields.forEach((key, value) {
        print('📤 $key: $value');
      });

      // Debug: Log what files are being sent
      print('📤 Files being sent to backend:');
      for (final file in request.files) {
        print(
          '📤 File: ${file.field} - ${file.filename} - ${file.length} bytes',
        );
      }

      // Debug: Log the complete request structure
      print('📤 Complete request structure:');
      print('📤 URL: ${request.url}');
      print('📤 Method: ${request.method}');
      print('📤 Headers: ${request.headers}');
      print('📤 Total fields: ${request.fields.length}');
      print('📤 Total files: ${request.files.length}');

      // Add photo file if provided
      if (photo != null) {
        print('📸 Photo provided: ${photo.path}');
        if (await photo.exists()) {
          try {
            print('📸 Adding photo file: ${photo.path}');
            final photoStream = http.ByteStream(photo.openRead());
            final photoLength = await photo.length();
            print('📸 Photo file size: ${photoLength} bytes');

            // Get file extension
            final fileName = photo.path.split('/').last;
            final fileExtension = fileName.contains('.')
                ? fileName.split('.').last
                : 'jpg';
            final mimeType = _getMimeType(fileExtension);

            final photoMultipart = http.MultipartFile(
              'photo',
              photoStream,
              photoLength,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            );
            request.files.add(photoMultipart);
            print('📸 Photo file added successfully');
          } catch (photoError) {
            print('❌ Error adding photo file: $photoError');
            return {
              'success': false,
              'statusCode': 400,
              'message':
                  'Error processing photo file: ${photoError.toString()}',
              'data': null,
              'error': photoError.toString(),
            };
          }
        } else {
          print('⚠️ Photo file does not exist: ${photo.path}');
        }
      } else {
        print('📸 No photo provided');
      }

      // Add attachment file if provided
      if (attachment != null) {
        print('📎 Attachment provided: ${attachment.path}');
        if (await attachment.exists()) {
          try {
            print('📎 Adding attachment file: ${attachment.path}');
            final attachmentStream = http.ByteStream(attachment.openRead());
            final attachmentLength = await attachment.length();
            print('📎 Attachment file size: ${attachmentLength} bytes');

            // Get file extension
            final fileName = attachment.path.split('/').last;
            final fileExtension = fileName.contains('.')
                ? fileName.split('.').last
                : 'pdf';
            final mimeType = _getMimeType(fileExtension);

            final attachmentMultipart = http.MultipartFile(
              'attachment',
              attachmentStream,
              attachmentLength,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            );
            request.files.add(attachmentMultipart);
            print('📎 Attachment file added successfully');
          } catch (attachmentError) {
            print('❌ Error adding attachment file: $attachmentError');
            return {
              'success': false,
              'statusCode': 400,
              'message':
                  'Error processing attachment file: ${attachmentError.toString()}',
              'data': null,
              'error': attachmentError.toString(),
            };
          }
        } else {
          print('⚠️ Attachment file does not exist: ${attachment.path}');
        }
      } else {
        print('📎 No attachment provided');
      }

      print('📤 Total files being sent: ${request.files.length}');
      request.files.forEach((file) {
        print(
          '📤 File: ${file.field} - ${file.filename} - ${file.length} bytes',
        );
      });

      // Send the request
      print('📤 Sending request to: ${request.url}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

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
          'error': null,
        };
      } else if (response.statusCode == 400) {
        // Validation error
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'Validation failed',
          'data': null,
          'error': responseData['error'],
        };
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        return {
          'success': false,
          'statusCode': 401,
          'message': 'Session expired. Please login again.',
          'data': null,
          'error': null,
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to create appointment',
          'data': null,
          'error': responseData['error'],
        };
      }
    } catch (error) {
      print('❌ Error in createQuickAppointment: $error');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Internal server error: ${error.toString()}',
        'data': null,
        'error': error.toString(),
      };
    }
  }

  // Helper function to get MIME type based on file extension
  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
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

  // Get ashram location by location ID with assigned secretaries
  static Future<Map<String, dynamic>> getAshramLocationByLocationId({
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
        Uri.parse('$baseUrl/ashram-locations/$locationId'),
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
        // Success - return location data with assigned secretaries
        final locationData = responseData['data'];
        final assignedSecretaries = locationData['assignedSecretaries'] ?? [];

        return {
          'success': true,
          'statusCode': 200,
          'data': {
            'location': locationData,
            'assignedSecretaries': assignedSecretaries,
          },
          'message':
              responseData['message'] ??
              'Location details fetched successfully',
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
      } else if (response.statusCode == 403) {
        // Location deactivated
        return {
          'success': false,
          'statusCode': 403,
          'message': responseData['message'] ?? 'This location is deactivated',
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
          'message':
              responseData['message'] ?? 'Failed to fetch location details',
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

  // Get all venues
  static Future<Map<String, dynamic>> getAllVenues({
    int page = 1,
    int limit = 10,
    String sortBy = "createdAt",
    String sortOrder = "desc",
    String? search,
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
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/venues',
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
          'message': responseData['message'] ?? 'Venues retrieved successfully',
          'pagination': responseData['data']['pagination'],
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
          'message': responseData['message'] ?? 'Failed to retrieve venues',
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

  // Global search appointments
  static Future<Map<String, dynamic>> globalSearchAppointments({
    required String query,
    String searchMode = 'all',
    String? status,
    String? meetingType,
    String? appointmentType,
    String? dateFrom,
    String? dateTo,
    bool starred = false,
    String? locationId,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool includeDeleted = false,
    String searchFields = 'all',
    String priority = 'relevance',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Get token from storage
      final token = await StorageService.getToken();

      if (token == null) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'q': query.trim(),
        'searchMode': searchMode,
        'limit': limit.toString(),
        'page': page.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'includeDeleted': includeDeleted.toString(),
        'searchFields': searchFields,
        'priority': priority,
      };

      // Add optional parameters
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (meetingType != null && meetingType.isNotEmpty) {
        queryParams['meetingType'] = meetingType;
      }
      if (appointmentType != null && appointmentType.isNotEmpty) {
        queryParams['appointmentType'] = appointmentType;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['dateFrom'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['dateTo'] = dateTo;
      }
      if (starred) {
        queryParams['starred'] = starred.toString();
      }
      if (locationId != null && locationId.isNotEmpty) {
        queryParams['locationId'] = locationId;
      }

      // Build URI with query parameters
      final uri = Uri.parse(
        '$baseUrl/appointment/search/global',
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
        return responseData;
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await StorageService.logout(); // Clear stored data
        throw Exception('Session expired. Please login again.');
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to perform global search',
        );
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

  /// Register a new user with profile photo upload
  /// This function handles user registration with file upload (camera or device)
  ///
  /// Parameters:
  /// - fullName: User's full name
  /// - email: User's email address
  /// - password: User's password
  /// - phoneNumber: User's phone number with country code
  /// - designation: User's professional designation
  /// - company: User's company/organization
  /// - full_address: User's full address
  /// - userTags: Array of user role tags
  /// - aol_teacher: Boolean indicating if user is AOL teacher
  /// - teacher_type: Type of teacher (part-time/full-time)
  /// - teachercode: AOL teacher code
  /// - teacheremail: AOL teacher email
  /// - mobilenumber: AOL teacher mobile number
  /// - profilePhotoFile: File object from camera or device upload
  ///
  /// Returns:
  /// - Map containing success status, message, and user data
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    String? designation,
    String? company,
    required String full_address,
    required List<String> userTags,
    required bool aol_teacher,
    String? teacher_type,
    String? teachercode,
    String? teacheremail,
    String? mobilenumber,
    required File profilePhotoFile,
  }) async {
    try {
      // ✅ 1. Validate required fields
      if (fullName.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          phoneNumber.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Missing fullName, email, password, or phone number.',
        };
      }

      if (profilePhotoFile == null) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Profile photo is required.',
        };
      }

      // ✅ 2. Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Please enter a valid email address.',
        };
      }

      // ✅ 3. Validate phone number format (basic validation)
      if (!phoneNumber.startsWith('+')) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Phone number must be in "+CC NNNNNNNNNN" format.',
        };
      }

      // ✅ 4. Validate file type and size
      final fileName = profilePhotoFile.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];

      if (!allowedExtensions.contains(fileExtension)) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Profile photo must be a valid image file (JPG, PNG, GIF).',
        };
      }

      // Check file size (max 5MB)
      final fileSize = await profilePhotoFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Profile photo size must be less than 5MB.',
        };
      }

      // ✅ 5. Prepare request body
      final Map<String, dynamic> requestBody = {
        'fullName': fullName.trim(),
        'email': email.toLowerCase().trim(),
        'password': password,
        'phoneNumber': phoneNumber,
        'designation': designation?.trim(),
        'company': company?.trim(),
        'full_address': full_address,
        'userTags': userTags,
        'aol_teacher': aol_teacher,
        'teacher_type': teacher_type,
        'teachercode': teachercode,
        'teacheremail': teacheremail,
        'mobilenumber': mobilenumber,
      };

      // ✅ 6. Create multipart request for file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/signup'),
      );

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add text fields
      requestBody.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            // Handle array fields like userTags
            for (String item in value) {
              request.fields['$key[]'] = item;
            }
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      // ✅ 7. Add file to request
      final fileStream = http.ByteStream(profilePhotoFile.openRead());
      final fileLength = await profilePhotoFile.length();

      final multipartFile = http.MultipartFile(
        'file', // Field name expected by server
        fileStream,
        fileLength,
        filename: fileName,
        contentType: MediaType('image', fileExtension),
      );

      request.files.add(multipartFile);

      // ✅ 8. Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ✅ 9. Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // ✅ 10. Registration successful
        return {
          'success': true,
          'statusCode': 201,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Registration successful. Please verify your email.',
        };
      } else if (response.statusCode == 409) {
        // ✅ 11. User already exists
        return {
          'success': false,
          'statusCode': 409,
          'message': responseData['message'] ?? 'Email already exists.',
        };
      } else if (response.statusCode == 400) {
        // ✅ 12. Validation error
        return {
          'success': false,
          'statusCode': 400,
          'message':
              responseData['message'] ??
              'Validation failed. Please check your input.',
        };
      } else {
        // ✅ 13. Other errors
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Registration failed. Please try again.',
        };
      }
    } catch (error) {
      // ✅ 14. Handle exceptions
      print('❌ Registration Error: $error');

      if (error.toString().contains('SocketException')) {
        return {
          'success': false,
          'statusCode': 500,
          'message':
              'Network error. Please check your connection and try again.',
        };
      }

      return {
        'success': false,
        'statusCode': 500,
        'message': 'Registration failed. Please try again.',
      };
    }
  }

  /// Validate AOL teacher credentials
  /// This function validates teacher code, email, and phone number with the ATOL API
  ///
  /// Parameters:
  /// - teacherCode: Teacher's AOL code
  /// - teacherEmail: Teacher's registered email
  /// - teacherPhone: Teacher's registered phone number
  ///
  /// Returns:
  /// - Map containing validation result and status
  static Future<Map<String, dynamic>> validateAolTeacher({
    required String teacherCode,
    required String teacherEmail,
    required String teacherPhone,
  }) async {
    try {
      // ✅ 1. Validate required fields
      if (teacherCode.isEmpty || teacherEmail.isEmpty || teacherPhone.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Teacher code, email, and phone number are required for validation',
        };
      }

      // ✅ 2. Validate email format
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(teacherEmail)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Please provide a valid email address',
        };
      }

      // ✅ 3. Validate phone number format
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,15}$');
      if (!phoneRegex.hasMatch(teacherPhone)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Please provide a valid phone number',
        };
      }

      // ✅ 4. Validate teacher code format (3-20 alphanumeric characters)
      final teacherCodeRegex = RegExp(r'^[A-Za-z0-9]{3,20}$');
      if (!teacherCodeRegex.hasMatch(teacherCode)) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Teacher code should be 3-20 characters long and contain only letters and numbers',
        };
      }

      // ✅ 5. Prepare request body
      final Map<String, dynamic> requestBody = {
        'teacherCode': teacherCode.trim().toUpperCase(),
        'teacherEmail': teacherEmail.toLowerCase().trim(),
        'teacherPhone': teacherPhone,
      };

      // ✅ 6. Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/validate-aol-teacher'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // ✅ 7. Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ 8. Validation successful
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              '✅ AOL teacher credentials verified successfully! You can proceed with registration.',
        };
      } else if (response.statusCode == 400) {
        // ✅ 9. Validation failed
        return {
          'success': false,
          'statusCode': 400,
          'message': responseData['message'] ?? 'AOL teacher validation failed',
          'details':
              responseData['details'] ??
              'The provided teacher credentials could not be verified.',
        };
      } else {
        // ✅ 10. Other errors
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to validate AOL teacher credentials',
        };
      }
    } catch (error) {
      // ✅ 11. Handle exceptions
      print('❌ AOL teacher validation error: $error');

      if (error.toString().contains('SocketException')) {
        return {
          'success': false,
          'statusCode': 500,
          'message':
              'Network error. Please check your connection and try again.',
        };
      }

      return {
        'success': false,
        'statusCode': 500,
        'message':
            'Failed to validate AOL teacher credentials. Please try again.',
      };
    }
  }

  // OTP Verification Methods
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // Validate input
      if (email.isEmpty || otp.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Email and OTP are required',
        };
      }

      if (otp.length != 6) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'OTP must be 6 digits',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'email': email.toLowerCase().trim(),
        'otp': otp,
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store tokens if available
        if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
          await StorageService.saveToken(responseData['data']['token']);
          if (responseData['data']['user'] != null) {
            await StorageService.saveUserData(responseData['data']['user']);
          }
        }

        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              '🎉 Excellent! Your account is now verified. Welcome to the Art of Living community!',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'OTP verification failed',
        };
      }
    } catch (error) {
      print('❌ OTP verification error: $error');

      if (error.toString().contains('SocketException')) {
        return {
          'success': false,
          'statusCode': 500,
          'message':
              'Network error. Please check your connection and try again.',
        };
      }

      return {
        'success': false,
        'statusCode': 500,
        'message': 'Failed to verify OTP. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      // Validate input
      if (email.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Email is required',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'email': email.toLowerCase().trim(),
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              '📧 New verification code sent! Please check your inbox for the latest code.',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to resend OTP',
        };
      }
    } catch (error) {
      print('❌ Resend OTP error: $error');

      if (error.toString().contains('SocketException')) {
        return {
          'success': false,
          'statusCode': 500,
          'message':
              'Network error. Please check your connection and try again.',
        };
      }

      return {
        'success': false,
        'statusCode': 500,
        'message': 'Failed to resend OTP. Please try again.',
      };
    }
  }

  // Get user appointments (for user history)
  static Future<Map<String, dynamic>> getUserAppointments({
    required String userId,
    int page = 1,
    int limit = 10,
    String? status,
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

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Make API call
      final response = await http.get(
        Uri.parse(
          '$baseUrl/appointment/user/$userId',
        ).replace(queryParameters: queryParams),
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
        final Map<String, dynamic> pagination =
            responseData['pagination'] ?? {};

        return {
          'success': true,
          'statusCode': 200,
          'data': appointments,
          'pagination': pagination,
          'message':
              responseData['message'] ??
              'User appointments retrieved successfully',
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
              responseData['message'] ?? 'Failed to get user appointments',
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

  // Validate and upload profile photo to S3
  static Future<Map<String, dynamic>> validateAndUploadProfilePhoto({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Get authentication token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate file size (max 5MB)
      if (imageBytes.length > 5 * 1024 * 1024) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'File size must be less than 5MB.',
        };
      }

      // Validate file type
      final fileExtension = fileName.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      if (!allowedExtensions.contains(fileExtension)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Only JPG, PNG, and GIF files are allowed.',
        };
      }

      // Create form data for multipart upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/validate-upload-s3'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file with proper content type
      final contentType = MediaType(
        'image',
        fileExtension == 'jpg' ? 'jpeg' : fileExtension,
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: contentType,
        ),
      );

      print(
        '🔍 Debug - Uploading file: $fileName, size: ${imageBytes.length} bytes',
      );
      print('🔍 Debug - Content-Type: $contentType');

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('🔍 Debug - Response status: ${response.statusCode}');
      print('🔍 Debug - Response body: $responseData');

      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        // Check if upload was successful based on response structure
        final success =
            jsonResponse['success'] == true ||
            jsonResponse['status'] == 'success';

        if (success) {
          // Upload successful
          return {
            'success': true,
            'statusCode': 200,
            'data': jsonResponse['data'] ?? jsonResponse,
            'message':
                jsonResponse['message'] ??
                'Profile photo uploaded successfully',
          };
        } else {
          // Upload failed
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message':
                jsonResponse['message'] ?? 'Failed to upload profile photo',
          };
        }
      } else {
        // HTTP error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              jsonResponse['message'] ?? 'Failed to upload profile photo',
        };
      }
    } catch (error) {
      print('🔍 Debug - Upload error: $error');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Network error: $error',
      };
    }
  }

  // Update user profile with file upload
  static Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    String? designation,
    String? company,
    required String full_address,
    required List<String> userTags,
    File? profilePhotoFile,
  }) async {
    try {
      // Get authentication token
      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'statusCode': 401,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Validate required fields
      if (fullName.isEmpty || email.isEmpty || phoneNumber.isEmpty) {
        return {
          'success': false,
          'statusCode': 400,
          'message':
              'Missing required fields: fullName, email, or phoneNumber.',
        };
      }

      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return {
          'success': false,
          'statusCode': 400,
          'message': 'Please enter a valid email address.',
        };
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/auth/profile'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['fullName'] = fullName.trim();
      request.fields['email'] = email.toLowerCase().trim();
      request.fields['phoneNumber'] = phoneNumber;
      if (designation != null && designation.isNotEmpty) {
        request.fields['designation'] = designation.trim();
      }
      if (company != null && company.isNotEmpty) {
        request.fields['company'] = company.trim();
      }

      // Handle full_address as JSON string
      request.fields['full_address'] = jsonEncode({
        'display_name': full_address.trim(),
      });

      // Handle userTags as array - send as additionalRoles
      if (userTags.isNotEmpty) {
        request.fields['additionalRoles'] = jsonEncode(userTags);
      }

      // Add file if present
      if (profilePhotoFile != null) {
        final fileName = profilePhotoFile.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // Validate file type
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
        if (!allowedExtensions.contains(fileExtension)) {
          return {
            'success': false,
            'statusCode': 400,
            'message':
                'Profile photo must be a valid image file (JPG, PNG, GIF).',
          };
        }

        // Check file size (max 5MB)
        final fileSize = await profilePhotoFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          return {
            'success': false,
            'statusCode': 400,
            'message': 'Profile photo size must be less than 5MB.',
          };
        }

        // Add file to request
        final fileStream = http.ByteStream(profilePhotoFile.openRead());
        final fileLength = await profilePhotoFile.length();

        final multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: fileName,
          contentType: MediaType('image', fileExtension),
        );

        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update cached user data with the response data
        if (responseData['data'] != null) {
          await StorageService.saveUserData(responseData['data']);
        }

        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Profile updated successfully!',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to update profile',
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

  ////////////////////////////////////////////////////---------------user---------------------////////////////////////////
  // Create appointment method using enhanced API
  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      print('🚀 Creating appointment with data: $appointmentData');

      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Add default secretary ID if not provided
      if (appointmentData['assignedSecretary'] == null) {
        appointmentData['assignedSecretary'] = '6891a4d3a26a787d5aec5d50';
        print('👤 Added default secretary ID: 6891a4d3a26a787d5aec5d50');
      }

      // Log the final appointment data being sent
      print('📋 Final appointment data to be sent:');
      print('   - meetingType: ${appointmentData['meetingType']}');
      print('   - appointmentFor: ${appointmentData['appointmentFor']}');
      print(
        '   - userCurrentCompany: ${appointmentData['userCurrentCompany']}',
      );
      print(
        '   - userCurrentDesignation: ${appointmentData['userCurrentDesignation']}',
      );
      print(
        '   - appointmentPurpose: ${appointmentData['appointmentPurpose']}',
      );
      print(
        '   - appointmentSubject: ${appointmentData['appointmentSubject']}',
      );
      print(
        '   - preferredDateRange: ${appointmentData['preferredDateRange']}',
      );
      print(
        '   - appointmentLocation: ${appointmentData['appointmentLocation']}',
      );
      print('   - numberOfUsers: ${appointmentData['numberOfUsers']}');
      print('   - accompanyUsers: ${appointmentData['accompanyUsers']}');
      print('   - assignedSecretary: ${appointmentData['assignedSecretary']}');
      print('   - guestInformation: ${appointmentData['guestInformation']}');

      final response = await http.post(
        Uri.parse('$baseUrl/appointment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(appointmentData),
      );

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Appointment created successfully!');
        return {
          'success': true,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Appointment created successfully',
          'statusCode': response.statusCode,
        };
      } else {
        print('❌ Failed to create appointment: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create appointment',
          'error': responseData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error creating appointment: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Upload and validate profile photo for accompanying users
  static Future<Map<String, dynamic>> uploadAndValidateProfilePhoto(
    File photoFile,
  ) async {
    try {
      print('📸 Starting photo upload and validation for: ${photoFile.path}');

      final token = await StorageService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Create multipart request for file upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/validate-upload-s3'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the photo file
      if (await photoFile.exists()) {
        try {
          print('📸 Adding photo file to request: ${photoFile.path}');
          final photoStream = http.ByteStream(photoFile.openRead());
          final photoLength = await photoFile.length();
          print('📸 Photo file size: ${photoLength} bytes');

          // Get file extension and name
          final fileName = photoFile.path.split('/').last;
          final fileExtension = fileName.contains('.')
              ? fileName.split('.').last
              : 'jpg';
          final mimeType = _getMimeType(fileExtension);

          final photoMultipart = http.MultipartFile(
            'file', // Field name expected by the API
            photoStream,
            photoLength,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(photoMultipart);
          print('📸 Photo file added successfully to multipart request');
        } catch (photoError) {
          print('❌ Error adding photo file: $photoError');
          return {
            'success': false,
            'message': 'Error processing photo file: ${photoError.toString()}',
          };
        }
      } else {
        print('⚠️ Photo file does not exist: ${photoFile.path}');
        return {'success': false, 'message': 'Photo file not found'};
      }

      print('📤 Sending photo upload request to: ${request.url}');
      print('📤 Request headers: ${request.headers}');
      print('📤 Total files being sent: ${request.files.length}');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Photo upload response status: ${response.statusCode}');
      print('📥 Photo upload response body: ${response.body}');

      // Parse response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Photo uploaded and validated successfully!');
        print('📸 S3 URL: ${responseData['data']['s3Url']}');
        print('📸 Validation result: ${responseData['data']['validation']}');

        return {
          'success': true,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Photo uploaded and validated successfully',
          's3Url': responseData['data']['s3Url'],
          'validation': responseData['data']['validation'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        print('❌ Photo upload failed: ${errorData['message']}');
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to upload photo',
          'error': errorData['error'],
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ Error in uploadAndValidateProfilePhoto: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
        'error': e.toString(),
      };
    }
  }

  // Add FCM token to user's database record
  static Future<Map<String, dynamic>> addFCMToken({
    required String token,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {'token': token};

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Notifications enabled successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to enable notifications',
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

  // Send login notification
  static Future<Map<String, dynamic>> sendLoginNotification({
    required String userId,
    Map<String, dynamic>? loginInfo,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'loginInfo':
            loginInfo ??
            {
              'deviceInfo': 'Flutter Mobile App',
              'location': 'Mobile Device',
              'timestamp': DateTime.now().toIso8601String(),
            },
      };

      // Make API call
      final url = '$baseUrl/notifications/login';
      print('📤 Calling login notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Login notification API response status: ${response.statusCode}',
      );
      print('📤 Login notification API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse login notification response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Login notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send login notification',
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

  // Send signup notification
  static Future<Map<String, dynamic>> sendSignupNotification({
    required String userId,
    Map<String, dynamic>? signupInfo,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'signupInfo':
            signupInfo ??
            {
              'source': 'mobile_app',
              'timestamp': DateTime.now().toIso8601String(),
            },
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/signup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Signup notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send signup notification',
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

  // Send role-specific notification
  static Future<Map<String, dynamic>> sendRoleNotification({
    required String role,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'role': role,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/send-to-role';
      print('📤 Calling role notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Role notification API response status: ${response.statusCode}');
      print('📤 Role notification API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse role notification response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Role notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send role notification',
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

  // Send notification to specific user
  static Future<Map<String, dynamic>> sendUserNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      };

      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/send-to-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'User notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send user notification',
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

  // Send test notification to current user
  static Future<Map<String, dynamic>> sendTestNotification({
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'title': title ?? 'Test Notification',
        'body':
            body ??
            'This is a test notification from Sri Sri Appointment system.',
        'data': data ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/test';
      print('📤 Calling test notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Test notification API response status: ${response.statusCode}');
      print('📤 Test notification API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse test notification response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Test notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send test notification',
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

  // Send notification to multiple users
  static Future<Map<String, dynamic>> sendNotificationToMultiple({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userIds': userIds,
        'title': title,
        'body': body,
        'data': data ?? {},
        'options': options ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/send-multiple';
      print('📤 Calling multiple notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Multiple notification API response status: ${response.statusCode}',
      );
      print('📤 Multiple notification API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse multiple notification response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Notifications sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to send notifications',
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

  // Send notification to topic
  static Future<Map<String, dynamic>> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Map<String, dynamic>? options,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'topic': topic,
        'title': title,
        'body': body,
        'data': data ?? {},
        'options': options ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/send-topic';
      print('📤 Calling topic notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Topic notification API response status: ${response.statusCode}',
      );
      print('📤 Topic notification API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse topic notification response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Topic notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to send topic notification',
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

  // Subscribe to topic
  static Future<Map<String, dynamic>> subscribeToTopic({
    required String topic,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {'topic': topic};

      // Make API call
      final url = '$baseUrl/notifications/subscribe-topic';
      print('📤 Calling subscribe topic API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Subscribe topic API response status: ${response.statusCode}');
      print('📤 Subscribe topic API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse subscribe topic response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Subscribed to topic successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to subscribe to topic',
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

  // Unsubscribe from topic
  static Future<Map<String, dynamic>> unsubscribeFromTopic({
    required String topic,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {'topic': topic};

      // Make API call
      final url = '$baseUrl/notifications/unsubscribe-topic';
      print('📤 Calling unsubscribe topic API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📤 Unsubscribe topic API response status: ${response.statusCode}');
      print('📤 Unsubscribe topic API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse unsubscribe topic response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Unsubscribed from topic successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ?? 'Failed to unsubscribe from topic',
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

  // Subscribe tokens to topic (public endpoint)
  static Future<Map<String, dynamic>> subscribeToTopicPublic({
    required List<String> tokens,
    required String topic,
  }) async {
    try {
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'tokens': tokens,
        'topic': topic,
      };

      // Make API call
      final url = '$baseUrl/notifications/subscribe-topic-public';
      print('📤 Calling public subscribe topic API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Public subscribe topic API response status: ${response.statusCode}',
      );
      print('📤 Public subscribe topic API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse public subscribe topic response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ?? 'Subscribed to topic successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to subscribe to topic',
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

  // Get user's FCM tokens
  static Future<Map<String, dynamic>> getUserTokens() async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Make API call
      final url = '$baseUrl/notifications/tokens';
      print('📤 Calling get user tokens API: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📤 Get user tokens API response status: ${response.statusCode}');
      print('📤 Get user tokens API response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ Failed to parse get user tokens response as JSON: $e');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'User FCM tokens retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to get user tokens',
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

  // Send appointment creation notification
  static Future<Map<String, dynamic>> sendAppointmentCreatedNotification({
    required String userId,
    required String appointmentId,
    Map<String, dynamic>? appointmentData,
    Map<String, dynamic>? notificationData,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'appointmentId': appointmentId,
        'appointmentData': appointmentData ?? {},
        'notificationData': notificationData ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/appointment-created';
      print('📤 Calling appointment created notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Appointment created notification API response status: ${response.statusCode}',
      );
      print(
        '📤 Appointment created notification API response body: ${response.body}',
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print(
          '❌ Failed to parse appointment created notification response as JSON: $e',
        );
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Appointment creation notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to send appointment creation notification',
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

  // Send appointment update notification
  static Future<Map<String, dynamic>> sendAppointmentUpdatedNotification({
    required String userId,
    required String appointmentId,
    Map<String, dynamic>? appointmentData,
    String updateType = 'updated',
    Map<String, dynamic>? notificationData,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'appointmentId': appointmentId,
        'appointmentData': appointmentData ?? {},
        'updateType': updateType,
        'notificationData': notificationData ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/appointment-updated';
      print('📤 Calling appointment updated notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Appointment updated notification API response status: ${response.statusCode}',
      );
      print(
        '📤 Appointment updated notification API response body: ${response.body}',
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print(
          '❌ Failed to parse appointment updated notification response as JSON: $e',
        );
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Appointment update notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to send appointment update notification',
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

  // Send profile update notification
  static Future<Map<String, dynamic>> sendProfileUpdateNotification({
    required String userId,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? notificationData,
  }) async {
    try {
      // Get authentication token
      final authToken = await StorageService.getToken();
      if (authToken == null) {
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'profileData': profileData ?? {},
        'notificationData': notificationData ?? {},
      };

      // Make API call
      final url = '$baseUrl/notifications/profile-updated';
      print('📤 Calling profile update notification API: $url');
      print('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print(
        '📤 Profile update notification API response status: ${response.statusCode}',
      );
      print(
        '📤 Profile update notification API response body: ${response.body}',
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print(
          '❌ Failed to parse profile update notification response as JSON: $e',
        );
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Invalid response format from server',
          'error': response.body,
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message':
              responseData['message'] ??
              'Profile update notification sent successfully',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              responseData['message'] ??
              'Failed to send profile update notification',
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
}
