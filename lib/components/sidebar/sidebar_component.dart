import 'package:flutter/material.dart';
import '../../main/inbox_screen.dart';
import '../../main/today_screen.dart';
import '../../main/tomorrow_screen.dart';
import '../../main/upcoming_screen.dart';
import '../../main/dashboard_screen.dart';
// import '../../main/bulk_email_sms_screen.dart';
import '../../main/assigned_to_me_screen.dart';
import '../../main/starred_screen.dart';
import '../../main/add_new_screen.dart';
import '../../main/reference_from_list_screen.dart';
import '../../main/change_password_screen.dart';
import '../../main/account_settings_screen.dart';
// import '../../main/export_data_screen.dart';
// import '../../main/forward_request_logs_screen.dart';
import '../../main/deleted_appointments_screen.dart';
import '../../main/global_search_screen.dart';
import '../../main/unique_phone_code_screen.dart';
import '../../main/create_desk_user_screen.dart';
import '../../user/user_screen.dart';
import '../../auth/login_screen.dart';
import '../../action/action.dart';
import '../../action/storage_service.dart';

class SidebarComponent extends StatefulWidget {
  final String? currentRoute;
  
  const SidebarComponent({super.key, this.currentRoute});

  @override
  State<SidebarComponent> createState() => _SidebarComponentState();
}

class _SidebarComponentState extends State<SidebarComponent> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _sidebarCounts;
  bool _isLoading = true;
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSidebarCounts();
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

  // Load sidebar counts
  Future<void> _loadSidebarCounts() async {
    try {
      final result = await ActionService.getSidebarCounts();
      if (result['success']) {
        setState(() {
          _sidebarCounts = result['data'];
          _isLoadingCounts = false;
        });
      } else {
        print('Error loading sidebar counts: ${result['message']}');
        setState(() {
          _isLoadingCounts = false;
        });
      }
    } catch (error) {
      print('Error loading sidebar counts: $error');
      setState(() {
        _isLoadingCounts = false;
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

  // Helper method to get count for menu items
  String _getCount(String key) {
    if (_isLoadingCounts || _sidebarCounts == null) {
      return '0';
    }
    final count = _sidebarCounts![key];
    return count?.toString() ?? '0';
  }

  // Helper method to check if a menu item is active
  bool _isActive(String routeName) {
    return widget.currentRoute == routeName;
  }

  // Helper method to get count badge background color
  Color _getCountBackgroundColor(String routeName) {
    return _isActive(routeName) ? Colors.white : Colors.grey.shade200;
  }

  // Helper method to get active tile decoration
  BoxDecoration? _getActiveTileDecoration(String routeName) {
    if (_isActive(routeName)) {
      return BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      );
    }
    return null;
  }

  // Helper method to get icon color
  Color _getIconColor(String routeName) {
    return _isActive(routeName) ? Colors.grey.shade800 : Colors.deepOrange;
  }

  // Helper method to get text color
  Color _getTextColor(String routeName) {
    return _isActive(routeName) ? Colors.grey.shade900 : Colors.black;
  }

  // Helper method to get text weight
  FontWeight _getTextWeight(String routeName) {
    return _isActive(routeName) ? FontWeight.w500 : FontWeight.normal;
  }

  // Helper method to get count text color
  Color _getCountTextColor(String routeName) {
    return _isActive(routeName) ? Colors.grey.shade800 : Colors.grey.shade700;
  }

  // Reusable method to create menu item
  Widget _buildMenuItem({
    required String routeName,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? count,
  }) {
    return Container(
      decoration: _getActiveTileDecoration(routeName),
      child: ListTile(
        leading: Icon(
          icon,
          color: _getIconColor(routeName),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: _getTextColor(routeName),
            fontWeight: _getTextWeight(routeName),
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCountBackgroundColor(routeName),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count,
                  style: TextStyle(
                    color: _getCountTextColor(routeName),
                    fontSize: 12,
                    fontWeight: _getTextWeight(routeName),
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

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
        // Clear local auth data
        await StorageService.clearAuthData();
        
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
    bool isAdmin = userRole == 'admin' || userRole == 'super-admin';
    bool isSuperAdmin = userRole == 'super-admin';
    bool isUser = userRole == 'user' || userRole == 'client';

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Fixed Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepOrange, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                    backgroundImage: _userData?['profilePhoto'] != null
                        ? NetworkImage(_userData!['profilePhoto'])
                        : null,
                    child: _userData?['profilePhoto'] == null
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.deepOrange,
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
                ],
              ),
            ),
            
            // Scrollable Menu Items
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [

          // Secretary and Super Admin menu items
          if (isSecretary || isSuperAdmin) ...[
            _buildMenuItem(
              routeName: 'inbox',
              icon: Icons.inbox,
              title: 'Inbox',
              count: _getCount('inbox'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InboxScreen()),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'today',
              icon: Icons.today,
              title: 'Today',
              count: _getCount('today'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TodayScreen()),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'tomorrow',
              icon: Icons.event,
              title: 'Tomorrow',
              count: _getCount('tomorrow'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TomorrowScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'upcoming',
              icon: Icons.schedule,
              title: 'Upcoming',
              count: _getCount('upcoming'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UpcomingScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'addNew',
              icon: Icons.add_circle_outline,
              title: 'Add New',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewScreen()),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'globalSearch',
              icon: Icons.search,
              title: 'Global Search',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const GlobalSearchScreen()),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'assignedToMe',
              icon: Icons.assignment_ind,
              title: 'Assigned to Me',
              count: _getCount('assignedToMe'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignedToMeScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'starred',
              icon: Icons.star,
              title: 'Starred',
              count: _getCount('starred'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StarredScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'deleted',
              icon: Icons.delete_outline,
              title: 'Deleted Appointments',
              count: _getCount('deleted'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeletedAppointmentsScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'darshanLine',
              icon: Icons.queue,
              title: 'Darshan Line',
              count: _getCount('darshanLine'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),

            _buildMenuItem(
              routeName: 'referenceFormList',
              icon: Icons.list_alt,
              title: 'Reference Form List',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferenceFromListScreen()),
                );
              },
            ),
          ],



          // Admin-specific menu items (to be implemented)
          if (isAdmin && !isSuperAdmin) ...[
            _buildMenuItem(
              routeName: 'adminDashboard',
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              count: '0',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to admin dashboard
              },
            ),
            _buildMenuItem(
              routeName: 'manageUsers',
              icon: Icons.people,
              title: 'Manage Users',
              count: '0',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to user management
              },
            ),
          ],

          // Create Desk User - Available for both Admin and Super Admin
          // if (isAdmin) ...[
          //   _buildMenuItem(
          //     routeName: 'createDeskUser',
          //     icon: Icons.person_add,
          //     title: 'Create Desk User',
          //     onTap: () {
          //       Navigator.pop(context);
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(builder: (context) => const CreateDeskUserScreen()),
          //       );
          //     },
          //   ),
          // ],

          // User/Client-specific menu items (to be implemented)
          if (isUser) ...[
            _buildMenuItem(
              routeName: 'myAppointments',
              icon: Icons.calendar_today,
              title: 'My Appointments',
              count: '0',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to user appointments
              },
            ),
            _buildMenuItem(
              routeName: 'appointmentHistory',
              icon: Icons.history,
              title: 'Appointment History',
              count: '0',
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to appointment history
              },
            ),
          ],
          // Quick Darshan Line Navigation Item - Commented out
          // ListTile(
          //   leading: const Icon(Icons.queue, color: Colors.deepOrange),
          //   title: const Text('Quick Darshan Line'),
          //   onTap: () {
          //     Navigator.pop(context); // Close drawer
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const QuickDarshanLineScreen(),
          //       ),
          //     );
          //   },
          // ),
          // Send Bulk Email & SMS Navigation Item - Commented out
          // ListTile(
          //   leading: const Icon(Icons.email, color: Colors.deepOrange),
          //   title: const Text('Send Bulk Email & SMS'),
          //   onTap: () {
          //     Navigator.pop(context); // Close drawer
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const BulkEmailSmsScreen(),
          //       ),
          //     );
          //   },
          // ),



          // User Profile Navigation Item
          // ListTile(
          //   leading: const Icon(Icons.person, color: Colors.deepOrange),
          //   title: const Text('User Profile'),
          //   onTap: () {
          //     Navigator.pop(context); // Close drawer
          //     Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(builder: (context) => const UserScreen()),
          //     );
          //   },
          // ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.grey),
            title: const Text('Account Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.grey),
            title: const Text('Unique Phone Code'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UniquePhoneCodeScreen(),
                ),
              );
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

          // Export Data Navigation Item - Commented out
          // ListTile(
          //   leading: const Icon(Icons.file_download, color: Colors.grey),
          //   title: const Text('Export Data'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ExportDataScreen(),
          //       ),
          //     );
          //   },
          // ),

          // Forward Request Logs Navigation Item - Commented out
          // ListTile(
          //   leading: const Icon(Icons.forward, color: Colors.grey),
          //   title: const Text('Forward Request Logs'),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => const ForwardRequestLogsScreen(),
          //       ),
          //     );
          //   },
          // ),



          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _handleLogout,
          ),

          // Build Number
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey[600]),
            title: Text(
              'Build 3.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              // Optional: Add any action when build number is tapped
            },
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
