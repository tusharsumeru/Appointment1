import 'package:flutter/material.dart';
import 'user_images_screen.dart';
import 'edit_appointment_screen.dart';
import 'appointment_schedule_form.dart';
import 'email_form.dart';
import 'message_form.dart';
import 'call_form.dart';
import 'assign_form.dart';
import 'star_form.dart';
import 'reminder_form.dart';
import '../../action/action.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final bool isFromDeletedAppointments;
  final bool isFromScheduleScreens; // New parameter to control sections

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
    this.isFromDeletedAppointments = false,
    this.isFromScheduleScreens = false, // Default to false
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isEditing = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Face match data storage
  Map<int, List<Map<String, dynamic>>> _faceMatchData = {};
  Map<int, bool> _isLoadingFaceMatch = {};
  Map<int, String?> _faceMatchErrors = {};
  
  // Filter state
  String _selectedFilter = '30_days'; // Default to 30 days
  bool _isRefreshing = false;
  
  // Appointments overview state
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _appointmentHistory = [];
  bool _isLoadingOverview = false;

  @override
  void initState() {
    super.initState();
    // Load existing notes and remarks from appointment data
    // Initialize notes and remarks - check quick appointment data first
    if (_isQuickAppointment()) {
      // For quick appointments, show purpose in notes and remarks for gurudev in remarks
      _notesController.text = _getQuickAppointmentPurpose();
      _remarksController.text = _getQuickAppointmentRemarks();
    } else {
      // For regular appointments, use the standard fields
      _notesController.text = widget.appointment['secretaryNotes']?.toString() ?? "";
      _remarksController.text = widget.appointment['gurudevRemarks']?.toString() ?? "";
    }
    
    // Debug quick appointment data
    _debugQuickAppointmentData();
    
    // Fetch appointments overview data
    _fetchAppointmentsOverview();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _remarksController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildNetworkImage(String imageUrl, double iconSize) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.person, size: iconSize, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }



  String _getUserName(int index) {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      if (index == 0) {
        // For guest appointments, index 0 is the guest (main user)
        final guestInformation = widget.appointment['guestInformation'];
        if (guestInformation is Map<String, dynamic>) {
          return guestInformation['fullName']?.toString() ?? 'Guest';
        }
        return 'Guest';
      } else {
        // For guest appointments, index 1+ are the accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              return user['fullName']?.toString() ?? 'User ${index + 1}';
            }
          }
        }
        return 'User ${index + 1}';
      }
    } else if (appointmentType?.toLowerCase() == 'myself') {
      if (index == 0) {
        // For myself appointments, index 0 is the main user
        return _getCreatedByName(); // Main user (Ram Tharun)
      } else {
        // For myself appointments, index 1+ are the accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              return user['fullName']?.toString() ?? 'User ${index + 1}';
            }
          }
        }
        return 'User ${index + 1}';
      }
    } else {
      // Regular appointment logic
      if (index == 0) {
        // Main user - try to get from mainUser object first, then fallback
        final mainUser = widget.appointment['mainUser'];
        if (mainUser is Map<String, dynamic>) {
          return mainUser['fullName']?.toString() ?? _getCreatedByName();
        }
        return _getCreatedByName(); // Fallback to createdBy
      } else {
        // Accompanying user - try to get from guest object
        final guest = widget.appointment['guest'];
        if (guest is Map<String, dynamic>) {
          return guest['fullName']?.toString() ?? 'Guest User';
        }
        
        // Fallback to old accompanyUsers structure
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              return user['fullName']?.toString() ?? 'User ${index + 1}';
            }
          }
        }
        
        // Final fallback
        return 'User ${index + 1}';
      }
    }
  }

  String _getUserLabel(int index) {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      if (index == 0) {
        return '(Guest)';
      } else {
        // Get age from API data for accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              final age = user['age']?.toString();
              if (age != null && age.isNotEmpty) {
                return '($age years old)';
              }
            }
          }
        }
        
        // Fallback ages
        return '(Adult)';
      }
    } else if (appointmentType?.toLowerCase() == 'myself') {
      if (index == 0) {
        return '(Main User)';
      } else {
        // Get age from API data for accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              final age = user['age']?.toString();
              if (age != null && age.isNotEmpty) {
                return '($age years old)';
              }
            }
          }
        }
        
        // Fallback ages
        return '(Adult)';
      }
    } else {
      // Regular appointment logic
      if (index == 0) {
        return '(Main User)';
      } else {
        // Get age from API data
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && index - 1 < users.length) {
            final user = users[index - 1];
            if (user is Map<String, dynamic>) {
              final age = user['age']?.toString();
              if (age != null && age.isNotEmpty) {
                return '($age years old)';
              }
            }
          }
        }
        
        // Fallback ages
        return '(Adult)';
      }
    }
  }

  int _getUserMatches(int index) {
    // Check if we have face match data for this user
    final faceMatchResults = _faceMatchData[index] ?? [];
    
    if (faceMatchResults.isNotEmpty) {
      final result = faceMatchResults[0]; // Get first result
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Return total count of all matches (no +1 for profile image)
        return matches30.length + matches60.length + matches90.length;
      }
    }
    
    // If no face match data available, return 0 (no matches found)
    return 0;
  }

  String _extractAge(String label) {
    // Extract age from labels like "(13 years old)", "(27 years old)", etc.
    final ageMatch = RegExp(r'\((\d+)\s+years?\s+old\)').firstMatch(label);
    if (ageMatch != null) {
      return '${ageMatch.group(1)} years';
    }
    
    // Handle main user case
    if (label.contains('Main User')) {
      return 'Main User';
    }
    
    return label;
  }

  Future<void> _fetchFaceMatchData(int userIndex) async {
    setState(() {
      _isLoadingFaceMatch[userIndex] = true;
      _faceMatchErrors[userIndex] = null;
    });

    try {
      // Use Appointment ID (like "APT-729a9644") instead of MongoDB ID
      final appointmentId = widget.appointment['appointmentId']?.toString() ?? '';
      if (appointmentId.isEmpty) {
        throw Exception('Appointment ID not found');
      }
      
      final result = await ActionService.getFaceMatchResultByAppointmentId(appointmentId);
      
      if (result['success']) {
        final responseData = result['data'];
        List<Map<String, dynamic>> faceMatchResults = [];
        
        if (responseData != null && responseData is Map<String, dynamic>) {
          // New API structure: faceMatchResults is inside data object
          final faceMatchData = responseData['faceMatchResults'];
          
          if (faceMatchData != null && faceMatchData is List) {
            // Process the faceMatchResults array
            for (final resultItem in faceMatchData) {
              if (resultItem is Map<String, dynamic>) {
                final userType = resultItem['userType']?.toString();
                
                // Match by userType: "main" for index 0, "guest" for index 1
                if ((userIndex == 0 && userType == 'main') || 
                    (userIndex == 1 && userType == 'guest')) {
                  faceMatchResults = [resultItem];
                  break;
                }
              }
            }
            
            // If no match found by userType, try photo URL matching as fallback
            if (faceMatchResults.isEmpty) {
              final userPhotoUrl = _getUserImageUrl(userIndex);
              for (final resultItem in faceMatchData) {
                if (resultItem is Map<String, dynamic>) {
                  final resultPhotoUrl = resultItem['photoUrl']?.toString();
                  if (resultPhotoUrl == userPhotoUrl) {
                    faceMatchResults = [resultItem];
                    break;
                  }
                }
              }
            }
            
            // If still no match, try index-based matching as final fallback
            if (faceMatchResults.isEmpty && faceMatchData.isNotEmpty) {
              final apiIndex = userIndex < faceMatchData.length ? userIndex : 0;
              final userResult = faceMatchData[apiIndex];
              if (userResult is Map<String, dynamic>) {
                faceMatchResults = [userResult];
              }
            }
          }
        } else if (responseData != null && responseData is List) {
          // Fallback: if data is directly a list (old structure)
          for (final resultItem in responseData) {
            if (resultItem is Map<String, dynamic>) {
              final userType = resultItem['userType']?.toString();
              
              // Match by userType: "main" for index 0, "guest" for index 1
              if ((userIndex == 0 && userType == 'main') || 
                  (userIndex == 1 && userType == 'guest')) {
                faceMatchResults = [resultItem];
                break;
              }
            }
          }
        }
        
        setState(() {
          _faceMatchData[userIndex] = faceMatchResults;
          _isLoadingFaceMatch[userIndex] = false;
        });
        
        // Debug: Print the results
        // print('User $userIndex: Found ${faceMatchResults.length} face match results');
        // if (faceMatchResults.isNotEmpty) {
        //   print('User $userIndex: First result userType: ${faceMatchResults[0]['userType']}');
        // } else {
        //   print('User $userIndex: No face match results found - this is normal for users without face match data');
        // }
      } else {
        setState(() {
          _faceMatchErrors[userIndex] = result['message'] ?? 'Failed to fetch face match results';
          _isLoadingFaceMatch[userIndex] = false;
        });
      }
    } catch (e) {
      setState(() {
        _faceMatchErrors[userIndex] = 'Network error: $e';
        _isLoadingFaceMatch[userIndex] = false;
      });
    }
  }

  void _navigateToUserImages(String userName, int imageCount, int userIndex) async {
    // Get the user's image URL based on index
    String userImageUrl = _getUserImageUrl(userIndex);
    
    // Use existing face match data without fetching new data
    // Only fetch data when refresh button is clicked
    
    // Pass the actual match count (no +1 for profile image)
    int finalImageCount = imageCount;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserImagesScreen(
          userName: userName,
          imageCount: finalImageCount,
          userImageUrl: userImageUrl,
          faceMatchData: _faceMatchData[userIndex] ?? [],
          isLoading: _isLoadingFaceMatch[userIndex] ?? false,
          error: _faceMatchErrors[userIndex],
          userIndex: userIndex,
        ),
      ),
    );
  }

  String _getUserImageUrl(int userIndex) {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    if (appointmentType?.toLowerCase() == 'guest') {
      if (userIndex == 0) {
        // For guest appointments, index 0 is the guest (main user)
        final guestInformation = widget.appointment['guestInformation'];
        if (guestInformation is Map<String, dynamic>) {
          final imageUrl = guestInformation['profilePhotoUrl']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }
        // Fallback to default image for guest
        return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      } else {
        // For guest appointments, index 1+ are the accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && userIndex - 1 < users.length) {
            final user = users[userIndex - 1];
            if (user is Map<String, dynamic>) {
              final imageUrl = user['profilePhotoUrl']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return imageUrl;
              }
            }
          }
        }
        // Fallback to default image for accompanying users
        return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      }
    } else if (appointmentType?.toLowerCase() == 'myself') {
      if (userIndex == 0) {
        // For myself appointments, index 0 is the main user
        return widget.appointment['profilePhoto']?.toString() ?? 
               'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      } else {
        // For myself appointments, index 1+ are the accompanying users
        final accompanyUsers = widget.appointment['accompanyUsers'];
        if (accompanyUsers is Map<String, dynamic>) {
          final users = accompanyUsers['users'] as List<dynamic>?;
          if (users != null && userIndex - 1 < users.length) {
            final user = users[userIndex - 1];
            if (user is Map<String, dynamic>) {
              final imageUrl = user['profilePhotoUrl']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return imageUrl;
              }
            }
          }
        }
        // Fallback to default image for accompanying users
        return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      }
    } else {
      // Regular appointment logic
      if (userIndex == 0) {
        // Main user - try to get from mainUser object first, then fallback
        final mainUser = widget.appointment['mainUser'];
        if (mainUser is Map<String, dynamic>) {
          // Main user might not have profilePhotoUrl in this structure
          // Use the profilePhoto from the main appointment object
          return widget.appointment['profilePhoto']?.toString() ?? 
                 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
        }
        return widget.appointment['profilePhoto']?.toString() ?? 
               'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      }
      
      // Accompanying user - try to get from guest object
      final guest = widget.appointment['guest'];
      if (guest is Map<String, dynamic>) {
        final imageUrl = guest['profilePhotoUrl']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
      
      // Fallback to old accompanyUsers structure
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'] as List<dynamic>?;
        if (users != null && userIndex - 1 < users.length) {
          final user = users[userIndex - 1];
          if (user is Map<String, dynamic>) {
            final imageUrl = user['profilePhotoUrl']?.toString();
            if (imageUrl != null && imageUrl.isNotEmpty) {
              return imageUrl;
            }
          }
        }
      }
      
      // Fallback to default image
      return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
    }
  }

  String _getAppointmentName() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final fullName = guestInformation['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final required = quickApt['required'];
      if (required is Map<String, dynamic>) {
        final name = required['name']?.toString();
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }

    // Try to get name from userId object first
    final userId = widget.appointment['userId'];
    if (userId is Map<String, dynamic>) {
      final fullName = userId['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
    }

    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentRole() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final designation = guestInformation['designation']?.toString();
        if (designation != null && designation.isNotEmpty) {
          return designation;
        }
      }
    }

    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final required = quickApt['required'];
      if (required is Map<String, dynamic>) {
        final designation = required['designation']?.toString();
        if (designation != null && designation.isNotEmpty) {
          return designation;
        }
      }
    }

    return widget.appointment['userCurrentDesignation']?.toString() ?? '';
  }

  String _getAppointmentCompany() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final company = guestInformation['company']?.toString();
        if (company != null && company.isNotEmpty) {
          return company;
        }
      }
    }

    return widget.appointment['userCurrentCompany']?.toString() ?? '';
  }

  String _getAppointmentImageUrl() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final photoUrl = guestInformation['profilePhotoUrl']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
    }

    // Check if this is a quick appointment and has a photo
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final photoUrl = optional['photo']?.toString();
        if (photoUrl != null && photoUrl.isNotEmpty) {
          return photoUrl;
        }
      }
    }
    
    // Fallback to profile photo
    return widget.appointment['profilePhoto']?.toString() ?? 
           'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? '';
  }

  // Get quick appointment email
  String _getQuickAppointmentEmail() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final email = guestInformation['emailId']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }

    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final email = optional['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }
    
    return '';
  }

  // Get quick appointment phone number
  String _getQuickAppointmentPhone() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      if (guestInformation is Map<String, dynamic>) {
        final phoneNumber = guestInformation['phoneNumber']?.toString();
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          return phoneNumber;
        }
      }
    }

    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final mobileNumber = optional['mobileNumber'];
        if (mobileNumber is Map<String, dynamic>) {
          final countryCode = mobileNumber['countryCode']?.toString() ?? '';
          final number = mobileNumber['number']?.toString() ?? '';
          if (countryCode.isNotEmpty && number.isNotEmpty) {
            // Handle cases where number might not have proper formatting
            String formattedNumber = number;
            if (number.startsWith('91') && number.length > 10) {
              formattedNumber = number.substring(2); // Remove country code if duplicated
            }
            return '$countryCode $formattedNumber';
          }
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
            return '$countryCode $number';
          }
        }
      }
    }
    return '';
  }

  // Get quick appointment purpose
  String _getQuickAppointmentPurpose() {
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final details = quickApt['details'];
      if (details is Map<String, dynamic>) {
        final purpose = details['purpose']?.toString();
        if (purpose != null && purpose.isNotEmpty) {
          return purpose;
        }
      }
    }
    
    return '';
  }

  // Get quick appointment remarks
  String _getQuickAppointmentRemarks() {
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final details = quickApt['details'];
      if (details is Map<String, dynamic>) {
        final remarks = details['remarksForGurudev']?.toString();
        if (remarks != null && remarks.isNotEmpty) {
          return remarks;
        }
      }
    }
    
    return '';
  }

  // Check if this is a quick appointment
  bool _isQuickAppointment() {
    final apptType = widget.appointment['appt_type']?.toString();
    return apptType == 'quick';
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

  // Debug method to print quick appointment data
  void _debugQuickAppointmentData() {
    final apptType = widget.appointment['appt_type']?.toString();
    print('🔍 Debug: Appointment type: $apptType');
    
    if (apptType == 'quick') {
      final quickApt = widget.appointment['quick_apt'];
      print('🔍 Debug: Quick appointment data: $quickApt');
      
      if (quickApt is Map<String, dynamic>) {
        final optional = quickApt['optional'];
        final details = quickApt['details'];
        print('🔍 Debug: Optional data: $optional');
        print('🔍 Debug: Details data: $details');
        
        // Test our helper methods
        print('🔍 Debug: Email: "${_getQuickAppointmentEmail()}"');
        print('🔍 Debug: Phone: "${_getQuickAppointmentPhone()}"');
        print('🔍 Debug: Purpose: "${_getQuickAppointmentPurpose()}"');
        print('🔍 Debug: Remarks: "${_getQuickAppointmentRemarks()}"');
      }
    }
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        // Dropdown (reduced size)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  DropdownMenuItem(
                    value: '30_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 30 Days'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: '60_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 60 Days'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: '90_days',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_view_month, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('Last 90 Days'),
                      ],
                    ),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedFilter = newValue;
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Refresh button inline with dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: InkWell(
            onTap: _isRefreshing ? null : () => _refreshAccompanyingUsers(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 32, // Match dropdown height
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRefreshing) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.refresh, size: 14, color: Colors.grey[600]),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    _isRefreshing ? 'Refreshing...' : 'Refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshAccompanyingUsers() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh face match data for all users including main user
      final attendeeCount = _getAttendeeCount();
      // print('Refresh: Starting refresh for $attendeeCount users');
      
      for (int i = 0; i < attendeeCount; i++) {
        // print('Refresh: Fetching data for user $i');
        await _fetchFaceMatchData(i);
      }
      
      // Force UI update to show new match counts
      setState(() {
        // This will trigger rebuild with updated face match data
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face match data refreshed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _fetchAppointmentsOverview() async {
    setState(() {
      _isLoadingOverview = true;
    });

    try {
      // Get the createdBy object which contains the user information
      final createdBy = widget.appointment['createdBy'];
      
      if (createdBy == null) {
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        return;
      }
      
      // Use createdBy as the user identifier (since it contains the same info as userId)
      String userId;
      
      if (createdBy is Map<String, dynamic>) {
        // Try to get user ID from createdBy object
        userId = createdBy['_id']?.toString() ?? 
                createdBy['userId']?.toString() ?? 
                createdBy['id']?.toString() ?? 
                createdBy.toString(); // Fallback to string representation
      } else {
        // If createdBy is not a Map, use its string representation
        userId = createdBy.toString();
      }

      // Fetch upcoming appointments
      final upcomingResult = await ActionService.getUpcomingAppointmentsByUser(userId: userId);
      
      // Use local appointment data instead of API call for appointment history
      // Get statusHistory from appointmentStatus object
      final historyResult = {
        'success': true,
        'data': _getStatusHistoryFromAppointment(),
      };
      

      
      if (mounted) {
        setState(() {
          if (upcomingResult['success'] && upcomingResult['data'] != null) {
            final List<dynamic> upcomingData = upcomingResult['data'];
            if (upcomingData is List) {
              _upcomingAppointments = upcomingData.map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
            } else {
              _upcomingAppointments = [];
            }
          } else {
            _upcomingAppointments = [];
          }
          
          if (historyResult['success'] == true && historyResult['data'] != null) {
            final historyData = historyResult['data'] as List<Map<String, dynamic>>;
            _appointmentHistory = historyData;
          } else {
            _appointmentHistory = [];
          }
          
          _isLoadingOverview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch appointments overview: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getStatusHistoryFromAppointment() {
    // Get statusHistory from appointmentStatus object
    final appointmentStatus = widget.appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      final statusHistory = appointmentStatus['statusHistory'];
      if (statusHistory is List) {
        // Convert statusHistory to the format expected by the UI
        return statusHistory.map((statusItem) {
          if (statusItem is Map<String, dynamic>) {
            final changedBy = statusItem['changedBy'];
            String changedByName = 'Unknown';
            String changedByEmail = '';
            
            if (changedBy is Map<String, dynamic>) {
              changedByName = changedBy['fullName']?.toString() ?? 'Unknown';
              changedByEmail = changedBy['email']?.toString() ?? '';
            }
            
            return {
              'status': statusItem['status']?.toString() ?? 'Unknown',
              'changedAt': statusItem['changedAt']?.toString() ?? '',
              'changedBy': {
                'fullName': changedByName,
                'email': changedByEmail,
                'userId': changedBy?['userId']?.toString() ?? '',
                'updatedTimestamp': changedBy?['updatedTimestamp']?.toString() ?? '',
              },
              'appointmentId': widget.appointment['appointmentId']?.toString() ?? '',
              'createdBy': widget.appointment['createdBy'],
              'appointmentStatus': widget.appointment['appointmentStatus'],
              'createdAt': statusItem['createdAt']?.toString() ?? '',
              'updatedAt': statusItem['updatedAt']?.toString() ?? '',
            };
          }
          return <String, dynamic>{};
        }).toList();
      }
    }
    
    // Fallback to empty list if no status history found
    return [];
  }

  Future<void> _refreshAppointmentsOverview() async {
    await _fetchAppointmentsOverview();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointments overview refreshed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool _shouldShowUser(int userIndex) {
    if (userIndex == 0) return true; // Always show main user
    
    // For time-based filtering, we'll filter based on appointment creation date
    final appointmentCreatedAt = widget.appointment['createdAt']?.toString();
    if (appointmentCreatedAt != null) {
      try {
        final appointmentDate = DateTime.parse(appointmentCreatedAt);
        final now = DateTime.now();
        final daysDifference = now.difference(appointmentDate).inDays;
        
        switch (_selectedFilter) {
          case '30_days':
            return daysDifference <= 30;
          case '60_days':
            return daysDifference <= 60;
          case '90_days':
            return daysDifference <= 90;
          default:
            return daysDifference <= 30; // Default to 30 days
        }
      } catch (e) {
        // If date parsing fails, show all
        return true;
      }
    }
    
    return true;
  }

  int _getFilteredAttendeeCount() {
    int count = 0;
    final totalAttendees = _getAttendeeCount();
    
    for (int i = 0; i < totalAttendees; i++) {
      if (_shouldShowUser(i)) {
        count++;
      }
    }
    
    return count;
  }

  int _getActualUserIndex(int filteredIndex) {
    int actualIndex = 0;
    int currentFilteredIndex = 0;
    final totalAttendees = _getAttendeeCount();
    
    for (int i = 0; i < totalAttendees; i++) {
      if (_shouldShowUser(i)) {
        if (currentFilteredIndex == filteredIndex) {
          actualIndex = i;
          break;
        }
        currentFilteredIndex++;
      }
    }
    
    return actualIndex;
  }

  String _getCreatedByName() {
    return widget.appointment['createdBy']?['name']?.toString() ?? 
           widget.appointment['createdBy']?['fullName']?.toString() ?? 
           'Not specified';
  }

  String _getCreatedByDesignation() {
    return widget.appointment['createdBy']?['designation']?.toString() ?? 
           widget.appointment['createdBy']?['currentDesignation']?.toString() ?? 
           'Not specified';
  }

  String _getCreatedByCompany() {
    return widget.appointment['createdBy']?['company']?.toString() ?? 
           widget.appointment['createdBy']?['currentCompany']?.toString() ?? 
           'Not specified';
  }

  String _getLocation() {
    // First try to get venue label from scheduledDateTime
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString();
      if (venueLabel != null && venueLabel.isNotEmpty) {
        return venueLabel;
      }
    }
    
    // Try locationName field
    final locationName = widget.appointment['locationName']?.toString();
    if (locationName != null && locationName.isNotEmpty) {
      return locationName;
    }
    
    // First try to get location from appointmentLocation object
    final appointmentLocation = widget.appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final name = appointmentLocation['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Fallback to other location fields
    final location = widget.appointment['location'];
    if (location is Map<String, dynamic>) {
      final name = location['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Try other string fields
    final locationString = widget.appointment['venue']?.toString() ?? 
                          widget.appointment['address']?.toString() ?? 
                          widget.appointment['city']?.toString() ?? 
                          widget.appointment['state']?.toString() ?? 
                          widget.appointment['country']?.toString();
    
    if (locationString != null && locationString.isNotEmpty) {
      return locationString;
    }
    
    // If no location found, return "Not specified"
    return 'Not specified';
  }

  String _getDateRange() {
    final preferredDateRange = widget.appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate']?.toString() ?? '';
      final toDate = preferredDateRange['toDate']?.toString() ?? '';
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        final from = DateTime.tryParse(fromDate);
        final to = DateTime.tryParse(toDate);
        if (from != null && to != null) {
          return '${from.day}/${from.month}/${from.year} - ${to.day}/${to.month}/${to.year}';
        }
      }
    }
    return 'Not specified';
  }

  int _getAttendeeCount() {
    // Check if this is a guest appointment
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    // Check if this is a guest appointment (either by appointmentType or by having guest data)
    if (appointmentType?.toLowerCase() == 'guest' || 
        (guestInformation is Map<String, dynamic> && 
         guestInformation['fullName']?.toString().isNotEmpty == true)) {
      // For guest appointments: 1 (guest) + number of accompanying users
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final numberOfUsers = accompanyUsers['numberOfUsers'] ?? 0;
        return 1 + (numberOfUsers as int); // Guest + accompanying users
      }
      return 1; // Just the guest if no accompanying users
    } else if (appointmentType?.toLowerCase() == 'myself') {
      // For myself appointments: 1 (main user) + number of accompanying users
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final numberOfUsers = accompanyUsers['numberOfUsers'] ?? 0;
        return 1 + (numberOfUsers as int); // Main user + accompanying users
      }
      return 1; // Just the main user if no accompanying users
    } else {
      // Regular appointment logic
      // Check if guest exists in new structure
      final guest = widget.appointment['guest'];
      if (guest != null) {
        return 2; // Main user + guest
      }
      
      // Fallback to old accompanyUsers structure
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final count = accompanyUsers['numberOfUsers'] ?? 1;
        return count;
      }
      return 1;
    }
  }



  String _getTeacherCode() {
    // Check direct aolTeacher field first
    final aolTeacher = widget.appointment['aolTeacher'];
    if (aolTeacher is Map<String, dynamic>) {
      final teacherCode = aolTeacher['teacherCode']?.toString();
      if (teacherCode != null && teacherCode.isNotEmpty) {
        return teacherCode;
      }
    }
    
    // Check nested structure in createdBy.aol_teacher
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        final nestedAolTeacher = aolTeacherNested['aolTeacher'];
        if (nestedAolTeacher is Map<String, dynamic>) {
          final teacherCode = nestedAolTeacher['teacherCode']?.toString();
          if (teacherCode != null && teacherCode.isNotEmpty) {
            return teacherCode;
          }
        }
      }
    }
    
    return '';
  }

  String _getTeacherName() {
    // Check nested structure in createdBy.aol_teacher
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          final data = atolValidationData['data'];
          if (data is Map<String, dynamic>) {
            final teacherDetails = data['teacherdetails'];
            if (teacherDetails is Map<String, dynamic>) {
              return teacherDetails['name']?.toString() ?? '';
            }
          }
        }
      }
    }
    
    // Fallback to createdBy fullName
    return _getCreatedByName();
  }

  String _getTeacherType() {
    // Check nested structure in createdBy.aol_teacher
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        // Check teacher_type field
        final teacherType = aolTeacherNested['teacher_type']?.toString();
        if (teacherType != null && teacherType.isNotEmpty) {
          return teacherType;
        }
        
        // Check atolValidationData.data.teacherdetails.teacher_type
        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          final data = atolValidationData['data'];
          if (data is Map<String, dynamic>) {
            final teacherDetails = data['teacherdetails'];
            if (teacherDetails is Map<String, dynamic>) {
              final detailsTeacherType = teacherDetails['teacher_type']?.toString();
              if (detailsTeacherType != null && detailsTeacherType.isNotEmpty) {
                return detailsTeacherType;
              }
            }
          }
        }
      }
    }
    
    return 'TAOL Teacher';
  }

  String _getTeacherPrograms() {
    // Check nested structure in createdBy.aol_teacher
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          final data = atolValidationData['data'];
          if (data is Map<String, dynamic>) {
            final teacherDetails = data['teacherdetails'];
            if (teacherDetails is Map<String, dynamic>) {
              return teacherDetails['program_types_can_teach']?.toString() ?? 'Happiness Program';
            }
          }
        }
      }
    }
    
    return 'Happiness Program';
  }

  List<String> _getUserTags() {
    // Check createdBy.userTags
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final userTags = createdBy['userTags'];
      if (userTags is List) {
        return userTags.map((tag) => tag.toString()).toList();
      }
    }
    
    return [];
  }

  bool _isTeacher() {
    // Check multiple possible fields for teacher status
    final aolTeacher = widget.appointment['aolTeacher'];
    final createdBy = widget.appointment['createdBy'];
    final userCurrentDesignation = widget.appointment['userCurrentDesignation']?.toString().toLowerCase();
    final appointmentPurpose = widget.appointment['appointmentPurpose']?.toString().toLowerCase();
    
    // Check aolTeacher.isTeacher field (direct field)
    if (aolTeacher is Map<String, dynamic>) {
      final isTeacher = aolTeacher['isTeacher'] == true;
      if (isTeacher) {
        return true;
      }
    }
    
    // Check createdBy.aol_teacher structure (nested structure)
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      
      if (aolTeacherNested is Map<String, dynamic>) {
        // Check aolTeacher.isTeacher in nested structure
        final nestedAolTeacher = aolTeacherNested['aolTeacher'];
        if (nestedAolTeacher is Map<String, dynamic>) {
          final isTeacher = nestedAolTeacher['isTeacher'] == true;
          if (isTeacher) {
            return true;
          }
        }
        
        // Check atolValidationData.verified
        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          final verified = atolValidationData['verified'] == true;
          if (verified) {
            return true;
          }
        }
        
        // Check teacher_type
        final teacherType = aolTeacherNested['teacher_type']?.toString().toLowerCase();
        if (teacherType != null && (teacherType.contains('teacher') || teacherType.contains('aol'))) {
          return true;
        }
      }
    }
    
    // Check if designation contains teacher-related keywords
    if (userCurrentDesignation != null) {
      if (userCurrentDesignation.contains('teacher') || 
          userCurrentDesignation.contains('aol') ||
          userCurrentDesignation.contains('art of living')) {
        return true;
      }
    }
    
    // Check if appointment purpose indicates teacher status
    if (appointmentPurpose != null) {
      if (appointmentPurpose.contains('teacher') || 
          appointmentPurpose.contains('aol') ||
          appointmentPurpose.contains('art of living')) {
        return true;
      }
    }
    
    return false;
  }

  String _formatStatusHistoryDateTime(Map<String, dynamic> statusItem) {
    try {
      // Use updatedTimestamp from changedBy object
      final changedBy = statusItem['changedBy'];
      if (changedBy is Map<String, dynamic>) {
        final updatedTimestamp = changedBy['updatedTimestamp']?.toString();
        if (updatedTimestamp != null && updatedTimestamp.isNotEmpty) {
          final date = DateTime.parse(updatedTimestamp);
          return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
      }
      
      // Fallback to changedAt if updatedTimestamp is not available
      final changedAt = statusItem['changedAt']?.toString();
      if (changedAt != null && changedAt.isNotEmpty) {
        final date = DateTime.parse(changedAt);
        return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      
      return 'Date not specified';
    } catch (e) {
      return 'Date not specified';
    }
  }

  String _formatAppointmentDateTime(Map<String, dynamic> appointment) {
    try {
      // Try to get scheduled date and time
      final scheduledDateTime = appointment['scheduledDateTime'];
      
      if (scheduledDateTime is Map<String, dynamic>) {
        final scheduledDate = scheduledDateTime['date']?.toString();
        final scheduledTime = scheduledDateTime['time']?.toString();
        
        if (scheduledDate != null && scheduledTime != null) {
          final date = DateTime.parse(scheduledDate);
          return '${date.day}/${date.month}/${date.year} at $scheduledTime';
        }
      }
      
      // Fallback to startTime and endTime
      final startTime = appointment['startTime']?.toString();
      final endTime = appointment['endTime']?.toString();
      
      if (startTime != null && startTime.isNotEmpty) {
        try {
          final start = DateTime.parse(startTime);
          if (endTime != null && endTime.isNotEmpty) {
            try {
              final end = DateTime.parse(endTime);
              return '${start.day}/${start.month}/${start.year} ${start.hour}:${start.minute.toString().padLeft(2, '0')} - ${end.hour}:${end.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              return '${start.day}/${start.month}/${start.year} ${start.hour}:${start.minute.toString().padLeft(2, '0')}';
            }
          } else {
            return '${start.day}/${start.month}/${start.year} ${start.hour}:${start.minute.toString().padLeft(2, '0')}';
          }
        } catch (e) {
          // If startTime parsing fails, continue to next fallback
        }
      }
      
      // Fallback to createdAt
      final createdAt = appointment['createdAt']?.toString();
      
      if (createdAt != null && createdAt.isNotEmpty) {
        try {
          final created = DateTime.parse(createdAt);
          return '${created.day}/${created.month}/${created.year}';
        } catch (e) {
          // If createdAt parsing fails, return default
        }
      }
      
      return 'Date not specified';
    } catch (e) {
      return 'Date not specified';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main User Information Section
            _buildMainUserSection(),
            
            // Action Buttons Section
            _buildActionButtonsSection(),
            
            // Show additional sections for all screens
            const SizedBox(height: 16),
            
            // Notes & Remarks Section - Always show for all screens
            _buildNotesRemarksSection(),
            
            // Only show other sections if NOT from schedule screens
            if (!widget.isFromScheduleScreens) ...[
              // Accompanying Users Section - Only show if 10 or fewer users and not from deleted appointments
              if (_getAttendeeCount() <= 10 && !widget.isFromDeletedAppointments) ...[
                _buildAccompanyingUsersSection(),
              ],
              
              // Teacher Verification Section - Only show if user is verified
              if (_isTeacher()) ...[
                _buildTeacherVerificationSection(),
              ] else ...[
                // Basic Information Section for non-verified users
                _buildBasicInformationSection(),
              ],
              
              // Appointments Overview Section
              _buildAppointmentsOverviewSection(),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    // Debug: Print appointment data structure
    print('DEBUG: Building action buttons section');
    print('DEBUG: Appointment keys: ${widget.appointment.keys.toList()}');
    print('DEBUG: isFromScheduleScreens: ${widget.isFromScheduleScreens}');
    
    // Debug: Check location information
    final appointmentLocation = widget.appointment['appointmentLocation'];
    final location = widget.appointment['location'];
    final venue = widget.appointment['venue'];
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    
    print('DEBUG: appointmentLocation: $appointmentLocation');
    print('DEBUG: location: $location');
    print('DEBUG: venue: $venue');
    print('DEBUG: scheduledDateTime: $scheduledDateTime');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.touch_app, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Perform quick actions for this appointment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Action buttons - Conditional based on source
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.schedule,
                label: 'Schedule',
                color: Colors.black,
                onTap: () => _showActionBottomSheet(context, 'reminder'),
              ),
              _buildActionButton(
                icon: Icons.email,
                label: 'Email',
                color: Colors.black,
                onTap: () => _showActionBottomSheet(context, 'email'),
              ),
              _buildActionButton(
                icon: Icons.message,
                label: 'Message',
                color: Colors.black,
                onTap: () => _showActionBottomSheet(context, 'message'),
              ),
              _buildActionButton(
                icon: Icons.call,
                label: 'Call',
                color: Colors.black,
                onTap: _makePhoneCall,
              ),
              // Show Assign button for all screens (no QR button)
              _buildActionButton(
                icon: Icons.assignment_ind,
                label: 'Assign',
                color: Colors.black,
                onTap: () {
                  print('DEBUG: Assign button tapped');
                  _showActionBottomSheet(context, 'assign');
                },
              ),
              _buildActionButton(
                icon: _isStarred() ? Icons.star : Icons.star_border,
                label: 'Starred',
                color: Colors.black,
                iconColor: _isStarred() ? Colors.amber : Colors.black,
                textColor: Colors.black,
                onTap: _toggleStar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: iconColor ?? color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor ?? color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context, String action) {
    print('DEBUG: _showActionBottomSheet() called with action: $action');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionContent(action),
    );
  }

  Widget _buildActionContent(String action) {
    print('DEBUG: _buildActionContent() called with action: $action');
    switch (action) {
      case 'reminder':
        return _buildReminderContent();
      case 'email':
        return _buildEmailContent();
      case 'message':
        return _buildMessageContent();
      case 'assign':
        return _buildAssignContent();
      default:
        print('DEBUG: Unknown action: $action');
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Schedule Appointment'),
          Expanded(
            child: ReminderForm(
              appointment: widget.appointment,
              onRefresh: () {
                // Refresh the detail page data
                _fetchAppointmentsOverview();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Send Email'),
          Expanded(child: EmailForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Send SMS'),
          Expanded(child: MessageForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildAssignContent() {
    print('DEBUG: _buildAssignContent() called');
    print('DEBUG: Appointment data passed to AssignForm: ${widget.appointment.keys.toList()}');
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Assign Secretary'),
          Expanded(child: AssignForm(
            appointment: widget.appointment,
            onRefresh: () {
              print('DEBUG: AssignForm onRefresh called');
              // Refresh the detail page data if needed
              setState(() {});
            },
          )),
        ],
      ),
    );
  }

  Widget _buildActionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    // Get the phone number from appointment data
    final phoneNumber = _getAppointeeMobile();
    
    if (phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create the phone URL
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAppointeeMobile() {
    // Check if this is a quick appointment first (same logic as message form)
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final mobileNumber = optional['mobileNumber'];
        if (mobileNumber is Map<String, dynamic>) {
          final countryCode = mobileNumber['countryCode']?.toString() ?? '';
          final number = mobileNumber['number']?.toString() ?? '';
          if (number.isNotEmpty) {
            return '$countryCode$number';
          }
        }
      }
    }
    
    // Fallback to regular phone fields (same logic as message form)
    final phoneNumber = widget.appointment['phoneNumber'];
    if (phoneNumber is Map<String, dynamic>) {
      final countryCode = phoneNumber['countryCode']?.toString() ?? '';
      final number = phoneNumber['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        // Return full phone number with country code
        return '$countryCode$number';
      }
    }
    // If it's a string, return as is
    final phoneString = phoneNumber?.toString() ?? '';
    return phoneString;
  }

  String _formatPhoneNumber(dynamic phoneData) {
    if (phoneData is Map<String, dynamic>) {
      final countryCode = phoneData['countryCode']?.toString() ?? '';
      final number = phoneData['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode $number';
      }
    }
    return phoneData?.toString() ?? '';
  }

  bool _isStarred() {
    // Check if appointment is starred
    return widget.appointment['starred'] == true;
  }

  Future<void> _toggleStar() async {
    try {
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Appointment ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get current starred status
      final currentStarredStatus = _isStarred();
      final desiredStarredStatus = !currentStarredStatus;

      // Call the star toggle API
      final result = await ActionService.updateStarred(appointmentId, starred: desiredStarredStatus);
      
      if (result['success']) {
        // Update the local appointment data
        setState(() {
          widget.appointment['starred'] = desiredStarredStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(desiredStarredStatus ? 'Appointment starred!' : 'Appointment unstarred!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to toggle star status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildMainUserSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              // Profile Image (Square)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: _buildNetworkImage(_getAppointmentImageUrl(), 40),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getAppointmentName(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAppointmentRole(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAppointmentCompany(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Request Details
          _buildMainCardDetailRow('Request ID', _getAppointmentId(), Icons.tag),
          _buildMainCardDetailRow('Date Range', _getDateRange(), Icons.calendar_today),
          _buildMainCardDetailRow('Location', _getLocation(), Icons.location_on),
          _buildMainCardDetailRow('Number of People', '${_getAttendeeCount()} People', Icons.people),
          

          
          const SizedBox(height: 20),
          
          // Action Buttons Section
          Row(
            children: [
              // Edit Button - Half width
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Delete/Restore Button - Half width
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isFromDeletedAppointments ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    widget.isFromDeletedAppointments ? 'Restore' : 'Delete',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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



  Widget _buildAccompanyingUsersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accompanying Users',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Users accompanying this appointment. Click refresh to load face match data.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Filter Section with refresh button inside
          _buildFilterSection(),
          
          const SizedBox(height: 20),
          
          // User Cards
          Column(
            children: [
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _getFilteredAttendeeCount(), // Use filtered count
                  itemBuilder: (context, index) {
                    final actualIndex = _getActualUserIndex(index);
                    final userName = _getUserName(actualIndex);
                    final userLabel = _getUserLabel(actualIndex);
                    final userMatches = _getUserMatches(actualIndex);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildUserCard(
                        userName,
                        userLabel,
                        userMatches,
                        actualIndex == 0, // First user is main user
                        actualIndex, // Pass the user index
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Number Indicators (dynamic based on filtered attendee count)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_getFilteredAttendeeCount(), (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPage = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _currentPage == index 
                            ? Colors.blue 
                            : Colors.grey[300],
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentPage == index 
                              ? Colors.white 
                              : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(String name, String label, int matches, bool isMainUser, int userIndex) {
    // Only make cards clickable if there are matches (count > 0)
    bool isClickable = matches > 0;
    
    return GestureDetector(
      onTap: isClickable ? () => _navigateToUserImages(name, matches, userIndex) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!, // Keep normal border for all cards
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1), // Keep normal shadow for all cards
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: 1.0, // Keep full opacity for all cards
          child: Row(
            children: [
              // Profile Image (Square)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _buildNetworkImage(_getUserImageUrl(userIndex), 30),
                ),
              ),
              const SizedBox(width: 12),
              
              // User Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name and Label
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Total Matches with Image Icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isLoadingFaceMatch[userIndex] == true
                              ? 'Loading matches...'
                              : _faceMatchData[userIndex]?.isNotEmpty == true
                                ? matches > 0 
                                  ? 'Total Matches Found : $matches'
                                  : 'No matches found'
                                : 'No face match data available',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isLoadingFaceMatch[userIndex] == true
                                ? Colors.blue[600]
                                : _faceMatchData[userIndex]?.isNotEmpty == true
                                  ? matches > 0
                                    ? Colors.grey[600]
                                    : Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                        ),
                        if (matches > 0) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.photo_library,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        ] else if (_isLoadingFaceMatch[userIndex] == true) ...[
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Basic appointment information and preferences.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Basic Details - Show regular appointment details (quick appointment details are shown in dedicated section)
          if (!_isQuickAppointment()) ...[
            if (_getQuickAppointmentEmail().isNotEmpty) ...[
              _buildDetailRow('Email', _getQuickAppointmentEmail(), Icons.email),
            ],
            if (_getQuickAppointmentPhone().isNotEmpty) ...[
              _buildDetailRow('Phone Number', _getQuickAppointmentPhone(), Icons.phone),
            ],
            if (_getQuickAppointmentPurpose().isNotEmpty) ...[
              _buildDetailRow('Purpose', _getQuickAppointmentPurpose(), Icons.info),
            ] else ...[
              _buildDetailRow('Purpose', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
            ],
            if (_getQuickAppointmentRemarks().isNotEmpty) ...[
              _buildDetailRow('Remarks for Gurudev', _getQuickAppointmentRemarks(), Icons.note),
            ],
          ] else ...[
            // For quick appointments, show basic info without duplicating quick appointment data
            _buildDetailRow('Purpose', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
          ],
          _buildDetailRow('Are you an Art Of Living teacher', 'No', Icons.school),
          _buildDetailRow('Are you seeking Online or In-person appointment', 'In-person', Icons.person),
        ],
      ),
    );
  }

  Widget _buildTeacherVerificationSection() {
    final teacherCode = _getTeacherCode();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Verification',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Teacher verification status for this appointment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Teacher Profile Card
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
                Text(
                  _getTeacherName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Verified By TAOL',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (teacherCode.isNotEmpty) ...[
                  _buildTeacherDetail('Teacher Code', teacherCode),
                  _buildTeacherDetail('Teacher Type', _getTeacherType()),
                  _buildTeacherDetail('Programs eligible to teach', _getTeacherPrograms()),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Additional Details
          _buildDetailRow('Purpose', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
          _buildDetailRow('Are you an Art Of Living teacher', 'Yes, ${_getTeacherType()}', Icons.school),
          _buildDetailRow('Programs eligible to teach', _getTeacherPrograms(), Icons.book),
          _buildDetailRow('Are you seeking Online or In-person appointment', 'In-person', Icons.person),
          _buildUserTagsRow(),
        ],
      ),
    );
  }

  Widget _buildTeacherDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTagsRow() {
    final userTags = _getUserTags();
    if (userTags.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: userTags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNotesRemarksSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes & Remarks',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notes and remarks for this appointment.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Notes Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isQuickAppointment() ? 'Purpose' : 'Notes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                enabled: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isQuickAppointment() ? 'Purpose of the appointment...' : 'Enter notes here...',
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
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Remarks Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isQuickAppointment() ? 'Gurudev Remarks' : 'Remarks',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarksController,
                enabled: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isQuickAppointment() ? 'Remarks for Gurudev...' : 'Enter remarks here...',
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
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Save Changes Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await _saveNotesAndRemarks();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Fully rounded
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildAppointmentsOverviewSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments Overview',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appointment history and upcoming appointments.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: _isLoadingOverview ? null : () => _refreshAppointmentsOverview(),
                icon: _isLoadingOverview 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    )
                  : const Icon(Icons.refresh),
                tooltip: _isLoadingOverview ? 'Refreshing...' : 'Refresh appointments overview',
                style: IconButton.styleFrom(
                  backgroundColor: _isLoadingOverview ? Colors.grey[100] : Colors.blue[50],
                  foregroundColor: _isLoadingOverview ? Colors.grey[400] : Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Upcoming Appointments
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Appointments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingOverview) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                  ),
                ),
              ] else if (_upcomingAppointments.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No upcoming appointments found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Scrollable container for upcoming appointments
                Container(
                  height: 300, // Fixed height for scrollable area
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Header for upcoming appointments
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: Colors.blue[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Upcoming Appointments',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_upcomingAppointments.length} items',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable content
                      Expanded(
                        child: Scrollbar(
                          controller: ScrollController(),
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _upcomingAppointments.where((appointment) => appointment is Map<String, dynamic>).map((appointment) {
                                try {
                                  return _buildAppointmentItem(
                                    appointment['createdBy']?['fullName']?.toString() ?? 'Unknown User',
                                    _formatAppointmentDateTime(appointment),
                                    appointment['appointmentStatus']?['status']?.toString() ?? 'Pending',
                                    _getStatusColor(appointment['appointmentStatus']?['status']?.toString() ?? 'pending'),
                                  );
                                } catch (e) {
                                  return _buildAppointmentItem(
                                    'Unknown User',
                                    'Date not specified',
                                    'Unknown',
                                    Colors.grey,
                                  );
                                }
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Appointment History
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Appointment History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingOverview) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                    ),
                  ),
                ),
              ] else if (_appointmentHistory.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'No appointment history found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Scrollable container for appointment history
                Container(
                  height: 300, // Fixed height for scrollable area
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      // Header for appointment history
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Appointment History',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_appointmentHistory.length} items',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Scrollable content
                      Expanded(
                        child: Scrollbar(
                          controller: ScrollController(),
                          thumbVisibility: true,
                          trackVisibility: true,
                          thickness: 6,
                          radius: const Radius.circular(10),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _appointmentHistory.where((appointment) => appointment is Map<String, dynamic>).map((appointment) {
                                try {
                                  return _buildAppointmentItem(
                                    appointment['changedBy']?['fullName']?.toString() ?? 'Unknown User',
                                    _formatStatusHistoryDateTime(appointment),
                                    appointment['status']?.toString() ?? 'Unknown',
                                    _getStatusColor(appointment['status']?.toString() ?? 'unknown'),
                                  );
                                } catch (e) {
                                  return _buildAppointmentItem(
                                    'Unknown User',
                                    'Date not specified',
                                    'Unknown',
                                    Colors.grey,
                                  );
                                }
                              }).toList(),
                            ),
                          ),
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
    );
  }

  Widget _buildAppointmentItem(String name, String dateTime, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Name on left, Status on right
          Row(
            children: [
              // Name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Second row: Date and Time
          Text(
            dateTime,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit appointment handler
  void _handleEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAppointmentScreen(
          appointment: widget.appointment,
        ),
      ),
    ).then((result) async {
      // Handle the result when returning from edit screen
      if (result != null) {
        if (result is Map<String, dynamic>) {
          // Fetch fresh appointment data from API
          await _fetchUpdatedAppointmentData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (result == true) {
          // Fallback for boolean result - also fetch fresh data
          await _fetchUpdatedAppointmentData();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // Fetch updated appointment data from API
  Future<void> _fetchUpdatedAppointmentData() async {
    try {
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        print('DEBUG: No appointment ID found for fetching updated data');
        return;
      }

      print('DEBUG: Fetching updated appointment data for ID: $appointmentId');
      
      // Show loading indicator
      setState(() {
        // You can add a loading state here if needed
      });

      // Fetch the updated appointment data
      final result = await ActionService.getAppointmentByIdDetailed(appointmentId);
      
      if (result['success'] && result['data'] != null) {
        // Update the appointment data with fresh data from API
        setState(() {
          widget.appointment.clear();
          widget.appointment.addAll(result['data']);
        });
        
        print('DEBUG: Successfully fetched updated appointment data');
      } else {
        print('DEBUG: Failed to fetch updated appointment data: ${result['message']}');
        // Optionally show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Warning: Could not refresh appointment data: ${result['message']}'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error fetching updated appointment data: $e');
      // Optionally show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Could not refresh appointment data: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Delete appointment handler
  void _handleDelete() {
    if (widget.isFromDeletedAppointments) {
      // Show restore dialog for deleted appointments
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Restore Appointment'),
            content: const Text('Are you sure you want to restore this appointment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performRestore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );
    } else {
      // Show delete dialog for regular appointments
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Appointment'),
            content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performSoftDelete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  // Perform soft delete operation
  Future<void> _performSoftDelete() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Deleting appointment...'),
              ],
            ),
          );
        },
      );

      // Get appointment ID
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Appointment ID not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Call the soft delete API
      final result = await ActionService.softDeleteAppointment(
        appointmentId: appointmentId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Appointment deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to inbox screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed('/inbox');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete appointment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Perform restore operation
  Future<void> _performRestore() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Restoring appointment...'),
              ],
            ),
          );
        },
      );

      // Get appointment ID
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Appointment ID not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Call the restore API
      final result = await ActionService.restoreDeletedAppointment(
        appointmentId: appointmentId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Appointment restored successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to deleted appointments screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed('/deleted-appointments');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to restore appointment'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // QR Code related methods
  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _downloadQRCode(String qrUrl, String patientName) async {
    try {
      _showSnackBar('Downloading QR code...', isError: false);
      
      // For now, we'll just show a success message
      // In a real implementation, you would use a package like 'dio' or 'http' 
      // to download the file and save it to the device
      
      await Future.delayed(const Duration(seconds: 1));
      _showSnackBar('QR code download started for $patientName', isError: false);
      
    } catch (error) {
      _showSnackBar('Failed to download QR code: $error', isError: true);
    }
  }

  void _showQRCodeDialog(Map<String, dynamic> appointment) {
    final appointmentId = appointment['appointmentId']?.toString();
    if (appointmentId == null) {
      _showSnackBar('Error: Appointment ID not found', isError: true);
      return;
    }
    // Use the correct domain for QR codes from action.dart
    final qrUrl = '${ActionService.baseUrl}/public/qr-codes/qr-$appointmentId.png';
    final patientName = _getAppointmentName();
    
    // Debug: Print the URL to console
    print('🔍 QR Code URL: $qrUrl');
    print('🔍 Appointment ID: $appointmentId');
    print('🔍 MongoDB ID: ${appointment['_id']}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QR Code - $patientName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'QR code for appointment ID: $appointmentId',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey.shade600,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // QR Code Image Container
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 192, // w-48 = 12rem = 192px
                      height: 192, // h-48 = 12rem = 192px
                      child: Image.network(
                        qrUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Debug: Print the error details
                          print('❌ QR Code Error: $error');
                          print('❌ Stack Trace: $stackTrace');
                          
                          return GestureDetector(
                            onTap: () {
                              // Close current dialog and reopen to retry
                              Navigator.of(context).pop();
                              _showQRCodeDialog(appointment);
                            },
                            child: Container(
                              width: 192,
                              height: 192,
                              color: Colors.grey.shade50,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'QR Code not available',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to retry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 192,
                            height: 192,
                            color: Colors.grey.shade50,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadQRCode(qrUrl, patientName),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showQRCodeDialog(appointment);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
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
          ),
        );
      },
    );
  }

  Future<void> _saveNotesAndRemarks() async {
    try {
      // Get appointment ID
      final appointmentId = _getAppointmentId();
      if (appointmentId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Appointment ID not found'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get notes and remarks from controllers
      final notes = _notesController.text.trim();
      final remarks = _remarksController.text.trim();

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Saving notes and remarks...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Call the API to update notes and remarks
      final result = await ActionService.updateStarred(
        appointmentId,
        gurudevRemarks: remarks.isNotEmpty ? remarks : null,
        secretaryNotes: notes.isNotEmpty ? notes : null,
      );

      if (result['success']) {
        // Success - show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Notes and remarks saved successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Error - show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save notes and remarks'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Network or other error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}