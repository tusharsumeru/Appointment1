import 'package:flutter/material.dart';
import '../../auth/login_screen.dart';
import '../../action/storage_service.dart';
import '../../user/request_appointment.dart';
import '../../user/appointment_details_screen.dart';
import '../../user/user_screen.dart';
import '../../user/user_history_screen.dart';
import '../../user/profile_screen.dart';
import '../../main/change_password_screen.dart';

class UserSidebarComponent extends StatefulWidget {
  const UserSidebarComponent({super.key});

  @override
  State<UserSidebarComponent> createState() => _UserSidebarComponentState();
}

class _UserSidebarComponentState extends State<UserSidebarComponent> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final cachedUserData = await StorageService.getUserData();
      if (cachedUserData != null) {
        setState(() {
          _userData = cachedUserData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error loading user data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Logging out...'),
              ],
            ),
          );
        },
      );

      try {
        await StorageService.logout();
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close drawer
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      } catch (e) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _userData?['profilePhoto'] != null
                          ? Image.network(
                              _userData!['profilePhoto'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User Name
                  Text(
                    _userData?['fullName'] ?? _userData?['name'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  // User Role
                  Text(
                    'User Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 16),

                  // Home
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text(
                      'Home',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserScreen(),
                        ),
                      );
                    },
                  ),

                  // Request Appointment
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                    title: const Text(
                      'Request Appointment',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestAppointmentScreen(
                            selectedType: 'Guest',
                          ),
                        ),
                      );
                    },
                  ),

                                    // My History
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.white),
                    title: const Text(
                      'My History',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserHistoryScreen(),
                        ),
                      );
                    },
                  ),

                  // Profile
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Colors.white),
                    title: const Text(
                      'Profile',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(color: Colors.white24),

                  // Settings
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white70),
                    title: const Text(
                      'Settings',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings screen
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.help_outline, color: Colors.white70),
                    title: const Text(
                      'Help & Support',
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to help screen
                    },
                  ),

                  const Divider(color: Colors.white24),

                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                    ),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'AOL Appointment System',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 