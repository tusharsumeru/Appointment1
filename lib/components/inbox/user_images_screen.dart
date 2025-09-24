import 'package:flutter/material.dart';
import 'dart:ui';

class UserImagesScreen extends StatefulWidget {
  final String userName;
  final int imageCount;
  final String? userImageUrl;
  final List<Map<String, dynamic>> faceMatchData;
  final bool isLoading;
  final String? error;
  final int userIndex;
  final Map<String, int>? albums;
  final int? totalAlbumImages;
  final int? uniqueAlbumCount;
  final bool isAlbumView;
  final String? albumId;

  const UserImagesScreen({
    super.key,
    required this.userName,
    required this.imageCount,
    this.userImageUrl,
    this.faceMatchData = const [],
    this.isLoading = false,
    this.error,
    this.userIndex = 0,
    this.albums,
    this.totalAlbumImages,
    this.uniqueAlbumCount,
    this.isAlbumView = false,
    this.albumId,
  });

  @override
  State<UserImagesScreen> createState() => _UserImagesScreenState();
}

class _UserImagesScreenState extends State<UserImagesScreen> {
  
  String _getUserImageUrl(int index) {
    // For all users (main user and accompanying users), return only face match result images (no profile image)
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0]; // Get first result
      
      // Check if this is the main result object with apiResult
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Use time_categories.all_time structure
        final timeCategories = apiResult['time_categories'];
        if (timeCategories != null) {
          final allTimeData = timeCategories['all_time'];
          if (allTimeData != null && allTimeData['top_matches'] != null) {
            final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
            
            if (index < matches.length) {
              final match = matches[index];
              return match['image_name']?.toString() ?? 
                     'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
            }
          }
        }
      }
    }
    
    // Fallback for no images
    return 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
  }



  double _getMatchConfidence(int index) {
    // For all users, calculate confidence from API matches
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0]; // Get first result
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Use time_categories.all_time structure
        final timeCategories = apiResult['time_categories'];
        if (timeCategories != null) {
          final allTimeData = timeCategories['all_time'];
          if (allTimeData != null && allTimeData['top_matches'] != null) {
            final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
            
            if (index < matches.length) {
              final match = matches[index];
              final score = match['score']?.toDouble() ?? 0.0;
              // Convert score to percentage (assuming score is 0-1, multiply by 100)
              return (score * 100).clamp(0.0, 100.0);
            }
          }
        }
      }
    }
    
    return 0.0;
  }

  int _getActualImageCount() {
    // For all users, count only API matches (no profile image)
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0]; // Get first result
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Use time_categories.all_time structure
        final timeCategories = apiResult['time_categories'];
        if (timeCategories != null) {
          final allTimeData = timeCategories['all_time'];
          if (allTimeData != null && allTimeData['top_matches'] != null) {
            final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
            return matches.length;
          }
        }
      }
    }
    
    return 0; // No matches found
  }

  // Get album ID for a specific image
  String _getImageAlbumId(int index) {
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0];
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Use time_categories.all_time structure
        final timeCategories = apiResult['time_categories'];
        if (timeCategories != null) {
          final allTimeData = timeCategories['all_time'];
          if (allTimeData != null && allTimeData['top_matches'] != null) {
            final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
            
            if (index < matches.length) {
              final match = matches[index];
              return match['album_id']?.toString() ?? '';
            }
          }
        }
      }
    }
    
    return '';
  }

  // Helper: extract epoch millis from image name and format date as "Friday, Sep 5, 2025"
  String _formatEpochToApiDate(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    
    return '$weekday, $month $day, $year';
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

  // Get image date for a specific image
  String _getImageDate(int index) {
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0];
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Use time_categories.all_time structure
        final timeCategories = apiResult['time_categories'];
        if (timeCategories != null) {
          final allTimeData = timeCategories['all_time'];
          if (allTimeData != null && allTimeData['top_matches'] != null) {
            final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
            
            if (index < matches.length) {
              final match = matches[index];
              String date = match['date']?.toString() ?? '';
              final imageUrl = match['image_name']?.toString() ?? '';
              
              // If date is unknown/empty, try to derive it from image name
              final isUnknown = date.isEmpty || date.toLowerCase() == 'unknown' || date == 'null';
              if (isUnknown && imageUrl.isNotEmpty) {
                final derived = _extractDateFromImageName(imageUrl);
                if (derived != null) {
                  date = derived;
                }
              }
              
              if (date.isNotEmpty && date.toLowerCase() != 'unknown' && date != 'null') {
                return date;
              }
            }
          }
        }
      }
    }
    
    return 'Image ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: widget.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : widget.error != null
          ? _buildErrorWidget()
          : _getActualImageCount() == 0
            ? _buildNoImagesWidget()
            : Column(
                children: [
                  // Header Info
                  _buildHeaderInfo(),
                  
                  // Images Grid
                  Expanded(
                    child: _buildImagesGrid(),
                  ),
                ],
              ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.error ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoImagesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No images found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userIndex == 0 
              ? 'This user has no additional images'
              : 'No face match results found for this user',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
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
      child: _buildMeetingInfo(),
    );
  }

  // Build meeting information widget
  Widget _buildMeetingInfo() {
    final meetingInfo = _getMeetingInfo();
    if (meetingInfo.isEmpty) return const SizedBox.shrink();
    
    // Extract album ID and meeting details
    final albumId = _getAlbumId();
    final meetingDetails = _getMeetingDetails();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Meeting Evidence: $albumId',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            meetingDetails,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Get album ID from the first image
  String _getAlbumId() {
    if (widget.faceMatchData.isEmpty) return 'N/A';
    
    final result = widget.faceMatchData[0];
    if (result['apiResult'] == null) return 'N/A';
    
    final apiResult = result['apiResult'];
    // Use time_categories.all_time structure
    final timeCategories = apiResult['time_categories'];
    if (timeCategories != null) {
      final allTimeData = timeCategories['all_time'];
      if (allTimeData != null && allTimeData['top_matches'] != null) {
        final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
        if (matches.isEmpty) return 'N/A';
        
        final firstMatch = matches[0];
        return firstMatch['album_id']?.toString() ?? 'N/A';
      }
    }
    
    return 'N/A';
  }

  // Get meeting details (photo count and date info)
  String _getMeetingDetails() {
    if (widget.faceMatchData.isEmpty) return '';
    
    final result = widget.faceMatchData[0];
    if (result['apiResult'] == null) return '';
    
    final apiResult = result['apiResult'];
    // Use time_categories.all_time structure
    final timeCategories = apiResult['time_categories'];
    if (timeCategories != null) {
      final allTimeData = timeCategories['all_time'];
      if (allTimeData != null && allTimeData['top_matches'] != null) {
        final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
        if (matches.isEmpty) return '';
        
        // Get the first match to extract meeting info
        final firstMatch = matches[0];
        final imageUrl = firstMatch['image_name']?.toString() ?? '';
        
        if (imageUrl.isEmpty) return '';
        
        // Extract meeting date and time from image URL
        final meetingDateTime = _extractMeetingDateTime(imageUrl);
        if (meetingDateTime == null) return '';
        
        final photoCount = matches.length;
        final photoText = photoCount == 1 ? 'photo' : 'photos';
        
        return '$photoCount $photoText from this meeting with Gurudev - Meeting on ${meetingDateTime['date']} - Meeting on ${meetingDateTime['fullDateTime']}';
      }
    }
    
    return '';
  }

  // Get meeting information from image data
  String _getMeetingInfo() {
    if (widget.faceMatchData.isEmpty) return '';
    
    final result = widget.faceMatchData[0];
    if (result['apiResult'] == null) return '';
    
    final apiResult = result['apiResult'];
    // Use time_categories.all_time structure
    final timeCategories = apiResult['time_categories'];
    if (timeCategories != null) {
      final allTimeData = timeCategories['all_time'];
      if (allTimeData != null && allTimeData['top_matches'] != null) {
        final matches = allTimeData['top_matches'] as List<dynamic>? ?? [];
        if (matches.isEmpty) return '';
        
        // Get the first match to extract meeting info
        final firstMatch = matches[0];
        final imageUrl = firstMatch['image_name']?.toString() ?? '';
        
        if (imageUrl.isEmpty) return '';
        
        // Extract meeting date and time from image URL
        final meetingDateTime = _extractMeetingDateTime(imageUrl);
        if (meetingDateTime == null) return '';
        
        final photoCount = matches.length;
        final photoText = photoCount == 1 ? 'photo' : 'photos';
        
        return '$photoCount $photoText from this meeting with Gurudev - Meeting on ${meetingDateTime['date']} - Meeting on ${meetingDateTime['fullDateTime']}';
      }
    }
    
    return '';
  }

  // Extract meeting date and time from image URL
  Map<String, String>? _extractMeetingDateTime(String imageUrl) {
    try {
      // Find 13-digit timestamp in the URL
      final timestampMatch = RegExp(r'(\d{13})').firstMatch(imageUrl);
      if (timestampMatch != null) {
        final timestamp = int.parse(timestampMatch.group(1)!);
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
        
        // Format date as DD/MM/YYYY
        final dateStr = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
        
        // Format full date time
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        
        final weekday = weekdays[dateTime.weekday - 1];
        final month = months[dateTime.month - 1];
        final day = dateTime.day;
        final year = dateTime.year;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final second = dateTime.second.toString().padLeft(2, '0');
        
        final fullDateTime = '$weekday $month ${day.toString().padLeft(2, '0')} $year $hour:$minute:$second GMT+0530 (India Standard Time)';
        
        return {
          'date': dateStr,
          'fullDateTime': fullDateTime,
        };
      }
    } catch (e) {
      // Handle parsing errors
    }
    return null;
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _getActualImageCount(),
      itemBuilder: (context, index) {
        return _buildImageCard(index);
      },
    );
  }

  Widget _buildImageCard(int index) {
    return GestureDetector(
      onTap: () => _showImageDetail(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    _getUserImageUrl(index),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Image Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date display
                  Text(
                    _getImageDate(index),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Album information
                  if (widget.albums != null && widget.albums!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.album,
                          size: 10,
                          color: Colors.green[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _getImageAlbumId(index),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDetail(int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              _getUserImageUrl(index),
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
      ),
    );
  }
} 