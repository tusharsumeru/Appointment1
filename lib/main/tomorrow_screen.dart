import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/tomorrow/tomorrow_card_component.dart';
import 'today_screen.dart';
import 'upcoming_screen.dart';
import 'global_search_screen.dart';

class TomorrowScreen extends StatefulWidget {
  const TomorrowScreen({super.key});

  @override
  State<TomorrowScreen> createState() => _TomorrowScreenState();
}

class _TomorrowScreenState extends State<TomorrowScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _refreshCounter = 0;

  String _getFormattedDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getFormattedDay(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
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
      // Get today's date (without time)
      final DateTime today = DateTime.now();
      final DateTime todayOnly = DateTime(today.year, today.month, today.day);
      
      // Get tomorrow's date
      final DateTime tomorrow = todayOnly.add(const Duration(days: 1));
      
      // Get the picked date (without time)
      final DateTime pickedOnly = DateTime(picked.year, picked.month, picked.day);
      
      // Navigate to appropriate screen based on selected date
      if (pickedOnly.isAtSameMomentAs(todayOnly)) {
        // Selected today - navigate to today screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TodayScreen(),
          ),
        );
      } else if (pickedOnly.isAtSameMomentAs(tomorrow)) {
        // Selected tomorrow - stay in tomorrow screen
        setState(() {
          _selectedDate = picked;
        });
      } else if (pickedOnly.isAfter(tomorrow)) {
        // Selected date after tomorrow - navigate to upcoming screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UpcomingScreen(),
          ),
        );
      } else {
        // Selected date in the past - navigate to today screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TodayScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tomorrow'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const SidebarComponent(),
      body: Column(
        children: [
          // Header with refresh button and calendar icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date selector button on the left
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    width: 192, // w-48 equivalent (48 * 4 = 192)
                    height: 44, // h-11 equivalent (11 * 4 = 44)
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFormattedDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
                // Refresh button on the right
                GestureDetector(
                  onTap: () {
                    // Refresh the tomorrow card component
                    setState(() {
                      _refreshCounter++;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tomorrow card component
          Expanded(child: TomorrowCardComponent(
            key: ValueKey(_refreshCounter),
            selectedDate: _selectedDate,
          )),
        ],
      ),
    );
  }
} 