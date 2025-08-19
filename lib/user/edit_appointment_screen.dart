import 'package:flutter/material.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import 'user_screen.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:country_picker/country_picker.dart';
import '../components/user/photo_validation_bottom_sheet.dart';

class EditAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointmentData;

  const EditAppointmentScreen({
    super.key,
    this.appointmentData,
  });

  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  // Form controllers
  final TextEditingController _appointmentPurposeController = TextEditingController();
  final TextEditingController _numberOfUsersController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  
  // Reference Information Controllers (for guest appointments)
  final TextEditingController _referenceNameController = TextEditingController();
  final TextEditingController _referenceEmailController = TextEditingController();
  final TextEditingController _referencePhoneController = TextEditingController();
  
  // Guest Information Controllers (for guest appointments)
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestEmailController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  final TextEditingController _guestDesignationController = TextEditingController();
  final TextEditingController _guestCompanyController = TextEditingController();
  final TextEditingController _guestLocationController = TextEditingController();
  
  // Form state
  bool _isFormValid = false;
  String? _selectedSecretary;
  String? _selectedSecretaryName;
  String? _selectedAppointmentLocation;
  String? _selectedLocationId;
  String? _selectedLocationMongoId;
  File? _selectedImage;
  bool _isAttendingProgram = false;
  
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
    return widget.appointmentData?['appointmentType']?.toString().toLowerCase() ?? 
           widget.appointmentData?['appointmentFor']?['type']?.toString().toLowerCase() ?? 
           'myself';
  }

  // Check if this is a guest appointment
  bool get _isGuestAppointment => _appointmentType == 'guest';

  @override
  void initState() {
    super.initState();
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
    _fromDateController.dispose();
    _toDateController.dispose();
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
      _appointmentPurposeController.text = appointment['appointmentPurpose']?.toString() ?? 
                                          appointment['appointmentSubject']?.toString() ?? '';
      
      // Load date range
      final preferredDateRange = appointment['preferredDateRange'];
      if (preferredDateRange != null) {
        final fromDate = preferredDateRange['fromDate'];
        final toDate = preferredDateRange['toDate'];
        
        if (fromDate != null) {
          final from = DateTime.parse(fromDate);
          _fromDateController.text = '${from.day.toString().padLeft(2, '0')}/${from.month.toString().padLeft(2, '0')}/${from.year}';
        }
        
        if (toDate != null) {
          final to = DateTime.parse(toDate);
          _toDateController.text = '${to.day.toString().padLeft(2, '0')}/${to.month.toString().padLeft(2, '0')}/${to.year}';
        }
      }

      // Load location
      final appointmentLocation = appointment['appointmentLocation'];
      if (appointmentLocation != null) {
        if (appointmentLocation is Map<String, dynamic>) {
          _selectedAppointmentLocation = appointmentLocation['name']?.toString();
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

      // Load guest-specific data if this is a guest appointment
      if (_isGuestAppointment) {
        _loadGuestData(appointment);
      }

      // Load accompanying users data
      _loadAccompanyingUsersData(appointment);

      // Set the number of users based on the loaded data
      final accompanyUsers = appointment['accompanyUsers'];
      print('DEBUG LOAD: Setting numberOfUsers. accompanyUsers: $accompanyUsers');
      if (accompanyUsers != null && accompanyUsers['users'] != null) {
        final List<dynamic> users = accompanyUsers['users'];
        // If users array is empty, set to 1 (just main user)
        if (users.isEmpty) {
          _numberOfUsersController.text = '1';
          print('DEBUG LOAD: Set numberOfUsers to 1 (empty users array)');
        } else {
          // Set number of users to 1 (main user) + number of accompanying users
          _numberOfUsersController.text = (users.length + 1).toString();
          print('DEBUG LOAD: Set numberOfUsers to ${users.length + 1} (${users.length} accompanying + 1 main)');
        }
      } else {
        _numberOfUsersController.text = '1';
        print('DEBUG LOAD: Set numberOfUsers to 1 (no accompanying users)');
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
      _guestNameController.text = guestInformation['fullName']?.toString() ?? '';
      _guestEmailController.text = guestInformation['emailId']?.toString() ?? '';
      _guestDesignationController.text = guestInformation['designation']?.toString() ?? '';
      _guestCompanyController.text = guestInformation['company']?.toString() ?? '';
      _guestLocationController.text = guestInformation['location']?.toString() ?? '';
      
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
            // Set combined format: +countryCode + number
            final cleanCountryCode = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
            _guestPhoneController.text = '+$cleanCountryCode$number';
            print('📞 Parsed main guest phone: +$cleanCountryCode$number');
            
            // Set country
            _selectedCountry = Country(
              phoneCode: cleanCountryCode,
              countryCode: 'IN', // Default to India
              e164Sc: 0,
              geographic: true,
              level: 1,
              name: 'India',
              example: '9876543210',
              displayName: 'India (IN) [+$cleanCountryCode]',
              displayNameNoCountryCode: 'India (IN)',
              e164Key: '$cleanCountryCode-IN-0',
            );
          }
        } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
          // Fallback: phone number is stored as a string
          if (phoneNumber.startsWith('+')) {
            final parts = phoneNumber.substring(1).split(' ');
            if (parts.length >= 2) {
              final countryCode = parts[0];
              final number = parts.sublist(1).join('');
              _guestPhoneController.text = '+$countryCode$number';
              print('📞 Parsed main guest phone: +$countryCode$number');
              
              // Set country
              _selectedCountry = Country(
                phoneCode: countryCode,
                countryCode: 'IN', // Default to India
                e164Sc: 0,
                geographic: true,
                level: 1,
                name: 'India',
                example: '9876543210',
                displayName: 'India (IN) [+$countryCode]',
                displayNameNoCountryCode: 'India (IN)',
                e164Key: '$countryCode-IN-0',
              );
            } else {
              _guestPhoneController.text = phoneNumber;
              print('📞 Main guest phone (no country code): $phoneNumber');
            }
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
    if (referenceInformation != null && referenceInformation is Map<String, dynamic>) {
      _referenceNameController.text = referenceInformation['fullName']?.toString() ?? '';
      _referenceEmailController.text = referenceInformation['email']?.toString() ?? '';
      _referencePhoneController.text = referenceInformation['phoneNumber']?.toString() ?? '';
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
          final nameController = TextEditingController(text: user['fullName']?.toString() ?? '');
          final phoneController = TextEditingController();
          final ageController = TextEditingController(text: user['age']?.toString() ?? '');

          // Parse phone number
          final phoneNumber = user['phoneNumber'];
          print('📞 Loading accompanying user $guestNumber phone number: $phoneNumber');
          if (phoneNumber != null) {
            if (phoneNumber is Map<String, dynamic>) {
              // Phone number is stored as an object with countryCode and number
              final countryCode = phoneNumber['countryCode']?.toString() ?? '';
              final number = phoneNumber['number']?.toString() ?? '';
              
              if (number.isNotEmpty) {
                // Set combined format: +countryCode + number
                final cleanCountryCode = countryCode.startsWith('+') ? countryCode.substring(1) : countryCode;
                phoneController.text = '+$cleanCountryCode$number';
                print('📞 Accompanying user $guestNumber phone: +$cleanCountryCode$number');
                
                _guestCountries[guestNumber] = Country(
                  phoneCode: cleanCountryCode,
                  countryCode: 'IN',
                  e164Sc: 0,
                  geographic: true,
                  level: 1,
                  name: 'India',
                  example: '9876543210',
                  displayName: 'India (IN) [+$cleanCountryCode]',
                  displayNameNoCountryCode: 'India (IN)',
                  e164Key: '$cleanCountryCode-IN-0',
                );
              }
            } else if (phoneNumber is String && phoneNumber.isNotEmpty) {
              // Fallback: phone number is stored as a string
              if (phoneNumber.startsWith('+')) {
                final parts = phoneNumber.substring(1).split(' ');
                if (parts.length >= 2) {
                  final countryCode = parts[0];
                  final number = parts.sublist(1).join('');
                  phoneController.text = '+$countryCode$number';
                  print('📞 Accompanying user $guestNumber phone: +$countryCode$number');
                  
                  _guestCountries[guestNumber] = Country(
                    phoneCode: countryCode,
                    countryCode: 'IN',
                    e164Sc: 0,
                    geographic: true,
                    level: 1,
                    name: 'India',
                    example: '9876543210',
                    displayName: 'India (IN) [+$countryCode]',
                    displayNameNoCountryCode: 'India (IN)',
                    e164Key: '$countryCode-IN-0',
                  );
                } else {
                  phoneController.text = phoneNumber;
                  print('📞 Accompanying user $guestNumber phone (no country code): $phoneNumber');
                }
              } else {
                phoneController.text = phoneNumber;
                print('📞 Accompanying user $guestNumber phone (no + prefix): $phoneNumber');
              }
            }
          } else {
            print('📞 No phone number found for accompanying user $guestNumber');
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
      final result = await ActionService.getAshramLocationByLocationId(locationId: _selectedLocationId!);
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
              'name': secretaryData['fullName']?.toString() ?? 'Unknown Secretary',
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
          _secretaryErrorMessage = result['message'] ?? 'Failed to load secretaries';
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
            // Show photo validation guidance bottom sheet
            PhotoValidationBottomSheet.show(
              context,
              onTryAgain: () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _mainGuestPhotoFile = null;
                  _mainGuestPhotoUrl = null;
                  _isMainGuestPhotoUploading = false;
                });
              },
            );
          }
        } catch (e) {
          setState(() {
            _isMainGuestPhotoUploading = false;
          });
          // Show photo validation guidance bottom sheet
          PhotoValidationBottomSheet.show(
            context,
            onTryAgain: () {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeMainGuestImage() {
    setState(() {
      _mainGuestPhotoUrl = null;
      _mainGuestPhotoFile = null;
    });
    _validateForm();
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
    int peopleCount = int.tryParse(_numberOfUsersController.text) ?? 0;
    int guestCount = peopleCount > 1 ? peopleCount - 1 : 0;
    
    print('DEBUG UPDATE: _updateGuestControllers - peopleCount: $peopleCount, guestCount: $guestCount, current controllers: ${_guestControllers.length}');
    
    // If we're reducing the number of guests, dispose extra controllers from the end
    if (_guestControllers.length > guestCount) {
      print('DEBUG UPDATE: Removing ${_guestControllers.length - guestCount} guest controllers');
      for (int i = guestCount; i < _guestControllers.length; i++) {
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
      _guestControllers.removeRange(guestCount, _guestControllers.length);
      print('DEBUG UPDATE: After removal, controllers count: ${_guestControllers.length}');
    }
    
    // If we need more guests, add them at the bottom
    while (_guestControllers.length < guestCount) {
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

  void _validateForm() {
    bool basicFormValid = _appointmentPurposeController.text.isNotEmpty &&
        _numberOfUsersController.text.isNotEmpty &&
        _fromDateController.text.isNotEmpty &&
        _toDateController.text.isNotEmpty;
    
    // Validate main guest photo if appointment type is guest
    bool mainGuestPhotoValid = true;
    if (_isGuestAppointment) {
      if (_mainGuestPhotoUrl == null) {
        mainGuestPhotoValid = false;
      }
    }
    
    // Validate guest information if any
    bool guestFormValid = true;
    if (_guestControllers.isNotEmpty) {
      for (var guest in _guestControllers) {
        if (guest['name']?.text.isEmpty == true ||
            guest['phone']?.text.isEmpty == true ||
            guest['age']?.text.isEmpty == true) {
          guestFormValid = false;
          break;
        }
      }
    }
    
    setState(() {
      _isFormValid = basicFormValid && mainGuestPhotoValid && guestFormValid;
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
        'preferredDateRange': {
          'fromDate': _parseDateToISO(_fromDateController.text),
          'toDate': _parseDateToISO(_toDateController.text),
        },
        'appointmentLocation': _selectedLocationMongoId,
        'assignedSecretary': _selectedSecretary,
        'numberOfUsers': int.tryParse(_numberOfUsersController.text) ?? 1,
      };

      // Add guest information if appointment type is guest
      if (_isGuestAppointment) {
        final phoneText = _guestPhoneController.text.trim();
        String fullPhoneNumber = phoneText;
        
        // If the phone number doesn't start with +, add the country code
        if (phoneText.isNotEmpty && !phoneText.startsWith('+')) {
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
      if (_guestControllers.isNotEmpty) {
        List<Map<String, dynamic>> accompanyUsers = [];
        for (int i = 0; i < _guestControllers.length; i++) {
          var guest = _guestControllers[i];
          int guestNumber = i + 1;
          
          final phoneText = guest['phone']?.text.trim() ?? '';
          String fullPhoneNumber = phoneText;
          
          // If the phone number doesn't start with +, add the country code
          if (phoneText.isNotEmpty && !phoneText.startsWith('+')) {
            final countryCode = '+${_guestCountries[guestNumber]?.phoneCode ?? '91'}';
            fullPhoneNumber = '$countryCode$phoneText';
          }
          
          print('📞 Saving accompanying user $guestNumber phone: $fullPhoneNumber');
          
          Map<String, dynamic> guestData = {
            'fullName': guest['name']?.text.trim() ?? '',
            'phoneNumber': fullPhoneNumber,
            'age': int.tryParse(guest['age']?.text ?? '0') ?? 0,
          };
          
          if (_guestImages.containsKey(guestNumber)) {
            guestData['profilePhotoUrl'] = _guestImages[guestNumber];
          }
          
          accompanyUsers.add(guestData);
        }
        
        updateData['accompanyUsers'] = {
          'numberOfUsers': accompanyUsers.length + 1, // +1 for main user
          'users': accompanyUsers,
        };
        print('DEBUG SAVE: Sending accompanyUsers with ${accompanyUsers.length} users');
      } else {
        // If no accompanying users, ensure numberOfUsers is set to 1 and clear accompanyUsers
        updateData['numberOfUsers'] = 1;
        // Try sending empty array instead of null to ensure backend clears the data
        updateData['accompanyUsers'] = {
          'numberOfUsers': 1,
          'users': [],
        };
        print('DEBUG SAVE: Setting accompanyUsers to empty array and numberOfUsers to 1');
      }

      // Call API to update appointment
      final appointmentId = widget.appointmentData?['appointmentId'] ?? 
                           widget.appointmentData?['_id'] ?? '';
      
      final result = await ActionService.updateAppointmentEnhanced(
        appointmentId: appointmentId,
        updateData: updateData,
      );

      if (result['success'] == true) {
        // Send appointment update notification
        await _sendAppointmentUpdatedNotification(result['data']);
        
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
          SnackBar(content: Text(result['message'] ?? 'Failed to update appointment')),
        );
      }
    } catch (e) {
      print('Error saving appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving appointment: $e')),
      );
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
        final date = DateTime(year, month, day);
        return date.toIso8601String().split('T')[0];
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return dateString;
  }

  // UI Helper Methods
  Widget _buildReferenceField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (_) => _validateForm(),
        ),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                Icon(
                  Icons.location_on,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedAppointmentLocation ?? 'Select a location',
                    style: TextStyle(
                      color: _selectedAppointmentLocation != null ? Colors.black87 : Colors.grey[600],
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
                    Icon(Icons.location_on, color: Colors.deepPurple, size: 24),
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
                          final locationName = location['name']?.toString() ?? '';
                          final isSelected = _selectedAppointmentLocation == locationName;
                          
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected ? Colors.deepPurple : Colors.grey[600],
                            ),
                            title: Text(
                              locationName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.deepPurple : Colors.black87,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check, color: Colors.deepPurple)
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedAppointmentLocation = locationName;
                                _selectedLocationId = location['locationId']?.toString();
                                _selectedLocationMongoId = location['_id']?.toString();
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
                Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 20,
                ),
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
                          : _secretaries.isEmpty
                              ? Text(
                                  'Select a secretary',
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

  String? _getSelectedSecretaryName() {
    print('🔍 _getSelectedSecretaryName() called');
    print('🔍 _selectedSecretary: $_selectedSecretary');
    print('🔍 _selectedSecretaryName: $_selectedSecretaryName');
    print('🔍 _secretaries count: ${_secretaries.length}');
    
    if (_selectedSecretary == null) return 'None - I am not in touch with any secretary';
    
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
                  Icon(Icons.person, color: Colors.deepPurple, size: 24),
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
                      color: _selectedSecretary == null ? Colors.deepPurple : Colors.grey[600],
                    ),
                    title: Text(
                      'None - I am not in touch with any secretary',
                      style: TextStyle(
                        fontWeight: _selectedSecretary == null ? FontWeight.w600 : FontWeight.normal,
                        color: _selectedSecretary == null ? Colors.deepPurple : Colors.black87,
                      ),
                    ),
                    trailing: _selectedSecretary == null
                        ? Icon(Icons.check, color: Colors.deepPurple)
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
                    final secretaryName = secretary['name']?.toString() ?? 'Unknown';
                    final isSelected = _selectedSecretary == secretaryId;
                    
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: isSelected ? Colors.deepPurple : Colors.grey[600],
                      ),
                      title: Text(
                        secretaryName,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Colors.deepPurple)
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
        final result = await ActionService.uploadAndValidateProfilePhoto(File(pickedFile.path));
        
        if (result['success']) {
          final s3Url = result['s3Url'];
          setState(() {
            _guestImages[guestNumber] = s3Url;
            _guestUploading[guestNumber] = false;
          });
          
          print('✅ Guest $guestNumber photo uploaded to S3: $s3Url');
          
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
          
          print('❌ Guest $guestNumber photo upload failed: ${result['message']}');
          
          // Show photo validation guidance bottom sheet
          PhotoValidationBottomSheet.show(
            context,
            onTryAgain: () {
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
        
        // Show photo validation guidance bottom sheet
        PhotoValidationBottomSheet.show(
          context,
          onTryAgain: () {
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

  void _updatePhoneNumberWithCountryCode(int guestNumber, String newCountryCode) {
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

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          onTap: onTap,
        ),
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
        // Row(
        //   children: [
        //     // Country picker button - UI COMMENTED OUT
        // GestureDetector(
        //   onTap: () {
        //         showCountryPicker(
        //           context: context,
        //           showPhoneCode: true,
        //           countryListTheme: CountryListThemeData(
        //             flagSize: 25,
        //             backgroundColor: Colors.white,
        //             textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        //             bottomSheetHeight: 500,
        //             borderRadius: const BorderRadius.only(
        //               topLeft: Radius.circular(20.0),
        //               topRight: Radius.circular(20.0),
        //             ),
        //             inputDecoration: InputDecoration(
        //               labelText: 'Search',
        //               hintText: 'Start typing to search',
        //               prefixIcon: const Icon(Icons.search),
        //               border: OutlineInputBorder(
        //                 borderSide: BorderSide(
        //                   color: const Color(0xFF8C98A8).withOpacity(0.2),
        //                 ),
        //               ),
        //             ),
        //           ),
        //           onSelect: (Country country) {
        //             setState(() {
        //               _selectedCountry = country;
        //               // Update the phone number with new country code
        //               _updateMainGuestPhoneNumberWithCountryCode(country.phoneCode);
        //             });
        //           },
        //         );
        //   },
        //   child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        //     decoration: BoxDecoration(
        //           border: Border.all(color: Colors.grey.shade300),
        //           borderRadius: const BorderRadius.only(
        //             topLeft: Radius.circular(8),
        //             bottomLeft: Radius.circular(8),
        //           ),
        //     ),
        //     child: Row(
        //           mainAxisSize: MainAxisSize.min,
        //       children: [
        //             Text(
        //               '+${_selectedCountry.phoneCode}',
        //               style: const TextStyle(fontSize: 16),
        //             ),
        //             const SizedBox(width: 4),
        //             const Icon(Icons.arrow_drop_down, size: 20),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // Phone number field with combined format - FULL WIDTH (country picker commented out)
        SizedBox(
          width: double.infinity,
          child: TextFormField(
            controller: _guestPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+${_selectedCountry.phoneCode} Enter mobile number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              // Ensure the phone number starts with the country code
              if (value.isNotEmpty && !value.startsWith('+')) {
                // If user enters number without +, add the country code
                if (!value.startsWith(_selectedCountry.phoneCode)) {
                  final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                  _guestPhoneController.text = '+${_selectedCountry.phoneCode}$cleanValue';
                  _guestPhoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _guestPhoneController.text.length),
                  );
                }
              }
              _validateForm();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccompanyingUserPhoneField(int guestNumber, TextEditingController controller) {
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
        // Row(
        //   children: [
        //     // Country picker button - UI COMMENTED OUT
        //     GestureDetector(
        //       onTap: () {
        //         showCountryPicker(
        //           context: context,
        //           showPhoneCode: true,
        //           countryListTheme: CountryListThemeData(
        //             flagSize: 25,
        //             backgroundColor: Colors.white,
        //             textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        //             bottomSheetHeight: 500,
        //             borderRadius: const BorderRadius.only(
        //               topLeft: Radius.circular(20.0),
        //               topRight: Radius.circular(20.0),
        //             ),
        //             inputDecoration: InputDecoration(
        //               labelText: 'Search',
        //               hintText: 'Start typing to search',
        //               prefixIcon: const Icon(Icons.search),
        //               border: OutlineInputBorder(
        //                 borderSide: BorderSide(
        //                   color: const Color(0xFF8C98A8).withOpacity(0.2),
        //                 ),
        //               ),
        //             ),
        //           ),
        //           onSelect: (Country selectedCountry) {
        //             setState(() {
        //               _guestCountries[guestNumber] = selectedCountry;
        //               // Update the phone number with new country code
        //               _updatePhoneNumberWithCountryCode(guestNumber, selectedCountry.phoneCode);
        //             });
        //           },
        //         );
        //       },
        //       child: Container(
        //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        //         decoration: BoxDecoration(
        //           border: Border.all(color: Colors.grey.shade300),
        //           borderRadius: const BorderRadius.only(
        //             topLeft: Radius.circular(8),
        //             bottomLeft: Radius.circular(8),
        //           ),
        //         ),
        //         child: Row(
        //           mainAxisSize: MainAxisSize.min,
        //           children: [
        //             Text(
        //               '+$countryCode',
        //               style: const TextStyle(fontSize: 16),
        //             ),
        //             const SizedBox(width: 4),
        //             const Icon(Icons.arrow_drop_down, size: 20),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        // Phone number field with combined format - FULL WIDTH (country picker commented out)
        SizedBox(
          width: double.infinity,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+$countryCode Enter phone number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              // Ensure the phone number starts with the country code
              if (value.isNotEmpty && !value.startsWith('+')) {
                // If user enters number without +, add the country code
                if (!value.startsWith(countryCode)) {
                  final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                  controller.text = '+$countryCode$cleanValue';
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }
              _validateForm();
            },
          ),
        ),
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
                    'Person $guestNumber',
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
              placeholder: 'Enter age',
              keyboardType: TextInputType.number,
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
                    color: Colors.blue.shade700,
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
                            color: Colors.blue.shade700,
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
                            color: Colors.blue.shade700,
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
                  if (_guestImages.containsKey(guestNumber) || _guestUploading[guestNumber] == true) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _guestUploading[guestNumber] == true 
                            ? Colors.blue[50] 
                            : (_guestImages.containsKey(guestNumber) ? Colors.green[50] : Colors.orange[50]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _guestUploading[guestNumber] == true 
                              ? Colors.blue[200]! 
                              : (_guestImages.containsKey(guestNumber) ? Colors.green[200]! : Colors.orange[200]!),
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        ),
                                      )
                                    : _guestImages.containsKey(guestNumber)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              _guestImages[guestNumber]!,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (context, error, stackTrace) {
                                                print('❌ Error loading accompanying user photo for guest $guestNumber: $error');
                                                print('❌ Photo URL: ${_guestImages[guestNumber]}');
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
                                    ] else if (_guestImages.containsKey(guestNumber)) ...[
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
        backgroundColor: Colors.deepPurple,
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
                            color: _isGuestAppointment ? Colors.green.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isGuestAppointment ? Colors.green.shade200 : Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
                                  Icon(
                                    _isGuestAppointment ? Icons.person : Icons.person_outline,
                                    color: _isGuestAppointment ? Colors.green.shade700 : Colors.blue.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
            Text(
                                    'Appointment Type: ${_isGuestAppointment ? 'Guest' : 'Myself'}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isGuestAppointment ? Colors.green.shade700 : Colors.blue.shade700,
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
                          _buildReferenceField(
                            label: 'Email ID of the Guest',
                            controller: _guestEmailController,
                            placeholder: 'guest@email.com',
                            keyboardType: TextInputType.emailAddress,
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
                                color: Colors.blue.shade700,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 12),
            Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Error loading main guest photo: $error');
                                          print('❌ Photo URL: $_mainGuestPhotoUrl');
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
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  onTap: () => _pickMainGuestImage(ImageSource.gallery),
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
                                  onTap: () => _pickMainGuestImage(ImageSource.camera),
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
                                  onTap: _removeMainGuestImage,
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                    onTap: () => _pickMainGuestImage(ImageSource.gallery),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.upload_file,
                                            color: Colors.blue[700],
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
                                    onTap: () => _pickMainGuestImage(ImageSource.camera),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange[200]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
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

                        // Appointment Location
                        _buildLocationField(),
                        const SizedBox(height: 20),

                        // Secretary Contact
                        _buildSecretaryField(),
                        const SizedBox(height: 20),

                        // Number of People with + and - buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Number of People',
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
                                    int currentCount = int.tryParse(_numberOfUsersController.text) ?? 1;
                                    print('DEBUG MINUS: Button clicked. Current count: $currentCount, Guest controllers: ${_guestControllers.length}');
                                    if (currentCount > 1) {
                                      print('DEBUG MINUS: Removing guest. Current count: $currentCount, Guest controllers: ${_guestControllers.length}');
                                      setState(() {
                                        _numberOfUsersController.text = (currentCount - 1).toString();
                                      });
                                      _updateGuestControllers();
                                      _validateForm();
                                      print('DEBUG MINUS: After removal. New count: ${_numberOfUsersController.text}, Guest controllers: ${_guestControllers.length}');
                                    } else {
                                      print('DEBUG MINUS: Cannot reduce below 1 (main user)');
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
                                        _numberOfUsersController.text.isEmpty ? '1' : _numberOfUsersController.text,
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
                                    int currentCount = int.tryParse(_numberOfUsersController.text) ?? 1;
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
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.deepPurple),
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
                              'Number of people (including yourself)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Guest Information Cards (for accompanying users)
                        if (_guestControllers.isNotEmpty) ...[
                          const Text(
                            'Additional Person Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please provide details for additional persons',
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
                        ),
                        const SizedBox(height: 20),

                        // To Date
                        _buildDateField(
                          label: 'To Date',
                          controller: _toDateController,
                          onTap: () => _selectDate(context, _toDateController),
                        ),
                        const SizedBox(height: 32),

                        // Save Changes Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFormValid && !_isSaving ? _saveAppointment : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
        
        // Update the number of users (main user + accompanying users)
        _numberOfUsersController.text = (_guestControllers.length + 1).toString();
        
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

  // Send appointment update notification
  Future<void> _sendAppointmentUpdatedNotification(Map<String, dynamic>? appointmentData) async {
    try {
      // Get current user data
      final userData = await StorageService.getUserData();
      if (userData == null) {
        print('⚠️ User data not found, skipping appointment update notification');
        return;
      }

      final userId = userData['_id']?.toString() ?? userData['userId']?.toString() ?? userData['id']?.toString();
      final appointmentId = widget.appointmentData?['appointmentId']?.toString() ?? 
                           widget.appointmentData?['_id']?.toString() ?? 
                           appointmentData?['_id']?.toString() ?? 
                           appointmentData?['id']?.toString();
      
      if (userId == null || appointmentId == null) {
        print('⚠️ User ID or Appointment ID not found, skipping notification');
        print('🔍 User ID: $userId, Appointment ID: $appointmentId');
        return;
      }

      print('🔄 Sending appointment update notification for appointment: $appointmentId');

      // Prepare appointment data for notification
      final notificationAppointmentData = {
        'fullName': appointmentData?['appointmentFor']?['personalInfo']?['fullName'] ?? 
                   widget.appointmentData?['appointmentFor']?['personalInfo']?['fullName'] ?? 
                   'User',
        'date': appointmentData?['preferredDateRange']?['fromDate'] ?? 
               widget.appointmentData?['preferredDateRange']?['fromDate'] ?? 
               _fromDateController.text,
        'time': 'Updated', // Time is part of the date range
        'venue': appointmentData?['appointmentLocation'] ?? 
                widget.appointmentData?['appointmentLocation'] ?? 
                'Selected Location',
        'purpose': appointmentData?['appointmentPurpose'] ?? 
                  widget.appointmentData?['appointmentPurpose'] ?? 
                  _appointmentPurposeController.text,
        'numberOfUsers': appointmentData?['numberOfUsers'] ?? 
                        widget.appointmentData?['numberOfUsers'] ?? 
                        _numberOfUsersController.text,
        'appointmentType': widget.appointmentData?['appointmentType'] ?? 'myself',
      };

      // Prepare additional notification data
      final notificationData = {
        'source': 'mobile_app',
        'formType': 'user_appointment_update',
        'userRole': userData['role']?.toString() ?? 'user',
        'timestamp': DateTime.now().toIso8601String(),
        'appointmentType': widget.appointmentData?['appointmentType'] ?? 'myself',
        'updateType': 'updated',
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
        print('✅ Appointment update notification sent successfully');
        print('📱 Notification ID: ${result['data']?['notificationId']}');
      } else {
        print('⚠️ Failed to send appointment update notification: ${result['message']}');
        print('🔍 Error details: ${result['error']}');
      }

    } catch (e) {
      print('❌ Error sending appointment update notification: $e');
      // Don't block the appointment update flow if notification fails
    }
  }
}
