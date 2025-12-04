import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../action/action.dart';
import '../components/inbox/appointment_detail_page.dart';
import '../components/inbox/event_detail_page.dart';

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

      if (response['success'] == true) {
        final data = response['data'] as List? ?? [];
        final pagination = response['pagination'] as Map<String, dynamic>? ?? {};

        if (isLoadMore) {
          setState(() {
            _searchResults.addAll(data.cast<Map<String, dynamic>>());
            _currentPage = pagination['currentPage'] as int? ?? _currentPage;
            _totalPages = pagination['totalPages'] as int? ?? _totalPages;
            _totalCount = pagination['totalCount'] as int? ?? _totalCount;
            _hasMoreData = pagination['hasNextPage'] as bool? ?? false;
          });
        } else {
          setState(() {
            _searchResults = data.cast<Map<String, dynamic>>();
            _currentPage = pagination['currentPage'] as int? ?? 1;
            _totalPages = pagination['totalPages'] as int? ?? 0;
            _totalCount = pagination['totalCount'] as int? ?? 0;
            _hasMoreData = pagination['hasNextPage'] as bool? ?? false;
          });
        }
      } else {
        setState(() {
          _error = response['message']?.toString() ?? 'Search failed. Please try again.';
        });
      }
    } catch (e) {
      // Extract user-friendly error message
      String errorMessage = 'An error occurred while searching.';
      
      if (e.toString().contains('Session expired')) {
        errorMessage = 'Your session has expired. Please login again.';
      } else if (e.toString().contains('Network error')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('Invalid search request')) {
        errorMessage = 'Invalid search request. Please check your search query.';
      } else if (e.toString().contains('Server error')) {
        errorMessage = 'Server error occurred. Please try again later.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'You do not have permission to perform this search.';
      } else if (e.toString().isNotEmpty) {
        // Remove "Exception: " prefix if present
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      setState(() {
        _error = errorMessage;
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
      final dateUtc = DateTime.parse(dateValue.toString());
      final date = dateUtc.toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatEventDateTime(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      final dateString = dateValue.toString();
      DateTime date;
      
      // Parse the date string
      final parsedDate = DateTime.parse(dateString);
      
      // For events, the time stored in UTC might actually be the intended local time
      // (stored incorrectly as UTC). So we use the UTC time directly without conversion
      // This prevents double conversion issues
      if (parsedDate.isUtc) {
        // Use UTC time directly as if it were local time
        // This handles the case where 9:30 AM was stored as 9:30 AM UTC
        // instead of being converted to 4:00 AM UTC (which is 9:30 AM IST)
        date = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedDate.hour,
          parsedDate.minute,
          parsedDate.second,
        );
      } else {
        date = parsedDate;
      }
      
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      // Format time in 12-hour format
      int hour = date.hour;
      String period = 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour == 12) {
        period = 'PM';
      } else if (hour > 12) {
        hour = hour - 12;
        period = 'PM';
      }
      
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '${date.day} ${months[date.month - 1]} ${date.year} (${hour.toString().padLeft(2, '0')}:$minute $period)';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatEventDateTimeVenue(Map<String, dynamic> result) {
    final List<String> parts = [];
    
    // Date and Time
    if (result['eventFromDateTime'] != null) {
      try {
        final dateString = result['eventFromDateTime'].toString();
        final parsedDate = DateTime.parse(dateString);
        DateTime date;
        
        // For events, use UTC time directly as if it were local time
        // This prevents double conversion issues
        if (parsedDate.isUtc) {
          date = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
          );
        } else {
          date = parsedDate;
        }
        
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        
        // Format time in 12-hour format
        int hour = date.hour;
        String period = 'AM';
        if (hour == 0) {
          hour = 12;
        } else if (hour == 12) {
          period = 'PM';
        } else if (hour > 12) {
          hour = hour - 12;
          period = 'PM';
        }
        
        final minute = date.minute.toString().padLeft(2, '0');
        parts.add('${date.day} ${months[date.month - 1]} ${date.year} (${hour.toString().padLeft(2, '0')}:$minute $period)');
      } catch (e) {
        parts.add('Invalid Date');
      }
    }
    
    // Venue
    if (result['eventLocation'] != null && result['eventLocation'].toString().isNotEmpty) {
      parts.add('Venue: ${result['eventLocation']}');
    }
    
    // Guests if available
    if (result['eventCapacity'] != null || result['numberOfGuests'] != null) {
      final guests = result['eventCapacity'] ?? result['numberOfGuests'] ?? 0;
      parts.add('Guests: $guests');
    }
    
    return parts.isEmpty ? 'N/A' : parts.join(' | ');
  }

  String _formatEventDetailsBlock(Map<String, dynamic> result) {
    final List<String> lines = [];
    
    // Date
    if (result['eventFromDateTime'] != null) {
      try {
        final dateString = result['eventFromDateTime'].toString();
        final parsedDate = DateTime.parse(dateString);
        DateTime date;
        
        // For events, use UTC time directly as if it were local time
        if (parsedDate.isUtc) {
          date = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
          );
        } else {
          date = parsedDate;
        }
        
        final day = date.day;
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final month = months[date.month - 1];
        final year = date.year;
        
        // Get ordinal suffix for day
        String daySuffix = 'th';
        if (day == 1 || day == 21 || day == 31) daySuffix = 'st';
        else if (day == 2 || day == 22) daySuffix = 'nd';
        else if (day == 3 || day == 23) daySuffix = 'rd';
        
        lines.add('Date: ${day}$daySuffix $month, $year');
      } catch (e) {
        lines.add('Date: Invalid Date');
      }
    }
    
    // Time
    if (result['eventFromDateTime'] != null) {
      try {
        final dateString = result['eventFromDateTime'].toString();
        final parsedDate = DateTime.parse(dateString);
        DateTime date;
        
        // For events, use UTC time directly as if it were local time
        if (parsedDate.isUtc) {
          date = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            parsedDate.hour,
            parsedDate.minute,
            parsedDate.second,
          );
        } else {
          date = parsedDate;
        }
        
        int hour = date.hour;
        String period = 'AM';
        if (hour == 0) {
          hour = 12;
        } else if (hour == 12) {
          period = 'PM';
        } else if (hour > 12) {
          hour = hour - 12;
          period = 'PM';
        }
        
        final minute = date.minute.toString().padLeft(2, '0');
        lines.add('Time: ${hour.toString().padLeft(2, '0')}:$minute $period');
      } catch (e) {
        // Skip if error
      }
    }
    
    // Venue
    if (result['eventLocation'] != null && result['eventLocation'].toString().isNotEmpty) {
      lines.add('Venue: ${result['eventLocation']}');
    }
    
    // Guests
    if (result['eventCapacity'] != null || result['numberOfGuests'] != null) {
      final guests = result['eventCapacity'] ?? result['numberOfGuests'] ?? 0;
      lines.add('Guests: $guests');
    }
    
    return lines.join('\n');
  }

  String _getAppointmentStatus(Map<String, dynamic> appointment) {
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      return appointmentStatus['status']?.toString() ?? 'Unknown';
    }
    return appointment['mainStatus']?.toString() ?? 'Unknown';
  }

  Widget _getAppointmentPurpose(Map<String, dynamic> appointment) {
    String? purposeText;
    
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final details = quickApt['details'];
      if (details is Map<String, dynamic>) {
        purposeText = details['purpose']?.toString();
      }
    }
    
    // For normal appointments, check appointmentPurpose or appointmentSubject
    if (purposeText == null || purposeText.isEmpty) {
      purposeText = appointment['appointmentPurpose']?.toString() ?? 
                    appointment['appointmentSubject']?.toString();
    }
    
    // If still no purpose, show "No purpose provided"
    if (purposeText == null || purposeText.isEmpty) {
      return Text(
        'No purpose provided',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }
    
    return Text(
      purposeText,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade700,
        height: 1.4,
      ),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  String _getPersonName(Map<String, dynamic> appointment) {
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final isQuickAppointment = quickApt['isQuickAppointment'] ?? false;
      if (isQuickAppointment) {
        final required = quickApt['required'];
        if (required is Map<String, dynamic>) {
          final name = required['name']?.toString();
          if (name != null && name.isNotEmpty) {
            return name;
          }
        }
      }
    }
    
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
      final name = referencePerson['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    final appointmentFor = appointment['appointmentFor'];
    if (appointmentFor is Map<String, dynamic>) {
      final otherPersonDetails = appointmentFor['otherPersonDetails'];
      if (otherPersonDetails is Map<String, dynamic>) {
        final fullName = otherPersonDetails['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
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

  String _formatAppointmentDateTime(Map<String, dynamic> appointment) {
    final scheduledDateTime = appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final date = scheduledDateTime['date'];
      final time = scheduledDateTime['time']?.toString();
      
      if (date != null && date.toString().isNotEmpty) {
        try {
          final dateUtc = DateTime.parse(date.toString());
          final dateLocal = DateTime(
            dateUtc.year,
            dateUtc.month,
            dateUtc.day,
            dateUtc.hour,
            dateUtc.minute,
            dateUtc.second,
          );
          
          final months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ];
          
          String dateStr = '${dateLocal.day} ${months[dateLocal.month - 1]} ${dateLocal.year}';
          
          // Add time if available
          if (time != null && time.isNotEmpty) {
            // Format time in 12-hour format
            try {
              final timeParts = time.split(':');
              if (timeParts.length >= 2) {
                int hour = int.parse(timeParts[0]);
                final minute = timeParts[1];
                String period = 'AM';
                if (hour == 0) {
                  hour = 12;
                } else if (hour == 12) {
                  period = 'PM';
                } else if (hour > 12) {
                  hour = hour - 12;
                  period = 'PM';
                }
                dateStr += ' (${hour.toString().padLeft(2, '0')}:$minute $period)';
              } else {
                dateStr += ' ($time)';
              }
            } catch (e) {
              dateStr += ' ($time)';
            }
          }
          
          return dateStr;
        } catch (e) {
          return _formatDate(date);
        }
      }
    }
    
    return 'N/A';
  }

  String _getEntryDate(Map<String, dynamic> appointment) {
    // For normal appointments, show fromDate from preferredDateRange
    // For quick appointments or if fromDate is not available, show createdAt
    final preferredDateRange = appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate'];
      if (fromDate != null) {
        return _formatDate(fromDate);
      }
    }
    // Fallback to createdAt
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

  // Check if result is an event
  bool _isEvent(Map<String, dynamic> result) {
    return result['_resultType']?.toString() == 'event' || 
           result['eventId'] != null;
  }

  Widget _buildSearchResultCard(Map<String, dynamic> result, int index) {
    final isEvent = _isEvent(result);
    
    // Extract appointment venue information for display
    String? appointmentVenue;
    bool hasAppointmentDate = false;
    bool hasAppointmentVenue = false;
    
    if (!isEvent) {
      if (result['scheduledDateTime'] is Map<String, dynamic>) {
        final scheduledDateTime = result['scheduledDateTime'] as Map<String, dynamic>;
        appointmentVenue = scheduledDateTime['venueLabel']?.toString();
        hasAppointmentVenue = appointmentVenue != null && appointmentVenue.isNotEmpty;
      }
      hasAppointmentDate = _formatAppointmentDateTime(result) != 'N/A';
    }
    
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
              if (isEvent) ...[
                // Event ID and Status in same row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '# ID: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            result['eventId']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getEventStatusColor(result['eventStatus']?.toString() ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (result['eventStatus']?.toString() ?? 'Unknown').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (result['appointmentId'] != null) ...[
                // Appointment ID and Status in same row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.tag, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '# ID: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            result['appointmentId']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_getAppointmentStatus(result)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getAppointmentStatus(result).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Name Section
              if (isEvent) ...[
                _buildDetailRow(
                  icon: Icons.event,
                  label: 'Name',
                  value: result['eventName']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 12),
              ] else ...[
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: _getPersonName(result),
                ),
                const SizedBox(height: 12),
              ],
            

              
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
                  children: isEvent ? [
                    // Subject/Purpose
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subject / Purpose:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result['eventName']?.toString() ?? 'Event',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                    if (result['eventDescription'] != null && result['eventDescription'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        result['eventDescription']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Type: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.event, size: 12, color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Event',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Appointment Date/Time/Venue
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Date / Time / Venue:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (result['eventFromDateTime'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _formatEventDateTime(result['eventFromDateTime']),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (result['eventLocation'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Venue: ${result['eventLocation']?.toString() ?? 'N/A'}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // Guests count if available
                                    if (result['eventCapacity'] != null || result['numberOfGuests'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.people, size: 14, color: Colors.blue.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Guests: ${result['eventCapacity'] ?? result['numberOfGuests'] ?? 0}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Starred
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Starred: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                result['starred'] == true ? 'Starred' : 'Not Starred',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: result['starred'] == true ? Colors.amber.shade700 : Colors.grey.shade600,
                                  fontWeight: result['starred'] == true ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (result['starred'] == true) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.star, size: 16, color: Colors.amber),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Created Date
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Created Date',
                      value: _formatDate(result['createdAt']),
                    ),
                    
                    // Secretary Notes if available
                    if (result['secretaryNotes'] != null && result['secretaryNotes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.note,
                        label: 'Notes',
                        value: result['secretaryNotes']?.toString() ?? 'N/A',
                      ),
                    ],
                  ] : [
                    // Appointment Details
                    // Subject/Purpose
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Subject / Purpose:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _getAppointmentPurpose(result),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Type
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Type: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.deepPurple.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.calendar_today, size: 12, color: Colors.deepPurple.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getMeetingType(result),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Appointment Date/Time/Venue
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointment Date / Time / Venue:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Check if we have any data
                                    if (hasAppointmentDate || hasAppointmentVenue) ...[
                                      // Date and Time
                                      if (hasAppointmentDate) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _formatAppointmentDateTime(result),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (hasAppointmentVenue) const SizedBox(height: 8),
                                      ],
                                      // Venue
                                      if (hasAppointmentVenue) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: Colors.blue.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Venue: $appointmentVenue',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ] else ...[
                                      // Show "Not available" if no date, time, or venue
                                      Text(
                                        'Not available',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Starred
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Starred: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                result['starred'] == true ? 'Starred' : 'Not Starred',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: result['starred'] == true ? Colors.amber.shade700 : Colors.grey.shade600,
                                  fontWeight: result['starred'] == true ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              if (result['starred'] == true) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.star, size: 16, color: Colors.amber),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Created Date
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Created Date',
                      value: _getEntryDate(result),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // View Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isEvent 
                    ? () => _navigateToEventDetail(result)
                    : () => _navigateToAppointmentDetail(result),
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

  Color _getEventStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
      case 'finished':
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
    // Don't navigate if this is an event
    if (_isEvent(appointment)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event details are not available yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

  Future<void> _navigateToEventDetail(Map<String, dynamic> event) async {
    // Get event ID from the search result
    final eventId = event['eventId']?.toString();
    
    if (eventId == null || eventId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Event ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
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
              Text('Loading event details...'),
            ],
          ),
        );
      },
    );

    try {
      // Fetch complete event details by ID
      final result = await ActionService.getEventById(eventId);
      
      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success'] && result['data'] != null) {
        final eventData = result['data'];
        
        // Navigate to event detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(
              event: eventData,
              onEventUpdated: () {
                // Refresh search results if needed
                _performSearch();
              },
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load event details'),
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