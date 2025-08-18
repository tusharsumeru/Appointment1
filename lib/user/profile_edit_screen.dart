import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../action/action.dart';
import '../components/user/photo_validation_bottom_sheet.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileEditScreen({
    super.key,
    required this.userData,
  });

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
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize full name
    final fullName = (widget.userData?['fullName'] ?? widget.userData?['name'] ?? '').toString();
    _fullNameController.text = fullName;

    // Initialize email
    final email = (widget.userData?['email'] ?? '').toString();
    _emailController.text = email;

    // Phone mapping: supports {countryCode, number} or plain string, and initialize country picker
    final dynamic phoneField = widget.userData?['phoneNumber'] ?? widget.userData?['phone'];
    String mappedPhone = '';
    
    if (phoneField is Map) {
      final cc = (phoneField['countryCode'] ?? '').toString();
      final num = (phoneField['number'] ?? '').toString();
      if (cc.isNotEmpty) {
        _selectedCountryCode = cc;
        // Try to find matching flag (simplified - you might want to add a mapping)
        if (cc == '+91') _selectedCountryFlag = '🇮🇳';
        else if (cc == '+1') _selectedCountryFlag = '🇺🇸';
        else if (cc == '+44') _selectedCountryFlag = '🇬🇧';
        else _selectedCountryFlag = '🇺🇳'; // default
      }
      mappedPhone = num; // Only the number part goes to the input field
    } else if (phoneField is String) {
      // Try to extract country code from string like "+91 7209657008"
      final phoneStr = phoneField.trim();
      if (phoneStr.startsWith('+')) {
        final spaceIndex = phoneStr.indexOf(' ');
        if (spaceIndex > 0) {
          final cc = phoneStr.substring(0, spaceIndex);
          final num = phoneStr.substring(spaceIndex + 1);
          _selectedCountryCode = cc;
          if (cc == '+91') _selectedCountryFlag = '🇮🇳';
          else if (cc == '+1') _selectedCountryFlag = '🇺🇸';
          else if (cc == '+44') _selectedCountryFlag = '🇬🇧';
          else _selectedCountryFlag = '🇺🇳';
          mappedPhone = num; // Only the number part goes to the input field
        } else {
          // If no space, treat as just country code, leave phone empty
          mappedPhone = '';
        }
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
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1'),
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
        // Validate photo first before uploading
        final result = await ActionService.uploadAndValidateProfilePhoto(File(pickedFile.path));

        if (result['success']) {
          // Validation successful, get the S3 URL
          final s3Url = result['s3Url'] ?? result['data']?['s3Url'] ?? result['data']?['url'];
          setState(() {
            _uploadedPhotoUrl = s3Url;
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo validated and uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // Validation failed - clear the selected file and show bottom sheet
          setState(() {
            _selectedImageFile = null;
            _isUploadingPhoto = false;
          });

          // Show photo validation guidance bottom sheet
          PhotoValidationBottomSheet.show(
            context,
            onTryAgain: () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _selectedImageFile = null;
                _uploadedPhotoUrl = null;
                _isUploadingPhoto = false;
              });
            },
          );
        }
      } catch (e) {
        // Exception occurred - clear the selected file and show bottom sheet
        setState(() {
          _selectedImageFile = null;
          _isUploadingPhoto = false;
        });

        // Show photo validation guidance bottom sheet
        PhotoValidationBottomSheet.show(
          context,
          onTryAgain: () {
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Photo Section
                    _buildSectionHeader('Profile Photo', Icons.camera_alt_outlined),
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
                                         errorBuilder: (context, error, stackTrace) {
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
                                     } else if (_uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty) {
                                       return Image.network(
                                         _uploadedPhotoUrl!,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
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
                                     } else if (_currentUserPhotoUrl != null && _currentUserPhotoUrl!.isNotEmpty) {
                                       return Image.network(
                                         _currentUserPhotoUrl!,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
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
                                 : _uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty
                                     ? 'Uploaded Profile Photo'
                                     : _currentUserPhotoUrl != null && _currentUserPhotoUrl!.isNotEmpty
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
                                 : _uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty
                                     ? 'Successfully uploaded to server'
                                     : _currentUserPhotoUrl != null && _currentUserPhotoUrl!.isNotEmpty
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
                                     border: Border.all(color: Colors.grey.shade300),
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
                                         color: const Color(0xFFF97316),
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
                               
                               // Show upload status
                               if (_isUploadingPhoto) ...[
                                 const SizedBox(height: 16),
                                 Container(
                                   padding: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(
                                     color: Colors.blue[50],
                                     borderRadius: BorderRadius.circular(12),
                                     border: Border.all(color: Colors.blue[200]!),
                                   ),
                                   child: Row(
                                     children: [
                                       SizedBox(
                                         width: 20,
                                         height: 20,
                                         child: CircularProgressIndicator(
                                           strokeWidth: 2,
                                           valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                         ),
                                       ),
                                       const SizedBox(width: 12),
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
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
                          
                          // Subtitle
                          Text(
                            'Your basic account information.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
                                  fillColor: Colors.grey.shade100, // Different color to indicate disabled
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600, // Different text color for disabled
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
                          
                          // Subtitle
                          Text(
                            'Your professional background.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Form Fields
                          _buildFormField('Designation', _designationController),
                          const SizedBox(height: 16),
                          
                          _buildFormField('Company/Organization', _companyController),
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
                          
                          // Subtitle
                          Text(
                            'Your current location.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Form Field
                          // Searchable location field with suggestions (same as signup screen)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _locationController,
                                decoration: InputDecoration(
                                  hintText: 'Start typing your location...',
                                  prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                            _locationController.text = _locationSuggestions[index];
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
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
          child: Icon(
            icon,
            color: const Color(0xFFF97316),
            size: 20,
          ),
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
              borderSide: const BorderSide(color: Color(0xFFF97316)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          border: Border.all(
            color: Colors.lightGreen.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _roleCheckboxes[role] == true ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _roleCheckboxes[role] == true ? Colors.green : Colors.lightGreen.shade300,
                  width: 2,
                ),
              ),
              child: _roleCheckboxes[role] == true
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
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
                  color: _roleCheckboxes[role] == true ? Colors.green.shade700 : Colors.grey.shade700,
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
                    textStyle: const TextStyle(fontSize: 16, color: Colors.black),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
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
                    borderSide: const BorderSide(color: Color(0xFFF97316)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare phone number with country code
      final fullPhoneNumber = '$_selectedCountryCode ${_phoneController.text.trim()}';
      
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
              content: Text('Role "$role" is too long. Maximum 50 characters allowed.'),
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
        profilePhotoUrl: _uploadedPhotoUrl, // S3 URL only
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
        final updatedProfilePhoto = result['data']?['profilePhoto'] ?? _uploadedPhotoUrl;
        
        // Clear selected file and uploaded URL after successful upload
        setState(() {
          _selectedImageFile = null;
          _uploadedPhotoUrl = null;
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
          'profilePhoto': updatedProfilePhoto, // Use the stored profile photo URL
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
      }
    } catch (error) {
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
} 