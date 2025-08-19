import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../main/home_screen.dart';
import '../main/inbox_screen.dart';
import '../user/user_screen.dart';
import '../user/user_history_screen.dart';
import '../guard/guard_screen.dart';
import '../action/action.dart';


class NotificationSetupScreen extends StatefulWidget {
  final bool isNewUser;
  final Map<String, dynamic> userData;
  
  const NotificationSetupScreen({
    super.key,
    required this.isNewUser,
    required this.userData,
  });

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Welcome Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                _getWelcomeMessage(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Enable notifications to receive important updates about your appointments and account',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 60),
              
              // Enable Notifications Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _enableNotifications,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active),
                  label: Text(_isLoading ? 'Enabling...' : 'Enable Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skip Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _skipNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip for Now',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enableNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if Firebase is initialized
      if (!Firebase.apps.isNotEmpty) {
        _showError('Firebase not initialized. Please restart the app.');
        return;
      }

      // Request permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('📱 Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _showError('Notification permissions are required. Please enable notifications in your device settings and try again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Generate FCM token
      final token = await FirebaseMessaging.instance.getToken();
      
      if (token == null) {
        _showError('Failed to generate device token. Please try again.');
        return;
      }

      print('🔥 FCM Token Generated: $token');
      
      // Save token to database
      await _saveTokenToDatabase(token);
      
      // Send welcome notification
      await _sendWelcomeNotification();
      
      // Navigate to main screen
      await _navigateToMainScreen();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error enabling notifications: $e');
      print('❌ Error generating FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final result = await ActionService.addFCMToken(token: token);
      
      if (result['success']) {
        print('✅ FCM token saved to database successfully');
      } else {
        print('❌ Failed to save FCM token to database: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving FCM token to database: $e');
    }
  }

  Future<void> _skipNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _navigateToMainScreen();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToMainScreen() async {
    // Determine which screen to navigate to based on user role
    final userRole = widget.userData['role']?.toString().toLowerCase();
    
    if (userRole == 'admin' || userRole == 'secretary' || userRole == 'super-admin') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const InboxScreen()),
        (route) => false,
      );
    } else if (userRole == 'guard') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const GuardScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const UserHistoryScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _sendWelcomeNotification() async {
    try {
      final userId = widget.userData['id']?.toString() ?? widget.userData['userId']?.toString();
      final userRole = widget.userData['role']?.toString().toLowerCase();
      final userName = widget.userData['name']?.toString() ?? 
                      widget.userData['fullName']?.toString() ?? 
                      'User';
      
      if (userId == null) {
        print('⚠️ User ID not found, skipping notification');
        return;
      }

      if (widget.isNewUser) {
        // Send signup notification for new users
        await ActionService.sendSignupNotification(
          userId: userId,
          signupInfo: {
            'role': userRole,
            'userName': userName,
            'source': 'mobile_app',
            'timestamp': DateTime.now().toIso8601String(),
            'notificationType': 'welcome_signup',
            'deviceInfo': 'Flutter Mobile App',
          },
        );
      } else {
        // Send login notification for returning users
        await ActionService.sendLoginNotification(
          userId: userId,
          loginInfo: {
            'role': userRole,
            'userName': userName,
            'deviceInfo': 'Flutter Mobile App',
            'location': 'Mobile Device',
            'timestamp': DateTime.now().toIso8601String(),
            'notificationType': 'welcome_login',
            'sessionType': 'mobile_app',
          },
        );
      }

      // Send role-specific welcome notification
      await _sendRoleSpecificNotification(userRole, userName);
      
    } catch (e) {
      print('❌ Error sending welcome notification: $e');
    }
  }

  Future<void> _sendRoleSpecificNotification(String? userRole, String userName) async {
    try {
      String title;
      String body;
      Map<String, dynamic> data = {
        'type': 'welcome',
        'userName': userName,
        'timestamp': DateTime.now().toIso8601String(),
        'screen': 'dashboard',
      };

      switch (userRole) {
        case 'admin':
          title = 'Welcome Administrator!';
          body = 'Hello $userName! You have successfully logged into the admin panel.';
          data['role'] = 'admin';
          data['action'] = 'admin_dashboard';
          data['screen'] = 'inbox';
          break;
        case 'secretary':
          title = 'Welcome Secretary!';
          body = 'Hello $userName! You have successfully logged into the secretary panel.';
          data['role'] = 'secretary';
          data['action'] = 'secretary_dashboard';
          data['screen'] = 'inbox';
          break;
        case 'super-admin':
          title = 'Welcome Super Administrator!';
          body = 'Hello $userName! You have successfully logged into the super admin panel.';
          data['role'] = 'super-admin';
          data['action'] = 'super_admin_dashboard';
          data['screen'] = 'inbox';
          break;
        case 'guard':
          title = 'Welcome Guard!';
          body = 'Hello $userName! You have successfully logged into the guard panel.';
          data['role'] = 'guard';
          data['action'] = 'guard_dashboard';
          data['screen'] = 'guard';
          break;
        case 'user':
        case 'client':
        default:
          title = 'Welcome to Appointment App!';
          body = 'Hello $userName! You have successfully logged into your account.';
          data['role'] = 'user';
          data['action'] = 'user_dashboard';
          data['screen'] = 'user';
          break;
      }

      await ActionService.sendRoleNotification(
        role: userRole ?? 'user',
        title: title,
        body: body,
        data: data,
      );

    } catch (e) {
      print('❌ Error sending role-specific notification: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getWelcomeMessage() {
    final userRole = widget.userData['role']?.toString().toLowerCase();
    
    if (widget.isNewUser) {
      return 'Welcome to Appointment App!';
    }
    
    switch (userRole) {
      case 'secretary':
        return 'Welcome back, Secretary!';
      case 'admin':
        return 'Welcome back, Administrator!';
      case 'super-admin':
        return 'Welcome back, Super Administrator!';
      case 'guard':
        return 'Welcome back, Guard!';
      case 'user':
      case 'client':
        return 'Welcome back!';
      default:
        return 'Welcome back!';
    }
  }
}
