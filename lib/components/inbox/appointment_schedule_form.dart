import 'package:flutter/material.dart';

class AppointmentScheduleForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const AppointmentScheduleForm({
    Key? key,
    required this.appointment,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<AppointmentScheduleForm> createState() => _AppointmentScheduleFormState();
}

class _AppointmentScheduleFormState extends State<AppointmentScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _scheduleDateController = TextEditingController();
  final TextEditingController _scheduleTimeController = TextEditingController();
  
  // Form values
  String _selectedTime = '16:30';
  String _selectedMeetingType = 'Offline';
  String _selectedVenue = 'Secretariat Office A1, Art of Living International Center, Bangalore.';
  String _selectedArrivalTime = '17:15';
  
  // Checkbox states
  bool _tbsReq = true;
  bool _dontSendEmailSms = false;
  bool _sendArrivalTime = false;
  bool _scheduleEmailSms = false;
  bool _sendVdsEmail = false;
  bool _stayAvailable = false;
  
  // Visibility states
  bool _showArrivalTime = false;
  bool _showScheduleTime = false;
  bool _showOfflineVenue = true;
  bool _showOnlineVenue = false;

  final List<String> _venues = [
    'Secretariat Office A1, Art of Living International Center, Bangalore.',
    'Special Enclosure - Shiva Temple, next to Yoga school, Art of Living International Center, Bangalore.',
    'Yoga School, next to Maitri Hall, Art of Living International Center, Bangalore.',
    'Radha Kunj, Near Sri Sri Tattva Panchakarma Admin Office',
    'Shiva Temple, next to Yoga school, Art of Living International Center, Bangalore.',
    'Satsang Backstage',
    'Gurukul',
  ];

  @override
  void initState() {
    super.initState();
    _timeController.text = _selectedTime;
    _arrivalTimeController.text = _selectedArrivalTime;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _arrivalTimeController.dispose();
    _scheduleDateController.dispose();
    _scheduleTimeController.dispose();
    super.dispose();
  }

  void _onMeetingTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedMeetingType = value;
        _showOfflineVenue = value == 'Offline';
        _showOnlineVenue = value == 'Zoom Meeting';
      });
    }
  }

  void _onSendArrivalTimeChanged(bool? value) {
    setState(() {
      _sendArrivalTime = value ?? false;
      _showArrivalTime = value ?? false;
    });
  }

  void _onScheduleEmailSmsChanged(bool? value) {
    setState(() {
      _scheduleEmailSms = value ?? false;
      _showScheduleTime = value ?? false;
    });
  }

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically send the data to your backend
      widget.onSave?.call();
      Navigator.of(context).pop();
    }
  }

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getAppointmentName(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Time Section Header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Date Field
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          _dateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Time Field
                    TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Select Time',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: 16, minute: 30),
                        );
                        if (time != null) {
                          _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          setState(() {
                            _selectedTime = _timeController.text;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Options Section Header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Checkboxes
                    _buildCheckbox(
                      value: _tbsReq,
                      onChanged: (value) => setState(() => _tbsReq = value ?? true),
                      title: 'TBS/Req',
                    ),
                    
                    _buildCheckbox(
                      value: _dontSendEmailSms,
                      onChanged: (value) => setState(() => _dontSendEmailSms = value ?? false),
                      title: 'Don\'t send Email/SMS',
                    ),
                    
                    _buildCheckbox(
                      value: _sendArrivalTime,
                      onChanged: _onSendArrivalTimeChanged,
                      title: 'Send Arrival Time',
                    ),
                    
                    // Arrival Time Field (conditional)
                    if (_showArrivalTime) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _arrivalTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Select Arrival Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: 17, minute: 15),
                          );
                          if (time != null) {
                            _arrivalTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            setState(() {
                              _selectedArrivalTime = _arrivalTimeController.text;
                            });
                          }
                        },
                      ),
                    ],
                    
                    _buildCheckbox(
                      value: _scheduleEmailSms,
                      onChanged: _onScheduleEmailSmsChanged,
                      title: 'Schedule Email & SMS Confirmation',
                    ),
                    
                    // Schedule Date and Time Fields (conditional)
                    if (_showScheduleTime) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _scheduleDateController,
                        decoration: const InputDecoration(
                          labelText: 'Select Schedule Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _scheduleDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _scheduleTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Select Schedule Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            _scheduleTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                    ],
                    
                    _buildCheckbox(
                      value: _sendVdsEmail,
                      onChanged: (value) => setState(() => _sendVdsEmail = value ?? false),
                      title: 'Send VDS Email',
                    ),
                    
                    _buildCheckbox(
                      value: _stayAvailable,
                      onChanged: (value) => setState(() => _stayAvailable = value ?? false),
                      title: 'Stay Available',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Meeting Details Section Header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Meeting Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Meeting Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedMeetingType,
                      decoration: const InputDecoration(
                        labelText: 'Select Meeting Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Offline', child: Text('Offline')),
                        DropdownMenuItem(value: 'Zoom Meeting', child: Text('Zoom Meeting')),
                      ],
                      onChanged: _onMeetingTypeChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a meeting type';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Venue Selection
                    if (_showOfflineVenue) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedVenue,
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: _venues.map((venue) {
                          return DropdownMenuItem(
                            value: venue,
                            child: Text(venue.split(',')[0]), // Show only the first part
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedVenue = value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a venue';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    if (_showOnlineVenue) ...[
                      TextFormField(
                        initialValue: 'Online Zoom Meeting',
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.video_call),
                        ),
                        readOnly: true,
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onClose?.call();
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 