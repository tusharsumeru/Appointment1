import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../components/inbox/appointment_detail_page.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Search parameters
  String _searchQuery = '';
  String _searchMode = 'all';
  String _status = '';
  String _meetingType = '';
  String _appointmentType = '';
  String _dateFrom = '';
  String _dateTo = '';
  bool _starred = false;
  String _locationId = '';
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  bool _includeDeleted = false;
  String _searchFields = 'all';
  String _priority = 'relevance';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 0;
  int _totalCount = 0;
  bool _hasMoreData = true;
  
  // Filter modal state
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Removed automatic load more on scroll - now only manual button click
  }

  Future<void> _performSearch({bool isLoadMore = false}) async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    try {
      final response = await ActionService.globalSearchAppointments(
        query: _searchQuery,
        searchMode: _searchMode,
        status: _status.isNotEmpty ? _status : null,
        meetingType: _meetingType.isNotEmpty ? _meetingType : null,
        appointmentType: _appointmentType.isNotEmpty ? _appointmentType : null,
        dateFrom: _dateFrom.isNotEmpty ? _dateFrom : null,
        dateTo: _dateTo.isNotEmpty ? _dateTo : null,
        starred: _starred,
        locationId: _locationId.isNotEmpty ? _locationId : null,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        includeDeleted: _includeDeleted,
        searchFields: _searchFields,
        priority: _priority,
        page: isLoadMore ? _currentPage + 1 : 1,
        limit: 20,
      );

      if (response['success']) {
        final data = response['data'] as List;
        final pagination = response['pagination'];

        if (isLoadMore) {
          setState(() {
            _searchResults.addAll(data.cast<Map<String, dynamic>>());
            _currentPage = pagination['currentPage'];
            _totalPages = pagination['totalPages'];
            _totalCount = pagination['totalCount'];
            _hasMoreData = pagination['hasNextPage'];
          });
        } else {
          setState(() {
            _searchResults = data.cast<Map<String, dynamic>>();
            _currentPage = pagination['currentPage'];
            _totalPages = pagination['totalPages'];
            _totalCount = pagination['totalCount'];
            _hasMoreData = pagination['hasNextPage'];
          });
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Search failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMoreData) {
      _performSearch(isLoadMore: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _status = '';
      _meetingType = '';
      _appointmentType = '';
      _dateFrom = '';
      _dateTo = '';
      _starred = false;
      _locationId = '';
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
      _includeDeleted = false;
      _searchFields = 'all';
      _priority = 'relevance';
    });
    _performSearch();
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateValue.toString());
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _getAppointmentStatus(Map<String, dynamic> appointment) {
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      return appointmentStatus['status']?.toString() ?? 'Unknown';
    }
    return appointment['mainStatus']?.toString() ?? 'Unknown';
  }

  String _getPersonName(Map<String, dynamic> appointment) {
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final fullName = guestInformation['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

    // Try different name fields
    final referencePerson = appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['name']?.toString() ?? 'No Name';
    }
    
    final appointmentFor = appointment['appointmentFor'];
    if (appointmentFor is Map<String, dynamic>) {
      final otherPersonDetails = appointmentFor['otherPersonDetails'];
      if (otherPersonDetails is Map<String, dynamic>) {
        return otherPersonDetails['fullName']?.toString() ?? 'No Name';
      }
    }
    
    return appointment['appointmentSubject']?.toString() ?? 'No Name';
  }

  String _getEmail(Map<String, dynamic> appointment) {
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final email = guestInformation['emailId']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }

    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final email = optional['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }

    final referencePerson = appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['email']?.toString() ?? 'No Email';
    }
    
    return appointment['email']?.toString() ?? 'No Email';
  }

  String _getPhoneNumber(Map<String, dynamic> appointment) {
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final phoneNumber = guestInformation['phoneNumber']?.toString();
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          return phoneNumber;
        }
      }
    }

    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final mobileNumber = optional['mobileNumber'];
        if (mobileNumber is Map<String, dynamic>) {
          final countryCode = mobileNumber['countryCode']?.toString() ?? '';
          final number = mobileNumber['number']?.toString() ?? '';
          if (number.isNotEmpty) {
            return '$countryCode$number';
          }
        }
      }
    }

    final referencePerson = appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final phoneNumber = referencePerson['phoneNumber'];
      if (phoneNumber is Map<String, dynamic>) {
        final countryCode = phoneNumber['countryCode']?.toString() ?? '';
        final number = phoneNumber['number']?.toString() ?? '';
        if (countryCode.isNotEmpty && number.isNotEmpty) {
          return '$countryCode$number';
        }
      }
    }
    
    return appointment['phoneNumber']?.toString() ?? 'No Phone';
  }

  String _getCreatedByName(Map<String, dynamic> appointment) {
    final createdBy = appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      return createdBy['fullName']?.toString() ?? 'Unknown';
    }
    return 'Unknown';
  }

  String _getMeetingType(Map<String, dynamic> appointment) {
    // Check for virtual meeting details
    final virtualMeetingDetails = appointment['virtualMeetingDetails'];
    if (virtualMeetingDetails is Map<String, dynamic>) {
      final isVirtualMeeting = virtualMeetingDetails['isVirtualMeeting'] ?? false;
      if (isVirtualMeeting) {
        return 'Virtual Meeting';
      }
    }
    
    // Check for appointment type
    final appointmentType = appointment['appointmentType']?.toString();
    if (appointmentType != null && appointmentType.isNotEmpty) {
      return appointmentType.toUpperCase();
    }
    
    // Check if it's a quick appointment
    final quickApt = appointment['quick_apt'];
    if (quickApt is Map<String, dynamic>) {
      final isQuickAppointment = quickApt['isQuickAppointment'] ?? false;
      if (isQuickAppointment) {
        return 'Quick Appointment';
      }
    }
    
    return 'Regular Meeting';
  }

  String _getScheduledDate(Map<String, dynamic> appointment) {
    // Show scheduled date if available, otherwise show N/A
    final scheduledDateTime = appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final date = scheduledDateTime['date'];
      if (date != null && date.toString().isNotEmpty) {
        return _formatDate(date);
      }
    }
    
    // Return N/A if no scheduled date
    return 'N/A';
  }

  String _getEntryDate(Map<String, dynamic> appointment) {
    // Show created date for entry date
    return _formatDate(appointment['createdAt']);
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  String _getReferencePersonName(Map<String, dynamic> appointment) {
    final referencePerson = appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['name']?.toString() ?? 'Unknown';
    }
    return 'Unknown';
  }

  Widget _buildSearchResultCard(Map<String, dynamic> appointment, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      color: index % 2 == 0 ? Colors.white : Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with ID and Status
              if (appointment['appointmentId'] != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurple.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tag, size: 14, color: Colors.deepPurple.shade700),
                          const SizedBox(width: 6),
                          Text(
                            appointment['appointmentId'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_getAppointmentStatus(appointment)),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(_getAppointmentStatus(appointment)).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _getAppointmentStatus(appointment).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Name Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.deepPurple.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPersonName(appointment),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getEmail(appointment),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Reference Person for Guest Appointments
                    if (appointment['appointmentType']?.toString().toLowerCase() == 'guest') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reference: ${_getReferencePersonName(appointment)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            

              
              // Details Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Purpose
                    if (appointment['appointmentPurpose'] != null) ...[
                      _buildDetailRow(
                        icon: Icons.description,
                        label: 'Purpose',
                        value: appointment['appointmentPurpose'],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Meeting Type
                    _buildDetailRow(
                      icon: Icons.meeting_room,
                      label: 'Meeting Type',
                      value: _getMeetingType(appointment),
                    ),
                    const SizedBox(height: 12),
                    
                    // Starred Status
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Starred: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          appointment['starred'] == true ? 'Starred' : 'Not Starred',
                          style: TextStyle(
                            fontSize: 14,
                            color: appointment['starred'] == true ? Colors.amber.shade700 : Colors.grey.shade600,
                            fontWeight: appointment['starred'] == true ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (appointment['starred'] == true) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Appointment Date
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Appointment Date',
                      value: _getScheduledDate(appointment),
                    ),
                    const SizedBox(height: 12),
                    
                    // Entry Date
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Entry Date',
                      value: _getEntryDate(appointment),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAppointmentDetail(appointment),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _isLoadingMore 
            ? const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF553C9A)], // darker purple when loading
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // purple gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingMore ? null : _loadMore,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: _isLoadingMore 
                  ? const LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF553C9A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingMore) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Loading more...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Load More Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dot indicator
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _navigateToAppointmentDetail(Map<String, dynamic> appointment) async {
    // Get appointment ID from the search result
    final appointmentId = appointment['appointmentId']?.toString();
    
    if (appointmentId == null || appointmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Appointment ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check appointment status from search result first
    final appointmentStatus = appointment['appointmentStatus'];
    String? status;
    if (appointmentStatus is Map<String, dynamic>) {
      status = appointmentStatus['status']?.toString()?.toLowerCase();
    }
    
    // Check if appointment has scheduled date
    final scheduledDateTime = appointment['scheduledDateTime'];
    bool hasScheduledDate = false;
    if (scheduledDateTime is Map<String, dynamic>) {
      final scheduledDate = scheduledDateTime['date']?.toString();
      hasScheduledDate = scheduledDate != null && scheduledDate.isNotEmpty;
    }

    // Determine if appointment is scheduled
    bool isScheduled = false;
    if (status != null) {
      // Check if status is scheduled or confirmed
      isScheduled = status == 'scheduled' || status == 'confirmed';
    }
    
    // If not scheduled by status, check if it has a scheduled date
    if (!isScheduled && hasScheduledDate) {
      isScheduled = true;
    }

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
              Text('Loading appointment details...'),
            ],
          ),
        );
      },
    );

    try {
      // Fetch complete appointment details by ID
      final result = await ActionService.getAppointmentByIdDetailed(appointmentId);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success'] && result['data'] != null) {
        final appointmentData = result['data'];
        
        // Navigate based on appointment status
        if (isScheduled) {
          // For scheduled appointments, navigate to detail page with schedule screens flag
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(
                appointment: appointmentData,
                isFromDeletedAppointments: false,
                isFromScheduleScreens: true, // Set to true for scheduled appointments
              ),
            ),
          );
        } else {
          // For unscheduled appointments, navigate to detail page without schedule screens flag
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(
                appointment: appointmentData,
                isFromDeletedAppointments: false,
                isFromScheduleScreens: false, // Set to false for unscheduled appointments
              ),
            ),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load appointment details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildFiltersModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text(
                  'Search Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showFilters = false),
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          
          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Mode
                  const Text(
                    'Search Mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _searchMode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'exact', child: Text('Exact Match')),
                      DropdownMenuItem(value: 'fuzzy', child: Text('Fuzzy Search')),
                      DropdownMenuItem(value: 'semantic', child: Text('Semantic')),
                      DropdownMenuItem(value: 'smart', child: Text('Smart Search')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _searchMode = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _status.isEmpty ? null : _status,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Select Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value ?? '';
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Date Range
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'From Date',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _dateFrom = date.toIso8601String().split('T')[0];
                              });
                            }
                          },
                          readOnly: true,
                          controller: TextEditingController(text: _dateFrom),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'To Date',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _dateTo = date.toIso8601String().split('T')[0];
                              });
                            }
                          },
                          readOnly: true,
                          controller: TextEditingController(text: _dateTo),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Starred Filter
                  Row(
                    children: [
                      Checkbox(
                        value: _starred,
                        onChanged: (value) {
                          setState(() {
                            _starred = value ?? false;
                          });
                        },
                        activeColor: Colors.deepPurple,
                      ),
                      const Text(
                        'Starred Only',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Include Deleted
                  Row(
                    children: [
                      Checkbox(
                        value: _includeDeleted,
                        onChanged: (value) {
                          setState(() {
                            _includeDeleted = value ?? false;
                          });
                        },
                        activeColor: Colors.deepPurple,
                      ),
                      const Text(
                        'Include Deleted',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            'Clear Filters',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => _showFilters = false);
                            _performSearch();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Global Search',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [],
      ),
      drawer: const SidebarComponent(),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search appointments, people, subjects...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          _performSearch();
                        },
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                                          Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9500), Color(0xFFFFD700)], // orange-500 to yellow-500
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      child: ElevatedButton(
                        onPressed: () => _performSearch(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              

              
              // Results List
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error: $_error',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _searchResults.isEmpty && _searchQuery.isNotEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No results found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your search terms or filters',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _searchQuery.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Start searching',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Enter your search query above to find appointments',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      physics: const ClampingScrollPhysics(),
                                      controller: _scrollController,
                                      itemCount: _searchResults.length + (_hasMoreData ? 1 : 0),
                                      itemBuilder: (context, index) {
                                        // Show load more button at the end
                                        if (index == _searchResults.length) {
                                          return _buildLoadMoreButton();
                                        }
                                        
                                        return _buildSearchResultCard(_searchResults[index], index);
                                      },
                                    ),
                ),
              ),
            ],
          ),
          
          // Filters Modal
          if (_showFilters)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFilters = false),
                child: Container(
                  color: Colors.black54,
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping modal content
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildFiltersModal(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 