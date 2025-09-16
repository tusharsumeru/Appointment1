import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../action/action.dart';
import 'user_sidebar.dart';
import 'user_darshan_photos_screen.dart';

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
    _loadReferencePhotos(); // Only load reference photos initially
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

  void _loadReferencePhotos() async {
    if (isLoading) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });

    try {
      final result = await ActionService.getFaceMatchResultByAppointmentId(
        widget.appointmentId,
      );

      if (result['success'] == true) {
        final data = result['data'];
        
        setState(() {
          apiData = data;
          isLoading = false;
          // Don't load photos initially, just store the API data
          allDarshanPhotos.clear();
          displayedPhotos.clear();
        });
      } else {
        // Check if the error is about face match results not found
        String backendMessage = result['message'] ?? 'Failed to load reference photos';
        String displayMessage = backendMessage;
        
        // Replace backend message with user-friendly message
        if (backendMessage.toLowerCase().contains('face match result not found') ||
            backendMessage.toLowerCase().contains('not found for this appointment')) {
          displayMessage = 'No user data found for this appointment.';
        }
        
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = displayMessage;
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

  void _loadDarshanPhotosForUser(String personName) async {
    if (isLoading || apiData == null) return;
    
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
      currentPage = 1;
      allDarshanPhotos.clear();
      displayedPhotos.clear();
    });

    try {
      // Filter photos for the specific user from already loaded API data
      final processedPhotos = _processApiDataForUser(apiData!, personName);
      
      if (processedPhotos.isNotEmpty) {
        setState(() {
          allDarshanPhotos = processedPhotos;
          displayedPhotos = _getPaginatedPhotos(processedPhotos, 1);
          isLoading = false;
          hasMoreData = processedPhotos.length > itemsPerPage;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'No darshan photos found for $personName in the last 90 days.';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error processing photos for $personName.';
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
        final userType = user['userType'] ?? 'main';
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
          final userType = result['userType'] ?? 'main';
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

  List<Map<String, dynamic>> _processApiDataForUser(Map<String, dynamic> data, String targetPersonName) {
    final List<Map<String, dynamic>> photos = [];
    
    // Check for new API structure (users array directly)
    final users = data['users'] as List<dynamic>?;
    
    if (users != null) {
      for (final user in users) {
        final fullName = user['fullName'] ?? 'Unknown';
        final userType = user['userType'] ?? 'main';
        final apiResult = user['apiResult'];
        
        // Only process photos for the selected user
        if (fullName == targetPersonName && apiResult != null) {
          final List<Map<String, dynamic>> matchedImages = _extractMatchedImages(apiResult);
          
          // Add ALL matched images for this user, not just the first one
          for (int i = 0; i < matchedImages.length; i++) {
            final matchedImage = matchedImages[i];
            photos.add({
              'id': '${matchedImage['image_name']}_${fullName}_$i',
              'imageUrl': matchedImage['image_name'],
              'personName': fullName,
              'date': matchedImage['image_date'] ?? 'Unknown',
              'userType': userType,
              'createdAt': user['createdAt'],
              'score': matchedImage['score'],
              'albumId': matchedImage['album_id'],
              'daysAgo': matchedImage['days_ago'],
              'totalMatches': matchedImages.length,
            });
          }
        }
      }
    } else {
      // Fallback to old structure (faceMatchResults)
      final faceMatchResults = data['faceMatchResults'] as List<dynamic>?;
      
      if (faceMatchResults != null) {
        for (final result in faceMatchResults) {
          final fullName = result['fullName'] ?? 'Unknown';
          final userType = result['userType'] ?? 'main';
          final apiResult = result['apiResult'];
          
          // Only process photos for the selected user
          if (fullName == targetPersonName && apiResult != null) {
            final List<Map<String, dynamic>> matchedImages = _extractMatchedImages(apiResult);
            
            // Add ALL matched images for this user, not just the first one
            for (int i = 0; i < matchedImages.length; i++) {
              final matchedImage = matchedImages[i];
              photos.add({
                'id': '${matchedImage['image_name']}_${fullName}_$i',
                'imageUrl': matchedImage['image_name'],
                'personName': fullName,
                'date': matchedImage['image_date'] ?? 'Unknown',
                'userType': userType,
                'createdAt': result['createdAt'],
                'score': matchedImage['score'],
                'albumId': matchedImage['album_id'],
                'daysAgo': matchedImage['days_ago'],
                'totalMatches': matchedImages.length,
              });
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
          final userType = user['userType'] ?? 'main';
          
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
            final userType = result['userType'] ?? 'main';
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
    if (personName == null || apiData == null) return;
    
    // Navigate to user-specific darshan photos screen
    _navigateToUserPhotosScreen(personName);
  }
  
  void _navigateToUserPhotosScreen(String personName) {
    if (apiData == null) return;
    
    // Find user data
    String profilePhotoUrl = '';
    String userType = 'main';
    
    // Check for new API structure (users array directly)
    final users = apiData!['users'] as List<dynamic>?;
    
    if (users != null) {
      for (final user in users) {
        final fullName = user['fullName'] ?? 'Unknown';
        if (fullName == personName) {
          profilePhotoUrl = user['profilePhotoUrl']?.toString() ?? '';
          userType = user['userType'] ?? 'main';
          break;
        }
      }
    } else {
      // Fallback to old structure
      final faceMatchResults = apiData!['faceMatchResults'] as List<dynamic>?;
      if (faceMatchResults != null) {
        for (final result in faceMatchResults) {
          final fullName = result['fullName'] ?? 'Unknown';
          if (fullName == personName) {
            profilePhotoUrl = result['profilePhotoUrl']?.toString() ?? '';
            userType = result['userType'] ?? 'main';
            break;
          }
        }
      }
    }
    
    // If profile photo is empty, use appointment data fallback
    if (profilePhotoUrl.isEmpty) {
      profilePhotoUrl = widget.appointmentData['profilePhoto']?.toString() ?? '';
    }
    
    // Get all photos for this user
    final userPhotos = _processApiDataForUser(apiData!, personName);
    
    // Navigate to user photos screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDarshanPhotosScreen(
          personName: personName,
          profilePhotoUrl: profilePhotoUrl,
          darshanPhotos: userPhotos,
          userType: userType,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final referencePhotos = _getReferencePhotos();
    final filteredPhotos = _getFilteredDarshanPhotos();

    return Scaffold(
      backgroundColor: Colors.white,
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
          _loadReferencePhotos();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Gradient title: Darshan Photos with Gurudev
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFEA580C), // from-orange-600
                          Color(0xFF9A3412), // to-orange-800
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        'Darshan Photos with Gurudev',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20, // Reduced size to fit in one line
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Discover and view your precious darshan moments with Gurudev',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Powered by line with pulsing dot and link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.3, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF97316),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          onEnd: () {
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF97316),
                            ),
                            children: [
                              const TextSpan(text: 'DivinePicAI Powered By '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () async {
                                    final Uri url = Uri.parse('https://sumerudigital.com/');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  child: Text(
                                    'Sumeru Digital Solutions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Reference Photos Section
              if (apiData != null && referencePhotos.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Reference Photos',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select a profile to view their darshan photos',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.orange.shade400,
                                      width: 2,
                                    ),
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

                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              // // Matched Darshan Photos Section
              // const Text(
              //   'Matched Darshan Photos',
              //   style: TextStyle(
              //     fontSize: 20,
              //     fontWeight: FontWeight.w600,
              //     color: Colors.black87,
              //   ),
              // ),
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

                    ],
                  ),
                )
              else
                const SizedBox.shrink(),

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


} 