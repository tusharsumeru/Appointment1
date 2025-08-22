import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/common/location_bottom_sheet.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import 'user_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../components/user/photo_validation_bottom_sheet.dart';

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
  final TextEditingController _referenceNameController = TextEditingController();
  final TextEditingController _referenceEmailController = TextEditingController();
  final TextEditingController _referencePhoneController = TextEditingController();
  
  // Guest Information Controllers
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _guestDesignationController = TextEditingController();
  final TextEditingController _guestCompanyController = TextEditingController();
  final TextEditingController _guestLocationController = TextEditingController();
  
  // Form state
  bool _isFormValid = false;
  String? _selectedSecretary;
  String? _selectedAppointmentLocation;
  String? _selectedLocationId; // Store the selected location ID (locationId for API calls)
  String? _selectedLocationMongoId; // Store the MongoDB _id for form submission
  File? _selectedImage;
  File? _selectedAttachment; // For file attachments
  bool _isAttendingProgram = false;
  
  // Guest information state
  List<Map<String, TextEditingController>> _guestControllers = [];

  // Guest images state - Map to store S3 URLs for each guest
  Map<int, String> _guestImages = {};
  // Guest upload states - Map to track upload status for each guest
  Map<int, bool> _guestUploading = {};
  
  // Location search state
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocations = false;
  String _lastSearchQuery = '';
  
  // Main guest photo state
  String? _mainGuestPhotoUrl;
  bool _isMainGuestPhotoUploading = false;

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

  @override
  void initState() {
    super.initState();
    // Initialize numberOfUsers to 0 by default
    _numberOfUsersController.text = '0';
    _validateForm();
    _loadLocations();
    _loadReferenceInfo();
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
    int accompanyUsersCount = int.tryParse(_numberOfUsersController.text) ?? 0;
    
    // If more than 10 accompany users, don't create dynamic cards
    if (accompanyUsersCount > 10) {
      // Clear all existing controllers and data
      for (var guest in _guestControllers) {
        guest['name']?.dispose();
        guest['phone']?.dispose();
        guest['age']?.dispose();
      }
      _guestControllers.clear();
      _guestImages.clear();
      _guestUploading.clear();
      _guestCountries.clear();
      
      setState(() {});
      _validateForm();
      return;
    }
    
    // If we're reducing the number of accompany users, dispose extra controllers from the end
    if (_guestControllers.length > accompanyUsersCount) {
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
      _guestControllers.removeRange(accompanyUsersCount, _guestControllers.length);
    }
    
    // If we need more accompany users, add them at the bottom (only if <= 10 accompany users total)
    while (_guestControllers.length < accompanyUsersCount) {
      int guestNumber = _guestControllers.length + 1;
      
      Map<String, TextEditingController> controllers = {
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'age': TextEditingController(),
      };
      _guestControllers.add(controllers);
      
      // Initialize country for new guest
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
    
    setState(() {});
    _validateForm();
  }

  // Helper method to parse date string to DateTime
  DateTime? _parseDateString(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }

  // Helper method to validate date range
  bool _isValidDateRange(String fromDate, String toDate) {
    if (fromDate.isEmpty || toDate.isEmpty) return true; // Let other validation handle empty dates
    
    final fromDateTime = _parseDateString(fromDate);
    final toDateTime = _parseDateString(toDate);
    
    if (fromDateTime == null || toDateTime == null) return true; // Let other validation handle invalid dates
    
    return fromDateTime.isBefore(toDateTime);
  }

  // Helper method to validate date range and set error message
  bool _validateDateRange(String fromDate, String toDate, {String errorType = 'appointment'}) {
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
      _programDateRangeError = isValid ? null : 'Program start date must be before program end date';
    }
    
    return isValid;
  }

  void _validateForm() {
    bool basicFormValid = _appointmentPurposeController.text.isNotEmpty &&
        _fromDateController.text.isNotEmpty &&
        _toDateController.text.isNotEmpty;
    
    // Validate date ranges
    bool dateRangeValid = _validateDateRange(_fromDateController.text, _toDateController.text, errorType: 'appointment');
    
    // Validate program date ranges if attending a program
    bool programDateRangeValid = true;
    if (_isAttendingProgram) {
      programDateRangeValid = _validateDateRange(_fromDateController.text, _toDateController.text, errorType: 'program');
    }
    
    // Validate main guest phone number if appointment type is guest
    bool mainGuestPhoneValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      if (_guestPhoneController.text.isEmpty || _guestPhoneController.text.length != 10) {
        mainGuestPhoneValid = false;
      }
    }
    
    // Validate main guest email if appointment type is guest
    bool mainGuestEmailValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      mainGuestEmailValid = _guestEmailError == null && _guestEmailController.text.isNotEmpty;
    }
    
    // Validate main guest photo if appointment type is guest
    bool mainGuestPhotoValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      if (_mainGuestPhotoUrl == null) {
        mainGuestPhotoValid = false;
      }
    }
    
    // Validate guest information if any (only for <= 10 accompany users)
    bool guestFormValid = true;
    final accompanyUsersCount = int.tryParse(_numberOfUsersController.text) ?? 0;
    
    if (accompanyUsersCount > 10) {
      // For more than 10 accompany users, no guest validation needed
      guestFormValid = true;
    } else {
      // Validate individual guest details for <= 10 accompany users
      for (int i = 0; i < _guestControllers.length; i++) {
        var guest = _guestControllers[i];
        int guestNumber = i + 1;
        
        if (guest['name']?.text.isEmpty == true ||
            guest['phone']?.text.isEmpty == true ||
            guest['phone']?.text.length != 10 ||
            guest['age']?.text.isEmpty == true) {
          guestFormValid = false;
          break;
        }
        
        // Check if photo is required and provided for guests aged 12+
        final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
        if (age >= 12 && !_guestImages.containsKey(guestNumber)) {
          guestFormValid = false;
          break;
        }
      }
    }
    
    setState(() {
      _isFormValid = basicFormValid && dateRangeValid && programDateRangeValid && mainGuestPhoneValid && mainGuestEmailValid && mainGuestPhotoValid && guestFormValid;
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Show uploading state
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isMainGuestPhotoUploading = true;
      });

      try {
        // Upload photo immediately and get S3 URL
        final result = await ActionService.uploadAndValidateProfilePhoto(File(pickedFile.path));

        if (result['success']) {
          final s3Url = result['s3Url'];

          setState(() {
            _mainGuestPhotoUrl = s3Url;
            _isMainGuestPhotoUploading = false;
          });
          
          // Update form validation
          _validateForm();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Main guest photo uploaded and validated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _isMainGuestPhotoUploading = false;
          });
          
          // Update form validation
          _validateForm();

          // Show backend error message in dialog
          final errorMessage = result['error'] ?? result['message'] ?? 'Photo validation failed';
          _showPhotoValidationErrorDialog(errorMessage, () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImage = null;
              _mainGuestPhotoUrl = null;
              _isMainGuestPhotoUploading = false;
            });
          });
        }
      } catch (e) {
        setState(() {
          _isMainGuestPhotoUploading = false;
        });
        
        // Update form validation
        _validateForm();

        // Show error message in dialog
        _showPhotoValidationErrorDialog('Error uploading photo: ${e.toString()}', () {
          // Clear any previous state and allow user to pick again
          setState(() {
            _selectedImage = null;
            _mainGuestPhotoUrl = null;
            _isMainGuestPhotoUploading = false;
          });
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _mainGuestPhotoUrl = null;
    });
    
    // Update form validation
    _validateForm();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // File attachment methods
  Future<void> _pickAttachment() async {
    try {
      // Import file_picker at the top of the file
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

  // Guest image handling methods
  Future<void> _pickGuestImage(ImageSource source, int guestNumber) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Show uploading state
      setState(() {
        _guestUploading[guestNumber] = true;
      });
      
      try {
        // Upload photo immediately and get S3 URL
        final result = await ActionService.uploadAndValidateProfilePhoto(File(pickedFile.path));
        
        if (result['success']) {
          final s3Url = result['s3Url'];
          setState(() {
            _guestImages[guestNumber] = s3Url;
            _guestUploading[guestNumber] = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Guest $guestNumber photo uploaded and validated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _guestUploading[guestNumber] = false;
          });
          
          // Show backend error message in dialog
          final errorMessage = result['error'] ?? result['message'] ?? 'Photo validation failed';
          _showPhotoValidationErrorDialog('Guest $guestNumber: $errorMessage', () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _guestImages.remove(guestNumber);
              _guestUploading[guestNumber] = false;
            });
          });
        }
      } catch (e) {
        setState(() {
          _guestUploading[guestNumber] = false;
        });
        
        // Show error message in dialog
        _showPhotoValidationErrorDialog('Guest $guestNumber: Error uploading photo: ${e.toString()}', () {
          // Clear any previous state and allow user to pick again
          setState(() {
            _guestImages.remove(guestNumber);
            _guestUploading[guestNumber] = false;
          });
        });
      }
    }
  }

  void _removeGuestImage(int guestNumber) {
    setState(() {
      _guestImages.remove(guestNumber);
      _guestUploading.remove(guestNumber);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guest $guestNumber photo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Load ashram locations from API
  Future<void> _loadLocations() async {
    try {
      final result = await ActionService.getAshramLocations();
      
      if (result['success']) {
        final locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        setState(() {
          _locations = locations;
          _isLoadingLocations = false;
        });
      } else {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  // Load secretaries for selected location
  Future<void> _loadSecretariesForLocation(String locationId) async {
    try {
      setState(() {
        _isLoadingSecretaries = true;
        _secretaryErrorMessage = null;
      });

      final result = await ActionService.getAshramLocationByLocationId(
        locationId: locationId,
      );

      if (result['success']) {
        final locationData = result['data'];
        final assignedSecretaries = locationData['assignedSecretaries'] ?? [];
        
        // Transform the API response to match our expected format
        final List<Map<String, dynamic>> secretaries = [];
        
        for (var secretary in assignedSecretaries) {
          try {
            final secretaryData = secretary['secretaryId'] ?? secretary;
            secretaries.add({
              'id': secretaryData['_id']?.toString() ?? '',
              'name': secretaryData['fullName']?.toString() ?? '',
              'email': secretaryData['email']?.toString() ?? '',
              'role': secretaryData['role']?.toString() ?? '',
            });
          } catch (e) {
            // Error processing secretary data
          }
        }

        setState(() {
          _secretaries = secretaries;
          _isLoadingSecretaries = false;
        });
      } else {
        setState(() {
          _isLoadingSecretaries = false;
          _secretaryErrorMessage = result['message'] ?? 'Failed to load secretaries';
          _secretaries = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSecretaries = false;
        _secretaryErrorMessage = 'Network error: $e';
        _secretaries = [];
      });
    }
  }

  // Load reference information from API
  Future<void> _loadReferenceInfo() async {
    try {
      // First try to get fresh data from API
      final apiResult = await ActionService.getCurrentUser();
      
      Map<String, dynamic>? userData;
      
      if (apiResult['success'] == true) {
        userData = apiResult['data'];
      } else {
        userData = await StorageService.getUserData();
      }
      
      if (userData != null) {
        // Set initial values for reference fields
        final fullName = userData['fullName'] ?? userData['name'] ?? '';
        final email = userData['email'] ?? '';
        
        // Handle phone number object structure
        String phone = '';
        if (userData['phoneNumber'] != null) {
          if (userData['phoneNumber'] is Map<String, dynamic>) {
            final phoneObj = userData['phoneNumber'] as Map<String, dynamic>;
            final countryCode = phoneObj['countryCode'] ?? '';
            final number = phoneObj['number'] ?? '';
            phone = '$countryCode$number';
          } else {
            phone = userData['phoneNumber'].toString();
          }
        } else if (userData['phone'] != null) {
          phone = userData['phone'].toString();
        } else {
          phone = ''; // Explicitly set to empty string
        }
        
        setState(() {
          _referenceNameController.text = fullName;
          _referenceEmailController.text = email;
          _referencePhoneController.text = phone;
          _isLoadingReferenceInfo = false;
        });
      }
      
    } catch (error) {
      // Set default values if data loading fails
      setState(() {
        _referenceNameController.text = '';
        _referenceEmailController.text = '';
        _referencePhoneController.text = '';
        _isLoadingReferenceInfo = false;
      });
    }
  }

  void _submitForm() async {
    if (!_isFormValid) return;
    
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



      // Prepare personalInfo and ensure a structured phoneNumber object is available
      Map<String, dynamic> cleanedPersonalInfo = Map<String, dynamic>.from(widget.personalInfo);
      try {
        final phoneValue = cleanedPersonalInfo['phone'];
        if (phoneValue != null) {
          if (phoneValue is Map<String, dynamic>) {
            // If already object, also mirror as phoneNumber for backend compatibility
            cleanedPersonalInfo['phoneNumber'] = {
              'countryCode': phoneValue['countryCode'] ?? '',
              'number': phoneValue['number'] ?? '',
            };
          } else if (phoneValue is String) {
            final parsed = _parsePhoneStringToObject(phoneValue);
            cleanedPersonalInfo['phoneNumber'] = parsed;
          }
        }
      } catch (e) {
        // Could not normalize personalInfo phone
      }
      
      // Collect all form data
      Map<String, dynamic> appointmentData = {
        'meetingType': 'in_person', // Default value
        'appointmentFor': {
          'type': widget.personalInfo['appointmentType'] ?? 'myself',
          'personalInfo': cleanedPersonalInfo, // Use cleaned version
        },
        'userCurrentCompany': widget.personalInfo['company'] ?? '', // Changed from 'Sumeru Digital'
        'userCurrentDesignation': widget.personalInfo['designation'] ?? '', // Changed from 'Office Operations Specialist'
        'appointmentPurpose': _appointmentPurposeController.text.trim(),
        'appointmentSubject': _appointmentPurposeController.text.trim(),
        'appointmentLocation': _selectedLocationMongoId ?? '6889dbd15b943e342f660060',
        'assignedSecretary': _selectedSecretary, // Send null when no secretary is selected
        'numberOfUsers': (int.tryParse(_numberOfUsersController.text) ?? 0) + 1, // +1 for main user
      };

      // Priority-based date range logic
      if (_isAttendingProgram) {
        // FIRST PRIORITY: If attending program, use program dates for preferred date range
        appointmentData['preferredDateRange'] = {
          'fromDate': _parseDateToISO(_fromDateController.text),
          'toDate': _parseDateToISO(_toDateController.text),
        };
      } else {
        // SECOND PRIORITY: If not attending program, use preferred date range
        appointmentData['preferredDateRange'] = {
          'fromDate': _parseDateToISO(_fromDateController.text),
          'toDate': _parseDateToISO(_toDateController.text),
        };
      }
      


      // Add accompanyUsers if there are additional users (only for <= 10 accompany users)
      final accompanyUsersCount = int.tryParse(_numberOfUsersController.text) ?? 0;
      if (_guestControllers.isNotEmpty && accompanyUsersCount <= 10) {
        List<Map<String, dynamic>> accompanyUsers = [];
        for (int i = 0; i < _guestControllers.length; i++) {
          var guest = _guestControllers[i];
          int guestNumber = i + 1;
          
          // Backend expects phoneNumber as string, not object
          final countryCode = '+${_guestCountries[guestNumber]?.phoneCode ?? '91'}';
          final phoneNumber = guest['phone']?.text.trim() ?? '';
          final fullPhoneNumber = '$countryCode$phoneNumber';
          
          Map<String, dynamic> guestData = {
            'fullName': guest['name']?.text.trim() ?? '',
            'phoneNumber': fullPhoneNumber, // Send as string for backend compatibility
            'age': int.tryParse(guest['age']?.text ?? '0') ?? 0,
          };
          
          // Add photo if available for this guest
          if (_guestImages.containsKey(guestNumber)) {
            guestData['profilePhotoUrl'] = _guestImages[guestNumber];
          }
          
          accompanyUsers.add(guestData);
        }
        
        // Structure accompanyUsers as expected by backend
        appointmentData['accompanyUsers'] = {
          'numberOfUsers': accompanyUsers.length,
          'users': accompanyUsers,
        };
      } else if (accompanyUsersCount > 10) {
        // For more than 10 accompany users, just send the total count without individual details
        appointmentData['accompanyUsers'] = {
          'numberOfUsers': accompanyUsersCount, // Use the accompany users count as entered by user
          'users': [], // Empty array since individual details not required
        };
      }

      // Add guest information if appointment type is guest
      if (widget.personalInfo['appointmentType'] == 'guest') {
        // Backend expects phoneNumber as string, not object
        final countryCode = '+${_selectedCountry.phoneCode}';
        final phoneNumber = _guestPhoneController.text.trim();
        final fullPhoneNumber = '$countryCode$phoneNumber';
        
        Map<String, dynamic> guestInfo = {
          'fullName': _guestNameController.text.trim(),
          'emailId': _guestEmailController.text.trim(),
          'phoneNumber': fullPhoneNumber, // Send as string for backend compatibility
          'designation': _guestDesignationController.text.trim(),
          'company': _guestCompanyController.text.trim(),
          'location': _guestLocationController.text.trim(),
        };
        
        // Add main guest photo URL if available
        if (_mainGuestPhotoUrl != null) {
          guestInfo['profilePhotoUrl'] = _mainGuestPhotoUrl;
        }
        
        appointmentData['guestInformation'] = guestInfo;
      }

      // Add reference information if appointment type is guest
      if (widget.personalInfo['appointmentType'] == 'guest') {
        appointmentData['referenceInformation'] = {
          'fullName': _referenceNameController.text.trim(),
          'email': _referenceEmailController.text.trim(),
          'phoneNumber': _referencePhoneController.text.trim(), // Send as string
        };
      }

      // Add virtual meeting details if applicable
      if (_selectedAppointmentLocation == 'Virtual Meeting') {
        appointmentData['virtualMeetingDetails'] = {
          'platform': 'Zoom',
          'link': 'To be provided',
        };
      }

      // Add attending course details if applicable
      if (_isAttendingProgram) {
        appointmentData['attendingCourseDetails'] = {
          'courseName': 'General Program',
          'duration': '1 day',
          'fromDate': _parseDateToISO(_fromDateController.text),
          'toDate': _parseDateToISO(_toDateController.text),
        };
      }



      // Use ActionService.createAppointment method with attachment
      final result = await ActionService.createAppointment(
        appointmentData,
        attachmentFile: _selectedAttachment,
      );

      // Hide loading indicator
      Navigator.pop(context);

      if (result['success'] == true) {
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                              placeholder: 'Your name will appear here',
                              isReadOnly: true,
                            ),
                            const SizedBox(height: 12),
                            
                            // Reference Email
                            _buildReferenceField(
                              label: 'Reference Email',
                              controller: _referenceEmailController,
                              placeholder: 'Your email will appear here',
                              keyboardType: TextInputType.emailAddress,
                              isReadOnly: true,
                            ),
                            const SizedBox(height: 12),
                            
                            // Reference Phone
                            _buildReferencePhoneField(
                              label: 'Reference Phone',
                              controller: _referencePhoneController,
                              isReadOnly: true,
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
                      'Enter the details of the person you are requesting the appointment for',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Guest Full Name
                    _buildReferenceField(
                      label: 'Full Name of the Guest *',
                      controller: _guestNameController,
                      placeholder: 'Enter guest\'s full name',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Email
                    _buildEmailField(
                      label: 'Email ID of the Guest *',
                      controller: _guestEmailController,
                      placeholder: 'guest@email.com',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Mobile
                    _buildGuestPhoneFieldWithCountryPicker(),
                    const SizedBox(height: 16),
                    
                    // Guest Designation
                    _buildReferenceField(
                      label: 'Designation *',
                      controller: _guestDesignationController,
                      placeholder: 'Guest\'s professional title',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Company/Organization
                    _buildReferenceField(
                      label: 'Company/Organization *',
                      controller: _guestCompanyController,
                      placeholder: 'Guest\'s organization name',
                    ),
                    const SizedBox(height: 16),
                    
                    // Guest Location with Search
                    _buildLocationSearchField(),
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
                        // Show selected image preview
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isMainGuestPhotoUploading 
                                  ? Colors.blue[50] 
                                  : (_mainGuestPhotoUrl != null ? Colors.green[50] : Colors.orange[50]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isMainGuestPhotoUploading 
                                    ? Colors.blue[200]! 
                                    : (_mainGuestPhotoUrl != null ? Colors.green[200]! : Colors.orange[200]!),
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
                                          if (_isMainGuestPhotoUploading) ...[
                                            const Text(
                                              'Uploading photo...',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                              ),
                                            ),
                                          ] else if (_mainGuestPhotoUrl != null) ...[
                                            const Text(
                                              'Photo uploaded and validated successfully',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'S3 URL: ${_mainGuestPhotoUrl!.substring(0, 50)}...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ] else ...[
                                            const Text(
                                              'Photo Not uploaded,Retry Upload',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.orange,
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Show action buttons after successful upload
                                if (_mainGuestPhotoUrl != null) ...[
                                  const SizedBox(height: 12),
                                  
                                  // Action buttons - one below the other
                                  Column(
                                    children: [
                                      // Upload Different Photo
                                      GestureDetector(
                                        onTap: () => _pickImage(ImageSource.gallery),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.blue[200]!),
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
                                        onTap: () => _pickImage(ImageSource.camera),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange[200]!),
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
                                        onTap: _removeImage,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.red[200]!),
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
                         GestureDetector(
                           onTap: _pickAttachment,
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: Colors.grey.shade300),
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
                               border: Border.all(color: Colors.green.shade200),
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
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         _selectedAttachment!.path.split('/').last,
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
                                       borderRadius: BorderRadius.circular(4),
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
                   const SizedBox(height: 20),

                                     // Appointment Location
                   _buildLocationButton(),
                  const SizedBox(height: 20),

                  // Secretary Contact
                  _buildSecretaryButton(),
                  const SizedBox(height: 20),

                  // Number of Accompany Users with + and - buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accompany Users',
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
                              int currentCount = int.tryParse(_numberOfUsersController.text) ?? 0;
                              if (currentCount > 0) {
                                setState(() {
                                  _numberOfUsersController.text = (currentCount - 1).toString();
                                });
                                _updateGuestControllers();
                                _validateForm();
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Text(
                                  _numberOfUsersController.text.isEmpty ? '0' : _numberOfUsersController.text,
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
                              int currentCount = int.tryParse(_numberOfUsersController.text) ?? 0;
                              setState(() {
                                _numberOfUsersController.text = (currentCount + 1).toString();
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
                      const SizedBox(height: 4),
                      Text(
                        'Number of people accompanying you',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Guest Information Cards
                  if (_guestControllers.isNotEmpty) ...[
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
                      Map<String, TextEditingController> guest = entry.value;
                      return _buildGuestCard(index + 1, guest);
                    }).toList(),
                    const SizedBox(height: 20),
                  ] else if ((int.tryParse(_numberOfUsersController.text) ?? 0) > 10) ...[
                    // Show message for more than 10 accompany users
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
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
                              const Text(
                                'Large Group Appointment',
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
                            'For appointments with more than 10 accompany users, additional person details are not required.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
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
                    controller: _fromDateController,
                    onTap: () => _selectDate(context, _fromDateController),
                    errorMessage: _dateRangeError,
                  ),
                  const SizedBox(height: 20),

                  // To Date
                  _buildDateField(
                    label: 'To Date',
                    controller: _toDateController,
                    onTap: () => _selectDate(context, _toDateController),
                    errorMessage: _dateRangeError,
                  ),
                  const SizedBox(height: 20),

                  // Add Gurudev's Schedule Link
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
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Check Gurudev\'s Schedule',
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
                          'View Gurudev Sri Sri Ravi Shankar\'s tour schedule to plan your visit accordingly',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            _launchGurudevSchedule();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  color: Colors.blue.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Open Tour Schedule',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                              onTap: () => _selectDate(context, _fromDateController),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: _programDateRangeError != null ? Colors.red : const Color(0xFFF97316)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _fromDateController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: 'dd-mm-yyyy',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFFF97316)),
                                    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
                              onTap: () => _selectDate(context, _toDateController),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: _programDateRangeError != null ? Colors.red : const Color(0xFFF97316)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _toDateController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    hintText: 'dd-mm-yyyy',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFFF97316)),
                                    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
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
                    Text(
                      'Please enter your program dates. Your appointment will be scheduled during this period.',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFF97316),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
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
              borderSide: const BorderSide(color: Color(0xFFF97316)),
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



  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? errorMessage,
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
              border: Border.all(color: errorMessage != null ? Colors.red : Colors.grey[300]!),
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
        if (errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestCard(int guestNumber, Map<String, TextEditingController> guest) {
    // Check if photo is required (age >= 12)
    final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
    final isPhotoRequired = age >= 12;
    
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
                    'Accompany User $guestNumber',
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
            _buildAdditionalGuestPhoneField(guestNumber, guest['phone']!),
            const SizedBox(height: 16),
            
            // Age
            _buildGuestTextField(
              label: 'Age',
              controller: guest['age']!,
              placeholder: 'Enter age',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _validateForm();
                setState(() {}); // Rebuild to show/hide photo section
              },
            ),
            
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Photo Upload Options
              Column(
                children: [
                  // Upload from Device Card
                  GestureDetector(
                    onTap: () => _pickGuestImage(ImageSource.gallery, guestNumber),
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
                    onTap: () => _pickGuestImage(ImageSource.camera, guestNumber),
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
                  
                  // Show upload status
                  if (_guestUploading[guestNumber] == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Uploading and validating photo...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Please wait',
                                  style: TextStyle(
                                    fontSize: 10,
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
                  
                  // Show selected image preview for this guest
                  if (_guestImages.containsKey(guestNumber)) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo preview and success message
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.grey[200],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _guestImages[guestNumber] != null
                                      ? Image.network(
                                          _guestImages[guestNumber]!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Photo uploaded successfully',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'S3 URL: ${_guestImages[guestNumber]!.substring(0, 30)}...',
                                      style: TextStyle(
                                        fontSize: 10,
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
                                onTap: () => _pickGuestImage(ImageSource.gallery, guestNumber),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.blue[200]!),
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
                                onTap: () => _pickGuestImage(ImageSource.camera, guestNumber),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.orange[200]!),
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
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red[200]!),
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
    bool isReadOnly = false,
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
          keyboardType: keyboardType,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
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
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _guestEmailError != null ? Colors.red : Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _guestEmailError != null ? Colors.red : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _guestEmailError != null ? Colors.red : Colors.deepPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              // Validate email on change
              if (value.isEmpty) {
                _guestEmailError = 'Email is required';
              } else {
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReferencePhoneField({
    required String label,
    required TextEditingController controller,
    bool isReadOnly = false,
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
        // Phone Number Field (without country code)
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            hintText: 'Enter phone number',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
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

   // Build location button that opens bottom sheet
   Widget _buildLocationButton() {
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
                 Icon(
                   Icons.location_on,
                   color: const Color(0xFFF97316),
                   size: 20,
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: _isLoadingLocations
                       ? Row(
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
                         )
                       : Text(
                           _selectedAppointmentLocation ?? 'Select a location',
                           style: TextStyle(
                             color: _selectedAppointmentLocation != null 
                                 ? Colors.black87 
                                 : Colors.grey[600],
                             fontSize: 16,
                           ),
                         ),
                 ),
                 Icon(
                   Icons.arrow_drop_down,
                   color: Colors.grey[600],
                   size: 24,
                 ),
               ],
             ),
           ),
         ),
       ],
     );
   }

   // Show location bottom sheet
   void _showLocationBottomSheet() {
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       backgroundColor: Colors.transparent,
       builder: (context) => DraggableScrollableSheet(
         initialChildSize: 0.6,
         minChildSize: 0.4,
         maxChildSize: 0.9,
         builder: (context, scrollController) => LocationBottomSheet(
           locations: _locations,
           selectedLocation: _selectedAppointmentLocation,
           isLoading: _isLoadingLocations,
           onLocationSelected: (locationName) {
             setState(() {
               _selectedAppointmentLocation = locationName;
               // Find and store the corresponding location ID
               if (locationName != null) {
                 final selectedLocation = _locations.firstWhere(
                   (location) => location['name'] == locationName,
                   orElse: () => {},
                 );
                 _selectedLocationId = selectedLocation['locationId'];
                 _selectedLocationMongoId = selectedLocation['_id'];
                 
                 // Load secretaries for the selected location
                 if (_selectedLocationId != null) {
                   _loadSecretariesForLocation(_selectedLocationId!);
                 }
               } else {
                 _selectedLocationId = null;
                 _selectedLocationMongoId = null;
                 // Clear secretaries when no location is selected
                 setState(() {
                   _secretaries = [];
                   _selectedSecretary = null;
                 });
               }
             });
             _validateForm();
           },
         ),
       ),
     );
   }

   // Build secretary dropdown with dynamic data
   Widget _buildSecretaryDropdown() {
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
         
         // Show loading state
         if (_isLoadingSecretaries) ...[
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey[300]!),
               borderRadius: BorderRadius.circular(8),
               color: Colors.grey[50],
             ),
             child: Row(
               children: [
                 const SizedBox(
                   width: 16,
                   height: 16,
                   child: CircularProgressIndicator(strokeWidth: 2),
                 ),
                 const SizedBox(width: 12),
                 Text(
                   'Loading secretaries...',
                   style: TextStyle(color: Colors.grey[600]),
                 ),
               ],
             ),
           ),
         ] else if (_secretaryErrorMessage != null) ...[
           // Show error state
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.red[300]!),
               borderRadius: BorderRadius.circular(8),
               color: Colors.red[50],
             ),
             child: Row(
               children: [
                 Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     _secretaryErrorMessage!,
                     style: TextStyle(color: Colors.red[600], fontSize: 14),
                   ),
                 ),
               ],
             ),
           ),
         ] else if (_selectedLocationId == null) ...[
           // Show placeholder when no location is selected
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey[300]!),
               borderRadius: BorderRadius.circular(8),
               color: Colors.grey[50],
             ),
             child: Text(
               'Please select a location first',
               style: TextStyle(color: Colors.grey[600]),
             ),
           ),
         ] else if (_secretaries.isEmpty) ...[
           // Show no secretaries available
           Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
             decoration: BoxDecoration(
               border: Border.all(color: Colors.orange[300]!),
               borderRadius: BorderRadius.circular(8),
               color: Colors.orange[50],
             ),
             child: Row(
               children: [
                 Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                     'No secretaries available for this location',
                     style: TextStyle(color: Colors.orange[600], fontSize: 14),
                   ),
                 ),
               ],
             ),
           ),
         ] else ...[
           // Show secretary dropdown
           Container(
             decoration: BoxDecoration(
               border: Border.all(color: Colors.grey[300]!),
               borderRadius: BorderRadius.circular(8),
             ),
             child: DropdownButtonFormField<String>(
               value: _selectedSecretary,
               decoration: const InputDecoration(
                 border: InputBorder.none,
                 contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
               ),
               items: [
                 // Add "Select a secretary" option
                 const DropdownMenuItem<String>(
                   value: null,
                   child: Text('Select a secretary'),
                 ),
                 // Add secretary options
                 ..._secretaries.map((secretary) {
                   return DropdownMenuItem<String>(
                     value: secretary['id'],
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(
                           secretary['name'],
                           style: const TextStyle(fontWeight: FontWeight.w500),
                         ),
                         if (secretary['email'] != null && secretary['email'].isNotEmpty)
                           Text(
                             secretary['email'],
                             style: TextStyle(
                               fontSize: 12,
                               color: Colors.grey[600],
                             ),
                           ),
                       ],
                     ),
                   );
                 }).toList(),
               ],
               onChanged: (value) {
                 setState(() {
                   _selectedSecretary = value;
                 });
                 _validateForm();
               },
               icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
             ),
           ),
         ],
       ],
     );
   }

   // Build secretary button that opens bottom sheet
   Widget _buildSecretaryButton() {
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
               border: Border.all(
                 color: _getSelectedSecretaryName() != null && _getSelectedSecretaryName() != 'None - I am not in touch with any secretary'
                     ? const Color(0xFFF97316)
                     : Colors.grey[300]!,
               ),
               borderRadius: BorderRadius.circular(8),
               color: Colors.white,
             ),
             child: Row(
               children: [
                 Icon(
                   Icons.person,
                   color: const Color(0xFFF97316),
                   size: 20,
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: _isLoadingSecretaries
                       ? Row(
                           children: [
                             const SizedBox(
                               width: 16,
                               height: 16,
                               child: CircularProgressIndicator(strokeWidth: 2),
                             ),
                             const SizedBox(width: 12),
                             Text(
                               'Loading secretaries...',
                               style: TextStyle(color: Colors.grey[600]),
                             ),
                           ],
                         )
                       : _secretaryErrorMessage != null
                           ? Row(
                               children: [
                                 Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                                 const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     _secretaryErrorMessage!,
                                     style: TextStyle(color: Colors.red[600], fontSize: 14),
                                   ),
                                 ),
                               ],
                             )
                           : _selectedLocationId == null
                               ? Text(
                                   'Please select a location first',
                                   style: TextStyle(color: Colors.grey[600]),
                                 )
                               : Text(
                                   _getSelectedSecretaryName() ?? 'Select a secretary',
                                   style: TextStyle(
                                     color: _getSelectedSecretaryName() != null && _getSelectedSecretaryName() != 'None - I am not in touch with any secretary'
                                         ? Colors.black87 
                                         : Colors.grey[600],
                                     fontSize: 16,
                                   ),
                                 ),
                 ),
                 Icon(
                   Icons.arrow_drop_down,
                   color: Colors.grey[600],
                   size: 24,
                 ),
               ],
             ),
           ),
         ),
       ],
     );
   }

     // Get selected secretary name
  String? _getSelectedSecretaryName() {
    if (_selectedSecretary == null) return 'None - I am not in touch with any secretary';
    final selectedSecretary = _secretaries.firstWhere(
      (secretary) => secretary['id'] == _selectedSecretary,
      orElse: () => {},
    );
    return selectedSecretary['name'] ?? '';
  }

   // Show secretary bottom sheet
   void _showSecretaryBottomSheet() {
     if (_selectedLocationId == null || _isLoadingSecretaries || _secretaryErrorMessage != null) {
       return; // Don't show bottom sheet if conditions aren't met
     }

     showModalBottomSheet(
       context: context,
       isDismissible: true, // Close when tapping outside
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
                   // None option at the top
                   ListTile(
                     leading: CircleAvatar(
                       backgroundColor: _selectedSecretary == null ? const Color(0xFFF97316) : Colors.grey[300],
                       child: Icon(
                         Icons.person_off,
                         color: _selectedSecretary == null ? Colors.white : Colors.grey[600],
                         size: 20,
                       ),
                     ),
                                            title: Text(
                         'None - I am not in touch with any secretary',
                         style: TextStyle(
                           fontWeight: _selectedSecretary == null ? FontWeight.w600 : FontWeight.normal,
                           color: _selectedSecretary == null ? const Color(0xFFF97316) : Colors.black87,
                         ),
                       ),
                       trailing: _selectedSecretary == null ? const Icon(Icons.check_circle, color: Color(0xFFF97316)) : null,
                     onTap: () {
                       setState(() {
                         _selectedSecretary = null;
                       });
                       _validateForm();
                       Navigator.pop(context);
                     },
                   ),
                   
                   // Divider between None and secretary options
                   const Divider(height: 1),
                   
                   // Show message if no secretaries available
                   if (_secretaries.isEmpty) ...[
                     Padding(
                       padding: const EdgeInsets.all(16),
                       child: Text(
                         'No secretaries available for this location',
                         style: TextStyle(
                           color: Colors.grey[600],
                           fontSize: 14,
                           fontStyle: FontStyle.italic,
                         ),
                         textAlign: TextAlign.center,
                       ),
                     ),
                   ] else ...[
                     // Secretary options
                     ..._secretaries.map((secretary) {
                     final secretaryName = secretary['name'] ?? 'Unknown Secretary';
                     final isSelected = _selectedSecretary == secretary['id'];
                     
                     return ListTile(
                       leading: CircleAvatar(
                         backgroundColor: isSelected ? const Color(0xFFF97316) : Colors.grey[300],
                         child: Text(
                           secretaryName.isNotEmpty ? secretaryName[0].toUpperCase() : '?',
                           style: TextStyle(
                             color: isSelected ? Colors.white : Colors.grey[600],
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       title: Text(
                         secretaryName,
                         style: TextStyle(
                           fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                           color: isSelected ? const Color(0xFFF97316) : Colors.black87,
                         ),
                       ),
                       trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFF97316)) : null,
                       onTap: () {
                         setState(() {
                           _selectedSecretary = secretary['id'];
                         });
                         _validateForm();
                         Navigator.pop(context);
                       },
                     );
                   }).toList(),
                   ],
                 ],
               ),
             ),
             
             SizedBox(height: MediaQuery.of(context).padding.bottom),
           ],
         ),
       ),
     );
   }

   // Build guest phone field with country picker
   Widget _buildGuestPhoneFieldWithCountryPicker() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
           'Mobile No. of the Guest *',
           style: TextStyle(
             fontSize: 16,
             fontWeight: FontWeight.w500,
             color: Colors.black87,
           ),
         ),
         const SizedBox(height: 8),
         Row(
           children: [
             // Country Code Button
             GestureDetector(
               onTap: () {
                 showCountryPicker(
                   context: context,
                   showPhoneCode: true,
                   countryListTheme: CountryListThemeData(
                     flagSize: 25,
                     backgroundColor: Colors.white,
                     textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
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
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey[300]!),
                   borderRadius: BorderRadius.circular(8),
                   color: Colors.white,
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       _selectedCountry.flagEmoji,
                       style: const TextStyle(fontSize: 18),
                     ),
                     const SizedBox(width: 8),
                     Text(
                       '+${_selectedCountry.phoneCode}',
                       style: const TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w500,
                         color: Colors.black87,
                       ),
                     ),
                     const SizedBox(width: 4),
                     Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 20),
                   ],
                 ),
               ),
             ),
             const SizedBox(width: 8),
             // Phone Number Field
             Expanded(
               child: TextField(
                 controller: _guestPhoneController,
                 keyboardType: TextInputType.phone,
                 maxLength: 10,
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                 ],
                 onChanged: (value) {
                   // Validate phone number length
                   if (value.length == 10) {
                     // Phone number is valid
                     setState(() {});
                   }
                 },
                 decoration: InputDecoration(
                   hintText: 'Enter 10-digit phone number',
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
                   errorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.red[300]!),
                   ),
                   focusedErrorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.red[500]!),
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                   counterText: '',
                   errorText: _guestPhoneController.text.isNotEmpty && _guestPhoneController.text.length != 10
                       ? 'Phone number must be 10 digits'
                       : null,
                 ),
               ),
             ),
           ],
         ),
       ],
     );
   }

   // Build additional guest phone field with country picker
   Widget _buildAdditionalGuestPhoneField(int guestNumber, TextEditingController controller) {
     final country = _guestCountries[guestNumber] ?? _selectedCountry;
     
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Text(
           'Contact Number *',
           style: TextStyle(
             fontSize: 14,
             fontWeight: FontWeight.w500,
             color: Colors.black87,
           ),
         ),
         const SizedBox(height: 6),
         Row(
           children: [
             // Country Code Button
             GestureDetector(
               onTap: () {
                 showCountryPicker(
                   context: context,
                   showPhoneCode: true,
                   countryListTheme: CountryListThemeData(
                     flagSize: 25,
                     backgroundColor: Colors.white,
                     textStyle: const TextStyle(fontSize: 16, color: Colors.black87),
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
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey[300]!),
                   borderRadius: BorderRadius.circular(8),
                   color: Colors.grey[50],
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       country.flagEmoji,
                       style: const TextStyle(fontSize: 16),
                     ),
                     const SizedBox(width: 6),
                     Text(
                       '+${country.phoneCode}',
                       style: const TextStyle(
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                         color: Colors.black87,
                       ),
                     ),
                     const SizedBox(width: 2),
                     Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 18),
                   ],
                 ),
               ),
             ),
             const SizedBox(width: 8),
             // Phone Number Field
             Expanded(
               child: TextField(
                 controller: controller,
                 keyboardType: TextInputType.phone,
                 maxLength: 10,
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                 ],
                 onChanged: (value) {
                   _validateForm();
                   // Validate phone number length
                   if (value.length == 10) {
                     // Phone number is valid
                     setState(() {});
                   }
                 },
                 decoration: InputDecoration(
                   hintText: 'Enter 10-digit phone number',
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
                   errorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.red[300]!),
                   ),
                   focusedErrorBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(8),
                     borderSide: BorderSide(color: Colors.red[500]!),
                   ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                   counterText: '',
                   errorText: controller.text.isNotEmpty && controller.text.length != 10
                       ? 'Phone number must be 10 digits'
                       : null,
                 ),
               ),
             ),
           ],
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
       // Error parsing date
     }
     
     // Return current date as fallback
     return DateTime.now().toUtc().toIso8601String();
   }
  
  // Helper to parse a string like "+919876543210" or "9876543210" into { countryCode, number }
  Map<String, String> _parsePhoneStringToObject(String value, {String defaultCode = '+91'}) {
    try {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return {'countryCode': defaultCode, 'number': ''};
      }
      // If it already starts with +, split code and number by first non-digit after +
      if (trimmed.startsWith('+')) {
        final codeMatch = RegExp(r'^\+(\d{1,4})').firstMatch(trimmed);
        if (codeMatch != null) {
          final code = '+${codeMatch.group(1)!}';
          final rest = trimmed.substring(codeMatch.end).replaceAll(RegExp(r'\D'), '');
          return {'countryCode': code, 'number': rest};
        }
      }
      // Otherwise fallback to default code and remove non-digits
      final onlyDigits = trimmed.replaceAll(RegExp(r'\D'), '');
      return {'countryCode': defaultCode, 'number': onlyDigits};
    } catch (e) {
      return {'countryCode': defaultCode, 'number': ''};
    }
  }

  // Location search functionality
  Future<void> _searchLocations(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    // Don't search if query is too short
    if (query.trim().length < 3) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    // Don't search if it's the same query
    if (_lastSearchQuery == query.trim()) {
      return;
    }

    setState(() {
      _isSearchingLocations = true;
      _lastSearchQuery = query.trim();
    });

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'AppointmentApp/1.0', // Required by Nominatim
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        final List<Map<String, dynamic>> suggestions = data.map((item) {
          final address = item['address'] as Map<String, dynamic>? ?? {};
          final displayName = item['display_name'] as String? ?? '';
          
          // Create a formatted display name
          String formattedName = displayName;
          if (address.isNotEmpty) {
            final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
            final state = address['state'] ?? '';
            final country = address['country'] ?? '';
            
            if (city.isNotEmpty && state.isNotEmpty) {
              formattedName = '$city, $state';
              if (country.isNotEmpty) {
                formattedName += ', $country';
              }
            }
          }
          
          return {
            'display_name': formattedName,
            'full_display_name': displayName,
            'lat': item['lat']?.toString() ?? '',
            'lon': item['lon']?.toString() ?? '',
            'type': item['type']?.toString() ?? '',
            'address': address,
          };
        }).toList();

        setState(() {
          _locationSuggestions = suggestions;
          _isSearchingLocations = false;
        });
        
        // Found location suggestions
      } else {
        setState(() {
          _locationSuggestions = [];
          _isSearchingLocations = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationSuggestions = [];
        _isSearchingLocations = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    final displayName = location['display_name'] as String? ?? '';
    _guestLocationController.text = displayName;
    
    setState(() {
      _locationSuggestions = [];
      _isSearchingLocations = false;
    });
  }

  void _clearLocationSuggestions() {
    setState(() {
      _locationSuggestions = [];
      _isSearchingLocations = false;
    });
  }

  // Build location search field with dropdown
  Widget _buildLocationSearchField() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        
        // Search input field
        TextField(
          controller: _guestLocationController,
          onChanged: (value) {
            // Debounce the search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_guestLocationController.text == value) {
                _searchLocations(value);
              }
            });
          },
          onTap: () {
            // Show suggestions if there's text
            if (_guestLocationController.text.isNotEmpty) {
              _searchLocations(_guestLocationController.text);
            }
          },
          decoration: InputDecoration(
            hintText: 'Start typing guest\'s location...',
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
            suffixIcon: _isSearchingLocations
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _guestLocationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _guestLocationController.clear();
                          _clearLocationSuggestions();
                        },
                      )
                    : const Icon(Icons.search, color: Colors.grey),
          ),
        ),
        
        // Location suggestions dropdown
        if (_locationSuggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
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
              itemCount: _locationSuggestions.length,
              itemBuilder: (context, index) {
                final location = _locationSuggestions[index];
                final displayName = location['display_name'] as String? ?? '';
                final type = location['type'] as String? ?? '';
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getLocationIcon(type),
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: type.isNotEmpty
                      ? Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                      : null,
                  onTap: () => _selectLocation(location),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // Get appropriate icon for location type
  IconData _getLocationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'city':
      case 'town':
        return Icons.location_city;
      case 'village':
        return Icons.location_on;
      case 'state':
      case 'province':
        return Icons.map;
      case 'country':
        return Icons.public;
      case 'suburb':
      case 'neighbourhood':
        return Icons.home;
      case 'street':
      case 'road':
        return Icons.directions;
      default:
        return Icons.location_on;
    }
  }

  void _launchGurudevSchedule() async {
    const url = 'https://gurudev.artofliving.org/tour-schedule/';
    
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Show URL in a dialog instead
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Gurudev\'s Tour Schedule'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please visit the following URL to check Gurudev\'s schedule:'),
                const SizedBox(height: 12),
                SelectableText(
                  url,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL copied to clipboard'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Copy URL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPhotoValidationErrorDialog(String errorMessage, VoidCallback onTryAgain) {
    // Remove "Guest X:" prefix if present
    String cleanErrorMessage = errorMessage;
    if (cleanErrorMessage.contains('Guest ') && cleanErrorMessage.contains(': ')) {
      cleanErrorMessage = cleanErrorMessage.split(': ').skip(1).join(': ');
    }
    
    // Remove "Profile photo validation failed:" prefix if present
    if (cleanErrorMessage.startsWith('Profile photo validation failed:')) {
      cleanErrorMessage = cleanErrorMessage.replaceFirst('Profile photo validation failed:', '').trim();
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 