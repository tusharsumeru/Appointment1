import 'package:flutter/material.dart';

class DateSelectorComponent extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const DateSelectorComponent({
    super.key,
    this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Colors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              selectedDate != null
                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                  : 'Select Date',
              style: TextStyle(
                fontSize: 16,
                color: selectedDate != null ? Colors.black87 : Colors.grey.shade600,
                fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020), // Allow dates from 2020 onwards
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.deepPurple,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateSelected(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 