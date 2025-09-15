import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../action/action.dart';
import '../components/user/photo_validation_bottom_sheet.dart';
import '../utils/phone_validation.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileEditScreen({super.key, required this.userData});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  // Scroll controller for auto-scrolling to missing fields
  final ScrollController _scrollController = ScrollController();
  
  // GlobalKeys for form fields to enable scrolling to them
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _fullNameFieldKey = GlobalKey();
  final GlobalKey _locationFieldKey = GlobalKey();
  final GlobalKey _designationFieldKey = GlobalKey();
  final GlobalKey _companyFieldKey = GlobalKey();
  
  // Error messages for each field
  String? _phoneError;
  String? _fullNameError;
  String? _locationError;
  String? _designationError;
  String? _companyError;

  // Photo upload state
  File? _selectedImageFile;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoUrl;
  bool _isLoading = false;
  String? _currentUserPhotoUrl; // Store current user's photo URL

  // Phone number state (same as signup screen)
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  Country _selectedCountry = Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9876543210',
    displayName: 'India (IN) [+91]',
    displayNameNoCountryCode: 'India (IN)',
    e164Key: '91-IN-0',
  );

  // Location search state (replicated from signup screen)
  List<String> _locationSuggestions = [];
  bool _isLoadingLocations = false;
  Timer? _locationDebounceTimer;

  // Role checkboxes state
  final Map<String, bool> _roleCheckboxes = {
    'Ashramite': false,
    'Ashram Sevak (Short-term)': false,
    'Swamiji / Brahmachari': false,
    'Ashram HOD': false,
    'Trustee': false,
    'State Apex / STC': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _locationDebounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize full name
    final fullName =
        (widget.userData?['fullName'] ?? widget.userData?['name'] ?? '')
            .toString();
    _fullNameController.text = fullName;

    // Initialize email
    final email = (widget.userData?['email'] ?? '').toString();
    _emailController.text = email;

    // Phone mapping: supports {countryCode, number} or plain string, and initialize country picker
    final dynamic phoneField =
        widget.userData?['phoneNumber'] ?? widget.userData?['phone'];
    String mappedPhone = '';

    if (phoneField is Map) {
      final cc = (phoneField['countryCode'] ?? '').toString();
      final num = (phoneField['number'] ?? '').toString();
      if (cc.isNotEmpty) {
        // Handle cases where countryCode might contain both country code and part of number
        if (cc.startsWith('+91') && cc.length > 3) {
          // Extract the actual country code and move extra digits to number
          _selectedCountryCode = '+91';
          final extraDigits = cc.substring(3); // Get digits after +91
          mappedPhone = extraDigits + num; // Combine with existing number
        } else {
          _selectedCountryCode = cc;
          mappedPhone = num; // Only the number part goes to the input field
        }

        // Set flag based on actual country code
        if (_selectedCountryCode == '+91')
          _selectedCountryFlag = '🇮🇳';
        else if (_selectedCountryCode == '+1')
          _selectedCountryFlag = '🇺🇸';
        else if (_selectedCountryCode == '+44')
          _selectedCountryFlag = '🇬🇧';
        else
          _selectedCountryFlag = '🇺🇳'; // default
      } else {
        mappedPhone = num; // Only the number part goes to the input field
      }
    } else if (phoneField is String) {
      // Handle both formats: "+91 7209657008" (with space) and "+919347653480" (combined)
      final phoneStr = phoneField.trim();
      if (phoneStr.startsWith('+')) {
        final spaceIndex = phoneStr.indexOf(' ');
        if (spaceIndex > 0) {
          // Format with space: "+91 7209657008"
          final cc = phoneStr.substring(0, spaceIndex);
          final num = phoneStr.substring(spaceIndex + 1);
          _selectedCountryCode = cc;
          mappedPhone = num;
        } else {
          // Combined format: "+919347653480" - need to extract country code
          if (phoneStr.startsWith('+91') && phoneStr.length > 3) {
            _selectedCountryCode = '+91';
            mappedPhone = phoneStr.substring(3); // Get digits after +91
          } else if (phoneStr.startsWith('+1') && phoneStr.length > 2) {
            _selectedCountryCode = '+1';
            mappedPhone = phoneStr.substring(2); // Get digits after +1
          } else if (phoneStr.startsWith('+44') && phoneStr.length > 3) {
            _selectedCountryCode = '+44';
            mappedPhone = phoneStr.substring(3); // Get digits after +44
          } else {
            // Default case - assume first 3-4 characters are country code
            if (phoneStr.length > 4) {
              _selectedCountryCode = phoneStr.substring(0, 3);
              mappedPhone = phoneStr.substring(3);
            } else {
              _selectedCountryCode = '+91'; // Default to India
              mappedPhone = '';
            }
          }
        }

        // Set flag based on country code
        if (_selectedCountryCode == '+91')
          _selectedCountryFlag = '🇮🇳';
        else if (_selectedCountryCode == '+1')
          _selectedCountryFlag = '🇺🇸';
        else if (_selectedCountryCode == '+44')
          _selectedCountryFlag = '🇬🇧';
        else
          _selectedCountryFlag = '🇺🇳';
      } else {
        // If doesn't start with +, treat as just the number
        mappedPhone = phoneStr;
      }
    }
    _phoneController.text = mappedPhone;

    // Initialize designation
    final designation = (widget.userData?['designation'] ?? '').toString();
    _designationController.text = designation;

    // Initialize company
    final company = (widget.userData?['company'] ?? '').toString();
    _companyController.text = company;

    // Location mapping: prefer full_address.street, fallback to location
    final dynamic fullAddress = widget.userData?['full_address'];
    String mappedLocation = '';

    if (fullAddress is Map) {
      mappedLocation = (fullAddress['street'] ?? '').toString();
    }
    if (mappedLocation.isEmpty) {
      mappedLocation = (widget.userData?['location'] ?? '').toString();
    }
    _locationController.text = mappedLocation;

    // Store current user's profile photo URL
    _currentUserPhotoUrl = widget.userData?['profilePhoto'];

    // Initialize role checkboxes from current user data if available
    // Backend might return either 'additionalRoles' or 'userTags' - handle both
    final dynamic rolesDynamic = widget.userData != null
        ? (widget.userData!['additionalRoles'] ??
              widget.userData!['userTags'] ??
              widget.userData!['selectedRoles'] ??
              widget.userData!['roles'])
        : null;

    List<String> roles = [];

    if (rolesDynamic is List) {
      roles = rolesDynamic.map((e) => e.toString()).toList();
    } else if (rolesDynamic is String) {
      try {
        final List<dynamic> parsedRoles = json.decode(rolesDynamic);
        roles = parsedRoles.map((e) => e.toString()).toList();
      } catch (e) {
        // Error parsing roles JSON
      }
    }

    if (roles.isNotEmpty) {
      for (final entry in _roleCheckboxes.entries.toList()) {
        final isSelected = roles.contains(entry.key);
        _roleCheckboxes[entry.key] = isSelected;
      }
    }
  }

  // Location search (same approach as in signup screen)
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
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
        ),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AppointmentApp/1.0',
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
        final suggestions = <String>[
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
      final suggestions = <String>[
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
    _locationDebounceTimer?.cancel();
    _locationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchLocations(value);
    });
  }

  void _validatePhone(String phoneNumber) {
    final expectedLength = PhoneValidation.getPhoneLengthForCountryObject(_selectedCountry);
    
    if (expectedLength == 0) {
      // No example available, no validation
      setState(() {
        _phoneError = null;
      });
      return;
    }
    
    if (phoneNumber.isEmpty) {
      setState(() {
        _phoneError = null; // Don't show error for empty field
      });
    } else if (phoneNumber.length < expectedLength) {
      setState(() {
        _phoneError = 'Phone number is too short. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else if (phoneNumber.length > expectedLength) {
      setState(() {
        _phoneError = 'Phone number is too long. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else {
      setState(() {
        _phoneError = null; // Valid length
      });
    }
  }

  // Helper method to scroll to a specific field and set error message
  void _scrollToField(GlobalKey fieldKey, String errorMessage, String fieldType) {
    final RenderBox? renderBox = fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final scrollOffset = _scrollController.offset + position.dy - 100; // 100px padding from top
      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      // Set error message for the specific field
      setState(() {
        switch (fieldType) {
          case 'phone':
            _phoneError = errorMessage;
            _fullNameError = null;
            _locationError = null;
            _designationError = null;
            _companyError = null;
            break;
          case 'fullName':
            _phoneError = null;
            _fullNameError = errorMessage;
            _locationError = null;
            _designationError = null;
            _companyError = null;
            break;
          case 'location':
            _phoneError = null;
            _fullNameError = null;
            _locationError = errorMessage;
            _designationError = null;
            _companyError = null;
            break;
          case 'designation':
            _phoneError = null;
            _fullNameError = null;
            _locationError = null;
            _designationError = errorMessage;
            _companyError = null;
            break;
          case 'company':
            _phoneError = null;
            _fullNameError = null;
            _locationError = null;
            _designationError = null;
            _companyError = errorMessage;
            break;
        }
      });
    }
  }

  // Photo upload functions with validation first
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Show uploading state immediately
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      try {
        // Validate photo first using the validation API
        final result = await ActionService.validateProfilePhoto(
          File(pickedFile.path),
        );

        if (result['success']) {
          // Validation successful
          setState(() {
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Photo validated successfully! It will be uploaded when you save changes.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Validation failed - clear the selected file and show error dialog
          setState(() {
            _selectedImageFile = null;
            _isUploadingPhoto = false;
          });

          // Show backend error message in dialog
          final errorMessage =
              result['error'] ?? result['message'] ?? 'Photo validation failed';
          _showPhotoValidationErrorDialog(errorMessage, () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImageFile = null;
              _uploadedPhotoUrl = null;
              _isUploadingPhoto = false;
            });
          });
        }
      } catch (e) {
        // Exception occurred - clear the selected file and show error dialog
        setState(() {
          _selectedImageFile = null;
          _isUploadingPhoto = false;
        });

        // Show error message in dialog
        _showPhotoValidationErrorDialog(
          'Error validating photo: ${e.toString()}',
          () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImageFile = null;
              _uploadedPhotoUrl = null;
              _isUploadingPhoto = false;
            });
          },
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _uploadedPhotoUrl = null;
      _isUploadingPhoto = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(), // Prevent overscroll/stretching
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Profile Photo Section
                    _buildSectionHeader(
                      'Profile Photo',
                      Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Profile Photo Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profile Photo Display
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.lightGreen.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Builder(
                                builder: (context) {
                                  if (_selectedImageFile != null) {
                                    return Image.file(
                                      _selectedImageFile!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.lightGreen.shade50,
                                              child: const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.green,
                                              ),
                                            );
                                          },
                                    );
                                  } else if (_uploadedPhotoUrl != null &&
                                      _uploadedPhotoUrl!.isNotEmpty) {
                                    return Image.network(
                                      _uploadedPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.lightGreen.shade50,
                                              child: const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.green,
                                              ),
                                            );
                                          },
                                    );
                                  } else if (_currentUserPhotoUrl != null &&
                                      _currentUserPhotoUrl!.isNotEmpty) {
                                    return Image.network(
                                      _currentUserPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.lightGreen.shade50,
                                              child: const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.green,
                                              ),
                                            );
                                          },
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.lightGreen.shade50,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Profile Photo Status Text
                          Text(
                            _selectedImageFile != null
                                ? 'New Photo Selected'
                                : _uploadedPhotoUrl != null &&
                                      _uploadedPhotoUrl!.isNotEmpty
                                ? 'Uploaded Profile Photo'
                                : _currentUserPhotoUrl != null &&
                                      _currentUserPhotoUrl!.isNotEmpty
                                ? 'Current Profile Photo'
                                : ' ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            _selectedImageFile != null
                                ? 'Click "Save Changes" to upload'
                                : _uploadedPhotoUrl != null &&
                                      _uploadedPhotoUrl!.isNotEmpty
                                ? 'Successfully uploaded to server'
                                : _currentUserPhotoUrl != null &&
                                      _currentUserPhotoUrl!.isNotEmpty
                                ? 'Your current profile photo'
                                : 'Upload a new profile photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Photo Upload Options
                          Column(
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
                              const SizedBox(height: 12),
                              // Upload from Device Card
                              GestureDetector(
                                onTap: () => _pickImage(ImageSource.gallery),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        color: const Color(0xFFF97316),
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: const Color(0xFFF97316),
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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

                              // Show upload status
                              if (_isUploadingPhoto) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue[600]!,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Uploading and validating photo...',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Please wait',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Teacher Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Teacher Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Your Art of Living teacher status (non-editable)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Question
                          Row(
                            children: [
                              Text(
                                'Are you an Art of Living teacher?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '(Read-only - Contact support to update teacher status)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Teacher Verification Box
                          _buildTeacherVerificationBox(),
                          const SizedBox(height: 16),
                          _buildSupportBox(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personal Information Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 20),

                          // Form Fields
                          _buildFormField('Full Name', _fullNameController, key: _fullNameFieldKey, isRequired: true, errorText: _fullNameError),
                          const SizedBox(height: 16),

                          // Email field (read-only)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                enabled: false, // Make email read-only
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors
                                      .grey
                                      .shade100, // Different color to indicate disabled
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors
                                      .grey
                                      .shade600, // Different text color for disabled
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildPhoneNumberField(key: _phoneFieldKey),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Professional Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Professional Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 20),

                          // Form Fields
                          _buildFormField(
                            'Designation',
                            _designationController,
                            key: _designationFieldKey,
                            isRequired: true,
                            errorText: _designationError,
                          ),
                          const SizedBox(height: 16),

                          _buildFormField(
                            'Company/Organization',
                            _companyController,
                            key: _companyFieldKey,
                            isRequired: true,
                            errorText: _companyError,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          const SizedBox(height: 20),

                          // Form Field
                          // Searchable location field with suggestions (same as signup screen)
                          Column(
                            key: _locationFieldKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    ' *',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
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
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFF97316),
                                    ),
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
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
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
                        if (_locationError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _locationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Roles Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(
                                  Icons.shield_outlined,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Additional Roles',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'Your roles and responsibilities.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Role Checkboxes
                          _buildRoleCheckbox('Ashramite'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Ashram Sevak (Short-term)'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Swamiji / Brahmachari'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Ashram HOD'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Trustee'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('State Apex / STC'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Save Button at Bottom
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Saving...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: const Color(0xFFF97316), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {GlobalKey? key, bool isRequired = false, String? errorText}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? Colors.red : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? Colors.red : const Color(0xFFF97316)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            errorText: errorText,
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCheckbox(String role) {
    return GestureDetector(
      onTap: () {
        final currentValue = _roleCheckboxes[role] ?? false;
        final newValue = !currentValue;

        setState(() {
          _roleCheckboxes[role] = newValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.lightGreen.shade200, width: 1),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _roleCheckboxes[role] == true
                    ? Colors.green
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _roleCheckboxes[role] == true
                      ? Colors.green
                      : Colors.lightGreen.shade300,
                  width: 2,
                ),
              ),
              child: _roleCheckboxes[role] == true
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),

            // Role Text
            Expanded(
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _roleCheckboxes[role] == true
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phone number field with country picker (same as signup screen)
  Widget _buildPhoneNumberField({GlobalKey? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
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
                      _selectedCountry = country;
                      _selectedCountryCode = '+${country.phoneCode}';
                      _selectedCountryFlag = country.flagEmoji;
                      // Clear the phone number field when country changes
                      _phoneController.clear();
                      // Clear phone validation error
                      _phoneError = null;
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
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
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
                maxLength: PhoneValidation.getPhoneLengthForCountryObject(_selectedCountry),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _validatePhone(value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFF97316)),
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
        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Text(
            _phoneError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  void _saveChanges() async {
    // Clear all previous errors
    setState(() {
      _phoneError = null;
      _fullNameError = null;
      _locationError = null;
      _designationError = null;
      _companyError = null;
    });
    
    // Validate required fields and scroll to missing field with specific messages
    if (_phoneController.text.trim().isEmpty) {
      _scrollToField(_phoneFieldKey, 'Please enter your phone number', 'phone');
      return;
    }
    
    if (_fullNameController.text.trim().isEmpty) {
      _scrollToField(_fullNameFieldKey, 'Please enter your full name', 'fullName');
      return;
    }
    
    if (_locationController.text.trim().isEmpty) {
      _scrollToField(_locationFieldKey, 'Please enter your location', 'location');
      return;
    }
    
    if (_designationController.text.trim().isEmpty) {
      _scrollToField(_designationFieldKey, 'Please enter your designation', 'designation');
      return;
    }
    
    if (_companyController.text.trim().isEmpty) {
      _scrollToField(_companyFieldKey, 'Please enter your company/organization name', 'company');
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare phone number with country code
      final fullPhoneNumber =
          '$_selectedCountryCode ${_phoneController.text.trim()}';

      // Prepare selected roles
      final selectedRoles = _roleCheckboxes.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      // Validate role lengths before sending
      for (final role in selectedRoles) {
        if (role.length > 50) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Role "$role" is too long. Maximum 50 characters allowed.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final result = await ActionService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: fullPhoneNumber,
        designation: _designationController.text.trim(),
        company: _companyController.text.trim(),
        full_address: _locationController.text.trim(),
        userTags: selectedRoles,
        profilePhotoUrl: _uploadedPhotoUrl, // Existing S3 URL (if any)
        profilePhotoFile: _selectedImageFile, // New file to upload
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Store the updated profile photo URL before clearing
        final updatedProfilePhoto =
            result['data']?['profilePhoto'] ?? _uploadedPhotoUrl;

        // Clear selected file after successful upload
        setState(() {
          _selectedImageFile = null;
          // Keep _uploadedPhotoUrl as it might be updated from the response
        });

        // Navigate back with updated data
        final updatedData = {
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'phoneNumber': fullPhoneNumber,
          'designation': _designationController.text,
          'company': _companyController.text,
          'location': _locationController.text,
          'selectedRoles': selectedRoles,
          'profilePhoto':
              updatedProfilePhoto, // Use the stored profile photo URL
        };

        Navigator.pop(context, updatedData);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear selected file on error to allow retry
        setState(() {
          _selectedImageFile = null;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Clear selected file on error to allow retry
      setState(() {
        _selectedImageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPhotoValidationErrorDialog(
    String errorMessage,
    VoidCallback onTryAgain,
  ) {
    // Remove "Profile photo validation failed:" prefix if present
    if (errorMessage.startsWith('Profile photo validation failed:')) {
      errorMessage = errorMessage
          .replaceFirst('Profile photo validation failed:', '')
          .trim();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Photo Validation Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please ensure your photo meets our validation requirements',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show photo validation guidance bottom sheet
                PhotoValidationBottomSheet.show(
                  context,
                  onTryAgain: onTryAgain,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View Photo Guidelines',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeacherDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherVerificationBox() {
    // Check if user is an AOL teacher
    final aolTeacherData = widget.userData?['aol_teacher'];
    final atolValidationData = aolTeacherData?['atolValidationData'];
    final aolTeacher = aolTeacherData?['aolTeacher'];

    // Determine international teacher status
    final bool isInternationalTeacher = (aolTeacherData?['isInternational'] == true) ||
        (aolTeacherData?['teacher_type']?.toString().toLowerCase().contains('taol') == true);

    // Check if teacher verification is successful (only for non-international)
    final bool isTeacherVerified = !isInternationalTeacher &&
        (atolValidationData?['verified'] == true || aolTeacher?['isTeacher'] == true);

    // Get teacher details (common)
    final rawTeacherdetails = (atolValidationData?['teacherdetails']) ??
        (atolValidationData?['data']?['teacherdetails']);
    final Map<String, dynamic>? teacherDetails =
        rawTeacherdetails is Map<String, dynamic> ? rawTeacherdetails : null;
    final teacherCode = aolTeacher?['teacherCode'] ?? 'N/A';
    final teacherEmail = aolTeacher?['teacherEmail'] ?? 'N/A';
    // For international teachers, show simplified type
    final String teacherType = isInternationalTeacher 
        ? (aolTeacherData?['teacher_type']?.toString().toLowerCase().contains('total') == true 
            ? 'Total Teacher' 
            : 'Teacher')
        : (aolTeacherData?['teacher_type'] ?? 'N/A');
    final teacherPhoneNumber = aolTeacher?['teacherPhoneNumber'];
    final phoneNumber = teacherPhoneNumber != null
        ? '${teacherPhoneNumber['countryCode']} ${teacherPhoneNumber['number']}'
        : 'N/A';
    final coursesTeaching = aolTeacher?['coursesTeaching'] as List<dynamic>?;
    final programsRaw = (coursesTeaching != null && coursesTeaching.isNotEmpty)
        ? coursesTeaching
        : teacherDetails?['program_types_can_teach'];
    final String programs = programsRaw is List
        ? programsRaw.map((e) => e.toString()).join(', ')
        : (programsRaw?.toString() ?? 'N/A');

    // If international teacher: show details but with Not Verified heading
    if (isInternationalTeacher) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (title + subtitle)
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Information Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Teacher details found but not verified',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details (hide name and phone for international)
            _buildTeacherDetail('Teacher Code', teacherCode),
            const SizedBox(height: 8),
            _buildTeacherDetail('Teacher Email', teacherEmail),
            const SizedBox(height: 8),
            _buildTeacherDetail('Type', teacherType),
            const SizedBox(height: 8),
            _buildTeacherDetail('Programs', programs),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 12),
            Text(
              'Teacher information needs verification. Edit your profile to verify.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!isTeacherVerified) {
      // Show basic not verified message for non-international unverified users
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Stack(
          children: [
            // Read-only indicator
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'READ-ONLY',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher not Verified',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Verified (non-international): show verified header and details
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.lightGreen.shade200, width: 1),
      ),
      child: Stack(
        children: [
          // Read-only indicator
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'READ-ONLY',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verification Header
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Verified',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'AOL Teacher',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Teacher Details (include name/phone for non-international)
                _buildTeacherDetail('Name', teacherDetails?['name'] ?? widget.userData?['fullName'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildTeacherDetail('Type', teacherType),
                const SizedBox(height: 8),
                _buildTeacherDetail('Teacher Code', teacherCode),
                const SizedBox(height: 8),
                _buildTeacherDetail('Teacher Email', teacherEmail),
                const SizedBox(height: 8),
                if (phoneNumber != 'N/A') ...[
                  _buildTeacherDetail('Phone Number', phoneNumber),
                  const SizedBox(height: 8),
                ],
                _buildTeacherDetail(
                  'Programs',
                  programs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If you want to edit this information Please contact support.',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.blue.shade200, height: 1),
          const SizedBox(height: 12),
          Text(
            'Contact Support:',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '📧 Email: support@sumerudigital.com',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📞 Phone: +91-8971227735',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Reach out to us and we'll help you update your teacher status and information.",
            style: TextStyle(
              color: Colors.blue.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Send profile update notification
  Future<void> _sendProfileUpdateNotification(
    Map<String, dynamic>? profileData,
  ) async {
    try {
      // Get current user data from widget
      final userData = widget.userData;
      if (userData == null) {
        print('⚠️ User data not found, skipping profile update notification');
        return;
      }

      final userId =
          userData['_id']?.toString() ??
          userData['userId']?.toString() ??
          userData['id']?.toString();

      if (userId == null) {
        print('⚠️ User ID not found, skipping notification');
        return;
      }

      print('👤 Sending profile update notification for user: $userId');

      // Prepare profile data for notification
      final notificationProfileData = {
        'fullName': profileData?['fullName'] ?? _fullNameController.text,
        'email': profileData?['email'] ?? _emailController.text,
        'phoneNumber':
            profileData?['phoneNumber'] ??
            '$_selectedCountryCode ${_phoneController.text.trim()}',
        'designation':
            profileData?['designation'] ?? _designationController.text,
        'company': profileData?['company'] ?? _companyController.text,
        'location': profileData?['full_address'] ?? _locationController.text,
        'userTags':
            profileData?['userTags'] ??
            _roleCheckboxes.entries
                .where((entry) => entry.value == true)
                .map((entry) => entry.key)
                .toList(),
        'profilePhoto': profileData?['profilePhoto'] ?? _uploadedPhotoUrl,
      };

      // Prepare additional notification data
      final notificationData = {
        'source': 'mobile_app',
        'formType': 'profile_update',
        'userRole': userData['role']?.toString() ?? 'user',
        'timestamp': DateTime.now().toIso8601String(),
        'updateType': 'profile_updated',
      };

      // Send the notification
      final result = await ActionService.sendProfileUpdateNotification(
        userId: userId,
        profileData: notificationProfileData,
        notificationData: notificationData,
      );

      if (result['success']) {
        print('✅ Profile update notification sent successfully');
        print('📱 Notification ID: ${result['data']?['notificationId']}');
      } else {
        print(
          '⚠️ Failed to send profile update notification: ${result['message']}',
        );
        print('🔍 Error details: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error sending profile update notification: $e');
      // Don't block the profile update flow if notification fails
    }
  }
}
