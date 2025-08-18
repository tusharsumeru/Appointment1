import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../action/action.dart';

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

  // Photo upload state
  File? _selectedImageFile;
  bool _isUploadingPhoto = false;
  String? _uploadedPhotoUrl;
  bool _isLoading = false;
  String? _currentUserPhotoUrl; // Store current user's photo URL

  // Log display state for profile picture
  List<String> _photoLogs = [];
  bool _showPhotoLogs = true; // Set to true to show logs on screen

  // Phone number state (same as signup screen)
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';

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

  // Validate role lengths
  void _validateRoles() {
    print('🔍 Validating role lengths...');
    for (final entry in _roleCheckboxes.entries) {
      final length = entry.key.length;
      print('🏷️ Role "${entry.key}": $length characters');
      if (length > 50) {
        print('❌ Role "${entry.key}" exceeds 50 characters!');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print('🚀 ProfileEditScreen.initState() - Starting initialization...');
    print('📋 Received userData: ${widget.userData}');
    _validateRoles(); // Validate role lengths
    _initializeControllers();
    print('✅ ProfileEditScreen.initState() - Initialization completed');
  }

  @override
  void dispose() {
    print('🧹 ProfileEditScreen.dispose() - Cleaning up resources...');
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _locationDebounceTimer?.cancel();
    super.dispose();
    print('✅ ProfileEditScreen.dispose() - Cleanup completed');
  }

  void _initializeControllers() {
    print(
      '🔧 _initializeControllers() - Starting controller initialization...',
    );

    // Initialize full name
    final fullName =
        (widget.userData?['fullName'] ?? widget.userData?['name'] ?? '')
            .toString();
    _fullNameController.text = fullName;
    print('📝 Full Name initialized: "$fullName"');

    // Initialize email
    final email = (widget.userData?['email'] ?? '').toString();
    _emailController.text = email;
    print('📧 Email initialized: "$email"');

    // Phone mapping: supports {countryCode, number} or plain string, and initialize country picker
    final dynamic phoneField =
        widget.userData?['phoneNumber'] ?? widget.userData?['phone'];
    String mappedPhone = '';
    print(
      '📱 Phone field received: $phoneField (type: ${phoneField.runtimeType})',
    );

    if (phoneField is Map) {
      final cc = (phoneField['countryCode'] ?? '').toString();
      final num = (phoneField['number'] ?? '').toString();
      print('📱 Phone is Map - Country Code: "$cc", Number: "$num"');
      if (cc.isNotEmpty) {
        _selectedCountryCode = cc;
        // Try to find matching flag (simplified - you might want to add a mapping)
        if (cc == '+91')
          _selectedCountryFlag = '🇮🇳';
        else if (cc == '+1')
          _selectedCountryFlag = '🇺🇸';
        else if (cc == '+44')
          _selectedCountryFlag = '🇬🇧';
        else
          _selectedCountryFlag = '🇺🇳'; // default
        print(
          '🌍 Country code set to: $_selectedCountryCode with flag: $_selectedCountryFlag',
        );
      }
      mappedPhone = num; // Only the number part goes to the input field
    } else if (phoneField is String) {
      // Try to extract country code from string like "+91 7209657008"
      final phoneStr = phoneField.trim();
      print('📱 Phone is String: "$phoneStr"');
      if (phoneStr.startsWith('+')) {
        final spaceIndex = phoneStr.indexOf(' ');
        if (spaceIndex > 0) {
          final cc = phoneStr.substring(0, spaceIndex);
          final num = phoneStr.substring(spaceIndex + 1);
          _selectedCountryCode = cc;
          if (cc == '+91')
            _selectedCountryFlag = '🇮🇳';
          else if (cc == '+1')
            _selectedCountryFlag = '🇺🇸';
          else if (cc == '+44')
            _selectedCountryFlag = '🇬🇧';
          else
            _selectedCountryFlag = '🇺🇳';
          mappedPhone = num; // Only the number part goes to the input field
          print('🌍 Extracted country code: $cc, number: $num');
        } else {
          // If no space, treat as just country code, leave phone empty
          mappedPhone = '';
          print('⚠️ Phone string has no space, treating as country code only');
        }
      } else {
        // If doesn't start with +, treat as just the number
        mappedPhone = phoneStr;
        print(
          '📱 Phone doesn\'t start with +, treating as number only: "$mappedPhone"',
        );
      }
    }
    _phoneController.text = mappedPhone;
    print('📱 Final phone number set: "$mappedPhone"');

    // Initialize designation
    final designation = (widget.userData?['designation'] ?? '').toString();
    _designationController.text = designation;
    print('💼 Designation initialized: "$designation"');

    // Initialize company
    final company = (widget.userData?['company'] ?? '').toString();
    _companyController.text = company;
    print('🏢 Company initialized: "$company"');

    // Location mapping: prefer full_address.street, fallback to location
    final dynamic fullAddress = widget.userData?['full_address'];
    String mappedLocation = '';
    print(
      '📍 Full address received: $fullAddress (type: ${fullAddress.runtimeType})',
    );

    if (fullAddress is Map) {
      mappedLocation = (fullAddress['street'] ?? '').toString();
      print('📍 Location from full_address.street: "$mappedLocation"');
    }
    if (mappedLocation.isEmpty) {
      mappedLocation = (widget.userData?['location'] ?? '').toString();
      print('📍 Location from location field: "$mappedLocation"');
    }
    _locationController.text = mappedLocation;
    print('📍 Final location set: "$mappedLocation"');

    // Store current user's profile photo URL
    _currentUserPhotoUrl = widget.userData?['profilePhoto'];
    print('🖼️ Current profile photo URL: $_currentUserPhotoUrl');
    _addPhotoLog('🖼️ Current profile photo URL: $_currentUserPhotoUrl');

    // Initialize role checkboxes from current user data if available
    // Backend might return either 'additionalRoles' or 'userTags' - handle both
    final dynamic rolesDynamic = widget.userData != null
        ? (widget.userData!['additionalRoles'] ??
              widget.userData!['userTags'] ??
              widget.userData!['selectedRoles'] ??
              widget.userData!['roles'])
        : null;

    print(
      '🏷️ Roles field received: $rolesDynamic (type: ${rolesDynamic.runtimeType})',
    );
    print(
      '🏷️ additionalRoles from userData: ${widget.userData?['additionalRoles']}',
    );
    print('🏷️ userTags from userData: ${widget.userData?['userTags']}');
    print(
      '🏷️ selectedRoles from userData: ${widget.userData?['selectedRoles']}',
    );
    print('🏷️ roles from userData: ${widget.userData?['roles']}');

    List<String> roles = [];

    if (rolesDynamic is List) {
      roles = rolesDynamic.map((e) => e.toString()).toList();
      print('🏷️ Roles is List: $roles');
    } else if (rolesDynamic is String) {
      try {
        final List<dynamic> parsedRoles = json.decode(rolesDynamic);
        roles = parsedRoles.map((e) => e.toString()).toList();
        print('🏷️ Roles parsed from JSON string: $roles');
      } catch (e) {
        print('❌ Error parsing roles JSON: $e');
      }
    }

    if (roles.isNotEmpty) {
      for (final entry in _roleCheckboxes.entries.toList()) {
        final isSelected = roles.contains(entry.key);
        _roleCheckboxes[entry.key] = isSelected;
        if (isSelected) {
          print('✅ Role selected: ${entry.key}');
        }
      }
    } else {
      print('⚠️ No roles found in user data');
    }

    print(
      '✅ _initializeControllers() - All controllers initialized successfully',
    );
  }

  // Location search (same approach as in signup screen)
  Future<void> _fetchLocations(String query) async {
    print('🔍 _fetchLocations() - Query: "$query"');

    if (query.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingLocations = false;
      });
      print('🔍 Query is empty, clearing suggestions');
      return;
    }

    setState(() {
      _isLoadingLocations = true;
    });

    try {
      print('🌐 Making API call to OpenStreetMap for location suggestions...');
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
        ),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AppointmentApp/1.0',
        },
      );

      print('🌐 Location API response status: ${response.statusCode}');
      print('🌐 Location API response body: ${response.body}');

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
        print('✅ Location suggestions loaded: $suggestions');
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
        print('⚠️ Using fallback location suggestions: $suggestions');
      }
    } catch (e) {
      print('❌ Error fetching locations: $e');
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
      print('⚠️ Using error fallback location suggestions: $suggestions');
    }
  }

  void _onLocationChanged(String value) {
    print('📍 _onLocationChanged() - Value: "$value"');
    _locationDebounceTimer?.cancel();
    _locationDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchLocations(value);
    });
  }

  // Photo upload functions with S3 URL only (no file upload)
  Future<void> _pickImage(ImageSource source) async {
    _addPhotoLog('📸 _pickImage() - Source: $source');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      _addPhotoLog('📸 Image picked: ${pickedFile.path}');
      _addPhotoLog('📸 Image name: ${pickedFile.name}');
      _addPhotoLog('📸 Image size: ${pickedFile.length} bytes');

      // Show uploading state immediately
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      try {
        _addPhotoLog('📤 Starting photo upload to S3...');
        // Upload photo to S3 and get URL
        final result = await ActionService.uploadAndValidateProfilePhoto(
          File(pickedFile.path),
        );
        _addPhotoLog('📤 Upload result: $result');

        if (result['success']) {
          final s3Url =
              result['s3Url'] ??
              result['data']?['s3Url'] ??
              result['data']?['url'];
          setState(() {
            _uploadedPhotoUrl = s3Url;
            _isUploadingPhoto = false;
          });
          _addPhotoLog('✅ Photo uploaded successfully. S3 URL: $s3Url');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isUploadingPhoto = false;
          });
          _addPhotoLog('❌ Photo upload failed: ${result['message']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload photo: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isUploadingPhoto = false;
        });
        _addPhotoLog('❌ Error uploading photo: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _addPhotoLog('⚠️ No image selected');
    }
  }

  void _removeImage() {
    _addPhotoLog('🗑️ _removeImage() - Removing selected image');
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
    _addPhotoLog('✅ Image removed successfully');
  }

  // Helper method to add logs to screen display
  void _addPhotoLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    final logMessage = '[$timestamp] $message';
    print(logMessage); // Console log
    setState(() {
      _photoLogs.add(logMessage);
      // Keep only last 20 logs to prevent memory issues
      if (_photoLogs.length > 20) {
        _photoLogs.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                                        color: Colors.blue.shade700,
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
                                        color: Colors.blue.shade700,
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

                              // Show photo preview (either selected file, uploaded URL, or current user photo)
                              if (_selectedImageFile != null ||
                                  (_uploadedPhotoUrl != null &&
                                      _uploadedPhotoUrl!.isNotEmpty) ||
                                  (_currentUserPhotoUrl != null &&
                                      _currentUserPhotoUrl!.isNotEmpty)) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Photo preview and success message
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              color: Colors.grey[200],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: _selectedImageFile != null
                                                  ? Image.file(
                                                      _selectedImageFile!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 24,
                                                            );
                                                          },
                                                    )
                                                  : _uploadedPhotoUrl != null &&
                                                        _uploadedPhotoUrl!
                                                            .isNotEmpty
                                                  ? Image.network(
                                                      _uploadedPhotoUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 24,
                                                            );
                                                          },
                                                    )
                                                  : _currentUserPhotoUrl !=
                                                            null &&
                                                        _currentUserPhotoUrl!
                                                            .isNotEmpty
                                                  ? Image.network(
                                                      _currentUserPhotoUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                              size: 24,
                                                            );
                                                          },
                                                    )
                                                  : const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 24,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _selectedImageFile != null
                                                      ? 'Photo selected for upload'
                                                      : _uploadedPhotoUrl !=
                                                                null &&
                                                            _uploadedPhotoUrl!
                                                                .isNotEmpty
                                                      ? 'Photo uploaded successfully'
                                                      : 'Current profile photo',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _selectedImageFile != null
                                                      ? 'File: ${_selectedImageFile!.path.split('/').last}'
                                                      : _uploadedPhotoUrl !=
                                                                null &&
                                                            _uploadedPhotoUrl!
                                                                .isNotEmpty
                                                      ? 'S3 URL: ${_uploadedPhotoUrl!.isNotEmpty ? _uploadedPhotoUrl!.substring(0, 30) + '...' : 'N/A'}'
                                                      : 'Current profile photo',
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

                                      const SizedBox(height: 12),

                                      // Action buttons - one below the other
                                      Column(
                                        children: [
                                          // Upload Different Photo
                                          GestureDetector(
                                            onTap: () =>
                                                _pickImage(ImageSource.gallery),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.blue[200]!,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.upload_file,
                                                    color: Colors.blue[700],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Upload Different Photo',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.blue[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          // Take New Photo
                                          GestureDetector(
                                            onTap: () =>
                                                _pickImage(ImageSource.camera),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.orange[200]!,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.orange[700],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Take New Photo',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.orange[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          // Remove Photo
                                          GestureDetector(
                                            onTap: _removeImage,
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.red[200]!,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red[700],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Remove Photo',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
                          _buildFormField('Full Name', _fullNameController),
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

                          _buildPhoneNumberField(),
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
                          ),
                          const SizedBox(height: 16),

                          _buildFormField(
                            'Company/Organization',
                            _companyController,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      color: Colors.deepPurple,
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
                    backgroundColor: Colors.deepPurple,
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
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 20),
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

  Widget _buildFormField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
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
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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

        print(
          '🏷️ Role checkbox tapped: "$role" - Current: $currentValue, New: $newValue',
        );

        setState(() {
          _roleCheckboxes[role] = newValue;
        });

        // Log all selected roles after change
        final selectedRoles = _roleCheckboxes.entries
            .where((entry) => entry.value == true)
            .map((entry) => entry.key)
            .toList();
        print('🏷️ All selected roles after change: $selectedRoles');
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
  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
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
                    print(
                      '🌍 Country selected: ${country.name} (${country.phoneCode}) - Flag: ${country.flagEmoji}',
                    );
                    setState(() {
                      _selectedCountryCode = '+${country.phoneCode}';
                      _selectedCountryFlag = country.flagEmoji;
                    });
                    print(
                      '🌍 Updated country code: $_selectedCountryCode, flag: $_selectedCountryFlag',
                    );
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
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '9876543210',
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
                    borderSide: const BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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

  void _saveChanges() async {
    print('💾 _saveChanges() - Starting profile update process...');

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare phone number with country code
      final fullPhoneNumber =
          '$_selectedCountryCode ${_phoneController.text.trim()}';
      print('📱 Full phone number prepared: "$fullPhoneNumber"');

      // Prepare selected roles
      final selectedRoles = _roleCheckboxes.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
      print('🏷️ Selected roles: $selectedRoles');

      // Validate role lengths before sending
      for (final role in selectedRoles) {
        if (role.length > 50) {
          print('❌ Role "$role" exceeds 50 characters (${role.length} chars)');
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

      // Log all form data being sent
      print('📋 Form data to be sent:');
      print('   - Full Name: "${_fullNameController.text.trim()}"');
      print('   - Email: "${_emailController.text.trim()}"');
      print('   - Phone Number: "$fullPhoneNumber"');
      print('   - Designation: "${_designationController.text.trim()}"');
      print('   - Company: "${_companyController.text.trim()}"');
      print('   - Location: "${_locationController.text.trim()}"');
      print('   - User Tags: $selectedRoles');
      print('   - Profile Photo URL: $_uploadedPhotoUrl');
      _addPhotoLog('💾 Profile photo URL being sent: $_uploadedPhotoUrl');

      // Call ActionService to update profile (S3 URL only, no file upload)
      print('📡 Calling ActionService.updateUserProfile()...');
      print('📡 userTags being sent: $selectedRoles');
      print('📡 userTags type: ${selectedRoles.runtimeType}');
      print('📡 userTags length: ${selectedRoles.length}');

      // Log each role being sent
      for (int i = 0; i < selectedRoles.length; i++) {
        print(
          '📡 userTags[$i]: "${selectedRoles[i]}" (${selectedRoles[i].length} chars)',
        );
      }

      final result = await ActionService.updateUserProfile(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: fullPhoneNumber,
        designation: _designationController.text.trim(),
        company: _companyController.text.trim(),
        full_address: _locationController.text.trim(),
        userTags: selectedRoles,
        profilePhotoUrl: _uploadedPhotoUrl, // S3 URL only
      );

      print('📡 ActionService.updateUserProfile() result: $result');

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Send profile update notification
        await _sendProfileUpdateNotification(result['data']);

        print('✅ Profile update successful!');
        print('📥 Response data: ${result['data']}');
        print('📥 Response message: ${result['message']}');
        _addPhotoLog('✅ Profile update successful!');
        _addPhotoLog('📥 Response data: ${result['data']}');

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
        print('🖼️ Updated profile photo URL: $updatedProfilePhoto');

        // Clear selected file and uploaded URL after successful upload
        setState(() {
          _selectedImageFile = null;
          _uploadedPhotoUrl = null;
        });
        print('🧹 Cleared temporary photo data');

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

        print('📤 Navigating back with updated data: $updatedData');
        Navigator.pop(context, updatedData);
      } else {
        print('❌ Profile update failed!');
        print('📥 Error status code: ${result['statusCode']}');
        print('📥 Error message: ${result['message']}');
        _addPhotoLog('❌ Profile update failed!');
        _addPhotoLog('📥 Error status code: ${result['statusCode']}');
        _addPhotoLog('📥 Error message: ${result['message']}');

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('❌ Exception during profile update: $error');
      print('❌ Error type: ${error.runtimeType}');

      setState(() {
        _isLoading = false;
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
