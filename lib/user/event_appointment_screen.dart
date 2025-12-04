import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../action/action.dart';

class EventAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? eventData; // Optional event data for editing
  
  const EventAppointmentScreen({
    super.key,
    this.eventData,
  });

  @override
  State<EventAppointmentScreen> createState() => _EventAppointmentScreenState();
}

class _EventAppointmentScreenState extends State<EventAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventPlaceController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _fromTimeController = TextEditingController();
  final _toDateController = TextEditingController();
  final _toTimeController = TextEditingController();
  final _detailsController = TextEditingController();
  final _remarksController = TextEditingController();
  final _numberOfPeopleController = TextEditingController();
  
  int _numberOfPeople = 1;
  DateTime? _selectedFromDate;
  TimeOfDay? _selectedFromTime;
  DateTime? _selectedToDate;
  TimeOfDay? _selectedToTime;
  bool _fromDateError = false;
  bool _fromTimeError = false;
  bool _toDateError = false;
  bool _toTimeError = false;
  File? _selectedImage;
  String? _existingImageUrl; // For editing mode - existing image URL
  final ImagePicker _imagePicker = ImagePicker();
  bool get _isEditMode => widget.eventData != null;

  @override
  void initState() {
    super.initState();
    // Initialize number of people controller
    _numberOfPeopleController.text = '1';
    // Pre-fill form if editing
    if (_isEditMode && widget.eventData != null) {
      _loadEventData();
    }
  }

  void _loadEventData() {
    final event = widget.eventData!;
    
    // Fill text fields
    _eventNameController.text = event['eventName']?.toString() ?? '';
    _eventPlaceController.text = event['eventLocation']?.toString() ?? '';
    _detailsController.text = event['eventDescription']?.toString() ?? '';
    _remarksController.text = event['secretaryNotes']?.toString() ?? '';
    _numberOfPeople = event['eventCapacity'] ?? 1;
    _numberOfPeopleController.text = _numberOfPeople.toString();
    
    // Set existing image URL
    _existingImageUrl = event['eventImage']?.toString();
    
    // Parse and set dates (convert from UTC to local time)
    if (event['eventFromDateTime'] != null) {
      try {
        final fromDateTimeUtc = DateTime.parse(event['eventFromDateTime']);
        final fromDateTime = fromDateTimeUtc.toLocal(); // Convert UTC to local time
        _selectedFromDate = fromDateTime;
        _fromDateController.text = _formatDate(fromDateTime);
        _selectedFromTime = TimeOfDay.fromDateTime(fromDateTime);
        _fromTimeController.text = _formatTime(_selectedFromTime!);
      } catch (e) {
        print('Error parsing from date: $e');
      }
    }
    
    if (event['eventToDateTime'] != null) {
      try {
        final toDateTimeUtc = DateTime.parse(event['eventToDateTime']);
        final toDateTime = toDateTimeUtc.toLocal(); // Convert UTC to local time
        _selectedToDate = toDateTime;
        _toDateController.text = _formatDate(toDateTime);
        _selectedToTime = TimeOfDay.fromDateTime(toDateTime);
        _toTimeController.text = _formatTime(_selectedToTime!);
      } catch (e) {
        print('Error parsing to date: $e');
      }
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventPlaceController.dispose();
    _fromDateController.dispose();
    _fromTimeController.dispose();
    _toDateController.dispose();
    _toTimeController.dispose();
    _detailsController.dispose();
    _remarksController.dispose();
    _numberOfPeopleController.dispose();
    super.dispose();
  }

  Future<void> _selectFromDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedFromDate = pickedDate;
        _fromDateController.text = _formatDate(pickedDate);
        _fromDateError = false;
      });
    }
  }

  Future<void> _selectFromTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedFromTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedFromTime = pickedTime;
        _fromTimeController.text = _formatTime(pickedTime);
        _fromTimeError = false;
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedToDate ?? (_selectedFromDate ?? DateTime.now()),
      firstDate: _selectedFromDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedToDate = pickedDate;
        _toDateController.text = _formatDate(pickedDate);
        _toDateError = false;
      });
    }
  }

  Future<void> _selectToTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedToTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedToTime = pickedTime;
        _toTimeController.text = _formatTime(pickedTime);
        _toTimeError = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      if (_selectedImage != null) {
        // If a new image was selected, just clear it (will show existing image in edit mode)
        _selectedImage = null;
      } else if (_isEditMode && _existingImageUrl != null) {
        // If in edit mode and no new image selected, clear the existing image reference
        // This will require user to select a new image
        _existingImageUrl = null;
      }
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _incrementPeople() {
    setState(() {
      _numberOfPeople++;
      _numberOfPeopleController.text = _numberOfPeople.toString();
    });
  }

  void _updateNumberOfPeopleFromController() {
    final text = _numberOfPeopleController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _numberOfPeople = 1;
        _numberOfPeopleController.text = '1';
      });
      return;
    }
    
    final parsedValue = int.tryParse(text);
    if (parsedValue != null && parsedValue >= 1) {
      setState(() {
        _numberOfPeople = parsedValue;
      });
    } else {
      // Invalid input, reset to current value
      setState(() {
        _numberOfPeopleController.text = _numberOfPeople.toString();
      });
    }
  }

  Future<void> _submitForm() async {
    // Validate all form fields first
    final isFormValid = _formKey.currentState!.validate();
    
    // Validate date and time fields
    setState(() {
      _fromDateError = _selectedFromDate == null || _fromDateController.text.isEmpty;
      _fromTimeError = _selectedFromTime == null || _fromTimeController.text.isEmpty;
      _toDateError = _selectedToDate == null || _toDateController.text.isEmpty;
      _toTimeError = _selectedToTime == null || _toTimeController.text.isEmpty;
    });

    // Validate that to date/time is after from date/time
    if (_selectedFromDate != null && _selectedFromTime != null &&
        _selectedToDate != null && _selectedToTime != null) {
      final fromDateTime = DateTime(
        _selectedFromDate!.year,
        _selectedFromDate!.month,
        _selectedFromDate!.day,
        _selectedFromTime!.hour,
        _selectedFromTime!.minute,
      );
      final toDateTime = DateTime(
        _selectedToDate!.year,
        _selectedToDate!.month,
        _selectedToDate!.day,
        _selectedToTime!.hour,
        _selectedToTime!.minute,
      );
      
      if (toDateTime.isBefore(fromDateTime) || toDateTime.isAtSameMomentAs(fromDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date/time must be after start date/time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Update number of people from controller
    _updateNumberOfPeopleFromController();

    // Return if any validation fails
    if (!isFormValid || _fromDateError || _fromTimeError || _toDateError || _toTimeError) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Combine from date and time into ISO format
      final DateTime fromDateTime = DateTime(
        _selectedFromDate!.year,
        _selectedFromDate!.month,
        _selectedFromDate!.day,
        _selectedFromTime!.hour,
        _selectedFromTime!.minute,
      );
      final eventFromDateTime = fromDateTime.toIso8601String();

      // Combine to date and time into ISO format
      final DateTime toDateTime = DateTime(
        _selectedToDate!.year,
        _selectedToDate!.month,
        _selectedToDate!.day,
        _selectedToTime!.hour,
        _selectedToTime!.minute,
      );
      final eventToDateTime = toDateTime.toIso8601String();

      // Call API to create or update event
      final result = _isEditMode
          ? await ActionService.updateEvent(
              eventId: widget.eventData!['eventId']?.toString() ?? '',
              eventName: _eventNameController.text.trim(),
              eventFromDateTime: eventFromDateTime,
              eventToDateTime: eventToDateTime,
              eventLocation: _eventPlaceController.text.trim(),
              eventDescription: _detailsController.text.trim(),
              eventImageFile: _selectedImage, // Optional when editing
              eventCapacity: _numberOfPeople,
              secretaryNotes: _remarksController.text.trim().isNotEmpty
                  ? _remarksController.text.trim()
                  : null,
            )
          : await ActionService.createEvent(
              eventName: _eventNameController.text.trim(),
              eventFromDateTime: eventFromDateTime,
              eventToDateTime: eventToDateTime,
              eventLocation: _eventPlaceController.text.trim(),
              eventDescription: _detailsController.text.trim(),
              eventImageFile: _selectedImage,
              eventCapacity: _numberOfPeople,
              secretaryNotes: _remarksController.text.trim().isNotEmpty
                  ? _remarksController.text.trim()
                  : null,
            );

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 
                  (_isEditMode 
                      ? 'Event updated successfully!' 
                      : 'Event appointment request submitted successfully!')),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate back after successful submission/update
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to submit event request. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Event' : 'Event Appointment Request'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316), // Orange
                Color(0xFFEAB308), // Yellow
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Text(
                        _isEditMode ? 'Edit Event Information' : 'Event Information',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditMode 
                            ? 'Update the details about your event'
                            : 'Fill in the details about your event',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 32),
                  
                  // Form Fields
                  Column(
                    children: [
                      // Event Name
                      _buildTextField(
                        label: 'Event Name',
                        controller: _eventNameController,
                        placeholder: 'Enter event name',
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),
                      
                      // Event Place
                      _buildTextField(
                        label: 'Event Place',
                        controller: _eventPlaceController,
                        placeholder: 'Enter event place',
                        isRequired: true,
                      ),
                      const SizedBox(height: 20),
                      
                      // Event Image
                      _buildImagePickerField(),
                      if (_isEditMode && _existingImageUrl != null && _selectedImage == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Current image will be kept if no new image is selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      
                      // From Date
                      _buildFromDateField(),
                      const SizedBox(height: 20),
                      
                      // From Time
                      _buildFromTimeField(),
                      const SizedBox(height: 20),
                      
                      // To Date
                      _buildToDateField(),
                      const SizedBox(height: 20),
                      
                      // To Time
                      _buildToTimeField(),
                      const SizedBox(height: 20),
                      
                      // Number of People
                      _buildNumberOfPeopleField(),
                      const SizedBox(height: 20),
                      
                      // Details of Events
                      _buildTextArea(
                        label: 'Details of Events',
                        controller: _detailsController,
                        placeholder: 'Provide details about the event',
                        isRequired: true,
                        minHeight: 100,
                      ),
                      const SizedBox(height: 20),
                      
                      // Special Remarks
                      _buildTextArea(
                        label: 'Special Remarks',
                        controller: _remarksController,
                        placeholder: 'Any special remarks or additional information',
                        isRequired: false,
                        minHeight: 80,
                      ),
                    ],
                  ),
                  
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'Update Event' : 'Submit Request',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              if (isRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildImagePickerField() {
    final hasImage = _selectedImage != null || (_existingImageUrl != null && _isEditMode);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(
                hasImage ? Icons.check_circle : Icons.image,
                size: 18,
              ),
              label: Text(hasImage ? 'Image Selected' : 'Choose Image'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                side: BorderSide(
                  color: hasImage ? Colors.green : Colors.grey[300]!,
                  width: hasImage ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: hasImage ? Colors.green : Colors.black87,
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedImage != null 
                      ? 'New image selected'
                      : 'Current image will be used',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : _existingImageUrl != null && _isEditMode
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            _existingImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No image available',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No image selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            // Remove button - only show when there's an image to remove
            if (_selectedImage != null || (_existingImageUrl != null && _isEditMode))
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFromDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: 'From Date '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _selectFromDate();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _fromDateError ? Colors.red : Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fromDateController.text.isEmpty ? 'Select From Date' : _fromDateController.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _fromDateController.text.isEmpty 
                          ? Colors.grey[400] 
                          : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_fromDateError && (_selectedFromDate == null || _fromDateController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFromTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: 'From Time '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _selectFromTime();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _fromTimeError ? Colors.red : Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fromTimeController.text.isEmpty ? 'Select From Time' : _fromTimeController.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _fromTimeController.text.isEmpty 
                          ? Colors.grey[400] 
                          : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_fromTimeError && (_selectedFromTime == null || _fromTimeController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildToDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: 'To Date '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _selectToDate();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _toDateError ? Colors.red : Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _toDateController.text.isEmpty ? 'Select To Date' : _toDateController.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _toDateController.text.isEmpty 
                          ? Colors.grey[400] 
                          : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_toDateError && (_selectedToDate == null || _toDateController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildToTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: 'To Time '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _selectToTime();
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _toTimeError ? Colors.red : Colors.grey[300]!,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _toTimeController.text.isEmpty ? 'Select To Time' : _toTimeController.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _toTimeController.text.isEmpty 
                          ? Colors.grey[400] 
                          : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_toTimeError && (_selectedToTime == null || _toTimeController.text.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'This field is required',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildNumberOfPeopleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: 'Number of People '),
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Minus button
            GestureDetector(
              onTap: () {
                if (_numberOfPeople > 1) {
                  setState(() {
                    _numberOfPeople--;
                    _numberOfPeopleController.text = _numberOfPeople.toString();
                  });
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  Icons.remove,
                  color: _numberOfPeople > 1 ? Colors.black87 : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Number input field
            Expanded(
              child: TextFormField(
                controller: _numberOfPeopleController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  // Update the value as user types
                  final parsedValue = int.tryParse(value);
                  if (parsedValue != null && parsedValue >= 1) {
                    setState(() {
                      _numberOfPeople = parsedValue;
                    });
                  }
                },
                onEditingComplete: () {
                  // Validate and update when user finishes editing
                  _updateNumberOfPeopleFromController();
                  FocusScope.of(context).unfocus();
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter number of people';
                  }
                  final parsedValue = int.tryParse(value.trim());
                  if (parsedValue == null || parsedValue < 1) {
                    return 'Please enter a valid number (minimum 1)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            
            // Plus button
            GestureDetector(
              onTap: _incrementPeople,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF97316)),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool isRequired,
    required double minHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              if (isRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                TextSpan(
                  text: '(Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: null,
          minLines: (minHeight / 20).round(),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

