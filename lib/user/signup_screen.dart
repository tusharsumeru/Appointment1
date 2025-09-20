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
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  // Professional Details Controllers
  final _designationController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();

  // State Variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedTeacherType = 'no';
  Set<String> _selectedRoles = {};
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  bool _isFormValid = false;
  
  // Scroll controller for auto-scrolling to errors
  final ScrollController _scrollController = ScrollController();

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
  String _selectedTeacherRegion = 'indian'; // 'indian' or 'international'
  Map<String, dynamic>? _internationalTeacherData; // Store International Teacher data
  String _selectedTeacherEmploymentType = 'full_time'; // 'full_time' or 'part_time'
  
  // International Teacher fields
  final _internationalTeacherCodeController = TextEditingController();
  final _internationalTeacherEmailController = TextEditingController();
  final _internationalTeacherPhoneController = TextEditingController();
  final _internationalTeacherLocationController = TextEditingController();
  final _internationalTeacherTeachController = TextEditingController();
  String _internationalTeacherCountryCode = '+1';
  String _internationalTeacherCountryFlag = '🇺🇸';
  Set<String> _selectedInternationalPrograms = {}; // Store selected programs
  
  // International Teacher location API variables
  List<String> _internationalLocationSuggestions = [];
  bool _isLoadingInternationalLocations = false;
  Timer? _internationalLocationDebounceTimer;
  
  // OTP verification
  final _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _otpError;
  int _otpResendCountdown = 0;
  Timer? _otpTimer;

  @override
  void initState() {
    super.initState();
    
    // Add listeners to text controllers for form validation
    _fullNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _designationController.addListener(_validateForm);
    _companyController.addListener(_validateForm);
    _locationController.addListener(_validateForm);
    
    // Initial form validation
    _validateForm();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _teacherCodeController.dispose();
    _teacherEmailController.dispose();
    _teacherPhoneController.dispose();
    _internationalTeacherCodeController.dispose();
    _internationalTeacherEmailController.dispose();
    _internationalTeacherPhoneController.dispose();
    _internationalTeacherLocationController.dispose();
    _internationalTeacherTeachController.dispose();
    _otpController.dispose();
    _locationDebounceTimer?.cancel();
    _internationalLocationDebounceTimer?.cancel();
    _otpTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Validate form and update button state
  void _validateForm() {
    bool isValid = true;

    // Check required fields
    if (_fullNameController.text.trim().isEmpty) isValid = false;
    if (_emailController.text.trim().isEmpty) isValid = false;
    if (_passwordController.text.isEmpty) isValid = false;
    if (_confirmPasswordController.text.isEmpty) isValid = false;
    if (_phoneController.text.trim().isEmpty) isValid = false;
    if (_designationController.text.trim().isEmpty) isValid = false;
    if (_companyController.text.trim().isEmpty) isValid = false;
    if (_locationController.text.trim().isEmpty) isValid = false;

    // Check if profile photo is selected
    if (_selectedImageFile == null) isValid = false;

    // Check teacher verification if teacher type is 'yes' and region is 'indian'
    if (_selectedTeacherType == 'yes' && _selectedTeacherRegion == 'indian') {
      if (!_isTeacherVerified) isValid = false;
    }

    setState(() {
      _isFormValid = isValid;
    });
  }

  // Scroll to first error field
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Find the first field with error and scroll to it
        if (_fullNameController.text.trim().isEmpty) {
          _scrollToField(0); // Personal Information section
        } else if (_emailController.text.trim().isEmpty || 
                   !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
          _scrollToField(0); // Personal Information section
        } else if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
          _scrollToField(0); // Personal Information section
        } else if (_confirmPasswordController.text.isEmpty || _confirmPasswordController.text != _passwordController.text) {
          _scrollToField(0); // Personal Information section
        } else if (_phoneController.text.trim().isEmpty) {
          _scrollToField(0); // Personal Information section
        } else if (_designationController.text.trim().isEmpty) {
          _scrollToField(1); // Professional Details section
        } else if (_companyController.text.trim().isEmpty) {
          _scrollToField(1); // Professional Details section
        } else if (_locationController.text.trim().isEmpty) {
          _scrollToField(2); // Location section
        } else if (_selectedImageFile == null) {
          _scrollToField(3); // Profile Photo section
        }
      }
    });
  }

  // Scroll to specific section
  void _scrollToField(int sectionIndex) {
    if (_scrollController.hasClients) {
      // Calculate approximate position for each section
      double targetPosition = 0;
      switch (sectionIndex) {
        case 0: // Personal Information
          targetPosition = 0;
          break;
        case 1: // Professional Details
          targetPosition = 400;
          break;
        case 2: // Location
          targetPosition = 600;
          break;
        case 3: // Profile Photo
          targetPosition = 800;
          break;
        case 4: // Additional Roles
          targetPosition = 1000;
          break;
      }
      
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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

  // International Teacher location API methods
  Future<void> _fetchInternationalLocations(String query, [StateSetter? setModalState]) async {
    if (query.isEmpty) {
      if (setModalState != null) {
        setModalState(() {
          _internationalLocationSuggestions = [];
          _isLoadingInternationalLocations = false;
        });
      } else {
        setState(() {
          _internationalLocationSuggestions = [];
          _isLoadingInternationalLocations = false;
        });
      }
      return;
    }

    if (setModalState != null) {
      setModalState(() {
        _isLoadingInternationalLocations = true;
      });
    } else {
      setState(() {
        _isLoadingInternationalLocations = true;
      });
    }

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

        if (setModalState != null) {
          setModalState(() {
            _internationalLocationSuggestions = suggestions;
            _isLoadingInternationalLocations = false;
          });
        } else {
          setState(() {
            _internationalLocationSuggestions = suggestions;
            _isLoadingInternationalLocations = false;
          });
        }
      } else {
        // Fallback to mock data if API fails
        final suggestions = [
          '$query, New York, USA',
          '$query, London, UK',
          '$query, Mumbai, India',
          '$query, Sydney, Australia',
          '$query, Toronto, Canada',
        ];

        if (setModalState != null) {
          setModalState(() {
            _internationalLocationSuggestions = suggestions;
            _isLoadingInternationalLocations = false;
          });
        } else {
          setState(() {
            _internationalLocationSuggestions = suggestions;
            _isLoadingInternationalLocations = false;
          });
        }
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

      if (setModalState != null) {
        setModalState(() {
          _internationalLocationSuggestions = suggestions;
          _isLoadingInternationalLocations = false;
        });
      } else {
        setState(() {
          _internationalLocationSuggestions = suggestions;
          _isLoadingInternationalLocations = false;
        });
      }
    }
  }

  void _onInternationalLocationChanged(String value, [StateSetter? setModalState]) {
    // Cancel previous timer
    _internationalLocationDebounceTimer?.cancel();

    // Set new timer for debouncing
    _internationalLocationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchInternationalLocations(value, setModalState);
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
        _validateForm();
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
        _validateForm();
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
    ).then((_) {
      // When the bottom sheet is closed, check if we need to revert teacher type
      // This handles cases where the user closes the sheet without completing verification
      if (_selectedTeacherType == 'yes' && !_isTeacherVerified) {
        setState(() {
          _selectedTeacherType = 'no';
          _teacherVerificationData = null;
          _teacherVerificationError = null;
          _selectedTeacherRegion = 'indian'; // Reset to default
          _internationalTeacherData = null; // Clear International Teacher data
          _selectedTeacherEmploymentType = 'full_time'; // Reset to default
          // Clear teacher form data since verification wasn't completed
          _teacherCodeController.clear();
          _teacherEmailController.clear();
          _teacherPhoneController.clear();
          _internationalTeacherCodeController.clear();
          _internationalTeacherEmailController.clear();
          _internationalTeacherPhoneController.clear();
          _internationalTeacherLocationController.clear();
          _internationalTeacherTeachController.clear();
          _selectedInternationalPrograms.clear();
          _internationalLocationSuggestions.clear();
        });
        _validateForm();
      }
      
      // Reset OTP verification state when bottom sheet is closed
      _resetOtpVerification();
    });
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
                      onPressed: () {
                        // If teacher type was changed to 'yes' but verification wasn't completed,
                        // revert back to 'no' when closing
                        if (_selectedTeacherType == 'yes' && !_isTeacherVerified) {
                          setState(() {
                            _selectedTeacherType = 'no';
                            // Clear any teacher verification data
                            _teacherVerificationData = null;
                            _teacherVerificationError = null;
                            _selectedTeacherRegion = 'indian'; // Reset to default
                            _internationalTeacherData = null; // Clear International Teacher data
                            _selectedTeacherEmploymentType = 'full_time'; // Reset to default
                            // Clear all teacher form data
                            _teacherCodeController.clear();
                            _teacherEmailController.clear();
                            _teacherPhoneController.clear();
                            _internationalTeacherCodeController.clear();
                            _internationalTeacherEmailController.clear();
                            _internationalTeacherPhoneController.clear();
                            _internationalTeacherLocationController.clear();
                            _internationalTeacherTeachController.clear();
                            _selectedInternationalPrograms.clear();
                _internationalLocationSuggestions.clear();
                            _internationalLocationSuggestions.clear();
                          });
                          _validateForm();
                        }
                        // Reset OTP verification state
                        _resetOtpVerification();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    ),
                  ],
                ),
              ),

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Teacher Region Selection
                      _buildTeacherRegionSelection(setModalState),
                      const SizedBox(height: 24),

                      // Show form fields only for Indian teachers
                      if (_selectedTeacherRegion == 'indian') ...[
                        // Employment Type Selection
                        _buildTeacherEmploymentTypeSelection(setModalState),
                        const SizedBox(height: 12),

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
                      ] else ...[
                        // International Teacher - Form fields
                        // Employment Type Selection
                        _buildTeacherEmploymentTypeSelection(setModalState),
                        const SizedBox(height: 12),

                        // Teacher Code
                        _buildTeacherTextField(
                          controller: _internationalTeacherCodeController,
                          label: 'Teacher Code',
                          hint: 'Enter your teacher code',
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        // Teacher Email
                        _buildTeacherTextField(
                          controller: _internationalTeacherEmailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                        ),
                        const SizedBox(height: 12),

                        // Teacher Phone Number
                        _buildInternationalTeacherPhoneField(),
                        const SizedBox(height: 12),

                        // Location
                        _buildInternationalTeacherLocationField(setModalState),
                        const SizedBox(height: 12),

        // What do you teach? - Program Selection
        _buildInternationalProgramSelection(setModalState),
        const SizedBox(height: 24),
                      ],

                      // OTP Verification Section (shown after initial verification)
                      if (_isOtpSent && !_isTeacherVerified) ...[
                        _buildOtpVerificationSection(),
                        const SizedBox(height: 24),
                      ],


                      // Error Message Display
                      if (_teacherVerificationError != null || _otpError != null) ...[
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
                                  _teacherVerificationError ?? _otpError!,
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
                      _buildActionButtons(setModalState),
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

  Widget _buildTeacherRegionSelection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teacher Region',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTeacherRegionOption(
                value: 'indian',
                label: 'Indian Teacher',
                isSelected: _selectedTeacherRegion == 'indian',
                onTap: () {
                  setModalState(() => _selectedTeacherRegion = 'indian');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeacherRegionOption(
                value: 'international',
                label: 'International Teacher',
                isSelected: _selectedTeacherRegion == 'international',
                onTap: () {
                  setModalState(() => _selectedTeacherRegion = 'international');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherEmploymentTypeSelection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Are you a?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTeacherEmploymentTypeOption(
                value: 'full_time',
                label: 'Full Time',
                isSelected: _selectedTeacherEmploymentType == 'full_time',
                onTap: () {
                  setModalState(() => _selectedTeacherEmploymentType = 'full_time');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTeacherEmploymentTypeOption(
                value: 'part_time',
                label: 'Part Time',
                isSelected: _selectedTeacherEmploymentType == 'part_time',
                onTap: () {
                  setModalState(() => _selectedTeacherEmploymentType = 'part_time');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherRegionOption({
    required String value,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.orange.shade200 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.orange.shade500 : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.orange.shade500
                      : Colors.grey.shade300,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.orange.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherEmploymentTypeOption({
    required String value,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue.shade500 : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade500
                      : Colors.grey.shade300,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.blue.shade800
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildInternationalTeacherPhoneField() {
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
                      _internationalTeacherCountryCode = '+${country.phoneCode}';
                      _internationalTeacherCountryFlag = country.flagEmoji;
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
                      _internationalTeacherCountryFlag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _internationalTeacherCountryCode,
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
                controller: _internationalTeacherPhoneController,
                keyboardType: TextInputType.number,
                maxLength: 15,
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

  Widget _buildInternationalTeacherLocationField([StateSetter? setModalState]) {
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
              controller: _internationalTeacherLocationController,
              decoration: InputDecoration(
                hintText: 'Start typing your location...',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                ),
                suffixIcon: _isLoadingInternationalLocations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _internationalTeacherLocationController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              if (setModalState != null) {
                                setModalState(() {
                                  _internationalTeacherLocationController.clear();
                                  _internationalLocationSuggestions.clear();
                                });
                              } else {
                                setState(() {
                                  _internationalTeacherLocationController.clear();
                                  _internationalLocationSuggestions.clear();
                                });
                              }
                            },
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
                  borderSide: BorderSide(color: Color(0xFFF97316), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _onInternationalLocationChanged(value, setModalState),
            ),
            if (_internationalLocationSuggestions.isNotEmpty)
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
                constraints: const BoxConstraints(
                  maxHeight: 120, // Limit height to show max 3 items
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _internationalLocationSuggestions.length > 3 
                      ? 3 
                      : _internationalLocationSuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        _internationalLocationSuggestions[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        if (setModalState != null) {
                          setModalState(() {
                            _internationalTeacherLocationController.text =
                                _internationalLocationSuggestions[index];
                            _internationalLocationSuggestions = [];
                          });
                        } else {
                          setState(() {
                            _internationalTeacherLocationController.text =
                                _internationalLocationSuggestions[index];
                            _internationalLocationSuggestions = [];
                          });
                        }
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

  Widget _buildInternationalProgramSelection(StateSetter setModalState) {
    final firstRowPrograms = ['HP', 'Silence Program'];
    final secondRowPrograms = ['Sahaj', 'AE/YES!', 'SSY'];
    final fullWidthProgram = 'Higher level Programs - DSN / VTP / TTP / Sanyam';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'What do you teach?',
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
        
        // First row: HP and Silence Program
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildProgramOption(firstRowPrograms[0], setModalState),
            _buildProgramOption(firstRowPrograms[1], setModalState),
          ],
        ),
        const SizedBox(height: 12),
        
        // Second row: Sahaj, AE/YES!, SSY
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildProgramOption(secondRowPrograms[0], setModalState),
            _buildProgramOption(secondRowPrograms[1], setModalState),
            _buildProgramOption(secondRowPrograms[2], setModalState),
          ],
        ),
        const SizedBox(height: 12),
        
        // Full width: Higher level Programs with word wrap
        _buildProgramOptionWithWrap(fullWidthProgram, setModalState),
        
        // Show error message if no programs selected
        if (_selectedInternationalPrograms.isEmpty && _teacherVerificationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select the programs you teach',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgramOption(String program, StateSetter setModalState) {
    final isSelected = _selectedInternationalPrograms.contains(program);

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _selectedInternationalPrograms.remove(program);
        } else {
          _selectedInternationalPrograms.add(program);
        }
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade200 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected ? Colors.green.shade500 : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              program,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.green.shade800
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramOptionWithWrap(String program, StateSetter setModalState) {
    final isSelected = _selectedInternationalPrograms.contains(program);

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          _selectedInternationalPrograms.remove(program);
        } else {
          _selectedInternationalPrograms.add(program);
        }
        setModalState(() {});
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade200 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? Colors.green.shade500
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
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
                program,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpVerificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Enter 6-digit OTP',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // OTP Input Field
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '******',
            hintStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFFF97316), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            counterText: '', // Hide the character counter
          ),
        ),
        const SizedBox(height: 4),

        // OTP sent message
        Text(
          'OTP sent to ${_teacherEmailController.text}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }


  Widget _buildActionButtons(StateSetter setModalState) {
    if (_isTeacherVerified) {
      // Show success state with close button
      return Column(
        children: [
          // Simple success message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Teacher verified successfully!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      );
    } else if (_selectedTeacherRegion == 'international') {
      // Show Cancel and Save buttons for international teachers
      return Row(
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
                  : () => _handleInternationalTeacherVerification(setModalState),
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
                  : const Text('Save'),
            ),
          ),
        ],
      );
    } else if (_isOtpSent) {
      // Show OTP verification buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _resetOtpVerification();
                Navigator.of(context).pop();
              },
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
              onPressed: _isVerifyingOtp
                  ? null
                  : () => _verifyOtpWithModalState(setModalState),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isVerifyingOtp
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
                  : const Text('Verify OTP'),
            ),
          ),
        ],
      );
    } else {
      // Show initial verification buttons
      return Row(
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
      );
    }
  }

  void _handleTeacherVerification() async {
    // This method is kept for backward compatibility
    _handleTeacherVerificationWithModalState(setState);
  }

  void _handleInternationalTeacherVerification(StateSetter setModalState) async {
    // Clear any previous error
    setModalState(() {
      _teacherVerificationError = null;
      _otpError = null;
    });

    // Validate International teacher fields
    if (_internationalTeacherCodeController.text.isEmpty ||
        _internationalTeacherEmailController.text.isEmpty ||
        _internationalTeacherPhoneController.text.isEmpty ||
        _internationalTeacherLocationController.text.isEmpty ||
        _selectedInternationalPrograms.isEmpty) {
      setModalState(() {
        _teacherVerificationError = 'Please fill all required fields and select at least one program';
      });
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_internationalTeacherEmailController.text)) {
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
      // For now, just simulate a successful verification for international teachers
      // In the future, this would call an API for international teacher verification
      await Future.delayed(const Duration(seconds: 2));

      // Store the International Teacher data for display
      final internationalTeacherData = {
        'teacherCode': _internationalTeacherCodeController.text.trim(),
        'email': _internationalTeacherEmailController.text.trim(),
        'phone': '$_internationalTeacherCountryCode ${_internationalTeacherPhoneController.text.trim()}',
        'location': _internationalTeacherLocationController.text.trim(),
        'teach': _selectedInternationalPrograms.join(', '), // Convert selected programs to comma-separated string
        'region': 'International',
        'employmentType': _selectedTeacherEmploymentType == 'full_time' ? 'Full Time' : 'Part Time',
      };

      setModalState(() {
        _isValidatingTeacher = false;
        _isTeacherVerified = true;
        _selectedTeacherType = 'yes';
        _internationalTeacherData = internationalTeacherData;
      });

      // Update main form state
      setState(() {
        _isTeacherVerified = true;
        _selectedTeacherType = 'yes';
        _internationalTeacherData = internationalTeacherData;
      });
      _validateForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ International teacher information saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (error) {
      setModalState(() {
        _isValidatingTeacher = false;
        _teacherVerificationError = 'Failed to save teacher information. Please try again.';
      });
    }
  }

  void _handleTeacherVerificationWithModalState(StateSetter setModalState) async {
    // Clear any previous error
    setModalState(() {
      _teacherVerificationError = null;
      _otpError = null;
    });

    // Validate teacher verification fields based on region
    if (_selectedTeacherRegion == 'indian') {
      // Validate Indian teacher fields
      if (_teacherCodeController.text.isEmpty ||
          _teacherEmailController.text.isEmpty ||
          _teacherPhoneController.text.isEmpty) {
        setModalState(() {
          _teacherVerificationError = 'Please fill all required fields';
        });
        return;
      }
    } else {
      // Validate International teacher fields
      if (_internationalTeacherCodeController.text.isEmpty ||
          _internationalTeacherEmailController.text.isEmpty ||
          _internationalTeacherPhoneController.text.isEmpty ||
          _internationalTeacherLocationController.text.isEmpty ||
          _selectedInternationalPrograms.isEmpty) {
        setModalState(() {
          _teacherVerificationError = 'Please fill all required fields and select at least one program';
        });
        return;
      }
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    String emailToValidate = _selectedTeacherRegion == 'indian' 
        ? _teacherEmailController.text 
        : _internationalTeacherEmailController.text;
    
    if (!emailRegex.hasMatch(emailToValidate)) {
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
        // Teacher credentials are valid, now send OTP
        setModalState(() {
          _teacherVerificationData = result['data'];
        });
        
        // Send OTP to teacher email
        _sendOtpToTeacherWithModalState(setModalState);
      } else {
        // Validation failed - show error in the sheet
        String errorMessage;
        if (result['details'] != null && result['details'].toString().isNotEmpty) {
          errorMessage = '${result['details']}Please try with correct teacher code, email, and phone number.';
        } else {
          errorMessage = '${result['message'] ?? 'Teacher validation failed. Please check your details and try again.'}\n\nPlease try with correct teacher code, email, and phone number.';
        }
        
        setModalState(() {
          _teacherVerificationError = errorMessage;
        });
      }
    } catch (error) {
      setModalState(() {
        _isValidatingTeacher = false;
        _teacherVerificationError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Send OTP to teacher email (with modal state)
  void _sendOtpToTeacherWithModalState(StateSetter setModalState) async {
    setModalState(() {
      _isSendingOtp = true;
      _otpError = null;
    });

    try {
      final result = await ActionService.sendAolTeacherOtpEmail(
        email: _teacherEmailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        purpose: "verification",
      );

      setModalState(() {
        _isSendingOtp = false;
      });

      if (result['success']) {
        setModalState(() {
          _isOtpSent = true;
          _otpResendCountdown = 60; // 60 seconds countdown
        });
        
        // Start countdown timer
        _startOtpCountdown();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setModalState(() {
          _otpError = result['message'] ?? 'Failed to send OTP. Please try again.';
        });
      }
    } catch (error) {
      setModalState(() {
        _isSendingOtp = false;
        _otpError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Send OTP to teacher email (regular state)
  void _sendOtpToTeacher() async {
    setState(() {
      _isSendingOtp = true;
      _otpError = null;
    });

    try {
      final result = await ActionService.sendAolTeacherOtpEmail(
        email: _teacherEmailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        purpose: "verification",
      );

      setState(() {
        _isSendingOtp = false;
      });

      if (result['success']) {
        setState(() {
          _isOtpSent = true;
          _otpResendCountdown = 60; // 60 seconds countdown
        });
        
        // Start countdown timer
        _startOtpCountdown();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP sent successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _otpError = result['message'] ?? 'Failed to send OTP. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _isSendingOtp = false;
        _otpError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Start OTP countdown timer
  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpResendCountdown > 0) {
        setState(() {
          _otpResendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Verify OTP (with modal state)
  void _verifyOtpWithModalState(StateSetter setModalState) async {
    if (_otpController.text.length != 6) {
      setModalState(() {
        _otpError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setModalState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final result = await ActionService.verifyAolTeacherOtp(
        email: _teacherEmailController.text.trim(),
        code: _otpController.text.trim(),
        purpose: "verification",
      );

      setModalState(() {
        _isVerifyingOtp = false;
      });

      if (result['success']) {
        // OTP verified successfully, show success in the same sheet
        setModalState(() {
          _isTeacherVerified = true;
          _selectedTeacherType = 'yes';
        });
        
        // Update main form state
        setState(() {
          _isTeacherVerified = true;
          _selectedTeacherType = 'yes';
        });
        _validateForm();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ AOL teacher verified successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setModalState(() {
          _otpError = result['message'] ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (error) {
      setModalState(() {
        _isVerifyingOtp = false;
        _otpError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Verify OTP (regular state)
  void _verifyOtp() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _otpError = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final result = await ActionService.verifyAolTeacherOtp(
        email: _teacherEmailController.text.trim(),
        code: _otpController.text.trim(),
        purpose: "verification",
      );

      setState(() {
        _isVerifyingOtp = false;
      });

      if (result['success']) {
        // OTP verified successfully, show success
        setState(() {
          _isTeacherVerified = true;
          _selectedTeacherType = 'yes';
        });
        _validateForm();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ AOL teacher verified successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _otpError = result['message'] ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _isVerifyingOtp = false;
        _otpError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Handle teacher verification after OTP is verified
  void _handleTeacherVerificationAfterOtp() async {
    setState(() {
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

      setState(() {
        _isValidatingTeacher = false;
      });

      if (result['success']) {
        // Validation successful
        Navigator.of(context).pop();

        // Store verification data and update state
        setState(() {
          _selectedTeacherType = 'yes';
          _isTeacherVerified = true;
          _teacherVerificationData = result['data'];
        });
        _validateForm();

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
        String errorMessage;
        if (result['details'] != null && result['details'].toString().isNotEmpty) {
          errorMessage = '${result['details']}Please try with correct teacher code, email, and phone number.';
        } else {
          errorMessage = '${result['message'] ?? 'Teacher validation failed. Please check your details and try again.'}\n\nPlease try with correct teacher code, email, and phone number.';
        }
        
        setState(() {
          _teacherVerificationError = errorMessage;
        });
      }
    } catch (error) {
      setState(() {
        _isValidatingTeacher = false;
        _teacherVerificationError = 'Network error. Please check your connection and try again.';
      });
    }
  }

  // Reset OTP verification state
  void _resetOtpVerification() {
    setState(() {
      _isOtpSent = false;
      _otpController.clear();
      _otpError = null;
      _otpResendCountdown = 0;
    });
    _otpTimer?.cancel();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
        _scrollToFirstError();
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

        if (_selectedTeacherType == 'yes') {
          if (_selectedTeacherRegion == 'indian') {
            teacherCode = _teacherCodeController.text.trim();
            teacherEmail = _teacherEmailController.text.trim();
            teacherMobile =
                '$_teacherCountryCode ${_teacherPhoneController.text.trim()}';
          } else {
            // International teacher data
            teacherCode = _internationalTeacherCodeController.text.trim();
            teacherEmail = _internationalTeacherEmailController.text.trim();
            teacherMobile =
                '$_internationalTeacherCountryCode ${_internationalTeacherPhoneController.text.trim()}';
          }
        }



        // Determine programs based on teacher type
        List<String>? programTypesCanTeach;
        if (_selectedTeacherType == 'yes') {
          if (_selectedTeacherRegion == 'international') {
            // For International Teachers, use selected programs
            programTypesCanTeach = _selectedInternationalPrograms.isNotEmpty 
                ? _selectedInternationalPrograms.toList() 
                : null;
          }
          // For Indian Teachers, programs will be handled by the backend API validation
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
          aol_teacher: _selectedTeacherType == 'yes',
          teacher_type: _selectedTeacherType == 'yes'
              ? (_selectedTeacherEmploymentType == 'full_time' ? 'FullTime' : 'PartTime')
              : null,
          teachercode: teacherCode,
          teacheremail: teacherEmail,
          mobilenumber: teacherMobile,
          programTypesCanTeach: programTypesCanTeach,
          isInternational: _selectedTeacherType == 'yes' && _selectedTeacherRegion == 'international',
          teacherEmploymentType: _selectedTeacherType == 'yes' ? _selectedTeacherEmploymentType : null,
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
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
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

                      _buildConfirmPasswordField(),
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
                          onPressed: (_isLoading || !_isFormValid) ? null : _handleSignup,
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
                              gradient: LinearGradient(
                                colors: _isFormValid 
                                  ? [const Color(0xFFF97316), const Color(0xFFEAB308)]
                                  : [Colors.grey.shade400, Colors.grey.shade400],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _isFormValid 
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.transparent,
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
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isFormValid ? 'Complete Registration' : 'Fill All Required Fields',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (_isFormValid) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
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
              // Trigger scroll to this field after validation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToFirstError();
              });
              return '$label is required';
            }
            if (keyboardType == TextInputType.emailAddress &&
                value != null &&
                value.isNotEmpty) {
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                // Trigger scroll to this field after validation
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToFirstError();
                });
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
              // Trigger scroll to this field after validation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToFirstError();
              });
              return 'Password is required';
            }
            if (value.length < 6) {
              // Trigger scroll to this field after validation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToFirstError();
              });
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Confirm Password',
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
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Re-enter your password',
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade600,
              ),
              onPressed: _toggleConfirmPasswordVisibility,
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
              // Trigger scroll to this field after validation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToFirstError();
              });
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              // Trigger scroll to this field after validation
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToFirstError();
              });
              return 'Passwords do not match';
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
                  // Trigger scroll to this field after validation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToFirstError();
                  });
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
                constraints: const BoxConstraints(
                  maxHeight: 120, // Limit height to show max 3 items
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _locationSuggestions.length > 3 
                      ? 3 
                      : _locationSuggestions.length,
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
                    // Trigger scroll to this field after validation
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToFirstError();
                    });
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
    // Ensure teacher type is consistent with verification status
    if (_selectedTeacherType == 'yes' && !_isTeacherVerified) {
      // If teacher type is 'yes' but not verified, reset to 'no'
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedTeacherType = 'no';
          _teacherVerificationData = null;
          _teacherVerificationError = null;
        });
        _validateForm();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show the heading
        const Row(
          children: [
            Text(
              'Are you an Art of Living teacher?',
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
        if (_isTeacherVerified && (_teacherVerificationData != null || _internationalTeacherData != null))
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
                value: 'yes',
                label: 'Yes',
                isSelected: _selectedTeacherType == 'yes',
                onTap: () =>
                    setState(() => _selectedTeacherType = 'yes'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVerifiedTeacherDisplay() {
    // Check if it's Indian or International teacher data
    final isInternational = _internationalTeacherData != null;
    
    if (isInternational) {
      // Display International Teacher data
      final data = _internationalTeacherData!;
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
                        'Teacher Not Verified',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        _selectedTeacherEmploymentType == 'full_time' ? 'Full Time Teacher' : 'Part Time Teacher',
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

            // International Teacher details grid (same as Indian Teacher)
            Column(
              children: [
                _buildTeacherDetailRow('Teacher Code:', data['teacherCode'] ?? 'N/A'),
                _buildTeacherDetailRow('Email:', data['email'] ?? 'N/A'),
                _buildTeacherDetailRow('Phone:', data['phone'] ?? 'N/A'),
                _buildTeacherDetailRow('Programs:', data['teach'] ?? 'N/A'),
              ],
            ),

            // Change teacher status button
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isTeacherVerified = false;
                  _internationalTeacherData = null;
                  _selectedTeacherType = 'no';
                  _selectedTeacherRegion = 'indian'; // Reset to default
                  _selectedTeacherEmploymentType = 'full_time'; // Reset to default
                  // Clear teacher form data
                  _teacherCodeController.clear();
                  _teacherEmailController.clear();
                  _teacherPhoneController.clear();
                  _internationalTeacherCodeController.clear();
                  _internationalTeacherEmailController.clear();
                  _internationalTeacherPhoneController.clear();
                  _internationalTeacherLocationController.clear();
                  _internationalTeacherTeachController.clear();
                _selectedInternationalPrograms.clear();
                _internationalLocationSuggestions.clear();
                });
                _validateForm();
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
    } else {
      // Display Indian Teacher data (existing logic)
      final teacherDetails =
          _teacherVerificationData?['validationResult']?['apiResponse']?['teacherdetails'] ??
          {};
      final teacherCode = _teacherVerificationData?['teacherCode'] ?? '';
      final teacherType = 'Teacher';

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
                        _selectedTeacherEmploymentType == 'full_time' ? 'Full Time Teacher' : 'Part Time Teacher',
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
                  _selectedTeacherRegion = 'indian'; // Reset to default
                  _selectedTeacherEmploymentType = 'full_time'; // Reset to default
                  // Clear teacher form data
                  _teacherCodeController.clear();
                  _teacherEmailController.clear();
                  _teacherPhoneController.clear();
                  _internationalTeacherCodeController.clear();
                  _internationalTeacherEmailController.clear();
                  _internationalTeacherPhoneController.clear();
                  _internationalTeacherLocationController.clear();
                  _internationalTeacherTeachController.clear();
                _selectedInternationalPrograms.clear();
                _internationalLocationSuggestions.clear();
                });
                _validateForm();
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
        // If selecting 'yes', show verification form first
        if (value == 'yes') {
          _showTeacherVerificationBottomSheet();
        } else {
          // If selecting 'no', update immediately
          onTap();
          _validateForm();
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
                // Important notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Important: Kindly upload a recent and clearly recognizable passport size photo to help us with identification and smooth entry during your visit. The appointment / darshan, if confirmed, will be non-transferable.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
              _validateForm();
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
