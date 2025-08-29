import 'package:flutter/material.dart';
import '../../action/action.dart';

class ReminderForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSave;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh; // Add refresh callback
  final bool isFromScheduleScreens; // Add parameter to indicate if from schedule screens

  const ReminderForm({
    Key? key,
    required this.appointment,
    this.onSave,
    this.onClose,
    this.onRefresh, // Add refresh callback parameter
    this.isFromScheduleScreens = false, // Default to false
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
  String _selectedTime = '';
  String _selectedArrivalTime = '';
  String _selectedScheduleDate = '';
  String _selectedScheduleTime = '';
  String _selectedMeetingType = 'in_person'; // Set default to 'in_person'
  String _selectedVenueId = ''; // Will be set from API
  String _selectedVenueName = 'Select a venue';
  
  // Checkbox states
  bool _tbsReq = true;
  bool _dontSendEmailSms = false;
  bool _sendArrivalTime = false;
  bool _scheduleEmailSms = false;
  
  // Visibility states
  bool _showArrivalTime = false;
  bool _showScheduleTime = false;
  bool _showOfflineVenue = true;
  bool _showOnlineVenue = false;
  
  // Loading state
  bool _isLoading = false;

  // Validation message state
  String? _validationMessage;
  bool _showValidationMessage = false;
  bool _isSuccessMessage = false;

  // Venue data from API
  List<Map<String, dynamic>> _venueOptions = [];
  bool _isLoadingVenues = false;
  String? _venueError;

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentId() {
    final appointmentId = widget.appointment['appointmentId']?.toString();
    final id = widget.appointment['_id']?.toString();
    
    // Use MongoDB _id instead of appointmentId for backend compatibility
    final result = id ?? appointmentId ?? '';
    
    return result;
  }

  void _loadVenues() async {
    setState(() {
      _isLoadingVenues = true;
      _venueError = null;
    });

    try {
      final result = await ActionService.getAllVenues(
        limit: 100, // Get more venues
      );

      if (result['success']) {
        final data = result['data'];
        if (data != null && data['venues'] != null) {
          final venuesData = data['venues'] as List<dynamic>;
          setState(() {
            _venueOptions = venuesData.cast<Map<String, dynamic>>();
            _isLoadingVenues = false;
            
            // Set default venue if venues are available and no venue is selected
            if (_venueOptions.isNotEmpty) {
              // Check if current selected venue exists in loaded venues
              final venueExists = _venueOptions.any((venue) => venue['_id']?.toString() == _selectedVenueId);
              
              if (_selectedVenueId.isEmpty || !venueExists) {
                // Try to find Kaveri venue first, otherwise use first venue
                final kaveriVenue = _venueOptions.firstWhere(
                  (venue) => venue['name']?.toString().toLowerCase().contains('kaveri') == true,
                  orElse: () => <String, dynamic>{},
                );
                
                if (kaveriVenue.isNotEmpty) {
                  _selectedVenueId = kaveriVenue['_id']?.toString() ?? '';
                  _selectedVenueName = kaveriVenue['name']?.toString() ?? 'Select a venue';
                } else {
                  // Fallback to first venue if Kaveri not found
                  final firstVenue = _venueOptions.first;
                  _selectedVenueId = firstVenue['_id']?.toString() ?? '';
                  _selectedVenueName = firstVenue['name']?.toString() ?? 'Select a venue';
                }
              } else {
                // Update venue name for existing selection
                final selectedVenue = _venueOptions.firstWhere(
                  (venue) => venue['_id']?.toString() == _selectedVenueId,
                  orElse: () => <String, dynamic>{},
                );
                _selectedVenueName = selectedVenue['name']?.toString() ?? 'Select a venue';
              }
            }
          });
        } else {
          setState(() {
            _venueError = 'Invalid venue data structure';
            _isLoadingVenues = false;
            _venueOptions = [];
          });
        }
      } else {
        setState(() {
          _venueError = result['message'] ?? 'Failed to load venues';
          _isLoadingVenues = false;
          _venueOptions = [];
        });
      }
    } catch (error) {
      setState(() {
        _venueError = 'Network error: ${error.toString()}';
        _isLoadingVenues = false;
        _venueOptions = [];
      });
    }
  }

  String _getSelectedVenueName() {
    // If venues are still loading, show placeholder
    if (_isLoadingVenues) {
      return 'Loading venues...';
    }
    
    // If no venue is selected or venues are empty, show placeholder
    if (_selectedVenueId.isEmpty || _venueOptions.isEmpty) {
      return 'Select a venue';
    }

    try {
      final selectedVenue = _venueOptions.firstWhere(
        (venue) => venue['_id']?.toString() == _selectedVenueId,
        orElse: () => <String, dynamic>{},
      );

      return selectedVenue['name']?.toString() ?? 'Select a venue';
    } catch (e) {
      return 'Select a venue';
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Load existing schedule data if available
    _loadExistingScheduleData();
    
    // Set time to 16:30 when TBS is checked by default (only if no existing time and not from schedule screens)
    if (_tbsReq && _selectedTime.isEmpty && !widget.isFromScheduleScreens) {
      _selectedTime = '16:30';
    }
    
    _timeController.text = _selectedTime;
    _arrivalTimeController.text = _selectedArrivalTime;
    _loadVenues(); // Load venues from API
  }

  // Method to load existing schedule data from appointment
  void _loadExistingScheduleData() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      // Load date
      final existingDate = scheduledDateTime['date']?.toString();
      if (existingDate != null && existingDate.isNotEmpty) {
        // Format the date properly - handle ISO format
        String formattedDate = existingDate;
        try {
          // If it's an ISO date string, parse and format it
          if (existingDate.contains('T') || existingDate.contains('Z')) {
            final dateTime = DateTime.parse(existingDate);
            formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
          }
        } catch (e) {
          // Keep original if parsing fails
          formattedDate = existingDate;
        }
        
        _selectedDate = formattedDate;
        _dateController.text = formattedDate;
      }
      
      // Load time
      final existingTime = scheduledDateTime['time']?.toString();
      if (existingTime != null && existingTime.isNotEmpty) {
        // Format the time properly - handle various time formats
        String formattedTime = existingTime;
        try {
          // If it's an ISO time string, parse and format it
          if (existingTime.contains('T') || existingTime.contains('Z')) {
            final dateTime = DateTime.parse(existingTime);
            formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          } else if (existingTime.contains(':')) {
            // If it's already in HH:MM format, keep it as is
            formattedTime = existingTime;
          } else {
            // Try to parse as a different format
            final dateTime = DateTime.parse(existingTime);
            formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          }
        } catch (e) {
          // Keep original if parsing fails
          formattedTime = existingTime;
        }
        
        _selectedTime = formattedTime;
        _timeController.text = formattedTime;
      }
      
      // Load venue information
      final existingVenue = scheduledDateTime['venue'];
      if (existingVenue != null) {
        if (existingVenue is Map<String, dynamic>) {
          _selectedVenueId = existingVenue['_id']?.toString() ?? '';
          _selectedVenueName = existingVenue['name']?.toString() ?? 'Select a venue';
        } else if (existingVenue is String) {
          _selectedVenueId = existingVenue;
          _selectedVenueName = 'Select a venue'; // Will be updated when venues load
        }
      }
      
      // Load venue label
      final existingVenueLabel = scheduledDateTime['venueLabel']?.toString();
      if (existingVenueLabel != null && existingVenueLabel.isNotEmpty) {
        _selectedVenueName = existingVenueLabel;
      }
      
      // Load meeting type
      final existingMeetingType = scheduledDateTime['meetingType']?.toString();
      if (existingMeetingType != null && existingMeetingType.isNotEmpty) {
        _selectedMeetingType = existingMeetingType;
      }
      
      // Load arrival time if available
      final existingArrivalTime = scheduledDateTime['arrivalTime']?.toString();
      if (existingArrivalTime != null && existingArrivalTime.isNotEmpty) {
        // Format the arrival time properly
        String formattedArrivalTime = existingArrivalTime;
        try {
          // If it's an ISO time string, parse and format it
          if (existingArrivalTime.contains('T') || existingArrivalTime.contains('Z')) {
            final dateTime = DateTime.parse(existingArrivalTime);
            formattedArrivalTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          } else if (existingArrivalTime.contains(':')) {
            // If it's already in HH:MM format, keep it as is
            formattedArrivalTime = existingArrivalTime;
          } else {
            // Try to parse as a different format
            final dateTime = DateTime.parse(existingArrivalTime);
            formattedArrivalTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          }
        } catch (e) {
          // Keep original if parsing fails
          formattedArrivalTime = existingArrivalTime;
        }
        
        _selectedArrivalTime = formattedArrivalTime;
        _arrivalTimeController.text = formattedArrivalTime;
        _sendArrivalTime = true;
        _showArrivalTime = true;
      }
      
      // Load TBS requirement
      final existingTbsRequired = scheduledDateTime['tbsRequired'];
      if (existingTbsRequired != null) {
        _tbsReq = existingTbsRequired == true;
      }
      
      // Load other options
      final existingDontSendNotifications = scheduledDateTime['dontSendNotifications'];
      if (existingDontSendNotifications != null) {
        _dontSendEmailSms = existingDontSendNotifications == true;
      }
      
      final existingScheduleEmailSms = scheduledDateTime['scheduleEmailSmsConfirmation'];
      if (existingScheduleEmailSms != null) {
        _scheduleEmailSms = existingScheduleEmailSms == true;
      }
      
      // Load schedule confirmation data if available
      final existingScheduleConfirmation = scheduledDateTime['scheduleConfirmation'];
      if (existingScheduleConfirmation is Map<String, dynamic>) {
        final scheduleDate = existingScheduleConfirmation['date']?.toString();
        final scheduleTime = existingScheduleConfirmation['time']?.toString();
        
        if (scheduleDate != null && scheduleDate.isNotEmpty) {
          // Format the schedule confirmation date
          String formattedScheduleDate = scheduleDate;
          try {
            if (scheduleDate.contains('T') || scheduleDate.contains('Z')) {
              final dateTime = DateTime.parse(scheduleDate);
              formattedScheduleDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
            }
          } catch (e) {
            formattedScheduleDate = scheduleDate;
          }
          
          _selectedScheduleDate = formattedScheduleDate;
          _scheduleDateController.text = formattedScheduleDate;
        }
        
        if (scheduleTime != null && scheduleTime.isNotEmpty) {
          // Format the schedule confirmation time
          String formattedScheduleTime = scheduleTime;
          try {
            if (scheduleTime.contains('T') || scheduleTime.contains('Z')) {
              final dateTime = DateTime.parse(scheduleTime);
              formattedScheduleTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
            } else if (scheduleTime.contains(':')) {
              formattedScheduleTime = scheduleTime;
            } else {
              final dateTime = DateTime.parse(scheduleTime);
              formattedScheduleTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
            }
          } catch (e) {
            formattedScheduleTime = scheduleTime;
          }
          
          _selectedScheduleTime = formattedScheduleTime;
          _scheduleTimeController.text = formattedScheduleTime;
        }
        
        if (scheduleDate != null && scheduleTime != null) {
          _showScheduleTime = true;
        }
      }
      
      // Update meeting type visibility
      _updateMeetingTypeVisibility();
    }
  }

  // Method to update meeting type visibility based on selected type
  void _updateMeetingTypeVisibility() {
    if (_selectedMeetingType == 'online') {
      _showOfflineVenue = false;
      _showOnlineVenue = true;
    } else {
      _showOfflineVenue = true;
      _showOnlineVenue = false;
    }
  }

  // Method to check if appointment has existing schedule data
  bool _hasExistingSchedule() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    return scheduledDateTime is Map<String, dynamic> && 
           scheduledDateTime['date'] != null && 
           scheduledDateTime['time'] != null;
  }

  // Method to get appropriate save button text
  String _getSaveButtonText() {
    return _hasExistingSchedule() ? 'Update Schedule' : 'Schedule Appointment';
  }

  // Method to show validation message at top of form
  void _displayValidationMessage(String message) {
    setState(() {
      _validationMessage = message;
      _showValidationMessage = true;
      _isSuccessMessage = message.startsWith('✅');
    });
    
    // Auto-hide the message after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showValidationMessage = false;
          _validationMessage = null;
        });
      }
    });
  }

  // Method to validate date and time
  bool _validateDateTime(String date, String time) {
    if (date.isEmpty || time.isEmpty) return true; // Let form validation handle empty fields
    
    try {
      final dateTime = DateTime.parse('$date $time');
      final now = DateTime.now();
      
      if (dateTime.isBefore(now)) {
        _displayValidationMessage('⚠️ Cannot select past date and time. Please choose a future date and time.');
        return false;
      }
      
      return true;
    } catch (e) {
      return true; // Let form validation handle parsing errors
    }
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
          meetingType: _selectedMeetingType, // Now has default value
          venueId: _selectedVenueId, // Use venue ID instead of venue name
          venueLabel: _selectedVenueName, // Pass venue label
          arrivalTime: _sendArrivalTime ? _selectedArrivalTime : null,
          scheduleConfirmation: scheduleConfirmation,
        );
        
        if (result['success']) {
          final actionText = _hasExistingSchedule() ? 'updated' : 'scheduled';
          
          // Show success message internally
          if (mounted) {
            _displayValidationMessage('✅ ${result['message'] ?? 'Appointment $actionText successfully!'}');
          }
          
          // Call onSave callback
          widget.onSave?.call();
          widget.onRefresh?.call(); // Call onRefresh callback
          
          // Close the form after a short delay to show the success message
          if (mounted) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        } else {
          final actionText = _hasExistingSchedule() ? 'update' : 'schedule';
          
          // Show error message internally
          if (mounted) {
            _displayValidationMessage('❌ ${result['message'] ?? 'Failed to $actionText appointment'}');
          }
        }
      } catch (error) {
        if (mounted) {
          _displayValidationMessage('❌ An unexpected error occurred. Please try again.');
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

  void _onMeetingTypeChanged(String value) {
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
                    
                    // Validation Message Display at Top
                    if (_showValidationMessage && _validationMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccessMessage ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isSuccessMessage ? Colors.green[200]! : Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccessMessage ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: _isSuccessMessage ? Colors.green[600] : Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _validationMessage!,
                                style: TextStyle(
                                  color: _isSuccessMessage ? Colors.green[700] : Colors.red[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
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
                          final selectedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          _dateController.text = selectedDate;
                          setState(() {
                            _selectedDate = selectedDate;
                          });
                          
                          // Validate date and time combination
                          if (_selectedTime.isNotEmpty) {
                            _validateDateTime(_selectedDate, _selectedTime);
                          }
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
                          final selectedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          _timeController.text = selectedTime;
                          setState(() {
                            _selectedTime = selectedTime;
                          });
                          
                          // Validate date and time combination
                          if (_selectedDate.isNotEmpty) {
                            _validateDateTime(_selectedDate, _selectedTime);
                          }
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
                          // When TBS/Req is checked, set time to 16:30
                          if (_tbsReq) {
                            _selectedTime = '16:30';
                            _timeController.text = _selectedTime;
                          }
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
                      onChanged: _isLoading ? null : (value) {
                        if (value != null) {
                          _onMeetingTypeChanged(value);
                        }
                      },
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
                       _isLoadingVenues
                           ? const Center(
                               child: Padding(
                                 padding: EdgeInsets.all(16.0),
                                 child: CircularProgressIndicator(),
                               ),
                             )
                           : _venueError != null
                               ? Container(
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(
                                     border: Border.all(color: Colors.red),
                                     borderRadius: BorderRadius.circular(8),
                                   ),
                                   child: Column(
                                     children: [
                                       Text(
                                         'Failed to load venues',
                                         style: TextStyle(color: Colors.red),
                                       ),
                                       TextButton(
                                         onPressed: _loadVenues,
                                         child: Text('Retry'),
                                       ),
                                     ],
                                   ),
                                 )
                               : DropdownButtonFormField<String>(
                                   value: _selectedVenueId.isNotEmpty && _venueOptions.any((venue) => venue['_id']?.toString() == _selectedVenueId) ? _selectedVenueId : null,
                        decoration: const InputDecoration(
                          labelText: 'Select Venue',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                                   ),
                                   items: _venueOptions.where((venue) => 
                                     venue['_id']?.toString().isNotEmpty == true
                                   ).map((venue) {
                                     return DropdownMenuItem(
                                       value: venue['_id']?.toString() ?? '',
                                       child: Text(venue['name']?.toString() ?? 'Unknown Venue'),
                                     );
                                   }).toList(),
                                   onChanged: _isLoading ? null : (value) {
                                     if (value != null) {
                                       setState(() {
                                         _selectedVenueId = value;
                                         final selectedVenue = _venueOptions.firstWhere(
                                           (venue) => venue['_id']?.toString() == value,
                                           orElse: () => <String, dynamic>{},
                                         );
                                         _selectedVenueName = selectedVenue['name']?.toString() ?? 'Select a venue';
                                         
                                         // Set specific times based on venue selection
                                         if (_selectedVenueName.toLowerCase().contains('satsang backstage')) {
                                           _selectedTime = '18:15';
                                           _timeController.text = _selectedTime;
                                         } else if (_selectedVenueName.toLowerCase().contains('gurukul')) {
                                           _selectedTime = '09:00';
                                           _timeController.text = _selectedTime;
                                         }
                                       });
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
                        : Text(_getSaveButtonText()),
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