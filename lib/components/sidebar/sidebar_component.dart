import 'package:flutter/material.dart';
import '../../main/home_screen.dart';
import '../../main/inbox_screen.dart';
import '../../main/today_screen.dart';
import '../../main/tomorrow_screen.dart';
import '../../main/upcoming_screen.dart';
import '../../main/dashboard_screen.dart';
import '../../main/quick_darshan_line_screen.dart';
import '../../main/bulk_email_sms_screen.dart';
import '../../main/upload_offline_appointment_screen.dart';
import '../../main/assigned_to_me_screen.dart';
import '../../main/starred_screen.dart';
import '../../main/add_new_screen.dart';
import '../../main/change_password_screen.dart';
import '../../main/export_data_screen.dart';
import '../../main/forward_request_logs_screen.dart';
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
      // First, try to get user data from local storage
      final cachedUserData = await StorageService.getUserData();

      if (cachedUserData != null) {
        // Use cached data immediately
        setState(() {
          _userData = cachedUserData;
          _isLoading = false;
        });

        // Optionally refresh in background (optional - you can remove this if you want to keep cached data)
        // _refreshUserDataInBackground();
      } else {
        // No cached data, fetch from API
        await _fetchUserDataFromAPI();
      }
    } catch (error) {
      print('Error loading user data: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDataFromAPI() async {
    try {
      final result = await ActionService.getCurrentUser();

      if (result['success']) {
        // Save to local storage for future use
        await StorageService.saveUserData(result['data']);

        setState(() {
          _userData = result['data'];
          _isLoading = false;
        });
      } else {
        // Handle error - token expired or other issues
        if (result['statusCode'] == 401 ||
            result['statusCode'] == 403 ||
            result['statusCode'] == 404) {
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
      print('Error fetching user data from API: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Optional: Refresh user data in background (uncomment if you want to keep data fresh)
  // Future<void> _refreshUserDataInBackground() async {
  //   try {
  //     final result = await ActionService.getCurrentUser();
  //     if (result['success']) {
  //       await StorageService.saveUserData(result['data']);
  //       if (mounted) {
  //         setState(() {
  //           _userData = result['data'];
  //         });
  //       }
  //     }
  //   } catch (error) {
  //     print('Error refreshing user data: $error');
  //   }
  // }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
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
      // Show loading indicator
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
        // Clear all stored data
        await StorageService.logout();
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Close drawer
        Navigator.of(context).pop();
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error message
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
    // Get user role for conditional menu items
    String? userRole = _userData?['role']?.toString().toLowerCase();
    bool isSecretary = userRole == 'secretary';
    bool isAdmin = userRole == 'admin';
    bool isUser = userRole == 'user' || userRole == 'client';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(color: Colors.deepPurple),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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

          // Secretary-specific menu items
          if (isSecretary) ...[
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
              leading: const Icon(Icons.event, color: Colors.deepPurple),
              title: const Text('Tomorrow'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TomorrowScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const UpcomingScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.assignment_ind,
                color: Colors.deepPurple,
              ),
              title: const Text('Assigned to Me'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignedToMeScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const StarredScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: Colors.deepPurple,
              ),
              title: const Text('Add New'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewScreen()),
                );
              },
            ),
          ],

          // Admin-specific menu items (to be implemented)
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(
                Icons.admin_panel_settings,
                color: Colors.deepPurple,
              ),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to admin dashboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.deepPurple),
              title: const Text('Manage Users'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to user management
              },
            ),
          ],

          // User/Client-specific menu items (to be implemented)
          if (isUser) ...[
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Colors.deepPurple,
              ),
              title: const Text('My Appointments'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to user appointments
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.deepPurple),
              title: const Text('Appointment History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to appointment history
              },
            ),
          ],
          // Quick Darshan Line Navigation Item
          ListTile(
            leading: const Icon(Icons.queue, color: Colors.deepPurple),
            title: const Text('Quick Darshan Line'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuickDarshanLineScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const BulkEmailSmsScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const UploadOfflineAppointmentScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
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
            leading: const Icon(Icons.lock_reset, color: Colors.grey),
            title: const Text('Change Password'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.grey),
            title: const Text('Export Data'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportDataScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.forward, color: Colors.grey),
            title: const Text('Forward Request Logs'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForwardRequestLogsScreen(),
                ),
              );
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
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }
}
