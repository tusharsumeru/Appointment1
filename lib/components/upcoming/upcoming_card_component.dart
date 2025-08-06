import 'package:flutter/material.dart';
import '../../action/action.dart';
import '../inbox/appointment_detail_page.dart';

class UpcomingCardComponent extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback? onRefresh;

  const UpcomingCardComponent({
    super.key, 
    required this.selectedDate,
    this.onRefresh,
  });

  @override
  State<UpcomingCardComponent> createState() => _UpcomingCardComponentState();
}

class _UpcomingCardComponentState extends State<UpcomingCardComponent> {
  List<Map<String, dynamic>> _upcomingAppointments = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _expandedCategories = {};

  // Category definitions
  final Map<String, Map<String, dynamic>> _categories = {
    'morning': {
      'title': 'Morning',
      'icon': Icons.wb_sunny,
      'color': Colors.deepPurple,
      'timeRange': {'start': 6, 'end': 15}, // 6 AM to 3 PM
    },
    'evening': {
      'title': 'Evening',
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.deepPurple,
      'timeRange': {'start': 15, 'end': 18.5}, // 3 PM to 6:30 PM
    },
    'night': {
      'title': 'Night',
      'icon': Icons.nightlight_round,
      'color': Colors.deepPurple,
      'timeRange': {'start': 20, 'end': 22}, // 8 PM to 10 PM
    },
    'tbs_req': {
      'title': 'TBS/Req',
      'icon': Icons.pending_actions,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on status
    },
    'done': {
      'title': 'Done',
      'icon': Icons.check_circle,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on status
    },
    'satsang_backstage': {
      'title': 'Satsang Backstage',
      'icon': Icons.music_note,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on venue
    },
    'gurukul': {
      'title': 'Gurukul',
      'icon': Icons.school,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on venue
    },
    'poojabackstage': {
      'title': 'Pooja Backstage',
      'icon': Icons.temple_hindu,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on venue
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchUpcomingAppointments();
  }

  @override
  void didUpdateWidget(UpcomingCardComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _fetchUpcomingAppointments();
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get selected date in YYYY-MM-DD format
      final dateString = ActionService.formatDateForAPI(widget.selectedDate);

      final result = await ActionService.getAppointmentsByScheduledDate(
        date: dateString,
      );

      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];

        if (appointmentsData.isNotEmpty) {
          final sortedAppointments = appointmentsData
              .cast<Map<String, dynamic>>();
          sortedAppointments.sort((a, b) {
            final timeA = a['scheduledTime']?.toString() ?? '';
            final timeB = b['scheduledTime']?.toString() ?? '';
            return timeA.compareTo(timeB);
          });

          _upcomingAppointments = sortedAppointments;
        } else {
          _upcomingAppointments = [];
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to fetch upcoming appointments';
        _upcomingAppointments = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _upcomingAppointments = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to refresh data
  Future<void> refresh() async {
    await _fetchUpcomingAppointments();
    widget.onRefresh?.call();
  }

  List<Map<String, dynamic>> _getAppointmentsForCategory(String categoryKey) {
    if (_upcomingAppointments.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
      case 'evening':
      case 'night':
        return _upcomingAppointments.where((appointment) {
          // First check if appointment is completed/done - if so, exclude it
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false; // Don't show completed appointments in time-based categories
          }

          // Check if appointment has TBS/Req communication preference - if so, exclude from time-based
          final communicationPreferences =
              appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false; // Don't show TBS/Req appointments in time categories
            }
          }

          // Check if appointment belongs to location-based categories - if so, exclude from time-based
          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');

          // If venue is satsang backstage, gurukul, or pooja backstage, exclude from time-based categories
          // Otherwise, continue to check time
          if (isSatsangBackstage || isGurukul || isPoojaBackstage) {
            return false; // Don't show location-based appointments in time categories
          }

          // Try multiple time fields
          String? timeString;

          // First try to get time from scheduledDateTime object
          final scheduledDateTime = appointment['scheduledDateTime'];
          if (scheduledDateTime is Map<String, dynamic>) {
            timeString = scheduledDateTime['time']?.toString();
          }

          // Fallback to other time fields
          if (timeString == null || timeString.isEmpty) {
            timeString =
                appointment['scheduledTime']?.toString() ??
                appointment['preferredTime']?.toString() ??
                appointment['createdAt']?.toString();
          }

          if (timeString == null) {
            return false;
          }

          try {
            // Handle time string like "20:55" or full DateTime
            int hour;
            if (timeString.contains(':')) {
              // Time string like "20:55"
              final parts = timeString.split(':');
              hour = int.parse(parts[0]);
            } else {
              // Full DateTime string
              final time = DateTime.parse(timeString);
              hour = time.hour;
            }

            final category = _categories[categoryKey]!;
            final start = category['timeRange']['start'] as num;
            final end = category['timeRange']['end'] as num;

            final isInRange = start <= end
                ? (hour >= start && hour < end)
                : (hour >= start || hour < end);

            return isInRange;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'tbs_req':
        return _upcomingAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          // Exclude completed/done appointments from TBS/Req category
          if (status == 'completed' || status == 'done') {
            return false;
          }

          // Check status-based TBS/Req
          final isStatusTbsReq =
              status == 'pending' || status == 'tbs' || status == 'requested';

          // Check communication preferences for TBS/Req
          final communicationPreferences =
              appointment['communicationPreferences'];
          bool isCommunicationTbsReq = false;

          if (communicationPreferences is List) {
            isCommunicationTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
          }

          final isTbsReq = isStatusTbsReq || isCommunicationTbsReq;

          return isTbsReq;
        }).toList();

      case 'done':
        return _upcomingAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          final isDone = status == 'completed' || status == 'done';
          return isDone;
        }).toList();

      case 'satsang_backstage':
        return _upcomingAppointments.where((appointment) {
          // Exclude completed/done appointments from location-based categories
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          // Exclude TBS/Req appointments from location-based categories
          final communicationPreferences =
              appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false; // Don't show TBS/Req appointments in location categories
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          
          // Exclude other location-based appointments from this category
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          if (isPoojaBackstage || isGurukul) {
            return false; // Don't show other location-based appointments in satsang backstage category
          }
          
          if (isSatsangBackstage) {
            print(
              '✅ SATSANG BACKSTAGE: Appointment ${appointment['_id']} at location: $location',
            );
          }
          return isSatsangBackstage;
        }).toList();

      case 'gurukul':
        return _upcomingAppointments.where((appointment) {
          // Exclude completed/done appointments from location-based categories
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          // Exclude TBS/Req appointments from location-based categories
          final communicationPreferences =
              appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false; // Don't show TBS/Req appointments in location categories
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isGurukul = location.contains('gurukul');
          
          // Exclude other location-based appointments from this category
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          if (isSatsangBackstage || isPoojaBackstage) {
            return false; // Don't show other location-based appointments in gurukul category
          }
          
          return isGurukul;
        }).toList();

      case 'poojabackstage':
        return _upcomingAppointments.where((appointment) {
          // Exclude completed/done appointments from location-based categories
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          // Exclude TBS/Req appointments from location-based categories
          final communicationPreferences =
              appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false; // Don't show TBS/Req appointments in location categories
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          
          // Exclude other location-based appointments from this category
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          if (isSatsangBackstage || isGurukul) {
            return false; // Don't show other location-based appointments in pooja backstage category
          }
          
          if (isPoojaBackstage) {
            print(
              '✅ POOJA BACKSTAGE: Appointment ${appointment['_id']} at location: $location',
            );
          }
          return isPoojaBackstage;
        }).toList();

      default:
        return [];
    }
  }

  String _getLocation(Map<String, dynamic> appointment) {
    // Try to get location from scheduledDateTime.venueLabel first
    final scheduledDateTime = appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null && venueLabel.isNotEmpty) {
        return venueLabel;
      }
    }

    // Try to get location from appointmentLocation object
    final appointmentLocation = appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final name = appointmentLocation['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    // Fallback to other location fields
    final location = appointment['location'];
    if (location is Map<String, dynamic>) {
      final name = location['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    // Try other string fields
    final locationString =
        appointment['locationName']?.toString() ??
        appointment['venue']?.toString() ??
        appointment['address']?.toString() ??
        appointment['city']?.toString() ??
        appointment['state']?.toString() ??
        appointment['country']?.toString();

    if (locationString != null && locationString.isNotEmpty) {
      return locationString;
    }

    return 'Not specified';
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return 'No time';

    try {
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }

  String _getAppointmentTime(Map<String, dynamic> appointment) {
    // Try to get time from scheduledDateTime object
    final scheduledDateTime = appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final time = scheduledDateTime['time']?.toString();
      if (time != null && time.isNotEmpty) {
        return time;
      }
    }

    // Fallback to other time fields
    return appointment['scheduledTime']?.toString() ??
        appointment['preferredTime']?.toString() ??
        appointment['createdAt']?.toString() ??
        'No time';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUpcomingAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUpcomingAppointments,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upcoming Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Appointments: ${_upcomingAppointments.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category cards
            ..._categories.entries.map((entry) {
              final categoryKey = entry.key;
              final category = entry.value;
              final appointments = _getAppointmentsForCategory(categoryKey);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCategoryCard(category, appointments, categoryKey),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
    List<Map<String, dynamic>> appointments,
    String categoryKey,
  ) {
    final isExpanded = _expandedCategories.contains(categoryKey);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section (clickable)
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(categoryKey);
                } else {
                  _expandedCategories.add(categoryKey);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: category['color'].withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isExpanded
                      ? Radius.zero
                      : const Radius.circular(12),
                  bottomRight: isExpanded
                      ? Radius.zero
                      : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(category['icon'], color: category['color'], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: category['color'],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: category['color'],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${appointments.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: category['color'],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: appointments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No appointments in this category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: appointments
                          .map(
                            (appointment) =>
                                _buildAppointmentCard(appointment, category),
                          )
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    Map<String, dynamic> category,
  ) {
    return GestureDetector(
      onTap: () async {
        // Check if this is a quick appointment
        final apptType = appointment['appt_type']?.toString();
        final quickApt = appointment['quick_apt'];
        final isQuickAppointment = apptType == 'quick' && 
                                  quickApt is Map<String, dynamic> && 
                                  quickApt['isQuickAppointment'] == true;

        if (isQuickAppointment) {
          // For quick appointments, fetch detailed data using the quick appointment API
          final appointmentId = appointment['appointmentId']?.toString();
          if (appointmentId != null && appointmentId.isNotEmpty) {
            try {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: const Text(
                            'Loading quick appointment details...',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );

              final result = await ActionService.getQuickAppointmentById(appointmentId);
              
              // Close loading dialog
              Navigator.of(context).pop();

              if (result['success'] && result['data'] != null) {
                // Navigate to appointment detail page with the fetched data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentDetailPage(
                      appointment: result['data'],
                      isFromScheduleScreens: true,
                    ),
                  ),
                );
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Failed to load quick appointment details'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e) {
              // Close loading dialog if still open
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              
              // Show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          // For regular appointments, use the existing flow
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(
                appointment: appointment,
                isFromScheduleScreens: true,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        children: [
          // Main content row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // First line - Patient profile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Patient image
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: _getProfilePhotoUrl(appointment).isNotEmpty
                              ? Image.network(
                                  _getProfilePhotoUrl(appointment),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getUserInitials(appointment),
                                          style: TextStyle(
                                            color: category['color'],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getUserInitials(appointment),
                                      style: TextStyle(
                                        color: category['color'],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Patient details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getAppointmentName(appointment),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getUserDesignation(appointment).isNotEmpty
                                  ? _getUserDesignation(appointment)
                                  : 'No designation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Second line - Status, Time, Accompany, Secretary (Side by Side Layout)
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Status (Check-in Status) - Only show for non-completed appointments
                      if (_getAppointmentStatusForDone(appointment).toLowerCase() != 'completed' && 
                          _getAppointmentStatusForDone(appointment).toLowerCase() != 'done') ...[
                        Row(
                          children: [
                            Text(
                              'Appointment Status: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _getStatusText(
                                  _getMainStatus(appointment),
                                ).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Appointment Status - Only show for completed appointments
                      if (_getAppointmentStatusForDone(appointment).toLowerCase() == 'completed' || 
                          _getAppointmentStatusForDone(appointment).toLowerCase() == 'done') ...[
                        Row(
                          children: [
                            Text(
                              'Appointment Status: ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _getStatusText(
                                  _getAppointmentStatusOnly(appointment),
                                ).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Time
                      Row(
                        children: [
                          Text(
                            'Time: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _getAppointmentTime(appointment),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Accompany
                      Row(
                        children: [
                          Text(
                            'Accompany: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_getAccompanyUsersCount(appointment)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Secretary
                      Row(
                        children: [
                          Text(
                            'Secretary: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getSecretaryInitials(appointment),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action button section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _buildActionButton(appointment),
          ),
        ],
      ),
      ),
    );
  }

  String _getAppointmentName(Map<String, dynamic> appointment) {
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final required = quickApt['required'];
      if (required is Map<String, dynamic>) {
        final name = required['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    // Try to get name from userId object first
    final userId = appointment['userId'];
    if (userId is Map<String, dynamic>) {
      final fullName = userId['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
    }

    // Fallback to other fields
    return appointment['userCurrentDesignation']?.toString() ??
        appointment['email']?.toString() ??
        'Unknown';
  }

  String _getUserEmail(Map<String, dynamic> appointment) {
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

    // Try to get email from userId object first
    final userId = appointment['userId'];
    if (userId is Map<String, dynamic>) {
      final email = userId['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }

    // Fallback to direct email field
    return appointment['email']?.toString() ?? 'No email';
  }

  String _getUserPhone(Map<String, dynamic> appointment) {
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

    // Try to get phone from userId object
    final userId = appointment['userId'];
    if (userId is Map<String, dynamic>) {
      final phone = userId['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        return phone;
      }
    }

    // Fallback to direct phone field
    return appointment['phone']?.toString() ?? 'No phone';
  }

  String _getUserDesignation(Map<String, dynamic> appointment) {
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final required = quickApt['required'];
      if (required is Map<String, dynamic>) {
        final designation = required['designation']?.toString();
        if (designation != null && designation.isNotEmpty) {
          return designation;
        }
      }
    }

    return appointment['userCurrentDesignation']?.toString() ?? '';
  }

  String _getUserInitials(Map<String, dynamic> appointment) {
    final name = _getAppointmentName(appointment);
    if (name == 'Unknown') return 'U';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _getProfilePhotoUrl(Map<String, dynamic> appointment) {
    // Check if this is a quick appointment and has a photo
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final photoUrl = optional['photo']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
    }
    
    // Fallback to profile photo
    return appointment['profilePhoto']?.toString() ?? '';
  }

  String _getSecretaryName(Map<String, dynamic> appointment) {
    // Try to get secretary name from assignedSecretary object
    final assignedSecretary = appointment['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      final fullName = assignedSecretary['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
    }

    // Fallback to other fields
    final secretaryName =
        appointment['secretaryName']?.toString() ??
        appointment['assignedTo']?.toString() ??
        appointment['secretary']?.toString() ??
        'Vishal Merani'; // Default fallback

    return secretaryName;
  }

  String _getSecretaryInitials(Map<String, dynamic> appointment) {
    // Try to get secretary name from assignedSecretary object
    final assignedSecretary = appointment['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      final fullName = assignedSecretary['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        final parts = fullName.split(' ');
        if (parts.length >= 2) {
          return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else if (parts.length == 1) {
          return parts[0][0].toUpperCase();
        }
      }
    }

    // Fallback to other fields
    final secretaryName =
        appointment['secretaryName']?.toString() ??
        appointment['assignedTo']?.toString() ??
        appointment['secretary']?.toString() ??
        'VM'; // Default fallback

    if (secretaryName == 'VM') return 'VM';

    final parts = secretaryName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return 'VM';
  }

  String _getAppointmentStatus(Map<String, dynamic> appointment) {
    // Check appointmentStatus.status first (this should be the primary source)
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      final status = appointmentStatus['status']?.toString();
      if (status != null && status.isNotEmpty) {
        // Always prioritize appointmentStatus.status over checkInStatus.mainStatus
        // Only use checkInStatus.mainStatus if appointmentStatus.status is not available
        return status;
      }
    }

    // Fallback to checkInStatus.mainStatus only if appointmentStatus.status is not available
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus is Map<String, dynamic>) {
      final mainStatus = checkInStatus['mainStatus']?.toString();
      if (mainStatus != null && mainStatus.isNotEmpty) {
        return mainStatus;
      }
    }

    // Final fallback to direct mainStatus field
    return appointment['mainStatus']?.toString() ?? 'Unknown';
  }

  String _getAppointmentStatusForDone(Map<String, dynamic> appointment) {
    // For "done" category, always use appointmentStatus.status (not checkInStatus.mainStatus)
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      final status = appointmentStatus['status']?.toString();
      if (status != null && status.isNotEmpty) {
        return status;
      }
    }

    // Fallback to direct mainStatus field if appointmentStatus.status is not available
    return appointment['mainStatus']?.toString() ?? 'Unknown';
  }

  String _getMainStatus(Map<String, dynamic> appointment) {
    // Get checkInStatus.mainStatus specifically
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus is Map<String, dynamic>) {
      final mainStatus = checkInStatus['mainStatus']?.toString();
      if (mainStatus != null && mainStatus.isNotEmpty) {
        return mainStatus;
      }
    }
    return 'Unknown';
  }

  String _getAppointmentStatusOnly(Map<String, dynamic> appointment) {
    // Get appointmentStatus.status specifically
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      final status = appointmentStatus['status']?.toString();
      if (status != null && status.isNotEmpty) {
        return status;
      }
    }
    return 'Unknown';
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    // Convert status to display text and get appropriate color
    switch (status.toLowerCase()) {
      case 'checked_in':
        return Colors.green; // Green for Admitted
      case 'not_arrived':
        return Colors.grey; // Grey for Not Arrived
      case 'checked_in_partial':
        return Colors.orange; // Orange for Admitted Partial
      case 'scheduled':
        return Colors.blue; // Blue for Scheduled
      case 'completed':
        return Colors.green; // Green for Completed
      default:
        return Colors.blue; // Default color for other statuses
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Unknown';
    
    // Convert status to display text
    switch (status.toLowerCase()) {
      case 'checked_in':
        return 'Admitted';
      case 'not_arrived':
        return 'Not Arrived';
      case 'checked_in_partial':
        return 'Admitted Partial';
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      default:
        return status; // Display exactly what comes from API for other statuses
    }
  }

  int _getAccompanyUsersCount(Map<String, dynamic> appointment) {
    final accompanyUsers = appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      return accompanyUsers['numberOfUsers'] ?? 0;
    }
    return 0;
  }

  Future<void> _handleMarkAsDone(Map<String, dynamic> appointment) async {
    try {
      // Get the appointment status ID
      final appointmentStatus = appointment['appointmentStatus'];
      if (appointmentStatus == null || appointmentStatus['_id'] == null) {
        _showSnackBar('Error: Appointment status not found', isError: true);
        return;
      }

      final appointmentStatusId = appointmentStatus['_id'].toString();
      final appointmentId = appointment['_id'].toString();

      // Show loading indicator
      _showSnackBar('Marking appointment as done...', isError: false);

      // Call the API
      final result = await ActionService.markAppointmentAsDone(
        appointmentStatusId: appointmentStatusId,
      );

      if (result['success']) {
        // Success - show success message and refresh the data
        _showSnackBar(
          result['message'] ?? 'Appointment marked as completed successfully',
          isError: false,
        );

        // Update the local appointment data immediately
        setState(() {
          final index = _upcomingAppointments.indexWhere((apt) => apt['_id'] == appointmentId);
          if (index != -1) {
            // Update the appointment status to 'completed' (prioritize appointmentStatus.status)
            if (_upcomingAppointments[index]['appointmentStatus'] is Map<String, dynamic>) {
              _upcomingAppointments[index]['appointmentStatus']['status'] = 'completed';
            }
            // Also update checkInStatus if it exists (fallback)
            if (_upcomingAppointments[index]['checkInStatus'] is Map<String, dynamic>) {
              _upcomingAppointments[index]['checkInStatus']['mainStatus'] = 'completed';
            }
            // Update direct mainStatus field as well (fallback)
            _upcomingAppointments[index]['mainStatus'] = 'completed';
          }
        });

        // Add a small delay to ensure server has updated the data
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the appointments list
        await _fetchUpcomingAppointments();
      } else {
        // Error - show error message
        _showSnackBar(
          result['message'] ?? 'Failed to mark appointment as completed',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackBar('Network error: $error', isError: true);
    }
  }

  Widget _buildActionButton(Map<String, dynamic> appointment) {
    final status = _getAppointmentStatus(appointment).toLowerCase();
    final isCompleted = status == 'completed' || status == 'done';

    return Row(
      children: [
        // Action button (Done/Undo) - takes 60% of width
        Expanded(
          flex: 3,
          child: isCompleted
              ? ElevatedButton(
                  onPressed: () async {
                    await _handleUndo(appointment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Undo',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.undo, size: 16),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: () async {
                    await _handleMarkAsDone(appointment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
        ),
        
        const SizedBox(width: 8),
        
        // View Details button - takes 40% of width
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: () {
              _navigateToAppointmentDetails(appointment);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'View',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.visibility, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToAppointmentDetails(Map<String, dynamic> appointment) async {
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;

    if (isQuickAppointment) {
      // For quick appointments, fetch detailed data using the quick appointment API
      final appointmentId = appointment['appointmentId']?.toString();
      if (appointmentId != null && appointmentId.isNotEmpty) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: const Text(
                        'Loading quick appointment details...',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          );

          final result = await ActionService.getQuickAppointmentById(appointmentId);
          
          // Close loading dialog
          Navigator.of(context).pop();

          if (result['success'] && result['data'] != null) {
            // Navigate to appointment detail page with the fetched data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(
                  appointment: result['data'],
                  isFromScheduleScreens: true,
                ),
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to load quick appointment details'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          // Close loading dialog if still open
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // For regular appointments, use the existing flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentDetailPage(
            appointment: appointment,
            isFromScheduleScreens: true,
          ),
        ),
      );
    }
  }

  Future<void> _handleUndo(Map<String, dynamic> appointment) async {
    try {
      // Get the appointment status ID
      final appointmentStatus = appointment['appointmentStatus'];
      if (appointmentStatus == null || appointmentStatus['_id'] == null) {
        _showSnackBar('Error: Appointment status not found', isError: true);
        return;
      }

      final appointmentStatusId = appointmentStatus['_id'].toString();
      final appointmentId = appointment['_id'].toString();

      // Show loading indicator
      _showSnackBar('Undoing appointment status...', isError: false);

      // Call the API
      final result = await ActionService.undoAppointmentStatus(
        appointmentStatusId: appointmentStatusId,
      );

      if (result['success']) {
        // Success - show success message and refresh the data
        _showSnackBar(
          result['message'] ?? 'Appointment status reverted successfully',
          isError: false,
        );

        // Update the local appointment data immediately
        setState(() {
          final index = _upcomingAppointments.indexWhere((apt) => apt['_id'] == appointmentId);
          if (index != -1) {
            // Update the appointment status back to 'scheduled' (original status)
            if (_upcomingAppointments[index]['appointmentStatus'] is Map<String, dynamic>) {
              _upcomingAppointments[index]['appointmentStatus']['status'] = 'scheduled';
            }
            // Also update checkInStatus if it exists (fallback)
            if (_upcomingAppointments[index]['checkInStatus'] is Map<String, dynamic>) {
              _upcomingAppointments[index]['checkInStatus']['mainStatus'] = 'scheduled';
            }
            // Update direct mainStatus field as well (fallback)
            _upcomingAppointments[index]['mainStatus'] = 'scheduled';
          }
        });

        // Add a small delay to ensure server has updated the data
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the appointments list
        await _fetchUpcomingAppointments();
      } else {
        // Error - show error message
        _showSnackBar(
          result['message'] ?? 'Failed to undo appointment status',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackBar('Network error: $error', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }


}
