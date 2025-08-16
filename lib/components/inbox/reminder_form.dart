import 'package:flutter/material.dart';
import '../../action/action.dart';

class ReminderForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSave;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh; // Add refresh callback

  const ReminderForm({
    Key? key,
    required this.appointment,
    this.onSave,
    this.onClose,
    this.onRefresh, // Add refresh callback parameter
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
  bool _tbsReq = false;
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
    
    print('🔍 [ID] Available IDs:');
    print('   📋 appointmentId: $appointmentId');
    print('   🆔 _id: $id');
    
    // FIXED: Use MongoDB _id instead of appointmentId for backend compatibility
    final result = id ?? appointmentId ?? '';
    print('   ✅ Using ID: $result (${id != null ? 'MongoDB _id' : 'appointmentId'})');
    
    return result;
  }

  void _loadVenues() async {
    print('🔄 [VENUE] Starting to load venues...');
    setState(() {
      _isLoadingVenues = true;
      _venueError = null;
    });

    try {
      final result = await ActionService.getAllVenues(
        limit: 100, // Get more venues
      );

      print('📡 [VENUE] API Response received: ${result['success'] ? 'SUCCESS' : 'FAILED'}');

      if (result['success']) {
        final data = result['data'];
        if (data != null && data['venues'] != null) {
          final venuesData = data['venues'] as List<dynamic>;
          setState(() {
            _venueOptions = venuesData.cast<Map<String, dynamic>>();
            _isLoadingVenues = false;
            
            print('✅ [VENUE] Successfully loaded ${_venueOptions.length} venues');
            
            // Debug: Check for duplicate IDs
            final venueIds = _venueOptions.map((v) => v['_id']?.toString()).where((id) => id != null).toList();
            final uniqueIds = venueIds.toSet();
            if (venueIds.length != uniqueIds.length) {
              print('⚠️  [VENUE] WARNING: Duplicate venue IDs found! Total: ${venueIds.length}, Unique: ${uniqueIds.length}');
            }
            
            // Set default venue if venues are available and no venue is selected
            if (_venueOptions.isNotEmpty) {
              // Check if current selected venue exists in loaded venues
              final venueExists = _venueOptions.any((venue) => venue['_id']?.toString() == _selectedVenueId);
              
              if (_selectedVenueId.isEmpty || !venueExists) {
                // Set to first venue if none selected or current selection doesn't exist
              final firstVenue = _venueOptions.first;
              _selectedVenueId = firstVenue['_id']?.toString() ?? '';
              _selectedVenueName = firstVenue['name']?.toString() ?? 'Select a venue';
                print('🎯 [VENUE] Auto-selected first venue: ${_selectedVenueName} (ID: ${_selectedVenueId})');
              } else {
                // Update venue name for existing selection
                final selectedVenue = _venueOptions.firstWhere(
                  (venue) => venue['_id']?.toString() == _selectedVenueId,
                  orElse: () => <String, dynamic>{},
                );
                _selectedVenueName = selectedVenue['name']?.toString() ?? 'Select a venue';
                print('🎯 [VENUE] Updated venue name for existing selection: ${_selectedVenueName}');
              }
            } else {
              print('⚠️  [VENUE] No venues available to select');
            }
          });
        } else {
          print('❌ [VENUE] Invalid venue data structure received');
          setState(() {
            _venueError = 'Invalid venue data structure';
            _isLoadingVenues = false;
            _venueOptions = [];
          });
        }
      } else {
        print('❌ [VENUE] API failed: ${result['message']}');
        setState(() {
          _venueError = result['message'] ?? 'Failed to load venues';
          _isLoadingVenues = false;
          _venueOptions = [];
        });
      }
    } catch (error) {
      print('💥 [VENUE] Network error: $error');
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
    print('🚀 [INIT] ReminderForm initialized');
    print('   📅 Default time: $_selectedTime');
    print('   ⏰ Default arrival time: $_selectedArrivalTime');
    print('   🏢 Default meeting type: $_selectedMeetingType');
    
    _timeController.text = _selectedTime;
    _arrivalTimeController.text = _selectedArrivalTime;
    _loadVenues(); // Load venues from API
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
    print('💾 [SAVE] Starting to save reminder...');
    if (_formKey.currentState!.validate()) {
      print('✅ [SAVE] Form validation passed');
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

        print('📋 [SAVE] Form data prepared:');
        print('   📅 Date: $_selectedDate');
        print('   🕐 Time: $_selectedTime');
        print('   🏢 Meeting Type: $_selectedMeetingType');
        print('   🏛️  Venue: $_selectedVenueName (ID: $_selectedVenueId)');
        print('   ⚙️  Options: $options');

        // Prepare schedule confirmation if enabled
        Map<String, dynamic>? scheduleConfirmation;
        if (_scheduleEmailSms && _selectedScheduleDate.isNotEmpty && _selectedScheduleTime.isNotEmpty) {
          scheduleConfirmation = {
            'date': _selectedScheduleDate,
            'time': _selectedScheduleTime,
          };
          print('   📧 Schedule Confirmation: $scheduleConfirmation');
        }

        print('📡 [SAVE] Calling API to schedule appointment...');
        print('   🔑 Appointment ID: ${_getAppointmentId()}');

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
        
        print('📡 [SAVE] API Response received: ${result['success'] ? 'SUCCESS' : 'FAILED'}');
        
        if (result['success']) {
          print('✅ [SAVE] Appointment scheduled successfully!');
          print('   📝 Message: ${result['message']}');
          
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
          widget.onRefresh?.call(); // Call onRefresh callback
          
          // Close the form
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          print('❌ [SAVE] Failed to schedule appointment');
          print('   📝 Error: ${result['message']}');
          print('   🔢 Status Code: ${result['statusCode']}');
          
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
        print('💥 [SAVE] Unexpected error occurred: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An unexpected error occurred. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        print('🏁 [SAVE] Save operation completed');
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
    print('🔄 [MEETING] Meeting type changed to: $value');
    setState(() {
      _selectedMeetingType = value;
      _showOfflineVenue = _selectedMeetingType == 'in_person';
      _showOnlineVenue = _selectedMeetingType == 'zoom';
    });
    print('   🏢 Show offline venue: $_showOfflineVenue');
    print('   💻 Show online venue: $_showOnlineVenue');
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
                                       print('🎯 [VENUE] User selected venue ID: $value');
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
                                           print('   ⏰ Auto-set time to 18:15 for Satsang backstage');
                                         } else if (_selectedVenueName.toLowerCase().contains('gurukul')) {
                                           _selectedTime = '09:00';
                                           _timeController.text = _selectedTime;
                                           print('   ⏰ Auto-set time to 09:00 for Gurukul');
                                         }
                                       });
                                       print('   🏛️  Selected venue name: $_selectedVenueName');
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