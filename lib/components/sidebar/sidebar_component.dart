import 'package:flutter/material.dart';
import '../../main/home_screen.dart';
import '../../main/inbox_screen.dart';
import '../../main/today_screen.dart';
import '../../main/upcoming_screen.dart';
import '../../main/dashboard_screen.dart';
import '../../main/quick_darshan_line_screen.dart';
import '../../main/bulk_email_sms_screen.dart';
import '../../main/upload_offline_appointment_screen.dart';

class SidebarComponent extends StatelessWidget {
  const SidebarComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Appointment App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'user@example.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
        
          
          // Navigation Items
          ListTile(
            leading: const Icon(Icons.home, color: Colors.deepPurple),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.inbox, color: Colors.deepPurple),
            title: const Text('Inbox'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InboxScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.today, color: Colors.deepPurple),
            title: const Text('Today'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TodayScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.deepPurple),
            title: const Text('Upcoming'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UpcomingScreen()),
              );
            },
          ),
          // Quick Darshan Line Navigation Item
          ListTile(
            leading: const Icon(Icons.queue, color: Colors.deepPurple),
            title: const Text('Quick Darshan Line'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const QuickDarshanLineScreen()),
              );
            },
          ),
          // Send Bulk Email & SMS Navigation Item
          ListTile(
            leading: const Icon(Icons.email, color: Colors.deepPurple),
            title: const Text('Send Bulk Email & SMS'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BulkEmailSmsScreen()),
              );
            },
          ),
          // Upload Offline Appointment Navigation Item
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.deepPurple),
            title: const Text('Upload Offline Appointment'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UploadOfflineAppointmentScreen()),
              );
            },
          ),
          // Dashboard Navigation Item
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
          const Divider(),
          
          // Settings and other options
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings screen
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help, color: Colors.grey),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to help screen
            },
          ),
          
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement logout functionality
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          // TODO: Navigate back to login screen
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
} 