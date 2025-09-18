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
import '../utils/phone_validation.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> personalInfo;

  const AppointmentDetailsScreen({super.key, required this.personalInfo});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  // Scroll controller for auto-scrolling
  final ScrollController _scrollController = ScrollController();
  
  // Focus nodes for form fields
  final FocusNode _appointmentPurposeFocus = FocusNode();
  final FocusNode _guestNameFocus = FocusNode();
  final FocusNode _guestEmailFocus = FocusNode();
  final FocusNode _guestPhoneFocus = FocusNode();
  final FocusNode _guestDesignationFocus = FocusNode();
  final FocusNode _guestCompanyFocus = FocusNode();
  final FocusNode _guestLocationFocus = FocusNode();
  final FocusNode _numberOfUsersFocus = FocusNode();
  
  // Focus nodes for date fields (to prevent focus issues)
  final FocusNode _fromDateFocus = FocusNode();
  final FocusNode _toDateFocus = FocusNode();
  final FocusNode _programFromDateFocus = FocusNode();
  final FocusNode _programToDateFocus = FocusNode();
  
  // Focus nodes for guest fields
  final Map<int, Map<String, FocusNode>> _guestFocusNodes = {};

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

  // Reference Information Controllers
  final TextEditingController _referenceNameController =
      TextEditingController();
  final TextEditingController _referenceEmailController =
      TextEditingController();
  final TextEditingController _referencePhoneController =
      TextEditingController();

  // Guest Information Controllers
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
  String? _selectedAppointmentLocation;
  String?
  _selectedLocationId; // Store the selected location ID (locationId for API calls)
  String? _selectedLocationMongoId; // Store the MongoDB _id for form submission
  File? _selectedImage;
  File? _selectedAttachment; // For file attachments
  bool _isAttendingProgram = false;
  
  // Appointment purpose validation
  String? _appointmentPurposeError;
  
  // Flag to prevent unnecessary scrolling during focus transitions
  bool _isTransitioningFocus = false;

  // Guest information state
  List<Map<String, TextEditingController>> _guestControllers = [];

  // Guest images state - Map to store S3 URLs for each guest
  Map<int, String> _guestImages = {};
  // Guest temporary files - Map to store File objects for duplicate checking
  Map<int, File> _guestTempFiles = {};
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

  // Phone validation errors
  String? _guestPhoneError;

  // Accompany user state
  bool _referenceAsAccompanyUser = false;
  Map<int, String?> _guestPhoneErrors = {};

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
    // Initialize numberOfUsers to 1 by default (including the main user)
    _numberOfUsersController.text = '1';
    
    // Set default secretary selection to "None"
    _selectedSecretary = null; // null represents "None" option
    
    _validateForm();
    _loadLocations();
    _loadReferenceInfo();
    
    // Add listeners to focus nodes for auto-scrolling
    _addFocusListeners();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    
    // Dispose focus nodes
    _appointmentPurposeFocus.dispose();
    _guestNameFocus.dispose();
    _guestEmailFocus.dispose();
    _guestPhoneFocus.dispose();
    _guestDesignationFocus.dispose();
    _guestCompanyFocus.dispose();
    _guestLocationFocus.dispose();
    _numberOfUsersFocus.dispose();
    _fromDateFocus.dispose();
    _toDateFocus.dispose();
    _programFromDateFocus.dispose();
    _programToDateFocus.dispose();
    
    // Dispose guest focus nodes
    for (var guestFocuses in _guestFocusNodes.values) {
      for (var focusNode in guestFocuses.values) {
        focusNode.dispose();
      }
    }
    
    _appointmentPurposeController.dispose();
    _numberOfUsersController.dispose();
    _preferredFromDateController.dispose();
    _preferredToDateController.dispose();
    _programFromDateController.dispose();
    _programToDateController.dispose();

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
      // COMMENTED OUT: Unique phone code controller disposal
      // guest['uniquePhoneCode']?.dispose();
    }
    super.dispose();
  }

  // Add focus listeners for auto-scrolling
  void _addFocusListeners() {
    _appointmentPurposeFocus.addListener(() {
      if (_appointmentPurposeFocus.hasFocus) {
        _scrollToField(_appointmentPurposeFocus);
      }
    });
    
    _guestNameFocus.addListener(() {
      if (_guestNameFocus.hasFocus) {
        _scrollToField(_guestNameFocus);
      }
    });
    
    _guestEmailFocus.addListener(() {
      if (_guestEmailFocus.hasFocus) {
        _scrollToField(_guestEmailFocus);
      }
    });
    
    _guestPhoneFocus.addListener(() {
      if (_guestPhoneFocus.hasFocus) {
        _scrollToField(_guestPhoneFocus);
      }
    });
    
    _guestDesignationFocus.addListener(() {
      if (_guestDesignationFocus.hasFocus) {
        _scrollToField(_guestDesignationFocus);
      }
    });
    
    _guestCompanyFocus.addListener(() {
      if (_guestCompanyFocus.hasFocus) {
        _scrollToField(_guestCompanyFocus);
      }
    });
    
    _guestLocationFocus.addListener(() {
      if (_guestLocationFocus.hasFocus) {
        _scrollToField(_guestLocationFocus);
      }
    });
    
    _numberOfUsersFocus.addListener(() {
      if (_numberOfUsersFocus.hasFocus) {
        _scrollToField(_numberOfUsersFocus);
      }
    });
  }

  // Auto-scroll to focused field
  void _scrollToField(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Don't scroll if we're transitioning focus or if field doesn't have focus
      if (_isTransitioningFocus || !focusNode.hasFocus || !_scrollController.hasClients) {
        return;
      }
      
      // Get the render object of the focused widget
      final RenderObject? renderObject = focusNode.context?.findRenderObject();
      if (renderObject != null) {
        final RenderBox renderBox = renderObject as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        
        // Calculate the scroll offset to bring the field into view
        final screenHeight = MediaQuery.of(context).size.height;
        final fieldHeight = renderBox.size.height;
        final currentScrollOffset = _scrollController.offset;
        
        // Calculate target scroll position
        double targetOffset = currentScrollOffset;
        
        // If field is below the visible area
        if (position.dy > screenHeight * 0.7) {
          targetOffset = currentScrollOffset + (position.dy - screenHeight * 0.6);
        }
        // If field is above the visible area
        else if (position.dy < screenHeight * 0.3) {
          targetOffset = currentScrollOffset - (screenHeight * 0.4 - position.dy);
        }
        
        // Only scroll if there's a significant change needed
        if ((targetOffset - currentScrollOffset).abs() > 50) {
          // Ensure scroll offset is within bounds
          targetOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);
          
          // Animate to the target position
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // Move focus to next field
  void _moveToNextField(FocusNode currentFocus, FocusNode? nextFocus) {
    if (nextFocus != null) {
      // Set flag to prevent scrolling during transition
      _isTransitioningFocus = true;
      
      // Unfocus current field first
      currentFocus.unfocus();
      
      // Use a small delay to ensure proper focus transition
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(nextFocus);
          // Reset flag after focus transition
          Future.delayed(const Duration(milliseconds: 100), () {
            _isTransitioningFocus = false;
          });
        }
      });
    } else {
      // If no next focus, just unfocus current field
      currentFocus.unfocus();
    }
  }

  // Get or create focus nodes for guest fields
  Map<String, FocusNode> _getGuestFocusNodes(int guestNumber) {
    if (!_guestFocusNodes.containsKey(guestNumber)) {
      _guestFocusNodes[guestNumber] = {
        'name': FocusNode(),
        'phone': FocusNode(),
        'age': FocusNode(),
        // COMMENTED OUT: Unique phone code focus node
        // 'uniquePhoneCode': FocusNode(),
      };
      
      // Add listeners for auto-scrolling
      _guestFocusNodes[guestNumber]!['name']!.addListener(() {
        if (_guestFocusNodes[guestNumber]!['name']!.hasFocus) {
          _scrollToField(_guestFocusNodes[guestNumber]!['name']!);
        }
      });
      
      _guestFocusNodes[guestNumber]!['phone']!.addListener(() {
        if (_guestFocusNodes[guestNumber]!['phone']!.hasFocus) {
          _scrollToField(_guestFocusNodes[guestNumber]!['phone']!);
        }
      });
      
      _guestFocusNodes[guestNumber]!['age']!.addListener(() {
        if (_guestFocusNodes[guestNumber]!['age']!.hasFocus) {
          _scrollToField(_guestFocusNodes[guestNumber]!['age']!);
        }
      });
    }
    return _guestFocusNodes[guestNumber]!;
  }

  void _updateGuestControllers() {
    int totalPeopleCount = int.tryParse(_numberOfUsersController.text) ?? 1;
    
    // Calculate max accompany users based on whether reference is coming as accompany
    int maxAccompanyUsers;
    if (_referenceAsAccompanyUser) {
      maxAccompanyUsers = 8; // Main guest + reference as accompany = 2, so 8 more allowed
    } else {
      maxAccompanyUsers = 9; // Main guest = 1, so 9 accompany users allowed
    }
    
    // Calculate actual accompany users that need detail cards
    int accompanyUsersCount;
    if (_referenceAsAccompanyUser) {
      // If reference is coming as accompany, subtract 2 (main guest + reference)
      accompanyUsersCount = totalPeopleCount - 2;
    } else {
      // If reference is not coming as accompany, subtract 1 (main guest only)
      accompanyUsersCount = totalPeopleCount - 1;
    }

    // If more than max accompany users (10+ total people), don't create dynamic cards
    if (accompanyUsersCount > maxAccompanyUsers) {
      // Clear all existing controllers and data
      for (var guest in _guestControllers) {
        guest['name']?.dispose();
        guest['phone']?.dispose();
        guest['age']?.dispose();
        // COMMENTED OUT: Unique phone code controller disposal
        // guest['uniquePhoneCode']?.dispose();
      }
      _guestControllers.clear();
      _guestImages.clear();
      _guestTempFiles.clear();
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
        // COMMENTED OUT: Unique phone code controller disposal
        // guest['uniquePhoneCode']?.dispose();

        // Also remove associated data
        int guestNumber = i + 1;
        _guestImages.remove(guestNumber);
        _guestTempFiles.remove(guestNumber);
        _guestUploading.remove(guestNumber);
        _guestCountries.remove(guestNumber);
      }
      _guestControllers.removeRange(
        accompanyUsersCount,
        _guestControllers.length,
      );
    }

    // If we need more accompany users, add them at the bottom (only if <= 10 accompany users total)
    while (_guestControllers.length < accompanyUsersCount) {
      int guestNumber = _guestControllers.length + 1;

      Map<String, TextEditingController> controllers = {
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'age': TextEditingController(),
        // COMMENTED OUT: Unique phone code controller
        // 'uniquePhoneCode': TextEditingController(),
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

  void _updatePeopleCountForAccompanyUser() {
    int currentCount = int.tryParse(_numberOfUsersController.text) ?? 1;
    
    if (_referenceAsAccompanyUser) {
      // If user is coming as accompany, increase the count by 1
      _numberOfUsersController.text = (currentCount + 1).toString();
    } else {
      // If user is not coming as accompany, decrease the count by 1 (but not below 1)
      if (currentCount > 1) {
        _numberOfUsersController.text = (currentCount - 1).toString();
      }
    }
    
    // Update guest controllers to reflect the new count
    _updateGuestControllers();
    _validateForm();
  }

  int _getDisplayPersonNumber(int guestNumber) {
    // Guest details start from person 3 when accompany checkbox is selected
    // or from person 2 when accompany checkbox is not selected
    if (_referenceAsAccompanyUser) {
      return guestNumber + 2; // guestNumber 1 becomes person 3, guestNumber 2 becomes person 4, etc.
    } else {
      return guestNumber + 1; // guestNumber 1 becomes person 2, guestNumber 2 becomes person 3, etc.
    }
  }

  // Helper method to parse date string to DateTime
  DateTime? _parseDateString(String dateString) {
    try {
      final parts = dateString.split('-');
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
  bool _validateDateRange(
    String fromDate,
    String toDate, {
    String errorType = 'appointment',
  }) {
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

  void _validateGuestPhone(String phoneNumber) {
    final expectedLength = PhoneValidation.getPhoneLengthForCountryObject(_selectedCountry);
    
    if (expectedLength == 0) {
      // No example available, no validation
      setState(() {
        _guestPhoneError = null;
      });
      return;
    }
    
    if (phoneNumber.isEmpty) {
      setState(() {
        _guestPhoneError = null; // Don't show error for empty field
      });
    } else if (phoneNumber.length < expectedLength) {
      setState(() {
        _guestPhoneError = 'Phone number is too short. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else if (phoneNumber.length > expectedLength) {
      setState(() {
        _guestPhoneError = 'Phone number is too long. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else {
      setState(() {
        _guestPhoneError = null; // Valid length
      });
    }
  }

  void _validateAdditionalGuestPhone(int guestNumber, String phoneNumber) {
    final country = _guestCountries[guestNumber] ?? _selectedCountry;
    final expectedLength = PhoneValidation.getPhoneLengthForCountryObject(country);
    
    if (expectedLength == 0) {
      // No example available, no validation
      setState(() {
        _guestPhoneErrors[guestNumber] = null;
      });
      return;
    }
    
    if (phoneNumber.isEmpty) {
      setState(() {
        _guestPhoneErrors[guestNumber] = null; // Don't show error for empty field
      });
    } else if (phoneNumber.length < expectedLength) {
      setState(() {
        _guestPhoneErrors[guestNumber] = 'Phone number is too short. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else if (phoneNumber.length > expectedLength) {
      setState(() {
        _guestPhoneErrors[guestNumber] = 'Phone number is too long. Expected $expectedLength digits, got ${phoneNumber.length}';
      });
    } else {
      setState(() {
        _guestPhoneErrors[guestNumber] = null; // Valid length
      });
    }
  }

  void _validateForm() {
    // Validate appointment purpose
    String purposeText = _appointmentPurposeController.text.trim();
    if (purposeText.isEmpty) {
      _appointmentPurposeError = 'Appointment purpose is required';
    } else if (purposeText.length < 3) {
      _appointmentPurposeError = 'Minimum 3 characters required';
    } else if (!RegExp(r'^[a-zA-Z]').hasMatch(purposeText)) {
      _appointmentPurposeError = 'Must start with a letter';
    } else {
      _appointmentPurposeError = null;
    }

    bool basicFormValid =
        _appointmentPurposeError == null &&
        _preferredFromDateController.text.isNotEmpty &&
        _preferredToDateController.text.isNotEmpty;

    // Validate preferred date ranges
    bool preferredDateRangeValid = _validateDateRange(
      _preferredFromDateController.text,
      _preferredToDateController.text,
      errorType: 'appointment',
    );

    // Validate program date ranges if attending a program
    bool programDateRangeValid = true;
    if (_isAttendingProgram) {
      programDateRangeValid = _validateDateRange(
        _programFromDateController.text,
        _programToDateController.text,
        errorType: 'program',
      );
    }

    // Validate main guest phone number if appointment type is guest
    bool mainGuestPhoneValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      if (_guestPhoneController.text.isEmpty) {
        mainGuestPhoneValid = false;
      }
    }

    // Validate main guest email if appointment type is guest
    bool mainGuestEmailValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      mainGuestEmailValid =
          _guestEmailError == null && _guestEmailController.text.isNotEmpty;
    }

    // Validate main guest photo if appointment type is guest
    bool mainGuestPhotoValid = true;
    if (widget.personalInfo['appointmentType'] == 'guest') {
      if (_mainGuestPhotoUrl == null) {
        mainGuestPhotoValid = false;
      }
    }

    // Validate guest information if any (only for <= max accompany users)
    bool guestFormValid = true;
    final totalPeopleCount =
        int.tryParse(_numberOfUsersController.text) ?? 1;
    
    // Calculate actual accompany users that need detail cards
    int accompanyUsersCount;
    if (_referenceAsAccompanyUser) {
      // If reference is coming as accompany, subtract 2 (main guest + reference)
      accompanyUsersCount = totalPeopleCount - 2;
    } else {
      // If reference is not coming as accompany, subtract 1 (main guest only)
      accompanyUsersCount = totalPeopleCount - 1;
    }

    // Calculate max accompany users based on whether reference is coming as accompany
    int maxAccompanyUsers;
    if (_referenceAsAccompanyUser) {
      maxAccompanyUsers = 8; // Main guest + reference as accompany = 2, so 8 more allowed
    } else {
      maxAccompanyUsers = 9; // Main guest = 1, so 9 accompany users allowed
    }

    if (accompanyUsersCount > maxAccompanyUsers) {
      // For more than max accompany users (10+ total people), no guest validation needed
      guestFormValid = true;
    } else {
      // Validate individual guest details for <= 10 accompany users
      for (int i = 0; i < _guestControllers.length; i++) {
        var guest = _guestControllers[i];
        int guestNumber = i + 1;
        final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
        // COMMENTED OUT: Unique phone code logic disabled
        // final hasUniquePhoneCode = guest['uniquePhoneCode']?.text.isNotEmpty == true;
        final hasUniquePhoneCode = false;

        // Check required fields
        if (guest['name']?.text.isEmpty == true || guest['age']?.text.isEmpty == true) {
          guestFormValid = false;
          break;
        }

        // New rules:
        // - For age < 12 or age > 59: hide unique code, phone optional
        // - For age 12..59: show unique code; if code present -> phone optional; else phone required
        if (age > 12 && age <= 59) {
          if ((guest['phone']?.text.isEmpty ?? true) && !hasUniquePhoneCode) {
            guestFormValid = false;
            break;
          }
        }

        // Validate age range (1-120)
        if (age < 1 || age > 120) {
          guestFormValid = false;
          break;
        }

        // Check if photo is required and provided for guests aged 12+
        if (age > 12 && !_guestImages.containsKey(guestNumber)) {
          guestFormValid = false;
          break;
        }
      }
    }

    setState(() {
      _isFormValid =
          basicFormValid &&
          preferredDateRangeValid &&
          programDateRangeValid &&
          mainGuestPhoneValid &&
          mainGuestEmailValid &&
          mainGuestPhotoValid &&
          guestFormValid;
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    // Unfocus any currently focused field before opening date picker
    FocusScope.of(context).unfocus();
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      controller.text =
          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      _validateForm();
    }
    
    // Ensure no field is focused after date picker closes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
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
        // First check for duplicate photos
        if (widget.personalInfo['appointmentType'] == 'guest') {
          // For guest appointments, check against accompany users' photos
          // Note: Main user's profile photo is automatically added by the backend
          final accompanyUserUrls = _guestImages.values.whereType<String>().toList();
          
          final duplicateCheckResult = await ActionService.validateDuplicatePhotos(
            photoFiles: [File(pickedFile.path)],
            referencePhotoUrls: accompanyUserUrls,
            submitType: 'accompanyuser',
          );
          
          // Check if duplicates were found
          final duplicatesFound = duplicateCheckResult['data']?['duplicates_found'] == true;
          
          if (!duplicatesFound) {
            // No duplicates found, proceed with upload and validation
            final uploadResult = await ActionService.uploadAndValidateProfilePhoto(
              File(pickedFile.path),
            );

            if (uploadResult['success']) {
              final s3Url = uploadResult['s3Url'];
              
              // Photo uploaded and validated successfully
              setState(() {
                _mainGuestPhotoUrl = s3Url;
                _isMainGuestPhotoUploading = false;
              });

              // Update form validation
              _validateForm();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Main guest photo duplicate check passed, uploaded, and validated successfully!',
                  ),
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
              final errorMessage =
                  uploadResult['error'] ?? uploadResult['message'] ?? 'Photo validation failed';
              _showPhotoValidationErrorDialog(
                'Main guest: $errorMessage',
                () {
                  // Clear any previous state and allow user to pick again
                  setState(() {
                    _selectedImage = null;
                    _mainGuestPhotoUrl = null;
                    _isMainGuestPhotoUploading = false;
                  });
                },
              );
            }
          } else {
            // Duplicates found - show error and clear photo
            setState(() {
              _isMainGuestPhotoUploading = false;
            });

            // Update form validation
            _validateForm();

            // Show duplicate photo error message
            final errorMessage = "Main guest: Duplicate photo detected — This image matches an accompany user's photo.";
            _showPhotoValidationErrorDialog(
              errorMessage,
              () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _selectedImage = null;
                  _mainGuestPhotoUrl = null;
                  _isMainGuestPhotoUploading = false;
                });
              },
            );
          }
        } else {
          // For regular appointments, check against main user's existing profile photo
          final duplicateCheckResult = await ActionService.validateDuplicatePhoto(
            File(pickedFile.path),
            submitType: 'subuser',
          );
          
          // Check if duplicates were found
          final duplicatesFound = duplicateCheckResult['data']?['duplicates_found'] == true;
          
          if (!duplicatesFound) {
            // No duplicates found, proceed with upload and validation
            final uploadResult = await ActionService.uploadAndValidateProfilePhoto(
              File(pickedFile.path),
            );

            if (uploadResult['success']) {
              final s3Url = uploadResult['s3Url'];
              
              // Photo uploaded and validated successfully
              setState(() {
                _mainGuestPhotoUrl = s3Url;
                _isMainGuestPhotoUploading = false;
              });

              // Update form validation
              _validateForm();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Main guest photo duplicate check passed, uploaded, and validated successfully!',
                  ),
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
              final errorMessage =
                  uploadResult['error'] ?? uploadResult['message'] ?? 'Photo validation failed';
              _showPhotoValidationErrorDialog(
                'Main guest: $errorMessage',
                () {
                  // Clear any previous state and allow user to pick again
                  setState(() {
                    _selectedImage = null;
                    _mainGuestPhotoUrl = null;
                    _isMainGuestPhotoUploading = false;
                  });
                },
              );
            }
          } else {
            // Duplicates found - show error and clear photo
            setState(() {
              _isMainGuestPhotoUploading = false;
            });

            // Update form validation
            _validateForm();

            // Show duplicate photo error message
            final errorMessage = "Main guest: Duplicate photo detected — This image matches your existing profile photo.";
            _showPhotoValidationErrorDialog(
              errorMessage,
              () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _selectedImage = null;
                  _mainGuestPhotoUrl = null;
                  _isMainGuestPhotoUploading = false;
                });
              },
            );
          }
        }
      } catch (e) {
        setState(() {
          _isMainGuestPhotoUploading = false;
        });

        // Update form validation
        _validateForm();

        // Show error message in dialog
        _showPhotoValidationErrorDialog(
          'Error processing photo: ${e.toString()}',
          () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _selectedImage = null;
              _mainGuestPhotoUrl = null;
              _isMainGuestPhotoUploading = false;
            });
          },
        );
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
        // First check for duplicate photos with submit_type=accompanyuser
        // Ensure this guest's photo does not match main user or any other accompany user's photo
        final currentFile = File(pickedFile.path);
        final otherGuestUrls = _guestImages.entries
            .where((e) => e.key != guestNumber)
            .map((e) => e.value)
            .whereType<String>()
            .toList();

        // Include main guest photo and other guest photos
        // Note: Main user's profile photo is automatically added by the backend
        final allUrlsToCheck = <String>[];
        if (_mainGuestPhotoUrl != null && _mainGuestPhotoUrl!.isNotEmpty) {
          allUrlsToCheck.add(_mainGuestPhotoUrl!);
        }
        allUrlsToCheck.addAll(otherGuestUrls);

        final duplicateCheckResult = await ActionService.validateDuplicatePhotos(
          photoFiles: [currentFile], // only the current photo being checked
          referencePhotoUrls: allUrlsToCheck, // use reference_photo_url_* format like web
          submitType: 'accompanyuser',
        );

        // Check if duplicates were found (similar to web version logic)
        final duplicatesFound = duplicateCheckResult['data']?['duplicates_found'] == true;
        
        if (!duplicatesFound) {
          // No duplicates found, proceed with upload and validation
          final uploadResult = await ActionService.uploadAndValidateProfilePhoto(
            File(pickedFile.path),
          );

          if (uploadResult['success']) {
            final s3Url = uploadResult['s3Url'];
            
            // Photo uploaded and validated successfully
            setState(() {
              _guestImages[guestNumber] = s3Url;
              _guestTempFiles[guestNumber] = currentFile; // store temp file for future duplicate checks
              _guestUploading[guestNumber] = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Guest ${_getDisplayPersonNumber(guestNumber)} photo duplicate check passed, uploaded, and validated successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _guestUploading[guestNumber] = false;
            });

            // Show backend error message in dialog
            final errorMessage =
                uploadResult['error'] ?? uploadResult['message'] ?? 'Photo validation failed';
            _showPhotoValidationErrorDialog(
              'Guest ${_getDisplayPersonNumber(guestNumber)}: $errorMessage',
              () {
                // Clear any previous state and allow user to pick again
                setState(() {
                  _guestImages.remove(guestNumber);
                  _guestTempFiles.remove(guestNumber);
                  _guestUploading[guestNumber] = false;
                });
              },
            );
          }
        } else {
          // Duplicates found - show error and clear photo
          setState(() {
            _guestUploading[guestNumber] = false;
          });

          // Show duplicate photo error message (similar to web version)
          final errorMessage = "Guest ${_getDisplayPersonNumber(guestNumber)}: Duplicate photo detected — This image matches an existing photo.";
          _showPhotoValidationErrorDialog(
            errorMessage,
            () {
              // Clear any previous state and allow user to pick again
              setState(() {
                _guestImages.remove(guestNumber);
                _guestTempFiles.remove(guestNumber);
                _guestUploading[guestNumber] = false;
              });
            },
          );
        }
      } catch (e) {
        setState(() {
          _guestUploading[guestNumber] = false;
        });

        // Show error message in dialog
        _showPhotoValidationErrorDialog(
          'Guest ${_getDisplayPersonNumber(guestNumber)}: Error processing photo: ${e.toString()}',
          () {
            // Clear any previous state and allow user to pick again
            setState(() {
              _guestImages.remove(guestNumber);
              _guestTempFiles.remove(guestNumber);
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
      _guestTempFiles.remove(guestNumber);
      _guestUploading.remove(guestNumber);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Guest ${_getDisplayPersonNumber(guestNumber)} photo removed'),
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
          
          // Debug: Print all locations to see the structure
          print('DEBUG: Available locations:');
          for (int i = 0; i < locations.length; i++) {
            final location = locations[i];
            print('Location $i: ${location['name']} (ID: ${location['locationId']}, MongoID: ${location['_id']})');
          }
          
          // Set Bangalore as default location - try multiple variations
          Map<String, dynamic> bangaloreLocation = {};
          
          // Try different ways to find Bangalore
          for (final location in locations) {
            final locationName = location['name']?.toString().toLowerCase() ?? '';
            if (locationName.contains('bangalore') || 
                locationName.contains('bangaluru') ||
                locationName.contains('bengaluru') ||
                locationName.contains('bengalore')) {
              bangaloreLocation = location;
              print('DEBUG: Found Bangalore location: ${location['name']}');
              break;
            }
          }
          
          // If still not found, try to find by locationId or _id if we know the specific ID
          if (bangaloreLocation.isEmpty) {
            // Try to find by the known Bangalore MongoDB ID
            bangaloreLocation = locations.firstWhere(
              (location) => location['_id'] == '6889dbd15b943e342f660060',
              orElse: () => {},
            );
            
            if (bangaloreLocation.isNotEmpty) {
              print('DEBUG: Found Bangalore location by MongoDB ID: ${bangaloreLocation['name']}');
            } else {
              print('DEBUG: Bangalore location not found by name or ID');
            }
          }
          
          if (bangaloreLocation.isNotEmpty) {
            _selectedAppointmentLocation = bangaloreLocation['name'];
            _selectedLocationId = bangaloreLocation['locationId'];
            _selectedLocationMongoId = bangaloreLocation['_id'];
            
            print('DEBUG: Set default location to: ${_selectedAppointmentLocation}');
            print('DEBUG: Location ID: ${_selectedLocationId}');
            print('DEBUG: Location Mongo ID: ${_selectedLocationMongoId}');
            
            // Load secretaries for Bangalore location
            if (_selectedLocationId != null) {
              _loadSecretariesForLocation(_selectedLocationId!);
            }
          } else {
            print('DEBUG: No Bangalore location found, no default will be set');
          }
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
          _secretaryErrorMessage =
              result['message'] ?? 'Failed to load secretaries';
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
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Prepare personalInfo and ensure a structured phoneNumber object is available
      Map<String, dynamic> cleanedPersonalInfo = Map<String, dynamic>.from(
        widget.personalInfo,
      );
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
        'userCurrentCompany':
            widget.personalInfo['company'] ??
            '', // Changed from 'Sumeru Digital'
        'userCurrentDesignation':
            widget.personalInfo['designation'] ??
            '', // Changed from 'Office Operations Specialist'
        'appointmentPurpose': _appointmentPurposeController.text.trim(),
        'appointmentSubject': _appointmentPurposeController.text.trim(),
        'appointmentLocation':
            _selectedLocationMongoId ?? '6889dbd15b943e342f660060',
        'assignedSecretary':
            _selectedSecretary, // Send null when no secretary is selected
        'numberOfUsers':
            int.tryParse(_numberOfUsersController.text) ?? 1, // Total number of people
        // Expose referenceAsAccompanyUser at top-level for backend convenience
        'referenceAsAccompanyUser': _referenceAsAccompanyUser,
      };

      // Use preferred date range for appointment scheduling
      appointmentData['preferredDateRange'] = {
        'fromDate': _parseDateToISO(_preferredFromDateController.text),
        'toDate': _parseDateToISO(_preferredToDateController.text),
      };

      // Add accompanyUsers if there are additional users (only for <= max accompany users)
      final totalPeopleCount =
          int.tryParse(_numberOfUsersController.text) ?? 1;
      
      // Calculate actual accompany users that need detail cards
      int accompanyUsersCount;
      if (_referenceAsAccompanyUser) {
        // If reference is coming as accompany, subtract 2 (main guest + reference)
        accompanyUsersCount = totalPeopleCount - 2;
      } else {
        // If reference is not coming as accompany, subtract 1 (main guest only)
        accompanyUsersCount = totalPeopleCount - 1;
      }
      
      // Calculate max accompany users based on whether reference is coming as accompany
      int maxAccompanyUsers;
      if (_referenceAsAccompanyUser) {
        maxAccompanyUsers = 8; // Main guest + reference as accompany = 2, so 8 more allowed
      } else {
        maxAccompanyUsers = 9; // Main guest = 1, so 9 accompany users allowed
      }
      
      if (_guestControllers.isNotEmpty && accompanyUsersCount <= maxAccompanyUsers) {
        List<Map<String, dynamic>> accompanyUsers = [];
        for (int i = 0; i < _guestControllers.length; i++) {
          var guest = _guestControllers[i];
          int guestNumber = i + 1;

          // Store phoneNumber as object with countryCode and local number only
          final countryCode =
              '+${_guestCountries[guestNumber]?.phoneCode ?? '91'}';
          final phoneNumber = guest['phone']?.text.trim() ?? '';
          final fullPhoneNumber = phoneNumber.isNotEmpty ? '$countryCode$phoneNumber' : null; // keep for display if needed
          // COMMENTED OUT: Unique phone code collection disabled
          // final uniquePhoneCode = guest['uniquePhoneCode']?.text.trim();
          // final hasUniquePhoneCode = uniquePhoneCode != null && uniquePhoneCode.isNotEmpty;
          final hasUniquePhoneCode = false;

          Map<String, dynamic> guestData = {
            'fullName': guest['name']?.text.trim() ?? '',
            'age': int.tryParse(guest['age']?.text ?? '0') ?? 0,
          };

          // If unique phone code is provided, use it instead of regular phone number
          // COMMENTED OUT: alternativePhone is disabled
          // if (hasUniquePhoneCode) {
          //   // When unique phone code is provided, don't send country code
          //   guestData['alternativePhone'] = uniquePhoneCode;
          // } else 
          if (fullPhoneNumber != null) {
            // Only add phoneNumber if we have a phone number and no unique phone code
            guestData['phoneNumber'] = {
              'countryCode': countryCode,
              'number': phoneNumber, // save only local number
            };
          }

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
      } else if (accompanyUsersCount > 9) {
        // For more than 9 accompany users (10+ total people), just send the total count without individual details
        appointmentData['accompanyUsers'] = {
          'numberOfUsers':
              accompanyUsersCount, // Use the accompany users count
          'users': [], // Empty array since individual details not required
        };
      } else {
        // Ensure accompanyUsers is always an object for backend safety when none provided
        appointmentData['accompanyUsers'] = {
          'numberOfUsers': 0,
          'users': [],
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
          'phoneNumber':
              fullPhoneNumber, // Send as string for backend compatibility
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
          'phoneNumber': _referencePhoneController.text
              .trim(), // Send as string
          'referenceAsAccompanyUser': _referenceAsAccompanyUser,
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
          'fromDate': _parseDateToISO(_programFromDateController.text),
          'toDate': _parseDateToISO(_programToDateController.text),
        };
      }

      // Use ActionService.createAppointment method with attachment
      print('🎯 Calling ActionService.createAppointment...');
      final result = await ActionService.createAppointment(
        appointmentData,
        attachmentFile: _selectedAttachment,
      );
      print('🎯 ActionService.createAppointment result: $result');

      // Hide loading indicator
      Navigator.pop(context);

      if (result['success'] == true) {
        // Send appointment creation notification
        await _sendAppointmentCreatedNotification(result['data']);

        // Show beautiful success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon with green background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Success Text
                    const Text(
                      'Appointment request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'submitted successfully.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          // Navigate back to the main screen
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Continue',
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
            );
          },
        );
      } else {
        // Show full error (message + error) and allow wrapping
        final msg = result['message']?.toString() ?? '';
        final err = result['error']?.toString() ?? '';
        final full = [msg, err].where((s) => s.isNotEmpty).join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(full.isNotEmpty ? full : 'Failed to create appointment', maxLines: null),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      Navigator.pop(context);

      // Show error message (ensure full visibility)
      final text = 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text, maxLines: null),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // Method to unfocus all fields when tapping outside
  void _unfocusAllFields() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocusAllFields,
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color to white
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
        controller: _scrollController,
        physics: const ClampingScrollPhysics(), // Prevent overscroll but allow normal scrolling
        child: Center(
                      child: Card(
              elevation: 4,
              color: Colors.white, // Set card background to white
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                              placeholder: 'Your name will appear here',
                              isReadOnly: true,
                              focusNode: null, // No focus for read-only field
                            ),
                            const SizedBox(height: 12),

                            // Reference Email
                            _buildReferenceField(
                              label: 'Reference Email',
                              controller: _referenceEmailController,
                              placeholder: 'Your email will appear here',
                              keyboardType: TextInputType.emailAddress,
                              isReadOnly: true,
                              focusNode: null, // No focus for read-only field
                            ),
                            const SizedBox(height: 12),

                            // Reference Phone
                            _buildReferencePhoneField(
                              label: 'Reference Phone',
                              controller: _referencePhoneController,
                              isReadOnly: true,
                              focusNode: null, // No focus for read-only field
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
                      label: 'Full Name of the Guest',
                      isRequired: true,
                      controller: _guestNameController,
                      placeholder: 'Enter guest\'s full name',
                      focusNode: _guestNameFocus,
                      onSubmitted: () {
                        // Move to next field when submitted
                        _moveToNextField(_guestNameFocus, _guestEmailFocus);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Guest Email
                    _buildEmailField(
                      label: 'Email ID of the Guest',
                      isRequired: true,
                      controller: _guestEmailController,
                      placeholder: 'guest@email.com',
                      focusNode: _guestEmailFocus,
                      onSubmitted: () {
                        // Move to next field when submitted
                        _moveToNextField(_guestEmailFocus, _guestPhoneFocus);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Guest Mobile
                    _buildGuestPhoneFieldWithCountryPicker(),
                    const SizedBox(height: 16),

                    // Guest Designation
                    _buildReferenceField(
                      label: 'Designation',
                      isRequired: true,
                      controller: _guestDesignationController,
                      placeholder: 'Guest\'s professional title',
                      focusNode: _guestDesignationFocus,
                      onSubmitted: () {
                        // Move to next field when submitted
                        _moveToNextField(_guestDesignationFocus, _guestCompanyFocus);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Guest Company/Organization
                    _buildReferenceField(
                      label: 'Company/Organization',
                      isRequired: true,
                      controller: _guestCompanyController,
                      placeholder: 'Guest\'s organization name',
                      focusNode: _guestCompanyFocus,
                      onSubmitted: () {
                        // Move to next field when submitted
                        _moveToNextField(_guestCompanyFocus, _guestLocationFocus);
                      },
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
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Guest Photo '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

                    // Important Photo Upload Notice
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
                        // Show selected image preview
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isMainGuestPhotoUploading
                                  ? Colors.blue[50]
                                  : (_mainGuestPhotoUrl != null
                                        ? Colors.green[50]
                                        : Colors.orange[50]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isMainGuestPhotoUploading
                                    ? Colors.blue[200]!
                                    : (_mainGuestPhotoUrl != null
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
                                        image: DecorationImage(
                                          image: FileImage(_selectedImage!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.blue),
                                              ),
                                            ),
                                          ] else if (_mainGuestPhotoUrl !=
                                              null) ...[
                                            const Text(
                                              'Photo uploaded and validated successfully',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Text(
                                            //   'S3 URL: ${_mainGuestPhotoUrl!.substring(0, 50)}...',
                                            //   style: TextStyle(
                                            //     fontSize: 12,
                                            //     color: Colors.grey[600],
                                            //   ),
                                            // ),
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
                                        onTap: () =>
                                            _pickImage(ImageSource.gallery),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                            _pickImage(ImageSource.camera),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                        onTap: _removeImage,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                    const SizedBox(height: 24),
                  ],

                  // Accompany user section for guest appointments
                  if (widget.personalInfo['appointmentType'] == 'guest') ...[
                    const SizedBox(height: 24),
                    Builder(builder: (context) {
                      final totalPeopleCount = int.tryParse(_numberOfUsersController.text) ?? 1;
                      final basePeople = _referenceAsAccompanyUser ? 2 : 1; // Guest (1) + you as accompany (1) when checked
                      final additionalAccompany = (totalPeopleCount - basePeople).clamp(0, 1000);
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC), // slate-50
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header and subtitle
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                // Text(
                                //   'Accompany User',
                                //   style: TextStyle(
                                //     fontSize: 18,
                                //     fontWeight: FontWeight.w600,
                                //     color: Color(0xFF0F172A), // slate-800
                                //   ),
                                // ),
                                // SizedBox(height: 4),
                                // Text(
                                //   'Are you also attending the appointment as an accompany user?',
                                //   style: TextStyle(
                                //     fontSize: 12,
                                //     color: Color(0xFF64748B), // slate-500
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Checkbox row
                            const Text(
                              'Will you accompany the guest?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155), // slate-700
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _referenceAsAccompanyUser = false;
                                        _updatePeopleCountForAccompanyUser();
                                      });
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: !_referenceAsAccompanyUser
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                        border: Border.all(
                                          color: !_referenceAsAccompanyUser
                                              ? Colors.orange.shade200
                                              : Colors.grey.shade300!,
                                          width: !_referenceAsAccompanyUser ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: !_referenceAsAccompanyUser
                                                  ? Colors.orange.shade500
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: !_referenceAsAccompanyUser
                                                    ? Colors.orange.shade500
                                                    : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'No',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: !_referenceAsAccompanyUser
                                                  ? Colors.orange.shade800
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _referenceAsAccompanyUser = true;
                                        _updatePeopleCountForAccompanyUser();
                                      });
                                    },
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _referenceAsAccompanyUser
                                            ? Colors.orange.shade50
                                            : Colors.white,
                                        border: Border.all(
                                          color: _referenceAsAccompanyUser
                                              ? Colors.orange.shade200
                                              : Colors.grey.shade300!,
                                          width: _referenceAsAccompanyUser ? 2 : 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _referenceAsAccompanyUser
                                                  ? Colors.orange.shade500
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: _referenceAsAccompanyUser
                                                    ? Colors.orange.shade500
                                                    : Colors.grey.shade400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Yes',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _referenceAsAccompanyUser
                                                  ? Colors.orange.shade800
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Info line
                            // Text(
                            //   'ℹ️ Guest (1) + You as accompany user (${_referenceAsAccompanyUser ? 1 : 0}) = $basePeople base people. Additional accompany users: $additionalAccompany.',
                            //   style: const TextStyle(
                            //     fontSize: 12,
                            //     color: Color(0xFF2563EB), // blue-600
                            //   ),
                            // ),
                          ],
                        ),
                      );
                    }),
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
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 32),

                  // Appointment Purpose
                  _buildTextArea(
                    label: 'Purpose of Meeting',
                    controller: _appointmentPurposeController,
                    placeholder:
                        'Please describe the purpose of your appointment in detail',
                    onChanged: (value) => _validateForm(),
                    errorMessage: _appointmentPurposeError,
                    focusNode: _appointmentPurposeFocus,
                    onSubmitted: () {
                      // Move to next field when submitted
                      _moveToNextField(_appointmentPurposeFocus, _guestNameFocus);
                    },
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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

                  // Total Number of People with + and - buttons
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
                              int currentCount =
                                  int.tryParse(_numberOfUsersController.text) ??
                                  1;
                              if (currentCount > 1) {
                                setState(() {
                                  _numberOfUsersController.text =
                                      (currentCount - 1).toString();
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
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
                                  int.tryParse(_numberOfUsersController.text) ??
                                  1;
                              // Allow increasing beyond 10 people
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
                       (widget.personalInfo['appointmentType'] == 'guest')
                            ? 'Number of people (including you, the guest and children if any) for the appointment?'
                            : 'Number of people (including you and children if any) for the appointment?',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Guest Information Cards
                  if (_guestControllers.isNotEmpty) ...[
                    // const Text(
                    //   'Accompany User Details',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    // const Text(
                    //   'Please provide details for accompany users',
                    //   style: TextStyle(fontSize: 14, color: Colors.black54),
                    // ),
                    const SizedBox(height: 16),
                    ..._guestControllers.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, TextEditingController> guest = entry.value;
                      return _buildGuestCard(index + 1, guest, index);
                    }).toList(),
                    const SizedBox(height: 20),
                  ] else if ((int.tryParse(_numberOfUsersController.text) ??
                          1) >
                      10) ...[
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
                              // Icon(
                              //   Icons.info_outline,
                              //   color: Colors.orange.shade700,
                              //   size: 20,
                              // ),
                              // const SizedBox(width: 8),
                              // const Text(
                              //   'Large Group Appointment',
                              //   style: TextStyle(
                              //     fontSize: 16,
                              //     fontWeight: FontWeight.w600,
                              //     color: Colors.black87,
                              //   ),
                              // ),
                            ],
                          ),
                          // const SizedBox(height: 8),
                          Text(
                            'For appointments with more than 10 people, individual details for additional accompanying people are not required.',
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: 'Select your preferred date range '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // From Date
                  _buildDateField(
                    label: 'From Date',
                    controller: _preferredFromDateController,
                    onTap: () =>
                        _selectDate(context, _preferredFromDateController),
                    errorMessage: _dateRangeError,
                    focusNode: _fromDateFocus,
                    isProgramDate: false,
                  ),
                  const SizedBox(height: 16),

                  // To Date
                  _buildDateField(
                    label: 'To Date',
                    controller: _preferredToDateController,
                    onTap: () =>
                        _selectDate(context, _preferredToDateController),
                    errorMessage: _dateRangeError,
                    focusNode: _toDateFocus,
                    isProgramDate: false,
                  ),
                  const SizedBox(height: 20),

                  // Add Gurudev's Schedule Link
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1),
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
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

                  // Date Range & Program Attendance Header
                  const Text('Are you attending any program at the Bangalore Ashram ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),

                  // Program Attendance Question
                  // Text(
                  //   'Are you attending any program at the Bangalore Ashram during these dates? *',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //     color: Colors.grey.shade700,
                  //   ),
                  // ),
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
                        _buildDateField(
                          label: 'Program Start',
                          controller: _programFromDateController,
                          onTap: () => _selectDate(
                            context,
                            _programFromDateController,
                          ),
                          errorMessage: null,
                          focusNode: _programFromDateFocus,
                          isProgramDate: true,
                        ),

                        const SizedBox(height: 16),

                        // Program End Date
                        _buildDateField(
                          label: 'Program End',
                          controller: _programToDateController,
                          onTap: () => _selectDate(
                            context,
                            _programToDateController,
                          ),
                          errorMessage: _programDateRangeError != null 
                            ? 'End date must be after or equal to start date'
                            : null,
                          focusNode: _programToDateFocus,
                          isProgramDate: true,
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
      )
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
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
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
    String? errorMessage,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
          maxLines: 4,
          inputFormatters: [
            // Prevent leading spaces
            FilteringTextInputFormatter.deny(RegExp(r'^\s')),
          ],
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[500]!),
            ),
          ),
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

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? errorMessage,
    FocusNode? focusNode,
    bool isProgramDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isProgramDate ? Icons.event_available : Icons.calendar_today,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(text: '$label '),
                  const TextSpan(
                    text: '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Unfocus any current field before opening date picker
            FocusScope.of(context).unfocus();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.grey[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: errorMessage != null ? Colors.red : Colors.grey[300]!,
                width: errorMessage != null ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (errorMessage != null ? Colors.red : Colors.grey).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.text.isEmpty ? 'Select $label' : controller.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: controller.text.isEmpty 
                          ? Colors.grey[500] 
                          : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red, 
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGuestCard(
    int guestNumber,
    Map<String, TextEditingController> guest,
    int index,
  ) {
    // Check if photo is required (age > 12)
    final age = int.tryParse(guest['age']?.text ?? '0') ?? 0;
    final isPhotoRequired = age > 12;
    final guestFocusNodes = _getGuestFocusNodes(guestNumber);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
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
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Details of person ${_getDisplayPersonNumber(guestNumber)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const Spacer(),
                // Delete button
                GestureDetector(
                  onTap: () => _showDeleteConfirmationDialog(guestNumber),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 20,
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
              placeholder: "Enter person full name",
              onChanged: (value) => _validateForm(),
              focusNode: guestFocusNodes['name'],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onSubmitted: () {
                // Move to next field (age) when submitted
                _moveToNextField(guestFocusNodes['name']!, guestFocusNodes['age']);
              },
            ),
            const SizedBox(height: 16),

            // Age
            _buildGuestTextField(
              label: 'Age',
              controller: guest['age']!,
              placeholder: 'Enter age',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3,
              onChanged: (value) {
                _validateForm();
                setState(() {}); // Rebuild to show/hide photo section
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Age must be between 1 and 120';
                }
                return null;
              },
              focusNode: guestFocusNodes['age'],
              onSubmitted: () {
                // Move to next field (phone) when submitted
                _moveToNextField(guestFocusNodes['age']!, guestFocusNodes['phone']);
              },
            ),
            const SizedBox(height: 16),

            // Contact Number
            _buildAdditionalGuestPhoneField(guestNumber, guest['phone']!),
            const SizedBox(height: 16),

            // Unique Phone Code (only show for ages 12..59)
            // COMMENTED OUT: Unique Phone Code UI disabled
            // if (age > 12 && age < 59) ...[
            //   const SizedBox(height: 16),
            //   _buildGuestTextField(
            //     label: 'Unique Phone Code (Optional)',
            //     controller: guest['uniquePhoneCode']!,
            //     placeholder: 'Enter 3-digit unique phone code',
            //     keyboardType: TextInputType.number,
            //     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            //     maxLength: 3,
            //     onChanged: (value) {
            //       _validateForm();
            //       setState(() {}); // Rebuild to update phone field label
            //     },
            //     focusNode: guestFocusNodes['uniquePhoneCode'],
            //     onSubmitted: () {
            //       // Move to next guest or next section when submitted
            //       if (index < _guestControllers.length - 1) {
            //         // Move to next guest's name field
            //         final nextGuestFocusNodes = _getGuestFocusNodes(index + 2);
            //         _moveToNextField(guestFocusNodes['uniquePhoneCode']!, nextGuestFocusNodes['name']);
            //       } else {
            //         // Move to next section (appointment purpose)
            //         _moveToNextField(guestFocusNodes['uniquePhoneCode']!, _appointmentPurposeFocus);
            //       }
            //     },
            //   ),
            //   const SizedBox(height: 4),
            //   Text(
            //     'If you don’t have the contact number, kindly reach out to the secretariat to proceed with the appointment.',
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Colors.grey[600],
            //     ),
            //   ),
            // ],

            // Photo Section (only show if age > 12)
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
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(text: 'Photo '),
                        TextSpan(
                          text: '*',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

              // Important Photo Upload Notice
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                                    // Text(
                                    //   'S3 URL: ${_guestImages[guestNumber]!.substring(0, 30)}...',
                                    //   style: TextStyle(
                                    //     fontSize: 10,
                                    //     color: Colors.grey[600],
                                    //   ),
                                    // ),
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
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: onChanged,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[300]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red[500]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterText: '', // Hide character counter
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
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$label '),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                  const Text(
                    '+91',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
    bool isRequired = false,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired) ...[
                const TextSpan(text: ' '),
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          enabled: !isReadOnly,
          onSubmitted: (_) => onSubmitted?.call(),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
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
    bool isRequired = false,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired) ...[
                const TextSpan(text: ' '),
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
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
              vertical: 16,
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

  Widget _buildReferencePhoneField({
    required String label,
    required TextEditingController controller,
    bool isReadOnly = false,
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
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
        // Note: Reference phone field uses default length since no country picker is available
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 15, // Increased to accommodate international numbers
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          enabled: !isReadOnly,
          onSubmitted: (_) => onSubmitted?.call(),
          decoration: InputDecoration(
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            counterText: '', // Hide the character counter
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
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: 'Appointment Location '),
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                Icon(Icons.arrow_drop_down, color: Colors.grey[600], size: 24),
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              items: [
                // Add "None" option
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None - I am not in touch with any secretary'),
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
                        if (secretary['email'] != null &&
                            secretary['email'].isNotEmpty)
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
                color:
                    _getSelectedSecretaryName() != null &&
                        _getSelectedSecretaryName() != 'None'
                    ? const Color(0xFFF97316)
                    : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: const Color(0xFFF97316), size: 20),
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
                            Icon(
                              Icons.error_outline,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _secretaryErrorMessage!,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 14,
                                ),
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
                          _getSelectedSecretaryName() ?? 'None',
                          style: TextStyle(
                            color:
                                _getSelectedSecretaryName() != null &&
                                    _getSelectedSecretaryName() != 'None'
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

  // Get selected secretary name
  String? _getSelectedSecretaryName() {
    if (_selectedSecretary == null)
      return 'None';
    final selectedSecretary = _secretaries.firstWhere(
      (secretary) => secretary['id'] == _selectedSecretary,
      orElse: () => {},
    );
    return selectedSecretary['name'] ?? '';
  }

  // Show secretary bottom sheet
  void _showSecretaryBottomSheet() {
    if (_selectedLocationId == null ||
        _isLoadingSecretaries ||
        _secretaryErrorMessage != null) {
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
                      backgroundColor: _selectedSecretary == null
                          ? const Color(0xFFF97316)
                          : Colors.grey[300],
                      child: Icon(
                        Icons.person_off,
                        color: _selectedSecretary == null
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
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
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFFF97316),
                          )
                        : null,
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
                      final secretaryName =
                          secretary['name'] ?? 'Unknown Secretary';
                      final isSelected = _selectedSecretary == secretary['id'];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? const Color(0xFFF97316)
                              : Colors.grey[300],
                          child: Text(
                            secretaryName.isNotEmpty
                                ? secretaryName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFFF97316),
                              )
                            : null,
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
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: 'Mobile No. of the Guest '),
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
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
                      // Clear the phone number field when country changes
                      _guestPhoneController.clear();
                      // Clear phone validation error
                      _guestPhoneError = null;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
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
            // Phone Number Field
            Expanded(
              child: TextField(
                controller: _guestPhoneController,
                focusNode: _guestPhoneFocus,
                keyboardType: TextInputType.number,
                maxLength: PhoneValidation.getPhoneLengthForCountryObject(_selectedCountry),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _validateGuestPhone(value);
                  _validateForm();
                },
                onSubmitted: (_) {
                  // Move to next field when submitted
                  _moveToNextField(_guestPhoneFocus, _guestDesignationFocus);
                },
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  counterText: '', // Hide the character counter
                ),
              ),
            ),
          ],
        ),
        // Phone validation error
        if (_guestPhoneError != null) ...[
          const SizedBox(height: 4),
          Text(
            _guestPhoneError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  // Build additional guest phone field with country picker
  Widget _buildAdditionalGuestPhoneField(
    int guestNumber,
    TextEditingController controller,
  ) {
    final country = _guestCountries[guestNumber] ?? _selectedCountry;
    final guestFocusNodes = _getGuestFocusNodes(guestNumber);
    
    // Find the guest data (unique phone code disabled)
    final guestIndex = guestNumber - 1;
    final guest = guestIndex < _guestControllers.length ? _guestControllers[guestIndex] : null;
    final age = guest != null ? int.tryParse(guest['age']?.text ?? '0') ?? 0 : 0;
    // COMMENTED OUT: unique phone code disabled
    // final hasUniquePhoneCode = guest != null ? guest['uniquePhoneCode']?.text.isNotEmpty == true : false;
    final hasUniquePhoneCode = false;
    
    // Determine if phone is required per new rules
    // - For age < 12 or age > 59: phone optional
    // - For age 12..59: phone required unless unique code present
    final isPhoneRequired = (age > 12 && age < 59) && !hasUniquePhoneCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: isPhoneRequired ? 'Contact Number ' : 'Contact Number (Optional)'),
              if (isPhoneRequired)
                const TextSpan(
                  text: '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
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
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
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
                  onSelect: (Country selectedCountry) {
                    setState(() {
                      _guestCountries[guestNumber] = selectedCountry;
                      // Clear the phone number field when country changes
                      controller.clear();
                      // Clear phone validation error for this guest
                      _guestPhoneErrors[guestNumber] = null;
                    });
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
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
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Phone Number Field
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: guestFocusNodes['phone'],
                keyboardType: TextInputType.number,
                maxLength: PhoneValidation.getPhoneLengthForCountryObject(country),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _validateAdditionalGuestPhone(guestNumber, value);
                  _validateForm();
                },
                onSubmitted: (_) {
                  // Move to next guest or next section when submitted
                  final guestIndex = guestNumber - 1;
                  if (guestIndex < _guestControllers.length - 1) {
                    // Move to next guest's name field
                    final nextGuestFocusNodes = _getGuestFocusNodes(guestNumber + 1);
                    _moveToNextField(guestFocusNodes['phone']!, nextGuestFocusNodes['name']);
                  } else {
                    // Move to next section (appointment purpose)
                    _moveToNextField(guestFocusNodes['phone']!, _appointmentPurposeFocus);
                  }
                },
                decoration: InputDecoration(
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  counterText: '', // Hide the character counter
                ),
              ),
            ),
          ],
        ),
        // Phone validation error for additional guests
        if (_guestPhoneErrors[guestNumber] != null) ...[
          const SizedBox(height: 4),
          Text(
            _guestPhoneErrors[guestNumber]!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
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

        // Create DateTime object in UTC directly to avoid timezone conversion issues
        final date = DateTime.utc(year, month, day);

        // Convert to ISO 8601 format
        return date.toIso8601String();
      }
    } catch (e) {
      // Error parsing date
    }

    // Return current date as fallback
    return DateTime.now().toUtc().toIso8601String();
  }

  // Helper to parse a string like "+919876543210" or "9876543210" into { countryCode, number }
  Map<String, String> _parsePhoneStringToObject(
    String value, {
    String defaultCode = '+91',
  }) {
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
          final rest = trimmed
              .substring(codeMatch.end)
              .replaceAll(RegExp(r'\D'), '');
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
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
        ),
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
            final city =
                address['city'] ?? address['town'] ?? address['village'] ?? '';
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
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: 'Location '),
              TextSpan(
                text: '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search input field
        TextField(
          controller: _guestLocationController,
          focusNode: _guestLocationFocus,
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
          onSubmitted: (_) {
            // Move to next field when submitted
            _moveToNextField(_guestLocationFocus, _numberOfUsersFocus);
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
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

  // Send appointment creation notification
  Future<void> _sendAppointmentCreatedNotification(
    Map<String, dynamic>? appointmentData,
  ) async {
    try {
      // Get current user data
      final userData = await StorageService.getUserData();
      if (userData == null) {
        print('⚠️ User data not found, skipping appointment notification');
        return;
      }

      final userId =
          userData['_id']?.toString() ??
          userData['userId']?.toString() ??
          userData['id']?.toString();
      final appointmentId =
          appointmentData?['_id']?.toString() ??
          appointmentData?['id']?.toString();

      if (userId == null || appointmentId == null) {
        print('⚠️ User ID or Appointment ID not found, skipping notification');
        print('🔍 User ID: $userId, Appointment ID: $appointmentId');
        return;
      }

      print(
        '🎉 Sending appointment creation notification for appointment: $appointmentId',
      );

      // Prepare appointment data for notification
      final notificationAppointmentData = {
        'fullName':
            appointmentData?['appointmentFor']?['personalInfo']?['fullName'] ??
            widget.personalInfo['fullName'] ??
            'User',
        'date':
            appointmentData?['preferredDateRange']?['fromDate'] ??
            _preferredFromDateController.text,
        'time': 'Scheduled', // Time is part of the date range
        'venue': appointmentData?['appointmentLocation'] ?? 'Selected Location',
        'purpose':
            appointmentData?['appointmentPurpose'] ??
            _appointmentPurposeController.text,
        'numberOfUsers':
            appointmentData?['numberOfUsers'] ?? _numberOfUsersController.text,
        'appointmentType': widget.personalInfo['appointmentType'] ?? 'myself',
      };

      // Prepare additional notification data
      final notificationData = {
        'source': 'mobile_app',
        'formType': 'user_appointment_request',
        'userRole': userData['role']?.toString() ?? 'user',
        'timestamp': DateTime.now().toIso8601String(),
        'appointmentType': widget.personalInfo['appointmentType'] ?? 'myself',
      };

      // Send the notification
      final result = await ActionService.sendAppointmentCreatedNotification(
        userId: userId,
        appointmentId: appointmentId,
        appointmentData: notificationAppointmentData,
        notificationData: notificationData,
      );

      if (result['success']) {
        print('✅ Appointment creation notification sent successfully');
        print('📱 Notification ID: ${result['data']?['notificationId']}');
      } else {
        print(
          '⚠️ Failed to send appointment creation notification: ${result['message']}',
        );
        print('🔍 Error details: ${result['error']}');
      }
    } catch (e) {
      print('❌ Error sending appointment creation notification: $e');
      // Don't block the appointment creation flow if notification fails
    }
  }

  void _launchGurudevSchedule() async {
    const url = 'https://gurudev.artofliving.org/tour-schedule/';

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
                const Text(
                  'Please visit the following URL to check Gurudev\'s schedule:',
                ),
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
        guest['uniquePhoneCode']?.dispose();

        // Remove the guest from the list
        _guestControllers.removeAt(index);

        // Remove associated data for the specific guest being deleted
        _guestCountries.remove(guestNumber);
        _guestImages.remove(guestNumber);
        _guestUploading.remove(guestNumber);
        _guestTempFiles.remove(guestNumber);

        // Update guest numbers for remaining guests
        // Create new maps with updated guest numbers
        Map<int, Country> newGuestCountries = {};
        Map<int, String> newGuestImages = {};
        Map<int, bool> newGuestUploading = {};
        Map<int, File> newGuestTempFiles = {};

        // Reassign guest numbers for remaining guests
        for (int i = 0; i < _guestControllers.length; i++) {
          int newGuestNumber = i + 1;
          int oldGuestNumber = i + 1;
          
          // If we're at or after the deleted index, the old guest number is one higher
          if (i >= index) {
            oldGuestNumber = i + 2;
          }
          
          // Copy data with new guest number
          if (_guestCountries.containsKey(oldGuestNumber)) {
            newGuestCountries[newGuestNumber] = _guestCountries[oldGuestNumber]!;
          }
          if (_guestImages.containsKey(oldGuestNumber)) {
            newGuestImages[newGuestNumber] = _guestImages[oldGuestNumber]!;
          }
          if (_guestUploading.containsKey(oldGuestNumber)) {
            newGuestUploading[newGuestNumber] = _guestUploading[oldGuestNumber]!;
          }
          if (_guestTempFiles.containsKey(oldGuestNumber)) {
            newGuestTempFiles[newGuestNumber] = _guestTempFiles[oldGuestNumber]!;
          }
        }

        // Update the maps with corrected guest numbers
        _guestCountries = newGuestCountries;
        _guestImages = newGuestImages;
        _guestUploading = newGuestUploading;
        _guestTempFiles = newGuestTempFiles;

        // Update the number of users (accompanying users + main person + reference if coming as accompany)
        int totalPeople = _guestControllers.length + 1; // accompanying users + main person
        if (_referenceAsAccompanyUser) {
          totalPeople += 1; // add reference person if coming as accompany
        }
        _numberOfUsersController.text = totalPeople.toString();

        // Update form validation
        _validateForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Person ${guestNumber} has been deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int guestNumber) {
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
                  Icons.delete_outline,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Person',
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
              Text(
                'Are you sure you want to delete the details of person ${_getDisplayPersonNumber(guestNumber)}?',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. All data for this person will be permanently removed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDeleteGuestCard(guestNumber);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
