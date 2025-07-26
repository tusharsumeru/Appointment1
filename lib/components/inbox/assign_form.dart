import 'package:flutter/material.dart';

class AssignForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Function(String)? onAssignTo;
  final VoidCallback? onClose;

  const AssignForm({
    Key? key,
    required this.appointment,
    this.onAssignTo,
    this.onClose,
  }) : super(key: key);

  @override
  State<AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<AssignForm> {
  // Sample assignees - in real app, this would come from API
  final List<Map<String, dynamic>> _availableAssignees = [
    {'id': '1', 'name': 'Meera Prashanth', 'email': 'secratary2@sumerudigital.com'},
    {'id': '2', 'name': 'Vishal Merani', 'email': 'secratary@sumerudigital.com'},
    {'id': '3', 'name': 'KK Secretary', 'email': 'kk@sumerudigital.com'},
    {'id': '4', 'name': 'Admin Team', 'email': 'admin@sumerudigital.com'},
  ];

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assign to Team',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getAppointmentName(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content - Compact list
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableAssignees.map((assignee) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo[100],
                  child: Text(
                    _getInitials(assignee['name']),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                title: Text(
                  assignee['name'],
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  assignee['email'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
                onTap: () {
                  widget.onAssignTo?.call('${_getAppointmentId()}|${assignee['id']}|${assignee['name']}');
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
                      Navigator.pop(context);
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