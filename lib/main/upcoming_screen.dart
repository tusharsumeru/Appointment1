import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import 'today_screen.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Sample events data - appointments for July 5th and 20th
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    // July 5th appointments
    DateTime(2024, 7, 5): [
      {'title': 'Dr. Smith', 'color': Colors.blue.shade300},
      {'title': 'Lab Test', 'color': Colors.orange.shade300},
      {'title': 'X-Ray', 'color': Colors.purple.shade300},
    ],
    
    // July 5th appointments (2025) - 4 appointments
    DateTime(2025, 7, 5): [
      {'title': 'Dr. Smith', 'color': Colors.blue.shade300},
      {'title': 'Lab Test', 'color': Colors.orange.shade300},
      {'title': 'X-Ray', 'color': Colors.purple.shade300},
      {'title': 'MRI Scan', 'color': Colors.grey.shade300},
    ],
    
    // July 20th appointments
    DateTime(2024, 7, 20): [
      {'title': 'Cardiology', 'color': Colors.red.shade300},
      {'title': 'Physical Therapy', 'color': Colors.green.shade300},
      {'title': 'Dental Check', 'color': Colors.teal.shade300},
    ],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _navigateToTodayScreen(DateTime selectedDate) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TodayScreen(selectedDate: selectedDate),
      ),
    );
  }

  Future<void> _selectYear(BuildContext context) async {
    final currentYear = DateTime.now().year;
    final int? pickedYear = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: currentYear - 2019, // 2020 to current year
              itemBuilder: (context, index) {
                final year = 2020 + index;
                return ListTile(
                  title: Text(year.toString()),
                  selected: year == _focusedDay.year,
                  onTap: () {
                    Navigator.of(context).pop(year);
                  },
                );
              },
            ),
          ),
        );
      },
    );
    
    if (pickedYear != null && pickedYear != _focusedDay.year) {
      setState(() {
        _focusedDay = DateTime(pickedYear, _focusedDay.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                });
              },
            ),
            GestureDetector(
              onTap: () => _selectYear(context),
              child: Row(
                children: [
                  Text('${_getMonthName(_focusedDay.month)} ${_focusedDay.year}'),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                });
              },
            ),
          ],
        ),
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
          // Days of the week header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Calendar grid
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate total cells needed (including previous month's days)
    final totalCells = firstWeekday + daysInMonth;
    final weeks = (totalCells / 7).ceil();
    
    return ListView.builder(
      itemCount: weeks,
      itemBuilder: (context, weekIndex) {
        return Row(
          children: List.generate(7, (dayIndex) {
            final cellIndex = weekIndex * 7 + dayIndex;
            final dayOffset = cellIndex - firstWeekday;
            
            if (dayOffset < 0) {
              // Previous month's days
              final prevMonthLastDay = DateTime(_focusedDay.year, _focusedDay.month, 0);
              final day = prevMonthLastDay.day + dayOffset + 1;
              return Expanded(
                child: _buildCalendarCell(day, isCurrentMonth: false),
              );
            } else if (dayOffset >= daysInMonth) {
              // Next month's days
              final day = dayOffset - daysInMonth + 1;
              return Expanded(
                child: _buildCalendarCell(day, isCurrentMonth: false),
              );
            } else {
              // Current month's days
              final day = dayOffset + 1;
              final currentDate = DateTime(_focusedDay.year, _focusedDay.month, day);
              final isSelected = _selectedDay != null && 
                  _selectedDay!.year == currentDate.year &&
                  _selectedDay!.month == currentDate.month &&
                  _selectedDay!.day == currentDate.day;
              final isToday = DateTime.now().year == currentDate.year &&
                  DateTime.now().month == currentDate.month &&
                  DateTime.now().day == currentDate.day;
              
              return Expanded(
                child: _buildCalendarCell(
                  day,
                  isCurrentMonth: true,
                  isSelected: isSelected,
                  isToday: isToday,
                  events: _getEventsForDay(currentDate),
                ),
              );
            }
          }),
        );
      },
    );
  }

  Widget _buildCalendarCell(
    int day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool isToday = false,
    List<Map<String, dynamic>> events = const [],
  }) {
    return GestureDetector(
      onTap: () {
        if (isCurrentMonth) {
          final selectedDate = DateTime(_focusedDay.year, _focusedDay.month, day);
          _navigateToTodayScreen(selectedDate);
        }
      },
      child: Container(
        height: 80,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.shade100 
              : isToday 
                  ? Colors.blue.shade50
                  : Colors.white,
          border: isSelected 
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // Day number
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCurrentMonth 
                      ? Colors.black87 
                      : Colors.grey.shade400,
                ),
              ),
            ),
            
            // Static "4" for July 5th, 2025
            if (_focusedDay.year == 2025 && _focusedDay.month == 7 && day == 5)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '4',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            
            // Static "5" for July 15th, 2025
            if (_focusedDay.year == 2025 && _focusedDay.month == 7 && day == 15)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            
            // Static "8" for July 23rd, 2025
            if (_focusedDay.year == 2025 && _focusedDay.month == 7 && day == 23)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '8',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
} 