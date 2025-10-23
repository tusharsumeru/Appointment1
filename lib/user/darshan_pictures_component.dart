import 'package:flutter/material.dart';
import '../action/action.dart';
import 'darshan_photos_results_screen.dart';

class DarshanPicturesComponent extends StatefulWidget {
  const DarshanPicturesComponent({super.key});

  @override
  State<DarshanPicturesComponent> createState() => _DarshanPicturesComponentState();
}

class _DarshanPicturesComponentState extends State<DarshanPicturesComponent> {
  final TextEditingController _appointmentIdController = TextEditingController();
  bool _isSearching = false;
  String _searchError = '';

  @override
  void dispose() {
    _appointmentIdController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    final trimmedId = _appointmentIdController.text.trim();
    
    if (trimmedId.isEmpty) {
      setState(() {
        _searchError = 'Please enter a valid appointment ID';
      });
      return;
    }
    
    // Basic validation for appointment ID format
    if (trimmedId.length < 5) {
      setState(() {
        _searchError = 'Appointment ID seems too short. Please check and try again.';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchError = '';
    });
    
    try {
      // Use the existing API method to fetch darshan photos
      final result = await ActionService.getAppointmentByIdWithDarshanPhotos(trimmedId);
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        // Extract user pictures from divineApiResponse
        final divineApiResponse = data['divineApiResponse'] as Map<String, dynamic>?;
        final userPictures = divineApiResponse?['userPictures'] as List<dynamic>? ?? [];
        
        // Navigate to the darshan photos results page with the fetched data
        // This will show the "No Photos Found" screen if userPictures is empty
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DarshanPhotosResultsScreen(
                appointmentId: trimmedId,
                albumData: data['album'],
                userPictures: List<Map<String, dynamic>>.from(userPictures),
                divineApiResponse: divineApiResponse,
              ),
            ),
          );
        }
      } else {
        // Even if the API call fails, navigate to results screen to show "No Photos Found"
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DarshanPhotosResultsScreen(
                appointmentId: trimmedId,
                albumData: null,
                userPictures: [],
                divineApiResponse: null,
              ),
            ),
          );
        }
      }
    } catch (error) {
      // Even if there's an error, navigate to results screen to show "No Photos Found"
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DarshanPhotosResultsScreen(
              appointmentId: trimmedId,
              albumData: null,
              userPictures: [],
              divineApiResponse: null,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEFF6FF), // Blue-50
            Color(0xFFE0E7FF), // Indigo-100
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 32),
            
            // Search Section
            _buildSearchSection(),
            const SizedBox(height: 32),
            
            // Instructions Section
            _buildInstructionsSection(),
            const SizedBox(height: 32),
            
            // Features Section
            _buildFeaturesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 48,
              color: Color(0xFF2563EB), // Blue-600
            ),
            const SizedBox(width: 12),
            const Text(
              'Darshan Pictures',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827), // Gray-900
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'View and download your divine darshan pictures from your appointment',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280), // Gray-600
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.search,
                  color: Color(0xFF2563EB), // Blue-600
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Find Your Pictures',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Gray-900
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your appointment ID to access your darshan pictures',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // Gray-600
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _appointmentIdController,
                    onSubmitted: (_) => _handleSearch(),
                    decoration: InputDecoration(
                      hintText: 'Enter your appointment ID (e.g., APT-b54250Ud)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)), // Gray-300
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD1D5DB)), // Gray-300
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2563EB)), // Blue-600
                      ),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF9CA3AF), // Gray-400
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSearching ? null : _handleSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Blue-600
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_isSearching ? 'Searching...' : 'Search'),
                ),
              ],
            ),
            if (_searchError.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // Red-50
                  border: Border.all(color: const Color(0xFFFECACA)), // Red-200
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Color(0xFFDC2626), // Red-600
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchError,
                        style: const TextStyle(
                          color: Color(0xFFDC2626), // Red-600
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF16A34A), // Green-600
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Gray-900
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow these simple steps to access your darshan pictures',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280), // Gray-600
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop layout - 2 columns
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildInstructionStep(
                              '1',
                              'Enter Appointment ID',
                              'Input your appointment ID in the search field above. This ID was provided when you booked your darshan appointment.',
                            ),
                            const SizedBox(height: 16),
                            _buildInstructionStep(
                              '2',
                              'View Your Pictures',
                              'Once found, you\'ll see all your darshan pictures in a beautiful gallery format.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildInstructionStep(
                              '3',
                              'Download & Share',
                              'Download individual pictures or the entire collection. Share them with family and friends.',
                            ),
                            const SizedBox(height: 16),
                            _buildInstructionStep(
                              '4',
                              'Enjoy Your Memories',
                              'Keep these precious moments forever. Your darshan pictures are stored securely and accessible anytime.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile layout - single column
                  return Column(
                    children: [
                      _buildInstructionStep(
                        '1',
                        'Enter Appointment ID',
                        'Input your appointment ID in the search field above. This ID was provided when you booked your darshan appointment.',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        '2',
                        'View Your Pictures',
                        'Once found, you\'ll see all your darshan pictures in a beautiful gallery format.',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        '3',
                        'Download & Share',
                        'Download individual pictures or the entire collection. Share them with family and friends.',
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep(
                        '4',
                        'Enjoy Your Memories',
                        'Keep these precious moments forever. Your darshan pictures are stored securely and accessible anytime.',
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Desktop layout - 2 columns
                  return Row(
                    children: [
                      Expanded(
                        child: _buildInfoStep(
                          '⏰',
                          'Photo Availability',
                          'Photos are typically available within 24-48 hours after your darshan appointment. If you don\'t see them yet, please try again later.',
                          const Color(0xFFFED7AA), // Orange-100
                          const Color(0xFFEA580C), // Orange-600
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoStep(
                          '📧',
                          'Need Help?',
                          'If you can\'t find your photos, check your appointment ID from your booking confirmation email or contact support.',
                          const Color(0xFFDCFCE7), // Green-100
                          const Color(0xFF16A34A), // Green-600
                        ),
                      ),
                    ],
                  );
                } else {
                  // Mobile layout - single column
                  return Column(
                    children: [
                      _buildInfoStep(
                        '⏰',
                        'Photo Availability',
                        'Photos are typically available within 24-48 hours after your darshan appointment. If you don\'t see them yet, please try again later.',
                        const Color(0xFFFED7AA), // Orange-100
                        const Color(0xFFEA580C), // Orange-600
                      ),
                      const SizedBox(height: 16),
                      _buildInfoStep(
                        '📧',
                        'Need Help?',
                        'If you can\'t find your photos, check your appointment ID from your booking confirmation email or contact support.',
                        const Color(0xFFDCFCE7), // Green-100
                        const Color(0xFF16A34A), // Green-600
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFDBEAFE), // Blue-100
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF2563EB), // Blue-600
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // Gray-900
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF6B7280), // Gray-600
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoStep(String icon, String title, String description, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Gray-900
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280), // Gray-600
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop layout - 3 columns
          return Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  Icons.download,
                  'Easy Download',
                  'Download individual photos or entire collections with one click',
                  const Color(0xFF2563EB), // Blue-600
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  Icons.share,
                  'Share Instantly',
                  'Share your divine moments with family and friends instantly',
                  const Color(0xFF16A34A), // Green-600
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFeatureCard(
                  Icons.visibility,
                  'High Quality',
                  'View and download high-resolution pictures of your darshan',
                  const Color(0xFF7C3AED), // Purple-600
                ),
              ),
            ],
          );
        } else {
          // Mobile layout - single column
          return Column(
            children: [
              _buildFeatureCard(
                Icons.download,
                'Easy Download',
                'Download individual photos or entire collections with one click',
                const Color(0xFF2563EB), // Blue-600
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.share,
                'Share Instantly',
                'Share your divine moments with family and friends instantly',
                const Color(0xFF16A34A), // Green-600
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                Icons.visibility,
                'High Quality',
                'View and download high-resolution pictures of your darshan',
                const Color(0xFF7C3AED), // Purple-600
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color iconColor) {
    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF111827), // Gray-900
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF6B7280), // Gray-600
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
