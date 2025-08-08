import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../action/action.dart';
import 'user_sidebar.dart';

class DarshanPhotosScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const DarshanPhotosScreen({
    Key? key,
    required this.appointmentId,
    required this.appointmentData,
  }) : super(key: key);

  @override
  State<DarshanPhotosScreen> createState() => _DarshanPhotosScreenState();
}

class _DarshanPhotosScreenState extends State<DarshanPhotosScreen> {
  String? selectedPerson;
  List<Map<String, dynamic>> allDarshanPhotos = []; // Store all photos
  List<Map<String, dynamic>> displayedPhotos = []; // Display paginated photos
  bool isLoading = false;
  bool isLoadingMore = false;
  Map<String, dynamic>? apiData;
  bool hasError = false;
  String errorMessage = '';
  
  // Pagination variables
  int currentPage = 1;
  int itemsPerPage = 8; // Reduced for better performance
  bool hasMoreData = true;
  
  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDarshanPhotos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePhotos();
    }
  }

  void _loadDarshanPhotos() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      currentPage = 1;
      allDarshanPhotos.clear();
      displayedPhotos.clear();
    });

    try {
      final result = await ActionService.getFaceMatchResultByAppointmentId(
        widget.appointmentId,
      );

      if (result['success'] == true) {
        final data = result['data'];
        final processedPhotos = _processApiData(data);
        
        setState(() {
          apiData = data;
          allDarshanPhotos = processedPhotos;
          displayedPhotos = _getPaginatedPhotos(processedPhotos, 1);
          isLoading = false;
          hasMoreData = processedPhotos.length > itemsPerPage;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = result['message'] ?? 'Failed to load darshan photos';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Network error. Please check your connection and try again.';
      });
    }
  }

  void _loadMorePhotos() async {
    if (isLoadingMore || !hasMoreData) return;
    
    setState(() {
      isLoadingMore = true;
    });

    // Simulate loading delay to prevent rapid calls
    await Future.delayed(const Duration(milliseconds: 300));
    
    final nextPage = currentPage + 1;
    final newPhotos = _getPaginatedPhotos(allDarshanPhotos, nextPage);
    
    if (newPhotos.isNotEmpty) {
      setState(() {
        displayedPhotos.addAll(newPhotos);
        currentPage = nextPage;
        hasMoreData = displayedPhotos.length < allDarshanPhotos.length;
        isLoadingMore = false;
      });
    } else {
      setState(() {
        hasMoreData = false;
        isLoadingMore = false;
      });
    }
  }

  List<Map<String, dynamic>> _getPaginatedPhotos(List<Map<String, dynamic>> allPhotos, int page) {
    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    
    if (startIndex >= allPhotos.length) return [];
    
    return allPhotos.sublist(
      startIndex, 
      endIndex > allPhotos.length ? allPhotos.length : endIndex
    );
  }

  List<Map<String, dynamic>> _processApiData(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> photos = [];
    final Set<String> addedUsers = {}; // Track users to avoid duplicates
    
    // Check for new API structure (users array directly)
    final users = data['users'] as List<dynamic>?;
    
    if (users != null) {
      for (final user in users) {
        final fullName = user['fullName'] ?? 'Unknown';
        final userType = user['userType'] ?? 'accompany';
        final apiResult = user['apiResult'];
        
        // Only add one image per user
        if (apiResult != null && !addedUsers.contains(fullName)) {
          final List<Map<String, dynamic>> matchedImages = _extractMatchedImages(apiResult);
          
          if (matchedImages.isNotEmpty) {
            // Take only the first (most recent) image for each user
            final matchedImage = matchedImages.first;
            photos.add({
              'id': '${matchedImage['image_name']}_${fullName}',
              'imageUrl': matchedImage['image_name'],
              'personName': fullName,
              'date': matchedImage['image_date'] ?? 'Unknown',
              'userType': userType,
              'createdAt': user['createdAt'],
              'score': matchedImage['score'],
              'albumId': matchedImage['album_id'],
              'daysAgo': matchedImage['days_ago'],
              'totalMatches': matchedImages.length, // Show total matches count
            });
            addedUsers.add(fullName);
          }
        }
      }
    } else {
      // Fallback to old structure (faceMatchResults)
      final faceMatchResults = data['faceMatchResults'] as List<dynamic>?;
      
      if (faceMatchResults != null) {
        for (final result in faceMatchResults) {
          final fullName = result['fullName'] ?? 'Unknown';
          final userType = result['userType'] ?? 'accompany';
          final apiResult = result['apiResult'];
          
          // Only add one image per user
          if (apiResult != null && !addedUsers.contains(fullName)) {
            final List<Map<String, dynamic>> matchedImages = _extractMatchedImages(apiResult);
            
            if (matchedImages.isNotEmpty) {
              // Take only the first (most recent) image for each user
              final matchedImage = matchedImages.first;
              photos.add({
                'id': '${matchedImage['image_name']}_${fullName}',
                'imageUrl': matchedImage['image_name'],
                'personName': fullName,
                'date': matchedImage['image_date'] ?? 'Unknown',
                'userType': userType,
                'createdAt': result['createdAt'],
                'score': matchedImage['score'],
                'albumId': matchedImage['album_id'],
                'daysAgo': matchedImage['days_ago'],
                'totalMatches': matchedImages.length, // Show total matches count
              });
              addedUsers.add(fullName);
            }
          }
        }
      }
    }

    return photos;
  }

  List<Map<String, dynamic>> _extractMatchedImages(Map<String, dynamic> apiResult) {
    final List<Map<String, dynamic>> images = [];
    
    // Extract matches from all time periods
    final timePeriods = ['30_days', '60_days', '90_days'];
    
    for (final period in timePeriods) {
      final periodData = apiResult[period];
      
      if (periodData != null && periodData['matches'] != null) {
        final matches = periodData['matches'] as List<dynamic>;
        
        for (final match in matches) {
          // Format the date from "2025-JUN-08" to "08/06/2025"
          String formattedDate = 'Unknown';
          if (match['image_date'] != null) {
            try {
              final date = DateTime.parse(match['image_date']);
              formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            } catch (e) {
              formattedDate = match['image_date'] ?? 'Unknown';
            }
          }
          
          images.add({
            'image_name': match['image_name'],
            'score': match['score'],
            'album_id': match['album_id'],
            'date': match['date'],
            'image_date': formattedDate,
            'days_ago': match['days_ago'],
          });
        }
      }
    }
    
    return images;
  }

  List<Map<String, dynamic>> _getReferencePhotos() {
    final List<Map<String, dynamic>> referencePhotos = [];
    final Set<String> addedNames = {};
    
    if (apiData != null) {
      final users = apiData!['users'] as List<dynamic>?;
      if (users != null) {
        for (final user in users) {
          final fullName = user['fullName'] ?? 'Unknown';
          final userType = user['userType'] ?? 'accompany';
          
          if (!addedNames.contains(fullName)) {
            addedNames.add(fullName);
            
            String photoUrl = user['profilePhotoUrl']?.toString() ?? '';
            if (photoUrl.isEmpty) {
              photoUrl = widget.appointmentData['profilePhoto']?.toString() ?? '';
            }
            
            referencePhotos.add({
              'name': fullName,
              'photoUrl': photoUrl,
              'type': userType,
              'isSelected': selectedPerson == fullName,
            });
          }
        }
      } else {
        final faceMatchResults = apiData!['faceMatchResults'] as List<dynamic>?;
        if (faceMatchResults != null) {
          for (final result in faceMatchResults) {
            final fullName = result['fullName'] ?? 'Unknown';
            final userType = result['userType'] ?? 'accompany';
            final profilePhotoUrl = result['profilePhotoUrl'];
            
            if (!addedNames.contains(fullName)) {
              addedNames.add(fullName);
              
              String photoUrl = profilePhotoUrl?.toString() ?? '';
              if (photoUrl.isEmpty) {
                photoUrl = widget.appointmentData['profilePhoto']?.toString() ?? '';
              }
              
              referencePhotos.add({
                'name': fullName,
                'photoUrl': photoUrl,
                'type': userType,
                'isSelected': selectedPerson == fullName,
              });
            }
          }
        }
      }
    }

    return referencePhotos;
  }

  List<Map<String, dynamic>> _getFilteredDarshanPhotos() {
    if (selectedPerson == null) {
      return displayedPhotos;
    }
    return displayedPhotos.where((photo) => photo['personName'] == selectedPerson).toList();
  }

  void _onPersonSelected(String? personName) {
    setState(() {
      selectedPerson = selectedPerson == personName ? null : personName;
    });
  }

  void _viewImage(Map<String, dynamic> photo) {
    final imageUrl = photo['imageUrl'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      launchUrl(Uri.parse(imageUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final referencePhotos = _getReferencePhotos();
    final filteredPhotos = _getFilteredDarshanPhotos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Darshan Photos with Gurudev'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const UserSidebar(),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDarshanPhotos();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Darshan Photos with Gurudev',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'View and manage your darshan photos with Gurudev',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Reference Photos Section
              if (apiData != null && referencePhotos.isNotEmpty) ...[
                const Text(
                  'Your Reference Photos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: referencePhotos.map((person) {
                    final isSelected = person['isSelected'] == true;
                    final isMain = person['type'] == 'main';
                    
                    return GestureDetector(
                      onTap: () => _onPersonSelected(person['name']),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 4,
                                ),
                              ] : null,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.orange : Colors.orange.shade400,
                                      width: isSelected ? 4 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _buildOptimizedImage(
                                      imageUrl: person['photoUrl'],
                                      placeholder: Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.person, size: 48),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -8,
                                    left: -8,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            person['name'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            isMain ? 'Main Appointee' : 'Accompany',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMain ? Colors.orange.shade600 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // Matched Darshan Photos Section
              const Text(
                'Matched Darshan Photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDarshanPhotos,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (filteredPhotos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No darshan photos found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...filteredPhotos.map((photo) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildDarshanPhotoCard(photo),
                    )),
                    
                    // Load more indicator
                    if (isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    
                    // End of list indicator
                    if (!hasMoreData && filteredPhotos.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No more photos to load',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized image widget with error handling and memory management
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
      // Add loading placeholder
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      // Add error handling
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.image, size: 48),
        );
      },
      // Add memory optimization
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

  Widget _buildDarshanPhotoCard(Map<String, dynamic> photo) {
    return Container(
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
      child: Column(
        children: [
          Container(
            height: 300,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildOptimizedImage(
                    imageUrl: photo['imageUrl'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      onTap: () => _viewImage(photo),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () => _viewImage(photo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Image',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo['personName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${photo['date']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (photo['totalMatches'] != null && photo['totalMatches'] > 1)
                        Text(
                          '${photo['totalMatches']} total matches found',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
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
} 