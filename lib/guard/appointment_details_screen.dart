import 'package:flutter/material.dart';
import '../action/action.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  
  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic>? appointmentData;
  bool isLoading = true;
  String? errorMessage;
  


  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      final result = await ActionService.getAppointmentById(widget.appointmentId);
      
      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load appointment details: $e';
        isLoading = false;
      });
    }
  }



  // Helper methods for check-in status display
  String _getMainStatusText() {
    if (appointmentData == null) return 'Status not available';
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return 'Admitted';
      case 'checked_in_partial':
        return 'Partially Admitted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Admission';
      case 'not_arrived':
        return 'Not Arrived';
      default:
        return 'Not Arrived';
    }
  }

  Color _getMainStatusColor() {
    if (appointmentData == null) return Colors.grey;
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return Colors.green;
      case 'checked_in_partial':
        return Colors.lightGreen;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'not_arrived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getMainStatusIcon() {
    if (appointmentData == null) return Icons.info_outline;
    final mainStatus = appointmentData!['mainStatus']?.toString().toLowerCase();
    switch (mainStatus) {
      case 'checked_in':
        return Icons.check_circle;
      case 'checked_in_partial':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending_actions;
      case 'not_arrived':
        return Icons.schedule;
      default:
        return Icons.schedule;
    }
  }

  String _getUserStatusText(String status) {
    switch (status?.toString().toLowerCase()) {
      case 'checked_in':
        return 'Admitted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      case 'not_arrived':
        return 'Not Arrived';
      default:
        return 'Not Arrived';
    }
  }

  Color _getUserStatusColor(String status) {
    switch (status?.toString().toLowerCase()) {
      case 'checked_in':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'not_arrived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatPhoneNumber(dynamic phoneData) {
    if (phoneData == null) return 'N/A';
    try {
      final countryCode = phoneData['countryCode'] ?? '';
      final number = phoneData['number'] ?? '';
      if (countryCode.isEmpty && number.isEmpty) return 'N/A';
      return '$countryCode$number';
    } catch (e) {
      return 'N/A';
    }
  }

  bool _hasPendingUsers() {
    if (appointmentData == null || appointmentData!['users'] == null) return false;
    
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    return usersList.any((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
    });
  }

  int _getTotalUsers() {
    if (appointmentData == null || appointmentData!['users'] == null) return 0;
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    return usersList.length;
  }

  int _getAdmittedUsers() {
    if (appointmentData == null || appointmentData!['users'] == null) return 0;
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'checked_in';
    }).length;
  }

  int _getRejectedUsers() {
    if (appointmentData == null || appointmentData!['users'] == null) return 0;
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'rejected';
    }).length;
  }

  int _getNotArrivedUsers() {
    if (appointmentData == null || appointmentData!['users'] == null) return 0;
    final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
    }).length;
  }

  Widget _buildCountItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _calculateMainStatus(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 'not_arrived';

    int checkedInCount = 0;
    int rejectedCount = 0;
    int totalUsers = users.length;

    for (final user in users) {
      final status = user['status']?.toString().toLowerCase();
      if (status == 'checked_in') {
        checkedInCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      }
    }

    // All users admitted
    if (checkedInCount == totalUsers) {
      return 'checked_in';
    }
    
    // All users rejected
    if (rejectedCount == totalUsers) {
      return 'rejected';
    }
    
    // All users not arrived
    if (checkedInCount == 0 && rejectedCount == 0) {
      return 'not_arrived';
    }
    
    // Mixed conditions (some accepted, some rejected, some not arrived, etc.)
    return 'checked_in_partial';
  }

  void _showImageModal(String imageUrl, String userName) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow tapping outside to close
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), // Tap anywhere to close
            onDoubleTap: () => Navigator.of(context).pop(), // Double tap to close
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.person,
                      size: 200,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Admit/Reject functionality
  Future<void> _admitUser(Map<String, dynamic> user) async {
    if (appointmentData == null) return;

    try {
      final updatedUsers = List<Map<String, dynamic>>.from(appointmentData!['users']);
      final userIndex = updatedUsers.indexWhere((u) => 
        u['fullName'] == user['fullName'] && u['userType'] == user['userType']
      );

      if (userIndex != -1) {
        updatedUsers[userIndex] = {
          ...updatedUsers[userIndex],
          'status': 'checked_in',
          'checkedInAt': DateTime.now().toIso8601String(),
        };

        // Calculate main status based on all users
        final mainStatus = _calculateMainStatus(updatedUsers);

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: mainStatus,
          users: updatedUsers,
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user['fullName']} admitted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to admit user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    if (appointmentData == null) return;

    try {
      final updatedUsers = List<Map<String, dynamic>>.from(appointmentData!['users']);
      final userIndex = updatedUsers.indexWhere((u) => 
        u['fullName'] == user['fullName'] && u['userType'] == user['userType']
      );

      if (userIndex != -1) {
        updatedUsers[userIndex] = {
          ...updatedUsers[userIndex],
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
        };

        // Calculate main status based on all users
        final mainStatus = _calculateMainStatus(updatedUsers);

        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: appointmentData!['_id'],
          mainStatus: mainStatus,
          users: updatedUsers,
        );

        if (result['success']) {
          setState(() {
            appointmentData = result['data'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user['fullName']} rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to reject user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _admitAllUsers() async {
    if (appointmentData == null) return;

    try {
      final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
      final updatedUsers = usersList.map<Map<String, dynamic>>((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        return {
          ...userMap,
          'status': 'checked_in',
          'checkedInAt': DateTime.now().toIso8601String(),
        };
      }).toList();

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: appointmentData!['_id'],
        mainStatus: 'checked_in',
        users: updatedUsers,
      );

      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All users admitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to admit all users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAllUsers() async {
    if (appointmentData == null) return;

    try {
      final List<dynamic> usersList = appointmentData!['users'] as List<dynamic>;
      final updatedUsers = usersList.map<Map<String, dynamic>>((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        return {
          ...userMap,
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
        };
      }).toList();

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: appointmentData!['_id'],
        mainStatus: 'rejected',
        users: updatedUsers,
      );

      if (result['success']) {
        setState(() {
          appointmentData = result['data'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All users rejected successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to reject all users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final fullName = user['fullName'] ?? 'Unknown';
    final userType = user['userType'] ?? 'unknown';
    final status = user['status'] ?? 'unknown';
    final profilePhotoUrl = user['profilePhotoUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getUserStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First line: Index and Name (removed status from right corner)
          Text(
            '${index + 1}. $fullName${userType == 'main' ? ' (Main Appointee)' : ''}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          
          // Second line: Full size image
          GestureDetector(
            onTap: () {
              if (profilePhotoUrl != null) {
                _showImageModal(profilePhotoUrl, fullName);
              }
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1a237e).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: profilePhotoUrl != null
                    ? Image.network(
                        profilePhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1a237e).withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Color(0xFF1a237e),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF1a237e).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Color(0xFF1a237e),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Third line: Action buttons or status display
          if (status == 'checked_in') ...[
            // Show checked in status instead of buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Admitted',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'rejected') ...[
            // Show rejected status instead of buttons
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rejected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show action buttons for non-admitted users
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _admitUser(user),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Admit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectUser(user),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1a237e)),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAppointmentDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appointment ID Card with Main Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Appointment ID: ${appointmentData?['appointmentId'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            _getMainStatusIcon(),
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Status: ${_getMainStatusText()}',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Show completion message when all users are processed (moved above count)
                      if (!_hasPendingUsers()) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'All users have been processed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // User Count Summary (always visible)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCountItem('Total', _getTotalUsers(), Icons.people, Colors.blue),
                            _buildCountItem('Admitted', _getAdmittedUsers(), Icons.check_circle, Colors.green),
                            _buildCountItem('Rejected', _getRejectedUsers(), Icons.cancel, Colors.red),
                            _buildCountItem('Not Arrived', _getNotArrivedUsers(), Icons.schedule, Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Admit All and Reject All Buttons (only show when there are pending users)
                      if (_hasPendingUsers()) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _admitAllUsers,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Admit All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _rejectAllUsers,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Reject All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),

                      // User Cards
                      if (appointmentData?['users'] != null) ...[
                        ...appointmentData!['users'].asMap().entries.map<Widget>((entry) => 
                          _buildUserCard(entry.value, entry.key)
                        ).toList(),
                      ],
                    ],
                  ),
                ),
    );
  }
} 