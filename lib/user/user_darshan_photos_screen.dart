import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../components/common/loading_dialog.dart';

class UserDarshanPhotosScreen extends StatefulWidget {
  final String personName;
  final String profilePhotoUrl;
  final List<Map<String, dynamic>> darshanPhotos;
  final String userType;

  const UserDarshanPhotosScreen({
    Key? key,
    required this.personName,
    required this.profilePhotoUrl,
    required this.darshanPhotos,
    required this.userType,
  }) : super(key: key);

  @override
  State<UserDarshanPhotosScreen> createState() => _UserDarshanPhotosScreenState();
}

class _UserDarshanPhotosScreenState extends State<UserDarshanPhotosScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Pagination variables
  List<Map<String, dynamic>> displayedPhotos = [];
  int currentPage = 1;
  int photosPerPage = 10; // Load 10 photos at a time
  bool isLoadingMore = false;
  bool hasMorePhotos = true;

  @override
  void initState() {
    super.initState();
    _loadInitialPhotos();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  String _formatDateForDisplay(String dateStr) {
    try {
      // Expecting YYYY-MON-DD format
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final month = parts[1];
        final day = parts[2];
        
        const monthNames = {
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
    } catch (_) {}
    return dateStr; // Return original if parsing fails
  }

  String _getDisplayDate(Map<String, dynamic> photo) {
    String date = photo['date']?.toString() ?? '';
    final imageUrl = photo['imageUrl']?.toString() ?? '';
    
    // If date is unknown/empty, try to derive it from image name
    final isUnknown = date.isEmpty || date.toLowerCase() == 'unknown' || date == 'null';
    if (isUnknown && imageUrl.isNotEmpty) {
      final derived = _extractDateFromImageName(imageUrl);
      if (derived != null) {
        return _formatDateForDisplay(derived);
      }
    }
    
    // If we have a valid date, format it for display
    if (date.isNotEmpty && date.toLowerCase() != 'unknown' && date != 'null') {
      return _formatDateForDisplay(date);
    }
    
    return 'Unknown';
  }

  void _loadInitialPhotos() {
    final totalPhotos = widget.darshanPhotos.length;
    final initialPhotos = widget.darshanPhotos.take(photosPerPage).toList();
    
    setState(() {
      displayedPhotos = initialPhotos;
      hasMorePhotos = totalPhotos > photosPerPage;
      currentPage = 1;
    });
  }

  void _loadMorePhotos() async {
    if (isLoadingMore || !hasMorePhotos) return;
    
    setState(() {
      isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newPage = currentPage + 1;
    final startIndex = (newPage - 1) * photosPerPage;
    final endIndex = startIndex + photosPerPage;
    
    if (startIndex < widget.darshanPhotos.length) {
      final newPhotos = widget.darshanPhotos
          .skip(startIndex)
          .take(photosPerPage)
          .toList();
      
      setState(() {
        displayedPhotos = newPhotos; // Replace instead of add
        currentPage = newPage;
        hasMorePhotos = endIndex < widget.darshanPhotos.length;
        isLoadingMore = false;
      });
    } else {
      setState(() {
        hasMorePhotos = false;
        isLoadingMore = false;
      });
    }
  }

  void _loadPreviousPhotos() async {
    if (isLoadingMore || currentPage <= 1) return;
    
    setState(() {
      isLoadingMore = true;
    });

    // Simulate network delay for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newPage = currentPage - 1;
    final startIndex = (newPage - 1) * photosPerPage;
    final endIndex = startIndex + photosPerPage;
    
    final newPhotos = widget.darshanPhotos
        .skip(startIndex)
        .take(photosPerPage)
        .toList();
    
    setState(() {
      displayedPhotos = newPhotos;
      currentPage = newPage;
      hasMorePhotos = endIndex < widget.darshanPhotos.length;
      isLoadingMore = false;
    });
  }

  Future<void> _downloadImage(String imageUrl, int photoNumber) async {
    try {
      // Show consistent loading dialog
      if (context.mounted) {
        LoadingDialog.show(context, message: 'Your image is preparing to download...');
      }

      // Download image to temporary directory
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'darshan_${photoNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          LoadingDialog.hide(context);
        }

        // Use share_plus to let user save/share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Your pics detected by DivinePicAI by Sumeru Digital',
          subject: 'Divine Pictures - 1 image',
        );

        // Cleanup after a short delay
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image ready to save!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to download image');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareImage(String imageUrl, int photoNumber) async {
    try {
      // Show consistent loading dialog
      if (context.mounted) {
        LoadingDialog.show(context, message: 'Your image is preparing to share...');
      }

      // Download image to temporary file for sharing
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = 'darshan_share_${photoNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          LoadingDialog.hide(context);
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Your pics detected by DivinePicAI by Sumeru Digital',
          subject: 'Divine Pictures - 1 image',
        );

        // Cleanup after share
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image shared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to download image for sharing');
      }
    } catch (e) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.personName}\'s Darshan Photos'),
        backgroundColor: const Color(0xFFF97316), // Orange color
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: widget.darshanPhotos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No darshan photos found in the last 90 days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Header with total count
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.orange.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.personName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Text(
                          'Showing ${displayedPhotos.length} of ${widget.darshanPhotos.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Photo List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: displayedPhotos.length + 1, // +1 for the bottom widget
                    itemBuilder: (context, index) {
                      // Show photos
                      if (index < displayedPhotos.length) {
                        final photo = displayedPhotos[index];
                        final actualIndex = widget.darshanPhotos.indexOf(photo) + 1;
                        return _buildPhotoCard(photo, actualIndex);
                      }
                      
                      // Show loading indicator, load more button, or completion message at the end
                      if (index == displayedPhotos.length) {
                        if (isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 8),
                                Text(
                                  'Loading more photos...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (hasMorePhotos) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Previous button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: currentPage > 1 ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: currentPage > 1 ? () => _loadPreviousPhotos() : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentPage > 1 ? Colors.white : Colors.grey.shade100,
                                      foregroundColor: currentPage > 1 ? Colors.black87 : Colors.grey.shade400,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: currentPage > 1 
                                            ? BorderSide(color: Colors.grey.shade200, width: 1)
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_back_ios_rounded,
                                          size: 16,
                                          color: currentPage > 1 ? Colors.black87 : Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Previous',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: currentPage > 1 ? Colors.black87 : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Page info with floating badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${currentPage} / ${(widget.darshanPhotos.length / photosPerPage).ceil()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                                
                                // Next button
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: hasMorePhotos ? [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ] : null,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: hasMorePhotos ? _loadMorePhotos : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasMorePhotos ? Colors.orange : Colors.grey.shade100,
                                      foregroundColor: hasMorePhotos ? Colors.white : Colors.grey.shade400,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Next',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: hasMorePhotos ? Colors.white : Colors.grey.shade400,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: hasMorePhotos ? Colors.white : Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (displayedPhotos.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.only(top: 8, left: 8, right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 24,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'All ${widget.darshanPhotos.length} photos loaded',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo, int photoNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 256, // Fixed height similar to h-64 in Tailwind
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildOptimizedImage(
                  imageUrl: photo['imageUrl'],
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading photo...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Photo details
            Container(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, date and download button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and date column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.personName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: ${_getDisplayDate(photo)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Download and Share buttons
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _downloadImage(photo['imageUrl'], photoNumber),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _shareImage(photo['imageUrl'], photoNumber),
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedImage({
    required String imageUrl,
    Widget? placeholder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Memory optimization - cache images but limit cache size
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 32, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                'Failed to load',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }
}

