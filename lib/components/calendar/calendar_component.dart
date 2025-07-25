import 'package:flutter/material.dart';

class CalendarComponent extends StatefulWidget {
  const CalendarComponent({super.key});

  @override
  State<CalendarComponent> createState() => _CalendarComponentState();
}

class _CalendarComponentState extends State<CalendarComponent> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.deepPurple),
              ),
              Text(
                '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Days of week header
          Row(
            children: _getDaysOfWeek().map((day) {
              return Expanded(
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          
          // Calendar grid
          ..._buildCalendarGrid(),
        ],
      ),
    );
  }

  List<String> _getDaysOfWeek() {
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  List<Widget> _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // Convert to 0-based (Sunday = 0)
    
    List<Widget> calendarRows = [];
    int dayCounter = 1;
    
    // Calculate number of weeks needed
    int totalCells = firstWeekday + daysInMonth;
    int weeks = (totalCells / 7).ceil();
    
    for (int week = 0; week < weeks; week++) {
      List<Widget> weekRow = [];
      
      for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
        if ((week == 0 && dayOfWeek < firstWeekday) || dayCounter > daysInMonth) {
          // Empty cell
          weekRow.add(
            Expanded(
              child: Container(
                height: 35,
                alignment: Alignment.center,
                child: const Text(''),
              ),
            ),
          );
        } else {
          // Day cell
          final currentDate = DateTime(_focusedDay.year, _focusedDay.month, dayCounter);
          final isToday = _isToday(currentDate);
          final isSelected = _isSameDay(currentDate, _selectedDay);
          
          weekRow.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = currentDate;
                  });
                },
                child: Container(
                  height: 35,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.deepPurple 
                        : isToday 
                            ? Colors.deepPurple.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday 
                        ? Border.all(color: Colors.deepPurple, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayCounter.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? Colors.white 
                          : isToday 
                              ? Colors.deepPurple
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      
      calendarRows.add(Row(children: weekRow));
    }
    
    return calendarRows;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
} 