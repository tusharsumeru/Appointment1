import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../action/action.dart';
import 'verify_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Professional Details Controllers
  final _designationController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();

  // State Variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedTeacherType = 'no';
  Set<String> _selectedRoles = {};
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';

  // Location variables
  List<String> _locationSuggestions = [];
  bool _isLoadingLocations = false;
  Timer? _locationDebounceTimer;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImageFile;
  String? _selectedImagePath;

  // Teacher verification
  final _teacherCodeController = TextEditingController();
  final _teacherEmailController = TextEditingController();
  final _teacherPhoneController = TextEditingController();
  String _teacherCountryCode = '+91';
  String _teacherCountryFlag = '🇮🇳';
  bool _isValidatingTeacher = false;
  bool _isTeacherVerified = false;
  Map<String, dynamic>? _teacherVerificationData;
  String? _teacherVerificationError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _teacherCodeController.dispose();
    _teacherEmailController.dispose();
    _teacherPhoneController.dispose();
    _locationDebounceTimer?.cancel();
    super.dispose();
  }

  // Fetch location suggestions
  Future<void> _fetchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingLocations = false;
      });
      return;
    }

    setState(() {
      _isLoadingLocations = true;
    });

    try {
      // Using OpenStreetMap Nominatim API
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
        ),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AppointmentApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> suggestions = [];

        for (var place in data) {
          final displayName = place['display_name'] as String?;
          if (displayName != null) {
            suggestions.add(displayName);
          }
        }

        setState(() {
          _locationSuggestions = suggestions;
          _isLoadingLocations = false;
        });
      } else {
        // Fallback to mock data if API fails
        final suggestions = [
          '$query, New York, USA',
          '$query, London, UK',
          '$query, Mumbai, India',
          '$query, Sydney, Australia',
          '$query, Toronto, Canada',
        ];

        setState(() {
          _locationSuggestions = suggestions;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      // Fallback to mock data on error
      final suggestions = [
        '$query, New York, USA',
        '$query, London, UK',
        '$query, Mumbai, India',
        '$query, Sydney, Australia',
        '$query, Toronto, Canada',
      ];

      setState(() {
        _locationSuggestions = suggestions;
        _isLoadingLocations = false;
      });
    }
  }

  void _onLocationChanged(String value) {
    // Cancel previous timer
    _locationDebounceTimer?.cancel();

    // Set new timer for debouncing
    _locationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchLocations(value);
    });
  }

  // Pick image from device
  Future<void> _pickImageFromDevice() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Take photo with camera
  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTeacherVerificationBottomSheet() {
    // Clear any previous error when opening the sheet
    setState(() {
      _teacherVerificationError = null;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _buildTeacherVerificationBottomSheet(),
      ),
    );
  }

  Widget _buildTeacherVerificationBottomSheet() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: MediaQuery.of(context).size.height * 0.4,
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
              // Handle bar for drag gesture
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Teacher Verification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Please provide your Art of Living teacher details.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              ),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teacher Code
                      _buildTeacherTextField(
                        controller: _teacherCodeController,
                        label: 'Teacher Code',
                        hint: 'Enter your teacher code',
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      // Teacher Email
                      _buildTeacherTextField(
                        controller: _teacherEmailController,
                        label: 'Registered Email',
                        hint: 'Enter your registered email',
                        keyboardType: TextInputType.emailAddress,
                        isRequired: true,
                      ),
                      const SizedBox(height: 12),

                      // Teacher Phone Number
                      _buildTeacherPhoneField(),
                      const SizedBox(height: 24),

                      // Error Message Display
                      if (_teacherVerificationError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _teacherVerificationError!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isValidatingTeacher
                                  ? null
                                  : () => _handleTeacherVerificationWithModalState(setModalState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isValidatingTeacher
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Verify'),
                            ),
                          ),
                        ],
                      ),
                      // Add extra padding at bottom for keyboard
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeacherTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFF97316), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Registered Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Picker
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    flagSize: 25,
                    backgroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    bottomSheetHeight: 500,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    inputDecoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Start typing to search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color(0xFF8C98A8).withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _teacherCountryCode = '+${country.phoneCode}';
                      _teacherCountryFlag = country.flagEmoji;
                    });
                  },
                );
              },
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _teacherCountryFlag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _teacherCountryCode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: _teacherPhoneController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: 'Enter your phone number',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFF97316), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '', // Hide the character counter
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleTeacherVerification() async {
    // This method is kept for backward compatibility
    _handleTeacherVerificationWithModalState(setState);
  }

  void _handleTeacherVerificationWithModalState(StateSetter setModalState) async {
    // Clear any previous error
    setModalState(() {
      _teacherVerificationError = null;
    });

    // Validate teacher verification fields
    if (_teacherCodeController.text.isEmpty ||
        _teacherEmailController.text.isEmpty ||
        _teacherPhoneController.text.isEmpty) {
      setModalState(() {
        _teacherVerificationError = 'Please fill all required fields';
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_teacherEmailController.text)) {
      setModalState(() {
        _teacherVerificationError = 'Please enter a valid email address';
      });
      return;
    }

    setModalState(() {
      _isValidatingTeacher = true;
      _teacherVerificationError = null;
    });

    try {
      // Prepare teacher phone number
      final teacherPhoneNumber =
          '$_teacherCountryCode ${_teacherPhoneController.text.trim()}';

      // Call AOL teacher validation API
      final result = await ActionService.validateAolTeacher(
        teacherCode: _teacherCodeController.text.trim(),
        teacherEmail: _teacherEmailController.text.trim(),
        teacherPhone: teacherPhoneNumber,
      );

      setModalState(() {
        _isValidatingTeacher = false;
      });

      print('🔍 Teacher verification result: $result');
      print('🔍 Result success: ${result['success']}');
      print('🔍 Result message: ${result['message']}');
      
      if (result['success']) {
        // Validation successful
        Navigator.of(context).pop();

        // Store verification data and update state
        print('🔍 Teacher verification data: ${result['data']}');

        setState(() {
          _selectedTeacherType = _selectedTeacherType == 'part-time'
              ? 'part-time'
              : 'full-time';
          _isTeacherVerified = true;
          _teacherVerificationData = result['data'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? '✅ AOL teacher verified successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Validation failed - show error in the sheet
        // Prioritize details field if it contains more specific information
        String errorMessage;
        if (result['details'] != null && result['details'].toString().isNotEmpty) {
          errorMessage = '${result['details']}Please try with correct teacher code, email, and phone number.';
        } else {
          errorMessage = '${result['message'] ?? 'Teacher validation failed. Please check your details and try again.'}\n\nPlease try with correct teacher code, email, and phone number.';
        }
        
        print('🔍 Setting error message: $errorMessage');
        print('🔍 Result details: ${result['details']}');
        setModalState(() {
          _teacherVerificationError = errorMessage;
        });
        print('🔍 Error message set: $_teacherVerificationError');
      }
    } catch (error) {
      setModalState(() {
        _isValidatingTeacher = false;
        _teacherVerificationError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // Check if profile photo is selected
      if (_selectedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a profile photo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare user data
        final fullPhoneNumber =
            '$_selectedCountryCode ${_phoneController.text.trim()}';

        // Prepare teacher verification data
        String? teacherCode;
        String? teacherEmail;
        String? teacherMobile;

        if (_selectedTeacherType != 'no') {
          teacherCode = _teacherCodeController.text.trim();
          teacherEmail = _teacherEmailController.text.trim();
          teacherMobile =
              '$_teacherCountryCode ${_teacherPhoneController.text.trim()}';
        }

        // Call registration API
        final result = await ActionService.registerUser(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: fullPhoneNumber,
          designation: _designationController.text.trim(),
          company: _companyController.text.trim(),
          full_address: _locationController.text.trim(),
          userTags: _selectedRoles.toList(),
          aol_teacher: _selectedTeacherType != 'no',
          teacher_type: _selectedTeacherType == 'no'
              ? null
              : _selectedTeacherType,
          teachercode: teacherCode,
          teacheremail: teacherEmail,
          mobilenumber: teacherMobile,
          profilePhotoFile: _selectedImageFile!,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          if (result['success']) {
            // Registration successful
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ??
                      'Registration successful! Please check your email for OTP verification.',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to OTP verification screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    VerifyOtpScreen(email: _emailController.text.trim()),
              ),
            );
          } else {
            // Registration failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Registration failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      _buildSectionHeader(
                        'Personal Information',
                        'Enter your basic account information',
                        null,
                      ),
                      const SizedBox(height: 24),

                      // Personal Information Form Fields
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      _buildPasswordField(),
                      const SizedBox(height: 16),

                      _buildPhoneNumberField(),

                      const SizedBox(height: 40),

                      // Professional Details Section
                      _buildSectionHeader(
                        'Professional Details',
                        'Tell us about your professional background',
                        null,
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _designationController,
                        label: 'Designation',
                        hint: 'Your professional title',
                        icon: Icons.badge_outlined,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _companyController,
                        label: 'Company/Organization',
                        hint: 'Your organization',
                        icon: Icons.business_outlined,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),

                      // Teacher Type Selection
                      _buildTeacherTypeSelection(),

                      const SizedBox(height: 40),

                      // Location Section
                      _buildSectionHeader(
                        'Location',
                        'Enter your location',
                        null,
                      ),
                      const SizedBox(height: 24),

                      _buildLocationField(),

                      const SizedBox(height: 40),

                      // Profile Photo Section
                      _buildProfilePhotoSection(),

                      const SizedBox(height: 40),

                      // Additional Roles Section
                      _buildSectionHeader(
                        'Additional Roles',
                        'Select all roles that apply to you',
                        null,
                      ),
                      const SizedBox(height: 24),

                      _buildRolesSelection(),

                      const SizedBox(height: 40),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF97316), Color(0xFFEAB308)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Complete Registration',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
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

  Widget _buildSectionHeader(String title, String subtitle, IconData? icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.grey.shade600, size: 24),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(left: icon != null ? 36 : 0),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isRequired = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (helperText != null) ...[
              const SizedBox(width: 8),
              Text(
                helperText,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade50.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label is required';
            }
            if (keyboardType == TextInputType.emailAddress &&
                value != null &&
                value.isNotEmpty) {
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: _togglePasswordVisibility,
            ),
            filled: true,
            fillColor: Colors.grey.shade50.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Start typing your location...',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                ),
                suffixIcon: _isLoadingLocations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onLocationChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            if (_locationSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _locationSuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        _locationSuggestions[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        setState(() {
                          _locationController.text =
                              _locationSuggestions[index];
                          _locationSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country Code Dropdown with Image
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    flagSize: 25,
                    backgroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    bottomSheetHeight: 500,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    inputDecoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Start typing to search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color(0xFF8C98A8).withOpacity(0.2),
                        ),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _selectedCountryCode = '+${country.phoneCode}';
                      _selectedCountryFlag = country.flagEmoji;
                    });
                  },
                );
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedCountryFlag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCountryCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  hintText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  counterText: '', // Hide the character counter
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show the heading
        const Row(
          children: [
            Text(
              'Are you an Art Of Living teacher?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Show verified teacher data if teacher is verified
        if (_isTeacherVerified && _teacherVerificationData != null)
          _buildVerifiedTeacherDisplay()
        else
          // Show radio buttons for teacher type selection
          Column(
            children: [
              _buildRadioOption(
                value: 'no',
                label: 'No',
                isSelected: _selectedTeacherType == 'no',
                onTap: () => setState(() => _selectedTeacherType = 'no'),
              ),
              const SizedBox(height: 12),
              _buildRadioOption(
                value: 'part-time',
                label: 'Yes - Part-time',
                isSelected: _selectedTeacherType == 'part-time',
                onTap: () =>
                    setState(() => _selectedTeacherType = 'part-time'),
              ),
              const SizedBox(height: 12),
              _buildRadioOption(
                value: 'full-time',
                label: 'Yes - Full-time',
                isSelected: _selectedTeacherType == 'full-time',
                onTap: () =>
                    setState(() => _selectedTeacherType = 'full-time'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVerifiedTeacherDisplay() {
    final teacherDetails =
        _teacherVerificationData?['validationResult']?['apiResponse']?['teacherdetails'] ??
        {};
    final teacherCode = _teacherVerificationData?['teacherCode'] ?? '';
    final teacherType = _selectedTeacherType == 'part-time'
        ? 'Part-time Teacher'
        : 'Full-time Teacher';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with checkmark and title
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Verified',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      teacherType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Teacher details grid
          Column(
            children: [
              _buildTeacherDetailRow('Name:', teacherDetails['name'] ?? 'N/A'),
              _buildTeacherDetailRow('Teacher Code:', teacherCode),
              _buildTeacherDetailRow(
                'Type:',
                teacherDetails['teacher_type'] ?? 'N/A',
              ),
              _buildTeacherDetailRow(
                'Programs:',
                teacherDetails['program_types_can_teach'] ?? 'N/A',
              ),
            ],
          ),

          // Change teacher status button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isTeacherVerified = false;
                _teacherVerificationData = null;
                _selectedTeacherType = 'no';
                // Clear teacher form data
                _teacherCodeController.clear();
                _teacherEmailController.clear();
                _teacherPhoneController.clear();
              });
            },
            child: Text(
              'Change teacher status',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String value,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        // Show teacher verification bottom sheet for part-time and full-time
        if ((value == 'part-time' || value == 'full-time') && !isSelected) {
          _showTeacherVerificationBottomSheet();
        }
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green.shade200 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green.shade500 : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.green.shade500
                      : Colors.grey.shade300,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade50,
                  Colors.white,
                  Colors.grey.shade50.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey.shade400, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildPhotoOption(
                  icon: Icons.upload,
                  title: 'Upload from Device',
                  subtitle: 'Choose an existing photo',
                  onTap: _pickImageFromDevice,
                ),
                const SizedBox(height: 16),
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  title: 'Take Photo',
                  subtitle: 'Use your device camera',
                  onTap: _takePhotoWithCamera,
                ),
                _buildSelectedImageDisplay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade50.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, size: 24, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImageDisplay() {
    if (_selectedImageFile == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(_selectedImageFile!),
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
                  'Profile Photo Selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  _selectedImagePath?.split('/').last ?? 'Image',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedImageFile = null;
                _selectedImagePath = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSelection() {
    final roles = [
      'Ashramite',
      'Ashram Sevak (Short-term)',
      'Swamiji / Brahmachari',
      'Ashram HOD',
      'Trustee',
      'State Apex / STC',
    ];

    return Column(
      children: [
        for (String role in roles)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRoleOption(role),
          ),
      ],
    );
  }

  Widget _buildRoleOption(String role) {
    final isSelected = _selectedRoles.contains(role);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedRoles.remove(role);
          } else {
            _selectedRoles.add(role);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? Colors.green.shade500
                      : Colors.grey.shade300,
                ),
                color: isSelected ? Colors.green.shade500 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
