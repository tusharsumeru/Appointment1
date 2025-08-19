import 'package:flutter/material.dart';
import '../components/user/user_appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../action/jwt_utils.dart';
import 'user_sidebar.dart';
import 'edit_appointment_screen.dart';

class UserHistoryScreen extends StatefulWidget {
  const UserHistoryScreen({super.key});

  @override
  State<UserHistoryScreen> createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends State<UserHistoryScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  bool isLoadingMore = false; // Track loading state for "Load More" button
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 1;
  int totalPages = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadUserAppointments();
  }

  Future<void> _loadUserAppointments({bool refresh = false}) async {
    print('🔄 _loadUserAppointments called with refresh: $refresh');
    
    // Check if widget is still mounted
    if (!mounted) {
      print('🔄 Widget not mounted, skipping load');
      return;
    }
    
    if (refresh) {
      print('🔄 Refreshing appointments list...');
      setState(() {
        currentPage = 1;
        appointments = [];
        hasMoreData = true;
      });
    }

    if (!hasMoreData && !refresh) return;

    if (mounted) {
      setState(() {
        if (refresh) {
          isLoading = true;
          hasError = false;
          errorMessage = '';
        }
      });
    }

    try {
      // Get current user ID from JWT token
      final token = await StorageService.getToken();
      if (token == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'No authentication token found. Please login again.';
          });
        }
        return;
      }

      final userId = JwtUtils.extractMongoId(token);
      if (userId == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = 'Could not extract user ID from authentication token.';
          });
        }
        return;
      }

      // Fetch appointments from API
      final result = await ActionService.getUserAppointments(
        userId: userId,
        page: currentPage,
        limit: 10,
      );

      if (result['success'] == true) {
        final List<dynamic> newAppointments = result['data'] ?? [];
        final Map<String, dynamic> pagination = result['pagination'] ?? {};
        
        print('🔄 Loaded ${newAppointments.length} appointments from API');
        if (refresh) {
          print('🔄 Refreshing appointments list with ${newAppointments.length} appointments');
        }
        
        if (mounted) {
          setState(() {
            if (refresh) {
              appointments = List<Map<String, dynamic>>.from(newAppointments);
            } else {
              appointments.addAll(List<Map<String, dynamic>>.from(newAppointments));
            }
            
            currentPage = pagination['currentPage'] ?? currentPage;
            totalPages = pagination['totalPages'] ?? 1;
            hasMoreData = currentPage < totalPages;
            isLoading = false;
            hasError = false;
          });
        }
        
        print('🔄 Total appointments in state: ${appointments.length}');
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            hasError = true;
            errorMessage = result['message'] ?? 'Failed to load appointments';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Network error. Please check your connection and try again.';
        });
      }
    }
  }

  Future<void> _loadMoreAppointments() async {
    if (!hasMoreData || isLoading || isLoadingMore) return;
    
    if (mounted) {
      setState(() {
        isLoadingMore = true;
        currentPage++;
      });
    }
    
    await _loadUserAppointments();
    
    if (mounted) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUserAppointments(refresh: true),
          ),
        ],
      ),
      drawer: const UserSidebar(),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // // Header
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(20),
            //   child: const Text(
            //     'My Appointment History',
            //     style: TextStyle(
            //       fontSize: 24,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.black87,
            //     ),
            //     textAlign: TextAlign.center,
            //   ),
            // ),
            
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError && appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadUserAppointments(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No appointment history found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUserAppointments(refresh: true),
      child: Column(
        children: [
          // Appointments List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return UserAppointmentCard(
                  appointmentId: appointment['appointmentId'] ?? 'N/A',
                  status: appointment['appointmentStatus']?['status'] ?? 'Unknown',
                  userName: appointment['createdBy']?['fullName'] ?? 'N/A',
                  userTitle: appointment['userCurrentDesignation'] ?? 'N/A',
                  company: appointment['userCurrentCompany'] ?? 'N/A',
                  profilePhoto: appointment['profilePhoto'],
                  appointmentDateRange: _formatDateRange(appointment),
                  attendeesCount: _calculateTotalAttendees(appointment),
                  attendeePhotos: _extractAttendeePhotos(appointment),
                  purpose: appointment['appointmentPurpose'] ?? appointment['appointmentSubject'] ?? 'N/A',
                  assignedTo: _formatAssignedSecretary(appointment),
                  dateRange: _formatPreferredDateRange(appointment),
                  daysCount: _calculateDaysCount(appointment),
                  email: appointment['email'] ?? 'N/A',
                  phone: _formatPhoneNumber(appointment),
                  location: appointment['currentAddress'] ?? appointment['appointmentLocation']?['name'] ?? 'N/A',
                  appointmentData: appointment, // Pass the complete appointment data
                  onEditPressed: () async {
                    print('🔄 Edit button pressed for appointment: ${appointment['appointmentId']}');
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditAppointmentScreen(
                          appointmentData: appointment,
                        ),
                      ),
                    );
                    print('🔄 Returned from edit screen with result: $result');
                    // Refresh the appointments list after returning from edit screen
                    // Only refresh if the edit was successful (result == true)
                    if (result == true) {
                      print('🔄 Refreshing appointments list...');
                      // Use addPostFrameCallback to defer the refresh until after the current build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _loadUserAppointments(refresh: true);
                      });
                      // Show a brief success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Appointment updated successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      print('🔄 No refresh needed - edit was not successful');
                    }
                  },
                );
              },
            ),
          ),
          
          // Pagination Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${appointments.length} appointments',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Page $currentPage of $totalPages',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Load More Button
          if (hasMoreData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: isLoadingMore ? null : () => _loadMoreAppointments(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoadingMore
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Loading...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.keyboard_arrow_down),
                          const SizedBox(width: 8),
                          Text('Load More'),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateRange(Map<String, dynamic> appointment) {
    try {
      // Check for scheduled date/time
      final scheduledDateTime = appointment['scheduledDateTime'];
      if (scheduledDateTime != null) {
        final scheduledDate = scheduledDateTime['date'];
        final scheduledTime = scheduledDateTime['time'];
        
        if (scheduledDate != null) {
          final date = DateTime.parse(scheduledDate);
          final formattedDate = '${date.day}/${date.month}/${date.year}';
          
          if (scheduledTime != null) {
            return '$formattedDate at $scheduledTime';
          }
          return formattedDate;
        } else {
          // If scheduled date is null, show "Date not approved yet"
          return 'Date not approved yet';
        }
      }
      
      // Check for preferred date range
      final preferredDateRange = appointment['preferredDateRange'];
      if (preferredDateRange != null) {
        final fromDate = preferredDateRange['fromDate'];
        final toDate = preferredDateRange['toDate'];
        
        if (fromDate != null && toDate != null) {
          final from = DateTime.parse(fromDate);
          final to = DateTime.parse(toDate);
          final fromFormatted = '${from.day}/${from.month}/${from.year}';
          final toFormatted = '${to.day}/${to.month}/${to.year}';
          return '$fromFormatted to $toFormatted';
        }
      }
      
      return 'Date not scheduled';
    } catch (e) {
      return 'Date not available';
    }
  }

  int _calculateDaysCount(Map<String, dynamic> appointment) {
    try {
      // Check for preferred date range ONLY - this is the only source for day calculation
      final preferredDateRange = appointment['preferredDateRange'];
      
      if (preferredDateRange != null) {
        final fromDate = preferredDateRange['fromDate'];
        final toDate = preferredDateRange['toDate'];
        
        if (fromDate != null && toDate != null) {
          final from = DateTime.parse(fromDate);
          final to = DateTime.parse(toDate);
          
          // Calculate the difference in days and add 1 to include both start and end dates
          // Example: 28-30 = 28, 29, 30 = 3 days
          final difference = to.difference(from).inDays;
          final totalDays = difference + 1;
          
          // Additional validation for edge cases
          if (from.isAtSameMomentAs(to)) {
            return 1;
          }
          
          if (difference < 0) {
            // Warning: Negative difference detected! fromDate is after toDate
            // This might indicate a data issue
          }
          
          return totalDays;
        } else {
          // Missing fromDate or toDate in preferredDateRange
        }
      } else {
        // No preferredDateRange found
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatPhoneNumber(Map<String, dynamic> appointment) {
    try {
      // Check for phoneNumber field
      final phoneNumber = appointment['phoneNumber'];
      if (phoneNumber != null && phoneNumber is Map<String, dynamic>) {
        final countryCode = phoneNumber['countryCode'] ?? '';
        final number = phoneNumber['number'] ?? '';
        if (number.isNotEmpty) {
          return '$countryCode$number';
        }
      }
      
      // Check for reference person phone number
      final referencePerson = appointment['referencePerson'];
      if (referencePerson != null && referencePerson is Map<String, dynamic>) {
        final refPhoneNumber = referencePerson['phoneNumber'];
        if (refPhoneNumber != null && refPhoneNumber is Map<String, dynamic>) {
          final countryCode = refPhoneNumber['countryCode'] ?? '';
          final number = refPhoneNumber['number'] ?? '';
          if (number.isNotEmpty) {
            return '$countryCode$number';
          }
        }
      }
      
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAssignedSecretary(Map<String, dynamic> appointment) {
    try {
      final assignedSecretary = appointment['assignedSecretary'];
      if (assignedSecretary is Map<String, dynamic>) {
        final fullName = assignedSecretary['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
      return 'Not assigned yet';
    } catch (e) {
      return 'Not assigned yet';
    }
  }

  String _formatPreferredDateRange(Map<String, dynamic> appointment) {
    try {
      // Check for preferred date range
      final preferredDateRange = appointment['preferredDateRange'];
      if (preferredDateRange != null) {
        final fromDate = preferredDateRange['fromDate'];
        final toDate = preferredDateRange['toDate'];
        
        if (fromDate != null && toDate != null) {
          final from = DateTime.parse(fromDate);
          final to = DateTime.parse(toDate);
          final fromFormatted = '${from.day}/${from.month}/${from.year}';
          final toFormatted = '${to.day}/${to.month}/${to.year}';
          return '$fromFormatted to $toFormatted';
        }
      }
      
      return 'No preferred date range';
    } catch (e) {
      return 'Date range not available';
    }
  }

  List<String>? _extractAttendeePhotos(Map<String, dynamic> appointment) {
    try {
      final List<String> photos = [];
      
      // Add main user's photo first
      final mainUserPhoto = appointment['profilePhoto'];
      if (mainUserPhoto != null && mainUserPhoto.toString().isNotEmpty) {
        photos.add(mainUserPhoto);
      }
      
      // Add accompanying users' photos
      final accompanyUsers = appointment['accompanyUsers'];
      if (accompanyUsers != null && accompanyUsers['users'] != null) {
        final List<dynamic> users = accompanyUsers['users'];
        
        for (final user in users) {
          if (user is Map<String, dynamic> && user['profilePhotoUrl'] != null && user['profilePhotoUrl'].toString().isNotEmpty) {
            photos.add(user['profilePhotoUrl']);
          }
        }
      }
      
      return photos.isNotEmpty ? photos : null;
    } catch (e) {
      return null;
    }
  }

  int _calculateTotalAttendees(Map<String, dynamic> appointment) {
    try {
      // Check for accompanyUsers first (this is the most reliable source)
      final accompanyUsers = appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final numberOfUsers = accompanyUsers['numberOfUsers'] ?? 0;
        return numberOfUsers; ///total number of users
      }
      
      // Fallback: check for numberOfUsers in main appointment data
      final numberOfUsers = appointment['numberOfUsers'];
      if (numberOfUsers != null) {
        return (numberOfUsers as num).toInt();
      }
      
      // If no data available, return 1 (at least the main user)
      return 1;
    } catch (e) {
      print('Error calculating total attendees: $e');
      return 1; // Return 1 if there's an error (at least the main user)
    }
  }
} 