import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../action/storage_service.dart';
import 'user_screen.dart';
import 'user_history_screen.dart';
import 'profile_screen.dart';
import 'appointment_type_selection_screen.dart';
import 'my_divine_picture_screen.dart';

class UserSidebar extends StatefulWidget {
  const UserSidebar({super.key});

  @override
  State<UserSidebar> createState() => _UserSidebarState();
}

class _UserSidebarState extends State<UserSidebar> {
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF97316), // Orange
              Color(0xFFEAB308), // Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
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
                  backgroundImage: _userData?['profilePhoto'] != null && _userData!['profilePhoto'].toString().isNotEmpty
                      ? NetworkImage(_userData!['profilePhoto'])
                      : null,
                  child: _userData?['profilePhoto'] == null || _userData!['profilePhoto'].toString().isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 30,
                          color: const Color(0xFFF97316),
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                // User Name
                Flexible(
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : _userData?['fullName'] ?? _userData?['name'] ?? 'User',
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
              ],
            ),
          ),

          // Navigation Items
          ListTile(
                            leading: const Icon(Icons.add_circle_outline, color: Color(0xFFF97316)),
            title: const Text('Request Appointment'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentTypeSelectionScreen(),
                ),
              );
            },
          ),

          ListTile(
                            leading: const Icon(Icons.history, color: Color(0xFFF97316)),
            title: const Text('My History'),
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

          ListTile(
                            leading: const Icon(Icons.photo_library, color: Color(0xFFF97316)),
            title: const Text('My Divine Picture'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyDivinePictureScreen(),
                ),
              );
            },
          ),

          ListTile(
                            leading: const Icon(Icons.person_outline, color: Color(0xFFF97316)),
            title: const Text('Profile'),
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

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }


} 