import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../../action/action.dart';
import '../../action/storage_service.dart';
import '../../action/jwt_utils.dart';
import '../../components/user/photo_validation_bottom_sheet.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const EditAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  late TextEditingController _purposeController;
  late TextEditingController _numberOfPeopleController;
  late TextEditingController _fromDateController;
  late TextEditingController _toDateController;
  TextEditingController _companyController = TextEditingController();
  TextEditingController _designationController = TextEditingController();
  
  // Controllers for guest information fields
  late TextEditingController _guestFullNameController;
  late TextEditingController _guestEmailController;
  late TextEditingController _guestPhoneController;
  late TextEditingController _guestDesignationController;
      late TextEditingController _guestCompanyController;
    late TextEditingController _guestLocationController;
    
    // Location autocomplete state
    List<String> _locationSuggestions = [];
    bool _isLoadingGuestLocations = false;
    Timer? _locationDebounceTimer;
    
    // Loading state
  bool _isSubmitting = false;
  
  // Form state
  String? _selectedLocation;
  String? _selectedSecretary;
  String _teacherStatus = 'no';
  
  // Secretary data (same as assign_form.dart)
  List<Map<String, dynamic>> _availableAssignees = [];
  bool _isLoadingSecretaries = true;
  String? _secretaryErrorMessage;
  String? _currentUserId;
  String? _assignedSecretaryId;
  
  // Location data
  List<Map<String, dynamic>> _availableLocations = [];
  bool _isLoadingLocations = true;
  String? _locationErrorMessage;
  
  // Attachment data
  PlatformFile? _selectedFile;
  bool _isPickingFile = false;
  
  // Guest information data
  List<Map<String, dynamic>> _guests = [];
  
  // Guest controllers for editable fields (similar to user edit screen)
  List<Map<String, TextEditingController>> _guestControllers = [];
  Map<int, String> _guestImages = {};
  Map<int, bool> _guestUploading = {};
  Map<int, String> _guestCountries = {};
  
  // Photo picker for guests
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _debugAppointmentStructure(); // Debug the appointment structure
    _initializeControllers();
    _loadCurrentUser();
    _loadSecretaries();
    _loadLocations();
  }

  void _initializeControllers() {
    _purposeController = TextEditingController(
      text: widget.appointment['appointmentPurpose']?.toString() ?? '',
    );
    
    _companyController.text = _getCreatedByCompany();
    _designationController.text = _getCreatedByDesignation();
    
    // Get total number of users from accompanyUsers object
    String numberOfPeople = '1'; // Default to 1 (main user)
    final accompanyUsers = widget.appointment['accompanyUsers'];
    
    if (accompanyUsers is Map<String, dynamic>) {
      final numberOfUsers = accompanyUsers['numberOfUsers'];
      if (numberOfUsers != null) {
        // numberOfUsers represents accompanying users, so total = numberOfUsers + 1 (main user)
        numberOfPeople = (numberOfUsers + 1).toString();
      }
      
      // Log the users array
      final users = accompanyUsers['users'];
      if (users is List) {
        // Process users if needed
      }
    }
    _numberOfPeopleController = TextEditingController(
      text: numberOfPeople,
    );
    
    // Initialize guest information from existing data
    _initializeGuestData();
    
    // Initialize guest information controllers
    _guestFullNameController = TextEditingController(text: _getGuestFullName());
    _guestEmailController = TextEditingController(text: _getGuestEmail());
    _guestPhoneController = TextEditingController(text: _getGuestPhone());
    _guestDesignationController = TextEditingController(text: _getGuestDesignation());
    _guestCompanyController = TextEditingController(text: _getGuestCompany());
    _guestLocationController = TextEditingController(text: _getGuestLocation());
    
    // Initialize guest photo state
    final existingGuestPhotoUrl = _getGuestPhotoUrl();
    if (existingGuestPhotoUrl.isNotEmpty) {
      _guestImages[0] = existingGuestPhotoUrl;
    }
    
    // Add listener to update guest controllers when number of people changes
    _numberOfPeopleController.addListener(_updateGuestControllers);
    
    // Initialize date controllers
    final preferredDateRange = widget.appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate']?.toString() ?? '';
      final toDate = preferredDateRange['toDate']?.toString() ?? '';
      
      // Convert ISO date format to YYYY-MM-DD format
      String formattedFromDate = '';
      String formattedToDate = '';
      
      if (fromDate.isNotEmpty) {
        try {
          final date = DateTime.parse(fromDate);
          formattedFromDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          formattedFromDate = fromDate;
        }
      }
      
      if (toDate.isNotEmpty) {
        try {
          final date = DateTime.parse(toDate);
          formattedToDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          formattedToDate = toDate;
        }
      }
      
      _fromDateController = TextEditingController(text: formattedFromDate);
      _toDateController = TextEditingController(text: formattedToDate);
    } else {
      _fromDateController = TextEditingController();
      _toDateController = TextEditingController();
    }
    
    // Initialize other fields
    final locationId = _getLocationId();
    final secretaryId = _getSecretaryId();
    
    // Set the currently assigned secretary as selected
    final assignedSecretary = widget.appointment['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      _selectedSecretary = assignedSecretary['_id']?.toString();
    } else {
      // Fallback to secretary field if assignedSecretary is not available
      _selectedSecretary = secretaryId.isNotEmpty ? secretaryId : null;
    }
    
    // Only set values if they are not empty
    _selectedLocation = locationId.isNotEmpty ? locationId : null;
    _teacherStatus = _getTeacherStatus();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _numberOfPeopleController.removeListener(_updateGuestControllers);
    _numberOfPeopleController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    
    // Dispose guest information controllers
    _guestFullNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _guestDesignationController.dispose();
    _guestCompanyController.dispose();
    _guestLocationController.dispose();
    _locationDebounceTimer?.cancel();
    
    // Dispose guest controllers
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
      guest['uniquePhoneCode']?.dispose();
    }
    
    super.dispose();
  }

  String _getLocationId() {
    final appointmentLocation = widget.appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final locationId = appointmentLocation['_id']?.toString() ?? '';
      // Check if the location ID exists in our dropdown options
      final locationOptions = [
        '6881bac36d6c111012d085ea',
        '6881baa26d6c111012d085b3',
        '6881b9626d6c111012d084d5',
        '6881b9586d6c111012d084c2',
        '6881b9526d6c111012d084af',
        '6881b9416d6c111012d0849c',
        '6881b9316d6c111012d08489',
        '6881b91d6d6c111012d08476',
        '6881b9116d6c111012d08463',
        '6881b8fc6d6c111012d08450',
        '6881b8ee6d6c111012d0843d',
        '6881b8df6d6c111012d0842a',
        '6881b8ce6d6c111012d08404',
      ];
      return locationOptions.contains(locationId) ? locationId : '';
    }
    return '';
  }

  String _getSecretaryId() {
    final secretary = widget.appointment['secretary'];
    if (secretary is Map<String, dynamic>) {
      final secretaryId = secretary['_id']?.toString() ?? '';
      // Check if the secretary ID exists in our dropdown options
      final secretaryOptions = [
        '6875ee11359225dab45ccc7a',
        '6875ee5e359225dab45ccc7d',
        '688b648c022f38ae6bd79658',
        '688b650d022f38ae6bd79659',
      ];
      return secretaryOptions.contains(secretaryId) ? secretaryId : '';
    }
    return '';
  }

  String _getTeacherStatus() {
    if (_checkIsTeacher()) {
      return 'yes';
    }
    return 'no';
  }

  bool _checkIsTeacher() {
    final aolTeacher = widget.appointment['aolTeacher'];
    final createdBy = widget.appointment['createdBy'];
    final userCurrentDesignation = widget.appointment['userCurrentDesignation']?.toString().toLowerCase();
    final appointmentPurpose = widget.appointment['appointmentPurpose']?.toString().toLowerCase();
    
    if (aolTeacher is Map<String, dynamic>) {
      final isTeacher = aolTeacher['isTeacher'] == true;
      if (isTeacher) return true;
    }
    
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        final nestedAolTeacher = aolTeacherNested['aolTeacher'];
        if (nestedAolTeacher is Map<String, dynamic>) {
          final isTeacher = nestedAolTeacher['isTeacher'] == true;
          if (isTeacher) return true;
        }
        
        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          final verified = atolValidationData['verified'] == true;
          if (verified) return true;
        }
        
        final teacherType = aolTeacherNested['teacher_type']?.toString().toLowerCase();
        if (teacherType != null && (teacherType.contains('teacher') || teacherType.contains('aol'))) {
          return true;
        }
      }
    }
    
    if (userCurrentDesignation != null) {
      if (userCurrentDesignation.contains('teacher') || 
          userCurrentDesignation.contains('aol') ||
          userCurrentDesignation.contains('art of living')) {
        return true;
      }
    }
    
    if (appointmentPurpose != null) {
      if (appointmentPurpose.contains('teacher') || 
          appointmentPurpose.contains('aol') ||
          appointmentPurpose.contains('art of living')) {
        return true;
      }
    }
    
    return false;
  }

  int _calculateDateRange() {
    try {
      final fromDateText = _fromDateController.text;
      final toDateText = _toDateController.text;
      
      if (fromDateText.isEmpty || toDateText.isEmpty) {
        return 0;
      }
      
      final fromDate = DateTime.parse(fromDateText);
      final toDate = DateTime.parse(toDateText);
      
      final difference = toDate.difference(fromDate).inDays;
      return difference + 1; // Include both start and end dates
    } catch (e) {
      return 0;
    }
  }

  String _getCreatedByName() {
    try {
      final createdBy = widget.appointment['createdBy'];
      if (createdBy is Map<String, dynamic>) {
        final name = createdBy['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
        final fullName = createdBy['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
      return 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  String _getCreatedByEmail() {
    try {
      final createdBy = widget.appointment['createdBy'];
      if (createdBy is Map<String, dynamic>) {
        final email = createdBy['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
      final email = widget.appointment['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
      return 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  String _getCreatedByPhone() {
    try {
      final createdBy = widget.appointment['createdBy'];
      
      if (createdBy is Map<String, dynamic>) {
        final phoneObj = createdBy['phoneNumber'];
        
        if (phoneObj is Map<String, dynamic>) {
          final countryCode = phoneObj['countryCode']?.toString() ?? '';
          final number = phoneObj['number']?.toString() ?? '';
          
          if (countryCode.isNotEmpty && number.isNotEmpty) {
            final fullPhone = '$countryCode $number';
            return fullPhone;
          }
        }
        
        final phone = createdBy['phone']?.toString();
        if (phone != null && phone.isNotEmpty) {
          return phone;
        }
      }
      
      final phoneObj = widget.appointment['phoneNumber'];
      
      if (phoneObj is Map<String, dynamic>) {
        final countryCode = phoneObj['countryCode']?.toString() ?? '';
        final number = phoneObj['number']?.toString() ?? '';
        
        if (countryCode.isNotEmpty && number.isNotEmpty) {
          final fullPhone = '$countryCode $number';
          return fullPhone;
        }
      }
      
      final phone = widget.appointment['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        return phone;
      }
      
      return 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  String _getCreatedByDesignation() {
    try {
      // Try direct appointment fields first (these are the correct ones)
      final designation = widget.appointment['userCurrentDesignation']?.toString();
      if (designation != null && designation.isNotEmpty) {
        return designation;
      }
      
      final designation2 = widget.appointment['designation']?.toString();
      if (designation2 != null && designation2.isNotEmpty) {
        return designation2;
      }
      
      final designation3 = widget.appointment['currentDesignation']?.toString();
      if (designation3 != null && designation3.isNotEmpty) {
        return designation3;
      }
      
      final designation4 = widget.appointment['jobTitle']?.toString();
      if (designation4 != null && designation4.isNotEmpty) {
        return designation4;
      }
      
      final designation5 = widget.appointment['title']?.toString();
      if (designation5 != null && designation5.isNotEmpty) {
        return designation5;
      }
      
      final designation6 = widget.appointment['role']?.toString();
      if (designation6 != null && designation6.isNotEmpty) {
        return designation6;
      }
      
      // Try createdBy fields as fallback
      final createdBy = widget.appointment['createdBy'];
      if (createdBy is Map<String, dynamic>) {
        final designation7 = createdBy['designation']?.toString();
        if (designation7 != null && designation7.isNotEmpty) {
          return designation7;
        }
        
        final designation8 = createdBy['currentDesignation']?.toString();
        if (designation8 != null && designation8.isNotEmpty) {
          return designation8;
        }
        
        final designation9 = createdBy['jobTitle']?.toString();
        if (designation9 != null && designation9.isNotEmpty) {
          return designation9;
        }
        
        final designation10 = createdBy['title']?.toString();
        if (designation10 != null && designation10.isNotEmpty) {
          return designation10;
        }
        
        final designation11 = createdBy['role']?.toString();
        if (designation11 != null && designation11.isNotEmpty) {
          return designation11;
        }
      }
      
      return 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  String _getCreatedByCompany() {
    try {
      // Try direct appointment fields first (these are the correct ones)
      final company = widget.appointment['userCurrentCompany']?.toString();
      if (company != null && company.isNotEmpty) {
        return company;
      }
      
      final company2 = widget.appointment['company']?.toString();
      if (company2 != null && company2.isNotEmpty) {
        return company2;
      }
      
      final company3 = widget.appointment['currentCompany']?.toString();
      if (company3 != null && company3.isNotEmpty) {
        return company3;
      }
      
      final company4 = widget.appointment['organization']?.toString();
      if (company4 != null && company4.isNotEmpty) {
        return company4;
      }
      
      final company5 = widget.appointment['employer']?.toString();
      if (company5 != null && company5.isNotEmpty) {
        return company5;
      }
      
      final company6 = widget.appointment['workplace']?.toString();
      if (company6 != null && company6.isNotEmpty) {
        return company6;
      }
      
      // Try createdBy fields as fallback
      final createdBy = widget.appointment['createdBy'];
      if (createdBy is Map<String, dynamic>) {
        final company7 = createdBy['company']?.toString();
        if (company7 != null && company7.isNotEmpty) {
          return company7;
        }
        
        final company8 = createdBy['currentCompany']?.toString();
        if (company8 != null && company8.isNotEmpty) {
          return company8;
        }
        
        final company9 = createdBy['organization']?.toString();
        if (company9 != null && company9.isNotEmpty) {
          return company9;
        }
        
        final company10 = createdBy['employer']?.toString();
        if (company10 != null && company10.isNotEmpty) {
          return company10;
        }
        
        final company11 = createdBy['workplace']?.toString();
        if (company11 != null && company11.isNotEmpty) {
          return company11;
        }
      }
      
      return 'Not specified';
    } catch (e) {
      return 'Not specified';
    }
  }

  void _initializeGuestData() {
    final accompanyUsers = widget.appointment['accompanyUsers'];
    
    if (accompanyUsers is Map<String, dynamic>) {
      final users = accompanyUsers['users'];
      
      if (users is List) {
        _guests = users.map((user) {
          final phoneNumber = user['phoneNumber'];
          
          String fullPhone = '';
          
          if (phoneNumber is Map<String, dynamic>) {
            final countryCode = phoneNumber['countryCode']?.toString() ?? '';
            final number = phoneNumber['number']?.toString() ?? '';
            
            // Format the phone number properly
            if (countryCode.isNotEmpty && number.isNotEmpty) {
              // Remove any existing country code from the number if it's already included
              String cleanNumber = number;
              if (number.startsWith(countryCode.replaceAll('+', ''))) {
                cleanNumber = number.substring(countryCode.replaceAll('+', '').length);
              }
              
              // Format the number with proper spacing
              if (cleanNumber.length >= 10) {
                // For Indian numbers (10 digits)
                if (countryCode == '+91' && cleanNumber.length == 10) {
                  fullPhone = '$countryCode ${cleanNumber.substring(0, 5)}-${cleanNumber.substring(5)}';
                } else {
                  // For other numbers, just add space after country code
                  fullPhone = '$countryCode $cleanNumber';
                }
              } else {
                fullPhone = '$countryCode $cleanNumber';
              }
            } else if (number.isNotEmpty) {
              fullPhone = number;
            }
          } else if (phoneNumber is String) {
            fullPhone = phoneNumber;
          }
          
          return {
            'fullName': user['fullName']?.toString() ?? '',
            'age': user['age']?.toString() ?? '',
            'phoneNumber': fullPhone,
            'profilePhotoUrl': user['profilePhotoUrl']?.toString() ?? '',
            'userId': user['userId']?.toString(),
            'admissionStatus': user['admissionStatus']?.toString() ?? 'pending',
            'admittedBy': user['admittedBy'],
            'relationshipToApplicant': user['relationshipToApplicant'],
            'admittedAt': user['admittedAt'],
            'isUploading': false,
          };
        }).toList();
      }
    }
    
    // Initialize guest controllers for editable fields
    _initializeGuestControllers();
  }

  // Initialize guest controllers for editable fields
  void _initializeGuestControllers() {
    // Clear existing controllers
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
      guest['uniquePhoneCode']?.dispose();
    }
    _guestControllers.clear();
    _guestImages.clear();
    _guestUploading.clear();
    _guestCountries.clear();
    
    // Initialize controllers for each guest
    for (int i = 0; i < _guests.length; i++) {
      final guest = _guests[i];
      final phoneNumber = guest['phoneNumber'] ?? '';
      
      // Parse phone number to extract country code and number
      String countryCode = '+91'; // Default
      String number = phoneNumber;
      
      if (phoneNumber.contains(' ')) {
        final parts = phoneNumber.split(' ');
        if (parts.isNotEmpty) {
          countryCode = parts[0];
          number = parts.skip(1).join(' ').replaceAll('-', '');
        }
      } else {
        number = phoneNumber;
      }
      
      final ageController = TextEditingController(text: guest['age'] ?? '');
      
      // Add listener to age controller to trigger rebuild when age changes
      ageController.addListener(() {
        setState(() {
          // This will trigger a rebuild and update the photo requirement visibility
        });
      });
      
      _guestControllers.add({
        'name': TextEditingController(text: guest['fullName'] ?? ''),
        'age': ageController,
        'phone': TextEditingController(text: number),
        'uniquePhoneCode': TextEditingController(text: guest['alternatePhoneNumber']?.toString() ?? 
                                                      guest['uniquePhoneCode']?.toString() ?? 
                                                      guest['alternativePhone']?.toString() ?? 
                                                      guest['alternatePhone']?.toString() ?? ''),
      });
      
      // Debug: Print all available fields in guest data
      print('Loading guest ${i + 1} data - All available fields:');
      guest.forEach((key, value) {
        print('  - $key: $value');
      });
      
      // Initialize associated data
      _guestImages[i + 1] = guest['profilePhotoUrl'] ?? '';
      _guestUploading[i + 1] = false;
      _guestCountries[i + 1] = countryCode;
    }
  }



  // Update guest controllers based on total number of users
  void _updateGuestControllers() {
    final totalUsers = int.tryParse(_numberOfPeopleController.text) ?? 1;
    final accompanyingUsers = totalUsers - 1; // Subtract 1 for main user
    final currentControllersCount = _guestControllers.length;
    
    // Skip if this is the initial setup (guests are being initialized from existing data)
    if (_guests.isNotEmpty && currentControllersCount == 0) {
      return;
    }
    
    // Initialize guests if empty and we need guests
    if (_guests.isEmpty && accompanyingUsers > 0) {
      _createEmptyGuests(accompanyingUsers);
    }
    
    if (accompanyingUsers > currentControllersCount) {
      // Add more controllers
      while (_guestControllers.length < accompanyingUsers) {
        int guestNumber = _guestControllers.length + 1;
        
        // Add to guests list
        _guests.add({
          'fullName': '',
          'age': '',
          'phoneNumber': '',
          'profilePhotoUrl': '',
          'userId': null,
          'admissionStatus': 'pending',
          'admittedBy': null,
          'relationshipToApplicant': null,
          'admittedAt': null,
          'isUploading': false,
        });
        
        // Add controllers for new guest
        final ageController = TextEditingController();
        
        // Add listener to age controller to trigger rebuild when age changes
        ageController.addListener(() {
          setState(() {
            // This will trigger a rebuild and update the photo requirement visibility
          });
        });
        
        _guestControllers.add({
          'name': TextEditingController(),
          'age': ageController,
          'phone': TextEditingController(),
          'uniquePhoneCode': TextEditingController(),
        });
        
        // Initialize associated data
        _guestImages[guestNumber] = '';
        _guestUploading[guestNumber] = false;
        _guestCountries[guestNumber] = '+91';
      }
    } else if (accompanyingUsers < currentControllersCount) {
      // Remove controllers (remove from the end)
      
      // Dispose controllers that will be removed
      for (int i = accompanyingUsers; i < currentControllersCount; i++) {
        var guest = _guestControllers[i];
        guest['name']?.dispose();
        guest['phone']?.dispose();
        guest['age']?.dispose();
        guest['uniquePhoneCode']?.dispose();
      }
      
      // Remove from lists (remove from the end)
      _guests.removeRange(accompanyingUsers, currentControllersCount);
      _guestControllers.removeRange(accompanyingUsers, currentControllersCount);
      
      // Remove associated data (remove from the end)
      for (int i = accompanyingUsers + 1; i <= currentControllersCount; i++) {
        _guestImages.remove(i);
        _guestUploading.remove(i);
        _guestCountries.remove(i);
      }
    }
  }

  // Create empty guests for new appointments
  void _createEmptyGuests(int numberOfGuests) {
    // Clear existing data
    for (var guest in _guestControllers) {
      guest['name']?.dispose();
      guest['phone']?.dispose();
      guest['age']?.dispose();
      guest['uniquePhoneCode']?.dispose();
    }
    _guestControllers.clear();
    _guestImages.clear();
    _guestUploading.clear();
    _guestCountries.clear();
    _guests.clear();
    
    // Create empty guests
    for (int i = 0; i < numberOfGuests; i++) {
      int guestNumber = i + 1;
      
      // Add to guests list
      _guests.add({
        'fullName': '',
        'age': '',
        'phoneNumber': '',
        'profilePhotoUrl': '',
        'userId': null,
        'admissionStatus': 'pending',
        'admittedBy': null,
        'relationshipToApplicant': null,
        'admittedAt': null,
        'isUploading': false,
      });
      
      // Add controllers for new guest
      final ageController = TextEditingController();
      
      // Add listener to age controller to trigger rebuild when age changes
      ageController.addListener(() {
        setState(() {
          // This will trigger a rebuild and update the photo requirement visibility
        });
      });
      
      _guestControllers.add({
        'name': TextEditingController(),
        'age': ageController,
        'phone': TextEditingController(),
        'uniquePhoneCode': TextEditingController(),
      });
      
      // Initialize associated data
      _guestImages[guestNumber] = '';
      _guestUploading[guestNumber] = false;
      _guestCountries[guestNumber] = '+91';
    }
  }

  // Photo picker methods for guests
  Future<void> _pickGuestImage(int guestIndex, ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {

        // Show uploading state
        setState(() {
          _guestUploading[guestIndex + 1] = true;
        });

        try {
          // Upload photo immediately and get S3 URL
          final result = await ActionService.uploadAndValidateProfilePhoto(
            File(pickedFile.path),
          );

          if (result['success']) {
            final s3Url = result['s3Url'];
            setState(() {
              _guestImages[guestIndex + 1] = s3Url;
              _guestUploading[guestIndex + 1] = false;
            });


            // Photo uploaded successfully
          } else {
            setState(() {
              _guestUploading[guestIndex + 1] = false;
            });


            // Show backend error message in dialog
            final errorMessage =
                result['error'] ?? result['message'] ?? 'Photo validation failed';
            _showPhotoValidationErrorDialog(
              'Guest ${guestIndex + 1}: $errorMessage',
              () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _guestImages[guestIndex + 1] = '';
                  _guestUploading[guestIndex + 1] = false;
                });
              },
            );
          }
        } catch (e) {
          setState(() {
            _guestUploading[guestIndex + 1] = false;
          });


          // Show error message in dialog
          _showPhotoValidationErrorDialog(
            'Guest ${guestIndex + 1}: Error uploading photo: ${e.toString()}',
            () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _guestImages[guestIndex + 1] = '';
                _guestUploading[guestIndex + 1] = false;
              });
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeGuestPhoto(int guestIndex) {
    setState(() {
      _guestImages[guestIndex + 1] = '';
      _guestUploading[guestIndex + 1] = false;
    });
    
    // Photo removed
  }

  // Guest photo display methods for guest appointments
  Future<void> _pickGuestImageForDisplay(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (pickedFile != null) {

        // Show uploading state
        setState(() {
          // For guest display, we'll use a special key
          _guestUploading[0] = true; // Use 0 for guest display
        });

        try {
          // Upload photo immediately and get S3 URL
          final result = await ActionService.uploadAndValidateProfilePhoto(
            File(pickedFile.path),
          );

          if (result['success']) {
            final s3Url = result['s3Url'];
            setState(() {
              // Store the guest photo URL in a special field
              _guestImages[0] = s3Url; // Use 0 for guest display
              _guestUploading[0] = false;
            });


            // Guest photo uploaded successfully
          } else {
            setState(() {
              _guestUploading[0] = false;
            });


            // Show backend error message in dialog
            final errorMessage =
                result['error'] ?? result['message'] ?? 'Photo validation failed';
            _showPhotoValidationErrorDialog(
              'Guest: $errorMessage',
              () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _guestImages[0] = '';
                  _guestUploading[0] = false;
                });
              },
            );
          }
        } catch (e) {
          setState(() {
            _guestUploading[0] = false;
          });


          // Show error message in dialog
          _showPhotoValidationErrorDialog(
            'Guest: Error uploading photo: ${e.toString()}',
            () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _guestImages[0] = '';
                _guestUploading[0] = false;
              });
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _removeGuestPhotoForDisplay() {
    setState(() {
      _guestImages[0] = ''; // Use 0 for guest display
      _guestUploading[0] = false;
    });
    
    // Guest photo removed
  }

  int _getGuestIndexFromPhotoUrl(String photoUrl) {
    for (int i = 1; i <= _guests.length; i++) {
      if (_guestImages[i] == photoUrl) {
        return i - 1;
      }
    }
        return 0; // Fallback to first guest
  }

  // Fetch location suggestions
  Future<void> _fetchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _locationSuggestions = [];
        _isLoadingGuestLocations = false;
      });
      return;
    }

    setState(() {
      _isLoadingGuestLocations = true;
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
          _isLoadingGuestLocations = false;
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
          _isLoadingGuestLocations = false;
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
        _isLoadingGuestLocations = false;
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
  
  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? '';
  }

  // Check if this is a guest appointment
  bool _isGuestAppointment() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    return appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true);
  }

  // Get reference person name for guest appointments
  String _getReferencePersonName() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final referencePerson = widget.appointment['referencePerson'];
      if (referencePerson is Map<String, dynamic>) {
        final name = referencePerson['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }
    return '';
  }

  // Get reference person email for guest appointments
  String _getReferencePersonEmail() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final referencePerson = widget.appointment['referencePerson'];
      if (referencePerson is Map<String, dynamic>) {
        final email = referencePerson['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }
    return '';
  }

  // Get reference person phone number for guest appointments
  String _getReferencePersonPhone() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    
    if (appointmentType?.toLowerCase() == 'guest') {
      final referencePerson = widget.appointment['referencePerson'];
      
      if (referencePerson is Map<String, dynamic>) {
        final phoneNumber = referencePerson['phoneNumber'];
        
        if (phoneNumber is Map<String, dynamic>) {
          final countryCode = phoneNumber['countryCode']?.toString() ?? '';
          final number = phoneNumber['number']?.toString() ?? '';
          
          if (countryCode.isNotEmpty && number.isNotEmpty) {
            final fullPhone = '$countryCode $number';
            return fullPhone;
          }
        } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
          return phoneNumber;
        }
      }
    }
    
    return '';
  }

  // Get guest information helper methods
  String _getGuestFullName() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final fullName = guestInformation['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    }
    return '';
  }

  String _getGuestEmail() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final email = guestInformation['emailId']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }
    return '';
  }

  String _getGuestPhone() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      
      if (guestInformation is Map<String, dynamic>) {
        final phoneNumber = guestInformation['phoneNumber'];
        
        if (phoneNumber is Map<String, dynamic>) {
          final countryCode = phoneNumber['countryCode']?.toString() ?? '';
          final number = phoneNumber['number']?.toString() ?? '';
          
          if (countryCode.isNotEmpty && number.isNotEmpty) {
            final fullPhone = '$countryCode$number';
            return fullPhone;
          } else if (number.isNotEmpty) {
            return number;
          }
        } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
          return phoneNumber;
        }
      }
    }
    
    return '';
  }

  String _getGuestDesignation() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final designation = guestInformation['designation']?.toString();
        if (designation != null && designation.isNotEmpty) {
          return designation;
        }
      }
    }
    return '';
  }

  String _getGuestCompany() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final company = guestInformation['company']?.toString();
        if (company != null && company.isNotEmpty) {
          return company;
        }
      }
    }
    return '';
  }

  String _getGuestLocation() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final location = guestInformation['location']?.toString();
        if (location != null && location.isNotEmpty) {
          return location;
        }
      }
    }
    return '';
  }

  String _getGuestPhotoUrl() {
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      final guestInformation = widget.appointment['guestInformation'];
      if (guestInformation is Map<String, dynamic>) {
        final photoUrl = guestInformation['profilePhotoUrl']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
    }
    return '';
  }

  Widget _buildGuestInformationDisplaySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Guest Information Fields - One per row
          Column(
            children: [
              // Full Name
              _buildEditableGuestField('Full Name of the Guest', _guestFullNameController),
              const SizedBox(height: 16),
              
              // Email
              _buildEditableGuestField('Email ID of the Guest', _guestEmailController),
              const SizedBox(height: 16),
              
              // Phone
              _buildEditableGuestField('Mobile No. of the Guest', _guestPhoneController),
              const SizedBox(height: 16),
              
              // Designation
              _buildEditableGuestField('Designation', _guestDesignationController),
              const SizedBox(height: 16),
              
              // Company
              _buildEditableGuestField('Company/Organization', _guestCompanyController),
              const SizedBox(height: 16),
              
                              // Location
                _buildLocationField(),
              const SizedBox(height: 24),
              
              // Guest Photo Section
              _buildGuestPhotoDisplaySection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPhotoDisplaySection() {
    // Use the guest photo URL from state if available, otherwise from appointment data
    final photoUrl = _guestImages[0]?.isNotEmpty == true 
        ? _guestImages[0]! 
        : _getGuestPhotoUrl();
    final hasPhoto = photoUrl.isNotEmpty;
    final isUploading = _guestUploading[0] == true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.grey[400], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Guest Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: isUploading 
                ? _buildGuestPhotoDisplayUploading() 
                : (hasPhoto ? _buildGuestPhotoDisplayUploaded(photoUrl) : _buildGuestPhotoDisplayNotUploaded()),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPhotoDisplayUploaded(String photoUrl) {
    return Column(
      children: [
        // Photo preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(height: 2),
                        const Text(
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
              
              // Action buttons
              const SizedBox(height: 12),
              
              Column(
                children: [
                  // Upload Different Photo
                  GestureDetector(
                    onTap: () => _pickGuestImageForDisplay(ImageSource.gallery),
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
                    onTap: () => _pickGuestImageForDisplay(ImageSource.camera),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Take New Photo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
    );
  }

  Widget _buildGuestPhotoDisplayUploading() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
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
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uploading photo...',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestPhotoDisplayNotUploaded() {
    return Column(
      children: [
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
          'Photo of the Person Required for Age 12 years and Above',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        
        // Photo Upload Options
        Column(
          children: [
            // Upload from Device Card
            GestureDetector(
              onTap: () => _pickGuestImageForDisplay(ImageSource.gallery),
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
              onTap: () => _pickGuestImageForDisplay(ImageSource.camera),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF97316)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF97316),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Use your device camera',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Load current user (same as assign_form.dart)
  Future<void> _loadCurrentUser() async {
    try {
      // Get current user ID from JWT token
      final token = await StorageService.getToken();
      if (token != null) {
        final mongoId = JwtUtils.extractMongoId(token);
        setState(() {
          _currentUserId = mongoId;
        });
      }

      // Get assigned secretary name from appointment data (same as appointment card)
      final assignedSecretary = widget.appointment['assignedSecretary'];
      if (assignedSecretary is Map<String, dynamic>) {
        setState(() {
          _assignedSecretaryId = assignedSecretary['fullName']?.toString();
        });
      }
    } catch (e) {
    }
  }

  // Load secretaries (same as assign_form.dart)
  Future<void> _loadSecretaries() async {
    try {
      setState(() {
        _isLoadingSecretaries = true;
        _secretaryErrorMessage = null;
      });

      // Use selected location if available, otherwise extract from appointment data
      String? locationId;
      if (_selectedLocation != null) {
        locationId = _selectedLocation;
      } else {
        locationId = _extractLocationId();
      }
      
      if (locationId == null) {
        setState(() {
          _isLoadingSecretaries = false;
          _secretaryErrorMessage = 'Location information not available';
          _availableAssignees = [];
        });
        return;
      }

      // Call the API to get secretaries for this location
      final result = await ActionService.getAssignedSecretariesByAshramLocation(
        locationId: locationId,
      );

      if (result['success']) {
        final List<dynamic> secretariesData = result['data'] ?? [];
        
        // Transform the API response to match our expected format
        final List<Map<String, dynamic>> secretaries = secretariesData.map((secretary) {
          final secretaryId = secretary['secretaryId']?.toString() ?? '';
          final secretaryName = secretary['fullName']?.toString() ?? '';
          final isCurrentUser = secretaryId == _currentUserId;
          final isAssigned = secretaryName == _assignedSecretaryId;
          
          
          return {
            'id': secretaryId,
            'name': secretaryName,
            'isCurrentUser': isCurrentUser,
            'isAssigned': isAssigned,
          };
        }).toList();
        

        setState(() {
          _availableAssignees = secretaries;
          _isLoadingSecretaries = false;
        });
        
        // Ensure the assigned secretary is selected if not already set
        if (_selectedSecretary == null && _assignedSecretaryId != null) {
          try {
            final assignedSecretary = secretaries.firstWhere(
              (secretary) => secretary['name'] == _assignedSecretaryId,
            );
            if (assignedSecretary['id'] != null && assignedSecretary['id'].isNotEmpty) {
              setState(() {
                _selectedSecretary = assignedSecretary['id'];
              });
            }
          } catch (e) {
          }
        }
        
        // If still no secretary selected, select the first available one
        if (_selectedSecretary == null && secretaries.isNotEmpty) {
          setState(() {
            _selectedSecretary = secretaries.first['id']?.toString();
          });
        }
      } else {
        setState(() {
          _isLoadingSecretaries = false;
          _secretaryErrorMessage = result['message'] ?? 'Failed to load secretaries';
          _availableAssignees = [];
        });
      }
    } catch (error) {
      setState(() {
        _isLoadingSecretaries = false;
        _secretaryErrorMessage = 'Network error: $error';
        _availableAssignees = [];
      });
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      final firstPart = parts[0];
      final secondPart = parts[1];
      if (firstPart.isNotEmpty && secondPart.isNotEmpty) {
        return '${firstPart[0]}${secondPart[0]}'.toUpperCase();
      } else if (firstPart.isNotEmpty) {
        return firstPart[0].toUpperCase();
      }
    }
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '';
  }

  // Load locations from API
  Future<void> _loadLocations() async {
    try {
      setState(() {
        _isLoadingLocations = true;
        _locationErrorMessage = null;
      });

      // Call the API to get ashram locations
      final result = await ActionService.getAshramLocations();

      if (result['success']) {
        final List<dynamic> locationsData = result['data'] ?? [];
        
        // Transform the API response to match our expected format
        final List<Map<String, dynamic>> locations = locationsData.map((location) {
          return {
            'id': location['_id']?.toString() ?? '',
            'name': location['name']?.toString() ?? '',
            'locationId': location['locationId']?.toString() ?? '',
            'description': location['description']?.toString() ?? '',
            'active': location['active'] ?? true,
          };
        }).toList();

        setState(() {
          _availableLocations = locations;
          _isLoadingLocations = false;
        });
      } else {
        setState(() {
          _isLoadingLocations = false;
          _locationErrorMessage = result['message'] ?? 'Failed to load locations';
          _availableLocations = [];
        });
      }
    } catch (error) {
      setState(() {
        _isLoadingLocations = false;
        _locationErrorMessage = 'Network error: $error';
        _availableLocations = [];
      });
    }
  }

  String? _extractLocationId() {
    // Try to get location ID from various possible fields
    // First check scheduledDateTime.venue (from the actual data structure)
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final venue = scheduledDateTime['venue'];
      if (venue != null) {
        return venue.toString();
      }
    }

    // Try appointmentLocation field
    final appointmentLocation = widget.appointment['appointmentLocation'];
    if (appointmentLocation != null) {
      // If it's an object, extract the _id field
      if (appointmentLocation is Map<String, dynamic>) {
        final id = appointmentLocation['_id']?.toString();
        return id;
      }
      return appointmentLocation.toString();
    }

    // Try location field
    final location = widget.appointment['location'];
    if (location != null) {
      // If it's an object, extract the _id field
      if (location is Map<String, dynamic>) {
        final id = location['_id']?.toString();
        return id;
      }
      return location.toString();
    }

    // Try venue field directly
    final venue = widget.appointment['venue'];
    if (venue != null) {
      // If it's an object, extract the _id field
      if (venue is Map<String, dynamic>) {
        final id = venue['_id']?.toString();
        return id;
      }
      return venue.toString();
    }

    // If no location ID found, return null
    return null;
  }

  // Debug method to print appointment structure
  void _debugAppointmentStructure() {
    
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
    } else {
    }
    
    
    // Debug accompanyUsers
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
    }
    
    // Debug all appointment data
    
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate guest information fields if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType == 'guest') {
      if (_guestFullNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest full name is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (_guestEmailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest email is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_guestEmailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (_guestPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest phone number is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (_guestDesignationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest designation is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (_guestCompanyController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest company is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      if (_guestLocationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guest location is required'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Validate accompany users
    final accompanyUsersData = _getAccompanyUsersData();
    if (accompanyUsersData != null) {
      final users = accompanyUsersData['users'] as List<Map<String, dynamic>>;
      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        final userIndex = i + 1;
        
        // Validate required fields
        if (user['fullName'] == null || user['fullName'].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $userIndex: Full name is required'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        
        final age = int.tryParse(user['age']?.toString() ?? '0') ?? 0;
        if (age < 1 || age > 120) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $userIndex: Age must be between 1 and 120'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        
        // Check if user has unique phone code
        final hasUniquePhoneCode = user['alternativePhone'] != null && 
            user['alternativePhone'].toString().trim().isNotEmpty;
        
        // Phone number validation based on age and unique phone code
        if (age < 12 || age > 60) {
          // For age < 12 or age > 60, either phone number OR unique phone code is required
          if (!hasUniquePhoneCode) {
            // Check if phone number is provided
            final hasPhoneNumber = user['phoneNumber'] != null && 
                user['phoneNumber']['number']?.toString().trim().isNotEmpty == true;
            
            if (!hasPhoneNumber) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User $userIndex: Either phone number or unique phone code is required for ages under 12 or over 60'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
          }
        } else {
          // For other ages: Phone number is always required
          final hasPhoneNumber = user['phoneNumber'] != null && 
              user['phoneNumber']['number']?.toString().trim().isNotEmpty == true;
          
          if (!hasPhoneNumber) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User $userIndex: Phone number is required'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        }
        
        // Validate unique phone code format if provided
        if (hasUniquePhoneCode) {
          final uniquePhoneCode = user['alternativePhone'].toString().trim();
          final uniquePhoneCodeRegex = RegExp(r'^[A-Za-z0-9]{3,20}$');
          if (!uniquePhoneCodeRegex.hasMatch(uniquePhoneCode)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User $userIndex: Invalid unique phone code format (3-20 alphanumeric characters)'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
        }
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get appointment ID
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        throw Exception('Appointment ID not found');
      }

      // Get original appointment type for debugging
      final originalAppointmentType = widget.appointment['appointmentType']?.toString() ?? 'myself';
      
      // Prepare the update data
      final updateData = {
        'userCurrentCompany': _companyController.text.trim(),
        'userCurrentDesignation': _designationController.text.trim(),
        'appointmentPurpose': _purposeController.text.trim(),
        'appointmentSubject': _purposeController.text.trim(),
        'preferredDateRange': {
          'fromDate': _fromDateController.text,
          'toDate': _toDateController.text,
        },
        'appointmentLocation': _selectedLocation,
        'assignedSecretary': _selectedSecretary,
        'numberOfUsers': int.tryParse(_numberOfPeopleController.text) ?? 1,
        'isTeacher': _teacherStatus,
        // Add required fields that the API expects - preserve original appointment type
        'appointmentFor': widget.appointment['appointmentFor'] ?? {
          'type': widget.appointment['appointmentType']?.toString() ?? 'myself', // Preserve original type
        },
        'appointmentType': widget.appointment['appointmentType']?.toString() ?? 'myself', // Preserve original type
        'accompanyUsers': _getAccompanyUsersData(),
        'attendingCourseDetails': {
          'isAttending': false,
          'fromDate': _fromDateController.text,
          'toDate': _toDateController.text,
        },
      };

      // Add guestInformation if appointment type is 'guest'
      if (originalAppointmentType == 'guest') {
        final guestPhoneNumber = _guestPhoneController.text.trim();
        
        updateData['guestInformation'] = {
          'fullName': _guestFullNameController.text.trim(),
          'emailId': _guestEmailController.text.trim(),
          'phoneNumber': guestPhoneNumber,
          'designation': _guestDesignationController.text.trim(),
          'company': _guestCompanyController.text.trim(),
          'location': _guestLocationController.text.trim(),
          // Use new photo URL if uploaded, otherwise preserve existing
          'profilePhotoUrl': _guestImages[0]?.isNotEmpty == true 
              ? _guestImages[0]! 
              : (widget.appointment['guestInformation']?['profilePhotoUrl'] ?? ''),
        };
      }

      // File upload in progress

      // Call the API to update appointment
      final result = await ActionService.updateAppointmentEnhanced(
        appointmentId: appointmentId,
        updateData: updateData,
        attachmentFile: _selectedFile,
      );

      if (result['success']) {
        // Send appointment update notification
        await _sendAppointmentUpdatedNotification(result['data']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Appointment updated successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Return to previous screen with updated data
          Navigator.pop(context, result['data']);
        }
      } else {
        // Handle API error
        String errorMessage = result['message'] ?? 'Failed to update appointment';
        if (result['error'] != null) {
          errorMessage += '\nError: ${result['error']}';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating appointment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Map<String, dynamic>? _getAccompanyUsersData() {
    // Get the total number of users from the controller
    final totalUsers = int.tryParse(_numberOfPeopleController.text) ?? 1;
    final accompanyingUsers = totalUsers - 1; // Subtract 1 for main user
    
    // If no accompanying users, return null
    if (accompanyingUsers <= 0) {
      return null;
    }
    
    // Ensure we have the right number of controllers
    if (_guestControllers.length != accompanyingUsers) {
      // Update controllers to match the required number
      _updateGuestControllers();
    }
    
    // Build users data from controllers
    final List<Map<String, dynamic>> users = [];
    
    for (int i = 0; i < _guestControllers.length; i++) {
      final controllers = _guestControllers[i];
      final guestNumber = i + 1;
      
      // Get phone number with country code
      final phoneNumber = controllers['phone']?.text ?? '';
      final countryCode = _guestCountries[guestNumber] ?? '+91';
      final age = int.tryParse(controllers['age']?.text ?? '0') ?? 0;
      final uniquePhoneCode = controllers['uniquePhoneCode']?.text.trim() ?? '';
      final hasUniquePhoneCode = uniquePhoneCode.isNotEmpty;
      
      // Get photo URL from guest images
      final photoUrl = _guestImages[guestNumber] ?? '';
      
      final userData = {
        'fullName': controllers['name']?.text ?? '',
        'age': age,
      };

      // Only include phone number if we have one OR if we don't have unique phone code (for ages 12-60)
      if (phoneNumber.isNotEmpty || !hasUniquePhoneCode) {
        userData['phoneNumber'] = {
          'countryCode': countryCode,
          'number': phoneNumber,
        };
      }

      // Add unique phone code as alternativePhone if provided
      if (hasUniquePhoneCode) {
        userData['alternativePhone'] = uniquePhoneCode;
      }

      userData.addAll({
        'profilePhotoUrl': photoUrl,
        'userId': '', // Will be assigned by backend
        'admissionStatus': 'pending',
        'admittedBy': '',
        'relationshipToApplicant': '',
        'admittedAt': '',
      });
      
      users.add(userData);
    }
    
    final result = {
      'numberOfUsers': _guestControllers.length,
      'users': _guestControllers.length > 9 ? [] : users, // Send empty array for >9 accompanying users
    };
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Appointment'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Appointment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appointment ID: ${_getAppointmentId()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section - Only show for non-guest appointments
                    if (!_isGuestAppointment()) ...[
                      _buildSectionHeader('Personal Information', 'Your contact details (auto-filled from your profile)'),
                      const SizedBox(height: 20),
                      
                      // Personal Info Grid
                      Column(
                        children: [
                          // Full Name and Email Address on separate lines
                          _buildDisabledField('Full Name', _getCreatedByName()),
                          const SizedBox(height: 16),
                          _buildDisabledField('Email Address', _getCreatedByEmail()),
                          const SizedBox(height: 16),
                          
                          // Phone Number and Designation on separate lines
                          _buildDisabledField('Phone Number', _getCreatedByPhone()),
                          const SizedBox(height: 16),
                          _buildDisabledField('Designation', _getCreatedByDesignation()),
                          const SizedBox(height: 16),
                          
                          // Company/Organization and Teacher Status on separate lines
                          _buildDisabledField('Company/Organization', _getCreatedByCompany()),
                          const SizedBox(height: 16),
                          _buildTeacherRadioGroup(),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                    
                    // Reference Information Section for Guest Appointments
                    if (_isGuestAppointment()) ...[
                      _buildSectionHeader('Reference Information', 'Reference details of the person requesting the appointment'),
                      const SizedBox(height: 20),
                      _buildReferenceInformationSection(),
                      const SizedBox(height: 32),
                      
                      // Guest Information Section
                      _buildSectionHeader('Guest Information', 'Enter the details of the person you are requesting the appointment for'),
                      const SizedBox(height: 20),
                      _buildGuestInformationDisplaySection(),
                      const SizedBox(height: 32),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Appointment Details Section
                    _buildSectionHeader('Appointment Details', 'Provide details about your requested appointment'),
                    const SizedBox(height: 20),
                    
                                          // Location Selection Field
                      _buildLocationSelectionField(),
                    
                    const SizedBox(height: 16),
                    

                    
                    // Secretary Selection Field
                    _buildSecretarySelectionField(),
                    
                    const SizedBox(height: 16),
                    
                    // Purpose TextArea
                    _buildTextAreaField(
                      'Purpose of Meeting',
                      _purposeController,
                      'Please describe the purpose of your meeting in detail',
                      isRequired: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                                          // Total Number of Users
                      _buildNumberField(
                        'Number of People',
                        _numberOfPeopleController,
                        'Number of people (including you) for the appointment?',
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Guest Information Section
                      // Show guest details only for 2-10 users, show message for >10 users
                      if ((int.tryParse(_numberOfPeopleController.text) ?? 1) > 1 && 
                          (int.tryParse(_numberOfPeopleController.text) ?? 1) <= 10) ...[
                        _buildGuestInformationSection(),
                        const SizedBox(height: 16),
                      ] else if ((int.tryParse(_numberOfPeopleController.text) ?? 1) > 10) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'For appointments with more than 10 people, individual details for additional accompanying people are not required.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Attachment Field
                      _buildAttachmentField(),
                      
                      const SizedBox(height: 16),
                    
                    // Date Range
                    _buildDateRangeSection(),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? Row(
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
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Updating...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Update Appointment',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceInformationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Reference Information Grid
          Column(
            children: [
              // Reference Name
              _buildDisabledField('Reference Name', _getReferencePersonName()),
              const SizedBox(height: 16),
              
              // Reference Email
              _buildDisabledField('Reference Email', _getReferencePersonEmail()),
              const SizedBox(height: 16),
              
              // Reference Phone
              _buildDisabledField('Reference Phone', _getReferencePersonPhone()),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildDisabledField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableGuestField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: label.contains('Email') ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              borderSide: BorderSide(color: Colors.orange[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            // Email validation for email fields
            if (label.contains('Email') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUniquePhoneCodeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              borderSide: BorderSide(color: Colors.orange[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Enter 3-digit unique phone code',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            counterText: '', // Hide the character counter
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableAgeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 3,
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide unique phone code field
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            filled: true,
            fillColor: Colors.grey[50],
            hintText: 'Enter age',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            counterText: '', // Hide character counter
          ),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Age is required';
            }
            final age = int.tryParse(value);
            if (age == null || age < 1 || age > 120) {
              return 'Please enter age between 1-120';
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
              controller: _guestLocationController,
              decoration: InputDecoration(
                hintText: 'Start typing your location...',
                suffixIcon: _isLoadingGuestLocations
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _guestLocationController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _guestLocationController.clear();
                                _locationSuggestions = [];
                              });
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
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _onLocationChanged(value);
                setState(() {
                  // Trigger rebuild to show/hide clear button
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            if (_locationSuggestions.isNotEmpty)
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
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
                              _guestLocationController.text =
                                  _locationSuggestions[index];
                              _locationSuggestions = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeacherRadioGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AOL Teacher:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildReadOnlyRadioOption(
                'No',
                'no',
                _teacherStatus,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildReadOnlyRadioOption(
                'Yes',
                'yes',
                _teacherStatus,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label, String value, String selectedValue, Function(String) onChanged) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green[200]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.green[500] : Colors.grey[300],
                border: Border.all(
                  color: isSelected ? Colors.green[500]! : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.green[900] : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRadioOption(String label, String value, String selectedValue) {
    final isSelected = selectedValue == value;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.green[200]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.green[500] : Colors.grey[400],
              border: Border.all(
                color: isSelected ? Colors.green[500]! : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.green[900] : Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<Map<String, dynamic>> options, Function(String?) onChanged, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              selectedItemBuilder: (BuildContext context) {
                return options.map<Widget>((option) {
                  final isAssigned = option['isAssigned'] == true;
                  final isSelected = option['id']?.toString() == selectedValue;
                  
                  if (isSelected) {
                    return Row(
                      children: [
                        // Circle avatar with initials
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isAssigned 
                              ? Colors.green[100]
                              : Colors.indigo[100],
                          child: Text(
                            _getInitials(option['name']?.toString() ?? ''),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isAssigned ? Colors.green : Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option['name']?.toString() ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isAssigned ? Colors.green[700] : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAssigned)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                      ],
                    );
                  } else {
                    return Text(option['name']?.toString() ?? 'Unknown');
                  }
                }).toList();
              },
                             items: options.map((option) {
                 final isAssigned = option['isAssigned'] == true;
                 return DropdownMenuItem<String>(
                   value: option['id']?.toString(),
                   child: Row(
                     children: [
                       // Circle avatar with initials (like assign_form.dart)
                       CircleAvatar(
                         radius: 12,
                         backgroundColor: isAssigned 
                             ? Colors.green[100]
                             : Colors.indigo[100],
                         child: Text(
                           _getInitials(option['name']?.toString() ?? ''),
                           style: TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                             color: isAssigned ? Colors.green : Colors.indigo,
                           ),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           option['name']?.toString() ?? 'Unknown',
                           style: TextStyle(
                             fontSize: 14,
                             fontWeight: FontWeight.w500,
                             color: isAssigned ? Colors.green[700] : Colors.black87,
                           ),
                         ),
                       ),
                       if (isAssigned)
                         const Icon(
                           Icons.check_circle,
                           color: Colors.green,
                           size: 16,
                         ),
                     ],
                   ),
                 );
               }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, TextEditingController controller, String placeholder, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: placeholder,
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
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: isRequired ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          } : null,
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, String placeholder, {bool isRequired = false}) {
    // Check if number of people is greater than 10
    final numberOfPeople = int.tryParse(controller.text) ?? 0;
    final shouldShowInfoCard = numberOfPeople <= 10;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        // Number of People with + and - buttons
        Row(
          children: [
            // Minus button
            GestureDetector(
              onTap: () {
                int currentCount = int.tryParse(controller.text) ?? 1;
                if (currentCount > 1) { // Minimum 1 total user (main user)
                  setState(() {
                    controller.text = (currentCount - 1).toString();
                  });
                  _updateGuestControllers();
                } else {
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
                    controller.text.isEmpty ? '1' : controller.text,
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
                int currentCount = int.tryParse(controller.text) ?? 1;
                setState(() {
                  controller.text = (currentCount + 1).toString();
                });
                _updateGuestControllers();
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
          'Number of people (including you) for the appointment?',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),

      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your preferred date range *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            _buildDateField('From Date', _fromDateController),
            const SizedBox(height: 16),
            _buildDateField('To Date', _toDateController),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              controller.text = date.toIso8601String().split('T')[0];
            }
          },
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
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
              borderSide: const BorderSide(color: Colors.blue),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }



  Widget _buildLoadingField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading secretaries...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelectionField() {
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
          onTap: _isLoadingLocations ? null : _showLocationSelectionBottomSheet,
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
                    _selectedLocation != null ? _getSelectedLocationName() : 'Select a location',
                    style: TextStyle(
                      color: _selectedLocation != null
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

  String _getSelectedLocationName() {
    final selectedLocation = _availableLocations.firstWhere(
      (location) => location['id']?.toString() == _selectedLocation,
      orElse: () => <String, dynamic>{'id': '', 'name': 'Unknown'},
    );
    return selectedLocation['name']?.toString() ?? 'Unknown';
  }

  void _showLocationSelectionBottomSheet() {
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

              // Location list
              Expanded(
                child: _isLoadingLocations
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _locationErrorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  _locationErrorMessage!,
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _availableLocations.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_off, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No locations available',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _availableLocations.length,
                                itemBuilder: (context, index) {
                                  final location = _availableLocations[index];
                                  final isSelected = location['id']?.toString() == _selectedLocation;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFF97316).withOpacity(0.1)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFF97316)
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        setState(() {
                                          _selectedLocation = location['id']?.toString();
                                          // Clear secretary selection when location changes
                                          _selectedSecretary = null;
                                        });
                                        Navigator.pop(context);
                                        // Reload secretaries for the new location
                                        _loadSecretaries();
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? const Color(0xFFF97316)
                                            : Colors.grey[300],
                                        child: Icon(
                                          Icons.location_on,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        location['name']?.toString() ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFFF97316)
                                              : Colors.black87,
                                        ),
                                      ),
                                      subtitle: location['description']?.toString().isNotEmpty == true
                                          ? Text(
                                              location['description']?.toString() ?? '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            )
                                          : null,
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFFF97316),
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
              ),

              // Done button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
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
      ),
    );
  }

  Widget _buildLocationSelectionContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Select Appointment Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Location list
              Flexible(
                child: _isLoadingLocations
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading locations...'),
                            ],
                          ),
                        ),
                      )
                    : _locationErrorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    _locationErrorMessage!,
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _availableLocations.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_off, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No locations available',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _availableLocations.map((location) {
                                    final isSelected = location['id']?.toString() == _selectedLocation;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue.withOpacity(0.5)
                                              : Colors.grey.withOpacity(0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedLocation = location['id']?.toString();
                                          });
                                          setModalState(() {}); // Rebuild the modal
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                color: isSelected ? Colors.blue : Colors.grey[600],
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  location['name']?.toString() ?? 'Unknown',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: isSelected ? Colors.blue[700] : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
              ),
              
              // Done button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
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
        );
      },
    );
  }

  Widget _buildSecretarySelectionField() {
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
          onTap: _selectedLocation == null || _isLoadingSecretaries ? null : _showSecretarySelectionBottomSheet,
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
                      : _selectedLocation == null
                      ? Text(
                          'Please select a location first',
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : Builder(
                          builder: (context) {
                            final secretaryName = _getSelectedSecretaryName();
                            return Text(
                              secretaryName ?? 'Select a secretary',
                              style: TextStyle(
                                color:
                                    secretaryName != null &&
                                        secretaryName !=
                                            'None - I am not in touch with any secretary'
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontSize: 16,
                              ),
                            );
                          },
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
    if (_selectedSecretary == null)
      return 'None - I am not in touch with any secretary';

    // Try to find it in the available assignees list
    try {
      final selectedSecretary = _availableAssignees.firstWhere(
        (secretary) => secretary['id']?.toString() == _selectedSecretary,
      );
      return selectedSecretary['name']?.toString();
    } catch (e) {
      return null;
    }
  }

  List<Widget> _buildSelectedSecretaryDisplay() {
    Map<String, dynamic> selectedSecretary;
    try {
      selectedSecretary = _availableAssignees.firstWhere(
        (secretary) => secretary['id']?.toString() == _selectedSecretary,
      );
    } catch (e) {
      selectedSecretary = {'id': '', 'name': 'Unknown', 'isAssigned': false};
    }
    
    final isAssigned = selectedSecretary['isAssigned'] == true;
    final secretaryName = selectedSecretary['name']?.toString() ?? 'Unknown';
    
    return [
      CircleAvatar(
        radius: 12,
        backgroundColor: isAssigned 
            ? Colors.green[100]
            : Colors.indigo[100],
        child: Text(
          _getInitials(secretaryName),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isAssigned ? Colors.green : Colors.indigo,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          secretaryName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isAssigned ? Colors.green[700] : Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (isAssigned)
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        ),
    ];
  }

  void _showSecretarySelectionBottomSheet() {
    if (_selectedLocation == null || _isLoadingSecretaries) {
      return;
    }

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
                      Icons.person,
                      color: const Color(0xFFF97316),
                      size: 24,
                    ),
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

              // Secretary list
              Expanded(
                child: _isLoadingSecretaries
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _availableAssignees.isEmpty
                        ? const Center(
                            child: Text(
                              'No secretaries available for this location',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _availableAssignees.length + 1, // +1 for "None" option
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // "None" option
                                final isSelected = _selectedSecretary == null;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF97316).withOpacity(0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFF97316)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      setState(() {
                                        _selectedSecretary = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? const Color(0xFFF97316)
                                          : Colors.grey[300],
                                      child: Icon(
                                        Icons.person_off,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                    title: const Text(
                                      'None - I am not in touch with any secretary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFF97316),
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                );
                              }

                              // Secretary options
                              final secretaryIndex = index - 1;
                              final secretary = _availableAssignees[secretaryIndex];
                              final isSelected = secretary['id']?.toString() == _selectedSecretary;
                              final isAssigned = secretary['isAssigned'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF97316).withOpacity(0.1)
                                      : isAssigned
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF97316)
                                        : isAssigned
                                            ? Colors.green
                                            : Colors.grey[300]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      _selectedSecretary = secretary['id']?.toString();
                                    });
                                    Navigator.pop(context);
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? const Color(0xFFF97316)
                                        : isAssigned
                                            ? Colors.green
                                            : Colors.indigo[100],
                                    child: Text(
                                      _getInitials(secretary['name']?.toString() ?? ''),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : isAssigned
                                                ? Colors.white
                                                : Colors.indigo,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    secretary['name']?.toString() ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFFF97316)
                                          : isAssigned
                                              ? Colors.green[700]
                                              : Colors.black87,
                                    ),
                                  ),
                                  subtitle: isAssigned
                                      ? const Text(
                                          'Currently assigned',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFF97316),
                                          size: 24,
                                        )
                                      : isAssigned
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            )
                                          : null,
                                ),
                              );
                            },
                          ),
              ),

              // Done button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
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
      ),
    );
  }

  void _updateSelectedSecretary(String? secretaryId) {
    setState(() {
      _selectedSecretary = secretaryId;
    });
  }

  void _updateSelectedLocation(String? locationId) {
    setState(() {
      _selectedLocation = locationId;
    });
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isPickingFile = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Check file size (5MB limit)
        if (file.size > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 5MB'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });
        

        // File selected successfully
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isPickingFile = false;
      });
    }
  }

  Widget _buildSecretarySelectionContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Available secretaries for this location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoadingSecretaries)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // Error message if any
              if (_secretaryErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _secretaryErrorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Secretary list
              Flexible(
                child: _isLoadingSecretaries
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading secretaries...'),
                            ],
                          ),
                        ),
                      )
                    : _availableAssignees.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No secretaries available for this location',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _availableAssignees.map((assignee) {
                                final isAssigned = assignee['isAssigned'] == true;
                                final isSelected = assignee['id']?.toString() == _selectedSecretary;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? Colors.blue.withOpacity(0.1)
                                        : isAssigned 
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue.withOpacity(0.5)
                                          : isAssigned 
                                              ? Colors.green.withOpacity(0.5)
                                              : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedSecretary = assignee['id']?.toString();
                                      });
                                      setModalState(() {}); // Rebuild the modal
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [

                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: isSelected
                                                ? Colors.blue[100]
                                                : isAssigned 
                                                    ? Colors.green[100]
                                                    : Colors.indigo[100],
                                            child: Text(
                                              _getInitials(assignee['name']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.blue
                                                    : isAssigned ? Colors.green : Colors.indigo,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              assignee['name'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.blue[700]
                                                    : isAssigned ? Colors.green[700] : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 20,
                                            )
                                          else if (isAssigned)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
              ),
              
              // Done button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
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
        );
      },
    );
  }

  Widget _buildAttachmentField() {
    final existingAttachment = widget.appointment['appointmentAttachment']?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachment (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You can attach documents (PDF, DOC, DOCX, XLS, XLSX, TXT) or images (JPG, PNG, GIF) (Max size: 5MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 12),
        
        // Show existing attachment if available
        if (existingAttachment.isNotEmpty) ...[
          _buildExistingAttachmentDisplay(existingAttachment),
          const SizedBox(height: 16),
        ],
        
        // File selection area
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedFile != null ? Colors.blue[300]! : Colors.grey[300]!,
              width: _selectedFile != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _selectedFile != null
              ? _buildSelectedFileDisplay()
              : _buildFilePickerArea(),
        ),
      ],
    );
  }

  Widget _buildSelectedFileDisplay() {
    final extension = _selectedFile!.extension ?? '';
    final fileColor = _getFileColor(extension);
    
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          // File icon with color
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileIcon(extension),
              color: fileColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedFile!.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        extension.toUpperCase(),
                        style: TextStyle(
                          color: fileColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          Container(
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedFile = null;
                });
                // File removed
              },
              icon: Icon(
                Icons.close,
                color: Colors.red[600],
                size: 18,
              ),
              tooltip: 'Remove file',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerArea() {
    return InkWell(
      onTap: _isPickingFile ? null : _pickFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.upload_file,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isPickingFile ? 'Selecting file...' : 'Upload New Attachment',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            _isPickingFile
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Browse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  // Helper method to get attachment filename from URL
  String _getAttachmentFilename(String attachmentUrl) {
    if (attachmentUrl.isNotEmpty) {
      final uri = Uri.parse(attachmentUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    }
    return 'Attachment';
  }

  // Helper method to get file extension
  String _getFileExtension(String filename) {
    if (filename.contains('.')) {
      return filename.split('.').last.toLowerCase();
    }
    return '';
  }

  // Helper method to get file color based on extension
  Color _getFileColor(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'txt':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Method to open existing attachment
  Future<void> _openExistingAttachment(String attachmentUrl) async {
    try {
      final Uri url = Uri.parse(attachmentUrl);
      
      // Try to open in browser directly
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // If canLaunchUrl returns false, try anyway with external application
        try {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } catch (e) {
          // If that fails, try platform default
          try {
            await launchUrl(url, mode: LaunchMode.platformDefault);
          } catch (e) {
            // Final fallback: in-app web view
            await launchUrl(url, mode: LaunchMode.inAppWebView);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening attachment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Build existing attachment display
  Widget _buildExistingAttachmentDisplay(String attachmentUrl) {
    final filename = _getAttachmentFilename(attachmentUrl);
    final extension = _getFileExtension(filename);
    final fileColor = _getFileColor(extension);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!.withOpacity(0.5),
            Colors.indigo[50]!.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue[100]!.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.attach_file, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                'CURRENT ATTACHMENT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Attachment card
          InkWell(
            onTap: () => _openExistingAttachment(attachmentUrl),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  // File icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: fileColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getFileIcon(extension),
                      color: fileColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // File details
                  Expanded(
                    child: Text(
                      'Click to view current attachment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  // Open icon
                  Icon(
                    Icons.open_in_new,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Info text
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Uploading a new file will replace the current attachment',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorField(String label, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRadioOption(String label, String value, String selectedValue, Function(String) onChanged) {
    final isSelected = selectedValue == value;
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInformationSection() {
    // Safety check - ensure controllers are initialized
    if (_guests.isNotEmpty && _guestControllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeGuestControllers();
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Details of Additional People',
        //   style: TextStyle(
        //     fontSize: 18,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.grey[800],
        //   ),
        // ),
        // const SizedBox(height: 16),
        ...List.generate(_guests.length, (index) {
          // Only generate cards if we have corresponding controllers
          if (index >= _guestControllers.length) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              _buildGuestCard(index),
              if (index < _guests.length - 1) const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildGuestCard(int index) {
    // Safety check to prevent index out of bounds
    if (index >= _guests.length || index >= _guestControllers.length) {
      return const SizedBox.shrink();
    }
    
    final guest = _guests[index];
    final guestNumber = index + 1;
    final controllers = _guestControllers[index];
    
    // Check if photo is required (age >= 12)
    final age = int.tryParse(controllers['age']?.text ?? '0') ?? 0;
    final isPhotoRequired = age >= 12;
    
    // Debug: Print age and unique phone code visibility
    print('Guest $guestNumber - Age: $age, Should show unique phone code: ${age < 12 || age > 60}');
    print('  - Age text: ${controllers['age']?.text}');
    print('  - Unique phone code text: ${controllers['uniquePhoneCode']?.text}');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guest header
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
              'Detail of Person ${guestNumber +1 }',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF97316),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Guest details - editable fields
          Column(
            children: [
              // Name
              _buildEditableGuestField('Full Name', controllers['name']!),
              const SizedBox(height: 12),
              
              // Age
              _buildEditableAgeField('Age *', controllers['age']!),
              const SizedBox(height: 12),

              // Unique Phone Code (only show if age < 12 or age > 60)
              if (age < 12 || age > 60) ...[
                _buildUniquePhoneCodeField('Unique Phone Code (Optional)', controllers['uniquePhoneCode']!),
                const SizedBox(height: 4),
                Text(
                  'If you provide a unique phone code, the phone number field becomes optional',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Phone
              _buildAccompanyingUserPhoneField(guestNumber, controllers['phone']!),
              
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
                  'Photo of the person Required for Age 12 years and Above',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                
                // Photo Upload Options
                Column(
                  children: [
                    // Upload from Device Card
                    GestureDetector(
                      onTap: () => _pickGuestImage(index, ImageSource.gallery),
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
                      onTap: () => _pickGuestImage(index, ImageSource.camera),
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
                    if ((_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty) ||
                        _guestUploading[guestNumber] == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _guestUploading[guestNumber] == true
                              ? Colors.blue[50]
                              : (_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty
                                    ? Colors.green[50]
                                    : Colors.orange[50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _guestUploading[guestNumber] == true
                                ? Colors.blue[200]!
                                : (_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty
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
                                      : (_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty)
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
                                      if (_guestUploading[guestNumber] == true) ...[
                                        const Text(
                                          'Uploading photo...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ] else if (_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty) ...[
                                        const Text(
                                          'Photo uploaded successfully',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Person photo is ready',
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
                            if (_guestImages.containsKey(guestNumber) && _guestImages[guestNumber]!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              
                              Column(
                                children: [
                                  // Upload Different Photo
                                  GestureDetector(
                                    onTap: () => _pickGuestImage(
                                      index,
                                      ImageSource.gallery,
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
                                      index,
                                      ImageSource.camera,
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
        ],
      ),
    );
  }

  Widget _buildGuestField(String label, String value, {bool isRequired = false, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '$label *' : label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }



  // Phone field for accompanying users with country code
  Widget _buildAccompanyingUserPhoneField(int guestNumber, TextEditingController controller) {
    // Find the guest data to check age and unique phone code
    final guestIndex = guestNumber - 1;
    final age = guestIndex < _guestControllers.length 
        ? int.tryParse(_guestControllers[guestIndex]['age']?.text ?? '0') ?? 0
        : 0;
    final hasUniquePhoneCode = guestIndex < _guestControllers.length 
        ? _guestControllers[guestIndex]['uniquePhoneCode']?.text.isNotEmpty == true
        : false;
    
    // Determine if phone is required
    final isPhoneRequired = !(age < 12 || age > 60) || !hasUniquePhoneCode;
    final phoneLabel = isPhoneRequired ? 'Contact Number *' : 'Contact Number (Optional)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          phoneLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code picker
            GestureDetector(
              onTap: () {
                showCountryPicker(
                  context: context,
                  showPhoneCode: true,
                  countryListTheme: CountryListThemeData(
                    flagSize: 25,
                    backgroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: 16, color: Colors.black),
                    bottomSheetHeight: 500,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    inputDecoration: InputDecoration(
                      labelText: 'Search',
                      hintText: 'Start typing to search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 8, 191, 214),
                        ),
                      ),
                    ),
                  ),
                  onSelect: (Country country) {
                    setState(() {
                      _guestCountries[guestNumber] = country.phoneCode;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _guestCountries[guestNumber] ?? '+91',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
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
                    borderSide: BorderSide(color: const Color(0xFFF97316)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.red[300]!),
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

  Widget _buildGuestPhotoSection(int index) {
    final guest = _guests[index];
    final hasPhoto = guest['profilePhotoUrl']?.isNotEmpty == true;
    
    // Check if guest age is above 11
    final ageString = guest['age']?.toString() ?? '';
    int? age;
    try {
      age = int.tryParse(ageString);
    } catch (e) {
      age = null;
    }
    
    // Only show photo section if age is above 11
    if (age == null || age <= 11) {
      return const SizedBox.shrink(); // Return empty widget if age is 11 or below
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildPhotoContent(index),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent(int guestIndex) {
    final guest = _guests[guestIndex];
    final isUploading = guest['isUploading'] == true;
    final hasPhoto = guest['profilePhotoUrl']?.isNotEmpty == true;
    
    if (isUploading) {
      return _buildPhotoUploadingState(guestIndex);
    } else if (hasPhoto) {
      return _buildPhotoUploadedState(guest['profilePhotoUrl']!, guestIndex);
    } else {
      return _buildPhotoNotUploadedState(guestIndex);
    }
  }

  Widget _buildPhotoUploadingState(int guestIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        children: [
          // Loading spinner
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Status text
          Text(
            'Uploading photo...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload, color: Colors.blue[800], size: 14),
                const SizedBox(width: 4),
                Text(
                  'Processing...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadedState(String photoUrl, int guestIndex) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Column(
            children: [
              // Photo preview
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: photoUrl.startsWith('http')
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(photoUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: 32,
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Status text
              Text(
                'Photo uploaded',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.yellow[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.yellow[800], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified & Uploaded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.yellow[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Action buttons
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickGuestImage(guestIndex, ImageSource.gallery),
                icon: Icon(Icons.upload, size: 16),
                label: const Text('Upload Different Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickGuestImage(guestIndex, ImageSource.camera),
                icon: Icon(Icons.camera_alt, size: 16),
                label: const Text('Take New Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          ],
        ),
      ],
    );
  }

  // Send appointment update notification
  Future<void> _sendAppointmentUpdatedNotification(Map<String, dynamic>? appointmentData) async {
    try {
      final appointmentId = _getAppointmentId();
      
      if (appointmentId.isEmpty) {
        return;
      }


      // For admin edit forms, we'll use the userId from the appointment data
      final userId = appointmentData?['userId']?.toString() ?? 
                    widget.appointment['userId']?.toString() ?? 
                    'admin_updated';

      // Prepare appointment data for notification
      final notificationAppointmentData = {
        'fullName': appointmentData?['appointmentFor']?['personalInfo']?['fullName'] ?? 
                   widget.appointment['appointmentFor']?['personalInfo']?['fullName'] ?? 
                   'User',
        'date': appointmentData?['preferredDateRange']?['fromDate'] ?? 
               widget.appointment['preferredDateRange']?['fromDate'] ?? 
               _fromDateController.text,
        'time': 'Updated', // Time is part of the date range
        'venue': appointmentData?['appointmentLocation'] ?? 
                widget.appointment['appointmentLocation'] ?? 
                _selectedLocation ?? 'Selected Location',
        'purpose': appointmentData?['appointmentPurpose'] ?? 
                  widget.appointment['appointmentPurpose'] ?? 
                  _purposeController.text,
        'numberOfUsers': appointmentData?['numberOfUsers'] ?? 
                        widget.appointment['numberOfUsers'] ?? 
                        _numberOfPeopleController.text,
        'appointmentType': widget.appointment['appointmentType'] ?? 'myself',
      };

      // Prepare additional notification data
      final notificationData = {
        'source': 'mobile_app',
        'formType': 'admin_appointment_update',
        'userRole': 'admin', // This is an admin form
        'timestamp': DateTime.now().toIso8601String(),
        'appointmentType': widget.appointment['appointmentType'] ?? 'myself',
        'updateType': 'updated',
        'updatedBy': 'admin',
      };

      // Send the notification
      final result = await ActionService.sendAppointmentUpdatedNotification(
        userId: userId,
        appointmentId: appointmentId,
        appointmentData: notificationAppointmentData,
        updateType: 'updated',
        notificationData: notificationData,
      );

      if (result['success']) {
      } else {
      }

    } catch (e) {
      // Don't block the appointment update flow if notification fails
    }
  }

  Widget _buildPhotoNotUploadedState(int guestIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No photo uploaded',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Required for guests 12+ years old - Divine pic validation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickGuestImage(guestIndex, ImageSource.gallery),
                  icon: Icon(Icons.upload, size: 16),
                  label: const Text('Upload Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickGuestImage(guestIndex, ImageSource.camera),
                  icon: Icon(Icons.camera_alt, size: 16),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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