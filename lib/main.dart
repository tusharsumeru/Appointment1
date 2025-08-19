import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'auth/splash_screen.dart';
import 'main/home_screen.dart';
import 'action/action.dart';
import 'main/inbox_screen.dart';
import 'main/dashboard_screen.dart';
import 'main/assigned_to_me_screen.dart';
import 'main/starred_screen.dart';
import 'main/upcoming_screen.dart';
import 'main/today_screen.dart';
import 'main/tomorrow_screen.dart';
import 'main/add_new_screen.dart';
import 'main/deleted_appointments_screen.dart';
import 'main/global_search_screen.dart';
import 'user/user_screen.dart';
import 'auth/notification_setup_screen.dart';
import 'guard/guard_screen.dart';
import 'debug/test_notification_screen.dart';

// Global variables for notification handling
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting app initialization...');
  print('📱 Platform: ${Platform.operatingSystem}');
  
  // Initialize base URL
  print('🌐 Initializing base URL...');
  try {
    await ActionService.initializeBaseUrl();
    print('✅ Base URL initialized successfully');
  } catch (e) {
    print('❌ Base URL initialization failed: $e');
    print('🚨 App cannot start without base URL. Please check your network connection.');
    return; // Stop app initialization if base URL fails
  }
  
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('⚠️ Continuing app initialization without Firebase...');
    // Continue with app initialization even if Firebase fails
  }

  // Set background message handler only if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialize local notifications
  print('🔧 Initializing local notifications...');
  await _initializeLocalNotifications();
  print('✅ Local notifications initialization completed');

  // Request notification permissions for both platforms
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('✅ Notification permissions requested');
    
    // 🔥 CRITICAL: Enable foreground notification presentation for iOS
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,   // 🔔 show banner while app is OPEN
        badge: true,
        sound: true,
      );
      print('✅ iOS foreground notification presentation enabled');
    }
  } catch (e) {
    print('❌ Notification permission request failed: $e');
  }

  // Set up foreground message handler only if Firebase is initialized
  if (Firebase.apps.isNotEmpty) {
    try {
      print('🔧 Setting up FCM message listeners...');
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Foreground message received:');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');

        // 🔥 CRITICAL: Always show local notification on Android when app is in foreground
        // This is because Android doesn't automatically show FCM notifications when app is in foreground
        if (Platform.isAndroid) {
          print('📱 Showing local notification on Android (foreground)');
          _showLocalNotification(message);
        } else if (Platform.isIOS) {
          // iOS automatically shows notifications in foreground due to setForegroundNotificationPresentationOptions
          print('📱 iOS will show notification automatically');
        }
      });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.data}');
      _handleNotificationTap(initialMessage);
    }
    
    print('✅ FCM message listeners set up successfully');
     } catch (e) {
       print('❌ FCM messaging setup failed: $e');
     }
   } else {
     print('⚠️ Firebase not initialized, skipping messaging setup');
   }

  runApp(const MyApp());
}

// Initialize local notifications
Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification tapped: ${response.payload}');
      // Handle notification tap
    },
  );

  // 🔥 CRITICAL: Create Android notification channel
  if (Platform.isAndroid) {
    await _createNotificationChannel();
  }
}

// Create Android notification channel
Future<void> _createNotificationChannel() async {
  print('🔧 Creating Android notification channel...');
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'appointment_notifications', // id - MUST match your backend channel_id
    'Appointment Notifications', // name
    description: 'Notifications for appointment updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(channel);
    print('✅ Android notification channel created successfully: ${channel.id}');
  } else {
    print('❌ Failed to get Android implementation for notification channel');
  }
}

// Show local notification
void _showLocalNotification(RemoteMessage message) {
  print('🔔 Attempting to show local notification...');
  
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'appointment_notifications',
    'Appointment Notifications',
    channelDescription: 'Notifications for appointment updates',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    icon: '@mipmap/ic_launcher',
  );

  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  // 🔥 Handle both notification and data-only messages
  String title = message.notification?.title ?? 
                 message.data['title'] ?? 
                 'New Appointment Update';
  String body = message.notification?.body ?? 
                message.data['body'] ?? 
                message.data['message'] ?? 
                'You have a new notification';

  print('🔔 Notification details:');
  print('   ID: ${message.hashCode}');
  print('   Title: $title');
  print('   Body: $body');
  print('   Channel: appointment_notifications');

  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    platformChannelSpecifics,
    payload: message.data.toString(),
  ).then((_) {
    print('✅ Local notification shown successfully');
  }).catchError((error) {
    print('❌ Error showing local notification: $error');
  });
}

// Handle notification tap
void _handleNotificationTap(RemoteMessage message) {
  // Navigate based on notification data
  if (message.data.containsKey('screen')) {
    final screen = message.data['screen'];
    final type = message.data['type'];
    final role = message.data['role'];
    
    print('📱 Notification tapped - Screen: $screen, Type: $type, Role: $role');
    print('📱 Full notification data: ${message.data}');
    
    // Store notification data for navigation
    _pendingNotificationData = message.data;
  }
}

// Global variable to store pending notification data
Map<String, dynamic>? _pendingNotificationData;

// Helper function to handle notification navigation
void _handleNotificationNavigation(BuildContext context) {
  if (_pendingNotificationData != null) {
    final screen = _pendingNotificationData!['screen'];
    final type = _pendingNotificationData!['type'];
    final role = _pendingNotificationData!['role'];
    
    print('🚀 Navigating to screen: $screen for role: $role');
    
    // Clear the pending notification data
    _pendingNotificationData = null;
    
    // Navigate based on screen and role
    switch (screen) {
      case 'inbox':
        Navigator.of(context).pushReplacementNamed('/inbox');
        break;
      case 'guard':
        Navigator.of(context).pushReplacementNamed('/guard');
        break;
      case 'user':
        Navigator.of(context).pushReplacementNamed('/user');
        break;
      case 'dashboard':
        Navigator.of(context).pushReplacementNamed('/dashboard');
        break;
      default:
        // Default to home screen
        Navigator.of(context).pushReplacementNamed('/home');
        break;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointment App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/inbox': (context) => const InboxScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/assigned-to-me': (context) => const AssignedToMeScreen(),
        '/starred': (context) => const StarredScreen(),
        '/upcoming': (context) => const UpcomingScreen(),
        '/today': (context) => const TodayScreen(),
        '/tomorrow': (context) => const TomorrowScreen(),
        '/add-new': (context) => const AddNewScreen(),
        '/deleted-appointments': (context) => const DeletedAppointmentsScreen(),
        '/global-search': (context) => const GlobalSearchScreen(),
        '/user': (context) => const UserScreen(),
        '/guard': (context) => const GuardScreen(),
        '/fcm-token': (context) => const FCMTokenScreen(),
        '/fcm-setup': (context) => NotificationSetupScreen(
          isNewUser: true,
          userData: {},
        ),
        '/test-notifications': (context) => const TestNotificationScreen(),
      },
    );
  }
}

// FCM Token Display Screen
class FCMTokenScreen extends StatefulWidget {
  const FCMTokenScreen({super.key});

  @override
  State<FCMTokenScreen> createState() => _FCMTokenScreenState();
}

class _FCMTokenScreenState extends State<FCMTokenScreen> {
  String? _token = 'Fetching token...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        setState(() {
          _token = 'Firebase not initialized. Please restart the app.';
          _isLoading = false;
        });
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _token = token ?? 'No token received';
        _isLoading = false;
      });
      print('🔥 FCM Token: $token'); // Also printed to console
      
      if (token == null) {
        print('⚠️ Warning: FCM token is null. Check Firebase configuration.');
      }
    } catch (e) {
      setState(() {
        _token = 'Error getting token: $e';
        _isLoading = false;
      });
      print('❌ Error getting FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Cloud Messaging Token:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _isLoading
                  ? const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Loading token...'),
                      ],
                    )
                  : SelectableText(
                      _token ?? 'No token available',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Copy this token to use with your backend\n'
              '• For iOS: Run on a real device (not simulator)\n'
              '• Token is also printed to console/logcat\n'
              '• Make sure Firebase is properly configured\n'
              '• Check console for detailed logs',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getToken,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Token'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _token == null || _token!.startsWith('Error') || _token!.startsWith('No token') || _token!.startsWith('Firebase not initialized') || _token!.startsWith('Fetching')
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: _token!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('FCM Token copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Token'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
