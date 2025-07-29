import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ActionService {
  static const String baseUrl = 'https://81650a222436.ngrok-free.app/api/v3'; // API base URL

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
          'message': 'Please enter both your email address and password to continue. 🔐',
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
        headers: {
          'Content-Type': 'application/json',
        },
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
          'message': responseData['message'] ?? '🎉 Welcome back! You\'re now logged in and ready to explore.',
        };
      } else if (response.statusCode == 202) {
        // Requires additional verification (OTP)
        return {
          'success': true,
          'statusCode': 202,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Verification code sent to your email.',
        };
      } else {
        // Error response
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Login failed. Please try again.',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Oops! Something went wrong during login. Please try again in a moment. If the problem persists, please contact our support team. 🛠️',
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
          'message': 'Please enter both your email address and password to continue. 🔐',
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
          'message': 'Your account is currently inactive. Please reach out to our support team and we\'ll be happy to help you get back on track! 💬',
        };
      case 423:
        return {
          'success': false,
          'statusCode': 423,
          'message': 'Your account is temporarily locked for security reasons. Please try again in a few hours or contact our support team if you need immediate assistance. 🔒',
        };
      default:
        return {
          'success': false,
          'statusCode': statusCode,
          'message': message,
        };
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
        // Success - return user data
        return {
          'success': true,
          'statusCode': 200,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'User profile retrieved successfully',
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



  // Get appointments for secretary
  static Future<Map<String, dynamic>> getAppointmentsForSecretary() async {
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

      // Try the main endpoint first
      final response = await http.get(
        Uri.parse('$baseUrl/appointment/secretary/appointments'),
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
        // If JSON parsing fails, it might be an HTML error page or plain text error
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Backend crashed while processing appointments',
        };
      }

      if (response.statusCode == 200) {
        // Success - return appointments data
        final List<dynamic> allAppointments = responseData['data'] ?? [];
        // Removed filtering by appointmentStatus
        return {
          'success': true,
          'statusCode': 200,
          'data': allAppointments,
          'message': responseData['message'] ?? 'Appointments retrieved successfully',
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
        // Handle backend errors (like the appointmentStatus null error)
        return {
          'success': false,
          'statusCode': 500,
          'message': 'Server error: Backend has data issues. Please try again later.',
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
  static Future<Map<String, dynamic>> getFaceMatchResultByAppointmentId(String appointmentId) async {
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
          'message': responseData['message'] ?? 'Face match results retrieved successfully',
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
          'message': responseData['message'] ?? 'Face match result not found for this appointment',
        };
      } else {
        // Other error
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': responseData['message'] ?? 'Failed to get face match results',
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