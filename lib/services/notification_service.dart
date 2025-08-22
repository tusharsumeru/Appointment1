import 'dart:convert';
import 'package:http/http.dart' as http;
import '../action/storage_service.dart';
import '../action/action.dart';

class NotificationService {
  // FCM v1 API endpoint
  static const String _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/appointment-8d641/messages:send';

  // Your Firebase project ID from google-services.json
  static const String _projectId = 'appointment-8d641';

  // Send notification to specific device token
  static Future<Map<String, dynamic>> sendToDevice({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get OAuth token (you'll need to implement this based on your server setup)
      final oauthToken = await _getOAuthToken();

      if (oauthToken == null) {
        return {'success': false, 'message': 'Failed to get OAuth token'};
      }

      // Prepare FCM v1 message payload
      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
          'android': {
            'notification': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': 'appointment_notifications',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'category': 'APPOINTMENT_NOTIFICATION',
                'sound': 'default',
              },
            },
          },
        },
      };

      // Send request to FCM v1 API
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oauthToken',
        },
        body: jsonEncode(message),
      );

      print('📤 FCM v1 API Response Status: ${response.statusCode}');
      print('📤 FCM v1 API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Notification sent successfully',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              'Failed to send notification: ${errorData['error']?['message'] ?? 'Unknown error'}',
          'error': errorData,
        };
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Send notification to topic
  static Future<Map<String, dynamic>> sendToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final oauthToken = await _getOAuthToken();

      if (oauthToken == null) {
        return {'success': false, 'message': 'Failed to get OAuth token'};
      }

      final Map<String, dynamic> message = {
        'message': {
          'topic': topic,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
          'android': {
            'notification': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'channel_id': 'appointment_notifications',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'category': 'APPOINTMENT_NOTIFICATION',
                'sound': 'default',
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $oauthToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Topic notification sent successfully',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              'Failed to send topic notification: ${errorData['error']?['message'] ?? 'Unknown error'}',
          'error': errorData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Send notification to multiple devices
  static Future<Map<String, dynamic>> sendToMultipleDevices({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final oauthToken = await _getOAuthToken();

      if (oauthToken == null) {
        return {'success': false, 'message': 'Failed to get OAuth token'};
      }

      // FCM v1 doesn't support multiple tokens in a single request
      // We need to send individual requests for each token
      List<Map<String, dynamic>> results = [];
      int successCount = 0;
      int failureCount = 0;

      for (String token in tokens) {
        final result = await sendToDevice(
          token: token,
          title: title,
          body: body,
          data: data,
        );

        results.add(result);
        if (result['success']) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      return {
        'success': successCount > 0,
        'message':
            'Sent to $successCount devices, failed for $failureCount devices',
        'data': {
          'total': tokens.length,
          'success': successCount,
          'failed': failureCount,
          'results': results,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get OAuth token for FCM v1 API
  static Future<String?> _getOAuthToken() async {
    try {
      // This is where you would implement OAuth token generation
      // For now, we'll use a placeholder that should be replaced with actual implementation

      // Option 1: If you have a service account JSON file
      // return await _getTokenFromServiceAccount();

      // Option 2: If you have a server endpoint that provides OAuth tokens
      return await _getTokenFromServer();

      // Option 3: If you're using Application Default Credentials
      // return await _getTokenFromADC();
    } catch (e) {
      print('❌ Error getting OAuth token: $e');
      return null;
    }
  }

  // Get token from your server (recommended approach)
  static Future<String?> _getTokenFromServer() async {
    try {
      final String url = await ActionService.baseUrl;
      
      final response = await http.get(
        Uri.parse(
          '$url/auth/fcm-oauth-token',
        ),
      );

      print('📤 OAuth token request status: ${response.statusCode}');
      print('📤 OAuth token response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['token'] != null) {
          print('✅ OAuth token received successfully');
          return data['data']['token'];
        } else {
          print('❌ OAuth token request failed: ${data['message']}');
          return null;
        }
      } else {
        print(
          '❌ Failed to get OAuth token from server: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error getting OAuth token from server: $e');
      return null;
    }
  }

  // Subscribe to topic using your server's public endpoint
  static Future<Map<String, dynamic>> subscribeToTopic({
    required String token,
    required String topic,
  }) async {
    try {
      // For now, just return success without server call
      // This will be handled by your existing server endpoints
      print('📤 Topic subscription skipped - will be handled by server');
      return {
        'success': true,
        'message': 'Topic subscription will be handled by server',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Unsubscribe from topic using your server's public endpoint
  static Future<Map<String, dynamic>> unsubscribeFromTopic({
    required String token,
    required String topic,
  }) async {
    try {
      // For now, just return success without server call
      // This will be handled by your existing server endpoints
      print('📤 Topic unsubscription skipped - will be handled by server');
      return {
        'success': true,
        'message': 'Topic unsubscription will be handled by server',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
