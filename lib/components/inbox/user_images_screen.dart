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

  const UserImagesScreen({
    super.key,
    required this.userName,
    required this.imageCount,
    this.userImageUrl,
    this.faceMatchData = const [],
    this.isLoading = false,
    this.error,
    this.userIndex = 0,
  });

  @override
  State<UserImagesScreen> createState() => _UserImagesScreenState();
}

class _UserImagesScreenState extends State<UserImagesScreen> {
  
  String _getUserImageUrl(int index) {
    // For main user, handle profile image and API matches
    if (widget.userIndex == 0) {
      if (index == 0) {
        // First image is always the profile image
        return widget.userImageUrl ?? 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
      } else {
        // Subsequent images are from API matches
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
            
            // Adjust index to account for profile image
            final matchIndex = index - 1;
            if (matchIndex < allMatches.length) {
              final match = allMatches[matchIndex];
              return match['image_name']?.toString() ?? 
                     'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face';
            }
          }
        }
      }
    }
    
    // For accompanying users, return only face match result images (no profile image)
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

  String _getImageDate(int index) {
    if (widget.userIndex == 0) {
      if (index == 0) {
        return 'Profile Image';
      } else {
        return 'Match ${index}'; // Adjust numbering since index 0 is profile image
      }
    }
    
    // For accompanying users, show "Match X" format
    return 'Match ${index + 1}';
  }

  double _getMatchConfidence(int index) {
    if (widget.userIndex == 0) {
      if (index == 0) {
        return 100.0; // Profile image always has 100% confidence
      } else {
        // For API matches, calculate confidence
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
            
            // Adjust index to account for profile image
            final matchIndex = index - 1;
            if (matchIndex < allMatches.length) {
              final match = allMatches[matchIndex];
              final score = match['score']?.toDouble() ?? 0.0;
              // Convert score to percentage (assuming score is 0-1, multiply by 100)
              return (score * 100).clamp(0.0, 100.0);
            }
          }
        }
        return 0.0;
      }
    }
    
    // For accompanying users, calculate confidence
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
    if (widget.userIndex == 0) {
      // For main user, count profile image + API matches
      int totalCount = 1; // Always include profile image
      
      // Add API matches if available
      if (widget.faceMatchData.isNotEmpty) {
        final result = widget.faceMatchData[0]; // Get first result
        
        if (result['apiResult'] != null) {
          final apiResult = result['apiResult'];
          
          // Get matches from all time periods
          final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
          final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
          final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
          
          // Add total count of all matches
          totalCount += matches30.length + matches60.length + matches90.length;
        }
      }
      
      return totalCount;
    }
    
    // For accompanying users, count matches from API result
    if (widget.faceMatchData.isNotEmpty) {
      final result = widget.faceMatchData[0]; // Get first result
      
      if (result['apiResult'] != null) {
        final apiResult = result['apiResult'];
        
        // Get matches from all time periods
        final matches30 = apiResult['30_days']?['matches'] as List<dynamic>? ?? [];
        final matches60 = apiResult['60_days']?['matches'] as List<dynamic>? ?? [];
        final matches90 = apiResult['90_days']?['matches'] as List<dynamic>? ?? [];
        
        // Return total count of all matches
        return matches30.length + matches60.length + matches90.length;
      }
    }
    
    return 0; // No matches found for this user
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
                      '${_getActualImageCount()} images found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
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
          child: Stack(
            children: [
              // Image only
              InteractiveViewer(
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
              
              // Close button (X) at top right
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
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
} 