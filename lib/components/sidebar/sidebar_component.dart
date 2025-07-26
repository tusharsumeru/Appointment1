import 'package:flutter/material.dart';
import '../../main/home_screen.dart';
import '../../main/inbox_screen.dart';
import '../../main/today_screen.dart';
import '../../main/upcoming_screen.dart';
import '../../main/assigned_to_me_screen.dart';
import '../../main/starred_screen.dart';
import '../../main/add_new_screen.dart';
import '../../auth/login_screen.dart';
import '../../action/action.dart';
import '../../action/storage_service.dart';

class SidebarComponent extends StatefulWidget {
  const SidebarComponent({super.key});

  @override
  State<SidebarComponent> createState() => _SidebarComponentState();
}

class _SidebarComponentState extends State<SidebarComponent> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await ActionService.getCurrentUser();
      
      if (result['success']) {
        setState(() {
          _userData = result['data'];
          _isLoading = false;
        });
      } else {
        // Handle error - token expired or other issues
        if (result['statusCode'] == 401 || result['statusCode'] == 403 || result['statusCode'] == 404) {
          // Clear stored data and navigate to login
          await StorageService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  backgroundImage: _userData?['profilePhoto'] != null 
                      ? NetworkImage(_userData!['profilePhoto'])
                      : null,
                  child: _userData?['profilePhoto'] == null
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.deepPurple,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                // User Name
                Flexible(
                  child: Text(
                    _isLoading 
                        ? 'Loading...'
                        : _userData?['fullName'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                // User Email
                Flexible(
                  child: Text(
                    _isLoading 
                        ? 'Loading...'
                        : _userData?['email'] ?? 'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // User Role (if available)
                if (_userData?['role'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userData!['role'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
          
          ListTile(
            leading: const Icon(Icons.assignment_ind, color: Colors.deepPurple),
            title: const Text('Assigned to Me'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AssignedToMeScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.star, color: Colors.deepPurple),
            title: const Text('Starred'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StarredScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.deepPurple),
            title: const Text('Add New'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddNewScreen()),
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
                        onPressed: () async {
                          Navigator.pop(context); // Close dialog
                          
                          // Clear stored data
                          await StorageService.logout();
                          
                          // Navigate to login screen and clear navigation stack
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
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