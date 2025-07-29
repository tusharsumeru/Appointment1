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

  String _selectedAssignee = '';

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

  void _assignTo(String assigneeId, String assigneeName) {
    setState(() {
      _selectedAssignee = assigneeId;
    });
    widget.onAssignTo?.call('${_getAppointmentId()}|$assigneeId|$assigneeName');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Radio buttons for assignees
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _availableAssignees.map((assignee) {
                  final isSelected = _selectedAssignee == assignee['id'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: assignee['id']!,
                      groupValue: _selectedAssignee,
                      onChanged: (value) {
                        if (value != null) {
                          _assignTo(value, assignee['name']);
                        }
                      },
                      title: Row(
                        children: [
                          CircleAvatar(
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assignee['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.indigo : Colors.black87,
                                  ),
                                ),
                                Text(
                                  assignee['email'],
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
                      activeColor: Colors.indigo,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),
            ),
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
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAssignee.isNotEmpty ? () {
                      final selectedAssignee = _availableAssignees.firstWhere(
                        (assignee) => assignee['id'] == _selectedAssignee,
                      );
                      _assignTo(_selectedAssignee, selectedAssignee['name']);
                      Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Assign'),
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