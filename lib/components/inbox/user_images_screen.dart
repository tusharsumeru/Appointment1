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
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Combine all matches
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        if (index < allMatches.length) {
          final match = allMatches[index];
          return match['image_name']?.toString() ?? 
                 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
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
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Combine all matches
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        if (index < allMatches.length) {
          final match = allMatches[index];
          final score = match['score']?.toDouble() ?? 0.0;
          // Convert score to percentage (assuming score is 0-1, multiply by 100)
          return (score * 100).clamp(0.0, 100.0);
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
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Return total count of all matches (no profile image)
        return matches30.length + matches60.length + matches90.length;
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
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Combine all matches
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        if (index < allMatches.length) {
          final match = allMatches[index];
          return match['album_id']?.toString() ?? '';
        }
      }
    }
    
    return '';
  }

  // Get image date for a specific image
  String _getImageDate(int index) {
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0];
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Combine all matches
        final allMatches = [...matches30, ...matches60, ...matches90];
        
        if (index < allMatches.length) {
          final match = allMatches[index];
          final date = match['date']?.toString() ?? '';
          if (date.isNotEmpty) {
            return date;
          }
        }
      }
    }
    
    return 'Match ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('${widget.userName}\'s Images'),
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
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                widget.userImageUrl ?? 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 30, color: Colors.grey),
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
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.isAlbumView 
                        ? '${_getActualImageCount()} images in album'
                        : '${_getActualImageCount()} images found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                // Show album information if available
                if (widget.albums != null && widget.albums!.isNotEmpty && !widget.isAlbumView) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.album, size: 16, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.uniqueAlbumCount} albums • ${widget.totalAlbumImages} total images',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                // Show album ID when viewing specific album
                if (widget.isAlbumView && widget.albumId != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.album, size: 16, color: Colors.orange[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Album ID: ${widget.albumId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.userIndex > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.face, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Face match results',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildImagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
                  // Match number and confidence
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getImageDate(index),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_getMatchConfidence(index).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
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