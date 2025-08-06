import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _appointmentsKey = 'cached_appointments';
  static const String _appointmentsTimestampKey = 'appointments_timestamp';
  static const String _inboxAppointmentsKey = 'cached_inbox_appointments';
  static const String _inboxAppointmentsTimestampKey = 'inbox_appointments_timestamp';
  static const String _assignedToMeAppointmentsKey = 'cached_assigned_to_me_appointments';
  static const String _assignedToMeAppointmentsTimestampKey = 'assigned_to_me_appointments_timestamp';

  // Save authentication token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);
      print('Token saved successfully: $token');
    } catch (e) {
      print('Error saving token: $e');
      throw Exception('Failed to save token: $e');
    }
  }

  // Get authentication token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Save refresh token
  static Future<void> saveRefreshToken(String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, refreshToken);
      print('Refresh token saved successfully');
    } catch (e) {
      print('Error saving refresh token: $e');
      throw Exception('Failed to save refresh token: $e');
    }
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  // Save user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = jsonEncode(userData);
      await prefs.setString(_userDataKey, userDataString);
      print('✅ User data saved successfully to storage');
      print('📋 Saved data: $userData');
      print('📋 Saved JSON string: $userDataString');
    } catch (e) {
      print('❌ Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      print('📡 StorageService.getUserData() - Retrieved from storage: $userDataString');
      
      if (userDataString != null) {
        final decodedData = jsonDecode(userDataString);
        print('✅ StorageService.getUserData() - Successfully decoded: $decodedData');
        return decodedData;
      }
      print('⚠️ StorageService.getUserData() - No data found in storage');
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);
      // Clear all appointments cache when logging out
      await prefs.remove(_appointmentsKey);
      await prefs.remove(_appointmentsTimestampKey);
      await prefs.remove(_inboxAppointmentsKey);
      await prefs.remove(_inboxAppointmentsTimestampKey);
      await prefs.remove(_assignedToMeAppointmentsKey);
      await prefs.remove(_assignedToMeAppointmentsTimestampKey);
      print('Auth data and all cache cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
      throw Exception('Failed to clear auth data: $e');
    }
  }

  // Logout user
  static Future<void> logout() async {
    await clearAuthData();
  }



  // Appointment data caching

  // Save appointments data
  static Future<void> saveAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = jsonEncode(appointments);
      await prefs.setString(_appointmentsKey, appointmentsString);
      await prefs.setInt(_appointmentsTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('Appointments data saved successfully: ${appointments.length} appointments');
    } catch (e) {
      print('Error saving appointments data: $e');
      throw Exception('Failed to save appointments data: $e');
    }
  }

  // Save inbox appointments data
  static Future<void> saveInboxAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = jsonEncode(appointments);
      await prefs.setString(_inboxAppointmentsKey, appointmentsString);
      await prefs.setInt(_inboxAppointmentsTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('Inbox appointments data saved successfully: ${appointments.length} appointments');
    } catch (e) {
      print('Error saving inbox appointments data: $e');
      throw Exception('Failed to save inbox appointments data: $e');
    }
  }

  // Save assigned to me appointments data
  static Future<void> saveAssignedToMeAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = jsonEncode(appointments);
      await prefs.setString(_assignedToMeAppointmentsKey, appointmentsString);
      await prefs.setInt(_assignedToMeAppointmentsTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('Assigned to me appointments data saved successfully: ${appointments.length} appointments');
    } catch (e) {
      print('Error saving assigned to me appointments data: $e');
      throw Exception('Failed to save assigned to me appointments data: $e');
    }
  }

  // Get cached appointments data
  static Future<List<Map<String, dynamic>>?> getAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = prefs.getString(_appointmentsKey);
      if (appointmentsString != null) {
        final List<dynamic> appointmentsList = jsonDecode(appointmentsString);
        return appointmentsList.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error getting appointments data: $e');
      return null;
    }
  }

  // Get cached inbox appointments data
  static Future<List<Map<String, dynamic>>?> getInboxAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = prefs.getString(_inboxAppointmentsKey);
      if (appointmentsString != null) {
        final List<dynamic> appointmentsList = jsonDecode(appointmentsString);
        return appointmentsList.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error getting inbox appointments data: $e');
      return null;
    }
  }

  // Get cached assigned to me appointments data
  static Future<List<Map<String, dynamic>>?> getAssignedToMeAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsString = prefs.getString(_assignedToMeAppointmentsKey);
      if (appointmentsString != null) {
        final List<dynamic> appointmentsList = jsonDecode(appointmentsString);
        return appointmentsList.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error getting assigned to me appointments data: $e');
      return null;
    }
  }

  // Get appointments timestamp
  static Future<int?> getAppointmentsTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_appointmentsTimestampKey);
    } catch (e) {
      print('Error getting appointments timestamp: $e');
      return null;
    }
  }

  // Clear appointments cache
  static Future<void> clearAppointmentsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appointmentsKey);
      await prefs.remove(_appointmentsTimestampKey);
      print('Appointments cache cleared successfully');
    } catch (e) {
      print('Error clearing appointments cache: $e');
      throw Exception('Failed to clear appointments cache: $e');
    }
  }
} 