import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user_images_screen.dart';
import 'meeting_history_screen.dart';
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
  final String? secretaryName; // Secretary name passed from schedule screens
  final bool? isTeacher; // Teacher status passed from schedule screens

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
    this.isFromDeletedAppointments = false,
    this.isFromScheduleScreens = false, // Default to false
    this.secretaryName, // Secretary name from schedule screens
    this.isTeacher, // Teacher status from schedule screens
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
  String _selectedFilter = '90_days'; // Default to 90 days
  bool _isRefreshing = false;
  
  // Meeting history expansion state
  Map<int, bool> _isMeetingHistoryExpanded = {};
  // Helper: extract epoch millis from image name and format date as YYYY-MON-DD
  String _formatEpochToApiDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    final mon = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mon-$day';
  }

  String? _extractDateFromImageName(String imageName) {
    try {
      // Find 13-digit number (epoch millis) in the filename
      final match = RegExp(r'(?<!\d)(\d{13})(?!\d)').firstMatch(imageName);
      if (match != null) {
        final millisStr = match.group(1);
        if (millisStr != null) {
          final millis = int.parse(millisStr);
          return _formatEpochToApiDate(millis);
        }
      }
    } catch (_) {}
    return null;
  }

  String _computeDaysAgoFromDateString(String dateStr) {
    try {
      // Expecting YYYY-MON-DD
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final monStr = parts[1].toUpperCase();
        final day = int.parse(parts[2]);
        const monthMap = {
          'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
          'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
        };
        final month = monthMap[monStr] ?? 1;
        final dt = DateTime(year, month, day);
        final now = DateTime.now();
        return now.difference(dt).inDays.toString();
      }
    } catch (_) {}
    return '0';
  }
  
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
    
    // Automatically fetch face match data when screen loads
    _refreshAccompanyingUsers(showSuccessMessage: false);
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
    // First, try to get name from face match data if available
    final faceMatchResults = _faceMatchData[index] ?? [];
    if (faceMatchResults.isNotEmpty) {
      final userData = faceMatchResults[0];
      final fullName = userData['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
    }
    
    // Fallback to appointment data if no face match data available
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
    // First, try to get age from face match data if available
    final faceMatchResults = _faceMatchData[index] ?? [];
    if (faceMatchResults.isNotEmpty) {
      final userData = faceMatchResults[0];
      final age = userData['age']?.toString();
      if (age != null && age.isNotEmpty) {
        return '($age years old)';
      }
    }
    
    // Fallback to appointment data if no face match data available
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
        return '(Adult)'; // Don't duplicate the main appointee label
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
        return '(Adult)'; // Don't duplicate the main appointee label
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
      
      // Check if apiResult exists and is not null
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Aggregate matches across all periods (30/60/90) so we don't miss any
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        return allMatches.length;
      } else {
        // apiResult is null - no face match data for this user
        return 0;
      }
    }
    
    // If no face match data available, return 0 (no matches found)
    return 0;
  }

  // Get album information for a user (only albums with valid dates)
  Map<String, int> _getUserAlbums(int index) {
    // Use meeting history to get only albums with valid dates
    final meetingHistory = _getMeetingHistory(index);
    Map<String, int> albumMap = {};
    
    for (final meeting in meetingHistory) {
      final albumId = meeting['albumId']?.toString() ?? '';
      if (albumId.isNotEmpty) {
        // Count images in this album (we already filtered out invalid dates in _getMeetingHistory)
        albumMap[albumId] = (albumMap[albumId] ?? 0) + 1;
      }
    }
    
    return albumMap;
  }

  // Get total album count for a user
  int _getUserAlbumCount(int index) {
    final albums = _getUserAlbums(index);
    return albums.values.fold(0, (sum, count) => sum + count);
  }

  // Get unique album count for a user
  int _getUserUniqueAlbumCount(int index) {
    final albums = _getUserAlbums(index);
    return albums.length;
  }

  // Get meeting history for a user (grouped by album)
  List<Map<String, dynamic>> _getMeetingHistory(int index) {
    final faceMatchResults = _faceMatchData[index] ?? [];
    
    if (faceMatchResults.isNotEmpty) {
      final result = faceMatchResults[0];
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        // Combine matches from all time periods and include items regardless of date value
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        final matches = [...matches30, ...matches60, ...matches90];

        // Group matches by album (do not exclude unknown dates)
        Map<String, List<Map<String, dynamic>>> albumGroups = {};
        
        for (final match in matches) {
          if (match is Map<String, dynamic>) {
            final albumId = match['album_id']?.toString() ?? '';
            String date = match['date']?.toString() ?? '';
            String daysAgo = match['days_ago']?.toString() ?? '';
            final imageUrl = match['image_name']?.toString() ?? '';

            // If date is unknown/empty, try to derive it from image name
            final isUnknown = date.isEmpty || date.toLowerCase() == 'unknown' || date == 'null';
            if (isUnknown && imageUrl.isNotEmpty) {
              final derived = _extractDateFromImageName(imageUrl);
              if (derived != null) {
                date = derived;
                daysAgo = _computeDaysAgoFromDateString(derived);
              }
            }
            
            // Only require a valid album ID; include unknown dates
            if (albumId.isNotEmpty) {
              if (!albumGroups.containsKey(albumId)) {
                albumGroups[albumId] = [];
              }
              albumGroups[albumId]!.add({
                'imageUrl': imageUrl,
                'date': date,
                'daysAgo': daysAgo,
                'albumId': albumId,
              });
            }
          }
        }
        
        // Convert to list of album meetings (one per album)
        List<Map<String, dynamic>> albumMeetings = [];
        albumGroups.forEach((albumId, matches) {
          if (matches.isNotEmpty) {
            // Sort matches by date to get the most recent, pushing 'unknown' to the end
            matches.sort((a, b) {
              final dateA = a['date']?.toString() ?? '';
              final dateB = b['date']?.toString() ?? '';
              final isUnknownA = dateA.isEmpty || dateA.toLowerCase() == 'unknown' || dateA == 'null';
              final isUnknownB = dateB.isEmpty || dateB.toLowerCase() == 'unknown' || dateB == 'null';
              if (isUnknownA && isUnknownB) return 0;
              if (isUnknownA) return 1; // A goes after B
              if (isUnknownB) return -1; // B goes after A
              return dateB.compareTo(dateA);
            });
            
            // Take the first (most recent) match from this album
            final firstMatch = matches.first;
            albumMeetings.add({
              'imageUrl': firstMatch['imageUrl'],
              'date': firstMatch['date'],
              'daysAgo': firstMatch['daysAgo'],
              'albumId': albumId,
              'totalImages': matches.length, // Number of images in this album
            });
          }
        });
        
        // Sort albums by date (most recent first), keeping unknowns at the end
        albumMeetings.sort((a, b) {
          final dateA = a['date']?.toString() ?? '';
          final dateB = b['date']?.toString() ?? '';
          final isUnknownA = dateA.isEmpty || dateA.toLowerCase() == 'unknown' || dateA == 'null';
          final isUnknownB = dateB.isEmpty || dateB.toLowerCase() == 'unknown' || dateB == 'null';
          if (isUnknownA && isUnknownB) return 0;
          if (isUnknownA) return 1;
          if (isUnknownB) return -1;
          return dateB.compareTo(dateA);
        });
        
        return albumMeetings;
      }
    }
    
    return [];
  }

  // Get last meeting date
  String _getLastMeetingDate(int index) {
    final meetings = _getMeetingHistory(index);
    if (meetings.isNotEmpty) {
      final date = meetings.first['date']?.toString() ?? '';
      if (date.isNotEmpty && date.toLowerCase() != 'unknown' && date != 'null') {
        // Convert "2025-JUN-09" to "Jun 9, 2025"
        try {
          final parts = date.split('-');
          if (parts.length == 3) {
            final year = parts[0];
            final month = parts[1];
            final day = parts[2];
            
            // Validate that all parts are valid
            if (year.isNotEmpty && month.isNotEmpty && day.isNotEmpty && 
                year != 'null' && month != 'null' && day != 'null') {
              
              final monthNames = {
                'JAN': 'Jan', 'FEB': 'Feb', 'MAR': 'Mar', 'APR': 'Apr',
                'MAY': 'May', 'JUN': 'Jun', 'JUL': 'Jul', 'AUG': 'Aug',
                'SEP': 'Sep', 'OCT': 'Oct', 'NOV': 'Nov', 'DEC': 'Dec'
              };
              
              final monthName = monthNames[month] ?? month;
              final dayNum = int.tryParse(day) ?? 0;
              
              if (dayNum > 0) {
                return '$monthName $dayNum, $year';
              }
            }
          }
        } catch (e) {
        }
      }
      // If date is unknown
      return 'Unknown';
    }
    return 'No meetings found';
  }

  // Get last meeting days ago
  String _getLastMeetingDaysAgo(int index) {
    final meetings = _getMeetingHistory(index);
    if (meetings.isNotEmpty) {
      return meetings.first['daysAgo']?.toString() ?? '0';
    }
    return '0';
  }

  // Get total meetings count
  int _getTotalMeetings(int index) {
    final meetings = _getMeetingHistory(index);
    return meetings.length;
  }

  // Build meeting history item widget
  Widget _buildMeetingHistoryItem(Map<String, dynamic> meeting, int userIndex) {
    final imageUrl = meeting['imageUrl']?.toString() ?? '';
    final date = meeting['date']?.toString() ?? '';
    final daysAgo = meeting['daysAgo']?.toString() ?? '';
    final albumId = meeting['albumId']?.toString() ?? '';
    final totalImages = meeting['totalImages']?.toString() ?? '0';
    
    // Convert date format
    String formattedDate = date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        
        final monthNames = {
          'JAN': 'Jan', 'FEB': 'Feb', 'MAR': 'Mar', 'APR': 'Apr',
          'MAY': 'May', 'JUN': 'Jun', 'JUL': 'Jul', 'AUG': 'Aug',
          'SEP': 'Sep', 'OCT': 'Oct', 'NOV': 'Nov', 'DEC': 'Dec'
        };
        
        final monthName = monthNames[month] ?? month;
        final dayNum = int.tryParse(day) ?? 0;
        
        formattedDate = '$monthName $dayNum, $year';
      }
    } catch (e) {
      // Keep original format if conversion fails
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // Album image (first image from the album)
          GestureDetector(
            onTap: () => _showImageInDialog(imageUrl),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildNetworkImage(imageUrl, 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Album details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$daysAgo days ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$totalImages images',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // View button
          ElevatedButton(
            onPressed: () => _navigateToAlbumImages(userIndex, albumId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigate to album images
  void _navigateToAlbumImages(int userIndex, String albumId) {
    final userName = _getUserName(userIndex);
    final userImageUrl = _getUserImageUrl(userIndex);
    final faceMatchResults = _faceMatchData[userIndex] ?? [];
    
    // Filter face match data to only include images from the specific album
    List<Map<String, dynamic>> filteredFaceMatchData = [];
    
    if (faceMatchResults.isNotEmpty) {
      final result = faceMatchResults[0];
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Get matches from all time periods and filter by album
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Filter matches by album ID
        List<Map<String, dynamic>> filteredMatches = [];
        
        for (final match in [...matches30, ...matches60, ...matches90]) {
          if (match is Map<String, dynamic> && 
              match['album_id']?.toString() == albumId) {
            filteredMatches.add(match);
          }
        }
        
        // Create filtered result
        if (filteredMatches.isNotEmpty) {
          filteredFaceMatchData = [{
            ...result,
            'apiResult': {
              ...apiResult,
              '30_days': {'matches': filteredMatches.where((m) => 
                apiResult['30_days']?['matches']?.contains(m) ?? false).toList()},
              '60_days': {'matches': filteredMatches.where((m) => 
                apiResult['60_days']?['matches']?.contains(m) ?? false).toList()},
              '90_days': {'matches': filteredMatches.where((m) => 
                apiResult['90_days']?['matches']?.contains(m) ?? false).toList()},
            }
          }];
        }
      }
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserImagesScreen(
          userName: '$userName (Album $albumId)',
          imageCount: filteredFaceMatchData.isNotEmpty ? 
            _getAlbumImageCount(userIndex, albumId) : 0,
          userImageUrl: userImageUrl,
          faceMatchData: filteredFaceMatchData,
          userIndex: userIndex,
          isAlbumView: true,
          albumId: albumId,
        ),
      ),
    );
  }
  
  // Get image count for specific album
  int _getAlbumImageCount(int userIndex, String albumId) {
    final faceMatchResults = _faceMatchData[userIndex] ?? [];
    
    if (faceMatchResults.isNotEmpty) {
      final result = faceMatchResults[0];
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        int count = 0;
        for (final match in [...matches30, ...matches60, ...matches90]) {
          if (match is Map<String, dynamic> && 
              match['album_id']?.toString() == albumId) {
            count++;
          }
        }
        return count;
      }
    }
    return 0;
  }

  // Show image in dialog
  void _showImageInDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
            // Process the faceMatchResults array - each item represents a user
            if (userIndex < faceMatchData.length) {
              final userResult = faceMatchData[userIndex];
              if (userResult is Map<String, dynamic>) {
                faceMatchResults = [userResult];
              }
            }
            
            // If no match found by index, try photo URL matching as fallback
            if (faceMatchResults.isEmpty) {
              final userPhotoUrl = _getUserImageUrl(userIndex);
              for (final resultItem in faceMatchData) {
                if (resultItem is Map<String, dynamic>) {
                  final resultPhotoUrl = resultItem['profilePhotoUrl']?.toString();
                  if (resultPhotoUrl == userPhotoUrl) {
                    faceMatchResults = [resultItem];
                    break;
                  }
                }
              }
            }
            
            // If still no match, try matching by fullName as final fallback
            if (faceMatchResults.isEmpty) {
              final userName = _getUserName(userIndex);
              for (final resultItem in faceMatchData) {
                if (resultItem is Map<String, dynamic>) {
                  final resultName = resultItem['fullName']?.toString();
                  if (resultName == userName) {
                    faceMatchResults = [resultItem];
                    break;
                  }
                }
              }
            }
          }
        } else if (responseData != null && responseData is List) {
          // Fallback: if data is directly a list (old structure)
          if (userIndex < responseData.length) {
            final userResult = responseData[userIndex];
            if (userResult is Map<String, dynamic>) {
              faceMatchResults = [userResult];
            }
          }
        }
        
        setState(() {
          _faceMatchData[userIndex] = faceMatchResults;
          _isLoadingFaceMatch[userIndex] = false;
        });
        
        // Debug: Print the results
        if (faceMatchResults.isNotEmpty) {
          final userData = faceMatchResults[0];
          final apiResult = userData['apiResult'];
          if (apiResult != null) {
            final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
            final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
            final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
          } else {
          }
        } else {
        }
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
    
    // Get album information for this user
    final albums = _getUserAlbums(userIndex);
    final totalAlbumImages = _getUserAlbumCount(userIndex);
    final uniqueAlbumCount = _getUserUniqueAlbumCount(userIndex);
    
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
          albums: albums,
          totalAlbumImages: totalAlbumImages,
          uniqueAlbumCount: uniqueAlbumCount,
        ),
      ),
    );
  }

  String _getUserImageUrl(int userIndex) {
    // First, try to get profile photo from face match data if available
    final faceMatchResults = _faceMatchData[userIndex] ?? [];
    if (faceMatchResults.isNotEmpty) {
      final userData = faceMatchResults[0];
      final imageUrl = userData['profilePhotoUrl']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }
    
    // Fallback to appointment data if no face match data available
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

    // For "myself" appointments, get name from createdBy
    if (appointmentType?.toLowerCase() == 'myself') {
      final createdBy = widget.appointment['createdBy'];
      if (createdBy is Map<String, dynamic>) {
        final fullName = createdBy['fullName']?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        }
      }
    }

    // Fallback - try createdBy for any appointment type
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final fullName = createdBy['fullName']?.toString();
      if (fullName != null && fullName.isNotEmpty) {
        return fullName;
      }
    }

    return widget.appointment['email']?.toString() ?? 'Unknown';
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

    // For all other appointments (including "myself"), use userCurrentDesignation
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

    // For all other appointments (including "myself"), use userCurrentCompany
    return widget.appointment['userCurrentCompany']?.toString() ?? '';
  }

  String _getAppointmentRoleAndCompany() {
    final role = _getAppointmentRole();
    final company = _getAppointmentCompany();
    
    if (role.isNotEmpty && company.isNotEmpty) {
      return '$role at $company';
    } else if (role.isNotEmpty) {
      return role;
    } else if (company.isNotEmpty) {
      return company;
    } else {
      return '';
    }
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
    
    if (apptType == 'quick') {
      final quickApt = widget.appointment['quick_apt'];
      
      if (quickApt is Map<String, dynamic>) {
        final optional = quickApt['optional'];
        final details = quickApt['details'];
        
        // Test our helper methods
      }
    }
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        // Dropdown (reduced size)
        Expanded(
          child: Container(
            height: 36, // Match refresh button height
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
          height: 36, // Match dropdown height
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

  Future<void> _refreshAccompanyingUsers({bool showSuccessMessage = true}) async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh face match data for all users including main user
      final attendeeCount = _getAttendeeCount();
      
      for (int i = 0; i < attendeeCount; i++) {
        await _fetchFaceMatchData(i);
      }
      
      // Force UI update to show new match counts
      setState(() {
        // This will trigger rebuild with updated face match data
      });
      
      if (mounted && showSuccessMessage) {
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
      
      // Use createdBy._id as the user identifier
      String userId;
      
      if (createdBy is Map<String, dynamic>) {
        // Get the _id from createdBy object
        userId = createdBy['_id']?.toString() ?? '';
      } else {
        // If createdBy is not a Map, use empty string
        userId = '';
      }
      
      // Check if we have a valid userId
      if (userId.isEmpty) {
        setState(() {
          _upcomingAppointments = [];
          _appointmentHistory = [];
          _isLoadingOverview = false;
        });
        return;
      }

      // Fetch upcoming appointments
      final upcomingResult = await ActionService.getUpcomingAppointmentsByUser(userId: userId);
      
      // Debug: Print the API response
      if (upcomingResult['data'] != null) {
        for (int i = 0; i < (upcomingResult['data'] as List).length; i++) {
          final appointment = upcomingResult['data'][i];
        }
      }
      
      // Fetch appointment history from API (same as upcoming appointments but filter for completed)
      final historyResult = await ActionService.getUpcomingAppointmentsByUser(userId: userId);
      

      
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
          
          if (historyResult['success'] && historyResult['data'] != null) {
            final List<dynamic> historyData = historyResult['data'];
            if (historyData is List) {
              // Show everything that's NOT in upcoming appointments (simple logic)
              _appointmentHistory = historyData.where((item) {
                if (item is Map<String, dynamic>) {
                  final status = item['appointmentStatus']?['status']?.toString()?.toLowerCase();
                  final scheduledDate = item['scheduledDateTime']?['date']?.toString();
                  
                  // Check if this is a future scheduled appointment (same logic as upcoming)
                  bool isUpcoming = false;
                  if (scheduledDate != null && scheduledDate.isNotEmpty) {
                    try {
                      final appointmentDate = DateTime.parse(scheduledDate);
                      final now = DateTime.now();
                      // Check if status is scheduled/confirmed AND date is in the future
                      final isValidStatus = status == 'scheduled' || status == 'confirmed';
                      final isFutureDate = appointmentDate.isAfter(DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)));
                      isUpcoming = isValidStatus && isFutureDate;
                    } catch (e) {
                      isUpcoming = false;
                    }
                  }
                  
                  // Include everything that's NOT upcoming AND NOT unscheduled
                  final hasScheduledDate = scheduledDate != null && scheduledDate.isNotEmpty;
                  final isUnscheduled = !hasScheduledDate && status != 'completed';
                  
                  return !isUpcoming && !isUnscheduled;
                }
                return false;
              }).map((item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
              
              // Sort by date (most recent first)
              _appointmentHistory.sort((a, b) {
                final dateA = a['scheduledDateTime']?['date']?.toString() ?? '';
                final dateB = b['scheduledDateTime']?['date']?.toString() ?? '';
                
                if (dateA.isNotEmpty && dateB.isNotEmpty) {
                  try {
                    final dateTimeA = DateTime.parse(dateA);
                    final dateTimeB = DateTime.parse(dateB);
                    return dateTimeB.compareTo(dateTimeA); // Most recent first
                  } catch (e) {
                    return 0;
                  }
                }
                return 0;
              });
            } else {
              _appointmentHistory = [];
            }
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
          // Format dates as "Aug 29, 2025"
          final fromFormatted = _formatDateToReadable(from);
          final toFormatted = _formatDateToReadable(to);
          
          // Calculate difference in days
          // final difference = to.difference(from).inDays;
          // final dayText = difference == 1 ? 'day' : 'days';
          
          return '$fromFormatted To $toFormatted';
        }
      }
    }
    return 'Not specified';
  }

  String _formatDateToReadable(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final monthName = months[date.month];
    return '$monthName ${date.day}, ${date.year}';
  }

  int _getAttendeeCount() {
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      final users = accompanyUsers['users'] ?? [];
      final numberOfUsers = accompanyUsers['numberOfUsers'] ?? 0;
      
      // If users array is empty but numberOfUsers is provided, add 1 for main user
      if (users is List && users.isEmpty && numberOfUsers > 0) {
        return numberOfUsers + 1; // Add 1 for main user
      }
      
      // Total attendees = 1 (main user) + number of accompanying users
      if (users is List) {
        return 1 + users.length;
      }
    }
    return 1;
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
        // Determine international teacher
        bool isInternationalTeacher = false;
        if (aolTeacherNested['isInternational'] == true) {
          isInternationalTeacher = true;
        }
        final tType = aolTeacherNested['teacher_type']?.toString().toLowerCase();
        if (tType != null && tType.contains('taol')) {
          isInternationalTeacher = true;
        }

        final atolValidationData = aolTeacherNested['atolValidationData'];
        if (atolValidationData is Map<String, dynamic>) {
          // Support both shapes: direct or inside data
          final rawTeacherdetails = (atolValidationData['teacherdetails']) ??
              (atolValidationData['data'] is Map<String, dynamic>
                  ? (atolValidationData['data']['teacherdetails'])
                  : null);
          if (rawTeacherdetails is Map<String, dynamic>) {
            final programsRaw = rawTeacherdetails['program_types_can_teach'];
            if (programsRaw is List && programsRaw.isNotEmpty) {
              return programsRaw.map((e) => e.toString()).join(', ');
            }
            if (programsRaw != null) {
              return programsRaw.toString();
            }
          }
        }

        // If not found in validation data and international, do not fallback to Indian defaults
        if (isInternationalTeacher) {
          return 'N/A';
        }

        // Non-international fallback (nothing found)
      }
    }
    return 'N/A';
  }

  String _getProgramDateRange() {
    final attendingCourseDetails = widget.appointment['attendingCourseDetails'];
    if (attendingCourseDetails is Map<String, dynamic>) {
      final isAttending = attendingCourseDetails['isAttending'];
      if (isAttending == true) {
        final fromDate = attendingCourseDetails['fromDate'];
        final toDate = attendingCourseDetails['toDate'];
        
        if (fromDate != null && toDate != null) {
          try {
            final from = DateTime.parse(fromDate.toString());
            final to = DateTime.parse(toDate.toString());
            
            // Use the same format as requested dates
            final fromFormatted = _formatDateToReadable(from);
            final toFormatted = _formatDateToReadable(to);
            
            return '$fromFormatted To $toFormatted';
          } catch (e) {
            return 'Invalid date format';
          }
        }
      }
    }
    return 'Not attending any program';
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

  // Helper methods for schedule screens main card
  String _getAppointmentPurpose() {
    // First check for quick appointment purpose
    if (_isQuickAppointment()) {
      final quickPurpose = _getQuickAppointmentPurpose();
      if (quickPurpose.isNotEmpty) {
        return quickPurpose;
      }
    }
    
    // Check regular appointment purpose/subject
    final purpose = widget.appointment['appointmentPurpose']?.toString() ?? 
                   widget.appointment['appointmentSubject']?.toString() ?? 
                   'Not specified';
    return purpose;
  }

  String _getTeacherStatus() {
    // First, check if teacher status was passed from schedule screens
    if (widget.isTeacher != null) {
      return widget.isTeacher == true ? 'Yes' : 'No';
    }
    
    // Fallback to existing logic
    return _isTeacher() ? 'Yes' : 'No';
  }

  String _getMeetingType() {
    // Check virtual meeting details
    final virtualMeetingDetails = widget.appointment['virtualMeetingDetails'];
    if (virtualMeetingDetails is Map<String, dynamic>) {
      final isVirtualMeeting = virtualMeetingDetails['isVirtualMeeting'] == true;
      if (isVirtualMeeting) {
        return 'Online';
      }
    }
    
    // Check meeting type field
    final meetingType = widget.appointment['meetingType']?.toString();
    if (meetingType != null) {
      switch (meetingType.toLowerCase()) {
        case 'online':
        case 'virtual':
          return 'Online';
        case 'in_person':
        case 'in-person':
        case 'offline':
          return 'In-person';
        default:
          return 'In-person'; // Default assumption
      }
    }
    
    return 'In-person'; // Default
  }

  String _getAccompanyingUsersNamesWithCount() {
    try {
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'] as List<dynamic>?;
        if (users != null && users.isNotEmpty) {
          final List<String> names = [];
          for (final user in users) {
            if (user is Map<String, dynamic>) {
              final fullName = user['fullName']?.toString();
              if (fullName != null && fullName.isNotEmpty) {
                names.add(fullName);
              }
            }
          }
          if (names.isNotEmpty) {
            return '${names.join(', ')}';
          }
        }
      }
    } catch (e) {
      print('Error parsing accompanying users: $e');
    }
    return 'No accompanying users';
  }

  int _getAccompanyingUsersCount() {
    try {
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        return accompanyUsers['numberOfUsers'] ?? 0;
      }
    } catch (e) {
      print('Error getting accompanying users count: $e');
    }
    return 0;
  }

  Widget _buildAccompanyingUsersNamesRow() {
    final count = _getAccompanyingUsersCount();
    final names = _getAccompanyingUsersNamesWithCount();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.people, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Names of people ($count) accompanying the appointee: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: names,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAssignedSecretary() {
    // First, check if secretary name was passed from schedule screens
    if (widget.secretaryName != null && widget.secretaryName!.isNotEmpty) {
      return widget.secretaryName!;
    }
    
    // Debug: Print the assigned secretary data structure
    final assignedSecretary = widget.appointment['assignedSecretary'];
    
    // Check if there's an assigned secretary in the appointment
    if (assignedSecretary is Map<String, dynamic>) {
      final secretaryName = assignedSecretary['fullName']?.toString() ?? 
                           assignedSecretary['name']?.toString();
      if (secretaryName != null && secretaryName.isNotEmpty) {
        return secretaryName;
      }
    } else if (assignedSecretary is String && assignedSecretary.isNotEmpty) {
      // If it's a string, it might be a MongoDB ID - we should not display it
      // Don't return MongoDB IDs, continue to other checks
    }
    
    // Check appointmentLocation for assigned secretary
    final appointmentLocation = widget.appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final assignedSecretaries = appointmentLocation['assignedSecretaries'];
      if (assignedSecretaries is List && assignedSecretaries.isNotEmpty) {
        final firstSecretary = assignedSecretaries.first;
        if (firstSecretary is Map<String, dynamic>) {
          final secretaryId = firstSecretary['secretaryId'];
          if (secretaryId is Map<String, dynamic>) {
            final secretaryName = secretaryId['fullName']?.toString() ?? 
                                 secretaryId['name']?.toString();
            if (secretaryName != null && secretaryName.isNotEmpty) {
              return secretaryName;
            }
          }
        }
      }
    }
    
    // Check if assignedSecretary is a string that looks like a MongoDB ID
    if (assignedSecretary is String && assignedSecretary.isNotEmpty) {
      // Check if it looks like a MongoDB ObjectId (24 hex characters)
      if (RegExp(r'^[a-f\d]{24}$').hasMatch(assignedSecretary)) {
        return 'Secretary Assigned'; // Show generic message instead of ID
      }
    }
    
    return 'Not assigned';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color(0xFFF97316), // Orange color
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
            
            // Show all sections for all screens (including schedule screens)
            // Accompanying Users Section - Only show if 10 or fewer users and not from deleted appointments
            // Hide for quick appointments when coming from schedule screens
            if (_getAttendeeCount() <= 10 && 
                !widget.isFromDeletedAppointments && 
                !(widget.isFromScheduleScreens && _isQuickAppointment())) ...[
              _buildAccompanyingUsersSection(),
            ],
            
            // Accompanying User Information Card - Only show when NOT from schedule screens
            if (!widget.isFromScheduleScreens) ...[
              _buildAccompanyingUserInfoCard(),
            ],
            
            // Teacher Verification Section - Only show if user is verified and NOT a guest appointment
            if (_isTeacher() && !_isGuestAppointment()) ...[
              _buildTeacherVerificationSection(),
            ] else ...[
              // Basic Information Section for non-verified users or guest appointments
              _buildBasicInformationSection(),
            ],
            
            // Appointments Overview Section
            _buildAppointmentsOverviewSection(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    // Debug: Print appointment data structure
    
    // Debug: Check location information
    final appointmentLocation = widget.appointment['appointmentLocation'];
    final location = widget.appointment['location'];
    final venue = widget.appointment['venue'];
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    
    
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
                onTap: () => _showActionBottomSheet(context, 'call'),
              ),
              // Show Assign button for all screens (no QR button)
              _buildActionButton(
                icon: Icons.assignment_ind,
                label: 'Assign',
                color: Colors.black,
                onTap: () {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionContent(action),
    );
  }

  Widget _buildActionContent(String action) {
    switch (action) {
      case 'reminder':
        return _buildReminderContent();
      case 'email':
        return _buildEmailContent();
      case 'message':
        return _buildMessageContent();
      case 'call':
        return _buildCallContent();
      case 'assign':
        return _buildAssignContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderContent() {
    // Check if appointment already has scheduled data
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    final hasExistingSchedule = scheduledDateTime is Map<String, dynamic> && 
                               scheduledDateTime['date'] != null && 
                               scheduledDateTime['time'] != null;
    
    final title = hasExistingSchedule ? 'Edit Schedule' : 'Schedule Appointment';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader(title),
          Expanded(
            child: ReminderForm(
              appointment: widget.appointment,
              isFromScheduleScreens: widget.isFromScheduleScreens,
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

  Widget _buildCallContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Make Call'),
          Expanded(child: CallForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildAssignContent() {
    
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
    // Check if this is a guest appointment first
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    if (appointmentType == 'guest' && guestInformation is Map<String, dynamic>) {
      final guestPhone = guestInformation['phoneNumber']?.toString();
      if (guestPhone != null && guestPhone.isNotEmpty) {
        return _ensurePlusPrefix(guestPhone);
      }
    }
    
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
            return _ensurePlusPrefix('$countryCode$number');
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
        return _ensurePlusPrefix('$countryCode$number');
      }
    }
    // If it's a string, return as is
    final phoneString = phoneNumber?.toString() ?? '';
    return _ensurePlusPrefix(phoneString);
  }

  // Helper function to ensure phone number has + prefix
  String _ensurePlusPrefix(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Remove any existing + and spaces
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\+]'), '');
    
    // If it starts with a number, add + prefix
    if (cleanNumber.isNotEmpty && RegExp(r'^\d').hasMatch(cleanNumber)) {
      return '+$cleanNumber';
    }
    
    return phoneNumber; // Return original if it doesn't start with a number
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.visible,
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAppointmentRoleAndCompany(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Request Details - Different for schedule screens
          if (widget.isFromScheduleScreens) ...[
            // Show Appointment ID for all screens (including schedule screens)
            _buildMainCardDetailRowWithCopy('Appointment ID', _getAppointmentId(), Icons.tag),
            // Show Purpose, Teacher status, Meeting type, and Assigned Secretary for schedule screens
            _buildMainCardDetailRow('Purpose', _getAppointmentPurpose(), Icons.info),
            _buildMainCardDetailRow('Are you an Art of Living Teacher', _getTeacherStatus(), Icons.school),
            _buildMainCardDetailRow('Are you seeking Online or In-person appointment?', _getMeetingType(), Icons.person),
            // Show accompanying users names before Assigned Secretary
            _buildAccompanyingUsersNamesRow(),
            _buildMainCardDetailRow('Assigned Secretary', _getAssignedSecretary(), Icons.person),
            _buildMainCardDetailRow('Program Date', _getProgramDateRange(), Icons.event),
            // Show attachment if exists
            if (_getAttachmentUrl().isNotEmpty) ...[
              _buildMainCardDetailRowWithAttachment('Attachment', _getAttachmentFilename(), Icons.attach_file),
            ],
          ] else ...[
            // Show original details for other screens
            _buildMainCardDetailRowWithCopy('Appointment ID', _getAppointmentId(), Icons.tag),
            _buildMainCardDetailRow('Req. Dates', _getDateRange(), Icons.calendar_today),
            _buildMainCardDetailRow('Program Date', _getProgramDateRange(), Icons.event),
            _buildMainCardDetailRow('Location', _getLocation(), Icons.location_on),
            _buildMainCardDetailRow('Requesting Appointment for', '${_getAttendeeCount()} People', Icons.people),
            // Show reference person information for guest appointments
            if (_isGuestAppointment()) ...[
              _buildMainCardDetailRow('Guest Referred By', _getReferencePersonName(), Icons.person_add),
            ],
            // Show attachment if exists
            if (_getAttachmentUrl().isNotEmpty) ...[
              _buildMainCardDetailRowWithAttachment('Attachment', _getAttachmentFilename(), Icons.attach_file),
            ],
          ],
          

          
          const SizedBox(height: 20),
          
          // Action Buttons Section
          Row(
            children: [
              // Edit Button - Half width (disabled for schedule screens)
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isFromScheduleScreens ? null : _handleEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isFromScheduleScreens ? Colors.grey[400] : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isFromScheduleScreens ? Colors.grey[600] : Colors.white,
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
                'Users with 90-day meeting history and album information. Click refresh to load face match data.',
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
                height: 400, // Increased height to accommodate the new card design
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
                    
                    // Debug: Print what data is being used for each card
                    
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
                physics: const ClampingScrollPhysics(),
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

  Widget _buildAccompanyingUserInfoCard() {
    final eligibleUsers = _getEligibleAccompanyingUsers();
    final namesText = eligibleUsers.isNotEmpty 
        ? eligibleUsers.join(', ')
        : 'Not provided';
    
    return Container(
      margin: const EdgeInsets.all(16), // Match Basic Information section
      padding: const EdgeInsets.all(20), // Match Basic Information section
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Match Basic Information section
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            const TextSpan(
              text: 'Name of people accompanying the appointee under age 12 and above 60 : ',
            ),
            TextSpan(
              text: namesText,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getEligibleAccompanyingUsers() {
    final List<String> eligibleNames = [];
    
    try {
      final accompanyUsers = widget.appointment['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'] as List<dynamic>?;
        if (users != null) {
          for (final user in users) {
            if (user is Map<String, dynamic>) {
              final fullName = user['fullName']?.toString();
              final ageStr = user['age']?.toString();
              
              if (fullName != null && fullName.isNotEmpty && ageStr != null && ageStr.isNotEmpty) {
                final age = int.tryParse(ageStr);
                if (age != null && (age < 12 || age > 60)) {
                  eligibleNames.add(fullName);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Handle any parsing errors gracefully
      print('Error parsing accompanying users: $e');
    }
    
    return eligibleNames;
  }

  Widget _buildUserCard(String name, String label, int matches, bool isMainUser, int userIndex) {
    // Get album information
    final albums = _getUserAlbums(userIndex);
    final totalAlbumImages = _getUserAlbumCount(userIndex);
    final uniqueAlbumCount = _getUserUniqueAlbumCount(userIndex);
    
    // Get meeting history data
    final meetingHistory = _getMeetingHistory(userIndex);
    final lastMeetingDate = _getLastMeetingDate(userIndex);
    final lastMeetingDaysAgo = _getLastMeetingDaysAgo(userIndex);
    final totalMeetings = _getTotalMeetings(userIndex);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile image and user info
            Row(
              children: [
                // Profile Image with badge
                Container(
                  width: 80, // Increased width to accommodate badge
                  height: 80, // Increased height to accommodate badge
                  child: Stack(
                    clipBehavior: Clip.none, // Allow badge to extend outside
                    children: [
                      Positioned(
                        left: 8, // Center the image within the larger container
                        top: 8,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMainUser ? Colors.orange[400]! : Colors.blue[400]!, 
                              width: 4
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildNetworkImage(_getUserImageUrl(userIndex), 32),
                          ),
                        ),
                      ),
                      // Badge showing user number
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isMainUser ? Colors.orange[500] : Colors.blue[500],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${userIndex + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // User Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMainUser ? '(Main Appointee #1)' : '(Accompanying #${userIndex + 1})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isMainUser ? Colors.orange[600] : Colors.blue[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Meeting Statistics Grid
            Column(
              children: [
                // Last Meeting Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Text(
                          'LAST MEETING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                                              Row(
                          children: [
                            Text(
                              lastMeetingDate,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                            if (lastMeetingDaysAgo != '0') ...[
                              const SizedBox(width: 8),
                              Text(
                                '$lastMeetingDaysAgo days ago',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Total Albums Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Text(
                          'TOTAL MEETINGS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '$uniqueAlbumCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Meeting History Section
            if (meetingHistory.isNotEmpty) ...[
              Text(
                'Meeting History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 12),
              
                             // Meeting History List
               Column(
                 children: [
                   ...(_isMeetingHistoryExpanded[userIndex] == true 
                     ? meetingHistory 
                     : meetingHistory.take(3)
                   ).map((meeting) => _buildMeetingHistoryItem(meeting, userIndex)),
                   if (meetingHistory.length > 3) ...[
                     const SizedBox(height: 8),
                     Center(
                       child: GestureDetector(
                         onTap: () {
                           if (_isMeetingHistoryExpanded[userIndex] == true) {
                             // Collapse if expanded
                             setState(() {
                               _isMeetingHistoryExpanded[userIndex] = false;
                             });
                           } else {
                             // Navigate to meeting history screen
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => MeetingHistoryScreen(
                                   userName: _getUserName(userIndex),
                                   meetingHistory: meetingHistory,
                                   userIndex: userIndex,
                                   faceMatchData: _faceMatchData[userIndex] ?? [],
                                 ),
                               ),
                             );
                           }
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.blue.shade50,
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.blue.shade200),
                           ),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text(
                                 _isMeetingHistoryExpanded[userIndex] == true 
                                   ? 'Show Less' 
                                   : '+${meetingHistory.length - 3} more meetings',
                                 style: TextStyle(
                                   fontSize: 12,
                                   color: Colors.blue.shade700,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                               const SizedBox(width: 4),
                              //  Icon(
                              //    _isMeetingHistoryExpanded[userIndex] == true 
                              //      ? Icons.keyboard_arrow_up 
                              //      : Icons.keyboard_arrow_down,
                              //    size: 16,
                              //    color: Colors.blue.shade700,
                              //  ),
                             ],
                           ),
                         ),
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
          
          // For non-verified teachers, show only purpose and tags
          // Purpose
          if (!_isQuickAppointment()) ...[
            if (_getQuickAppointmentPurpose().isNotEmpty) ...[
              _buildDetailRow('Purpose of appointment', _getQuickAppointmentPurpose(), Icons.info),
            ] else ...[
              _buildDetailRow('Purpose of appointment', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
            ],
          ] else ...[
            // For quick appointments, show basic info without duplicating quick appointment data
            _buildDetailRow('Purpose of appointment', widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified', Icons.info),
          ],
          
          // Tags (hide for guest appointments)
          if (!_isGuestAppointment()) _buildUserTagsRow(),
        ],
      ),
    );
  }

  Widget _buildTeacherVerificationSection() {
    final teacherCode = _getTeacherCode();
    
    // Detect international teacher from createdBy.aol_teacher
    bool isInternationalTeacher = false;
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final aolTeacherNested = createdBy['aol_teacher'];
      if (aolTeacherNested is Map<String, dynamic>) {
        if (aolTeacherNested['isInternational'] == true) {
          isInternationalTeacher = true;
        }
        final tType = aolTeacherNested['teacher_type']?.toString().toLowerCase();
        if (tType != null && tType.contains('taol')) {
          isInternationalTeacher = true;
        }
      }
    }
    
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
          // Header label similar to provided design
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Art Of Living Teacher Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Status Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // slate-50
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code + Verified/Pending chip
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (teacherCode.isNotEmpty)
                      Text(
                        teacherCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569), // slate-600
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInternationalTeacher ? const Color(0xFFFFFBEB) /* amber-50 */ : const Color(0xFFF0FDF4) /* green-50 */,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isInternationalTeacher ? const Color(0xFFFDE68A) /* amber-300 */ : const Color(0xFFBBF7D0) /* green-200 */,
                        ),
                      ),
                      child: Text(
                        isInternationalTeacher ? 'Pending' : 'Verified By Art Of Living',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isInternationalTeacher ? const Color(0xFF92400E) /* amber-900 */ : const Color(0xFF15803D) /* green-700 */,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Teacher label
                const Text(
                  'Art Of Living Teacher',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827), // gray-900
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Programs list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programs:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569), // slate-600
                      ),
                    ),
                    const SizedBox(height: 6),
                    Builder(
                      builder: (context) {
                        final programsString = _getTeacherPrograms();
                        final List<String> programs = programsString
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                        if (programs.isEmpty) {
                          return const Text(
                            'N/A',
                            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: programs
                              .map((p) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                                        Expanded(
                                          child: Text(
                                            p,
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isGuestAppointment()) _buildUserTagsRow(),
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
          // Text(
          //   'Notes and remarks for this appointment.',
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: Colors.grey[600],
          //   ),
          // ),
          // const SizedBox(height: 20),
          
          // Notes Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isQuickAppointment() ? 'Notes for Secretary' : 'Notes for Secretary',
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
                  hintText: _isQuickAppointment() ? 'Add your notes here...' : 'Add your notes here...',
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
                _isQuickAppointment() ? 'Remarks for Gurudev' : 'Remarks for Gurudev',
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
                  hintText: _isQuickAppointment() ? 'Add your remarks here...' : 'Add your remarks here...',
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
                              '${_upcomingAppointments.where((appointment) {
                                if (appointment is Map<String, dynamic>) {
                                  final status = appointment['appointmentStatus']?['status']?.toString()?.toLowerCase();
                                  final scheduledDate = appointment['scheduledDateTime']?['date']?.toString();
                                  
                                  // Check if status is scheduled or confirmed
                                  final isValidStatus = status == 'scheduled' || status == 'confirmed';
                                  
                                  // Check if date is in the future
                                  bool isFutureDate = false;
                                  if (scheduledDate != null && scheduledDate.isNotEmpty) {
                                    try {
                                      final appointmentDate = DateTime.parse(scheduledDate);
                                      final now = DateTime.now();
                                      // Consider it future if it's today or later (including time)
                                      isFutureDate = appointmentDate.isAfter(now.subtract(const Duration(days: 1)));
                                    } catch (e) {
                                      // If date parsing fails, don't show it
                                      isFutureDate = false;
                                    }
                                  }
                                  
                                  return isValidStatus && isFutureDate;
                                }
                                return false;
                              }).length} items',
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
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _upcomingAppointments.where((appointment) {
                                // Filter to show only scheduled/confirmed appointments with future dates
                                if (appointment is Map<String, dynamic>) {
                                  final status = appointment['appointmentStatus']?['status']?.toString()?.toLowerCase();
                                  final scheduledDate = appointment['scheduledDateTime']?['date']?.toString();
                                  final appointmentId = appointment['appointmentId']?.toString();
                                  
                                  // Debug: Print appointment details
                                  if (appointment['scheduledDateTime'] is Map) {
                                    final scheduledDateTime = appointment['scheduledDateTime'] as Map;
                                  }
                                  
                                  // Check if status is scheduled or confirmed
                                  final isValidStatus = status == 'scheduled' || status == 'confirmed';
                                  
                                  // Check if date is in the future
                                  bool isFutureDate = false;
                                  if (scheduledDate != null && scheduledDate.isNotEmpty) {
                                    try {
                                      final appointmentDate = DateTime.parse(scheduledDate);
                                      final now = DateTime.now();
                                      
                                      // Compare only the date part (ignoring time)
                                      final today = DateTime(now.year, now.month, now.day);
                                      final appointmentDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
                                      
                                      // Consider it future if it's today or later
                                      isFutureDate = appointmentDay.isAfter(today.subtract(const Duration(days: 1)));
                                      
                                    } catch (e) {
                                      // If date parsing fails, don't show it
                                      isFutureDate = false;
                                    }
                                  } else {
                                  }
                                  
                                  final shouldShow = isValidStatus && isFutureDate;
                                  
                                  return shouldShow;
                                }
                                return false;
                              }).map((appointment) {
                                try {
                                  // Extract the required fields
                                  final purpose = appointment['appointmentPurpose']?.toString() ?? 
                                                appointment['appointmentSubject']?.toString() ?? 'No Purpose';
                                  final venueLabel = appointment['scheduledDateTime']?['venueLabel']?.toString() ?? 'No Venue';
                                  final secretary = appointment['assignedSecretary']?['fullName']?.toString() ?? 'No Secretary';
                                  final date = appointment['scheduledDateTime']?['date']?.toString() ?? 'No Date';
                                  final time = appointment['scheduledDateTime']?['time']?.toString() ?? 'No Time';
                                  
                                  // Format date and time
                                  String formattedDate = 'No Date';
                                  String formattedTime = 'No Time';
                                  
                                  if (date != 'No Date' && date.isNotEmpty) {
                                    try {
                                      final dateTime = DateTime.parse(date);
                                      final months = [
                                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                      ];
                                      formattedDate = '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
                                    } catch (e) {
                                      formattedDate = date;
                                    }
                                  }
                                  
                                  if (time != 'No Time' && time.isNotEmpty) {
                                    try {
                                      final timeParts = time.split(':');
                                      if (timeParts.length >= 2) {
                                        final hour = int.parse(timeParts[0]);
                                        final minute = timeParts[1];
                                        final period = hour >= 12 ? 'PM' : 'AM';
                                        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                                        formattedTime = '${displayHour}:${minute} $period';
                                      } else {
                                        formattedTime = time;
                                      }
                                    } catch (e) {
                                      formattedTime = time;
                                    }
                                  }
                                  
                                  // Create display name with purpose, venue, and secretary
                                  String displayName = '$purpose - $venueLabel - $secretary';
                                  
                                                                                                        return _buildAppointmentItem(
                                    purpose: purpose,
                                    venueLabel: venueLabel,
                                    secretary: secretary,
                                    date: formattedDate,
                                    time: formattedTime,
                                    status: appointment['appointmentStatus']?['status']?.toString() ?? 'Pending',
                                    statusColor: _getStatusColor(appointment['appointmentStatus']?['status']?.toString() ?? 'pending'),
                                    isTbs: _isTbsAppointment(appointment),
                                    appointment: appointment,
                                  );
                                } catch (e) {
                                  return _buildAppointmentItem(
                                    purpose: 'Unknown Purpose',
                                    venueLabel: 'Unknown Venue',
                                    secretary: 'Unknown Secretary',
                                    date: 'Unknown Date',
                                    time: 'Unknown Time',
                                    status: 'Unknown',
                                    statusColor: Colors.grey,
                                    isTbs: false,
                                    appointment: appointment,
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
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: _appointmentHistory.map((appointment) {
                                try {
                                  // Extract the required fields from upcoming appointments API data
                                  final purpose = appointment['appointmentPurpose']?.toString() ?? 
                                                appointment['appointmentSubject']?.toString() ?? 'No Purpose';
                                  final venueLabel = appointment['scheduledDateTime']?['venueLabel']?.toString() ?? 'No Venue';
                                  final secretary = appointment['assignedSecretary']?['fullName']?.toString() ?? 'No Secretary';
                                  final date = appointment['scheduledDateTime']?['date']?.toString() ?? 'No Date';
                                  final time = appointment['scheduledDateTime']?['time']?.toString() ?? 'No Time';
                                  
                                  // Format date and time
                                  String formattedDate = 'No Date';
                                  String formattedTime = 'No Time';
                                  
                                  if (date != 'No Date' && date.isNotEmpty) {
                                    try {
                                      final dateTime = DateTime.parse(date);
                                      final months = [
                                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                      ];
                                      formattedDate = '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
                                    } catch (e) {
                                      formattedDate = date;
                                    }
                                  }
                                  
                                  if (time != 'No Time' && time.isNotEmpty) {
                                    try {
                                      final timeParts = time.split(':');
                                      if (timeParts.length >= 2) {
                                        final hour = int.parse(timeParts[0]);
                                        final minute = timeParts[1];
                                        final period = hour >= 12 ? 'PM' : 'AM';
                                        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
                                        formattedTime = '${displayHour}:${minute} $period';
                                      } else {
                                        formattedTime = time;
                                      }
                                    } catch (e) {
                                      formattedTime = time;
                                    }
                                  }
                                  
                                  return _buildAppointmentHistoryItem(
                                    purpose: purpose,
                                    venueLabel: venueLabel,
                                    secretary: secretary,
                                    date: formattedDate,
                                    time: formattedTime,
                                    status: appointment['appointmentStatus']?['status']?.toString() ?? 'Unknown',
                                    statusColor: _getStatusColor(appointment['appointmentStatus']?['status']?.toString() ?? 'unknown'),
                                    isTbs: _isTbsAppointment(appointment),
                                    appointment: appointment,
                                  );
                                } catch (e) {
                                  return _buildAppointmentHistoryItem(
                                    purpose: 'Unknown Purpose',
                                    venueLabel: 'Unknown Venue',
                                    secretary: 'Unknown Secretary',
                                    date: 'Unknown Date',
                                    time: 'Unknown Time',
                                    status: 'Unknown',
                                    statusColor: Colors.grey,
                                    isTbs: false,
                                    appointment: appointment,
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

  // Helper method to check if appointment is TBS
  bool _isTbsAppointment(Map<String, dynamic> appointment) {
    final communicationPreferences = appointment['communicationPreferences'];
    
    // Debug: Print the communication preferences
    
    if (communicationPreferences is List) {
      final hasTbsReq = communicationPreferences.any(
        (pref) => pref.toString() == 'TBS/Req',
      );
      return hasTbsReq;
    }
    
    return false;
  }

  // Helper method to format venue label based on TBS status and shortName
  String _formatVenueLabel(Map<String, dynamic> appointment) {
    // Check if it's TBS appointment
    final communicationPreferences = appointment['communicationPreferences'];
    if (communicationPreferences is List) {
      final hasTbsReq = communicationPreferences.any(
        (pref) => pref.toString() == 'TBS/Req',
      );
      if (hasTbsReq) {
        return 'TBS/Req';
      }
    }
    
    // If not TBS, check scheduledVenue.shortName
    final scheduledVenue = appointment['scheduledVenue'];
    if (scheduledVenue is Map && scheduledVenue['shortName'] != null) {
      return scheduledVenue['shortName'].toString();
    }
    
    // If no shortName, return "Scheduled"
    return 'Scheduled';
  }

  // Helper method to get short secretary name from uppercase letters
  String _getShortSecretaryName(String fullName) {
    if (fullName.isEmpty || fullName == 'No Secretary') {
      return 'No Sec';
    }
    
    // Extract all uppercase letters from the name
    final uppercaseLetters = fullName.split('').where((char) => char == char.toUpperCase() && char != char.toLowerCase()).toList();
    
    if (uppercaseLetters.isNotEmpty) {
      // If there are uppercase letters, return them combined
      return uppercaseLetters.join('');
    } else {
      // If no uppercase letters, return first two letters
      return fullName.length >= 2 ? fullName.substring(0, 2).toUpperCase() : fullName.toUpperCase();
    }
  }

  Widget _buildAppointmentItem({
    required String purpose,
    required String venueLabel,
    required String secretary,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required bool isTbs,
    required Map<String, dynamic> appointment,
  }) {
    // Format venue and secretary based on TBS status
    final formattedVenue = _formatVenueLabel(appointment);
    final formattedSecretary = _getShortSecretaryName(secretary);
    
    // Debug: Print what's being displayed
    
    final displayText = isTbs 
      ? '$purpose, $formattedVenue, $date, $formattedSecretary'
      : '$purpose, $formattedVenue, $date, $formattedSecretary';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Appointment details
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentHistoryItem({
    required String purpose,
    required String venueLabel,
    required String secretary,
    required String date,
    required String time,
    required String status,
    required Color statusColor,
    required bool isTbs,
    required Map<String, dynamic> appointment,
  }) {
    // Format display text based on appointment status for history
    String displayText;
    final appointmentStatus = appointment['appointmentStatus']?['status']?.toString()?.toLowerCase();
    final hasScheduledDate = appointment['scheduledDateTime']?['date'] != null;
    
    // Get short secretary name
    final shortSecretaryName = _getShortSecretaryName(secretary);
    
    if (appointmentStatus == 'completed') {
      // Completed: purpose, Done, schedule date, secretary
      displayText = '$purpose, Done, $date, $shortSecretaryName';
    } else if (appointmentStatus == 'scheduled' && hasScheduledDate) {
      // Scheduled: purpose, Scheduled, schedule date, secretary
      displayText = '$purpose, Scheduled, $date, $shortSecretaryName';
    } else {
      // Not scheduled: purpose, Not Scheduled
      displayText = '$purpose, Not Scheduled';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bullet point
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[600], // Different color for history
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          
          // Appointment details
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: null,
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
                  overflow: TextOverflow.visible,
                  maxLines: null,
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
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardDetailRowWithCopy(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.lightBlue[100], // Ocean blue background
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.lightBlue[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.lightBlue[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(value),
                    borderRadius: BorderRadius.circular(2),
                    child: Icon(
                      Icons.copy,
                      size: 14,
                      color: Colors.lightBlue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCardDetailRowWithAttachment(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _openAttachment,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!.withOpacity(0.5),
                      Colors.indigo[50]!.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[100]!.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Attachment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Colors.blue[600],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Copy to clipboard method
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied "$text" to clipboard'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Copy attachment URL to clipboard method
  Future<void> _copyAttachmentUrlToClipboard(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attachment URL copied to clipboard'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy URL: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
        return;
      }

      
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
        
      } else {
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

  void _showQRCodeDialog(Map<String, dynamic> appointment) async {
    final appointmentId = appointment['appointmentId']?.toString();
    if (appointmentId == null) {
      _showSnackBar('Error: Appointment ID not found', isError: true);
      return;
    }
    // Use the correct domain for QR codes from action.dart
    final String baseUrl = await ActionService.baseUrl;
    final qrUrl = '$baseUrl/public/qr-codes/qr-$appointmentId.png';
    final patientName = _getAppointmentName();
    
    // Debug: Print the URL to console

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

  // Helper method to get attachment URL
  String _getAttachmentUrl() {
    return widget.appointment['appointmentAttachment']?.toString() ?? '';
  }

  // Helper method to get attachment filename
  String _getAttachmentFilename() {
    final attachmentUrl = _getAttachmentUrl();
    if (attachmentUrl.isNotEmpty) {
      // Extract filename from URL
      final uri = Uri.parse(attachmentUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    }
    return 'Attachment';
  }

  // Helper method to get file extension
  String _getFileExtension() {
    final filename = _getAttachmentFilename();
    if (filename.contains('.')) {
      return filename.split('.').last.toLowerCase();
    }
    return '';
  }

  // Helper method to get file icon based on extension
  IconData _getFileIcon() {
    final extension = _getFileExtension();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.attach_file;
    }
  }

  // Helper method to get file type color
  Color _getFileColor() {
    final extension = _getFileExtension();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Method to open attachment
  Future<void> _openAttachment() async {
    final attachmentUrl = _getAttachmentUrl();
    if (attachmentUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No attachment available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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
          ),
        );
      }
    }
  }

  // Build attachment section
  Widget _buildAttachmentSection() {
    final attachmentUrl = _getAttachmentUrl();
    
    if (attachmentUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _openAttachment,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!.withOpacity(0.5),
                Colors.indigo[50]!.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue[100]!.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'View Attachment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new,
                color: Colors.blue[600],
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}