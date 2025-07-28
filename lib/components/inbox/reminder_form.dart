import 'package:flutter/material.dart';
import '../../action/action.dart';

class ReminderForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSave;
  final VoidCallback? onClose;

  const ReminderForm({
    Key? key,
    required this.appointment,
    this.onSave,
    this.onClose,
  }) : super(key: key);

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _scheduleDateController = TextEditingController();
  final TextEditingController _scheduleTimeController = TextEditingController();
  
  // Form values
  String _selectedDate = '';
  String _selectedTime = '16:30';
  String _selectedArrivalTime = '17:15';
  String _selectedScheduleDate = '';
  String _selectedScheduleTime = '';
  String? _selectedMeetingType; // Changed to nullable and no initial value
  String _selectedVenueId = '507f1f77bcf86cd799439011'; // Default venue ID
  String _selectedVenueName = 'Secretariat Office A1';
  
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
  
  // Loading state
  bool _isLoading = false;

  // Venue data with IDs
  static const List<Map<String, String>> _venues = [
    {
      'id': '507f1f77bcf86cd799439011',
      'name': 'Secretariat Office A1',
      'fullName': 'Secretariat Office A1, Art of Living International Center, Bangalore.'
    },
    {
      'id': '507f1f77bcf86cd799439012',
      'name': 'Special Enclosure - Shiva Temple',
      'fullName': 'Special Enclosure - Shiva Temple, next to Yoga school, Art of Living International Center, Bangalore.'
    },
    {
      'id': '507f1f77bcf86cd799439013',
      'name': 'Yoga School',
      'fullName': 'Yoga School, next to Maitri Hall, Art of Living International Center, Bangalore.'
    },
    {
      'id': '507f1f77bcf86cd799439014',
      'name': 'Radha Kunj',
      'fullName': 'Radha Kunj, Near Sri Sri Tattva Panchakarma Admin Office'
    },
    {
      'id': '507f1f77bcf86cd799439015',
      'name': 'Shiva Temple',
      'fullName': 'Shiva Temple, next to Yoga school, Art of Living International Center, Bangalore.'
    },
    {
      'id': '507f1f77bcf86cd799439016',
      'name': 'Satsang Backstage',
      'fullName': 'Satsang Backstage'
    },
    {
      'id': '507f1f77bcf86cd799439017',
      'name': 'Gurukul',
      'fullName': 'Gurukul'
    },
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

  void _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare options map
        final Map<String, dynamic> options = {
          'tbsRequired': _tbsReq,
          'dontSendNotifications': _dontSendEmailSms,
          'sendArrivalTime': _sendArrivalTime,
          'scheduleEmailSmsConfirmation': _scheduleEmailSms,
          'sendVdsEmail': _sendVdsEmail,
          'stayAvailable': _stayAvailable,
        };

        // Prepare schedule confirmation if enabled
        Map<String, dynamic>? scheduleConfirmation;
        if (_scheduleEmailSms && _selectedScheduleDate.isNotEmpty && _selectedScheduleTime.isNotEmpty) {
          scheduleConfirmation = {
            'date': _selectedScheduleDate,
            'time': _selectedScheduleTime,
          };
        }

        // Call the ActionService method
        final result = await ActionService.scheduleAppointment(
          appointmentId: _getAppointmentId(),
          scheduledDate: _selectedDate,
          scheduledTime: _selectedTime,
          options: options,
          meetingType: _selectedMeetingType ?? 'in_person', // Provide default if null
          venueId: _selectedVenueId, // Use venue ID instead of venue name
          arrivalTime: _sendArrivalTime ? _selectedArrivalTime : null,
          scheduleConfirmation: scheduleConfirmation,
        );
        
        if (result['success']) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
              ),
            );
          }
          
          // Call onSave callback
          widget.onSave?.call();
          
          // Close the form
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onSendArrivalTimeChanged(bool? value) {
    setState(() {
      _sendArrivalTime = value ?? false;
      _showArrivalTime = _sendArrivalTime;
    });
  }

  void _onScheduleEmailSmsChanged(bool? value) {
    setState(() {
      _scheduleEmailSms = value ?? false;
      _showScheduleTime = _scheduleEmailSms;
    });
  }

  void _onMeetingTypeChanged(String? value) {
    setState(() {
      _selectedMeetingType = value;
      _showOfflineVenue = _selectedMeetingType == 'in_person';
      _showOnlineVenue = _selectedMeetingType == 'zoom';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
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
                          setState(() {
                            _selectedDate = _dateController.text;
                          });
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
                    
                    // TBS/Req Checkbox
                    CheckboxListTile(
                      title: const Text('TBS/Req'),
                      value: _tbsReq,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _tbsReq = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Don't send Email/SMS Checkbox
                    CheckboxListTile(
                      title: const Text('Don\'t send Email/SMS'),
                      value: _dontSendEmailSms,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _dontSendEmailSms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Send Arrival Time Checkbox
                    CheckboxListTile(
                      title: const Text('Send Arrival Time'),
                      value: _sendArrivalTime,
                      onChanged: _isLoading ? null : _onSendArrivalTimeChanged,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Arrival Time Field (conditional)
                    if (_showArrivalTime) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _arrivalTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Select Arrival Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: _isLoading ? null : () async {
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
                    
                    // Schedule Email & SMS Confirmation Checkbox
                    CheckboxListTile(
                      title: const Text('Schedule Email & SMS Confirmation'),
                      value: _scheduleEmailSms,
                      onChanged: _isLoading ? null : _onScheduleEmailSmsChanged,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Schedule Date and Time Fields (conditional)
                    if (_showScheduleTime) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _scheduleDateController,
                        decoration: const InputDecoration(
                          labelText: 'Select Schedule Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _isLoading ? null : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _scheduleDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            setState(() {
                              _selectedScheduleDate = _scheduleDateController.text;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _scheduleTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Select Schedule Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: _isLoading ? null : () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            _scheduleTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                            setState(() {
                              _selectedScheduleTime = _scheduleTimeController.text;
                            });
                          }
                        },
                      ),
                    ],
                    
                    // Send VDS Email Checkbox
                    CheckboxListTile(
                      title: const Text('Send VDS Email'),
                      value: _sendVdsEmail,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _sendVdsEmail = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    // Stay Available Checkbox
                    CheckboxListTile(
                      title: const Text('Stay Available'),
                      value: _stayAvailable,
                      onChanged: _isLoading ? null : (value) {
                        setState(() {
                          _stayAvailable = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Meeting Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedMeetingType,
                      decoration: const InputDecoration(
                        labelText: 'Select Meeting Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'in_person', child: Text('In Person')),
                        DropdownMenuItem(value: 'zoom', child: Text('Zoom Meeting')),
                      ],
                      onChanged: _isLoading ? null : _onMeetingTypeChanged,
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
                        value: _selectedVenueId, // Use venue ID
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: _venues.map((venue) {
                          return DropdownMenuItem(
                            value: venue['id'],
                            child: Text(venue['name']!),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : (value) {
                          setState(() {
                            _selectedVenueId = value ?? _selectedVenueId;
                            _selectedVenueName = _venues.firstWhere((venue) => venue['id'] == value)['name']!;
                          });
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
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        readOnly: true,
                        initialValue: 'Online Zoom Meeting',
                      ),
                    ],
                    
                    const SizedBox(height: 24),
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
                    onPressed: _isLoading ? null : () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () {
                      _saveReminder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save'),
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