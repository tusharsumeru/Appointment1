import 'package:flutter/material.dart';
import '../../action/action.dart';
import 'today_detail_component.dart';

class TodayCardComponent extends StatefulWidget {
  const TodayCardComponent({super.key});

  @override
  State<TodayCardComponent> createState() => _TodayCardComponentState();
}

class _TodayCardComponentState extends State<TodayCardComponent> {
  List<Map<String, dynamic>> _todayAppointments = [];
  bool _isLoading = false;
  String? _error;

  // Category definitions
  final Map<String, Map<String, dynamic>> _categories = {
    'morning': {
      'title': 'Morning',
      'icon': Icons.wb_sunny,
      'color': Colors.orange,
      'timeRange': {'start': 6, 'end': 12},
    },
    'evening': {
      'title': 'Evening',
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.amber,
      'timeRange': {'start': 12, 'end': 18},
    },
    'night': {
      'title': 'Night',
      'icon': Icons.nightlight_round,
      'color': Colors.indigo,
      'timeRange': {'start': 18, 'end': 24},
    },
    'tbs_req': {
      'title': 'TBS/Req',
      'icon': Icons.pending_actions,
      'color': Colors.red,
      'timeRange': null, // Based on status
    },
    'done': {
      'title': 'Done',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'timeRange': null, // Based on status
    },
    'satsang_backstage': {
      'title': 'Satsang Backstage',
      'icon': Icons.music_note,
      'color': Colors.purple,
      'timeRange': null, // Based on venue
    },
    'gurukul': {
      'title': 'Gurukul',
      'icon': Icons.school,
      'color': Colors.teal,
      'timeRange': null, // Based on venue
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchTodayAppointments();
  }

  Future<void> _fetchTodayAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ActionService.getAppointmentsWithFilters(
        today: true,
        sortBy: 'scheduledTime',
        sortOrder: 'asc',
      );

      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];
        
        if (appointmentsData.isNotEmpty) {
          final sortedAppointments = appointmentsData.cast<Map<String, dynamic>>();
          sortedAppointments.sort((a, b) {
            final timeA = a['scheduledTime']?.toString() ?? '';
            final timeB = b['scheduledTime']?.toString() ?? '';
            return timeA.compareTo(timeB);
          });
          
          _todayAppointments = sortedAppointments;
          
          // Debug: Print first appointment data to understand structure
          if (_todayAppointments.isNotEmpty) {
            print('🔍 Debug: First appointment data:');
            print('ID: ${_todayAppointments[0]['_id']}');
            print('All fields: ${_todayAppointments[0].keys.toList()}');
            print('Scheduled Time: ${_todayAppointments[0]['scheduledTime']}');
            print('Preferred Time: ${_todayAppointments[0]['preferredTime']}');
            print('Created At: ${_todayAppointments[0]['createdAt']}');
            print('Status: ${_todayAppointments[0]['status']}');
            print('Location: ${_getLocation(_todayAppointments[0])}');
            print('User Designation: ${_todayAppointments[0]['userCurrentDesignation']}');
            print('---');
          }
        } else {
          _todayAppointments = [];
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to fetch today\'s appointments';
        _todayAppointments = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _todayAppointments = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getAppointmentsForCategory(String categoryKey) {
    if (_todayAppointments.isEmpty) return [];

    switch (categoryKey) {
      case 'morning':
      case 'evening':
      case 'night':
        return _todayAppointments.where((appointment) {
          // Try multiple time fields
          String? timeString = appointment['scheduledTime']?.toString() ?? 
                              appointment['preferredTime']?.toString() ?? 
                              appointment['createdAt']?.toString();
          
          if (timeString == null) {
            print('❌ No time field found for appointment: ${appointment['_id']}');
            return false;
          }
          
          try {
            final time = DateTime.parse(timeString);
            final hour = time.hour;
            final category = _categories[categoryKey]!;
            final start = category['timeRange']['start'] as int;
            final end = category['timeRange']['end'] as int;
            
            final isInRange = start <= end ? 
              (hour >= start && hour < end) : 
              (hour >= start || hour < end);
            
            if (isInRange) {
              print('✅ ${categoryKey.toUpperCase()}: Appointment ${appointment['_id']} at ${time.hour}:${time.minute}');
            }
            
            return isInRange;
          } catch (e) {
            print('❌ Error parsing time "$timeString": $e');
            return false;
          }
        }).toList();

      case 'tbs_req':
        return _todayAppointments.where((appointment) {
          final status = appointment['status']?.toString().toLowerCase();
          final isTbsReq = status == 'pending' || status == 'tbs' || status == 'requested';
          if (isTbsReq) {
            print('✅ TBS/REQ: Appointment ${appointment['_id']} with status: $status');
          }
          return isTbsReq;
        }).toList();

      case 'done':
        return _todayAppointments.where((appointment) {
          final status = appointment['status']?.toString().toLowerCase();
          final isDone = status == 'completed' || status == 'done';
          if (isDone) {
            print('✅ DONE: Appointment ${appointment['_id']} with status: $status');
          }
          return isDone;
        }).toList();

      case 'satsang_backstage':
        return _todayAppointments.where((appointment) {
          final location = _getLocation(appointment).toLowerCase();
          final isSatsangBackstage = location.contains('satsang') && location.contains('backstage');
          if (isSatsangBackstage) {
            print('✅ SATSANG BACKSTAGE: Appointment ${appointment['_id']} at location: $location');
          }
          return isSatsangBackstage;
        }).toList();

      case 'gurukul':
        return _todayAppointments.where((appointment) {
          final location = _getLocation(appointment).toLowerCase();
          final isGurukul = location.contains('gurukul');
          if (isGurukul) {
            print('✅ GURUKUL: Appointment ${appointment['_id']} at location: $location');
          }
          return isGurukul;
        }).toList();

      default:
        return [];
    }
  }

  String _getLocation(Map<String, dynamic> appointment) {
    // First try to get location from appointmentLocation object
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
    final locationString = appointment['locationName']?.toString() ?? 
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



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      );
    }

    if (_error != null) {
      return Center(
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
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
                      Icon(
                        Icons.today,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
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
                  Text(
                    'Total Appointments: ${_todayAppointments.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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

  Widget _buildCategoryCard(Map<String, dynamic> category, List<Map<String, dynamic>> appointments, String categoryKey) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TodayDetailComponent(
              categoryTitle: category['title'],
              categoryColor: category['color'],
              categoryIcon: category['icon'],
              appointments: appointments,
            ),
          ),
        );
      },
      child: Container(
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: category['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                category['icon'],
                color: category['color'],
                size: 24,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ],
          ),
        ),
      ),
    );
  }


} 