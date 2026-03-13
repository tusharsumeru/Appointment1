import 'package:flutter/material.dart';
import '../../action/action.dart';
import '../inbox/appointment_detail_page.dart';
import '../inbox/event_detail_page.dart';
import '../common/profile_photo_dialog.dart';
import '../common/bulk_cancel_dialog.dart';

class TodayCardComponent extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback? onRefresh;
  final VoidCallback? onSelectionChanged;

  const TodayCardComponent({
    super.key,
    required this.selectedDate,
    this.onRefresh,
    this.onSelectionChanged,
  });

  @override
  State<TodayCardComponent> createState() => _TodayCardComponentState();
}

class _TodayCardComponentState extends State<TodayCardComponent> {
  List<Map<String, dynamic>> _todayAppointments = [];
  List<Map<String, dynamic>> _todayEvents = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _expandedCategories = {};
  Set<String> _selectedAppointmentIds = {};
  bool _selectAllMode = false;

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
    _fetchTodayAppointments();
  }

  @override
  void didUpdateWidget(TodayCardComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _fetchTodayAppointments();
    }
  }

  Future<void> _fetchTodayAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get selected date in YYYY-MM-DD format
      final dateString = ActionService.formatDateForAPI(widget.selectedDate);
      print('📅 Fetching appointments for date: $dateString');

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
          _todayAppointments = sortedAppointments;
        } else {
          _todayAppointments = [];
        }

        // Store all events (scheduled and completed - completed ones will show in done section)
        _todayEvents = events;
      } else {
        _error = result['message'] ?? 'Failed to fetch today\'s appointments';
        _todayAppointments = [];
        _todayEvents = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _todayAppointments = [];
      _todayEvents = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Public method to refresh data
  Future<void> refresh() async {
    await _fetchTodayAppointments();
    widget.onRefresh?.call();
  }

  List<Map<String, dynamic>> _getEventsForCategory(String categoryKey) {
    if (_todayEvents.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
      case 'night':
        return _todayEvents.where((event) {
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
        return _todayEvents.where((event) {
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
            return dateTimeIst.hour == 16 && dateTimeIst.minute == 45;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening_500':
        return _todayEvents.where((event) {
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
            return dateTimeIst.hour == 17 && dateTimeIst.minute == 0;
          } catch (e) {
            return false;
          }
        }).toList();

      case 'evening':
        return _todayEvents.where((event) {
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

      case 'done':
        // Return completed/done events
        return _todayEvents.where((event) {
          final status = (event['status']?.toString() ?? 
                         event['eventStatus']?.toString() ?? '').toLowerCase();
          final isDone = status == 'completed' || status == 'done';
          return isDone;
        }).toList();

      case 'tbs_req':
      default:
        // For other categories, return empty (events only in time-based categories)
        return [];
    }
  }

  List<Map<String, dynamic>> _getAppointmentsForCategory(String categoryKey) {
    if (_todayAppointments.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
      case 'night':
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
          final status = _getAppointmentStatus(appointment).toLowerCase();
          final isDone = status == 'completed' || status == 'done';
          return isDone;
        }).toList();

      case 'satsang_backstage':
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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
        return _todayAppointments.where((appointment) {
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

  int _calculateTotalPeople(List<Map<String, dynamic>> appointments) {
    int total = 0;
    for (var appointment in appointments) {
      // Check if this is a quick appointment
      final apptType = appointment['appt_type']?.toString();
      final quickApt = appointment['quick_apt'];
      final isQuickAppointment = apptType == 'quick' && 
                                quickApt is Map<String, dynamic> && 
                                quickApt['isQuickAppointment'] == true;
      
      if (isQuickAppointment) {
        // For quick appointments, try multiple sources for the count
        // First, try checkInStatus.totalUsers (most reliable for quick appointments)
        final checkInStatus = appointment['checkInStatus'];
        if (checkInStatus is Map<String, dynamic> && checkInStatus['totalUsers'] != null) {
          final totalUsers = int.tryParse(checkInStatus['totalUsers'].toString()) ?? 0;
          if (totalUsers > 0) {
            total += totalUsers;
            continue;
          }
        }
        
        // Second, try numberOfPeople from quick_apt.optional
        final optional = quickApt['optional'];
        if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
          final numberOfPeople = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
          if (numberOfPeople > 0) {
            total += numberOfPeople;
            continue;
          }
        }
        
        // If neither is available, default to 1 (at least the main user)
        total += 1;
        continue;
      }
      
      // For regular appointments, get total number of people from accompanyUsers
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
              onPressed: _fetchTodayAppointments,
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
      onRefresh: _fetchTodayAppointments,
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
                      Icon(Icons.today, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Today\'s Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Total Appointments: ${_todayAppointments.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Total Events: ${_todayEvents.length}',
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
                  // Total people count badge
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
                          '${_calculateTotalPeople(appointments) + _calculateTotalEventCapacity(events)}',
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
        
        // Other evening items (expandable/collapsible) - show last
        if (otherEvents.isNotEmpty || otherAppointments.isNotEmpty)
          _buildEveningSubSection(
            title: 'Other Evening Appointments',
            icon: Icons.access_time,
            events: otherEvents,
            appointments: otherAppointments,
            category: category,
            subSectionKey: 'evening_other',
            useOrangeColors: false,
          ),
      ],
    );
  }


  Widget _buildEveningSubSection({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> events,
    required List<Map<String, dynamic>> appointments,
    required Map<String, dynamic> category,
    required String subSectionKey,
    bool useOrangeColors = true,
  }) {
    final totalItems = events.length + appointments.length;
    final totalPeople = _calculateTotalPeople(appointments);
    final isExpanded = _expandedCategories.contains(subSectionKey);

    // Choose colors based on useOrangeColors parameter
    final borderColor = useOrangeColors ? Colors.orange.shade200 : Colors.grey.shade300;
    final headerBgColor = useOrangeColors ? Colors.orange.shade50 : Colors.grey.shade50;
    final iconColor = useOrangeColors ? Colors.orange.shade700 : Colors.grey.shade700;
    final textColor = useOrangeColors ? Colors.orange.shade700 : Colors.grey.shade700;
    final badgeBgColor = useOrangeColors ? Colors.orange.shade200 : Colors.grey.shade200;
    final badgeTextColor = useOrangeColors ? Colors.orange.shade900 : Colors.grey.shade900;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
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
                color: headerBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: isExpanded ? Radius.zero : const Radius.circular(8),
                  bottomRight: isExpanded ? Radius.zero : const Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
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
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(
                        color: badgeTextColor,
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
                    color: iconColor,
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
    final events = _todayEvents;
    
    // Calculate total capacity of all events
    int totalCapacity = 0;
    for (var event in events) {
      final eventCapacity = event['eventCapacity'] ?? 0;
      final capacity = eventCapacity is int ? eventCapacity : 
                      (int.tryParse(eventCapacity.toString()) ?? 0);
      totalCapacity += capacity;
    }

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
          // Header section (clickable)
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
                  // Total capacity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '$totalCapacity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Event count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.orange,
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
              child: events.isEmpty
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
                              'No events scheduled',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: events
                          .map((event) => _buildEventCard(event))
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventName = event['eventName']?.toString() ?? 'Event';
    final eventLocation = event['eventLocation']?.toString() ?? 'N/A';
    // Check both status and eventStatus fields
    final eventStatus = (event['eventStatus'] ?? event['status'] ?? 'pending').toString();
    final scheduledDate = event['scheduledDate']?.toString();
    final eventImage = event['eventImage']?.toString();
    final eventCapacity = event['eventCapacity'] ?? 0;
    
    // Get capacity only
    final capacity = eventCapacity is int ? eventCapacity : 
                    (int.tryParse(eventCapacity.toString()) ?? 0);

    // Use eventId field, not MongoDB _id
    final eventId = event['eventId']?.toString() ?? event['_id']?.toString() ?? '';
    final isCompleted = eventStatus.toLowerCase() == 'completed' || eventStatus.toLowerCase() == 'done';

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
      child: Column(
        children: [
          // Main content
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                    event: event,
                    onEventUpdated: () {
                      _fetchTodayAppointments();
                    },
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Event Image
                  if (eventImage != null && eventImage.isNotEmpty)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                  // Event Details
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        // People count (capacity only)
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$capacity ${capacity == 1 ? 'Person' : 'People'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEventStatusColor(eventStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getEventStatusColor(eventStatus),
                        width: 1,
                      ),
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
            child: _buildEventActionButton(event, eventId, isCompleted),
          ),
        ],
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

  Widget _buildEventActionButton(Map<String, dynamic> event, String eventId, bool isCompleted) {
    return Row(
      children: [
        // Action button (Done/Undo) - takes 60% of width
        Expanded(
          flex: 3,
          child: isCompleted
              ? ElevatedButton(
                  onPressed: () async {
                    await _handleUndoEvent(event, eventId);
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
                    await _handleMarkEventAsDone(event, eventId);
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
                      Icon(Icons.check_circle, size: 16),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(
                    event: event,
                    onEventUpdated: () {
                      _fetchTodayAppointments();
                    },
                  ),
                ),
              );
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

  Future<void> _handleMarkEventAsDone(Map<String, dynamic> event, String eventId) async {
    try {
      // Use eventId field, not MongoDB _id
      final actualEventId = event['eventId']?.toString() ?? 
                           event['_id']?.toString() ?? 
                           eventId;
      
      if (actualEventId.isEmpty) {
        print('❌ Event ID not found. Event keys: ${event.keys.toList()}');
        _showSnackBar('Error: Event ID not found', isError: true);
        return;
      }

      print('🔍 Marking event as done. Event ID: $actualEventId');
      
      _showSnackBar('Marking event as done...', isError: false);

      final result = await ActionService.rescheduleEvent(
        eventId: actualEventId,
        status: 'completed',
      );

      if (result['success']) {
        _showSnackBar(
          result['message'] ?? 'Event marked as completed successfully',
          isError: false,
        );

        // Update local state immediately - no hard refresh, just smooth transition
        setState(() {
          final index = _todayEvents.indexWhere((evt) => 
            (evt['eventId']?.toString() ?? evt['_id']?.toString()) == actualEventId
          );
          if (index != -1) {
            // If API returned updated event data, use it
            if (result['data'] != null && result['data'] is Map<String, dynamic>) {
              final updatedEvent = result['data'] as Map<String, dynamic>;
              _todayEvents[index] = updatedEvent;
            } else {
              // Update both status and eventStatus fields manually
              _todayEvents[index] = Map<String, dynamic>.from(_todayEvents[index]);
              _todayEvents[index]['eventStatus'] = 'completed';
              _todayEvents[index]['status'] = 'completed';
            }
            print('✅ Updated event status to completed. New status: ${_todayEvents[index]['eventStatus']}');
          }
        });
        // No hard refresh - the event will smoothly move to Done section via setState rebuild
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to mark event as completed',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackBar('Network error: $error', isError: true);
    }
  }

  Future<void> _handleUndoEvent(Map<String, dynamic> event, String eventId) async {
    try {
      // Use eventId field, not MongoDB _id
      final actualEventId = event['eventId']?.toString() ?? 
                           event['_id']?.toString() ?? 
                           eventId;
      
      if (actualEventId.isEmpty) {
        print('❌ Event ID not found. Event keys: ${event.keys.toList()}');
        _showSnackBar('Error: Event ID not found', isError: true);
        return;
      }

      print('🔍 Undoing event. Event ID: $actualEventId');
      
      _showSnackBar('Undoing event status...', isError: false);

      final result = await ActionService.rescheduleEvent(
        eventId: actualEventId,
        status: 'scheduled',
      );

      if (result['success']) {
        _showSnackBar(
          result['message'] ?? 'Event status reverted successfully',
          isError: false,
        );

        // Update local state immediately - no hard refresh, just smooth transition
        setState(() {
          final index = _todayEvents.indexWhere((evt) => 
            (evt['eventId']?.toString() ?? evt['_id']?.toString()) == actualEventId
          );
          if (index != -1) {
            // If API returned updated event data, use it
            if (result['data'] != null && result['data'] is Map<String, dynamic>) {
              final updatedEvent = result['data'] as Map<String, dynamic>;
              _todayEvents[index] = updatedEvent;
            } else {
              // Update both status and eventStatus fields manually
              _todayEvents[index] = Map<String, dynamic>.from(_todayEvents[index]);
              _todayEvents[index]['eventStatus'] = 'scheduled';
              _todayEvents[index]['status'] = 'scheduled';
            }
            print('✅ Updated event status to scheduled. New status: ${_todayEvents[index]['eventStatus']}');
          }
        });
        // No hard refresh - the event will smoothly move back to its original section via setState rebuild
      } else {
        _showSnackBar(
          result['message'] ?? 'Failed to undo event status',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackBar('Network error: $error', isError: true);
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
      child: Stack(
        children: [
          Column(
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
                          // External badge (E-<secretary initials>) when scheduled as external
                          if ((appointment['scheduledDateTime'] is Map<String, dynamic>) &&
                              (appointment['scheduledDateTime']['isExternal'] == true)) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange, width: 2),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              'E-${_getSecretaryInitials(appointment)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                      // Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _getCheckInStatus(appointment).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getCheckInStatusColor(appointment),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBreakdown(appointment),
                        ],
                      ),
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
          // Checkbox positioned in top right corner
          Positioned(
            top: 8,
            right: 8,
            child: Checkbox(
              value: _selectedAppointmentIds.contains(_getAppointmentId(appointment)),
              onChanged: (value) {
                setState(() {
                  final appointmentId = _getAppointmentId(appointment);
                  if (value == true) {
                    _selectedAppointmentIds.add(appointmentId);
                  } else {
                    _selectedAppointmentIds.remove(appointmentId);
                  }
                  if (_selectedAppointmentIds.isEmpty) {
                    _selectAllMode = false;
                  }
                });
                // Notify parent of selection change
                widget.onSelectionChanged?.call();
              },
            ),
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
    // Check if this is a quick appointment first
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    if (isQuickAppointment) {
      // For quick appointments, only use photo from quick_apt.optional
      // Don't fall back to secretary/profile photo
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final photoUrl = optional['photo']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
      // Return empty string for quick appointments with no photo
      return '';
    }
    
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
    
    // Fallback to profile photo (for non-quick appointments)
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
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    // For quick appointments, use numberOfPeople from quick_apt.optional
    if (isQuickAppointment) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
        final numberOfPeople = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
        if (numberOfPeople > 0) {
          return numberOfPeople;
        }
      }
    }
    
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
      print('🔍 Debug: Calling markAppointmentAsDone with statusId: $appointmentStatusId');
      final result = await ActionService.markAppointmentAsDone(
        appointmentStatusId: appointmentStatusId,
      );
      
      print('🔍 Debug: API result: $result');

      if (result['success']) {
        // Success - show success message and refresh the data
        _showSnackBar(
          result['message'] ?? 'Appointment marked as completed successfully',
          isError: false,
        );

        // Update the local appointment data immediately
        setState(() {
          final index = _todayAppointments.indexWhere((apt) => apt['_id'] == appointmentId);
          print('🔍 Debug: Found appointment at index: $index');
          if (index != -1) {
            // Update the appointment status to 'completed' (prioritize appointmentStatus.status)
            if (_todayAppointments[index]['appointmentStatus'] is Map<String, dynamic>) {
              _todayAppointments[index]['appointmentStatus']['status'] = 'completed';
              print('🔍 Debug: Updated appointmentStatus.status to completed');
            }
            // Also update checkInStatus if it exists (fallback)
            if (_todayAppointments[index]['checkInStatus'] is Map<String, dynamic>) {
              _todayAppointments[index]['checkInStatus']['mainStatus'] = 'completed';
              print('🔍 Debug: Updated checkInStatus.mainStatus to completed');
            }
            // Update direct mainStatus field as well (fallback)
            _todayAppointments[index]['mainStatus'] = 'completed';
            print('🔍 Debug: Updated mainStatus to completed');
          }
        });

        // Add a small delay to ensure server has updated the data
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the appointments list
        print('🔍 Debug: Refreshing appointments list...');
        await _fetchTodayAppointments();
        print('🔍 Debug: Refresh completed. Total appointments: ${_todayAppointments.length}');
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
        // Action button (Done/Undo) - takes 30% of width
        Expanded(
          flex: 2,
          child: isCompleted
              ? ElevatedButton(
                  onPressed: () async {
                    await _handleUndo(appointment);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Undo',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.undo, size: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
        ),
        
        const SizedBox(width: 8),
        
        // Admit button - takes 30% of width
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () async {
              await _handleAdmit(appointment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Admit',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.check_circle, size: 14),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // View Details button - takes 30% of width
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
          final index = _todayAppointments.indexWhere((apt) => apt['_id'] == appointmentId);
          if (index != -1) {
            // Update the appointment status back to 'scheduled' (original status)
            if (_todayAppointments[index]['appointmentStatus'] is Map<String, dynamic>) {
              _todayAppointments[index]['appointmentStatus']['status'] = 'scheduled';
            }
            // Also update checkInStatus if it exists (fallback)
            if (_todayAppointments[index]['checkInStatus'] is Map<String, dynamic>) {
              _todayAppointments[index]['checkInStatus']['mainStatus'] = 'scheduled';
            }
            // Update direct mainStatus field as well (fallback)
            _todayAppointments[index]['mainStatus'] = 'scheduled';
          }
        });

        // Add a small delay to ensure server has updated the data
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the appointments list
        await _fetchTodayAppointments();
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

  Future<void> _handleAdmit(Map<String, dynamic> appointment) async {
    // Show bottom sheet with user list
    _showAdmitRejectBottomSheet(appointment);
  }

  void _showAdmitRejectBottomSheet(Map<String, dynamic> appointment) {
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus == null || checkInStatus['_id'] == null) {
      _showSnackBar('Error: Check-in status not found', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdmitRejectBottomSheet(
        appointment: appointment,
        checkInStatus: Map<String, dynamic>.from(checkInStatus),
        onUpdate: () {
          // Refresh the appointments list after updates
          _fetchTodayAppointments();
        },
      ),
    );
  }

  String _getCheckInStatus(Map<String, dynamic> appointment) {
    // Get checkInStatus.mainStatus from the API data
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus is Map<String, dynamic>) {
      final mainStatus = checkInStatus['mainStatus']?.toString();
      if (mainStatus != null && mainStatus.isNotEmpty) {
        // Map status to display text
        switch (mainStatus.toLowerCase()) {
          case 'checked_in_partial':
            return 'Admitted partially';
          case 'checked_in':
            return 'Admitted';
          case 'not_arrived':
            return 'Not Arrived';
          case 'rejected':
            return 'Rejected';
          default:
            return mainStatus;
        }
      }
    }
    return 'Unknown';
  }

  Color _getCheckInStatusColor(Map<String, dynamic> appointment) {
    // All statuses should be green as requested
    return Colors.green.shade600;
  }

  Widget _buildStatusBreakdown(Map<String, dynamic> appointment) {
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus is! Map<String, dynamic>) {
      return const SizedBox.shrink();
    }

    final users = checkInStatus['users'] as List<dynamic>? ?? [];
    final checkedInUsers = int.tryParse(checkInStatus['checkedInUsers']?.toString() ?? '0') ?? 0;
    
    // Check if this is a quick appointment
    final apptType = appointment['appt_type']?.toString();
    final quickApt = appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    int totalUsers = 0;
    if (isQuickAppointment) {
      // For quick appointments, use totalUsers from checkInStatus (it's already set correctly)
      totalUsers = int.tryParse(checkInStatus['totalUsers']?.toString() ?? '0') ?? 0;
      if (totalUsers == 0) {
        // Fallback to numberOfPeople in quick_apt.optional if totalUsers not available
        final optional = quickApt['optional'];
        if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
          totalUsers = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
        }
      }
      
      // For quick appointments, use checkedInUsers directly and calculate rejected from users array
      final rejectedCount = users.where((user) {
        if (user is Map<String, dynamic>) {
          final userStatus = user['status']?.toString().toLowerCase() ?? '';
          return userStatus == 'rejected';
        }
        return false;
      }).length;
      
      return Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          if (checkedInUsers > 0) ...[
            Text(
              '$checkedInUsers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              'Admitted',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (rejectedCount > 0) ...[
            Text(
              '$rejectedCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            Text(
              'Rejected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          Text(
            'Total $totalUsers Appointee${totalUsers != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    }
    
    // For non-quick appointments, use original logic
    totalUsers = int.tryParse(checkInStatus['totalUsers']?.toString() ?? '0') ?? 0;
    
    // Calculate actual total users from the users array
    final actualTotalUsers = users.length;
    
    // If total users from backend is more than 10, count rejected users from users array only
    if (totalUsers > 10) {
      final rejectedCount = users.where((user) {
        if (user is Map<String, dynamic>) {
          final userStatus = user['status']?.toString().toLowerCase() ?? '';
          return userStatus == 'rejected';
        }
        return false;
      }).length;
      
      return Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          if (checkedInUsers > 0) ...[
            Text(
              '$checkedInUsers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            Text(
              'Admitted',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (rejectedCount > 0) ...[
            Text(
              '$rejectedCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade600,
              ),
            ),
            Text(
              'Rejected',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          Text(
            'Total $totalUsers Appointee${totalUsers != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );
    }

    // For 10 or fewer users, count individual statuses from users array
    int admittedCount = 0;
    int rejectedCount = 0;

    for (var user in users) {
      if (user is Map<String, dynamic>) {
        final userStatus = user['status']?.toString().toLowerCase() ?? '';
        switch (userStatus) {
          case 'checked_in':
            admittedCount++;
            break;
          case 'rejected':
            rejectedCount++;
            break;
        }
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        if (admittedCount > 0) ...[
          Text(
            '$admittedCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            'Admitted',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        // Always show rejected count (even if 0)
        Text(
          '$rejectedCount',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade600,
          ),
        ),
        Text(
          'Rejected',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        Text(
          'Total $actualTotalUsers Appointee${actualTotalUsers != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // Helper method to get appointment ID
  String _getAppointmentId(Map<String, dynamic> appointment) {
    return appointment['appointmentId']?.toString() ??
        appointment['_id']?.toString() ??
        '';
  }

  // Get all selectable appointment IDs
  Set<String> _getAllSelectableAppointmentIds() {
    final Set<String> ids = {};
    for (final appointment in _todayAppointments) {
      final id = _getAppointmentId(appointment);
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }

  // Show bulk cancel dialog
  void _showBulkCancelDialog() {
    if (_selectedAppointmentIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => BulkCancelDialog(
        appointmentIds: _selectedAppointmentIds.toList(),
        type: 'cancellation',
        onSuccess: () {
          setState(() {
            _selectedAppointmentIds.clear();
            _selectAllMode = false;
          });
          // Notify parent of selection change to update header
          widget.onSelectionChanged?.call();
          _fetchTodayAppointments();
        },
      ),
    );
  }

  // Public methods for parent screen access
  Set<String> get selectedAppointmentIds => _selectedAppointmentIds;
  bool get hasSelectedAppointments => _selectedAppointmentIds.isNotEmpty;
  int get selectedCount => _selectedAppointmentIds.length;
  bool get isAllSelected => _selectedAppointmentIds.length == _getAllSelectableAppointmentIds().length && _getAllSelectableAppointmentIds().isNotEmpty;

  void selectAll() {
    setState(() {
      _selectedAppointmentIds = _getAllSelectableAppointmentIds().toSet();
    });
    // Notify parent of selection change
    widget.onSelectionChanged?.call();
  }

  void deselectAll() {
    setState(() {
      _selectedAppointmentIds.clear();
      _selectAllMode = false;
    });
    // Notify parent of selection change
    widget.onSelectionChanged?.call();
  }

  void showBulkCancel() {
    _showBulkCancelDialog();
  }

}

// Separate StatefulWidget for the bottom sheet to maintain its own state
class _AdmitRejectBottomSheet extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> checkInStatus;
  final VoidCallback onUpdate;

  const _AdmitRejectBottomSheet({
    required this.appointment,
    required this.checkInStatus,
    required this.onUpdate,
  });

  @override
  State<_AdmitRejectBottomSheet> createState() => _AdmitRejectBottomSheetState();
}

class _AdmitRejectBottomSheetState extends State<_AdmitRejectBottomSheet> {
  late Map<String, dynamic> _checkInStatus;

  @override
  void initState() {
    super.initState();
    _checkInStatus = Map<String, dynamic>.from(widget.checkInStatus);
  }

  int _getTotalNumberOfUsers() {
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    // For quick appointments, always use totalUsers from checkInStatus first (it's already set correctly)
    if (isQuickAppointment) {
      if (_checkInStatus['totalUsers'] != null) {
        final total = int.tryParse(_checkInStatus['totalUsers'].toString()) ?? 0;
        if (total > 0) {
          return total;
        }
      }
      // Fallback to numberOfPeople in quick_apt.optional if totalUsers not available
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
        final numberOfPeople = int.tryParse(optional['numberOfPeople'].toString()) ?? 0;
        if (numberOfPeople > 0) {
          return numberOfPeople;
        }
      }
    }
    
    // For regular appointments, check totalUsers first
    if (_checkInStatus['totalUsers'] != null) {
      final total = int.tryParse(_checkInStatus['totalUsers'].toString()) ?? 0;
      if (total > 0) {
        return total;
      }
    }
    
    // Fallback to users array length
    final usersList = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    return usersList.length;
  }

  String _calculateMainStatus(List<Map<String, dynamic>> users) {
    if (users.isEmpty) return 'not_arrived';

    int checkedInCount = 0;
    int rejectedCount = 0;
    final expectedTotal = _getTotalNumberOfUsers();
    final observedTotal = users.length;

    for (final user in users) {
      final status = user['status']?.toString().toLowerCase();
      if (status == 'checked_in') {
        checkedInCount++;
      } else if (status == 'rejected') {
        rejectedCount++;
      }
    }

    // If we only have partial user list (large group), use partial logic
    if (expectedTotal > observedTotal) {
      if (checkedInCount > 0) return 'checked_in_partial';
      if (rejectedCount > 0) return 'checked_in_partial';
      return 'not_arrived';
    }

    // Full list logic
    if (checkedInCount == expectedTotal && expectedTotal > 0) {
      return 'checked_in';
    }
    if (rejectedCount == expectedTotal && expectedTotal > 0) {
      return 'rejected';
    }
    if (checkedInCount == 0 && rejectedCount == 0) {
      return 'not_arrived';
    }
    return 'checked_in_partial';
  }

  int _getTotalUsers() {
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    // Helper function to parse MongoDB extended JSON number
    int parseNumber(dynamic value) {
      if (value is int) return value;
      if (value is Map<String, dynamic> && value['\$numberInt'] != null) {
        return int.tryParse(value['\$numberInt'].toString()) ?? 0;
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    
    // For quick appointments, always use totalUsers from checkInStatus (it's already set correctly)
    if (isQuickAppointment) {
      final totalUsers = parseNumber(_checkInStatus['totalUsers']);
      if (totalUsers > 0) {
        return totalUsers;
      }
      // Fallback to numberOfPeople in quick_apt.optional if totalUsers not available
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic> && optional['numberOfPeople'] != null) {
        final numberOfPeople = parseNumber(optional['numberOfPeople']);
        if (numberOfPeople > 0) {
          return numberOfPeople;
        }
      }
    }
    
    final usersList = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    final actualTotalUsers = usersList.length;
    final totalUsers = parseNumber(_checkInStatus['totalUsers']);
    
    // For normal appointments, if totalUsers is set, always use it (prioritize backend value)
    if (totalUsers > 0) {
      return totalUsers;
    }
    
    // Fallback to users array length if totalUsers is not set
    return actualTotalUsers;
  }

  int _getAdmittedUsers() {
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    // Helper function to parse MongoDB extended JSON number
    int parseNumber(dynamic value) {
      if (value is int) return value;
      if (value is Map<String, dynamic> && value['\$numberInt'] != null) {
        return int.tryParse(value['\$numberInt'].toString()) ?? 0;
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    
    final usersList = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    final totalUsers = parseNumber(_checkInStatus['totalUsers']);
    final checkedInUsers = parseNumber(_checkInStatus['checkedInUsers']);
    
    // For quick appointments, always use checkedInUsers from checkInStatus
    // (users array only has main user, so we can't count from array)
    if (isQuickAppointment) {
      return checkedInUsers;
    }
    
    // For normal appointments (≤10 users), count from users array to get accurate count
    // This ensures we show the actual admitted count, not the backend's total
    if (totalUsers > 0 && totalUsers <= 10) {
      return usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'checked_in';
      }).length;
    }
    
    // For large groups (>10 users), use checkedInUsers from backend
    // (backend has the correct count, array might be incomplete)
    if (totalUsers > 10) {
      return checkedInUsers;
    }
    
    // Fallback: count individual users from users array if totalUsers is not set
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'checked_in';
    }).length;
  }

  int _getRejectedUsers() {
    final usersList = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    final totalUsers = int.tryParse(_checkInStatus['totalUsers']?.toString() ?? '') ?? 0;
    
    // If total users from backend is more than 10, count rejected users from users array only
    if (totalUsers > 10) {
      return usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
    }
    
    // For 10 or fewer users, count individual users from users array
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'rejected';
    }).length;
  }

  int _getNotArrivedUsers() {
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    final usersList = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    
    // Helper function to parse MongoDB extended JSON number
    int parseNumber(dynamic value) {
      if (value is int) return value;
      if (value is Map<String, dynamic> && value['\$numberInt'] != null) {
        return int.tryParse(value['\$numberInt'].toString()) ?? 0;
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    
    final totalUsers = parseNumber(_checkInStatus['totalUsers']);
    final checkedInUsers = parseNumber(_checkInStatus['checkedInUsers']);
    
    // For quick appointments, calculate not arrived as total - admitted - rejected
    // (users array only has main user, so we calculate from totals)
    if (isQuickAppointment) {
      final rejectedCount = usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
      return totalUsers - checkedInUsers - rejectedCount;
    }
    
    // For normal appointments, if users array is complete (matches totalUsers), count from array
    // This is more accurate when we have all users in the array
    if (totalUsers > 0 && usersList.length == totalUsers) {
      return usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
      }).length;
    }
    
    // If totalUsers is set but array is incomplete, calculate from totals
    // (backend has the correct counts, array might be incomplete)
    if (totalUsers > 0) {
      final rejectedCount = usersList.where((user) {
        final Map<String, dynamic> userMap = user as Map<String, dynamic>;
        final status = userMap['status']?.toString().toLowerCase();
        return status == 'rejected';
      }).length;
      return totalUsers - checkedInUsers - rejectedCount;
    }
    
    // Fallback: count individual users from users array if totalUsers is not set
    return usersList.where((user) {
      final Map<String, dynamic> userMap = user as Map<String, dynamic>;
      final status = userMap['status']?.toString().toLowerCase();
      return status == 'not_arrived' || status == 'pending' || status == null || status.isEmpty;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final users = (_checkInStatus['users'] as List<dynamic>?) ?? [];
    final totalUsers = _getTotalUsers();
    final actualAdmitted = _getAdmittedUsers();
    final actualRejected = _getRejectedUsers();
    final actualNotArrived = _getNotArrivedUsers();

    final allAdmitted = actualAdmitted == totalUsers && totalUsers > 0;

    return _buildAdmitRejectBottomSheet(
      widget.appointment,
      _checkInStatus,
      users,
      totalUsers,
      actualAdmitted,
      actualRejected,
      actualNotArrived,
      allAdmitted,
    );
  }

  Widget _buildAdmitRejectBottomSheet(
    Map<String, dynamic> appointment,
    Map<String, dynamic> checkInStatus,
    List<dynamic> users,
    int totalUsers,
    int actualAdmitted,
    int actualRejected,
    int actualNotArrived,
    bool allAdmitted,
  ) {

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                          const Text(
                            'Admit/Reject Users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage checked-in users for this appointment',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Statistics row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Statistics in one line
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildStatItem('Total', totalUsers.toString(), Colors.grey.shade900),
                            const SizedBox(width: 12),
                            _buildStatItem('Admitted', actualAdmitted.toString(), Colors.green.shade600),
                            const SizedBox(width: 12),
                            _buildStatItem('Rejected', actualRejected.toString(), Colors.red.shade600),
                            const SizedBox(width: 12),
                            _buildStatItem('Not Arrived', actualNotArrived.toString(), Colors.orange.shade600),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Check if this is a quick appointment
                      Builder(
                        builder: (context) {
                          final apptType = appointment['appt_type']?.toString();
                          final quickApt = appointment['quick_apt'];
                          final isQuickAppointment = apptType == 'quick' && 
                                                    quickApt is Map<String, dynamic> && 
                                                    quickApt['isQuickAppointment'] == true;
                          
                          // For quick appointments, always show partial admit button
                          if (isQuickAppointment) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: allAdmitted ? null : () => _showPartialAdmissionDialog(),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text(
                                  'Partially Admit',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allAdmitted ? Colors.grey.shade400 : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // For non-quick appointments, use original logic
                          if (totalUsers > 10) {
                            // For large groups (>10 users), show Partially Admitted button
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: allAdmitted ? null : () => _showPartialAdmissionDialog(),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text(
                                  'Partially Admitted',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: allAdmitted ? Colors.grey.shade400 : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // For small groups (≤10 users), show Admit All button
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (allAdmitted || actualNotArrived == 0) ? null : () => _handleAdmitAll(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (allAdmitted || actualNotArrived == 0) ? Colors.grey.shade400 : Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Admit All',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const ClampingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index] as Map<String, dynamic>;
                      return _buildUserCard(user, index, users);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index, List<dynamic> allUsers) {
    final userType = user['userType']?.toString().toLowerCase() ?? '';
    final isMainUser = index == 0 || userType == 'main';
    
    // Get user name - for main user show name or "Unknown", for others without name show "User 1", "User 2", etc.
    String userName;
    final fullName = user['fullName']?.toString() ?? '';
    
    if (isMainUser) {
      userName = fullName.isNotEmpty ? fullName : 'Unknown';
    } else {
      // For accompanying users, if no name, label as "User 2", "User 3", etc.
      if (fullName.isEmpty) {
        // Count how many accompanying users without names come before this one (excluding main user)
        int userNumber = 0;
        for (int i = 1; i < index; i++) {
          final prevUser = allUsers[i] as Map<String, dynamic>;
          final prevUserType = prevUser['userType']?.toString().toLowerCase() ?? '';
          final prevFullName = prevUser['fullName']?.toString() ?? '';
          if (prevUserType != 'main' && prevFullName.isEmpty) {
            userNumber++;
          }
        }
        // Add 2 because we want "User 2", "User 3", etc. (starting from 2)
        userName = 'User ${userNumber + 2}';
      } else {
        userName = fullName;
      }
    }
    
    final userPhone = _formatUserPhone(user);
    final userPhoto = user['profilePhotoUrl']?.toString() ?? '';
    final userStatus = user['status']?.toString().toLowerCase() ?? 'not_arrived';
    // User is considered admitted if status is checked_in or checked_in_partial
    final isAdmitted = userStatus == 'checked_in' || userStatus == 'checked_in_partial';
    final isRejected = userStatus == 'rejected';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAdmitted 
            ? Colors.green.shade50 
            : isRejected 
                ? Colors.red.shade50 
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmitted 
              ? Colors.green.shade200 
              : isRejected 
                  ? Colors.red.shade200 
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Profile photo
          GestureDetector(
            onTap: userPhoto.isNotEmpty
                ? () {
                    ProfilePhotoDialog.showWithErrorHandling(
                      context,
                      imageUrl: userPhoto,
                      userName: userName,
                      description: "$userName's profile photo",
                    );
                  }
                : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipOval(
                child: userPhoto.isNotEmpty
                    ? Image.network(
                        userPhoto,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildUserInitials(userName);
                        },
                      )
                    : _buildUserInitials(userName),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (isMainUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Main User',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    if (isAdmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Admitted',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    if (isRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Rejected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (isAdmitted)
            // Show only disabled Reject button when admitted
            OutlinedButton(
              onPressed: null, // Disabled when admitted
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
                side: BorderSide(
                  color: Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else if (isRejected)
            // Show only disabled Admit button when rejected
            ElevatedButton(
              onPressed: null, // Disabled when rejected
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Admit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            // Show both Admit and Reject buttons when not admitted or rejected
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _handleAdmitUser(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Admit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _handleRejectUser(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(
                      color: Colors.red.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUserInitials(String name) {
    // Handle empty or null name
    if (name.isEmpty || name.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade500, Colors.yellow.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    final trimmedName = name.trim();
    final parts = trimmedName.split(' ').where((part) => part.isNotEmpty).toList();
    
    String initials;
    if (parts.length >= 2) {
      // Get first letter of first and second word
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      // Get first letter of the single word
      initials = parts[0][0].toUpperCase();
    } else {
      // Fallback if somehow still empty
      initials = '?';
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade500, Colors.yellow.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatUserPhone(Map<String, dynamic> user) {
    final phone = user['phone'];
    if (phone == null) return '';
    
    if (phone is Map<String, dynamic>) {
      final countryCode = phone['countryCode']?.toString() ?? '';
      final number = phone['number']?.toString() ?? '';
      if (number.isNotEmpty) {
        return '$countryCode$number';
      }
    } else if (phone is String) {
      return phone;
    }
    
    return '';
  }

  Future<void> _handleAdmitUser(Map<String, dynamic> user) async {
  try {
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    final isQuickAppointment = apptType == 'quick' && 
                              quickApt is Map<String, dynamic> && 
                              quickApt['isQuickAppointment'] == true;
    
    final totalUsersCount = _getTotalNumberOfUsers();
    final usersList = (_checkInStatus['users'] as List<dynamic>);
    final isLargeGroup = totalUsersCount > 10;
    
    // For quick appointments or large groups, use partial admit flow (admit 1 more user)
    if (isQuickAppointment || isLargeGroup) {
      final currentlyAdmitted = _getAdmittedUsers();
      
      // Don't allow admitting if all users are already admitted
      if (currentlyAdmitted >= totalUsersCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All users are already admitted'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // For large groups, if the user is in the array, update them first
      // Then use partial admit flow to increment the count
      if (isLargeGroup && !isQuickAppointment) {
        // Try to find and update the user in the array using userId
        final userIndex = usersList.indexWhere((u) => u['userId'] == user['userId']);
        
        if (userIndex != -1) {
          final currentUser = usersList[userIndex] as Map<String, dynamic>;
          final currentStatus = currentUser['status']?.toString().toLowerCase() ?? 'not_arrived';
          
          // Only update if status is actually changing
          if (currentStatus != 'checked_in' && currentStatus != 'checked_in_partial') {
            final updatedUsers = usersList.map((u) => 
              Map<String, dynamic>.from(u as Map)
            ).toList();
            
            updatedUsers[userIndex] = {
              ...currentUser,
              'status': 'checked_in_partial',
              'checkedInAt': DateTime.now().toIso8601String(),
            };
            
            // Update the checkInStatus locally before calling partial admit
            setState(() {
              _checkInStatus = {
                ..._checkInStatus,
                'users': updatedUsers,
              };
            });
          }
        }
      }
      
      // Admit 1 more user (additional count = 1)
      await _admitPartialUsers(1, currentlyAdmitted, totalUsersCount);
      return;
    }
    
    // For normal appointments (≤10 users), use exact same logic as guard side
    // Create a deep copy of users to preserve all existing fields
    final updatedUsers = List<Map<String, dynamic>>.from(
      usersList.map((u) => Map<String, dynamic>.from(u as Map<String, dynamic>))
    );
    
    // Match user by userId directly (as fallback, but we'll use userId here)
    int userIndex = updatedUsers.indexWhere((u) => u['userId'] == user['userId']);
    
    if (userIndex != -1) {
      // Update user status exactly like guard side (no status check)
      updatedUsers[userIndex] = {
        ...updatedUsers[userIndex],
        'status': 'checked_in',
        'checkedInAt': DateTime.now().toIso8601String(),
        'type': 'vip', // You can remove this line if you don't want to add VIP
      };

      // Calculate main status based on all users
      final mainStatus = _calculateMainStatus(updatedUsers);

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: _checkInStatus['_id'],
        mainStatus: mainStatus,
        users: updatedUsers,
        totalUsers: totalUsersCount,
      );

      if (result['success']) {
        // Update the checkInStatus with the response data
        setState(() {
          final responseData = result['data'] as Map<String, dynamic>;
          _checkInStatus = Map<String, dynamic>.from(responseData);
          // Ensure the users array is properly updated from the response
          if (responseData['users'] != null) {
            final responseUsers = List<dynamic>.from(responseData['users']);
            // Find and update the user in the response to ensure status is correct
            final responseUserIndex = responseUsers.indexWhere((u) => u['userId'] == user['userId']);
            
            // If user found in response, ensure status is checked_in
            if (responseUserIndex != -1) {
              final responseUser = responseUsers[responseUserIndex] as Map<String, dynamic>;
              responseUsers[responseUserIndex] = {
                ...responseUser,
                'status': 'checked_in',
                'checkedInAt': responseUser['checkedInAt'] ?? DateTime.now().toIso8601String(),
              };
            }
            
            _checkInStatus['users'] = responseUsers;
          } else {
            // If response doesn't have users, use our updated users array
            _checkInStatus['users'] = updatedUsers;
          }
        });
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['fullName'] ?? 'User'} admitted successfully'),
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
    } else {
      // User not found - show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not found in the list. Please refresh and try again.'),
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


  Future<void> _handleRejectUser(Map<String, dynamic> user) async {
  try {
    // Create a deep copy of users exactly like guard side
    final updatedUsers = List<Map<String, dynamic>>.from(
      (_checkInStatus['users'] as List<dynamic>).map((u) => 
        Map<String, dynamic>.from(u as Map<String, dynamic>)
      )
    );
    
    // Match user by userId instead of fullName and userType
    final userIndex = updatedUsers.indexWhere((u) => 
      u['userId'] == user['userId']
    );

    if (userIndex != -1) {
      // Update user status to 'rejected', add rejection timestamp, and set 'vip' type
      updatedUsers[userIndex] = {
        ...updatedUsers[userIndex],
        'status': 'rejected',
        'rejectedAt': DateTime.now().toIso8601String(),
        'type': 'vip',  // Set type as 'vip'
      };

      // Calculate main status based on all users
      final mainStatus = _calculateMainStatus(updatedUsers);

      // Call the service to update the check-in status
      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: _checkInStatus['_id'],
        mainStatus: mainStatus,
        users: updatedUsers,
        totalUsers: _getTotalNumberOfUsers(),
      );

      if (result['success']) {
        setState(() {
          _checkInStatus = result['data'];
        });
        widget.onUpdate();
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not found in the list. Please refresh and try again.'),
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


  Future<void> _handleAdmitAll() async {
    try {
      // Create a deep copy of users to preserve all existing fields
      final updatedUsers = (_checkInStatus['users'] as List<dynamic>).map((u) => 
        Map<String, dynamic>.from(u as Map)
      ).toList();
      
      // Update all users to checked_in (only those whose status is changing)
      for (int i = 0; i < updatedUsers.length; i++) {
        final userStatus = updatedUsers[i]['status']?.toString().toLowerCase() ?? 'not_arrived';
        if (userStatus != 'checked_in' && userStatus != 'rejected') {
          updatedUsers[i] = {
            ...updatedUsers[i],
            'status': 'checked_in',
            'checkedInAt': DateTime.now().toIso8601String(),
            'type': 'vip',
          };
        }
      }

      // Calculate main status
      final mainStatus = _calculateMainStatus(updatedUsers);

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: _checkInStatus['_id'],
        mainStatus: mainStatus,
        users: updatedUsers,
        totalUsers: _getTotalNumberOfUsers(),
      );

      if (result['success']) {
        setState(() {
          _checkInStatus = result['data'];
        });
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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

  void _showPartialAdmissionDialog() {
    final TextEditingController countController = TextEditingController();
    final totalUsers = _getTotalNumberOfUsers();
    final currentlyAdmitted = _getAdmittedUsers();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admit Partial Users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter the number of users to admit (including the main user)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Input section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How many more users to admit:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Note: Currently $currentlyAdmitted admitted out of $totalUsers total. You can admit up to ${totalUsers - currentlyAdmitted} more users.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter count',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total users: $totalUsers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currently admitted: $currentlyAdmitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Footer buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final additionalCount = int.tryParse(countController.text);
                        final maxCanAdmit = totalUsers - currentlyAdmitted;
                        
                        // Validate: additionalCount should be between 1 and maxCanAdmit
                        if (additionalCount != null && additionalCount > 0 && additionalCount <= maxCanAdmit) {
                          Navigator.of(context).pop();
                          // Send additional count to backend (backend will add it to existing)
                          _admitPartialUsers(additionalCount, currentlyAdmitted, totalUsers);
                        } else if (additionalCount != null && additionalCount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a number greater than 0'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (additionalCount != null && additionalCount > maxCanAdmit) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You can only admit $maxCanAdmit more user${maxCanAdmit != 1 ? 's' : ''} (currently $currentlyAdmitted admitted out of $totalUsers total)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please enter a valid number between 1 and $maxCanAdmit'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _admitPartialUsers(int additionalCount, int currentlyAdmitted, int totalUsersCount) async {
    try {
      // Check if this is a quick appointment
      final apptType = widget.appointment['appt_type']?.toString();
      final quickApt = widget.appointment['quick_apt'];
      final isQuickAppointment = apptType == 'quick' && 
                                quickApt is Map<String, dynamic> && 
                                quickApt['isQuickAppointment'] == true;
      
      final List<dynamic> usersList = _checkInStatus['users'] as List<dynamic>;
      
      // Calculate total count after admitting additional users
      final totalCountAfterAdmit = currentlyAdmitted + additionalCount;

      // For normal appointments with ≤10 users, update individual users in the array
      if (!isQuickAppointment && totalUsersCount <= 10 && usersList.length == totalUsersCount) {
        // Create a deep copy of users
        final updatedUsers = usersList.map((u) => 
          Map<String, dynamic>.from(u as Map)
        ).toList();
        
        // Count how many users need to be admitted
        int usersToAdmit = additionalCount;
        for (int i = 0; i < updatedUsers.length && usersToAdmit > 0; i++) {
          final userStatus = updatedUsers[i]['status']?.toString().toLowerCase() ?? 'not_arrived';
          // Only update users that are not already admitted or rejected
          if (userStatus != 'checked_in' && userStatus != 'rejected') {
            updatedUsers[i] = {
              ...updatedUsers[i],
              'status': 'checked_in',
              'checkedInAt': DateTime.now().toIso8601String(),
              'type': 'vip',
            };
            usersToAdmit--;
          }
        }
        
        // Calculate main status based on all users
        final mainStatus = _calculateMainStatus(updatedUsers.cast<Map<String, dynamic>>());
        
        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: _checkInStatus['_id'],
          mainStatus: mainStatus,
          users: updatedUsers,
          totalUsers: totalUsersCount,
          // Don't send partialUsersCount for normal appointments with complete user array
        );
        
        if (result['success']) {
          setState(() {
            _checkInStatus = result['data'];
          });
          widget.onUpdate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$additionalCount more user${additionalCount != 1 ? 's' : ''} admitted successfully (Total: $totalCountAfterAdmit)'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to partially admit users'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // For quick appointments or large groups (>10 users), update main user and send partialUsersCount
      final mainUser = usersList.isNotEmpty ? usersList.first as Map<String, dynamic> : <String, dynamic>{};
      final currentMainUserStatus = mainUser['status']?.toString().toLowerCase() ?? 'not_arrived';
      
      // Determine the status based on whether all users are admitted
      String mainStatus;
      if (totalCountAfterAdmit >= totalUsersCount) {
        mainStatus = 'checked_in';
      } else {
        mainStatus = 'checked_in_partial';
      }
      
      // If user is already fully checked_in and we're trying to set it to checked_in again, don't update
      // Only update if status is actually changing
      if ((currentMainUserStatus == 'checked_in' || currentMainUserStatus == 'checked_in_partial') && mainStatus == 'checked_in') {
        // User is already admitted (fully or partially), just update the partialUsersCount without changing user status
        // Make sure we preserve the existing user object exactly as is
        final result = await ActionService.updateCheckInStatus(
          checkInStatusId: _checkInStatus['_id'],
          mainStatus: mainStatus,
          users: [Map<String, dynamic>.from(mainUser)], // Send copy of existing user without changes
          totalUsers: totalUsersCount,
          partialUsersCount: additionalCount, // Send additional count, not total
        );
        
        if (result['success']) {
          setState(() {
            // Update checkInStatus but preserve the user's existing status
            final updatedCheckInStatus = Map<String, dynamic>.from(result['data']);
            final updatedUsers = updatedCheckInStatus['users'] as List<dynamic>?;
            if (updatedUsers != null && updatedUsers.isNotEmpty) {
              // Ensure the first user (main user) maintains its checked_in status
              final firstUser = updatedUsers[0] as Map<String, dynamic>;
              if (firstUser['status']?.toString().toLowerCase() != 'checked_in') {
                // If backend changed it, restore it
                updatedUsers[0] = {
                  ...firstUser,
                  'status': 'checked_in',
                  'checkedInAt': mainUser['checkedInAt'] ?? firstUser['checkedInAt'],
                };
              }
            }
            _checkInStatus = updatedCheckInStatus;
          });
          widget.onUpdate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$additionalCount more user${additionalCount != 1 ? 's' : ''} admitted successfully (Total: $totalCountAfterAdmit)'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to partially admit users'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Only update checkedInAt if the user wasn't already admitted
      // Preserve existing checkedInAt if user is already in checked_in or checked_in_partial status
      final updatedMainUser = {
        ...mainUser,
        'status': mainStatus == 'checked_in' ? 'checked_in' : 'checked_in_partial',
        // Only set checkedInAt if user wasn't already admitted
        if (currentMainUserStatus != 'checked_in' && currentMainUserStatus != 'checked_in_partial')
          'checkedInAt': DateTime.now().toIso8601String(),
      };

      final result = await ActionService.updateCheckInStatus(
        checkInStatusId: _checkInStatus['_id'],
        mainStatus: mainStatus,
        users: [updatedMainUser],
        totalUsers: totalUsersCount,
        partialUsersCount: additionalCount, // Send additional count, not total
      );

      if (result['success']) {
        setState(() {
          _checkInStatus = result['data'];
        });
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$additionalCount more user${additionalCount != 1 ? 's' : ''} admitted successfully (Total: $totalCountAfterAdmit)'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to partially admit users'),
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

}
