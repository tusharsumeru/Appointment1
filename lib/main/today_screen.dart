import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/today/today_card_component.dart';
import '../action/action.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _todayAppointments = [];
  bool _isLoading = false;
  String? _error;

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
      // Print API call details
      print('🚀 Fetching Today\'s Appointments');
      print('API: https://f5c9f6886eb2.ngrok-free.app/api/v3/appointment/appointments/status?today=true');
      print('---');
      
      final result = await ActionService.getAppointmentsWithFilters(
        today: true,
        sortBy: 'scheduledTime', // Sort by scheduled time
        sortOrder: 'asc', // Ascending order (earliest first)
      );
      
      // Print API response details
      print('📡 Today API Response:');
      print('Success: ${result['success']}');
      print('Status Code: ${result['statusCode']}');
      print('Message: ${result['message']}');
      print('Data Count: ${(result['data'] as List?)?.length ?? 0}');
      print('---');
      
      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];
        
        if (appointmentsData.isNotEmpty) {
          // Sort appointments by scheduled time
          final sortedAppointments = appointmentsData.cast<Map<String, dynamic>>();
          sortedAppointments.sort((a, b) {
            final timeA = a['scheduledTime']?.toString() ?? '';
            final timeB = b['scheduledTime']?.toString() ?? '';
            return timeA.compareTo(timeB);
          });
          
          _todayAppointments = sortedAppointments;
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

  String _getFormattedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getFormattedDay(DateTime date) {
    final days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
      'Thursday', 'Friday', 'Saturday'
    ];
    return days[date.weekday % 7];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
              drawer: const SidebarComponent(),
        body: Column(
          children: [
            // Today's date section with calendar icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  // Date on the left
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFormattedDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFormattedDay(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Calendar icon on the right
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Today card component
            Expanded(
              child: TodayCardComponent(),
            ),
          ],
        ),
    );
  }
} 