import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../action/action.dart';
import '../../action/storage_service.dart';
import '../../action/jwt_utils.dart';

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
  
  // Loading state
  bool _isSubmitting = false;
  
  // Form state
  String? _selectedLocation;
  String? _selectedSecretary;
  String _teacherStatus = 'no';
  String _attendingProgram = 'no';
  
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
    
    // Initialize guest information
    _initializeGuestData();
    
    // Get number of people from accompanyUsers object
    String numberOfPeople = '1';
    final accompanyUsers = widget.appointment['accompanyUsers'];
    print('DEBUG: accompanyUsers = $accompanyUsers');
    
    if (accompanyUsers is Map<String, dynamic>) {
      final numberOfUsers = accompanyUsers['numberOfUsers'];
      print('DEBUG: numberOfUsers = $numberOfUsers');
      if (numberOfUsers != null) {
        numberOfPeople = numberOfUsers.toString();
        print('DEBUG: Setting numberOfPeople = $numberOfPeople');
      }
    }
    
    print('DEBUG: Final numberOfPeople = $numberOfPeople');
    _numberOfPeopleController = TextEditingController(
      text: numberOfPeople,
    );
    
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
      print('DEBUG: Set selected secretary to: $_selectedSecretary');
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
    _numberOfPeopleController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _companyController.dispose();
    _designationController.dispose();
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
      print('Error in _getCreatedByName: $e');
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
      print('Error in _getCreatedByEmail: $e');
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
            return '$countryCode $number';
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
          return '$countryCode $number';
        }
      }
      
      final phone = widget.appointment['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        return phone;
      }
      
      return 'Not specified';
    } catch (e) {
      print('Error in _getCreatedByPhone: $e');
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
      print('Error in _getCreatedByDesignation: $e');
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
      print('Error in _getCreatedByCompany: $e');
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
          };
        }).toList();
      }
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
        setState(() {
          _guests[guestIndex]['profilePhotoUrl'] = pickedFile.path;
          _guests[guestIndex]['localPhotoFile'] = File(pickedFile.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera 
                    ? 'Photo captured successfully!' 
                    : 'Photo uploaded successfully!'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
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
      _guests[guestIndex]['profilePhotoUrl'] = '';
      _guests[guestIndex]['localPhotoFile'] = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo removed successfully!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _getGuestIndexFromPhotoUrl(String photoUrl) {
    for (int i = 0; i < _guests.length; i++) {
      if (_guests[i]['profilePhotoUrl'] == photoUrl) {
        return i;
      }
    }
    return 0; // Fallback to first guest
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? '';
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
      print('Error loading current user: $e');
    }
  }

  // Load secretaries (same as assign_form.dart)
  Future<void> _loadSecretaries() async {
    try {
      setState(() {
        _isLoadingSecretaries = true;
        _secretaryErrorMessage = null;
      });

      // Extract location ID from appointment data
      final locationId = _extractLocationId();
      print('DEBUG: Extracted locationId = $locationId');
      
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
              print('DEBUG: Auto-selected assigned secretary: $_selectedSecretary');
            }
          } catch (e) {
            print('DEBUG: Could not find assigned secretary in list');
          }
        }
        
        // If still no secretary selected, select the first available one
        if (_selectedSecretary == null && secretaries.isNotEmpty) {
          setState(() {
            _selectedSecretary = secretaries.first['id']?.toString();
          });
          print('DEBUG: Auto-selected first secretary: $_selectedSecretary');
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
    print('DEBUG: scheduledDateTime = $scheduledDateTime');
    if (scheduledDateTime is Map<String, dynamic>) {
      final venue = scheduledDateTime['venue'];
      print('DEBUG: venue from scheduledDateTime = $venue');
      if (venue != null) {
        print('DEBUG: Using venue from scheduledDateTime = $venue');
        return venue.toString();
      }
    }

    // Try appointmentLocation field
    final appointmentLocation = widget.appointment['appointmentLocation'];
    print('DEBUG: appointmentLocation = $appointmentLocation');
    if (appointmentLocation != null) {
      // If it's an object, extract the _id field
      if (appointmentLocation is Map<String, dynamic>) {
        final id = appointmentLocation['_id']?.toString();
        print('DEBUG: Extracted _id from appointmentLocation = $id');
        return id;
      }
      print('DEBUG: Using appointmentLocation as string = ${appointmentLocation.toString()}');
      return appointmentLocation.toString();
    }

    // Try location field
    final location = widget.appointment['location'];
    print('DEBUG: location = $location');
    if (location != null) {
      // If it's an object, extract the _id field
      if (location is Map<String, dynamic>) {
        final id = location['_id']?.toString();
        print('DEBUG: Extracted _id from location = $id');
        return id;
      }
      print('DEBUG: Using location as string = ${location.toString()}');
      return location.toString();
    }

    // Try venue field directly
    final venue = widget.appointment['venue'];
    print('DEBUG: venue = $venue');
    if (venue != null) {
      // If it's an object, extract the _id field
      if (venue is Map<String, dynamic>) {
        final id = venue['_id']?.toString();
        print('DEBUG: Extracted _id from venue = $id');
        return id;
      }
      print('DEBUG: Using venue as string = ${venue.toString()}');
      return venue.toString();
    }

    // If no location ID found, return null
    print('DEBUG: No location ID found');
    return null;
  }

  // Debug method to print appointment structure
  void _debugAppointmentStructure() {
    print('=== APPOINTMENT DEBUG INFO ===');
    print('Appointment keys: ${widget.appointment.keys.toList()}');
    
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      print('CreatedBy keys: ${createdBy.keys.toList()}');
      print('CreatedBy phone: ${createdBy['phone']}');
      print('CreatedBy designation: ${createdBy['designation']}');
      print('CreatedBy company: ${createdBy['company']}');
    } else {
      print('CreatedBy is not a Map: $createdBy');
    }
    
    print('Direct phone: ${widget.appointment['phone']}');
    print('Direct designation: ${widget.appointment['designation']}');
    print('Direct company: ${widget.appointment['company']}');
    
    // Debug accompanyUsers
    final accompanyUsers = widget.appointment['accompanyUsers'];
    print('AccompanyUsers: $accompanyUsers');
    if (accompanyUsers is Map<String, dynamic>) {
      print('AccompanyUsers keys: ${accompanyUsers.keys.toList()}');
      print('AccompanyUsers numberOfUsers: ${accompanyUsers['numberOfUsers']}');
    }
    
    print('=== END DEBUG INFO ===');
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
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
        'attendingProgram': _attendingProgram,
        'isTeacher': _teacherStatus,
        // Add required fields that the API expects
        'appointmentFor': {
          'type': 'myself', // Default to myself since we're editing existing appointment
        },
        'appointmentType': 'myself', // Default to myself
        'accompanyUsers': _getAccompanyUsersData(),
        'attendingCourseDetails': {
          'isAttending': _attendingProgram == 'yes',
          'fromDate': _fromDateController.text,
          'toDate': _toDateController.text,
        },
      };

      // Debug: Print the update data being sent
      print('DEBUG: Sending update data: $updateData');
      print('DEBUG: Appointment ID: $appointmentId');

      // Call the API to update appointment
      final result = await ActionService.updateAppointmentEnhanced(
        appointmentId: appointmentId,
        updateData: updateData,
        attachmentFile: _selectedFile,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Appointment updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
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
              duration: Duration(seconds: 5),
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
            duration: Duration(seconds: 3),
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
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      final numberOfUsers = accompanyUsers['numberOfUsers'];
      final users = accompanyUsers['users'];
      
      if (numberOfUsers != null && users is List) {
        return {
          'numberOfUsers': numberOfUsers,
          'users': users,
        };
      }
    }
    
    // If no existing accompanyUsers data, return null to skip this field
    return null;
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
                    // Personal Information Section
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
                    
                                          // Number of People
                      _buildNumberField(
                        'Number of People',
                        _numberOfPeopleController,
                        'Number of people for the appointment',
                        isRequired: true,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Guest Information Section
                      if (_guests.isNotEmpty) ...[
                        _buildGuestInformationSection(),
                        const SizedBox(height: 16),
                      ],
                      
                      // Attachment Field
                      _buildAttachmentField(),
                      
                      const SizedBox(height: 16),
                    
                    // Date Range
                    _buildDateRangeSection(),
                    
                    const SizedBox(height: 16),
                    
                    // Attending Program Radio
                    _buildProgramRadioGroup(),
                    
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
              child:                          _buildRadioOption(
                           'No',
                           'no',
                           _teacherStatus,
                           (value) => setState(() => _teacherStatus = value),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: _buildRadioOption(
                           'Part-time',
                           'part-time',
                           _teacherStatus,
                           (value) => setState(() => _teacherStatus = value),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: _buildRadioOption(
                           'Full-time',
                           'full-time',
                           _teacherStatus,
                           (value) => setState(() => _teacherStatus = value),
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
          keyboardType: TextInputType.number,
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
            final number = int.tryParse(value);
            if (number == null || number < 1) {
              return 'Please enter a valid number (minimum 1)';
            }
            return null;
          } : null,
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the number of people for the appointment',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            'ℹ️ For appointments with more than 10 people, individual details for additional accompanying people are not required. The appointment will be processed with the main contact information and guest details.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[800],
            ),
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
        Row(
          children: [
            Expanded(
              child: _buildDateField('From Date', _fromDateController),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField('To Date', _toDateController),
            ),
          ],
        ),
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
              const Icon(Icons.calendar_today, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📅 Selected Range: 9 days\nFrom 02/08/2025 to 10/08/2025',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildProgramRadioGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Are you attending any program at the Bangalore Ashram during these dates? *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSimpleRadioOption('Yes', 'yes', _attendingProgram, (value) => setState(() => _attendingProgram = value)),
            const SizedBox(width: 16),
            _buildSimpleRadioOption('No', 'no', _attendingProgram, (value) => setState(() => _attendingProgram = value)),
          ],
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
        Text(
          'Appointment Location *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLoadingLocations ? null : () => _showLocationSelectionBottomSheet(),
          child: Container(
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
                if (_isLoadingLocations) ...[
                  // Show loading state
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading locations...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ] else if (_locationErrorMessage != null) ...[
                  // Show error state
                  Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error loading locations',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else if (_selectedLocation != null) ...[
                  // Show selected location
                  Icon(
                    Icons.location_on,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getSelectedLocationName(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  // Show placeholder
                  Text(
                    'Select location',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
                const Spacer(),
                if (!_isLoadingLocations && _locationErrorMessage == null)
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
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
      builder: (context) => _buildLocationSelectionContent(),
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
                                          print('DEBUG: Tapped location: ${location['name']} with ID: ${location['id']}');
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
        Text(
          'Have you been in touch with any secretary regarding your appointment?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSecretarySelectionBottomSheet(),
          child: Container(
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
                if (_selectedSecretary != null) ...[
                  // Show selected secretary with avatar and check icon
                  ..._buildSelectedSecretaryDisplay(),
                ] else ...[
                  // Show placeholder
                  Text(
                    'Select secretary',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSecretarySelectionContent(),
    );
  }

  void _updateSelectedSecretary(String? secretaryId) {
    setState(() {
      _selectedSecretary = secretaryId;
    });
    print('DEBUG: Updated _selectedSecretary to: $_selectedSecretary');
  }

  void _updateSelectedLocation(String? locationId) {
    setState(() {
      _selectedLocation = locationId;
    });
    print('DEBUG: Updated _selectedLocation to: $_selectedLocation');
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isPickingFile = true;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
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

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: ${file.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _availableAssignees.map((assignee) {
                                final isAssigned = assignee['isAssigned'] == true;
                                final isSelected = assignee['id']?.toString() == _selectedSecretary;
                                print('DEBUG: Secretary ${assignee['name']} - ID: ${assignee['id']}, Selected: $isSelected, Assigned: $isAssigned');
                                
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
                                      print('DEBUG: Tapped secretary: ${assignee['name']} with ID: ${assignee['id']}');
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
          'You can attach a project proposal, report, or invitation (Max size: 5MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 12),
        
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
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            _getFileIcon(_selectedFile!.extension ?? ''),
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB • ${_selectedFile!.extension?.toUpperCase() ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedFile = null;
              });
            },
            icon: Icon(
              Icons.close,
              color: Colors.red[600],
              size: 20,
            ),
            tooltip: 'Remove file',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.attach_file,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isPickingFile ? 'Selecting file...' : 'Choose file (.pdf, .doc, .docx, .ppt, .pptx)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
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
                : Text(
                    'Browse',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.attach_file;
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details of Additional People',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_guests.length, (index) {
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
    final guest = _guests[index];
    final guestNumber = index + 1;
    
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
          Row(
            children: [
              Text(
                'Guest $guestNumber',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (guest['profilePhotoUrl']?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Photo uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Guest details grid
          Column(
            children: [
              // Full Name
              _buildGuestField(
                'Full Name',
                guest['fullName'] ?? '',
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              // Contact Number
              _buildGuestField(
                'Contact Number',
                guest['phoneNumber'] ?? '',
                isRequired: true,
              ),
              const SizedBox(height: 16),
              
              // Age
              _buildGuestField(
                'Age',
                guest['age'] ?? '',
                isRequired: true,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              
              // Photo section
              _buildGuestPhotoSection(index),
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

  Widget _buildGuestPhotoSection(int index) {
    final guest = _guests[index];
    final hasPhoto = guest['profilePhotoUrl']?.isNotEmpty == true;
    
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
                  'Guest ${index + 1} Photo',
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
            child: hasPhoto
                ? _buildPhotoUploadedState(guest['profilePhotoUrl']!, index)
                : _buildPhotoNotUploadedState(index),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _removeGuestPhoto(guestIndex),
                icon: Icon(Icons.close, size: 16),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[300]!),
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
}