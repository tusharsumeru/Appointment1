import 'package:flutter/material.dart';
import '../components/user/user_appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../action/jwt_utils.dart';
import 'user_sidebar.dart';
import 'edit_appointment_screen.dart';
import 'event_appointment_screen.dart';

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
        flexibleSpace: Container(
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
        ),
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
              physics: const ClampingScrollPhysics(), // Prevent overscroll/stretching
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                
                // Check if this is an event
                final isEvent = appointment['type']?.toString().toLowerCase() == 'event' || 
                               appointment['eventId'] != null;
                
                if (isEvent) {
                  // Map event data
                  final eventName = appointment['eventName']?.toString() ?? '';
                  final eventDescription = appointment['eventDescription']?.toString() ?? '';
                  // Use event description as purpose, or event name if description is not available
                  final purpose = eventDescription.isNotEmpty ? eventDescription : (eventName.isNotEmpty ? eventName : 'N/A');
                  
                  return UserAppointmentCard(
                    appointmentId: appointment['eventId']?.toString() ?? 'N/A',
                    status: appointment['eventStatus']?.toString() ?? 'Unknown',
                    userName: eventName.isNotEmpty ? eventName : 'Event', // Use event name as userName
                    userTitle: '',
                    company: '',
                    profilePhoto: appointment['eventImage'],
                    appointmentDateRange: _formatEventScheduledDate(appointment),
                    attendeesCount: _calculateEventAttendees(appointment),
                    attendeePhotos: null,
                    purpose: purpose,
                    assignedTo: 'N/A',
                    dateRange: _formatEventFromToDateRange(appointment),
                    daysCount: _calculateEventDaysCount(appointment),
                    email: appointment['createdBy']?['email'] ?? 'N/A',
                    phone: _formatEventPhoneNumber(appointment),
                    location: appointment['eventLocation'] ?? 'N/A',
                    appointmentData: appointment, // Pass the complete event data
                    appointmentAttachment: null,
                    onEditPressed: () async {
                      // Navigate to event edit screen
                      final eventId = appointment['eventId']?.toString();
                      if (eventId != null && eventId.isNotEmpty) {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                        
                        final eventResult = await ActionService.getEventById(eventId);
                        
                        // Hide loading indicator
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                        
                        if (mounted) {
                          if (eventResult['success'] == true) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventAppointmentScreen(
                                  eventData: eventResult['data'],
                                ),
                              ),
                            );
                            
                            // Refresh the list if event was updated successfully
                            if (result == true) {
                              _loadUserAppointments(refresh: true);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(eventResult['message'] ?? 'Failed to load event details'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event ID not found'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  );
                }
                
                // Regular appointment mapping
                // Debug attachment data
                final attachmentUrl = appointment['appointmentAttachment'];
                print('🔄 Appointment ${appointment['appointmentId']} attachment: $attachmentUrl');
                
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
                  appointmentAttachment: attachmentUrl, // Pass the attachment URL
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
                  backgroundColor: const Color(0xFFF97316),
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

  String _formatTimeTo12Hour(String time24) {
    try {
      // Parse the time string (format: "HH:mm")
      final parts = time24.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        
        String period = 'AM';
        int hour12 = hour;
        
        if (hour == 0) {
          hour12 = 12;
        } else if (hour == 12) {
          period = 'PM';
        } else if (hour > 12) {
          hour12 = hour - 12;
          period = 'PM';
        }
        
        return '$hour12:$minute $period';
      }
      return time24; // Return original if parsing fails
    } catch (e) {
      return time24; // Return original if any error occurs
    }
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
            final formattedTime = _formatTimeTo12Hour(scheduledTime);
            return '$formattedDate at $formattedTime';
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
      
      // Check if this is a guest appointment
      final appointmentType = appointment['appointmentType']?.toString().toLowerCase();
      final appointmentFor = appointment['appointmentFor'];
      final isGuestAppointment = appointmentType == 'guest' || 
                                 (appointmentFor != null && appointmentFor['type']?.toString().toLowerCase() == 'guest');
      
      if (isGuestAppointment) {
        // For guest appointments: show guest photo first, then accompanying users
        // Add guest's photo first
        final guestInformation = appointment['guestInformation'];
        if (guestInformation != null && guestInformation is Map<String, dynamic>) {
          final guestPhoto = guestInformation['profilePhotoUrl'];
          if (guestPhoto != null && guestPhoto.toString().isNotEmpty) {
            photos.add(guestPhoto);
          }
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
      } else {
        // For regular appointments: show main user's photo first, then accompanying users
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
      }
      
      return photos.isNotEmpty ? photos : null;
    } catch (e) {
      return null;
    }
  }

  // Format scheduled date for "Appointment Date" field
  String _formatEventScheduledDate(Map<String, dynamic> event) {
    try {
      // Check for scheduledDate - show scheduled date
      final scheduledDate = event['scheduledDate']?.toString();
      if (scheduledDate != null && scheduledDate.isNotEmpty && scheduledDate != 'null') {
        try {
          final dateUtc = DateTime.parse(scheduledDate);
          final date = dateUtc.toLocal(); // Convert UTC to local time
          final formattedDate = '${date.day}/${date.month}/${date.year}';
          return formattedDate;
        } catch (e) {
          // If parsing fails, continue to check other conditions
        }
      }
      
      // Check if event is pending - if no scheduled date and pending, show "Date Not Approved Yet"
      final eventStatus = event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? 
                         'pending';
      final isPending = eventStatus.toLowerCase() == 'pending';
      
      if (isPending) {
        return 'Date Not Approved Yet';
      }
      
      // If not scheduled and not pending, return empty or fallback
      return 'Not scheduled';
    } catch (e) {
      return 'Not scheduled';
    }
  }
  
  // Format from/to date range for "Date" field
  String _formatEventFromToDateRange(Map<String, dynamic> event) {
    try {
      // Check for event date range (from and to dates)
      final eventFromDateTime = event['fromDateTime']?.toString() ?? 
                               event['eventFromDateTime']?.toString();
      final eventToDateTime = event['toDateTime']?.toString() ?? 
                             event['eventToDateTime']?.toString();
      
      if (eventFromDateTime != null && eventToDateTime != null && 
          eventFromDateTime.isNotEmpty && eventToDateTime.isNotEmpty) {
        try {
          final fromDateUtc = DateTime.parse(eventFromDateTime);
          final toDateUtc = DateTime.parse(eventToDateTime);
          final fromDate = fromDateUtc.toLocal(); // Convert UTC to local time
          final toDate = toDateUtc.toLocal(); // Convert UTC to local time
          final fromFormatted = '${fromDate.day}/${fromDate.month}/${fromDate.year}';
          final toFormatted = '${toDate.day}/${toDate.month}/${toDate.year}';
          return '$fromFormatted to $toFormatted';
        } catch (e) {
          // If parsing fails, continue to check other conditions
        }
      } else if (eventFromDateTime != null && eventFromDateTime.isNotEmpty) {
        try {
          final dateUtc = DateTime.parse(eventFromDateTime);
          final date = dateUtc.toLocal(); // Convert UTC to local time
          final formattedDate = '${date.day}/${date.month}/${date.year}';
          return formattedDate;
        } catch (e) {
          // If parsing fails, continue to check other conditions
        }
      }
      
      // Fallback to createdAt if event dates are not available
      final createdAt = event['createdAt'];
      if (createdAt != null) {
        try {
          final dateUtc = DateTime.parse(createdAt);
          final date = dateUtc.toLocal(); // Convert UTC to local time
          final formattedDate = '${date.day}/${date.month}/${date.year}';
          return formattedDate;
        } catch (e) {
          // If parsing fails, return default message
        }
      }
      return 'Date not available';
    } catch (e) {
      return 'Date not available';
    }
  }
  
  int _calculateEventDaysCount(Map<String, dynamic> event) {
    try {
      final eventFromDateTime = event['eventFromDateTime'];
      final eventToDateTime = event['eventToDateTime'];
      
      if (eventFromDateTime != null && eventToDateTime != null) {
        final fromUtc = DateTime.parse(eventFromDateTime);
        final toUtc = DateTime.parse(eventToDateTime);
        final from = fromUtc.toLocal(); // Convert UTC to local time
        final to = toUtc.toLocal(); // Convert UTC to local time
        
        // Calculate the difference in days and add 1 to include both start and end dates
        final difference = to.difference(from).inDays;
        final totalDays = difference + 1;
        
        return totalDays > 0 ? totalDays : 1;
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }
  
  String _formatEventPhoneNumber(Map<String, dynamic> event) {
    try {
      final createdBy = event['createdBy'];
      if (createdBy != null && createdBy is Map<String, dynamic>) {
        final phoneNumber = createdBy['phoneNumber'];
        if (phoneNumber != null && phoneNumber is Map<String, dynamic>) {
          final countryCode = phoneNumber['countryCode'] ?? '';
          final number = phoneNumber['number'] ?? '';
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

  int _calculateEventAttendees(Map<String, dynamic> event) {
    try {
      final registeredCount = event['eventRegisteredCount'] ?? 0;
      final capacity = event['eventCapacity'] ?? 0;
      // Return registered count, or capacity if registered count is 0
      if (registeredCount is int) {
        return registeredCount > 0 ? registeredCount : (capacity is int ? capacity : 0);
      }
      if (registeredCount is num) {
        return registeredCount.toInt() > 0 ? registeredCount.toInt() : (capacity is num ? capacity.toInt() : 0);
      }
      return capacity is int ? capacity : (capacity is num ? capacity.toInt() : 0);
    } catch (e) {
      return 0;
    }
  }

  int _calculateTotalAttendees(Map<String, dynamic> appointment) {
    try {
      // Check if this is a guest appointment
      final appointmentType = appointment['appointmentType']?.toString().toLowerCase();
      final appointmentFor = appointment['appointmentFor'];
      final isGuestAppointment = appointmentType == 'guest' || 
                                 (appointmentFor != null && appointmentFor['type']?.toString().toLowerCase() == 'guest');
      
      // Check for accompanyUsers first (this is the most reliable source)
      final accompanyUsers = appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        // For large groups (>9), users array is empty and count is in numberOfUsers field
        // For small groups (≤9), users array contains the actual users
        final users = accompanyUsers['users'];
        final numberOfUsers = accompanyUsers['numberOfUsers'];
        
        int actualAccompanyingUsers = 0;
        
        // Check if this is a large group scenario (numberOfUsers > users.length)
        // This handles cases where users array has some users but numberOfUsers is much larger
        if (numberOfUsers != null && numberOfUsers > 0 && 
            (users == null || users.isEmpty || numberOfUsers > users.length)) {
          // Large groups: use numberOfUsers field
          actualAccompanyingUsers = (numberOfUsers as num).toInt();
        } else if (users != null && users is List && users.isNotEmpty) {
          // Small groups: use actual users array length
          actualAccompanyingUsers = users.length;
        } else if (numberOfUsers != null) {
          // Fallback: use numberOfUsers field
          actualAccompanyingUsers = (numberOfUsers as num).toInt();
        }
        
        if (isGuestAppointment) {
          // For guest appointments: count guest + actual accompanying users
          // The reference-as-accompany user is already included in numberOfUsers field
          return actualAccompanyingUsers + 1; // +1 for the guest
        } else {
          // For regular appointments: count main user + actual accompanying users
          return actualAccompanyingUsers + 1; // +1 for the main user
        }
      }
      
      // Fallback: check for numberOfUsers in main appointment data
      final numberOfUsers = appointment['numberOfUsers'];
      if (numberOfUsers != null) {
        return (numberOfUsers as num).toInt();
      }
      
      // If no data available, return 1 (at least the guest or main user)
      return 1;
    } catch (e) {
      print('Error calculating total attendees: $e');
      return 1; // Return 1 if there's an error (at least the guest or main user)
    }
  }
} 