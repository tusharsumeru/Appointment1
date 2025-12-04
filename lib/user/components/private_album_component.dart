import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../action/action.dart';
import '../private_album_detail_screen.dart';

class PrivateAlbumComponent extends StatefulWidget {
  const PrivateAlbumComponent({super.key});

  @override
  State<PrivateAlbumComponent> createState() => _PrivateAlbumComponentState();
}

class _PrivateAlbumComponentState extends State<PrivateAlbumComponent> {
  final TextEditingController _accessCodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingAlbums = false;
  List<Map<String, dynamic>> _albums = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalAlbums = 0;
  final int _limit = 10;
  String? _lastSearchQuery;

  @override
  void initState() {
    super.initState();
    _loadPrivateAlbums();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search - reload albums when search changes
    final query = _searchController.text.trim();
    if (query != _lastSearchQuery) {
      _lastSearchQuery = query;
      _currentPage = 1; // Reset to first page on new search
      _loadPrivateAlbums();
    }
  }

  Future<void> _loadPrivateAlbums({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoadingAlbums = true;
    });

    try {
      final searchQuery = _searchController.text.trim().isEmpty 
          ? null 
          : _searchController.text.trim();

      final result = await ActionService.getPrivateAlbums(
        page: _currentPage,
        limit: _limit,
        search: searchQuery,
      );

      if (mounted) {
        setState(() {
          _isLoadingAlbums = false;
        });

        if (result['success'] == true) {
          final albums = List<Map<String, dynamic>>.from(result['data'] ?? []);
          setState(() {
            _albums = albums;
            _totalAlbums = result['totalAlbums'] ?? 0;
            _totalPages = result['totalPages'] ?? 1;
            _currentPage = result['currentPage'] ?? _currentPage;
          });
        } else {
          // If no albums found, that's okay - just show empty state
          setState(() {
            _albums = [];
            _totalAlbums = 0;
            _totalPages = 1;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoadingAlbums = false;
          _albums = [];
          _totalAlbums = 0;
          _totalPages = 1;
        });
      }
    }
  }

  void _loadNextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      _loadPrivateAlbums();
    }
  }

  void _loadPreviousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _loadPrivateAlbums();
    }
  }

  void _showRequestAccessBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        // Local state variables for the modal
        String? localErrorMessage;
        String? localSuccessMessage;
        bool localIsLoading = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Access to Private Album',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter the access code provided to you to unlock a private album.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _accessCodeController.clear();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Access Code Input
                TextField(
                  controller: _accessCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter access code (e.g., 8EOUNA or 58dfadf5-14b6-4641-8b85-db015e76ef18)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    errorText: localErrorMessage,
                    errorMaxLines: 2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                  ],
                  onSubmitted: (_) {
                    _requestAccessInModal(
                      setModalState,
                      (error, success, loading) {
                        setModalState(() {
                          localErrorMessage = error;
                          localSuccessMessage = success;
                          localIsLoading = loading;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Note*: You can only unlock an album if you have the access code.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                // Success Message
                if (localSuccessMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localSuccessMessage!,
                            style: TextStyle(color: Colors.green.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Footer Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _accessCodeController.clear();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: localIsLoading
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                _requestAccessInModal(
                                  setModalState,
                                  (error, success, loading) {
                                    setModalState(() {
                                      localErrorMessage = error;
                                      localSuccessMessage = success;
                                      localIsLoading = loading;
                                    });
                                  },
                                );
                              },
                              icon: const Icon(Icons.lock, size: 18),
                              label: const Text('Request Access'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF97316),
                                foregroundColor: Colors.white,
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
      },
    );
  }

  Future<void> _requestAccessInModal(
    StateSetter setModalState,
    void Function(String?, String?, bool) updateLocalState,
  ) async {
    final accessCode = _accessCodeController.text.trim();

    if (accessCode.isEmpty) {
      setModalState(() {
        updateLocalState('Please enter an access code', null, false);
      });
      return;
    }

    setModalState(() {
      updateLocalState(null, null, true);
    });

    try {
      final result = await ActionService.requestAccessToPrivateAlbum(
        accessCode: accessCode,
      );

      if (mounted) {
        if (result['success'] == true) {
          _accessCodeController.clear();
          
          // Close bottom sheet
          Navigator.of(context).pop();
          
          // Reload albums after successful access
          _loadPrivateAlbums(resetPage: true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'] ?? 'Access granted successfully.')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          setModalState(() {
            updateLocalState(
              result['message'] ?? 'Failed to request access. Please try again.',
              null,
              false,
            );
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result['message'] ?? 'Failed to request access. Please try again.')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setModalState(() {
          updateLocalState('An error occurred. Please try again.', null, false);
        });
      }
    }
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  String _formatDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final day = date.day;
      final month = _getMonthName(date.month);
      final year = date.year;
      
      String timePart = '';
      // Use the time from event_date if available, otherwise use event_time
      if (date.hour != 0 || date.minute != 0) {
        // Format time like "6 November 2025 at 10:30 PM"
        final hour = date.hour;
        final minute = date.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');
        timePart = ' at $displayHour:$displayMinute $period';
      } else if (timeStr != null && timeStr.isNotEmpty && timeStr != 'NA') {
        // If event_time is provided, use it
        timePart = ' at $timeStr';
      }
      
      return '$day $month $year$timePart';
    } catch (e) {
      return dateStr;
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    // Extract data from the JSON structure provided
    final title = album['album_name'] ?? album['title'] ?? album['name'] ?? 'Untitled Album';
    final location = album['album_venue'] ?? album['location'] ?? album['venue'] ?? '';
    final eventDate = album['event_date'] ?? album['date'] ?? album['createdAt'];
    final eventTime = album['event_time'] ?? album['time'] ?? '';
    final albumType = album['album_venue_category'] ?? album['albumType'] ?? album['type'] ?? 'darshanLine';
    final venueSlot = album['venue_slot'] ?? album['timeOfDay'] ?? '';
    
    // album_images is a List, not a Map
    final albumImagesList = album['album_images'] as List<dynamic>? ?? [];
    final totalImages = album['totalImages'] as int? ?? albumImagesList.length;
    
    // Extract first 3 images for preview
    final displayImages = albumImagesList.take(3).map((img) {
      if (img is Map<String, dynamic>) {
        return img['compressed'] as String? ?? img['original'] as String? ?? '';
      }
      return '';
    }).where((url) => url.isNotEmpty).toList();
    
    final imageCount = totalImages;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateAlbumDetailScreen(album: album),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Images Grid with Badges
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: displayImages.isEmpty
                        ? Center(
                            child: Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: List.generate(3, (index) {
                                if (index < displayImages.length) {
                                  final imageUrl = displayImages[index];
                                  return Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(
                                        right: index < 2 ? 6 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: Icon(Icons.image, color: Colors.grey.shade400),
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
                                      ),
                                    ),
                                  );
                                } else {
                                  return Expanded(
                                    child: Container(
                                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  );
                                }
                              }),
                            ),
                          ),
                  ),
                  // Private Badge (top left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.red.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Venue Category Badge (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _capitalizeFirstLetter(albumType.toString()),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Album Info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title.toString(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Date and Image Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDateTime(eventDate?.toString(), eventTime?.toString()),
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(Icons.image, size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              imageCount.toString(),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location and Slot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (location.isNotEmpty)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _capitalizeFirstLetter(location),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (venueSlot.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                _capitalizeFirstLetter(venueSlot.toString()),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Private Albums',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View and manage your private albums',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.blue.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Private Albums: These are private albums that you have been granted access to. Request access using an access code to unlock new albums.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                ),
              ),
            ],
          ),
        ),
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search private albums...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        // Request Access Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRequestAccessBottomSheet,
              icon: const Icon(Icons.lock, size: 18),
              label: const Text('Request Access'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        // Albums Grid
        Expanded(
          child: _isLoadingAlbums
              ? const Center(child: CircularProgressIndicator())
              : _albums.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No private albums found',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Request access using an access code to view private albums',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _albums.length,
                            itemBuilder: (context, index) {
                              return _buildAlbumCard(_albums[index]);
                            },
                          ),
                        ),
                        // Pagination Controls
                        if (_totalPages > 1)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Page $_currentPage of $_totalPages ($_totalAlbums total)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _currentPage > 1 ? _loadPreviousPage : null,
                                      icon: const Icon(Icons.chevron_left),
                                      tooltip: 'Previous page',
                                    ),
                                    Text(
                                      '$_currentPage / $_totalPages',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _currentPage < _totalPages ? _loadNextPage : null,
                                      icon: const Icon(Icons.chevron_right),
                                      tooltip: 'Next page',
                                    ),
                                  ],
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
}
