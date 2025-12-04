import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../components/common/loading_dialog.dart';
import 'user_history_screen.dart';
import 'darshan_pictures_screen.dart';
import '../action/action.dart';

// Helper widget for info items
class _InfoItem extends StatelessWidget {
  final String text;
  
  const _InfoItem({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 8, right: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E40AF),
            ),
          ),
        ),
      ],
    );
  }
}

class DarshanPhotosResultsScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic>? albumData;
  final List<Map<String, dynamic>>? userPictures;
  final Map<String, dynamic>? divineApiResponse;

  const DarshanPhotosResultsScreen({
    super.key,
    required this.appointmentId,
    this.albumData,
    this.userPictures,
    this.divineApiResponse,
  });

  @override
  State<DarshanPhotosResultsScreen> createState() => _DarshanPhotosResultsScreenState();
}

class _DarshanPhotosResultsScreenState extends State<DarshanPhotosResultsScreen> {
  Map<String, dynamic>? _albumData;
  List<Map<String, dynamic>> _userPictures = [];
  String? _selectedUserId;
  List<Map<String, dynamic>> _filteredPhotos = [];
  List<bool> _selectedPhotos = [];
  int _currentPage = 1;
  int _photosPerPage = 20;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    
    // Always use pre-fetched data from component
    _processApiData({
      'success': true,
      'data': {
        'album': widget.albumData,
        'userPictures': widget.userPictures,
        'divineApiResponse': widget.divineApiResponse,
      }
    });
  }

  void _processApiData(Map<String, dynamic> data) {
    // Handle the actual API response format
    if (data['success'] == true && data['data'] != null) {
      final responseData = data['data'];
      
      setState(() {
        // Extract album data from the response
        _albumData = responseData['album'];
        
        // Extract user pictures from the response
        _userPictures = List<Map<String, dynamic>>.from(responseData['userPictures'] ?? []);
        
        // Get the divineApiResponse data
        final divineApiResponse = responseData['divineApiResponse'] as Map<String, dynamic>?;
        
        if (divineApiResponse != null) {
          final apiresult = divineApiResponse['apiresult'] as Map<String, dynamic>?;
          
          if (apiresult != null) {
            final imageResults = apiresult['image_results'] as List<dynamic>?;
            
            // Update each user with their corresponding image results
            for (int i = 0; i < _userPictures.length && i < (imageResults?.length ?? 0); i++) {
              final user = _userPictures[i];
              final imageResult = imageResults![i];
              
              // Update the user's apiResults with the actual image results
              user['apiResults'] = {
                'summary': {
                  'total_matches': imageResult['total_matches'] ?? 0,
                  'unique_dates': imageResult['summary']?['unique_dates'] ?? 0,
                  'unique_albums': imageResult['summary']?['unique_albums'] ?? 0,
                },
                'image_results': [imageResult],
              };
            }
          }
        }
        
        // Don't auto-select any user - show all photos by default
        // This prevents the "No Photos Found" screen from showing initially
        _selectedUserId = null;
        _filteredPhotos = _getAllPhotos();
        _selectedPhotos = List.filled(_filteredPhotos.length, false);
      });
    }
  }


  void _filterPhotosForUser(String userId) {
    if (_albumData == null) return;
    
    // Find the user in userPictures to get their top_matches
    final userIndex = _userPictures.indexWhere((user) => user['_id'] == userId);
    
    List<dynamic> userPhotos = [];
    
    if (userIndex != -1) {
      final user = _userPictures[userIndex];
      final apiResults = user['apiResults'] as Map<String, dynamic>?;
      final imageResults = apiResults?['image_results'] as List<dynamic>?;
      
      if (imageResults != null && imageResults.isNotEmpty) {
        // Get the first image result (user_2_image.jpg has the matches)
        final firstImageResult = imageResults.first;
        final topMatches = firstImageResult['top_matches'] as List<dynamic>? ?? [];
        
        userPhotos = topMatches;
      }
    }
    
    setState(() {
      _filteredPhotos = userPhotos.map((photo) => {
        'compressed': photo['image_name'],
        'original': photo['image_name'],
        'userId': userId,
        'score': photo['score'],
        'date': photo['date'],
        'days_ago': photo['days_ago'],
        'album_id': photo['album_id'],
      }).toList();
      
      _selectedPhotos = List.filled(_filteredPhotos.length, false);
      _currentPage = 1;
      _selectAll = false;
    });
  }

  void _selectUser(String userId) {
    setState(() {
      _selectedUserId = userId;
    });
    _filterPhotosForUser(userId);
  }

  void _togglePhotoSelection(int index) {
    setState(() {
      _selectedPhotos[index] = !_selectedPhotos[index];
      _selectAll = _selectedPhotos.every((selected) => selected);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      _selectedPhotos = List.filled(_filteredPhotos.length, _selectAll);
    });
  }

  void _nextPage() {
    final totalPages = (_filteredPhotos.length / _photosPerPage).ceil();
    if (_currentPage < totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  List<Map<String, dynamic>> _getCurrentPagePhotos() {
    final startIndex = (_currentPage - 1) * _photosPerPage;
    final endIndex = (startIndex + _photosPerPage).clamp(0, _filteredPhotos.length);
    return _filteredPhotos.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredPhotos.length / _photosPerPage).ceil();

  List<Map<String, dynamic>> _getAllPhotos() {
    List<Map<String, dynamic>> allPhotos = [];
    
    // Get photos from all users' top_matches
    for (var user in _userPictures) {
      final apiResults = user['apiResults'] as Map<String, dynamic>?;
      final imageResults = apiResults?['image_results'] as List<dynamic>?;
      
      if (imageResults != null && imageResults.isNotEmpty) {
        final firstImageResult = imageResults.first;
        final topMatches = firstImageResult['top_matches'] as List<dynamic>? ?? [];
        
        for (var photo in topMatches) {
          allPhotos.add({
            'compressed': photo['image_name'],
            'original': photo['image_name'],
            'userId': user['_id'],
            'score': photo['score'],
            'date': photo['date'],
            'days_ago': photo['days_ago'],
            'album_id': photo['album_id'],
          });
        }
      }
    }
    
    return allPhotos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Appointment ID: ${widget.appointmentId}'),
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildContent(),
    );
  }


  Widget _buildContent() {
    // Check if we have any photos at all
    final hasPhotos = _userPictures.isNotEmpty && _userPictures.any((user) => _getUserPhotoCount(user['_id']) > 0);
    
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // Only show album info and user selection if we have photos
          if (hasPhotos) ...[
            // Album Info Section
            _buildAlbumInfoSection(),
            
            // User Selection Section
            _buildUserSelectionSection(),
          ],
          
          // Photos Section (this will show "No Photos Found" if empty)
          _buildPhotosSection(),
          
          // Pagination (only show if we have photos)
          if (hasPhotos) _buildPaginationSection(),
        ],
      ),
    );
  }


  Widget _buildAlbumInfoSection() {
    if (_albumData == null) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment ID
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.symmetric(vertical: 8),
          //   child: Text(
          //     'Appointment ID: ${widget.appointmentId}',
          //     style: const TextStyle(
          //       fontSize: 16,
          //       color: Color(0xFF111827),
          //       fontWeight: FontWeight.w600,
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          //           const SizedBox(height: 12),
          
          // Album name and photo count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _albumData!['album_name'] ?? 'Darshan Photos',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF111827),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          
          // Photo count and date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${_filteredPhotos.length} photos • ${_getDateFromFirstPhoto()}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          
          // Compact grid layout with icons
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4,
            children: [
              // Venue
              _buildInfoItem(
                icon: Icons.location_on,
                label: _albumData!['album_venue'] ?? 'N/A',
              ),
              // Date
              _buildInfoItem(
                icon: Icons.calendar_today,
                label: _getDateFromFirstPhoto(),
              ),
              // Time
              _buildInfoItem(
                icon: Icons.access_time,
                label: _albumData!['venue_slot'] ?? 'N/A',
              ),
              // Location
              _buildInfoItem(
                icon: Icons.location_on,
                label: _albumData!['event_place'] ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUserSelectionSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        color: Color(0xFF111827),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select User to View',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Show all photos
                      setState(() {
                        _selectedUserId = null;
                        _filteredPhotos = _getAllPhotos();
                        _selectedPhotos = List.filled(_filteredPhotos.length, false);
                        _currentPage = 1;
                        _selectAll = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 16,
                            color: Color(0xFF111827),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // User cards in a horizontal scrollable row
          SizedBox(
            height: 120,
            child: _userPictures.isEmpty 
              ? const Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _userPictures.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _userPictures.length - 1 ? 16 : 0,
                      ),
                      child: _buildUserCard(_userPictures[index]),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  int _getUserPhotoCount(String userId) {
    final userIndex = _userPictures.indexWhere((user) => user['_id'] == userId);
    
    if (userIndex != -1) {
      final user = _userPictures[userIndex];
      final apiResults = user['apiResults'] as Map<String, dynamic>?;
      final imageResults = apiResults?['image_results'] as List<dynamic>?;
      
      if (imageResults != null && imageResults.isNotEmpty) {
        final firstImageResult = imageResults.first;
        final topMatches = firstImageResult['top_matches'] as List<dynamic>? ?? [];
        return topMatches.length;
      }
    }
    
    return 0;
  }

  int get _selectedCount => _selectedPhotos.where((selected) => selected).length;

  Future<void> _downloadSelected() async {
    if (_selectedCount == 0) return;
    
    try {
      // Show loading dialog
      if (mounted) {
        LoadingDialog.show(context, message: 'Your images are preparing to download...');
      }

      // Get selected photos
      final selectedPhotos = <Map<String, dynamic>>[];
      for (int i = 0; i < _selectedPhotos.length; i++) {
        if (_selectedPhotos[i]) {
          selectedPhotos.add(_filteredPhotos[i]);
        }
      }

      // Download images to temporary directory
      final tempDir = await getTemporaryDirectory();
      final List<XFile> downloadedFiles = [];
      
      for (int i = 0; i < selectedPhotos.length; i++) {
        try {
          final photo = selectedPhotos[i];
          final imageUrl = photo['compressed'] ?? photo['original'];
          final response = await http.get(Uri.parse(imageUrl));
          
          if (response.statusCode == 200) {
            final fileName = 'darshan_photo_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(XFile(file.path));
          }
        } catch (e) {
          print('Error downloading image $i: $e');
        }
      }

      if (downloadedFiles.isEmpty) {
        if (mounted) {
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
      if (mounted) {
        LoadingDialog.hide(context);
      }

      // Use share_plus to share/download images
      await Share.shareXFiles(
        downloadedFiles,
        text: 'Your pics detected by DivinePicAI by Sumeru Digital',
        subject: 'Darshan Photos - ${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''} ready to save!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clean up temporary files after a delay
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
      if (mounted) {
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

  Future<void> _shareSelected() async {
    if (_selectedCount == 0) return;
    
    try {
      // Show loading dialog
      if (mounted) {
        LoadingDialog.show(context, message: 'Your images are preparing to share...');
      }

      // Get selected photos
      final selectedPhotos = <Map<String, dynamic>>[];
      for (int i = 0; i < _selectedPhotos.length; i++) {
        if (_selectedPhotos[i]) {
          selectedPhotos.add(_filteredPhotos[i]);
        }
      }

      // Download images to temporary files
      final tempDir = await getTemporaryDirectory();
      final List<XFile> imageFiles = [];
      
      for (int i = 0; i < selectedPhotos.length; i++) {
        try {
          final photo = selectedPhotos[i];
          final imageUrl = photo['compressed'] ?? photo['original'];
          final response = await http.get(Uri.parse(imageUrl));
          
          if (response.statusCode == 200) {
            final fileName = 'darshan_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            final file = File('${tempDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            imageFiles.add(XFile(file.path));
          }
        } catch (e) {
          print('Error downloading image $i: $e');
        }
      }

      if (imageFiles.isEmpty) {
        if (mounted) {
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

      // Use share_plus to share images
      await Share.shareXFiles(
        imageFiles,
        text: 'Your pics detected by DivinePicAI by Sumeru Digital',
        subject: 'Darshan Photos - ${imageFiles.length} image${imageFiles.length > 1 ? 's' : ''}',
      );

      if (mounted) {
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
      if (mounted) {
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userInfo = user['userInfo'] as Map<String, dynamic>;
    final userId = user['_id'] as String;
    final isSelected = _selectedUserId == userId;
    
    // Get the actual photo count for this user
    final actualPhotoCount = _getUserPhotoCount(userId);
    
    return GestureDetector(
      onTap: () => _selectUser(userId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isSelected ? (Matrix4.identity()..scale(1.05)) : Matrix4.identity(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile image with border
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                  width: isSelected ? 4 : 4,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: ClipOval(
                child: user['images'] != null && 
                    (user['images'] as List).isNotEmpty
                    ? Image.network(
                        (user['images'] as List)[0]['imageUrl'],
                        fit: BoxFit.cover,
                        width: 64,
                        height: 64,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.person,
                              size: 32,
                              color: Color(0xFF9CA3AF),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            
            // User name
            SizedBox(
              width: 80,
              child: Text(
                userInfo['fullName'] ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            
            // Photo count
            Text(
              actualPhotoCount > 0 ? '$actualPhotoCount photos' : '0 photos',
              style: TextStyle(
                fontSize: 11,
                color: actualPhotoCount > 0 ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPhotosFoundScreen() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 60,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'No Photos Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              const Text(
                'Scheduled confirmation not found',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF1E40AF),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'What to do next:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _InfoItem(
                      text: 'Your photos may not be uploaded yet. Please try again after some time.',
                    ),
                    const SizedBox(height: 6),
                    const _InfoItem(
                      text: 'Photos are typically available within 24-48 hours after your darshan appointment.',
                    ),
                    const SizedBox(height: 6),
                    const _InfoItem(
                      text: 'Double-check your appointment ID from your booking confirmation email.',
                    ),
                    const SizedBox(height: 6),
                    const _InfoItem(
                      text: 'If you attended a recent appointment, photos may take longer to process.',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Column(
                children: [
                  // Try Different Appointment ID Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DarshanPicturesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Try Different Appointment ID'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Secondary Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Show loading indicator
                            if (mounted) {
                              LoadingDialog.show(context, message: 'Refreshing data...');
                            }
                            
                            try {
                              // Call the API again to refresh data
                              final result = await ActionService.getAppointmentByIdWithDarshanPhotos(widget.appointmentId);
                              
                              // Close loading dialog
                              if (mounted) {
                                LoadingDialog.hide(context);
                              }
                              
                              if (result['success'] == true && result['data'] != null) {
                                final data = result['data'];
                                final divineApiResponse = data['divineApiResponse'] as Map<String, dynamic>?;
                                final userPictures = divineApiResponse?['userPictures'] as List<dynamic>? ?? [];
                                
                                // Update the screen with new data
                                setState(() {
                                  _albumData = data['album'];
                                  _userPictures = List<Map<String, dynamic>>.from(userPictures);
                                });
                              } else {
                                // Still no photos, show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'No photos found for this appointment ID.'),
                                    backgroundColor: const Color(0xFFDC2626),
                                  ),
                                );
                              }
                            } catch (error) {
                              // Close loading dialog
                              if (mounted) {
                                LoadingDialog.hide(context);
                              }
                              
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to refresh data. Please check your internet connection.'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserHistoryScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('My Appointments'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                            side: const BorderSide(color: const Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
              
              const SizedBox(height: 16),
              
              // Help Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'If you\'re still having trouble finding your photos, please contact support with your appointment ID:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFFCD34D),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.appointmentId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF92400E),
                        ),
                      ),
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

  Widget _buildPhotosSection() {
    if (_filteredPhotos.isEmpty) {
      return _buildNoPhotosFoundScreen();
    }

    final currentPagePhotos = _getCurrentPagePhotos();
    
    // Handle both single user selection and "View All" mode
    String userName = 'All Users';
    if (_selectedUserId != null) {
      final selectedUser = _userPictures.firstWhere(
        (user) => user['_id'] == _selectedUserId,
        orElse: () => _userPictures.isNotEmpty ? _userPictures.first : {},
      );
      if (selectedUser.isNotEmpty) {
        final userInfo = selectedUser['userInfo'] as Map<String, dynamic>?;
        userName = userInfo?['fullName'] ?? 'User';
      }
    }

    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          // Photos Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          "$userName's Photos (${_filteredPhotos.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFED7AA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_filteredPhotos.length} total',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEA580C),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${currentPagePhotos.length} showing',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            if (_selectedCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_selectedCount selected',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    ),
                    SizedBox(
                      width: 120,
                      child: CheckboxListTile(
                        value: _selectAll,
                        onChanged: (value) => _toggleSelectAll(),
                        title: const Text(
                          'Select All',
                          style: TextStyle(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                if (_selectedCount > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadSelected,
                          icon: const Icon(Icons.download, size: 16),
                          label: Text('Download ($_selectedCount)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareSelected,
                          icon: const Icon(Icons.share, size: 16),
                          label: Text('Share ($_selectedCount)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
                  // Photos Grid
                  GridView.builder(
                    physics: const ClampingScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: currentPagePhotos.length,
                    itemBuilder: (context, index) {
                      final globalIndex = (_currentPage - 1) * _photosPerPage + index;
                      return _buildPhotoCard(currentPagePhotos[index], globalIndex);
                    },
                  ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo, int index) {
    final isSelected = index < _selectedPhotos.length ? _selectedPhotos[index] : false;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFED7AA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Controls Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                // Selection checkbox
                GestureDetector(
                  onTap: () => _togglePhotoSelection(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? const Color(0xFFEA580C) : Colors.grey.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Select',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Photo
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(photo['compressed'] ?? photo['original']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Photo info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Stack(
              children: [
                  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_albumData?['album_name'] ?? 'Photo'} ${index + 1}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Album: ${photo['album_id'] ?? _albumData?['album_id'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date: ${photo['date'] ?? _extractDateFromImageUrl(photo)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                
                // View and Share buttons in bottom right of info section
                Positioned(
                  bottom: 4,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _viewPhoto(photo, index),
                              child: const Text(
                                'View',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.share, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _sharePhoto(photo),
                              child: const Text(
                                'Share',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationSection() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_currentPage of $_totalPages • ${_filteredPhotos.length} total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _currentPage > 1 ? _previousPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPage > 1 ? Colors.white : const Color(0xFFF3F4F6),
                  foregroundColor: _currentPage > 1 ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                  side: BorderSide(
                    color: _currentPage > 1 ? const Color(0xFFFED7AA) : const Color(0xFFE5E7EB),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPage < _totalPages 
                      ? const Color(0xFFEA580C) 
                      : const Color(0xFFF3F4F6),
                  foregroundColor: _currentPage < _totalPages 
                      ? Colors.white 
                      : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewPhoto(Map<String, dynamic> photo, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: _filteredPhotos,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _sharePhoto(Map<String, dynamic> photo) async {
    try {
      await Share.share(
        'Check out my darshan photo from the divine appointment!',
        subject: 'Darshan Photo',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: ${e.toString()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }


  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _extractDateFromImageUrl(Map<String, dynamic> photo) {
    try {
      // First try to get date from photo data
      if (photo['date'] != null) {
        final dateString = photo['date'] as String;
        final date = DateTime.parse(dateString);
        const months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
      
      // Fallback to album date if no date found in photo
      return _formatDate(_albumData?['event_date']);
    } catch (e) {
      return _formatDate(_albumData?['event_date']);
    }
  }

  String _getDateFromFirstPhoto() {
    if (_filteredPhotos.isNotEmpty) {
      try {
        final firstPhoto = _filteredPhotos.first;
        
        // First try to get date from photo data
        if (firstPhoto['date'] != null) {
          final dateString = firstPhoto['date'] as String;
          final date = DateTime.parse(dateString);
          const months = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ];
          return '${months[date.month - 1]} ${date.day}, ${date.year}';
        }
      } catch (e) {
        // Fall through to album date
      }
    }
    
    // Fallback to album date
    return _formatDateFull(_albumData?['event_date']);
  }

  String _formatDateFull(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadCurrentPhoto(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareCurrentPhoto(),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Center(
            child: InteractiveViewer(
              child: Image.network(
                photo['original'] ?? photo['compressed'],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _downloadCurrentPhoto() {
    // Implement download logic for current photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading photo...'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  void _shareCurrentPhoto() {
    // Implement share logic for current photo
    Share.share(
      'Check out my darshan photo!',
      subject: 'Darshan Photo',
    );
  }
}
