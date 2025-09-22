import 'package:flutter/material.dart';
import 'user_images_screen.dart';

class MeetingHistoryScreen extends StatefulWidget {
  final String userName;
  final List<Map<String, dynamic>> meetingHistory;
  final int userIndex;
  final List<Map<String, dynamic>>? faceMatchData; // Add face match data

  const MeetingHistoryScreen({
    super.key,
    required this.userName,
    required this.meetingHistory,
    required this.userIndex,
    this.faceMatchData,
  });

  @override
  State<MeetingHistoryScreen> createState() => _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends State<MeetingHistoryScreen> {
  // Pagination state
  int _currentPage = 1;
  bool _isLoadingMore = false;
  static const int _meetingsPerPage = 10;

  @override
  void initState() {
    super.initState();
  }

  // Get paginated meetings
  List<Map<String, dynamic>> _getPaginatedMeetings() {
    final startIndex = 0;
    final endIndex = _currentPage * _meetingsPerPage;
    return widget.meetingHistory
        .sublist(startIndex, endIndex > widget.meetingHistory.length ? widget.meetingHistory.length : endIndex);
  }

  // Check if there are more meetings to load
  bool _hasMoreMeetings() {
    final totalLoaded = _currentPage * _meetingsPerPage;
    return totalLoaded < widget.meetingHistory.length;
  }

  // Load more meetings
  Future<void> _loadMoreMeetings() async {
    if (_isLoadingMore || !_hasMoreMeetings()) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.userName} - Meeting History'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.meetingHistory.isEmpty
          ? _buildNoMeetingsWidget()
          : _buildMeetingHistoryList(),
    );
  }

  Widget _buildNoMeetingsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No meeting history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This user has no previous meeting records',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meeting History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.meetingHistory.length} total meetings found',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          // Progress indicator
          LinearProgressIndicator(
            value: _getPaginatedMeetings().length / widget.meetingHistory.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing ${_getPaginatedMeetings().length} of ${widget.meetingHistory.length} meetings',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingHistoryList() {
    final paginatedMeetings = _getPaginatedMeetings();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      itemCount: paginatedMeetings.length + (_hasMoreMeetings() ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == paginatedMeetings.length) {
          // Load more section
          return _buildLoadMoreSection();
        }
        
        return _buildMeetingHistoryItem(paginatedMeetings[index], index);
      },
    );
  }

  Widget _buildLoadMoreSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          if (_isLoadingMore) ...[
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          if (_hasMoreMeetings() && !_isLoadingMore) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadMoreMeetings,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Load More Meetings',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          if (!_hasMoreMeetings()) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'All meetings loaded',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeetingHistoryItem(Map<String, dynamic> meeting, int index) {
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
        formattedDate = '$day/$month/$year';
      }
    } catch (e) {
      // Keep original date if parsing fails
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildNetworkImage(imageUrl, 30),
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
            onPressed: () => _navigateToUserImages(meeting, index),
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

  // Helper method to build network image (same as appointment detail page)
  Widget _buildNetworkImage(String imageUrl, double iconSize) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.image, size: iconSize, color: Colors.grey),
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.image, size: iconSize, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  // Helper method to show image in dialog (same as appointment detail page)
  void _showImageInDialog(String imageUrl) {
    if (imageUrl.isEmpty) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
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

  void _navigateToUserImages(Map<String, dynamic> meeting, int index) {
    // Extract meeting data for the user images screen
    final albumId = meeting['albumId']?.toString() ?? '';
    final totalImages = int.tryParse(meeting['totalImages']?.toString() ?? '0') ?? 0;
    
    // Extract ONLY images from the specific album from face match data
    List<Map<String, dynamic>> albumImages = [];
    
    if (widget.faceMatchData != null && widget.faceMatchData!.isNotEmpty) {
      final result = widget.faceMatchData![0];
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        // Filter matches for ONLY this specific album
        for (final match in allMatches) {
          if (match is Map<String, dynamic>) {
            final matchAlbumId = match['album_id']?.toString() ?? '';
            if (matchAlbumId == albumId) {
              albumImages.add(match);
            }
          }
        }
      }
    }
    
    // If no images found in face match data, create a fallback with multiple images
    if (albumImages.isEmpty) {
      final imageUrl = meeting['imageUrl']?.toString() ?? '';
      final date = meeting['date']?.toString() ?? '';
      
      // Create multiple fallback images for this album (simulate different images)
      for (int i = 0; i < totalImages; i++) {
        albumImages.add({
          'image_name': imageUrl, // In real scenario, these would be different image URLs
          'album_id': albumId,
          'date': date,
          'score': 0.95 - (i * 0.01),
        });
      }
    }
    
    // Create face match data structure for ONLY this specific album
    final faceMatchData = [
      {
        'apiResult': {
          '30_days': {
            'matches': albumImages, // Only images from this album
          },
          '60_days': {'matches': []}, // Empty for other time periods
          '90_days': {'matches': []}, // Empty for other time periods
        }
      }
    ];
    
    // Navigate to user images screen with ONLY this album's images
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserImagesScreen(
          userName: widget.userName,
          imageCount: albumImages.length, // Only count of this album's images
          faceMatchData: faceMatchData, // Only this album's data
          userIndex: widget.userIndex,
          albums: {albumId: albumImages.length}, // Only this album
          totalAlbumImages: albumImages.length, // Only this album's count
          uniqueAlbumCount: 1, // Only one album
          isAlbumView: true,
          albumId: albumId, // Specific album ID
        ),
      ),
    );
  }

  void _showMeetingDetail(Map<String, dynamic> meeting, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Meeting Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Date', meeting['date']?.toString() ?? 'N/A'),
                    _buildDetailRow('Days Ago', meeting['daysAgo']?.toString() ?? 'N/A'),
                    _buildDetailRow('Album ID', meeting['albumId']?.toString() ?? 'N/A'),
                    _buildDetailRow('Total Images', meeting['totalImages']?.toString() ?? '0'),
                    if (meeting['imageUrl']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Meeting Image:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            meeting['imageUrl']?.toString() ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
