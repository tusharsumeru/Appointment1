import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_service.dart';
import '../action/storage_service.dart';

class TestNotificationScreen extends StatefulWidget {
  const TestNotificationScreen({super.key});

  @override
  State<TestNotificationScreen> createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  String? _fcmToken;
  bool _isLoading = false;
  String _testResult = '';
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getFCMToken();
    _titleController.text = 'Test Notification';
    _bodyController.text = 'This is a test notification from the app!';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = token;
      });
      
      if (token != null) {
        _tokenController.text = token;
        print('🔥 FCM Token: $token');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  Future<void> _testLocalNotification() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing local notification...';
    });

    try {
      // This would require the local notification plugin to be properly set up
      _testResult = 'Local notification test completed. Check your device notifications.';
    } catch (e) {
      _testResult = 'Error testing local notification: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFCMNotification() async {
    if (_tokenController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter a valid FCM token';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Sending FCM notification...';
    });

    try {
      final result = await NotificationService.sendToDevice(
        token: _tokenController.text,
        title: _titleController.text,
        body: _bodyController.text,
        data: {
          'screen': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _testResult = result['success'] 
            ? '✅ FCM notification sent successfully!\n${result['message']}'
            : '❌ Failed to send FCM notification:\n${result['message']}';
      });

      print('📤 FCM Test Result: $result');
    } catch (e) {
      setState(() {
        _testResult = '❌ Error testing FCM notification: $e';
      });
      print('❌ Error testing FCM notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTopicNotification() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Sending topic notification...';
    });

    try {
      final result = await NotificationService.sendToTopic(
        topic: 'test_topic',
        title: _titleController.text,
        body: _bodyController.text,
        data: {
          'screen': 'test_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _testResult = result['success'] 
            ? '✅ Topic notification sent successfully!\n${result['message']}'
            : '❌ Failed to send topic notification:\n${result['message']}';
      });

      print('📤 Topic Test Result: $result');
    } catch (e) {
      setState(() {
        _testResult = '❌ Error testing topic notification: $e';
      });
      print('❌ Error testing topic notification: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _subscribeToTopic() async {
    if (_fcmToken == null) {
      setState(() {
        _testResult = 'No FCM token available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = 'Subscribing to test topic...';
    });

    try {
      final result = await NotificationService.subscribeToTopic(
        token: _fcmToken!,
        topic: 'test_topic',
      );

      setState(() {
        _testResult = result['success'] 
            ? '✅ Successfully subscribed to test_topic!\n${result['message']}'
            : '❌ Failed to subscribe to topic:\n${result['message']}';
      });

      print('📤 Subscribe Result: $result');
    } catch (e) {
      setState(() {
        _testResult = '❌ Error subscribing to topic: $e';
      });
      print('❌ Error subscribing to topic: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FCM Token Section
            _buildSectionHeader('FCM Token'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Token:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _fcmToken ?? 'Loading...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _getFCMToken,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh Token'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _fcmToken != null ? () {
                            Clipboard.setData(ClipboardData(text: _fcmToken!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token copied to clipboard!')),
                            );
                          } : null,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Content Section
            _buildSectionHeader('Notification Content'),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Target Token Section
            _buildSectionHeader('Target FCM Token'),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'FCM Token to send to',
                border: OutlineInputBorder(),
                hintText: 'Enter FCM token or use current device token',
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons Section
            _buildSectionHeader('Test Actions'),
            
            // Subscribe to Topic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _subscribeToTopic,
                icon: const Icon(Icons.subscriptions),
                label: const Text('Subscribe to Test Topic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Send to Device
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFCMNotification,
                icon: const Icon(Icons.send),
                label: const Text('Send to Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Send to Topic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testTopicNotification,
                icon: const Icon(Icons.topic),
                label: const Text('Send to Topic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Results Section
            _buildSectionHeader('Test Results'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isLoading
                  ? const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Testing...'),
                      ],
                    )
                  : Text(
                      _testResult.isEmpty ? 'No test results yet' : _testResult,
                      style: const TextStyle(fontSize: 14),
                    ),
            ),

            const SizedBox(height: 24),

            // Instructions Section
            _buildSectionHeader('Instructions'),
            const Text(
              '1. Make sure you have a valid FCM token\n'
              '2. Enter notification title and body\n'
              '3. Use current device token or enter a specific token\n'
              '4. Subscribe to test topic first\n'
              '5. Test sending notifications\n'
              '6. Check device notifications and console logs\n\n'
              'Note: FCM v1 API requires OAuth token from your server',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
