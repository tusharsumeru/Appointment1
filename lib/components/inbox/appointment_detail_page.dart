import 'package:flutter/material.dart';
import 'user_images_screen.dart';
import '../../action/action.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isEditing = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Face match data storage
  Map<int, List<Map<String, dynamic>>> _faceMatchData = {};
  Map<int, bool> _isLoadingFaceMatch = {};
  Map<int, String?> _faceMatchErrors = {};
  
  // Filter state
  String _selectedFilter = '30_days'; // Default to 30 days
  bool _isRefreshing = false;
  
  // Appointments overview state
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _appointmentHistory = [];
  bool _isLoadingOverview = false;

  @override
  void initState() {
    super.initState();
    // Initialize with empty text
    _notesController.text = "";
    _remarksController.text = "";
    
    // Fetch appointments overview data
    _fetchAppointmentsOverview();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _remarksController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildNetworkImage(String imageUrl, double iconSize) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.person, size: iconSize, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }



  String _getUserName(int index) {
    // Generate user names based on index and attendee count
    if (index == 0) {
      return _getCreatedByName(); // Main user is the creator
    } else {
      // Get accompanying user names from API data
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'] as List<dynamic>?;
        if (users != null && index - 1 < users.length) {
          final user = users[index - 1];
          if (user is Map<String, dynamic>) {
            return user['fullName']?.toString() ?? 'User ${index + 1}';
          }
        }
      }
      
      // Fallback names
      return 'User ${index + 1}';
    }
  }

  String _getUserLabel(int index) {
    if (index == 0) {
      return '(Main User)';
    } else {
      // Get age from API data
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'] as List<dynamic>?;
        if (users != null && index - 1 < users.length) {
          final user = users[index - 1];
          if (user is Map<String, dynamic>) {
            final age = user['age']?.toString();
            if (age != null && age.isNotEmpty) {
              return '($age years old)';
            }
          }
        }
      }
      
      // Fallback ages
      return '(Adult)';
    }
  }

  int _getUserMatches(int index) {
    // For main user (index 0), always return at least 1 for profile image
    if (index == 0) {
      // Check if we have face match data for main user
      final faceMatchResults = _faceMatchData[index] ?? [];
      
      if (faceMatchResults.isNotEmpty) {
        final result = faceMatchResults[0]; // Get first result
        
        if (result['apiResult'] != null) {
          final apiResult = result['apiResult'];
          
          // Get matches from all time periods
          final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
          final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
          final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
          
          // Return total count of all matches + 1 for profile image
          return matches30.length + matches60.length + matches90.length + 1;
        }
      }
      
      // If no face match data available, return 1 for profile image
      return 1;
    }
    
    // For accompanying users, count matches from API result
    final faceMatchResults = _faceMatchData[index] ?? [];
    
    if (faceMatchResults.isNotEmpty) {
      final result = faceMatchResults[0]; // Get first result
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Return total count of all matches for this specific user
        return matches30.length + matches60.length + matches90.length;
      }
    }
    
    // If no face match data available, return 0 (will be fetched on refresh or navigation)
    return 0;
  }

  String _extractAge(String label) {
    // Extract age from labels like "(13 years old)", "(27 years old)", etc.
    final ageMatch = RegExp(r'\((\d+)\s+years?\s+old\)').firstMatch(label);
    if (ageMatch != null) {
      return '${ageMatch.group(1)} years';
    }
    
    // Handle main user case
    if (label.contains('Main User')) {
      return 'Main User';
    }
    
    return label;
  }

  Future<void> _fetchFaceMatchData(int userIndex) async {
    setState(() {
      _isLoadingFaceMatch[userIndex] = true;
      _faceMatchErrors[userIndex] = null;
    });

    try {
      // Use MongoDB ObjectId instead of appointmentId string
      final mongoDbId = widget.appointment['_id']?.toString() ?? '';
      if (mongoDbId.isEmpty) {
        throw Exception('MongoDB ID not found');
      }
      
      final result = await ActionService.getFaceMatchResultByAppointmentId(mongoDbId);
      
      if (result['success']) {
        final data = result['data'];
        List<Map<String, dynamic>> faceMatchResults = [];
        
        if (data != null) {
          if (data is List) {
            // Get the user's photo URL to match with API results
            final userPhotoUrl = _getUserImageUrl(userIndex);
            
            // Find the matching result by comparing photo URLs
            for (final resultItem in data) {
              if (resultItem is Map<String, dynamic>) {
                final resultPhotoUrl = resultItem['photoUrl']?.toString();
                if (resultPhotoUrl == userPhotoUrl) {
                  faceMatchResults = [resultItem];
                  break;
                }
              }
            }
            
            // If no match found by photo URL, try different matching strategies
            if (faceMatchResults.isEmpty) {
              // For main user (index 0), try to find result without userId or with main user's userId
              if (userIndex == 0) {
                // Look for result that might be for main user (no accompanyUser field or different structure)
                for (final resultItem in data) {
                  if (resultItem is Map<String, dynamic>) {
                    // Check if this result doesn't have accompanyUser field (likely main user)
                    if (!resultItem.containsKey('accompanyUser')) {
                      faceMatchResults = [resultItem];
                      break;
                    }
                  }
                }
              }
              
              // If still no match, fall back to index-based matching
              if (faceMatchResults.isEmpty) {
                final apiIndex = userIndex - 1; // Convert to 0-based index
                if (apiIndex >= 0 && apiIndex < data.length) {
                  final userResult = data[apiIndex];
                  if (userResult is Map<String, dynamic>) {
                    faceMatchResults = [userResult];
                  }
                }
              }
            }
          } else if (data is Map<String, dynamic>) {
            // If it's a single result, use it for main user or first accompanying user
            if (userIndex == 0 || userIndex == 1) {
              faceMatchResults = [data];
            }
          }
        }
        
        setState(() {
          _faceMatchData[userIndex] = faceMatchResults;
          _isLoadingFaceMatch[userIndex] = false;
        });
      } else {
        setState(() {
          _faceMatchErrors[userIndex] = result['message'] ?? 'Failed to fetch face match results';
          _isLoadingFaceMatch[userIndex] = false;
        });
      }
    } catch (e) {
      setState(() {
        _faceMatchErrors[userIndex] = 'Network error: $e';
        _isLoadingFaceMatch[userIndex] = false;
      });
    }
  }

  void _navigateToUserImages(String userName, int imageCount, int userIndex) async {
    // Get the user's image URL based on index
    String userImageUrl = _getUserImageUrl(userIndex);
    
    // Fetch face match data for the specific user (including main user)
    await _fetchFaceMatchData(userIndex);
    
    // For main user, ensure we have at least 1 image count
    int finalImageCount = imageCount;
    if (userIndex == 0) {
      // Recalculate image count after fetching data
      final updatedMatches = _getUserMatches(userIndex);
      finalImageCount = updatedMatches > 0 ? updatedMatches : 1; // At least show profile image
    } else if (imageCount == 0) {
      // For accompanying users, recalculate after fetching data
      final updatedMatches = _getUserMatches(userIndex);
      finalImageCount = updatedMatches;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserImagesScreen(
          userName: userName,
          imageCount: finalImageCount,
          userImageUrl: userImageUrl,
          faceMatchData: _faceMatchData[userIndex] ?? [],
          isLoading: _isLoadingFaceMatch[userIndex] ?? false,
          error: _faceMatchErrors[userIndex],
          userIndex: userIndex,
        ),
      ),
    );
  }

  String _getUserImageUrl(int userIndex) {
    // Get user images from API data
    if (userIndex == 0) {
      return widget.appointment['profilePhoto']?.toString() ?? 
             'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
    }
    
    // Get accompanying user images from API data
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      final users = accompanyUsers['users'] as List<dynamic>?;
      if (users != null && userIndex - 1 < users.length) {
        final user = users[userIndex - 1];
        if (user is Map<String, dynamic>) {
          final imageUrl = user['profilePhotoUrl']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
      }
    }
    
    // Fallback to default image
    return widget.appointment['profilePhoto']?.toString() ?? 
           'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
  }

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentRole() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? '';
  }

  String _getAppointmentCompany() {
    return widget.appointment['userCurrentCompany']?.toString() ?? '';
  }

  String _getAppointmentImageUrl() {
    return widget.appointment['profilePhoto']?.toString() ?? 
           'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? '';
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Show Match',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem(
                    value: '30_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 30 Days'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: '60_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 60 Days'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: '90_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_month, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 90 Days'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAccompanyingUsers() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh face match data for all users including main user
      final attendeeCount = _getAttendeeCount();
      
      for (int i = 0; i < attendeeCount; i++) {
        await _fetchFaceMatchData(i);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face match data refreshed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _fetchAppointmentsOverview() async {
    setState(() {
      _isLoadingOverview = true;
    });

    try {
      // Get the MongoDB _id from the appointment data
      String? userId = widget.appointment['_id']?.toString();
      
      // If still not found, try _id field directly (this might be the appointment ID, not user ID)
      if (userId == null || userId.isEmpty) {
        // If user ID is not found, we cannot fetch appointments overview
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        return;
      }
      
      if (userId == null || userId.isEmpty) {
        print('Warning: User ID not found in appointment data. Available fields: ${widget.appointment.keys.toList()}');
        print('CreatedBy data: ${widget.appointment['createdBy']}');
        // Don't throw exception, just set empty lists
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        return;
      }

      // Fetch upcoming appointments
      final upcomingResult = await ActionService.getUpcomingAppointmentsByUser(userId: userId);
      
      // Fetch appointment history
      final historyResult = await ActionService.getAppointmentHistoryByUser(userId: userId);
      
      // Debug: Print the results to see the data structure
      print('Upcoming result: $upcomingResult');
      print('History result: $historyResult');
      print('User ID being used: $userId');
      
      if (mounted) {
        setState(() {
          if (upcomingResult['success'] && upcomingResult['data'] != null) {
            final List<dynamic> upcomingData = upcomingResult['data'];
            if (upcomingData is List) {
              _upcomingAppointments = upcomingData.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
            } else {
              _upcomingAppointments = [];
            }
          } else {
            _upcomingAppointments = [];
          }
          
          if (historyResult['success'] && historyResult['data'] != null) {
            final List<dynamic> historyData = historyResult['data'];
            if (historyData is List) {
              _appointmentHistory = historyData.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
            } else {
              _appointmentHistory = [];
            }
          } else {
            _appointmentHistory = [];
          }
          
          _isLoadingOverview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch appointments overview: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _refreshAppointmentsOverview() async {
    await _fetchAppointmentsOverview();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointments overview refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _shouldShowUser(int userIndex) {
    if (userIndex == 0) return true; // Always show main user
    
    // For time-based filtering, we'll filter based on appointment creation date
    final appointmentCreatedAt = widget.appointment['createdAt']?.toString();
    if (appointmentCreatedAt != null) {
      try {
        final appointmentDate = DateTime.parse(appointmentCreatedAt);
        final now = DateTime.now();
        final daysDifference = now.difference(appointmentDate).inDays;
        
        switch (_selectedFilter) {
          case '30_days':
            return daysDifference <= 30;
          case '60_days':
            return daysDifference <= 60;
          case '90_days':
            return daysDifference <= 90;
          default:
            return daysDifference <= 30; // Default to 30 days
        }
      } catch (e) {
        // If date parsing fails, show all
        return true;
      }
    }
    
    return true;
  }

  int _getFilteredAttendeeCount() {
    int count = 0;
    final totalAttendees = _getAttendeeCount();
    
    for (int i = 0; i < totalAttendees; i++) {
      if (_shouldShowUser(i)) {
        count++;
      }
    }
    
    return count;
  }

  int _getActualUserIndex(int filteredIndex) {
    int actualIndex = 0;
    int currentFilteredIndex = 0;
    final totalAttendees = _getAttendeeCount();
    
    for (int i = 0; i < totalAttendees; i++) {
      if (_shouldShowUser(i)) {
        if (currentFilteredIndex == filteredIndex) {
          actualIndex = i;
          break;
        }
        currentFilteredIndex++;
      }
    }
    
    return actualIndex;
  }

  String _getCreatedByName() {
    return widget.appointment['createdBy']?['name']?.toString() ?? 
           widget.appointment['createdBy']?['fullName']?.toString() ?? 
           'Not specified';
  }

  String _getCreatedByDesignation() {
    return widget.appointment['createdBy']?['designation']?.toString() ?? 
           widget.appointment['createdBy']?['currentDesignation']?.toString() ?? 
           'Not specified';
  }

  String _getCreatedByCompany() {
    return widget.appointment['createdBy']?['company']?.toString() ?? 
           widget.appointment['createdBy']?['currentCompany']?.toString() ?? 
           'Not specified';
  }

  String _getLocation() {
    // First try to get location from appointmentLocation object
    final appointmentLocation = widget.appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final name = appointmentLocation['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Fallback to other location fields
    final location = widget.appointment['location'];
    if (location is Map<String, dynamic>) {
      final name = location['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Try other string fields
    final locationString = widget.appointment['locationName']?.toString() ?? 
                          widget.appointment['venue']?.toString() ?? 
                          widget.appointment['address']?.toString() ?? 
                          widget.appointment['city']?.toString() ?? 
                          widget.appointment['state']?.toString() ?? 
                          widget.appointment['country']?.toString();
    
    if (locationString != null && locationString.isNotEmpty) {
      return locationString;
    }
    
    // If no location found, return "Not specified"
    return 'Not specified';
  }

  String _getDateRange() {
    final preferredDateRange = widget.appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate']?.toString() ?? '';
      final toDate = preferredDateRange['toDate']?.toString() ?? '';
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        final from = DateTime.tryParse(fromDate);
        final to = DateTime.tryParse(toDate);
        if (from != null && to != null) {
          return '${from.day}/${from.month}/${from.year} - ${to.day}/${to.month}/${to.year}';
        }
      }
    }
    return 'Not specified';
  }

  int _getAttendeeCount() {
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      return accompanyUsers['numberOfUsers'] ?? 1;
    }
    return 1;
  }



  String _getTeacherCode() {
    final aolTeacher = widget.appointment['aolTeacher'];
    if (aolTeacher is Map<String, dynamic>) {
      return aolTeacher['teacherCode']?.toString() ?? '';
    }
    return '';
  }

  bool _isTeacher() {
    final aolTeacher = widget.appointment['aolTeacher'];
    if (aolTeacher is Map<String, dynamic>) {
      return aolTeacher['isTeacher'] == true;
    }
    return false;
  }

  String _formatAppointmentDateTime(Map<String, dynamic> appointment) {
    try {
      // Debug: Print the appointment data to see its structure
      print('Appointment data for formatting: $appointment');
      print('Appointment keys: ${appointment.keys.toList()}');
      
      // Try to get scheduled date and time
      final scheduledDateTime = appointment['scheduledDateTime'];
      print('ScheduledDateTime: $scheduledDateTime');
      
      if (scheduledDateTime is Map<String, dynamic>) {
        final scheduledDate = scheduledDateTime['date']?.toString();
        final scheduledTime = scheduledDateTime['time']?.toString();
        
        print('ScheduledDate: $scheduledDate, ScheduledTime: $scheduledTime');
        
        if (scheduledDate != null && scheduledTime != null) {
          final date = DateTime.parse(scheduledDate);
          return '${date.day}/${date.month}/${date.year} at $scheduledTime';
        }
      }
      
      // Fallback to startTime and endTime
      final startTime = appointment['startTime']?.toString();
      final endTime = appointment['endTime']?.toString();
      
      print('StartTime: $startTime, EndTime: $endTime');
      
      if (startTime != null) {
        final start = DateTime.parse(startTime);
        if (endTime != null) {
          final end = DateTime.parse(endTime);
          return '${start.day}/${start.month}/${start.year} ${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
        } else {
          return '${start.day}/${start.month}/${start.year} ${start.hour}:${start.minute.toString().padLeft(2, '0')}';
        }
      }
      
      // Fallback to createdAt
      final createdAt = appointment['createdAt']?.toString();
      print('CreatedAt: $createdAt');
      
      if (createdAt != null) {
        final created = DateTime.parse(createdAt);
        return '${created.day}/${created.month}/${created.year}';
      }
      
      return 'Date not specified';
    } catch (e) {
      print('Error formatting appointment date time: $e');
      print('Error stack trace: ${StackTrace.current}');
      return 'Date not specified';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main User Information Section
            _buildMainUserSection(),
            
            // Accompanying Users Section
            _buildAccompanyingUsersSection(),
            
            // Teacher Verification Section
            _buildTeacherVerificationSection(),
            
            // Notes & Remarks Section
            _buildNotesRemarksSection(),
            
            // Appointments Overview Section
            _buildAppointmentsOverviewSection(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUserSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              // Profile Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.red, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(37),
                  child: _buildNetworkImage(_getAppointmentImageUrl(), 40),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCreatedByName(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCreatedByDesignation(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAppointmentCompany(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Request Details
          _buildDetailRow('Request ID', _getAppointmentId(), Icons.tag),
          _buildDetailRow('Date Range', _getDateRange(), Icons.calendar_today),
          _buildDetailRow('Location', _getLocation(), Icons.location_on),
          _buildDetailRow('Number of People', '${_getAttendeeCount()} People', Icons.people),
        ],
      ),
    );
  }

  Widget _buildAccompanyingUsersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and refresh button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accompanying Users',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Users accompanying this appointment. Click refresh to load face match data.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _isRefreshing ? null : () => _refreshAccompanyingUsers(),
                icon: _isRefreshing 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    )
                  : const Icon(Icons.refresh),
                tooltip: _isRefreshing ? 'Refreshing...' : 'Refresh face match data',
                style: IconButton.styleFrom(
                  backgroundColor: _isRefreshing ? Colors.grey[100] : Colors.blue[50],
                  foregroundColor: _isRefreshing ? Colors.grey[400] : Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Filter Section
          _buildFilterSection(),
          
          const SizedBox(height: 20),
          
          // User Cards
          Column(
            children: [
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _getFilteredAttendeeCount(), // Use filtered count
                  itemBuilder: (context, index) {
                    final actualIndex = _getActualUserIndex(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildUserCard(
                        _getUserName(actualIndex),
                        _getUserLabel(actualIndex),
                        _getUserMatches(actualIndex),
                        actualIndex == 0, // First user is main user
                        actualIndex, // Pass the user index
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Number Indicators (dynamic based on filtered attendee count)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_getFilteredAttendeeCount(), (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _currentPage == index 
                        ? Colors.blue 
                        : Colors.grey[300],
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentPage == index 
                          ? Colors.white 
                          : Colors.grey[600],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String name, String label, int matches, bool isMainUser, int userIndex) {
    // Determine if card should be clickable
    bool isClickable = matches > 0 || isMainUser; // Main user is always clickable
    
    return GestureDetector(
      onTap: isClickable ? () => _navigateToUserImages(name, matches, userIndex) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isClickable ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isClickable ? 0.1 : 0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: isClickable ? 1.0 : 0.6,
          child: Row(
            children: [
              // Profile Image (Square)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildNetworkImage(_getUserImageUrl(userIndex), 30),
                ),
              ),
              const SizedBox(width: 12),
              
              // User Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name and Label
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Total Matches with Image Icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            matches > 0 
                              ? 'Total Matches Found : $matches'
                              : _isLoadingFaceMatch[userIndex] == true
                                ? 'Loading matches...'
                                : 'Click refresh to load matches',
                            style: TextStyle(
                              fontSize: 12,
                              color: matches > 0 
                                ? Colors.grey[600]
                                : _isLoadingFaceMatch[userIndex] == true
                                  ? Colors.blue[600]
                                  : Colors.grey[500],
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                        if (matches > 0) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.photo_library,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ] else if (_isLoadingFaceMatch[userIndex] == true) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherVerificationSection() {
    final teacherCode = _getTeacherCode();
    final isTeacher = _isTeacher();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Verification',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teacher verification status for this appointment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Teacher Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isTeacher ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isTeacher ? Colors.green[200]! : Colors.grey[200]!),
            ),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _buildNetworkImage(_getAppointmentImageUrl(), 30),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Teacher Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAppointmentName(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isTeacher ? Icons.verified : Icons.cancel,
                            color: isTeacher ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isTeacher ? 'Verified By TAOL' : 'Not Verified',
                              style: TextStyle(
                                fontSize: 14,
                                color: isTeacher ? Colors.green[700] : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isTeacher && teacherCode.isNotEmpty) ...[
                        _buildTeacherDetail('Teacher Code', teacherCode),
                        _buildTeacherDetail('Teacher Type', 'TAOL Teacher'),
                        _buildTeacherDetail('Can Teach', 'Happiness Program'),
                      ] else ...[
                        _buildTeacherDetail('Teacher Status', 'Not a verified teacher'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Additional Details
          _buildDetailRow('Purpose', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
          _buildDetailRow('Are you an Art Of Living teacher', isTeacher ? 'Yes, Part Time AOL Teacher' : 'No', Icons.school),
          _buildDetailRow('Programs eligible to teach', isTeacher ? 'Happiness Program' : 'Not applicable', Icons.book),
          _buildDetailRow('Are you seeking Online or In-person appointment', 'In-person', Icons.person),
          _buildDetailRow('Tags', 'No tags', Icons.label),
        ],
      ),
    );
  }

  Widget _buildTeacherDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesRemarksSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes & Remarks',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notes and remarks for this appointment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Notes Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: _isEditing,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter notes here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Remarks Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Remarks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                enabled: _isEditing,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter remarks here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_isEditing) ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Changes saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Notes'),
                      content: const Text('Are you sure you want to delete the notes and remarks?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _notesController.clear();
                            _remarksController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notes deleted successfully!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsOverviewSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments Overview',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appointment history and upcoming appointments.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _isLoadingOverview ? null : () => _refreshAppointmentsOverview(),
                icon: _isLoadingOverview 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    )
                  : const Icon(Icons.refresh),
                tooltip: _isLoadingOverview ? 'Refreshing...' : 'Refresh appointments overview',
                style: IconButton.styleFrom(
                  backgroundColor: _isLoadingOverview ? Colors.grey[100] : Colors.blue[50],
                  foregroundColor: _isLoadingOverview ? Colors.grey[400] : Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Upcoming Appointments
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingOverview) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                ),
              ] else if (_upcomingAppointments.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No upcoming appointments found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._upcomingAppointments.where((appointment) => appointment is Map<String, dynamic>).map((appointment) {
                  try {
                    return _buildAppointmentItem(
                      appointment['createdBy']?['fullName']?.toString() ?? 'Unknown User',
                      _formatAppointmentDateTime(appointment),
                      appointment['appointmentStatus']?['status']?.toString() ?? 'Pending',
                      _getStatusColor(appointment['appointmentStatus']?['status']?.toString() ?? 'pending'),
                    );
                  } catch (e) {
                    print('Error building appointment item: $e');
                    return _buildAppointmentItem(
                      'Unknown User',
                      'Date not specified',
                      'Unknown',
                      Colors.grey,
                    );
                  }
                }).toList(),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Appointment History
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Appointment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingOverview) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                  ),
                ),
              ] else if (_appointmentHistory.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No appointment history found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Scrollable container for appointment history
                Container(
                  height: 300, // Fixed height for scrollable area
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Header for appointment history
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Appointment History',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_appointmentHistory.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable content
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _appointmentHistory.where((appointment) => appointment is Map<String, dynamic>).map((appointment) {
                                try {
                                  return _buildAppointmentItem(
                                    appointment['createdBy']?['fullName']?.toString() ?? 'Unknown User',
                                    _formatAppointmentDateTime(appointment),
                                    appointment['appointmentStatus']?['status']?.toString() ?? 'Completed',
                                    _getStatusColor(appointment['appointmentStatus']?['status']?.toString() ?? 'completed'),
                                  );
                                } catch (e) {
                                  print('Error building appointment item: $e');
                                  return _buildAppointmentItem(
                                    'Unknown User',
                                    'Date not specified',
                                    'Unknown',
                                    Colors.grey,
                                  );
                                }
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String name, String dateTime, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey[300],
            ),
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 