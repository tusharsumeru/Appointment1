import 'package:flutter/material.dart';
import '../../action/action.dart';
import '../inbox/appointment_detail_page.dart';
import '../inbox/event_detail_page.dart';
import '../common/profile_photo_dialog.dart';

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
  List<Map<String, dynamic>> _upcomingEvents = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _expandedCategories = {};

  // Category definitions
  final Map<String, Map<String, dynamic>> _categories = {
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
      'timeRange': {'start': 15, 'end': 20}, // 3 PM to 8 PM
    },
    'tbs_req': {
      'title': 'TBS/Req',
      'icon': Icons.pending_actions,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on status
    },
    'satsang_backstage': {
      'title': 'Satsang Backstage',
      'icon': Icons.music_note,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on venue
    },
    'night': {
      'title': 'Night',
      'icon': Icons.nightlight_round,
      'color': Colors.deepPurple,
      'timeRange': {'start': 20, 'end': 24}, // 8 PM to 11:59 PM (midnight)
    },
    'done': {
      'title': 'Done',
      'icon': Icons.check_circle,
      'color': Colors.deepPurple,
      'timeRange': null, // Based on status
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

      // Use getAppointmentsByScheduledDate which returns both appointments and events merged
      final result = await ActionService.getAppointmentsByScheduledDate(date: dateString);

      if (result['success']) {
        final List<dynamic> mergedData = result['data'] ?? [];

        // Separate appointments and events
        final List<Map<String, dynamic>> appointments = [];
        final List<Map<String, dynamic>> events = [];

        for (var item in mergedData) {
          if (item is Map<String, dynamic>) {
            if (item['type'] == 'event') {
              events.add(item);
            } else {
              appointments.add(item);
            }
          }
        }

        // Process appointments (EXISTING LOGIC - UNCHANGED)
        if (appointments.isNotEmpty) {
          final sortedAppointments = appointments;
          sortedAppointments.sort((a, b) {
            final timeA = a['scheduledTime']?.toString() ?? 
                         a['scheduledDateTime']?['time']?.toString() ?? '';
            final timeB = b['scheduledTime']?.toString() ?? 
                         b['scheduledDateTime']?['time']?.toString() ?? '';
            return timeA.compareTo(timeB);
          });
          _upcomingAppointments = sortedAppointments;
        } else {
          _upcomingAppointments = [];
        }

        // Store events (only scheduled ones are already filtered by backend)
        _upcomingEvents = events;
      } else {
        _error = result['message'] ?? 'Failed to fetch upcoming appointments';
        _upcomingAppointments = [];
        _upcomingEvents = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _upcomingAppointments = [];
      _upcomingEvents = [];
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

  List<Map<String, dynamic>> _getEventsForCategory(String categoryKey) {
    if (_upcomingEvents.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
      case 'night':
        return _upcomingEvents.where((event) {
          // Only show scheduled events (backend already filters, but double-check)
          final status = (event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? '').toLowerCase();
          if (status != 'scheduled') {
            return false;
          }

          // Get scheduledDate and convert to IST (UTC+5:30)
          final scheduledDate = event['scheduledDate']?.toString();
          
          if (scheduledDate == null || scheduledDate.isEmpty || scheduledDate == 'null') {
            return false;
          }

          try {
            // Parse UTC datetime and convert to IST (UTC+5:30)
            final dateTimeUtc = DateTime.parse(scheduledDate);
            // Convert to IST by adding 5 hours and 30 minutes
            final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
            final hour = dateTimeIst.hour;

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

      case 'evening_445':
        return _upcomingEvents.where((event) {
          final status = (event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? '').toLowerCase();
          if (status != 'scheduled') {
            return false;
          }

          final scheduledDate = event['scheduledDate']?.toString();
          if (scheduledDate == null || scheduledDate.isEmpty || scheduledDate == 'null') {
            return false;
          }

          try {
            final dateTimeUtc = DateTime.parse(scheduledDate);
            final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
            // Check for exactly 4:45 PM (16:45)
            return dateTimeIst.hour == 16 && dateTimeIst.minute == 15;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening_500':
        return _upcomingEvents.where((event) {
          final status = (event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? '').toLowerCase();
          if (status != 'scheduled') {
            return false;
          }

          final scheduledDate = event['scheduledDate']?.toString();
          if (scheduledDate == null || scheduledDate.isEmpty || scheduledDate == 'null') {
            return false;
          }

          try {
            final dateTimeUtc = DateTime.parse(scheduledDate);
            final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
            // Check for exactly 5:00 PM (17:00)
            return dateTimeIst.hour == 16 && dateTimeIst.minute == 25;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening':
        return _upcomingEvents.where((event) {
          final status = (event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? '').toLowerCase();
          if (status != 'scheduled') {
            return false;
          }

          final scheduledDate = event['scheduledDate']?.toString();
          if (scheduledDate == null || scheduledDate.isEmpty || scheduledDate == 'null') {
            return false;
          }

          try {
            final dateTimeUtc = DateTime.parse(scheduledDate);
            final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
            final hour = dateTimeIst.hour;
            final minute = dateTimeIst.minute;

            // Evening range: 3 PM (15:00) to 8 PM (20:00)
            // But exclude exactly 4:45 PM and 5:00 PM
            final isInEveningRange = hour >= 15 && hour < 20;
            final isNot445 = !(hour == 16 && minute == 45);
            final isNot500 = !(hour == 17 && minute == 0);

            return isInEveningRange && isNot445 && isNot500;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'tbs_req':
      case 'done':
      default:
        // For other categories, return empty (events only in time-based categories)
        return [];
    }
  }

  List<Map<String, dynamic>> _getAppointmentsForCategory(String categoryKey) {
    if (_upcomingAppointments.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
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

      case 'evening_445':
        return _upcomingAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          final communicationPreferences = appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false;
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          if (isSatsangBackstage || isGurukul || isPoojaBackstage) {
            return false;
          }

          String? timeString;
          final scheduledDateTime = appointment['scheduledDateTime'];
          if (scheduledDateTime is Map<String, dynamic>) {
            timeString = scheduledDateTime['time']?.toString();
          }

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
            int hour, minute;
            if (timeString.contains(':')) {
              final parts = timeString.split(':');
              hour = int.parse(parts[0]);
              minute = parts.length > 1 ? int.parse(parts[1]) : 0;
            } else {
              final time = DateTime.parse(timeString);
              hour = time.hour;
              minute = time.minute;
            }

            // Check for exactly 4:45 PM (16:45)
            return hour == 16 && minute == 45;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening_500':
        return _upcomingAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          final communicationPreferences = appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false;
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          if (isSatsangBackstage || isGurukul || isPoojaBackstage) {
            return false;
          }

          String? timeString;
          final scheduledDateTime = appointment['scheduledDateTime'];
          if (scheduledDateTime is Map<String, dynamic>) {
            timeString = scheduledDateTime['time']?.toString();
          }

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
            int hour, minute;
            if (timeString.contains(':')) {
              final parts = timeString.split(':');
              hour = int.parse(parts[0]);
              minute = parts.length > 1 ? int.parse(parts[1]) : 0;
            } else {
              final time = DateTime.parse(timeString);
              hour = time.hour;
              minute = time.minute;
            }

            // Check for exactly 5:00 PM (17:00)
            return hour == 17 && minute == 0;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening':
        return _upcomingAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          if (status == 'completed' || status == 'done') {
            return false;
          }

          final communicationPreferences = appointment['communicationPreferences'];
          if (communicationPreferences is List) {
            final hasTbsReq = communicationPreferences.any(
              (pref) => pref.toString() == 'TBS/Req',
            );
            if (hasTbsReq) {
              return false;
            }
          }

          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage =
              location.contains('satsang') && location.contains('backstage');
          final isGurukul = location.contains('gurukul');
          final isPoojaBackstage =
              location.contains('pooja') && location.contains('backstage');
          if (isSatsangBackstage || isGurukul || isPoojaBackstage) {
            return false;
          }

          String? timeString;
          final scheduledDateTime = appointment['scheduledDateTime'];
          if (scheduledDateTime is Map<String, dynamic>) {
            timeString = scheduledDateTime['time']?.toString();
          }

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
            int hour, minute;
            if (timeString.contains(':')) {
              final parts = timeString.split(':');
              hour = int.parse(parts[0]);
              minute = parts.length > 1 ? int.parse(parts[1]) : 0;
            } else {
              final time = DateTime.parse(timeString);
              hour = time.hour;
              minute = time.minute;
            }

            // Evening range: 3 PM (15:00) to 8 PM (20:00)
            // But exclude exactly 4:45 PM and 5:00 PM
            final isInEveningRange = hour >= 15 && hour < 20;
            final isNot445 = !(hour == 16 && minute == 45);
            final isNot500 = !(hour == 17 && minute == 0);

            return isInEveningRange && isNot445 && isNot500;
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
    if (timeString == null || timeString.isEmpty) return 'No time';

    try {
      // Check if it's just a time string like "14:30" or "14:30:00"
      if (timeString.contains(':') && !timeString.contains('T') && !timeString.contains(' ')) {
        // It's just a time string, parse it directly
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          
          // Convert to 12-hour format with AM/PM
          final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          final period = hour < 12 ? 'AM' : 'PM';
          
          return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
        }
      } else {
        // It's a full DateTime string, parse it normally
        final time = DateTime.parse(timeString);
        final hour = time.hour;
        final minute = time.minute;
        
        // Convert to 12-hour format with AM/PM
        final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final period = hour < 12 ? 'AM' : 'PM';
        
        return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // If parsing fails, return the original string
      return timeString;
    }
    
    return 'Invalid time';
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
        physics: const ClampingScrollPhysics(),
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
                  Row(
                    children: [
                      Text(
                        'Total Appointments: ${_upcomingAppointments.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Total Events: ${_upcomingEvents.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category cards
            ..._categories.entries.map((entry) {
              final categoryKey = entry.key;
              final category = entry.value;
              List<Map<String, dynamic>> appointments;
              List<Map<String, dynamic>> events;
              
              // For evening category, include sub-sections in the count
              if (categoryKey == 'evening') {
                appointments = _getAppointmentsForCategory('evening');
                events = _getEventsForCategory('evening');
                // Add items from sub-sections
                appointments.addAll(_getAppointmentsForCategory('evening_445'));
                appointments.addAll(_getAppointmentsForCategory('evening_500'));
                events.addAll(_getEventsForCategory('evening_445'));
                events.addAll(_getEventsForCategory('evening_500'));
              } else {
                appointments = _getAppointmentsForCategory(categoryKey);
                events = _getEventsForCategory(categoryKey);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCategoryCard(category, appointments, events, categoryKey),
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
    List<Map<String, dynamic>> events,
    String categoryKey,
  ) {
    final totalItems = appointments.length + events.length;
    final totalPeopleCount =
        _calculateTotalPeople(appointments) + _calculateTotalEventCapacity(events);
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalPeopleCount',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      '$totalItems',
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
              child: totalItems == 0
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
                              'No appointments or events in this category',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : categoryKey == 'evening'
                      ? _buildEveningWithSubSections(events, appointments, category)
                      : Column(
                          children: [
                            // Display events first
                            ...events.map(
                              (event) => _buildEventCard(event),
                            ),
                            // Then display appointments (EXISTING LOGIC - UNCHANGED)
                            ...appointments.map(
                              (appointment) => _buildAppointmentCard(appointment, category),
                            ),
                          ],
                        ),
            ),
        ],
      ),
    );
  }

  Widget _buildEveningWithSubSections(
    List<Map<String, dynamic>> events,
    List<Map<String, dynamic>> appointments,
    Map<String, dynamic> category,
  ) {
    // Get sub-section items
    final events445 = _getEventsForCategory('evening_445');
    final events500 = _getEventsForCategory('evening_500');
    final appointments445 = _getAppointmentsForCategory('evening_445');
    final appointments500 = _getAppointmentsForCategory('evening_500');
    
    // Get other evening items (excluding 4:45 and 5:00)
    final otherEvents = events.where((event) {
      return !events445.contains(event) && !events500.contains(event);
    }).toList();
    final otherAppointments = appointments.where((appointment) {
      return !appointments445.contains(appointment) && !appointments500.contains(appointment);
    }).toList();

    return Column(
      children: [
        // Other evening items (display normally, not in a sub-section) - show first
        if (otherEvents.isNotEmpty || otherAppointments.isNotEmpty) ...[
          _buildOtherEveningHeader(otherEvents, otherAppointments),
          ...otherEvents.map((event) => _buildEventCard(event)),
          ...otherAppointments.map((appointment) => _buildAppointmentCard(appointment, category)),
        ],
        
        // 4:45 PM sub-section (expandable/collapsible) - always show
        _buildEveningSubSection(
          title: '4:45 PM',
          icon: Icons.access_time,
          events: events445,
          appointments: appointments445,
          category: category,
          subSectionKey: 'evening_445',
        ),
        
        // 5:00 PM sub-section (expandable/collapsible) - always show
        _buildEveningSubSection(
          title: '5:00 PM',
          icon: Icons.access_time,
          events: events500,
          appointments: appointments500,
          category: category,
          subSectionKey: 'evening_500',
        ),
      ],
    );
  }

  Widget _buildOtherEveningHeader(
    List<Map<String, dynamic>> events,
    List<Map<String, dynamic>> appointments,
  ) {
    final totalItems = events.length + appointments.length;
    final totalPeople = _calculateTotalPeople(appointments);
    final totalEventCapacity = _calculateTotalEventCapacity(events);
    final totalPeopleCount = totalPeople + totalEventCapacity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Title
          Text(
            'Other Evening Appointments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 8),
          // Count badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$totalItems',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // People count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  size: 12,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '$totalPeopleCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEveningSubSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> events,
    required List<Map<String, dynamic>> appointments,
    required Map<String, dynamic> category,
    required String subSectionKey,
  }) {
    final totalItems = events.length + appointments.length;
    final totalPeople = _calculateTotalPeople(appointments);
    final isExpanded = _expandedCategories.contains(subSectionKey);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
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
                  _expandedCategories.remove(subSectionKey);
                } else {
                  _expandedCategories.add(subSectionKey);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: isExpanded ? Radius.zero : const Radius.circular(8),
                  bottomRight: isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  // Total people count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${totalPeople + _calculateTotalEventCapacity(events)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Total items count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.orange.shade700,
                    size: 20,
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
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Column(
                children: [
                  ...events.map((event) => _buildEventCard(event)),
                  ...appointments.map((appointment) => _buildAppointmentCard(appointment, category)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventsCategoryCard() {
    final isExpanded = _expandedCategories.contains('events');
    final events = _upcomingEvents;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove('events');
                } else {
                  _expandedCategories.add('events');
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isExpanded ? Radius.zero : const Radius.circular(12),
                  bottomRight: isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Events',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.orange,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: events.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, size: 32, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No events scheduled',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: events.map((event) => _buildEventCard(event)).toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventName = event['eventName']?.toString() ?? 'Event';
    final eventLocation = event['eventLocation']?.toString() ?? 'N/A';
    final eventStatus = event['eventStatus']?.toString() ?? 'pending';
    final scheduledDate = event['scheduledDate']?.toString();
    final eventImage = event['eventImage']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(
                event: event,
                onEventUpdated: () {
                  _fetchUpcomingAppointments();
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (eventImage != null && eventImage.isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      eventImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.event, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            eventLocation,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (scheduledDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventDate(scheduledDate),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEventStatusColor(eventStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getEventStatusColor(eventStatus), width: 1),
                ),
                child: Text(
                  eventStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getEventStatusColor(eventStatus),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatEventDate(String dateStr) {
    try {
      // Parse UTC datetime and convert to IST (UTC+5:30)
      final dateTimeUtc = DateTime.parse(dateStr);
      final dateTimeIst = dateTimeUtc.add(const Duration(hours: 5, minutes: 30));
      
      // Convert to 12-hour format with AM/PM
      final hour12 = dateTimeIst.hour == 0 
          ? 12 
          : (dateTimeIst.hour > 12 ? dateTimeIst.hour - 12 : dateTimeIst.hour);
      final amPm = dateTimeIst.hour < 12 ? 'AM' : 'PM';
      final minute = dateTimeIst.minute.toString().padLeft(2, '0');
      
      return '${dateTimeIst.day}/${dateTimeIst.month}/${dateTimeIst.year} $hour12:$minute $amPm';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildAppointmentCard(
    Map<String, dynamic> appointment,
    Map<String, dynamic> category,
  ) {
    return Container(
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
                      GestureDetector(
                        onTap: () {
                          final photoUrl = _getProfilePhotoUrl(appointment);
                          ProfilePhotoDialog.showWithErrorHandling(
                            context,
                            imageUrl: photoUrl,
                            userName: _getAppointmentName(appointment),
                            description: "${_getAppointmentName(appointment)}'s profile photo",
                          );
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
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

                // Status section
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
                                  color: _getStatusColor(_getMainStatus(appointment)),
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
                    ],
                  ),
                ),

                // Table-like layout for Time, Appointees, Secretary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Appointees',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Secretary',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Data row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatTime(_getAppointmentTime(appointment)),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${_getTotalAppointeesCount(appointment)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getSecretaryInitials(appointment),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
    );
  }

  String _getAppointmentName(Map<String, dynamic> appointment) {
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    final guestInformation = appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final fullName = guestInformation['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

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
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    final guestInformation = appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final designation = guestInformation['designation']?.toString();
        if (designation != null && designation.isNotEmpty) {
          return designation;
        }
      }
    }

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
    // Check if this is a guest appointment
    final appointmentType = appointment['appointmentType']?.toString();
    final guestInformation = appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final photoUrl = guestInformation['profilePhotoUrl']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
    }

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
        return Colors.red; // Red for Not Arrived
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

  int _getTotalAppointeesCount(Map<String, dynamic> appointment) {
    final appointmentType = appointment['appointmentType']?.toString().toLowerCase();
    int accompanyCount = 0;
    
    // Get accompanying users count
    final accompanyUsers = appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      accompanyCount = accompanyUsers['numberOfUsers'] ?? 0;
    }
    
    // Add 1 for main user/guest based on appointment type
    if (appointmentType == 'myself') {
      // For myself appointments, add 1 for the main user
      return accompanyCount + 1;
    } else if (appointmentType == 'guest') {
      // For guest appointments, add 1 for the main guest
      return accompanyCount + 1;
    } else {
      // For other appointment types, add 1 for the main appointee
      return accompanyCount + 1;
    }
  }

  int _calculateTotalPeople(List<Map<String, dynamic>> appointments) {
    int total = 0;
    for (var appointment in appointments) {
      // Get total number of people from accompanyUsers
      final accompanyUsers = appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final numberOfUsers = accompanyUsers['numberOfUsers'];
        if (numberOfUsers != null && numberOfUsers is int) {
          // numberOfUsers represents accompanying users, so total = numberOfUsers + 1 (main user)
          total += (numberOfUsers + 1);
        } else {
          // If numberOfUsers is not available, default to 1 (main user)
          total += 1;
        }
      } else {
        // If accompanyUsers is not available, default to 1 (main user)
        total += 1;
      }
    }
    return total;
  }

  int _calculateTotalEventCapacity(List<Map<String, dynamic>> events) {
    int total = 0;
    for (var event in events) {
      final eventCapacity = event['eventCapacity'] ?? 0;
      final capacity = eventCapacity is int ? eventCapacity : 
                      (int.tryParse(eventCapacity.toString()) ?? 0);
      total += capacity;
    }
    return total;
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
          final result = await ActionService.getQuickAppointmentById(appointmentId);

          if (result['success'] && result['data'] != null) {
            // Navigate to appointment detail page with the fetched data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailPage(
                  appointment: result['data'],
                  isFromScheduleScreens: true,
                  secretaryName: _getSecretaryName(appointment), // Pass secretary name
                  isTeacher: appointment['isTeacher'] ?? false, // Pass teacher status
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
            secretaryName: _getSecretaryName(appointment), // Pass secretary name
            isTeacher: appointment['isTeacher'] ?? false, // Pass teacher status
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
