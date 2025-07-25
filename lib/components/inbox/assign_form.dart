import 'package:flutter/material.dart';
import '../../models/appointment.dart';

class AssignForm extends StatefulWidget {
  final String appointmentId;
  final String appointmentName;
  final List<Assignee> availableAssignees;
  final Function(String)? onAssignTo;
  final VoidCallback? onClose;

  const AssignForm({
    Key? key,
    required this.appointmentId,
    required this.appointmentName,
    required this.availableAssignees,
    this.onAssignTo,
    this.onClose,
  }) : super(key: key);

  @override
  State<AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<AssignForm> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.group_add,
                  color: Colors.indigo[600],
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Assign to Team',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Content - Compact list
          Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.availableAssignees.map((assignee) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo[100],
                  child: Text(
                    assignee.initials,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                title: Text(
                  assignee.name,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
                onTap: () {
                  widget.onAssignTo?.call('${widget.appointmentId}|${assignee.id}|${assignee.name}');
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onClose?.call();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 