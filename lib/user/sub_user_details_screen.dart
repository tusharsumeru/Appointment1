import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../action/action.dart';
import '../components/common/loading_dialog.dart';

class SubUserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final bool isMainUser;

  const SubUserDetailsScreen({
    Key? key,
    required this.userData,
    required this.isMainUser,
  }) : super(key: key);

  @override
  State<SubUserDetailsScreen> createState() => _SubUserDetailsScreenState();
}

class _SubUserDetailsScreenState extends State<SubUserDetailsScreen> {
  bool isDownloading = false;
  List<Map<String, dynamic>> faceMatchResults = [];
  bool isLoadingFaceMatch = false;
  bool hasFaceMatchError = false;
  String faceMatchErrorMessage = '';
  Map<String, dynamic>? paginationInfo;
  int currentPage = 1;
  int itemsPerPage = 10;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  
  // Selection state
  Set<String> selectedImageIds = {};
  bool isSelectAll = false;
  


  Future<void> _downloadImage(String imageUrl) async {
    if (isDownloading) return;

    setState(() {
      isDownloading = true;
    });

    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to download images'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get the app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'divine_picture_${widget.userData['userId']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Save to gallery (platform specific)
        if (Platform.isAndroid || Platform.isIOS) {
          // For mobile platforms, we'll use the share functionality
          await _shareImage(filePath);
        } else {
          // For other platforms, just show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image saved to: $filePath'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to download image');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareImage(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Use platform channel to share the image
        const platform = MethodChannel('image_sharing');
        await platform.invokeMethod('shareImage', {'filePath': filePath});
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image shared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openImageInBrowser(String imageUrl) async {
    try {
      final Uri url = Uri.parse(imageUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening image: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildOptimizedImage({
    required String imageUrl,
    Widget? placeholder,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.isEmpty) {
      return placeholder ?? Container(
        color: Colors.grey.shade300,
        child: const Icon(
          Icons.person,
          size: 100,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Icon(
            Icons.person,
            size: 100,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFaceMatchResults();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadFaceMatchResults() async {
    if (isLoadingFaceMatch) return;
    
    setState(() {
      isLoadingFaceMatch = true;
      hasFaceMatchError = false;
      faceMatchErrorMessage = '';
      currentPage = 1;
      faceMatchResults.clear();
    });

    try {
      final subUserId = widget.userData['userId'];
      if (subUserId == null || subUserId.toString().isEmpty) {
        setState(() {
          isLoadingFaceMatch = false;
          hasFaceMatchError = true;
          faceMatchErrorMessage = 'No sub-user ID available for face match results';
        });
        return;
      }

      final result = await ActionService.getSubUserFaceMatchResultBySubUserId(
        subUserId,
        page: currentPage,
        limit: itemsPerPage,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final pagination = result['pagination'];
        
        setState(() {
          faceMatchResults = _extractFaceMatchImages(data);
          paginationInfo = pagination;
          isLoadingFaceMatch = false;
          hasMoreData = pagination != null ? pagination['page'] < pagination['totalPages'] : false;
        });
      } else {
        setState(() {
          isLoadingFaceMatch = false;
          hasFaceMatchError = true;
          faceMatchErrorMessage = result['message'] ?? 'Failed to load face match results';
        });
      }
    } catch (error) {
      setState(() {
        isLoadingFaceMatch = false;
        hasFaceMatchError = true;
        faceMatchErrorMessage = 'Network error. Please check your connection and try again.';
      });
    }
  }

  void _loadPage(int page) async {
    if (isLoadingFaceMatch) return;
    
    setState(() {
      isLoadingFaceMatch = true;
      currentPage = page;
    });

    try {
      final subUserId = widget.userData['userId'];
      
      final result = await ActionService.getSubUserFaceMatchResultBySubUserId(
        subUserId,
        page: page,
        limit: itemsPerPage,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final pagination = result['pagination'];
        
        setState(() {
          faceMatchResults = _extractFaceMatchImages(data);
          paginationInfo = pagination;
          isLoadingFaceMatch = false;
          // Clear selection when changing pages
          selectedImageIds.clear();
          isSelectAll = false;
        });
      } else {
        setState(() {
          isLoadingFaceMatch = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoadingFaceMatch = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractFaceMatchImages(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> images = [];
    
    try {
      final apiResult = data['apiResult'];
      if (apiResult != null && apiResult['matches'] != null) {
        final matches = apiResult['matches'] as List<dynamic>;
        
        for (int i = 0; i < matches.length; i++) {
          final match = matches[i];
          images.add({
            'id': 'match_$i',
            'imageUrl': match['image_name'] ?? '',
            'date': match['image_date'] ?? 'Unknown',
            'score': match['score'] ?? 0.0,
            'albumId': match['album_id'] ?? '',
            'daysAgo': match['days_ago'] ?? 0,
          });
        }
      }
    } catch (error) {
      print('Error extracting face match images: $error');
    }

    return images;
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      isSelectAll = value ?? false;
      if (isSelectAll) {
        // Select all images
        selectedImageIds = Set.from(faceMatchResults.map((image) => image['id']));
      } else {
        // Deselect all images
        selectedImageIds.clear();
      }
    });
  }

  void _toggleImageSelection(String imageId, bool? value) {
    setState(() {
      if (value ?? false) {
        selectedImageIds.add(imageId);
      } else {
        selectedImageIds.remove(imageId);
      }
      
      // Update select all state
      isSelectAll = selectedImageIds.length == faceMatchResults.length;
    });
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }



  Future<void> _downloadSelectedAsZip() async {
    if (selectedImageIds.isEmpty) return;

    // Get selected images
    final selectedImages = faceMatchResults
        .where((image) => selectedImageIds.contains(image['id']))
        .toList();

    // Extract image URLs
    final imageUrls = selectedImages
        .map((image) => image['imageUrl'] as String)
        .where((url) => url.isNotEmpty)
        .toList();

    if (imageUrls.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid image URLs to download'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      LoadingDialog.show(context, message: 'Downloading images...');
    }

    try {
      // Download images to temporary directory
      final tempDir = await getTemporaryDirectory();
      final List<XFile> downloadedFiles = [];
      
      for (int i = 0; i < imageUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(imageUrls[i]));
          if (response.statusCode == 200) {
            final fileName = 'divine_picture_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(XFile(file.path));
          }
        } catch (e) {
          print('Error downloading image $i: $e');
        }
      }

      if (downloadedFiles.isEmpty) {
        if (context.mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images could be downloaded'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Hide loading dialog
      if (context.mounted) {
        LoadingDialog.hide(context);
      }

      // Use share_plus to share/download images
      await Share.shareXFiles(
        downloadedFiles,
        text: 'Divine Pictures - ${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''}',
        subject: 'Divine Pictures from ${widget.userData['fullName']}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''} ready to save!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clean up temporary files after a delay to allow sharing
      Future.delayed(const Duration(seconds: 5), () async {
        for (final xFile in downloadedFiles) {
          try {
            final file = File(xFile.path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error deleting temp file: $e');
          }
        }
      });

    } catch (error) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading images: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _shareSelectedImages() async {
    if (selectedImageIds.isEmpty) return;

    try {
      // Show loading indicator
      if (context.mounted) {
        LoadingDialog.show(context, message: 'Your image is preparing to share...');
      }

      // Get selected images
      final selectedImages = faceMatchResults
          .where((image) => selectedImageIds.contains(image['id']))
          .toList();

      // Extract image URLs
      final imageUrls = selectedImages
          .map((image) => image['imageUrl'] as String)
          .where((url) => url.isNotEmpty)
          .toList();

      if (imageUrls.isEmpty) {
        if (context.mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No valid image URLs to share'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Download images to temporary files
      final List<XFile> imageFiles = [];
      
      for (int i = 0; i < imageUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(imageUrls[i]));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final fileName = 'divine_picture_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            imageFiles.add(XFile(file.path));
          }
        } catch (e) {
          print('Error downloading image $i: $e');
        }
      }

      if (imageFiles.isEmpty) {
        if (context.mounted) {
          LoadingDialog.hide(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No images could be downloaded'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Use share_plus to share images directly
      await Share.shareXFiles(
        imageFiles,
        text: 'Your pics detected by DivinePicAI by Sumeru Digital',
        subject: 'Divine Pictures - ${imageFiles.length} image${imageFiles.length > 1 ? 's' : ''}',
      );

      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared ${imageFiles.length} image${imageFiles.length > 1 ? 's' : ''} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clean up temporary files
      for (final xFile in imageFiles) {
        try {
          final file = File(xFile.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting temp file: $e');
        }
      }

    } catch (error) {
      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing images: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userColor = widget.isMainUser ? const Color(0xFFF97316) : Colors.blue;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.userData['fullName']}\'s Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Face Match Results Section (for all users)
            ...[
              if (isLoadingFaceMatch && faceMatchResults.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (hasFaceMatchError)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        faceMatchErrorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFaceMatchResults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: userColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (faceMatchResults.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      // Icon
                      Icon(
                        widget.isMainUser 
                            ? Icons.account_circle_outlined
                            : Icons.image_not_supported_outlined,
                        size: 96,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        widget.isMainUser 
                            ? 'No Divine Pictures Available'
                            : 'No Divine Pictures Found',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          widget.isMainUser
                              ? 'No divine pictures have been uploaded yet for this account. Divine pictures are automatically generated from darshan photos.'
                              : 'We couldn\'t find any divine pictures for this user in the last 90 days.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bullet points (only for sub-users)
                      if (!widget.isMainUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              _buildBulletPoint('Pictures are searched from the last 90 days'),
                              const SizedBox(height: 4),
                              _buildBulletPoint('Make sure the user has attended darshan recently'),
                              const SizedBox(height: 4),
                              _buildBulletPoint('Try selecting a different user from above'),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isMainUser ? const Color(0xFFF97316) : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.isMainUser ? 'Go Back' : 'View All Users',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    // Header with count and select all
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First row: Divine Pictures and total count
                          Row(
                            children: [
                              const Text(
                                'Divine Pictures',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${paginationInfo?['total'] ?? faceMatchResults.length} total, showing ${faceMatchResults.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Second row: Select All checkbox and selected count
                          Row(
                            children: [
                              // Select All checkbox
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isSelectAll,
                                    onChanged: _toggleSelectAll,
                                    activeColor: widget.isMainUser ? const Color(0xFFF97316) : Colors.blue,
                                  ),
                                  const Text(
                                    'Select All',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const Spacer(),
                              
                              // Selected count (only show when items are selected)
                              if (selectedImageIds.isNotEmpty)
                                Text(
                                  '${selectedImageIds.length} selected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isMainUser ? const Color(0xFFF97316) : Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Third row: Download and Share buttons (only show when items are selected)
                          if (selectedImageIds.isNotEmpty)
                            Row(
                              children: [
                                // Download button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _downloadSelectedAsZip,
                                    icon: const Icon(Icons.download, size: 16),
                                    label: Text('Download (${selectedImageIds.length})'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 8),
                                
                                // Share button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _shareSelectedImages,
                                    icon: const Icon(Icons.share, size: 16),
                                    label: Text('Share (${selectedImageIds.length})'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.isMainUser ? const Color(0xFFF97316) : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    

                    
                    // Face Match Results List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faceMatchResults.length,
                      itemBuilder: (context, index) {
                        // Reduce bottom padding for the last item
                        final isLastItem = index == faceMatchResults.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLastItem ? 4 : 16),
                          child: _buildFaceMatchImageCard(faceMatchResults[index]),
                        );
                      },
                    ),

                    // Loading Indicator
                    if (isLoadingFaceMatch && faceMatchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Pagination Component
                    if (paginationInfo != null && paginationInfo!['totalPages'] > 1)
                      Container(
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
                                onPressed: currentPage > 1 ? () => _loadPage(currentPage - 1) : null,
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
                                color: widget.isMainUser 
                                    ? const Color(0xFFF97316).withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.isMainUser 
                                      ? const Color(0xFFF97316).withOpacity(0.3)
                                      : Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${paginationInfo!['page']} / ${paginationInfo!['totalPages']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isMainUser ? const Color(0xFFF97316) : Colors.blue,
                                ),
                              ),
                            ),
                            
                            // Next button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: currentPage < paginationInfo!['totalPages'] ? [
                                  BoxShadow(
                                    color: (widget.isMainUser ? const Color(0xFFF97316) : Colors.blue).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 0,
                                  ),
                                ] : null,
                              ),
                              child: ElevatedButton(
                                onPressed: currentPage < paginationInfo!['totalPages'] ? () => _loadPage(currentPage + 1) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: currentPage < paginationInfo!['totalPages'] 
                                      ? (widget.isMainUser ? const Color(0xFFF97316) : Colors.blue)
                                      : Colors.grey.shade100,
                                  foregroundColor: currentPage < paginationInfo!['totalPages'] 
                                      ? Colors.white 
                                      : Colors.grey.shade400,
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
                                        color: currentPage < paginationInfo!['totalPages'] 
                                            ? Colors.white 
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: currentPage < paginationInfo!['totalPages'] 
                                          ? Colors.white 
                                          : Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildFaceMatchImageCard(Map<String, dynamic> imageData) {
    final userColor = widget.isMainUser ? const Color(0xFFF97316) : Colors.blue;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: userColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select checkbox at top right
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: selectedImageIds.contains(imageData['id']),
                        onChanged: (value) => _toggleImageSelection(imageData['id'], value),
                        activeColor: userColor,
                      ),
                      const Text(
                        'Select',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
            ),
          ),
          
          // Image with buttons overlay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                // Image
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildOptimizedImage(
                      imageUrl: imageData['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
                
                
              ],
            ),
          ),
          
          // Image Details at bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Divine Picture #${faceMatchResults.indexOf(imageData) + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Face Match Score: ${(imageData['score'] * 100).toStringAsFixed(1)}%',
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
    );
  }
}
