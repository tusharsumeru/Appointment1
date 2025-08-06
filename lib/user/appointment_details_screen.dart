import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../action/action.dart';
import 'user_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> personalInfo;

  const AppointmentDetailsScreen({
    super.key,
    required this.personalInfo,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  // Form controllers
  final TextEditingController _appointmentPurposeController = TextEditingController();
  final TextEditingController _numberOfUsersController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  
  // Reference Information Controllers
  final TextEditingController _referenceNameController = TextEditingController(text: 'Kiran');
  final TextEditingController _referenceEmailController = TextEditingController(text: 'kiran@sumerudigital.com');
  final TextEditingController _referencePhoneController = TextEditingController(text: '97387-41432');
  
  // Guest Information Controllers
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController(text: 'guest@email.com');
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _guestDesignationController = TextEditingController();
  final TextEditingController _guestCompanyController = TextEditingController();
  final TextEditingController _guestLocationController = TextEditingController();
  
  // Form state
  bool _isFormValid = false;
  String? _selectedSecretary;
  String? _selectedAppointmentLocation;
  String? _selectedLocationId; // Store the selected location ID
  PlatformFile? _selectedFile;
  File? _selectedImage;
  bool _isAttendingProgram = false;
  
  // Guest information state
  List<Map<String, TextEditingController>> _guestControllers = [];

  // Location data
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingLocations = true;

  final List<String> _secretaries = [
    'Select a secretary',
    'Secretary 1',
    'Secretary 2',
    'Secretary 3',
  ];

  @override
  void initState() {
    super.initState();
    _validateForm();
    _loadLocations();
  }

  @override
  void dispose() {
    _appointmentPurposeController.dispose();
    _numberOfUsersController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    
    // Dispose reference controllers
    _referenceNameController.dispose();
    _referenceEmailController.dispose();
    _referencePhoneController.dispose();
    
    // Dispose guest controllers
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestDesignationController.dispose();
    _guestCompanyController.dispose();
    _guestLocationController.dispose();
    
    // Dispose guest controllers
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
    }
    super.dispose();
  }

  void _updateGuestControllers() {
    int peopleCount = int.tryParse(_numberOfUsersController.text) ?? 0;
    int guestCount = peopleCount > 1 ? peopleCount - 1 : 0;
    
    // Dispose existing controllers
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
    }
    
    // Create new controllers
    _guestControllers.clear();
    for (int i = 0; i < guestCount; i++) {
      _guestControllers.add({
        'name': TextEditingController(),
        'phone': TextEditingController(text: '+91'),
        'age': TextEditingController(),
      });
    }
    
    setState(() {});
    _validateForm();
  }

  void _validateForm() {
    bool basicFormValid = _appointmentPurposeController.text.isNotEmpty &&
        _numberOfUsersController.text.isNotEmpty &&
        _fromDateController.text.isNotEmpty &&
        _toDateController.text.isNotEmpty;
    
    // Validate guest information if any
    bool guestFormValid = true;
    for (var guest in _guestControllers) {
      if (guest['name']?.text.isEmpty == true ||
          guest['phone']?.text.isEmpty == true ||
          guest['age']?.text.isEmpty == true) {
        guestFormValid = false;
        break;
      }
    }
    
    setState(() {
      _isFormValid = basicFormValid && guestFormValid;
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      _validateForm();
    }
  }

  Future<void> _chooseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        // Check file size (5MB = 5 * 1024 * 1024 bytes)
        const int maxSizeInBytes = 5 * 1024 * 1024; // 5MB
        
        if (file.size > maxSizeInBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedFile = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "${file.name}" selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      print('📸 Image selected: ${pickedFile.path}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo "${pickedFile.name}" ${source == ImageSource.camera ? 'captured' : 'selected'} successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Load ashram locations from API
  Future<void> _loadLocations() async {
    try {
      print('🔄 Loading ashram locations...');
      final result = await ActionService.getAshramLocations();
      
      if (result['success']) {
        final locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
        print('✅ Loaded ${locations.length} locations from API');
        
        setState(() {
          _locations = locations;
          _isLoadingLocations = false;
        });
        
        // Log location details for debugging
        for (var location in locations) {
          print('📍 Location: ${location['name']} (ID: ${location['_id']})');
        }
      } else {
        print('❌ Failed to load locations: ${result['message']}');
        setState(() {
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('❌ Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  void _submitForm() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Collect all form data
      Map<String, dynamic> appointmentData = {
        'meetingType': 'in_person', // Default value
        'appointmentFor': {
          'type': widget.personalInfo['appointmentType'] ?? 'myself',
          'personalInfo': widget.personalInfo,
        },
        'userCurrentCompany': widget.personalInfo['company'] ?? 'Sumeru Digital', // Get from user data
        'userCurrentDesignation': widget.personalInfo['designation'] ?? 'Office Operations Specialist', // Get from user data
        'appointmentPurpose': _appointmentPurposeController.text.trim(),
        'appointmentSubject': _appointmentPurposeController.text.trim(), // Use same value as purpose
        'preferredDateRange': {
          'fromDate': _parseDateToISO(_fromDateController.text),
          'toDate': _parseDateToISO(_toDateController.text),
        },
        'appointmentLocation': _selectedLocationId ?? '6889dbd15b943e342f660060', // Use selected location ID or fallback to static
        'assignedSecretary': '6891a4d3a26a787d5aec5d50', // Static secretary ID
        'numberOfUsers': int.tryParse(_numberOfUsersController.text) ?? 1,
      };

      // Add accompanyUsers if there are additional users
      if (_guestControllers.isNotEmpty) {
        List<Map<String, dynamic>> accompanyUsers = [];
        for (var guest in _guestControllers) {
          accompanyUsers.add({
            'name': guest['name']?.text.trim() ?? '',
            'phone': guest['phone']?.text.trim() ?? '',
            'age': int.tryParse(guest['age']?.text ?? '0') ?? 0,
          });
        }
        appointmentData['accompanyUsers'] = accompanyUsers;
      }

      // Add guest information if appointment type is guest
      if (widget.personalInfo['appointmentType'] == 'guest') {
        appointmentData['guestInformation'] = {
          'name': _guestNameController.text.trim(),
          'email': _guestEmailController.text.trim(),
          'phone': _guestPhoneController.text.trim(),
          'designation': _guestDesignationController.text.trim(),
          'company': _guestCompanyController.text.trim(),
          'location': _guestLocationController.text.trim(),
        };
      }

      // Add reference information if appointment type is guest
      if (widget.personalInfo['appointmentType'] == 'guest') {
        appointmentData['referenceInformation'] = {
          'name': _referenceNameController.text.trim(),
          'email': _referenceEmailController.text.trim(),
          'phone': _referencePhoneController.text.trim(),
        };
      }

      // Add virtual meeting details if applicable
      if (_selectedAppointmentLocation == 'Virtual Meeting') {
        appointmentData['virtualMeetingDetails'] = {
          'platform': 'Zoom', // Default value
          'link': 'To be provided', // Default value
        };
      }

      // Add attending course details if applicable
      if (_isAttendingProgram) {
        appointmentData['attendingCourseDetails'] = {
          'courseName': 'General Program', // Default value
          'duration': '1 day', // Default value
        };
      }

      // Log the date conversion for debugging
      print('📅 Date conversion:');
      print('   - Original from date: ${_fromDateController.text}');
      print('   - Original to date: ${_toDateController.text}');
      print('   - Converted fromDate: ${appointmentData['preferredDateRange']['fromDate']}');
      print('   - Converted toDate: ${appointmentData['preferredDateRange']['toDate']}');

      print('📋 Submitting appointment data:');
      print('   - appointmentType: ${widget.personalInfo['appointmentType']}');
      print('   - purpose: ${_appointmentPurposeController.text}');
      print('   - location: $_selectedAppointmentLocation');
      print('   - locationId: $_selectedLocationId');
      print('   - numberOfUsers: ${_numberOfUsersController.text}');
      print('   - guestControllers count: ${_guestControllers.length}');

      // Call the API
      final result = await ActionService.createAppointment(appointmentData);

      // Hide loading indicator
      Navigator.pop(context);

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Appointment created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back to the main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create appointment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: const SidebarComponent(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome Card for Guest Appointments
                  if (widget.personalInfo['appointmentType'] == 'guest') ...[
                    // Reference Information Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reference Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter the reference details of the person you are requesting the appointment for',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Reference Name
                          _buildReferenceField(
                            label: 'Reference Name',
                            controller: _referenceNameController,
                            placeholder: 'Kiran',
                          ),
                          const SizedBox(height: 12),
                          
                          // Reference Email
                          _buildReferenceField(
                            label: 'Reference Email',
                            controller: _referenceEmailController,
                            placeholder: 'kiran@sumerudigital.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          
                          // Reference Phone
                          _buildReferencePhoneField(
                            label: 'Reference Phone',
                            controller: _referencePhoneController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Guest Information Section
                    const Text(
                      'Guest Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the details of the person you are requesting the appointment for',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Guest Full Name
                    _buildReferenceField(
                      label: 'Full Name of the Guest',
                      controller: _guestNameController,
                      placeholder: 'Enter guest\'s full name',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Email
                    _buildReferenceField(
                      label: 'Email ID of the Guest',
                      controller: _guestEmailController,
                      placeholder: 'guest@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Mobile
                    _buildReferencePhoneField(
                      label: 'Mobile No. of the Guest',
                      controller: _guestPhoneController,
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Designation
                    _buildReferenceField(
                      label: 'Designation',
                      controller: _guestDesignationController,
                      placeholder: 'Guest\'s professional title',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Company/Organization
                    _buildReferenceField(
                      label: 'Company/Organization',
                      controller: _guestCompanyController,
                      placeholder: 'Guest\'s organization name',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Location
                    _buildReferenceField(
                      label: 'Location',
                      controller: _guestLocationController,
                      placeholder: 'Start typing guest\'s location...',
                    ),
                    const SizedBox(height: 24),
                    
                    // Guest Photo Section
                    Row(
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Guest Photo *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required for guests 12+ years old - Divine pic validation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Photo Upload Options
                    Column(
                      children: [
                        // Upload from Device Card
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Upload from Device',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Choose an existing photo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Take Photo Card
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.camera),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue.shade700,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Take Photo',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Use your device camera',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Show selected image preview
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Photo uploaded successfully',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to remove',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Header
                  const Text(
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide details about your requested appointment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                                     const SizedBox(height: 32),

                   // Appointment Purpose
                   _buildTextArea(
                     label: 'Appointment Purpose',
                     controller: _appointmentPurposeController,
                     placeholder: 'Please describe the purpose of your appointment in detail',
                     onChanged: (value) => _validateForm(),
                   ),
                   const SizedBox(height: 20),

                                     // Appointment Location
                   _buildLocationDropdown(),
                  const SizedBox(height: 20),

                  // Secretary Contact
                  _buildDropdownField(
                    label: 'Have you been in touch with any secretary regarding your appointment?',
                    value: _selectedSecretary,
                    items: _secretaries,
                    onChanged: (value) {
                      setState(() {
                        _selectedSecretary = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Number of People
                  _buildTextField(
                    label: 'Number of People',
                    controller: _numberOfUsersController,
                    placeholder: 'Number of people (including yourself)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _updateGuestControllers();
                      _validateForm();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Guest Information Cards
                  if (_guestControllers.isNotEmpty) ...[
                    const Text(
                      'Additional Person Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide details for additional persons',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._guestControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, TextEditingController> guest = entry.value;
                      return _buildGuestCard(index + 1, guest);
                    }).toList(),
                    const SizedBox(height: 20),
                  ],

                  // Attachment
                  _buildFileUpload(),
                  const SizedBox(height: 20),

                  // Date Range Section
                  const Text(
                    'Select your preferred date range *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // From Date
                  _buildDateField(
                    label: 'From Date',
                    controller: _fromDateController,
                    onTap: () => _selectDate(context, _fromDateController),
                  ),
                  const SizedBox(height: 20),

                  // To Date
                  _buildDateField(
                    label: 'To Date',
                    controller: _toDateController,
                    onTap: () => _selectDate(context, _toDateController),
                  ),
                  const SizedBox(height: 20),

                  // Program Attendance Question
                  const Text(
                    'Are you attending any program at the Bangalore Ashram during these dates? *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _isAttendingProgram,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingProgram = value!;
                          });
                        },
                      ),
                      const Text('No'),
                      const SizedBox(width: 32),
                      Radio<bool>(
                        value: true,
                        groupValue: _isAttendingProgram,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingProgram = value!;
                          });
                        },
                      ),
                      const Text('Yes'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    bool hasDropdown = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            suffixIcon: hasDropdown
                ? Icon(Icons.arrow_drop_down, color: Colors.grey[600])
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item == 'Select a secretary' ? null : item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You can attach a project proposal, report, or invitation (Max size: 5MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile != null ? '${_selectedFile!.name} (${_formatFileSize(_selectedFile!.size)})' : 'No file chosen',
                style: TextStyle(
                  color: _selectedFile != null ? Colors.black87 : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            if (_selectedFile != null)
              IconButton(
                onPressed: _removeFile,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'dd-mm-yyyy',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestCard(int guestNumber, Map<String, TextEditingController> guest) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Guest $guestNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Full Name
            _buildGuestTextField(
              label: 'Full Name',
              controller: guest['name']!,
              placeholder: "Enter guest's full name",
              onChanged: (value) => _validateForm(),
            ),
            const SizedBox(height: 16),
            
            // Contact Number
            _buildGuestPhoneField(
              label: 'Contact Number',
              controller: guest['phone']!,
              onChanged: (value) => _validateForm(),
            ),
            const SizedBox(height: 16),
            
            // Age
            _buildGuestTextField(
              label: 'Age',
              controller: guest['age']!,
              placeholder: 'Enter age',
              keyboardType: TextInputType.number,
              onChanged: (value) => _validateForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestPhoneField({
    required String label,
    required TextEditingController controller,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Phone Number Field
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
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
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods for Reference and Guest Information fields
  Widget _buildReferenceField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
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
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildReferencePhoneField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              width: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  const Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Phone Number Field
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  hintStyle: TextStyle(color: Colors.grey[400]),
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
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
          ],
        ),
             ],
     );
   }

   // Build location dropdown with dynamic data from API
   Widget _buildLocationDropdown() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
           'Appointment Location *',
           style: TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w500,
             color: Colors.black87,
           ),
         ),
         const SizedBox(height: 8),
         Container(
           decoration: BoxDecoration(
             border: Border.all(color: Colors.grey[300]!),
             borderRadius: BorderRadius.circular(8),
           ),
           child: _isLoadingLocations
               ? Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                   child: Row(
                     children: [
                       const SizedBox(
                         width: 16,
                         height: 16,
                         child: CircularProgressIndicator(strokeWidth: 2),
                       ),
                       const SizedBox(width: 12),
                       Text(
                         'Loading locations...',
                         style: TextStyle(color: Colors.grey[600]),
                       ),
                     ],
                   ),
                 )
               : DropdownButtonFormField<String>(
                   value: _selectedAppointmentLocation,
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                   ),
                   hint: const Text('Select a location'),
                   items: [
                     const DropdownMenuItem<String>(
                       value: null,
                       child: Text('Select a location'),
                     ),
                     ..._locations.map((location) {
                       return DropdownMenuItem<String>(
                         value: location['name'],
                         child: Text(location['name'] ?? 'Unknown Location'),
                       );
                     }).toList(),
                   ],
                   onChanged: (value) {
                     setState(() {
                       _selectedAppointmentLocation = value;
                       // Find and store the corresponding location ID
                       if (value != null) {
                         final selectedLocation = _locations.firstWhere(
                           (location) => location['name'] == value,
                           orElse: () => {},
                         );
                         _selectedLocationId = selectedLocation['_id'];
                         print('📍 Selected location: $value (ID: $_selectedLocationId)');
                       } else {
                         _selectedLocationId = null;
                       }
                     });
                     _validateForm();
                   },
                   icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                 ),
         ),
       ],
     );
   }

   // Helper method to parse dd-mm-yyyy format to ISO 8601 format
   String _parseDateToISO(String dateString) {
     try {
       // Parse dd-mm-yyyy format
       final parts = dateString.split('-');
       if (parts.length == 3) {
         final day = int.parse(parts[0]);
         final month = int.parse(parts[1]);
         final year = int.parse(parts[2]);
         
         // Create DateTime object
         final date = DateTime(year, month, day);
         
         // Convert to ISO 8601 format with timezone
         return date.toUtc().toIso8601String();
       }
     } catch (e) {
       print('❌ Error parsing date "$dateString": $e');
     }
     
     // Return current date as fallback
     return DateTime.now().toUtc().toIso8601String();
   }
 } 