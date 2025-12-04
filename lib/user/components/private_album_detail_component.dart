import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../components/common/loading_dialog.dart';
import '../../action/action.dart';

class PrivateAlbumDetailComponent extends StatefulWidget {
  final Map<String, dynamic> album;

  const PrivateAlbumDetailComponent({
    super.key,
    required this.album,
  });

  @override
  State<PrivateAlbumDetailComponent> createState() => _PrivateAlbumDetailComponentState();
}

class _PrivateAlbumDetailComponentState extends State<PrivateAlbumDetailComponent> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _allImages = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalImages = 0;
  final int _limit = 20;
  Set<int> _selectedIndices = {};
  Map<String, dynamic>? _albumDetails; // Store full album details from API

  @override
  void initState() {
    super.initState();
    _loadAlbumImages();
  }

  Future<void> _loadAlbumImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get album_id from the widget.album
      final albumId = widget.album['album_id'] as String?;
      
      if (albumId == null || albumId.isEmpty) {
        // Fallback to old method if no album_id
        _loadImagesFromPassedData();
        return;
      }

      print('📸 Loading album details for: $albumId, page: $_currentPage');

      // Call the API to get paginated album details
      final result = await ActionService.getAlbumDetails(
        albumId: albumId,
        page: _currentPage,
        limit: _limit,
      );

      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>? ?? {};
          final albumImages = data['album_images'] as List<dynamic>? ?? [];
          
          List<Map<String, dynamic>> allImagesList = [];
          
          for (var image in albumImages) {
            if (image is Map<String, dynamic>) {
              allImagesList.add({
                'compressed': image['compressed'] ?? image['original'],
                'original': image['original'] ?? image['compressed'],
                'index': image['index'] ?? 0,
                'key': image['key'], // year or category tag
              });
            }
          }

          setState(() {
            _albumDetails = data; // Store full album details
            _allImages = allImagesList;
            _totalImages = data['totalImages'] as int? ?? allImagesList.length;
            _totalPages = data['totalPages'] as int? ?? 1;
            _currentPage = data['currentPage'] as int? ?? _currentPage;
            _isLoading = false;
          });
        } else {
          // API failed, fallback to passed data
          print('⚠️ API failed, using passed data: ${result['message']}');
          _loadImagesFromPassedData();
        }
      }
    } catch (error) {
      print('❌ Error loading album images: $error');
      if (mounted) {
        // Fallback to passed data on error
        _loadImagesFromPassedData();
      }
    }
  }

  void _loadImagesFromPassedData() {
    // Fallback: Load from passed album data (old method)
    final albumImagesList = widget.album['album_images'] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> allImagesList = [];
    
    for (var image in albumImagesList) {
      if (image is Map<String, dynamic>) {
        allImagesList.add({
          'compressed': image['compressed'] ?? image['original'],
          'original': image['original'] ?? image['compressed'],
          'index': image['index'] ?? 0,
        });
      }
    }

    setState(() {
      _allImages = allImagesList;
      _totalImages = widget.album['totalImages'] as int? ?? allImagesList.length;
      _totalPages = (_totalImages / _limit).ceil();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getCurrentPageImages() {
    // Since we're loading paginated data from API, just return all loaded images
    return _allImages;
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadAlbumImages(); // Reload images for new page
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadAlbumImages(); // Reload images for new page
    }
  }

  Future<void> _downloadSelected() async {
    if (_selectedIndices.isEmpty) return;
    
    try {
      // Show loading dialog
      if (mounted) {
        LoadingDialog.show(context, message: 'Your images are preparing to download...');
      }

      // Get selected photos
      final selectedPhotos = <Map<String, dynamic>>[];
      for (final index in _selectedIndices) {
        if (index < _allImages.length) {
          selectedPhotos.add(_allImages[index]);
        }
      }

      // Download images to temporary directory
      final tempDir = await getTemporaryDirectory();
      final List<XFile> downloadedFiles = [];
      
      for (int i = 0; i < selectedPhotos.length; i++) {
        try {
          final photo = selectedPhotos[i];
          final imageUrl = photo['original'] ?? photo['compressed'] ?? '';
          if (imageUrl.isEmpty) continue;
          
          final response = await http.get(Uri.parse(imageUrl));
          
          if (response.statusCode == 200) {
            final fileName = 'album_photo_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        subject: 'Private Album Photos - ${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${downloadedFiles.length} image${downloadedFiles.length > 1 ? 's' : ''} ready to save!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
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

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final displayMinute = minute.toString().padLeft(2, '0');
      return '$displayHour:$displayMinute $period';
    } catch (e) {
      return '';
    }
  }


  Future<void> _openImageInBrowser(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    
    try {
      final Uri uri = Uri.parse(imageUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open image in browser'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildImageCard(Map<String, dynamic> image, int globalIndex) {
    final imageUrl = image['compressed'] ?? image['original'] ?? '';
    final originalImageUrl = image['original'] ?? image['compressed'] ?? '';
    final isSelected = _selectedIndices.contains(globalIndex);
    final pageImages = _getCurrentPageImages();
    final localIndex = pageImages.indexOf(image);
    final imageNumber = ((_currentPage - 1) * _limit) + localIndex + 1;
    
    final albumName = widget.album['album_name'] ?? 'Untitled Album';
    final venue = widget.album['album_venue'] ?? '';
    final eventDate = widget.album['event_date'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4CC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select checkbox
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _toggleSelection(globalIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleSelection(globalIndex),
                          activeColor: const Color(0xFFF97316),
                          checkColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text(
                          'Select',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Image
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // View button overlay
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _openImageInBrowser(originalImageUrl);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Image info
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$albumName $imageNumber',
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Date: ${_formatDate(eventDate?.toString())}',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Venue: ${venue.toString().toLowerCase()}',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    // Use album details from API if available, otherwise use passed data
    final album = _albumDetails ?? widget.album;
    final albumName = album['album_name'] ?? 'Untitled Album';
    final venue = album['album_venue'] ?? '';
    final venueSlot = album['venue_slot'] ?? '';
    final eventDate = album['event_date'];
    final eventTime = album['event_time'] ?? '';
    final eventPlace = album['event_place'] ?? '';
    
    // Use _totalImages from state (set by API or fallback)
    final totalImages = _totalImages;

    return Container(
      color: Colors.grey.shade50,
      child: Stack(
        children: [
          Column(
            children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Mobile Header
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 640) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lock, size: 16, color: Colors.red.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Private Album',
                                          style: TextStyle(fontSize: 12, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      albumName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$totalImages photos • ${_formatDate(eventDate?.toString())}',
                                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_selectedIndices.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: _downloadSelected,
                                            icon: const Icon(Icons.download, size: 16),
                                            label: Text('Download (${_selectedIndices.length})'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF16A34A),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              minimumSize: const Size(0, 28),
                                              textStyle: const TextStyle(fontSize: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
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
                        ],
                      );
                    } else {
                      // Desktop Header
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.lock, size: 16, color: Colors.red.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Private Album',
                                      style: TextStyle(fontSize: 14, color: Colors.red.shade600, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  albumName,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '$totalImages photos • ${_formatDate(eventDate?.toString())}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_selectedIndices.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: _downloadSelected,
                                        icon: const Icon(Icons.download, size: 16),
                                        label: Text('Download (${_selectedIndices.length})'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          minimumSize: const Size(0, 28),
                                          textStyle: const TextStyle(fontSize: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Info Section
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width >= 640 ? 24 : 16,
              vertical: MediaQuery.of(context).size.width >= 640 ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First line: Venue, Date
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      venue.isNotEmpty 
                          ? venue.toString().split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ')
                          : 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(eventDate?.toString()),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Second line: Slot, Time, Location
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      venueSlot.isNotEmpty 
                          ? venueSlot.toString().split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ')
                          : 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(eventDate?.toString()).isNotEmpty 
                          ? _formatTime(eventDate?.toString())
                          : (eventTime.isNotEmpty ? eventTime : 'N/A'),
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    if (eventPlace.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        eventPlace.toString().split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' '),
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Images Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No images found',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          physics: const ClampingScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 1280 ? 5
                                : MediaQuery.of(context).size.width > 1024 ? 4
                                : MediaQuery.of(context).size.width > 640 ? 3
                                : 1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _getCurrentPageImages().length,
                          itemBuilder: (context, index) {
                            final pageImages = _getCurrentPageImages();
                            final image = pageImages[index];
                            final globalIndex = ((_currentPage - 1) * _limit) + index;
                            return _buildImageCard(image, globalIndex);
                          },
                        ),
                      ),
          ),
            ],
          ),
          // Floating Pagination Footer
          if (_totalPages > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Page $_currentPage of $_totalPages • $_totalImages total photos',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 16, color: Colors.grey.shade300),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: _currentPage < _totalPages ? _goToNextPage : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Next'),
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

}

