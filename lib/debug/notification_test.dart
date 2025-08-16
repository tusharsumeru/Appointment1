import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  String _status = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iOSSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(settings);
  }

  Future<void> _testLocalNotification() async {
    setState(() => _status = 'Sending local notification...');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      0,
      'Test Notification ✨',
      'This is a test notification while app is open',
      details,
    );

    setState(() => _status = 'Local notification sent! Check if banner appears.');
  }

  Future<void> _testForegroundSettings() async {
    setState(() => _status = 'Checking foreground settings...');

    try {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      setState(() => _status = '✅ Foreground notification settings applied successfully!');
    } catch (e) {
      setState(() => _status = '❌ Error setting foreground options: $e');
    }
  }

  Future<void> _getFCMToken() async {
    setState(() => _status = 'Getting FCM token...');

    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() => _status = 'FCM Token: ${token?.substring(0, 20)}...');
    } catch (e) {
      setState(() => _status = '❌ Error getting token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'iOS Foreground Notification Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This screen helps test if notifications appear as banners while the app is open.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testForegroundSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Test Foreground Settings'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _testLocalNotification,
              icon: const Icon(Icons.notifications),
              label: const Text('Send Test Local Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _getFCMToken,
              icon: const Icon(Icons.token),
              label: const Text('Get FCM Token'),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Run on a real iOS device (not simulator)\n'
                      '2. Tap "Test Foreground Settings" first\n'
                      '3. Tap "Send Test Local Notification"\n'
                      '4. You should see a banner appear at the top\n'
                      '5. For FCM testing, use the token with your backend\n'
                      '6. Send a notification with "notification" block in payload',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
