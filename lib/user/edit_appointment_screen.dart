import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import 'user_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:country_picker/country_picker.dart';
import '../components/user/photo_validation_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentData;

  const EditAppointmentScreen({super.key, this.appointmentData});

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  // Form controllers
  final TextEditingController _appointmentPurposeController =
      TextEditingController();
  final TextEditingController _numberOfUsersController =
      TextEditingController();

  // Preferred date range controllers (for appointment scheduling)
  final TextEditingController _preferredFromDateController =
      TextEditingController();
  final TextEditingController _preferredToDateController =
      TextEditingController();

  // Program date range controllers (for course/program dates)
  final TextEditingController _programFromDateController =
      TextEditingController();
  final TextEditingController _programToDateController =
      TextEditingController();

  // Reference Information Controllers (for guest appointments)
  final TextEditingController _referenceNameController =
      TextEditingController();
  final TextEditingController _referenceEmailController =
      TextEditingController();
  final TextEditingController _referencePhoneController =
      TextEditingController();

  // Guest Information Controllers (for guest appointments)
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _guestDesignationController =
      TextEditingController();
  final TextEditingController _guestCompanyController = TextEditingController();
  final TextEditingController _guestLocationController =
      TextEditingController();

  // Form state
  bool _isFormValid = false;
  String? _selectedSecretary;
  String? _selectedSecretaryName;
  String? _selectedAppointmentLocation;
  String? _selectedLocationId;
  String? _selectedLocationMongoId;
  File? _selectedImage;
  File? _selectedAttachment; // For file attachments
  bool _isAttendingProgram = false;
  String?
  _existingAttachmentUrl; // For existing attachment from appointment data

  // Guest information state
  List<Map<String, TextEditingController>> _guestControllers = [];
  Map<int, String> _guestImages = {};
  Map<int, bool> _guestUploading = {};

  // Location search state
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocations = false;
  String _lastSearchQuery = '';

  // Main guest photo state
  String? _mainGuestPhotoUrl;
  bool _isMainGuestPhotoUploading = false;
  File? _mainGuestPhotoFile;

  // Location data
  List<Map<String, dynamic>> _locations = [];
  bool _isLoadingLocations = true;

  // Reference information loading state
  bool _isLoadingReferenceInfo = true;

  // Secretary data
  List<Map<String, dynamic>> _secretaries = [];
  bool _isLoadingSecretaries = false;
  String? _secretaryErrorMessage;

  // Email validation error
  String? _guestEmailError;

  // Date validation errors
  String? _dateRangeError;
  String? _programDateRangeError;

  // Country picker data for guest phone
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

  // Country picker data for additional guests
  Map<int, Country> _guestCountries = {};

  // Loading state
  bool _isLoading = false;
  bool _isSaving = false;

  // Get appointment type
  String get _appointmentType {
    return widget.appointmentData?['appointmentType']
            ?.toString()
            .toLowerCase() ??
        widget.appointmentData?['appointmentFor']?['type']
            ?.toString()
            .toLowerCase() ??
        'myself';
  }

  // Check if this is a guest appointment
  bool get _isGuestAppointment => _appointmentType == 'guest';

  @override
  void initState() {
    super.initState();
    // Initialize numberOfUsers to 1 by default (including the main user)
    _numberOfUsersController.text = '1';
    _loadAppointmentData();
    _loadLocations();
    if (_isGuestAppointment) {
      _loadReferenceInfo();
    }
  }

  @override
  void dispose() {
    _appointmentPurposeController.dispose();
    _numberOfUsersController.dispose();
    _preferredFromDateController.dispose();
    _preferredToDateController.dispose();
    _programFromDateController.dispose();
    _programToDateController.dispose();
    _referenceNameController.dispose();
    _referenceEmailController.dispose();
    _referencePhoneController.dispose();
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

  // Load existing appointment data
  void _loadAppointmentData() {
    if (widget.appointmentData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appointment = widget.appointmentData!;

      // Load basic appointment data
      _appointmentPurposeController.text =
          appointment['appointmentPurpose']?.toString() ??
          appointment['appointmentSubject']?.toString() ??
          '';

      // Load preferred date range
      final preferredDateRange = appointment['preferredDateRange'];
      if (preferredDateRange != null) {
        final fromDate = preferredDateRange['fromDate'];
        final toDate = preferredDateRange['toDate'];

        if (fromDate != null) {
          final from = DateTime.parse(fromDate);
          _preferredFromDateController.text =
              '${from.day.toString().padLeft(2, '0')}/${from.month.toString().padLeft(2, '0')}/${from.year}';
        }

        if (toDate != null) {
          final to = DateTime.parse(toDate);
          _preferredToDateController.text =
              '${to.day.toString().padLeft(2, '0')}/${to.month.toString().padLeft(2, '0')}/${to.year}';
        }
      }

      // Load location
      final appointmentLocation = appointment['appointmentLocation'];
      if (appointmentLocation != null) {
        if (appointmentLocation is Map<String, dynamic>) {
          _selectedAppointmentLocation = appointmentLocation['name']
              ?.toString();
          _selectedLocationId = appointmentLocation['locationId']?.toString();
          _selectedLocationMongoId = appointmentLocation['_id']?.toString();
        } else {
          _selectedAppointmentLocation = appointmentLocation.toString();
        }
      }

      // Load secretary
      final assignedSecretary = appointment['assignedSecretary'];
      print('🔍 Loading assignedSecretary data: $assignedSecretary');
      print('🔍 assignedSecretary type: ${assignedSecretary.runtimeType}');

      if (assignedSecretary is Map<String, dynamic>) {
        print('🔍 assignedSecretary keys: ${assignedSecretary.keys.toList()}');
        _selectedSecretary = assignedSecretary['_id']?.toString();
        // Store the full name for display
        _selectedSecretaryName = assignedSecretary['fullName']?.toString();
        print('🔍 Set _selectedSecretary: $_selectedSecretary');
        print('🔍 Set _selectedSecretaryName: $_selectedSecretaryName');
      } else {
        _selectedSecretary = assignedSecretary?.toString();
        print('🔍 Set _selectedSecretary (fallback): $_selectedSecretary');
      }

      // Load secretaries after location is set
      if (_selectedLocationId != null) {
        _loadSecretaries();
      }

      // Load program attendance data
      final attendingCourseDetails = appointment['attendingCourseDetails'];
      if (attendingCourseDetails != null &&
          attendingCourseDetails is Map<String, dynamic>) {
        
        // Check the isAttending field from the database
        final isAttending = attendingCourseDetails['isAttending'];
        if (isAttending == true) {
          _isAttendingProgram = true;
          print('📅 Program attendance data found: isAttending = true');
          
          // Load program date range
          final fromDate = attendingCourseDetails['fromDate'];
          final toDate = attendingCourseDetails['toDate'];

          if (fromDate != null) {
            final from = DateTime.parse(fromDate);
            _programFromDateController.text =
                '${from.day.toString().padLeft(2, '0')}/${from.month.toString().padLeft(2, '0')}/${from.year}';
          }

          if (toDate != null) {
            final to = DateTime.parse(toDate);
            _programToDateController.text =
                '${to.day.toString().padLeft(2, '0')}/${to.month.toString().padLeft(2, '0')}/${to.year}';
          }
        } else {
          _isAttendingProgram = false;
          print('📅 Program attendance data found: isAttending = false');
        }
      } else {
        // Explicitly set to false if no program details exist
        _isAttendingProgram = false;
        print('📅 No program attendance data found, setting _isAttendingProgram to false');
      }

      // Load existing attachment URL
      _existingAttachmentUrl = appointment['appointmentAttachment']?.toString();

      // Load guest-specific data if this is a guest appointment
      if (_isGuestAppointment) {
        _loadGuestData(appointment);
      }

      // Load accompanying users data
      _loadAccompanyingUsersData(appointment);

      // Set the number of users based on the loaded data
      final accompanyUsers = appointment['accompanyUsers'];
      print(
        'DEBUG LOAD: Setting numberOfUsers. accompanyUsers: $accompanyUsers',
      );
      if (accompanyUsers != null) {
        final List<dynamic> users = accompanyUsers['users'] ?? [];
        final numberOfUsers = accompanyUsers['numberOfUsers'];
        
        print('DEBUG LOAD: users.length = ${users.length}, numberOfUsers = $numberOfUsers');
        
        if (users.isNotEmpty) {
          // Use the length of users array + 1 for main user (when users array has data)
          _numberOfUsersController.text = (users.length + 1).toString();
          print(
            'DEBUG LOAD: Set numberOfUsers to ${users.length + 1} (total people including main user)',
          );
        } else if (numberOfUsers != null) {
          // Use numberOfUsers field + 1 for main user (when users array is empty)
          final int totalUsers = (numberOfUsers is int ? numberOfUsers : int.tryParse(numberOfUsers.toString()) ?? 0) + 1;
          _numberOfUsersController.text = totalUsers.toString();
          print(
            'DEBUG LOAD: Set numberOfUsers to $totalUsers (using numberOfUsers field + 1)',
          );
        } else {
          _numberOfUsersController.text = '1';
          print('DEBUG LOAD: Set numberOfUsers to 1 (just main user)');
        }
      } else {
        _numberOfUsersController.text = '1';
        print('DEBUG LOAD: Set numberOfUsers to 1 (just main user)');
      }

      _validateForm();
    } catch (e) {
      print('Error loading appointment data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointment data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadGuestData(Map<String, dynamic> appointment) {
    final guestInformation = appointment['guestInformation'];
    if (guestInformation != null && guestInformation is Map<String, dynamic>) {
      _guestNameController.text =
          guestInformation['fullName']?.toString() ?? '';
      _guestEmailController.text =
          guestInformation['emailId']?.toString() ?? '';
      _guestDesignationController.text =
          guestInformation['designation']?.toString() ?? '';
      _guestCompanyController.text =
          guestInformation['company']?.toString() ?? '';
      _guestLocationController.text =
          guestInformation['location']?.toString() ?? '';

      // Load guest photo
      _mainGuestPhotoUrl = guestInformation['profilePhotoUrl']?.toString();

      // Load phone number
      final phoneNumber = guestInformation['phoneNumber'];
      print('📞 Loading main guest phone number: $phoneNumber');
      if (phoneNumber != null) {
        if (phoneNumber is Map<String, dynamic>) {
          // Phone number is stored as an object with countryCode and number
          final countryCode = phoneNumber['countryCode']?.toString() ?? '';
          final number = phoneNumber['number']?.toString() ?? '';

                      if (number.isNotEmpty) {
              // Extract just the number part (remove country code if present)
              String numberOnly = number;
              
              // Get the country code without the + prefix
              final countryCodeWithoutPlus = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
              
              // Check if the number starts with the country code (without +)
              if (number.startsWith(countryCodeWithoutPlus)) {
                // Remove the country code from the beginning of the number
                numberOnly = number.substring(countryCodeWithoutPlus.length);
              } else if (number.startsWith('+')) {
                // Fallback: if number starts with +, try to extract country code
                final countryCodeWithoutPlus = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
                if (number.startsWith('+$countryCodeWithoutPlus')) {
                  numberOnly = number.substring(countryCodeWithoutPlus.length + 1); // +1 for the +
                } else {
                  // If the number doesn't match the expected country code format,
                  // try to extract any country code from the beginning
                  numberOnly = _extractNumberFromFullPhone(number);
                }
              }
              
              _guestPhoneController.text = numberOnly;
              print('📞 Parsed main guest phone number only: $numberOnly');

            // Set country
            _selectedCountry = Country(
              phoneCode: countryCode.startsWith('+') ? countryCode.substring(1) : countryCode,
              countryCode: 'IN', // Default to India
              e164Sc: 0,
              geographic: true,
              level: 1,
              name: 'India',
              example: '9876543210',
              displayName: 'India (IN) [$countryCode]',
              displayNameNoCountryCode: 'India (IN)',
              e164Key: '${countryCode.startsWith('+') ? countryCode.substring(1) : countryCode}-IN-0',
            );
          }
        } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
                      // Fallback: phone number is stored as a string
            if (phoneNumber.startsWith('+')) {
              // Extract just the number part
              String numberOnly = _extractNumberFromFullPhone(phoneNumber);
              String countryCode = '+91'; // Default
              
              // Try to find the country code that was removed
              final knownCountryCodes = ['+1', '+44', '+91', '+86', '+81', '+49', '+33', '+39', '+34', '+7', '+61', '+55', '+52', '+46', '+31', '+32', '+41', '+47', '+45', '+358', '+46', '+47', '+48', '+351', '+420', '+380', '+213', '+355'];
              
              for (String code in knownCountryCodes) {
                if (phoneNumber.startsWith(code)) {
                  countryCode = code;
                  break;
                }
              }
              
              _guestPhoneController.text = numberOnly;
              print('📞 Parsed main guest phone number only: $numberOnly');

            // Set country
            _selectedCountry = Country(
              phoneCode: countryCode.startsWith('+') ? countryCode.substring(1) : countryCode,
              countryCode: 'IN', // Default to India
              e164Sc: 0,
              geographic: true,
              level: 1,
              name: 'India',
              example: '9876543210',
              displayName: 'India (IN) [$countryCode]',
              displayNameNoCountryCode: 'India (IN)',
              e164Key: '${countryCode.startsWith('+') ? countryCode.substring(1) : countryCode}-IN-0',
            );
          } else {
            _guestPhoneController.text = phoneNumber;
            print('📞 Main guest phone (no + prefix): $phoneNumber');
          }
        }
      } else {
        print('📞 No main guest phone number found');
      }
    }

    // Load reference information
    final referenceInformation = appointment['referenceInformation'];
    if (referenceInformation != null &&
        referenceInformation is Map<String, dynamic>) {
      _referenceNameController.text =
          referenceInformation['fullName']?.toString() ?? '';
      _referenceEmailController.text =
          referenceInformation['email']?.toString() ?? '';
      _referencePhoneController.text =
          referenceInformation['phoneNumber']?.toString() ?? '';
    }
  }

  void _clearGuestControllers() {
    // Clear existing controllers
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
    }
    _guestControllers.clear();
    _guestImages.clear();
    _guestCountries.clear();
  }

  void _loadAccompanyingUsersData(Map<String, dynamic> appointment) {
    final accompanyUsers = appointment['accompanyUsers'];
    print('DEBUG LOAD: accompanyUsers from appointment: $accompanyUsers');
    if (accompanyUsers != null && accompanyUsers['users'] != null) {
      final List<dynamic> users = accompanyUsers['users'];
      print('DEBUG LOAD: Found ${users.length} accompanying users');

      // If users array is empty, treat it as no accompanying users
      if (users.isEmpty) {
        print('DEBUG LOAD: Empty users array, clearing guest controllers');
        _clearGuestControllers();
        return;
      }

      // Clear existing controllers
      _clearGuestControllers();

      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        if (user is Map<String, dynamic>) {
          final guestNumber = i + 1;

          // Create controllers for this guest
          final nameController = TextEditingController(
            text: user['fullName']?.toString() ?? '',
          );
          final phoneController = TextEditingController();
          final ageController = TextEditingController(
            text: user['age']?.toString() ?? '',
          );

          // Parse phone number
          final phoneNumber = user['phoneNumber'];
          print(
            '📞 Loading accompanying user $guestNumber phone number: $phoneNumber',
          );
          if (phoneNumber != null) {
            if (phoneNumber is Map<String, dynamic>) {
              // Phone number is stored as an object with countryCode and number
              final countryCode = phoneNumber['countryCode']?.toString() ?? '';
              final number = phoneNumber['number']?.toString() ?? '';

              if (number.isNotEmpty) {
                // Extract just the number part (remove country code if present)
                String numberOnly = number;
                
                // Get the country code without the + prefix
                final countryCodeWithoutPlus = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
                
                // Check if the number starts with the country code (without +)
                if (number.startsWith(countryCodeWithoutPlus)) {
                  // Remove the country code from the beginning of the number
                  numberOnly = number.substring(countryCodeWithoutPlus.length);
                } else if (number.startsWith('+')) {
                  // Fallback: if number starts with +, try to extract country code
                  final countryCodeWithoutPlus = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
                  if (number.startsWith('+$countryCodeWithoutPlus')) {
                    numberOnly = number.substring(countryCodeWithoutPlus.length + 1); // +1 for the +
                  } else {
                    // If the number doesn't match the expected country code format,
                    // try to extract any country code from the beginning
                    numberOnly = _extractNumberFromFullPhone(number);
                  }
                }
                
                phoneController.text = numberOnly;
                print(
                  '📞 Accompanying user $guestNumber phone number only: $numberOnly',
                );

                _guestCountries[guestNumber] = Country(
                  phoneCode: countryCode.startsWith('+') ? countryCode.substring(1) : countryCode,
                  countryCode: 'IN',
                  e164Sc: 0,
                  geographic: true,
                  level: 1,
                  name: 'India',
                  example: '9876543210',
                  displayName: 'India (IN) [$countryCode]',
                  displayNameNoCountryCode: 'India (IN)',
                  e164Key: '${countryCode.startsWith('+') ? countryCode.substring(1) : countryCode}-IN-0',
                );
              }
            } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
              // Fallback: phone number is stored as a string
              if (phoneNumber.startsWith('+')) {
                // Extract just the number part
                String numberOnly = _extractNumberFromFullPhone(phoneNumber);
                String countryCode = '+91'; // Default
                
                // Try to find the country code that was removed
                final knownCountryCodes = ['+1', '+44', '+91', '+86', '+81', '+49', '+33', '+39', '+34', '+7', '+61', '+55', '+52', '+46', '+31', '+32', '+41', '+47', '+45', '+358', '+46', '+47', '+48', '+351', '+420', '+380', '+213', '+355'];
                
                for (String code in knownCountryCodes) {
                  if (phoneNumber.startsWith(code)) {
                    countryCode = code;
                    break;
                  }
                }
                
                phoneController.text = numberOnly;
                print(
                  '📞 Accompanying user $guestNumber phone number only: $numberOnly',
                );

                _guestCountries[guestNumber] = Country(
                  phoneCode: countryCode.startsWith('+') ? countryCode.substring(1) : countryCode,
                  countryCode: 'IN',
                  e164Sc: 0,
                  geographic: true,
                  level: 1,
                  name: 'India',
                  example: '9876543210',
                  displayName: 'India (IN) [$countryCode]',
                  displayNameNoCountryCode: 'India (IN)',
                  e164Key: '${countryCode.startsWith('+') ? countryCode.substring(1) : countryCode}-IN-0',
                );
              } else {
                phoneController.text = phoneNumber;
                print(
                  '📞 Accompanying user $guestNumber phone (no + prefix): $phoneNumber',
                );
              }
            }
          } else {
            print(
              '📞 No phone number found for accompanying user $guestNumber',
            );
          }

          _guestControllers.add({
            'name': nameController,
            'phone': phoneController,
            'age': ageController,
          });

          // Load guest photo
          final photoUrl = user['profilePhotoUrl']?.toString();
          if (photoUrl != null && photoUrl.isNotEmpty) {
            _guestImages[guestNumber] = photoUrl;
          }
        }
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      final result = await ActionService.getAshramLocations();
      if (result['success'] == true) {
        setState(() {
          _locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _loadSecretaries() async {
    if (_selectedLocationId == null) return;

    setState(() {
      _isLoadingSecretaries = true;
      _secretaryErrorMessage = null;
    });

    try {
      final result = await ActionService.getAshramLocationByLocationId(
        locationId: _selectedLocationId!,
      );
      if (result['success'] == true) {
        final locationData = result['data'];
        final assignedSecretaries = locationData['assignedSecretaries'] ?? [];

        print('✅ Loaded ${assignedSecretaries.length} secretaries from API');

        // Transform the API response to match our expected format
        final List<Map<String, dynamic>> secretaries = [];

        for (var secretary in assignedSecretaries) {
          try {
            final secretaryData = secretary['secretaryId'] ?? secretary;
            secretaries.add({
              'id': secretaryData['_id']?.toString() ?? '',
              'name':
                  secretaryData['fullName']?.toString() ?? 'Unknown Secretary',
              'email': secretaryData['email']?.toString() ?? '',
              'role': secretaryData['role']?.toString() ?? '',
            });
          } catch (e) {
            print('⚠️ Error processing secretary data: $e');
            print('⚠️ Secretary data: $secretary');
          }
        }

        setState(() {
          _secretaries = secretaries;
          _isLoadingSecretaries = false;
        });

        // Log secretary details for debugging
        for (var secretary in secretaries) {
          print('👤 Secretary: ${secretary['name']} (ID: ${secretary['id']})');
        }
      } else {
        print('❌ Failed to load secretaries: ${result['message']}');
        setState(() {
          _isLoadingSecretaries = false;
          _secretaryErrorMessage =
              result['message'] ?? 'Failed to load secretaries';
          _secretaries = [];
        });
      }
    } catch (e) {
      print('❌ Error loading secretaries: $e');
      setState(() {
        _isLoadingSecretaries = false;
        _secretaryErrorMessage = 'Network error: $e';
        _secretaries = [];
      });
    }
  }

  // Main guest photo methods
  Future<void> _pickMainGuestImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _mainGuestPhotoFile = File(image.path);
          _isMainGuestPhotoUploading = true;
        });

        // Upload to S3
        try {
          final result = await ActionService.uploadAndValidateProfilePhoto(
            _mainGuestPhotoFile!,
          );

          if (result['success'] == true) {
            final s3Url = result['data']['s3Url'];
            print('✅ Main guest photo uploaded successfully!');
            print('📸 S3 URL received: $s3Url');
            setState(() {
              _mainGuestPhotoUrl = s3Url;
              _isMainGuestPhotoUploading = false;
            });
            _validateForm();
          } else {
            setState(() {
              _isMainGuestPhotoUploading = false;
            });

            // Show backend error message in dialog
            final errorMessage =
                result['error'] ??
                result['message'] ??
                'Photo validation failed';
            _showPhotoValidationErrorDialog(errorMessage, () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _mainGuestPhotoFile = null;
                _mainGuestPhotoUrl = null;
                _isMainGuestPhotoUploading = false;
              });
            });
          }
        } catch (e) {
          setState(() {
            _isMainGuestPhotoUploading = false;
          });

          // Show error message in dialog
          _showPhotoValidationErrorDialog(
            'Error uploading photo: ${e.toString()}',
            () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _mainGuestPhotoFile = null;
                _mainGuestPhotoUrl = null;
                _isMainGuestPhotoUploading = false;
              });
            },
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _removeMainGuestImage() {
    setState(() {
      _mainGuestPhotoUrl = null;
      _mainGuestPhotoFile = null;
    });
    _validateForm();
  }

  // File attachment methods
  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        setState(() {
          _selectedAttachment = File(file.path!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachment removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _loadReferenceInfo() async {
    try {
      final result = await ActionService.getCurrentUser();
      if (result['success'] == true) {
        final userData = result['data'];
        if (userData != null) {
          final fullName = userData['fullName']?.toString() ?? '';
          final email = userData['email']?.toString() ?? '';
          String phone = '';

          // Extract phone number
          if (userData['phoneNumber'] != null) {
            if (userData['phoneNumber'] is Map<String, dynamic>) {
              final phoneData = userData['phoneNumber'];
              final countryCode = phoneData['countryCode']?.toString() ?? '';
              final number = phoneData['number']?.toString() ?? '';
              phone = '$countryCode$number';
            } else {
              phone = userData['phoneNumber'].toString();
            }
          } else if (userData['phone'] != null) {
            phone = userData['phone'].toString();
          }

          setState(() {
            _referenceNameController.text = fullName;
            _referenceEmailController.text = email;
            _referencePhoneController.text = phone;
            _isLoadingReferenceInfo = false;
          });
        }
      }
    } catch (error) {
      setState(() {
        _referenceNameController.text = '';
        _referenceEmailController.text = '';
        _referencePhoneController.text = '';
        _isLoadingReferenceInfo = false;
      });
    }
  }

  void _updateGuestControllers() {
    int totalPeopleCount = int.tryParse(_numberOfUsersController.text) ?? 1;
    int accompanyUsersCount = totalPeopleCount - 1; // Subtract 1 for the main user

    print(
      'DEBUG UPDATE: _updateGuestControllers - totalPeopleCount: $totalPeopleCount, accompanyUsersCount: $accompanyUsersCount, current controllers: ${_guestControllers.length}',
    );

    // If we're reducing the number of guests, dispose extra controllers from the end
    if (_guestControllers.length > accompanyUsersCount) {
      print(
        'DEBUG UPDATE: Removing ${_guestControllers.length - accompanyUsersCount} guest controllers',
      );
      for (int i = accompanyUsersCount; i < _guestControllers.length; i++) {
        var guest = _guestControllers[i];
        guest['name']?.dispose();
        guest['phone']?.dispose();
        guest['age']?.dispose();

        // Also remove associated data
        int guestNumber = i + 1;
        _guestImages.remove(guestNumber);
        _guestUploading.remove(guestNumber);
        _guestCountries.remove(guestNumber);
      }
      _guestControllers.removeRange(
        accompanyUsersCount,
        _guestControllers.length,
      );
      print(
        'DEBUG UPDATE: After removal, controllers count: ${_guestControllers.length}',
      );
    }

    // If we need more guests, add them at the bottom
    while (_guestControllers.length < accompanyUsersCount) {
      int guestNumber = _guestControllers.length + 1;

      Map<String, TextEditingController> controllers = {
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'age': TextEditingController(),
      };
      _guestControllers.add(controllers);

      // Initialize country for new guest (only if not already set)
      if (!_guestCountries.containsKey(guestNumber)) {
        _guestCountries[guestNumber] = Country(
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
      }
    }

    setState(() {});
    _validateForm();
  }

  // Helper method to parse date string to DateTime
  DateTime? _parseDateString(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime.utc(year, month, day); // Use UTC to avoid timezone issues
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  // Helper method to validate date range
  bool _isValidDateRange(String fromDate, String toDate) {
    if (fromDate.isEmpty || toDate.isEmpty)
      return true; // Let other validation handle empty dates

    final fromDateTime = _parseDateString(fromDate);
    final toDateTime = _parseDateString(toDate);

    if (fromDateTime == null || toDateTime == null)
      return true; // Let other validation handle invalid dates

    return fromDateTime.isBefore(toDateTime);
  }

  // Helper method to validate date range and set error message
  bool _validateDateRange(String fromDate, String toDate, String errorType) {
    if (fromDate.isEmpty || toDate.isEmpty) {
      if (errorType == 'appointment') {
        _dateRangeError = null;
      } else if (errorType == 'program') {
        _programDateRangeError = null;
      }
      return true; // Let other validation handle empty dates
    }

    final fromDateTime = _parseDateString(fromDate);
    final toDateTime = _parseDateString(toDate);

    if (fromDateTime == null || toDateTime == null) {
      if (errorType == 'appointment') {
        _dateRangeError = null;
      } else if (errorType == 'program') {
        _programDateRangeError = null;
      }
      return true; // Let other validation handle invalid dates
    }

    final isValid = fromDateTime.isBefore(toDateTime);

    if (errorType == 'appointment') {
      _dateRangeError = isValid ? null : 'From date must be before to date';
    } else if (errorType == 'program') {
      _programDateRangeError = isValid
          ? null
          : 'Program start date must be before program end date';
    }

    return isValid;
  }

  void _validateForm() {
    bool basicFormValid =
        _appointmentPurposeController.text.isNotEmpty &&
        _preferredFromDateController.text.isNotEmpty &&
        _preferredToDateController.text.isNotEmpty;

    // Validate preferred date ranges
    bool preferredDateRangeValid = _validateDateRange(
      _preferredFromDateController.text,
      _preferredToDateController.text,
      'appointment',
    );

    // Validate main guest photo if appointment type is guest
    bool mainGuestPhotoValid = true;
    if (_isGuestAppointment) {
      if (_mainGuestPhotoUrl == null) {
        mainGuestPhotoValid = false;
      }
    }

    // Validate main guest email if appointment type is guest
    bool mainGuestEmailValid = true;
    if (_isGuestAppointment) {
      mainGuestEmailValid =
          _guestEmailError == null && _guestEmailController.text.isNotEmpty;
    }

    // Validate guest information if any
    bool guestFormValid = true;
    final totalPeopleCount =
        int.tryParse(_numberOfUsersController.text) ?? 1;
    final accompanyUsersCount = totalPeopleCount - 1; // Subtract 1 for the main user
    if (accompanyUsersCount > 0 && accompanyUsersCount <= 10) {
      for (var guest in _guestControllers) {
        if (guest['name']?.text.isEmpty == true ||
            guest['phone']?.text.isEmpty == true ||
            guest['age']?.text.isEmpty == true) {
          guestFormValid = false;
          break;
        }

        // Validate age range (1-120)
        final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
        if (age < 1 || age > 120) {
          guestFormValid = false;
          break;
        }
      }
    }

    // Validate program dates if attending a program
    bool programDatesValid = true;
    if (_isAttendingProgram) {
      if (_programFromDateController.text.isEmpty ||
          _programToDateController.text.isEmpty) {
        programDatesValid = false;
      } else {
        // Validate program date range
        programDatesValid = _validateDateRange(
          _programFromDateController.text,
          _programToDateController.text,
          'program',
        );
      }
    }

    setState(() {
      _isFormValid =
          basicFormValid &&
          preferredDateRangeValid &&
          mainGuestPhotoValid &&
          mainGuestEmailValid &&
          guestFormValid &&
          programDatesValid;
    });
  }

  Future<void> _saveAppointment() async {
    if (!_isFormValid) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare update data
      Map<String, dynamic> updateData = {
        'appointmentPurpose': _appointmentPurposeController.text.trim(),
        'appointmentSubject': _appointmentPurposeController.text.trim(),
        'appointmentLocation': _selectedLocationMongoId,
        'assignedSecretary': _selectedSecretary,
        'numberOfUsers': int.tryParse(_numberOfUsersController.text) ?? 1, // Total number of people
      };

      // Use preferred date range for appointment scheduling
      updateData['preferredDateRange'] = {
        'fromDate': _parseDateToISO(_preferredFromDateController.text),
        'toDate': _parseDateToISO(_preferredToDateController.text),
      };

      // Add guest information if appointment type is guest
      if (_isGuestAppointment) {
        final phoneText = _guestPhoneController.text.trim();
        String fullPhoneNumber = phoneText;

        // Always add the country code to the phone number
        if (phoneText.isNotEmpty) {
          final countryCode = '+${_selectedCountry.phoneCode}';
          fullPhoneNumber = '$countryCode$phoneText';
        }

        print('📞 Saving main guest phone: $fullPhoneNumber');

        Map<String, dynamic> guestInfo = {
          'fullName': _guestNameController.text.trim(),
          'emailId': _guestEmailController.text.trim(),
          'phoneNumber': fullPhoneNumber,
          'designation': _guestDesignationController.text.trim(),
          'company': _guestCompanyController.text.trim(),
          'location': _guestLocationController.text.trim(),
        };

        if (_mainGuestPhotoUrl != null) {
          guestInfo['profilePhotoUrl'] = _mainGuestPhotoUrl;
        }

        updateData['guestInformation'] = guestInfo;

        // Add reference information
        updateData['referenceInformation'] = {
          'fullName': _referenceNameController.text.trim(),
          'email': _referenceEmailController.text.trim(),
          'phoneNumber': _referencePhoneController.text.trim(),
        };
      }

      // Add accompanyUsers if there are additional users
      final totalPeopleCount =
          int.tryParse(_numberOfUsersController.text) ?? 1;
      final accompanyUsersCount = totalPeopleCount - 1; // Subtract 1 for the main user
      if (accompanyUsersCount > 0) {
        List<Map<String, dynamic>> accompanyUsers = [];
        for (int i = 0; i < _guestControllers.length; i++) {
          var guest = _guestControllers[i];
          int guestNumber = i + 1;

          final phoneText = guest['phone']?.text.trim() ?? '';
          final countryCode = _guestCountries[guestNumber]?.phoneCode ?? '91';
          
          // Format phone number as object with countryCode and number
          Map<String, dynamic> phoneNumberObj = {
            'countryCode': '+$countryCode',
            'number': '$countryCode$phoneText',
          };

          print(
            '📞 Saving accompanying user $guestNumber phone: ${phoneNumberObj['countryCode']}${phoneText}',
          );

          Map<String, dynamic> guestData = {
            'fullName': guest['name']?.text.trim() ?? '',
            'phoneNumber': phoneNumberObj,
            'age': int.tryParse(guest['age']?.text ?? '0') ?? 0,
          };

          if (_guestImages.containsKey(guestNumber)) {
            guestData['profilePhotoUrl'] = _guestImages[guestNumber];
          }

          accompanyUsers.add(guestData);
        }

        updateData['accompanyUsers'] = {
          'numberOfUsers': accompanyUsersCount,
          'users': accompanyUsersCount > 10 ? [] : accompanyUsers,
        };
        print(
          'DEBUG SAVE: Sending accompanyUsers with ${accompanyUsers.length} users',
        );
      } else {
        // If no accompanying users, ensure numberOfUsers is set to 1 and clear accompanyUsers
        updateData['numberOfUsers'] = 1;
        // Try sending empty array instead of null to ensure backend clears the data
        updateData['accompanyUsers'] = {'numberOfUsers': 0, 'users': []};
        print(
          'DEBUG SAVE: Setting accompanyUsers to empty array and numberOfUsers to 1',
        );
      }

      // Add program attendance data if applicable
      if (_isAttendingProgram) {
        updateData['attendingCourseDetails'] = {
          'courseName': 'General Program',
          'duration': '1 day',
          'fromDate': _parseDateToISO(_programFromDateController.text),
          'toDate': _parseDateToISO(_programToDateController.text),
        };
      }

      // Call API to update appointment
      final appointmentId =
          widget.appointmentData?['appointmentId'] ??
          widget.appointmentData?['_id'] ??
          '';

      final result = await ActionService.updateAppointmentEnhanced(
        appointmentId: appointmentId,
        updateData: updateData,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update appointment'),
          ),
        );
      }
    } catch (e) {
      print('Error saving appointment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving appointment: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _parseDateToISO(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime.utc(year, month, day); // Use UTC to avoid timezone issues
        return date.toIso8601String().split('T')[0];
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return dateString;
  }

  // Helper method to extract number from full phone number (removes country code)
  String _extractNumberFromFullPhone(String fullPhone) {
    if (!fullPhone.startsWith('+')) {
      return fullPhone; // No country code to remove
    }

    // List of common country codes to try
    final countryCodes = [
      '+1', '+44', '+91', '+86', '+81', '+49', '+33', '+39', '+34', '+7', 
      '+61', '+55', '+52', '+46', '+31', '+32', '+41', '+47', '+45', '+358', 
      '+46', '+47', '+48', '+351', '+420', '+380', '+213', '+355', '+33', '+39'
    ];

    // Try to find and remove the country code
    for (String code in countryCodes) {
      if (fullPhone.startsWith(code)) {
        return fullPhone.substring(code.length);
      }
    }

    // If no known country code found, try to remove the first 1-4 digits after +
    // This handles cases like +21312345667 where 213 is the country code
    if (fullPhone.length > 4) {
      // Try removing 1-4 digits after the +
      for (int i = 1; i <= 4; i++) {
        if (fullPhone.length > i + 1) {
          String possibleCode = fullPhone.substring(1, i + 1);
          // Check if the remaining part looks like a phone number (at least 7 digits)
          String remaining = fullPhone.substring(i + 1);
          if (remaining.length >= 7 && RegExp(r'^\d+$').hasMatch(remaining)) {
            return remaining;
          }
        }
      }
    }

    // If all else fails, return the original number without the +
    return fullPhone.substring(1);
  }

  // Open attachment URL
  Future<void> _openAttachmentUrl(String url) async {
    try {
      // Clean and validate the URL
      String cleanUrl = url.trim();

      // Add protocol if missing
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      print('🔄 Attempting to open URL: $cleanUrl');

      final Uri uri = Uri.parse(cleanUrl);

      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(uri);
      print('🔄 Can launch URL: $canLaunch');

      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('🔄 URL launched successfully: $launched');

        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open attachment in browser'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error if URL cannot be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot open attachment URL: $cleanUrl'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('🔄 Error opening attachment URL: $e');
      // Show error if there's an exception
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening attachment: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // UI Helper Methods
  Widget _buildReferenceField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterText: '', // Hide character counter
          ),
          onChanged: (_) => _validateForm(),
        ),
      ],
    );
  }

  // Email field with validation
  Widget _buildEmailField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
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
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _guestEmailError != null
                    ? Colors.red
                    : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _guestEmailError != null
                    ? Colors.red
                    : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _guestEmailError != null
                    ? Colors.red
                    : Colors.deepPurple,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            setState(() {
              // Validate email on change
              if (value.isEmpty) {
                _guestEmailError = 'Email is required';
              } else {
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value)) {
                  _guestEmailError = 'Please enter a valid email address';
                } else {
                  _guestEmailError = null;
                }
              }
            });
            _validateForm();
          },
        ),
        if (_guestEmailError != null) ...[
          const SizedBox(height: 4),
          Text(
            _guestEmailError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    Function(String)? onChanged,
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
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLocationField() {
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
        GestureDetector(
          onTap: _showLocationBottomSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedAppointmentLocation ?? 'Select a location',
                    style: TextStyle(
                      color: _selectedAppointmentLocation != null
                          ? Colors.black87
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFFF97316),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Location List
              Expanded(
                child: _isLoadingLocations
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          final location = _locations[index];
                          final locationName =
                              location['name']?.toString() ?? '';
                          final isSelected =
                              _selectedAppointmentLocation == locationName;

                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? const Color(0xFFF97316)
                                  : Colors.grey[600],
                            ),
                            title: Text(
                              locationName,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFFF97316)
                                    : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: const Color(0xFFF97316),
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedAppointmentLocation = locationName;
                                _selectedLocationId = location['locationId']
                                    ?.toString();
                                _selectedLocationMongoId = location['_id']
                                    ?.toString();
                              });

                              // Load secretaries for the selected location
                              if (_selectedLocationId != null) {
                                _loadSecretaries();
                              }

                              Navigator.pop(context);
                              _validateForm();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecretaryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Have you been in touch with any secretary regarding your appointment?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showSecretaryBottomSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingSecretaries
                      ? Text(
                          'Loading secretaries...',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : _selectedLocationId == null
                      ? Text(
                          'Please select a location first',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : Text(
                          _getSelectedSecretaryName() ?? 'Select a secretary',
                          style: TextStyle(
                            color:
                                _getSelectedSecretaryName() != null &&
                                    _getSelectedSecretaryName() !=
                                        'None - I am not in touch with any secretary'
                                ? Colors.black87
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _getSelectedSecretaryName() {
    print('🔍 _getSelectedSecretaryName() called');
    print('🔍 _selectedSecretary: $_selectedSecretary');
    print('🔍 _selectedSecretaryName: $_selectedSecretaryName');
    print('🔍 _secretaries count: ${_secretaries.length}');

    if (_selectedSecretary == null)
      return 'None - I am not in touch with any secretary';

    // If we have a stored name, use it
    if (_selectedSecretaryName != null && _selectedSecretaryName!.isNotEmpty) {
      print('🔍 Using stored name: $_selectedSecretaryName');
      return _selectedSecretaryName;
    }

    // Otherwise, try to find it in the secretaries list
    final selectedSecretary = _secretaries.firstWhere(
      (secretary) => secretary['id'] == _selectedSecretary,
      orElse: () => {},
    );
    print('🔍 Found secretary in list: $selectedSecretary');
    return selectedSecretary['name'];
  }

  void _showSecretaryBottomSheet() {
    if (_selectedLocationId == null || _isLoadingSecretaries) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.person, color: const Color(0xFFF97316), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Secretary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Secretary List
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // None option
                  ListTile(
                    leading: Icon(
                      Icons.person_off,
                      color: _selectedSecretary == null
                          ? const Color(0xFFF97316)
                          : Colors.grey[600],
                    ),
                    title: Text(
                      'None - I am not in touch with any secretary',
                      style: TextStyle(
                        fontWeight: _selectedSecretary == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedSecretary == null
                            ? const Color(0xFFF97316)
                            : Colors.black87,
                      ),
                    ),
                    trailing: _selectedSecretary == null
                        ? Icon(Icons.check, color: const Color(0xFFF97316))
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSecretary = null;
                        _selectedSecretaryName = null;
                      });
                      Navigator.pop(context);
                      _validateForm();
                    },
                  ),

                  // Secretary options
                  ..._secretaries.map((secretary) {
                    final secretaryId = secretary['id']?.toString();
                    final secretaryName =
                        secretary['name']?.toString() ?? 'Unknown';
                    final isSelected = _selectedSecretary == secretaryId;

                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: isSelected
                            ? const Color(0xFFF97316)
                            : Colors.grey[600],
                      ),
                      title: Text(
                        secretaryName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFF97316)
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: const Color(0xFFF97316))
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSecretary = secretaryId;
                          _selectedSecretaryName = secretaryName;
                        });
                        Navigator.pop(context);
                        _validateForm();
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Photo picker methods for guests
  Future<void> _pickGuestImage(ImageSource source, int guestNumber) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      print('📸 Guest $guestNumber image selected: ${pickedFile.path}');

      // Show uploading state
      setState(() {
        _guestUploading[guestNumber] = true;
      });

      try {
        // Upload photo immediately and get S3 URL
        final result = await ActionService.uploadAndValidateProfilePhoto(
          File(pickedFile.path),
        );

        if (result['success']) {
          final s3Url = result['s3Url'];
          setState(() {
            _guestImages[guestNumber] = s3Url;
            _guestUploading[guestNumber] = false;
          });

          print('✅ Guest $guestNumber photo uploaded to S3: $s3Url');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Guest $guestNumber photo uploaded and validated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _guestUploading[guestNumber] = false;
          });

          print(
            '❌ Guest $guestNumber photo upload failed: ${result['message']}',
          );

          // Show backend error message in dialog
          final errorMessage =
              result['error'] ?? result['message'] ?? 'Photo validation failed';
          _showPhotoValidationErrorDialog(
            'Guest $guestNumber: $errorMessage',
            () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _guestImages.remove(guestNumber);
                _guestUploading[guestNumber] = false;
              });
            },
          );
        }
      } catch (e) {
        setState(() {
          _guestUploading[guestNumber] = false;
        });

        print('❌ Error uploading guest $guestNumber photo: $e');

        // Show error message in dialog
        _showPhotoValidationErrorDialog(
          'Guest $guestNumber: Error uploading photo: ${e.toString()}',
          () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _guestImages.remove(guestNumber);
              _guestUploading[guestNumber] = false;
            });
          },
        );
      }
    }
  }

  void _removeGuestImage(int guestNumber) {
    setState(() {
      _guestImages.remove(guestNumber);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guest $guestNumber photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _updatePhoneNumberWithCountryCode(
    int guestNumber,
    String newCountryCode,
  ) {
    if (guestNumber > 0 && guestNumber <= _guestControllers.length) {
      final controller = _guestControllers[guestNumber - 1]['phone'];
      if (controller != null) {
        final currentText = controller.text;
        if (currentText.isNotEmpty) {
          // Extract the number part (remove existing country code)
          String numberPart = currentText;
          if (currentText.startsWith('+')) {
            // Remove the + and existing country code
            numberPart = currentText.substring(1);
            // Find where the country code ends and number begins
            for (int i = 1; i <= numberPart.length; i++) {
              final possibleCountryCode = numberPart.substring(0, i);
              if (possibleCountryCode == newCountryCode) {
                numberPart = numberPart.substring(i);
                break;
              }
            }
          }
          // Set the new combined format
          controller.text = '+$newCountryCode$numberPart';
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      }
    }
  }

  void _updateMainGuestPhoneNumberWithCountryCode(String newCountryCode) {
    final currentText = _guestPhoneController.text;
    if (currentText.isNotEmpty) {
      // Extract the number part (remove existing country code)
      String numberPart = currentText;
      if (currentText.startsWith('+')) {
        // Remove the + and existing country code
        numberPart = currentText.substring(1);
        // Find where the country code ends and number begins
        for (int i = 1; i <= numberPart.length; i++) {
          final possibleCountryCode = numberPart.substring(0, i);
          if (possibleCountryCode == newCountryCode) {
            numberPart = numberPart.substring(i);
            break;
          }
        }
      }
      // Set the new combined format
      _guestPhoneController.text = '+$newCountryCode$numberPart';
      _guestPhoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: _guestPhoneController.text.length),
      );
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _validateForm();
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    Function(String)? onChanged,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: placeholder,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    Function()? onTap,
    String? errorMessage,
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
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Select date',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorMessage != null ? Colors.red : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorMessage != null ? Colors.red : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: errorMessage != null ? Colors.red : Colors.deepPurple,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: onTap,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestPhoneFieldWithCountryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country picker button
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
                      _selectedCountry = country;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+${_selectedCountry.phoneCode}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: _guestPhoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter mobile number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterText: '', // Hide character counter
                ),
                onChanged: (value) {
                  _validateForm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccompanyingUserPhoneField(
    int guestNumber,
    TextEditingController controller,
  ) {
    // Get the country for this guest
    final country = _guestCountries[guestNumber] ?? _selectedCountry;
    final countryCode = country.phoneCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country picker button
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
                  onSelect: (Country selectedCountry) {
                    setState(() {
                      _guestCountries[guestNumber] = selectedCountry;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+$countryCode',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(0),
                    borderSide: BorderSide(color: Colors.deepPurple),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterText: '', // Hide character counter
                ),
                onChanged: (value) {
                  _validateForm();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestCard(
    int guestNumber,
    Map<String, TextEditingController> guest,
  ) {
    // Check if photo is required (age >= 12)
    final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
    final isPhotoRequired = age >= 12;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Accompany User $guestNumber',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF97316),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            _buildReferenceField(
              label: 'Name',
              controller: guest['name']!,
              placeholder: 'Enter name',
            ),
            const SizedBox(height: 12),

            // Age
            _buildReferenceField(
              label: 'Age',
              controller: guest['age']!,
              placeholder: 'Enter age (1-120)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Please enter 1-120';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Phone
            _buildAccompanyingUserPhoneField(guestNumber, guest['phone']!),

            // Photo Section (only show if age >= 12)
            if (isPhotoRequired) ...[
              const SizedBox(height: 16),

              // Photo Header
              Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    color: const Color(0xFFF97316),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Photo *',
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
                'Photo of the Guest Required for Age 12 years and Above',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),

              // Photo Upload Options
              Column(
                children: [
                  // Upload from Device Card
                  GestureDetector(
                    onTap: () =>
                        _pickGuestImage(ImageSource.gallery, guestNumber),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: const Color(0xFFF97316),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upload from Device',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose an existing photo',
                                  style: TextStyle(
                                    fontSize: 12,
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
                  const SizedBox(height: 8),

                  // Take Photo Card
                  GestureDetector(
                    onTap: () =>
                        _pickGuestImage(ImageSource.camera, guestNumber),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: const Color(0xFFF97316),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Take Photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Use your device camera',
                                  style: TextStyle(
                                    fontSize: 12,
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
                  if (_guestImages.containsKey(guestNumber) ||
                      _guestUploading[guestNumber] == true) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _guestUploading[guestNumber] == true
                            ? Colors.blue[50]
                            : (_guestImages.containsKey(guestNumber)
                                  ? Colors.green[50]
                                  : Colors.orange[50]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _guestUploading[guestNumber] == true
                              ? Colors.blue[200]!
                              : (_guestImages.containsKey(guestNumber)
                                    ? Colors.green[200]!
                                    : Colors.orange[200]!),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo preview and status message
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: _guestUploading[guestNumber] == true
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue,
                                              ),
                                        ),
                                      )
                                    : _guestImages.containsKey(guestNumber)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _guestImages[guestNumber]!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                valueColor:
                                                    const AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.blue),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            print(
                                              '❌ Error loading accompanying user photo for guest $guestNumber: $error',
                                            );
                                            print(
                                              '❌ Photo URL: ${_guestImages[guestNumber]}',
                                            );
                                            return Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.warning,
                                        color: Colors.orange,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_guestUploading[guestNumber] ==
                                        true) ...[
                                      const Text(
                                        'Uploading photo...',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ] else if (_guestImages.containsKey(
                                      guestNumber,
                                    )) ...[
                                      const Text(
                                        'Photo uploaded successfully',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Guest photo is ready',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        'Photo required',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Please upload a photo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Action buttons (only show if photo is uploaded)
                          if (_guestImages.containsKey(guestNumber)) ...[
                            const SizedBox(height: 12),

                            Column(
                              children: [
                                // Upload Different Photo
                                GestureDetector(
                                  onTap: () => _pickGuestImage(
                                    ImageSource.gallery,
                                    guestNumber,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: const Color(0xFFF97316),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upload Different Photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                                  onTap: () => _pickGuestImage(
                                    ImageSource.camera,
                                    guestNumber,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(6),
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
                                            fontWeight: FontWeight.w500,
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
                                  onTap: () => _removeGuestImage(guestNumber),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
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
                                            fontWeight: FontWeight.w500,
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
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Appointment'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        // Appointment Type Display at Top
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isGuestAppointment
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isGuestAppointment
                                  ? Colors.green.shade200
                                  : Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isGuestAppointment
                                        ? Icons.person
                                        : Icons.person_outline,
                                    color: _isGuestAppointment
                                        ? Colors.green.shade700
                                        : Colors.blue.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Appointment Type: ${_isGuestAppointment ? 'Guest' : 'Myself'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isGuestAppointment
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isGuestAppointment
                                    ? 'Editing appointment for a guest'
                                    : 'Editing your personal appointment',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Reference Information Section (for guest appointments)
                        if (_isGuestAppointment) ...[
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
                                  _isLoadingReferenceInfo
                                      ? 'Loading your information...'
                                      : 'Your reference details',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Show loading state or reference fields
                                if (_isLoadingReferenceInfo) ...[
                                  const Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.blue,
                                              ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Loading your information...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Reference Name
                                  _buildReferenceField(
                                    label: 'Reference Name',
                                    controller: _referenceNameController,
                                    placeholder: 'Your name',
                                  ),
                                  const SizedBox(height: 12),

                                  // Reference Email
                                  _buildReferenceField(
                                    label: 'Reference Email',
                                    controller: _referenceEmailController,
                                    placeholder: 'Your email',
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 12),

                                  // Reference Phone
                                  _buildReferenceField(
                                    label: 'Reference Phone',
                                    controller: _referencePhoneController,
                                    placeholder: 'Your phone number',
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
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
                            'Edit the details of the person you are requesting the appointment for',
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
                          _buildEmailField(
                            label: 'Email ID of the Guest',
                            controller: _guestEmailController,
                            placeholder: 'guest@email.com',
                          ),
                          const SizedBox(height: 16),

                          // Guest Mobile
                          _buildGuestPhoneFieldWithCountryPicker(),
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
                            placeholder: 'Guest\'s location',
                          ),
                          const SizedBox(height: 24),

                          // Guest Photo Section
                          Row(
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: const Color(0xFFF97316),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Guest Photo',
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

                          // Guest Photo Status
                          if (_isMainGuestPhotoUploading) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: const Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Uploading photo...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Please wait while we process your photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_mainGuestPhotoUrl != null) ...[
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
                                      color: Colors.grey[200],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _mainGuestPhotoUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.blue),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print(
                                            '❌ Error loading main guest photo: $error',
                                          );
                                          print(
                                            '❌ Photo URL: $_mainGuestPhotoUrl',
                                          );
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Photo uploaded successfully',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Guest photo is ready',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action buttons for main guest photo
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                // Upload Different Photo
                                GestureDetector(
                                  onTap: () =>
                                      _pickMainGuestImage(ImageSource.gallery),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.upload_file,
                                          color: const Color(0xFFF97316),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upload Different Photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                                      _pickMainGuestImage(ImageSource.camera),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(6),
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
                                            fontWeight: FontWeight.w500,
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
                                  onTap: _removeMainGuestImage,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
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
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Photo required for guests 12+ years old',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Please upload a photo',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Upload buttons when no photo exists
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickMainGuestImage(
                                      ImageSource.gallery,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.upload_file,
                                            color: const Color(0xFFF97316),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Upload Photo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        _pickMainGuestImage(ImageSource.camera),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.orange[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            color: Colors.orange[700],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Take Photo',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],

                        // Header for Appointment Details
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
                          'Edit details about your requested appointment',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 32),

                        // Appointment Purpose
                        _buildTextArea(
                          label: 'Appointment Purpose',
                          controller: _appointmentPurposeController,
                          placeholder:
                              'Please describe the purpose of your appointment in detail',
                          onChanged: (value) => _validateForm(),
                        ),
                        const SizedBox(height: 20),

                        // Appointment Location
                        _buildLocationField(),
                        const SizedBox(height: 20),

                        // Secretary Contact
                        _buildSecretaryField(),
                        const SizedBox(height: 20),

                        // Total Number of People with + and - buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Number of People',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Minus button
                                GestureDetector(
                                  onTap: () {
                                    int currentCount =
                                        int.tryParse(
                                          _numberOfUsersController.text,
                                        ) ??
                                        1;
                                    print(
                                      'DEBUG MINUS: Button clicked. Current count: $currentCount, Guest controllers: ${_guestControllers.length}',
                                    );
                                    if (currentCount > 1) {
                                      print(
                                        'DEBUG MINUS: Removing guest. Current count: $currentCount, Guest controllers: ${_guestControllers.length}',
                                      );
                                      setState(() {
                                        _numberOfUsersController.text =
                                            (currentCount - 1).toString();
                                      });
                                      _updateGuestControllers();
                                      _validateForm();
                                      print(
                                        'DEBUG MINUS: After removal. New count: ${_numberOfUsersController.text}, Guest controllers: ${_guestControllers.length}',
                                      );
                                    } else {
                                      print(
                                        'DEBUG MINUS: Cannot reduce below 1 (minimum is main user)',
                                      );
                                    }
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Number display
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _numberOfUsersController.text.isEmpty
                                            ? '1'
                                            : _numberOfUsersController.text,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Plus button
                                GestureDetector(
                                  onTap: () {
                                    int currentCount =
                                        int.tryParse(
                                          _numberOfUsersController.text,
                                        ) ??
                                        1;
                                    setState(() {
                                      _numberOfUsersController.text =
                                          (currentCount + 1).toString();
                                    });
                                    _updateGuestControllers();
                                    _validateForm();
                                  },
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF97316),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFF97316),
                                      ),
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
                            const SizedBox(height: 4),
                            Text(
                              'Total number of people including you',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Guest Information Cards (for accompanying users)
                        if ((int.tryParse(_numberOfUsersController.text) ?? 1) >
                                1 &&
                            (int.tryParse(_numberOfUsersController.text) ??
                                    1) <=
                                11) ...[
                          const Text(
                            'Accompany User Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please provide details for accompany users',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._guestControllers.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, TextEditingController> guest =
                                entry.value;
                            return _buildGuestCard(index + 1, guest);
                          }).toList(),
                          const SizedBox(height: 20),
                        ] else if ((int.tryParse(
                                  _numberOfUsersController.text,
                                ) ??
                                1) >
                            11) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Large Group Appointment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'For appointments with more than 10 accompany users, additional person details are not required.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

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
                          controller: _preferredFromDateController,
                          onTap: () => _selectDate(
                            context,
                            _preferredFromDateController,
                          ),
                          errorMessage: _dateRangeError,
                        ),
                        const SizedBox(height: 20),

                        // To Date
                        _buildDateField(
                          label: 'To Date',
                          controller: _preferredToDateController,
                          onTap: () =>
                              _selectDate(context, _preferredToDateController),
                          errorMessage: _dateRangeError,
                        ),
                        const SizedBox(height: 32),

                        // Attachment Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.attach_file,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Upload Document',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select PDF, DOC, PPT files (up to 5MB)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Show existing attachment if available
                              if (_existingAttachmentUrl != null &&
                                  _existingAttachmentUrl!.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => _openAttachmentUrl(
                                        _existingAttachmentUrl!,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.attach_file,
                                            size: 20,
                                            color: Colors.blue.shade600,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Existing Attachment',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .blue
                                                            .shade600,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Click to view attachment',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.blue.shade500,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.open_in_new,
                                            size: 20,
                                            color: Colors.blue.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              GestureDetector(
                                onTap: _pickAttachment,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: const Text(
                                    'Choose File',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                              // Show selected attachment
                              if (_selectedAttachment != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
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
                                              _selectedAttachment!.path
                                                  .split('/')
                                                  .last,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'File selected successfully',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: _removeAttachment,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.red.shade600,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

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
                                _validateForm();
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
                                _validateForm();
                              },
                            ),
                            const Text('Yes'),
                          ],
                        ),

                        // Program Date Range Section (only show if user selects Yes)
                        if (_isAttendingProgram) ...[
                          const SizedBox(height: 24),

                          // Program Date Range Header
                          Row(
                            children: [
                              const Text(
                                'Program Date Range',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '*',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Program Start and End Date Fields
                          Column(
                            children: [
                              // Program Start Date
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Program Start',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFF97316),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _selectDate(
                                      context,
                                      _programFromDateController,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _programDateRangeError != null
                                              ? Colors.red
                                              : const Color(0xFFF97316),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _programFromDateController,
                                        enabled: false,
                                        decoration: InputDecoration(
                                          hintText: 'dd-mm-yyyy',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 16,
                                              ),
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                            color: const Color(0xFFF97316),
                                          ),
                                          suffixIcon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_programDateRangeError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _programDateRangeError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Program End Date
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Program End',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFF97316),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _selectDate(
                                      context,
                                      _programToDateController,
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _programDateRangeError != null
                                              ? Colors.red
                                              : const Color(0xFFF97316),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextField(
                                        controller: _programToDateController,
                                        enabled: false,
                                        decoration: InputDecoration(
                                          hintText: 'dd-mm-yyyy',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 16,
                                              ),
                                          prefixIcon: Icon(
                                            Icons.calendar_today,
                                            color: const Color(0xFFF97316),
                                          ),
                                          suffixIcon: Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_programDateRangeError != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _programDateRangeError!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Instructional Text
                          // Text(
                          //   'Please enter your program dates. Your appointment will be scheduled during this period.',
                          //   style: TextStyle(
                          //     fontSize: 14,
                          //     color: const Color(0xFFF97316),
                          //     fontStyle: FontStyle.italic,
                          //   ),
                          // ),
                        ],
                        const SizedBox(height: 32),

                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFormValid && !_isSaving
                                ? _saveAppointment
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Saving Changes...'),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _performDeleteGuestCard(int guestNumber) {
    // Convert guestNumber to 0-based index
    int index = guestNumber - 1;

    if (index >= 0 && index < _guestControllers.length) {
      setState(() {
        // Dispose the controllers for this guest
        var guest = _guestControllers[index];
        guest['name']?.dispose();
        guest['phone']?.dispose();
        guest['age']?.dispose();

        // Remove the guest from the list
        _guestControllers.removeAt(index);

        // Remove associated data
        _guestCountries.remove(guestNumber);
        _guestImages.remove(guestNumber);
        _guestUploading.remove(guestNumber);

        // Update the number of users (just accompanying users)
        _numberOfUsersController.text = _guestControllers.length.toString();

        // Update form validation
        _validateForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Person $guestNumber has been deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPhotoValidationErrorDialog(
    String errorMessage,
    VoidCallback onTryAgain,
  ) {
    // Remove "Guest X:" prefix if present
    String cleanErrorMessage = errorMessage;
    if (cleanErrorMessage.contains('Guest ') &&
        cleanErrorMessage.contains(': ')) {
      cleanErrorMessage = cleanErrorMessage.split(': ').skip(1).join(': ');
    }

    // Remove "Profile photo validation failed:" prefix if present
    if (cleanErrorMessage.startsWith('Profile photo validation failed:')) {
      cleanErrorMessage = cleanErrorMessage
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
                      cleanErrorMessage,
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
}
