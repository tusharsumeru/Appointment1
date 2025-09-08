import 'package:flutter/material.dart';

class DarshanLineForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const DarshanLineForm({
    Key? key,
    required this.appointment,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<DarshanLineForm> createState() => _DarshanLineFormState();
}

class _DarshanLineFormState extends State<DarshanLineForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String _selectedDarshanLine = '';

  // Darshan line options
  final List<Map<String, String>> _darshanLineOptions = [
    {'value': 'P1', 'label': 'P1', 'type': 'darshan_line'},
    {'value': 'P2', 'label': 'P2', 'type': 'darshan_line'},
    {'value': 'SB', 'label': 'SB', 'type': 'backstage'},
    {'value': 'PB', 'label': 'PB', 'type': 'backstage'},
    {'value': 'Z', 'label': 'Z', 'type': 'backstage'},
  ];

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _saveDarshanLine() {
    // Here you would typically send the data to your backend
    // You can access the selected darshan line via _selectedDarshanLine
    widget.onSave?.call();
    Navigator.of(context).pop();
  }

  void _moveDarshanLine(String appointmentId, String option) {
    setState(() {
      _selectedDarshanLine = option;
    });
    // Here you would call your move_darshan_line function
  }

  void _moveBackstage(String appointmentId, String option) {
    setState(() {
      _selectedDarshanLine = option;
    });
    // Here you would call your move_backstage function
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
          // Form
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Radio buttons for darshan line options
                    ..._darshanLineOptions.map((option) {
                      final isSelected = _selectedDarshanLine == option['value'];
                      final isDarshanLine = option['type'] == 'darshan_line';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: RadioListTile<String>(
                          value: option['value']!,
                          groupValue: _selectedDarshanLine,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedDarshanLine = value;
                              });
                              
                              // Call appropriate function based on type
                              if (isDarshanLine) {
                                _moveDarshanLine(_getAppointmentId(), value);
                              } else {
                                _moveBackstage(_getAppointmentId(), value);
                              }
                            }
                          },
                          title: Row(
                            children: [
                              Icon(
                                isDarshanLine ? Icons.queue : Icons.people,
                                color: isSelected ? Colors.deepPurple : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option['label']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.deepPurple : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDarshanLine ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isDarshanLine ? 'Darshan Line' : 'Backstage',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDarshanLine ? Colors.blue : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          activeColor: Colors.deepPurple,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ],
                ),
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
                    onPressed: _selectedDarshanLine.isNotEmpty ? () {
                      _saveDarshanLine();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
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