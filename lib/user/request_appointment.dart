import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import 'user_screen.dart';
import 'appointment_details_screen.dart';
import '../action/storage_service.dart';
import '../action/action.dart';

class RequestAppointmentScreen extends StatefulWidget {
  final String selectedType;

  const RequestAppointmentScreen({super.key, required this.selectedType});

  @override
  State<RequestAppointmentScreen> createState() =>
      _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  String get _appointmentTypeText {
    return widget.selectedType == 'myself' ? 'Myself' : 'Guest';
  }

  String get _appointmentTypeDisplayText {
    return widget.selectedType == 'myself'
        ? 'Request appointment for Myself'
        : 'Request appointment for a Guest';
  }

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  // Form state
  bool _isTeacher = false;
  String? _teacherType; // Add teacher type field
  bool _isFormValid = false;
  bool _isLoading = true; // Add loading state
  String? _teacherCode; // Extracted teacher code to display

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print(
      '🚀 RequestAppointmentScreen._loadUserData() - Starting to load user data...',
    );

    try {
      // First try to get fresh data from API
      print('📡 Calling ActionService.getCurrentUser() to fetch fresh data...');
      final apiResult = await ActionService.getCurrentUser();

      Map<String, dynamic>? userData;

      if (apiResult['success'] == true) {
        print('✅ API call successful, using fresh data');
        userData = apiResult['data'];
      } else {
        print('⚠️ API call failed, falling back to stored data');
        print('📡 Calling StorageService.getUserData()...');
        userData = await StorageService.getUserData();
      }

      print('✅ Data retrieval completed');
      print('📋 Raw userData received: $userData');
      print('📋 userData type: ${userData.runtimeType}');
      print('📋 userData is null: ${userData == null}');

      if (userData != null) {
        print('🔍 Detailed userData analysis:');
        print('   - userData keys: ${userData.keys.toList()}');
        print('   - userData length: ${userData.length}');

        // Log each field individually
        print('📝 Individual field values:');
        print(
          '   - fullName: ${userData['fullName']} (type: ${userData['fullName']?.runtimeType})',
        );
        print(
          '   - name: ${userData['name']} (type: ${userData['name']?.runtimeType})',
        );
        print(
          '   - email: ${userData['email']} (type: ${userData['email']?.runtimeType})',
        );
        print(
          '   - phoneNumber: ${userData['phoneNumber']} (type: ${userData['phoneNumber']?.runtimeType})',
        );
        print(
          '   - phone: ${userData['phone']} (type: ${userData['phone']?.runtimeType})',
        );
        print(
          '   - designation: ${userData['designation']} (type: ${userData['designation']?.runtimeType})',
        );
        print(
          '   - company: ${userData['company']} (type: ${userData['company']?.runtimeType})',
        );
        print(
          '   - location: ${userData['location']} (type: ${userData['location']?.runtimeType})',
        );
        print(
          '   - isTeacher: ${userData['isTeacher']} (type: ${userData['isTeacher']?.runtimeType})',
        );
        print(
          '   - aol_teacher: ${userData['aol_teacher']} (type: ${userData['aol_teacher']?.runtimeType})',
        );

        // Log ALL fields to see what's actually available
        print('🔍 ALL fields in userData:');
        userData.forEach((key, value) {
          print('   - $key: $value (type: ${value.runtimeType})');
        });
      }

      print('🎯 Setting form field values...');

      // Set initial values for form fields with logging
      final fullName = userData?['fullName'] ?? userData?['name'] ?? '';
      final email = userData?['email'] ?? '';

      // Handle phone number object structure
      String phone = '';
      if (userData?['phoneNumber'] != null) {
        if (userData!['phoneNumber'] is Map<String, dynamic>) {
          final phoneObj = userData['phoneNumber'] as Map<String, dynamic>;
          final countryCode = phoneObj['countryCode'] ?? '';
          final number = phoneObj['number'] ?? '';
          phone = '$countryCode$number';
          print('📱 Phone number extracted: $phone (from phoneNumber object)');
        } else {
          phone = userData['phoneNumber'].toString();
          print('📱 Phone number extracted: $phone (from phoneNumber string)');
        }
      } else if (userData?['phone'] != null) {
        phone = userData!['phone'].toString();
        print('📱 Phone number extracted: $phone (from phone field)');
      } else {
        print('📱 No phone number found in user data');
      }

      final designation = userData?['designation'] ?? '';
      final company = userData?['company'] ?? '';

      // Handle teacher status - check atolValidationData.verified field inside aol_teacher (same as profile screen)
      bool isTeacher = false;
      String? teacherType;
      String? teacherCode;

      // Debug prints to show what values are coming in

      final aolTeacherData = userData?['aol_teacher'];
      if (aolTeacherData is Map<String, dynamic>) {
        final atolValidationData = aolTeacherData['atolValidationData'];
        final aolTeacherInner = aolTeacherData['aolTeacher'];
        final teacherTypeStr = aolTeacherData['teacher_type']?.toString();
        // Extract teacher code if present
        if (aolTeacherInner is Map<String, dynamic>) {
          final code = aolTeacherInner['teacherCode']?.toString();
          if (code != null && code.isNotEmpty) {
            teacherCode = code;
          }
        }

        // Determine international teacher
        bool isInternationalTeacher = (aolTeacherData['isInternational'] == true) ||
            (teacherTypeStr != null && teacherTypeStr.toLowerCase().contains('taol'));

        // Verified Indian teacher
        final isVerifiedIndian = (atolValidationData is Map<String, dynamic>) &&
            (atolValidationData['verified'] == true);

        // AOL teacher flag from inner object
        final isAolTeacherInner = (aolTeacherInner is Map<String, dynamic>) &&
            (aolTeacherInner['isTeacher'] == true);

        if (isInternationalTeacher) {
          isTeacher = true; // Show Yes for international teacher
          teacherType = teacherTypeStr ?? 'TAOL Teacher';
          print('👨‍🏫 Teacher status: YES (International teacher)');
        } else if (isVerifiedIndian || isAolTeacherInner) {
          isTeacher = true; // Show Yes for verified or explicit AOL teacher
          teacherType = teacherTypeStr ?? 'Teacher';
          print('👨‍🏫 Teacher status: YES (Verified/Inner AOL teacher)');
        } else {
          isTeacher = false;
          print('👨‍🏫 Teacher status: NO (Not verified and not international)');
        }
      } else {
        isTeacher = false;
        print('👨‍🏫 Teacher status: NO (aol_teacher not found)');
      }

      print('📝 Form field values set:');
      print('   - fullName: $fullName');
      print('   - email: $email');
      print('   - phone: $phone');
      print('   - designation: $designation');
      print('   - company: $company');
      print('   - isTeacher: $isTeacher');

      setState(() {
        _fullNameController.text = fullName;
        _emailController.text = email;
        _phoneController.text = phone;
        _designationController.text = designation;
        _companyController.text = company;
        _isTeacher = isTeacher;
        _teacherType = teacherType;
        _isLoading = false; // Set loading to false after data is loaded
        _teacherCode = teacherCode;
      });

      print(
        '✅ RequestAppointmentScreen._loadUserData() completed successfully',
      );
    } catch (error) {
      print('❌ Error in RequestAppointmentScreen._loadUserData(): $error');
      print('❌ Error type: ${error.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      print('🔄 Setting default values due to error...');

      // Set default values if data loading fails
      setState(() {
        _fullNameController.text = '';
        _emailController.text = '';
        _phoneController.text = '';
        _designationController.text = '';
        _companyController.text = '';
        _isTeacher = false;
        _teacherType = null;
        _isLoading = false; // Ensure loading is false on error
      });

      print('✅ Default values set successfully');
    }
  }

  void _validateForm() {
    setState(() {
      // FIXED: All fields are now optional for testing
      _isFormValid = true; // Always allow navigation for testing
    });
  }

  void _showSuccessAndNavigate() {
    // Navigate to appointment details form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          personalInfo: {
            'fullName': _fullNameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'designation': _designationController.text,
            'company': _companyController.text,
            'isTeacher': _isTeacher,
            'appointmentType': widget.selectedType,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      appBar: AppBar(
        title: Text('$_appointmentTypeText'),
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: const SidebarComponent(),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF97316),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your information...',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const ClampingScrollPhysics(), // Prevent overscroll but allow normal scrolling
              child: Center(
                child: Card(
                  elevation: 4,
                  color: Colors.white, // Set card background to white
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your contact details',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 32),

                        // Appointment Type Display Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.lightGreen.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.lightGreen.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _appointmentTypeDisplayText,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Appointment Type Selected',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        _buildTextField(
                          label: 'Full Name',
                          controller: _fullNameController,
                          placeholder: 'Enter your full name',
                          onChanged: (value) => _validateForm(),
                        ),
                        const SizedBox(height: 20),

                        // Email Address
                        _buildTextField(
                          label: 'Email Address',
                          controller: _emailController,
                          placeholder: 'your@email.com',
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) => _validateForm(),
                        ),
                        const SizedBox(height: 20),

                        // Phone Number
                        _buildPhoneField(),
                        const SizedBox(height: 20),

                        // Designation
                        _buildTextField(
                          label: 'Designation',
                          controller: _designationController,
                          placeholder: 'Your professional title',
                          onChanged: (value) => _validateForm(),
                        ),
                        const SizedBox(height: 20),

                        // Company/Organization
                        _buildTextField(
                          label: 'Company/Organization',
                          controller: _companyController,
                          placeholder: 'Your organization name',
                          onChanged: (value) => _validateForm(),
                        ),
                        const SizedBox(height: 24),

                        // Teacher Question
                        const Text(
                          'Are you an Art Of Living teacher?',
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
                              groupValue: _isTeacher,
                              onChanged: null, // Disable radio buttons
                            ),
                            Text(
                              'No',
                              style: TextStyle(
                                color: _isTeacher
                                    ? Colors.grey[400]
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 32),
                            Radio<bool>(
                              value: true,
                              groupValue: _isTeacher,
                              onChanged: null, // Disable radio buttons
                            ),
                            Text(
                              'Yes',
                              style: TextStyle(
                                color: _isTeacher
                                    ? Colors.black87
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),

                        // Show teacher code if user is a teacher
                        if (_isTeacher && _teacherCode != null && _teacherCode!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.lightGreen.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.lightGreen.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Teacher Code: ${_teacherCode!}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _showSuccessAndNavigate, // FIXED: Always enabled for testing
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Next',
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, // Removed "(Read-only)" text
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
          enabled: false, // Keep read-only functionality
          decoration: InputDecoration(
            hintText: '$placeholder',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor:
                Colors.grey[100], // Keep different color to indicate read-only
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number', // Removed "(Read-only)" text
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: Row(
            children: [
              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _validateForm(),
                  enabled: false, // Keep read-only functionality
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
