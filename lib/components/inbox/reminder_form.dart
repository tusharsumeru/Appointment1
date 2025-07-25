import 'package:flutter/material.dart';
import 'appointment_schedule_form.dart';

class ReminderForm extends StatefulWidget {
  final String appointmentId;
  final String appointmentName;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const ReminderForm({
    Key? key,
    required this.appointmentId,
    required this.appointmentName,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple handle
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Simple header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange[600],
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Schedule Appointment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Content - Scrollable
          Expanded(
            child: SingleChildScrollView(
              child: AppointmentScheduleForm(
                appointmentId: widget.appointmentId,
                appointmentName: widget.appointmentName,
                onSave: () {
                  widget.onSave?.call();
                },
                onClose: () {
                  widget.onClose?.call();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 