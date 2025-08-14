import 'package:flutter/material.dart';
import '../action/storage_service.dart';
import 'profile_edit_screen.dart';
import 'user_sidebar.dart';
import '../action/action.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  // Text controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Log display state for profile screen
  List<String> _profileLogs = [];
  bool _showProfileLogs = true;

  // Helper method to add logs to screen display
  void _addProfileLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    final logMessage = '[$timestamp] $message';
    print(logMessage); // Console log
    setState(() {
      _profileLogs.add(logMessage);
      // Keep only last 15 logs to prevent memory issues
      if (_profileLogs.length > 15) {
        _profileLogs.removeAt(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _addProfileLog('🔄 _loadUserData() - Starting to load user data...');
    try {
      // Only fetch fresh data from API
      _addProfileLog('📡 Calling ActionService.getCurrentUser()...');
      final apiResult = await ActionService.getCurrentUser();

      if (apiResult['success'] == true) {
        final freshUserData = apiResult['data'];
        _addProfileLog('✅ API call successful');
        _addProfileLog('📋 Profile photo from API: ${freshUserData?['profilePhoto']}');

        // Update cached data in StorageService (for other parts of app)
        await StorageService.saveUserData(freshUserData);
        _addProfileLog('💾 User data saved to storage');

        setState(() {
          _userData = freshUserData;
          _isLoading = false;
        });
        _addProfileLog('✅ Profile screen updated with fresh data');

        // Set initial values for form fields from fresh data
        _fullNameController.text =
            freshUserData?['fullName'] ?? freshUserData?['name'] ?? '';
        _emailController.text = freshUserData?['email'] ?? '';

        // Handle phone number mapping
        final dynamic phoneField =
            freshUserData?['phoneNumber'] ?? freshUserData?['phone'];
        String phoneText = '';
        if (phoneField is Map) {
          final cc = (phoneField['countryCode'] ?? '').toString();
          final num = (phoneField['number'] ?? '').toString();
          phoneText = '$cc $num';
        } else if (phoneField is String) {
          phoneText = phoneField;
        }
        _phoneController.text = phoneText;

        _designationController.text = freshUserData?['designation'] ?? '';
        _companyController.text = freshUserData?['company'] ?? '';

        // Handle location mapping
        final dynamic fullAddress = freshUserData?['full_address'];
        String locationText = '';
        if (fullAddress is Map) {
          locationText = (fullAddress['street'] ?? '').toString();
        }
        if (locationText.isEmpty) {
          locationText = (freshUserData?['location'] ?? '').toString();
        }
        _locationController.text = locationText;
      } else {
        _addProfileLog('❌ API call failed: ${apiResult['message']}');
        // API failed - show error and empty state
        setState(() {
          _userData = null;
          _isLoading = false;
        });

        // Clear form fields
        _fullNameController.text = '';
        _emailController.text = '';
        _phoneController.text = '';
        _designationController.text = '';
        _companyController.text = '';
        _locationController.text = '';

        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${apiResult['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      _addProfileLog('❌ Network error: $error');
      // Network error - show error and empty state
      setState(() {
        _userData = null;
        _isLoading = false;
      });

      // Clear form fields
      _fullNameController.text = '';
      _emailController.text = '';
      _phoneController.text = '';
      _designationController.text = '';
      _companyController.text = '';
      _locationController.text = '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Failed to load profile data'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadUserData();
                  },
          ),
        ],
      ),
      drawer: const UserSidebar(),
      body: Container(
        color: Colors.grey.shade50,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              )
            : _userData == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load profile data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        _loadUserData();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadUserData();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // User Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.deepPurple.withOpacity(0.3),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _userData?['profilePhoto'] != null
                                    ? Image.network(
                                        _userData!['profilePhoto'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.deepPurple
                                                    .withOpacity(0.1),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.deepPurple,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.deepPurple.withOpacity(
                                          0.1,
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 20),

                            // User Name and Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userData?['fullName'] ??
                                        _userData?['name'] ??
                                        '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userData?['designation'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _userData?['company'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Personal Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Your basic account information.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Full Name Field
                            _buildFormField(
                              label: 'Full Name',
                              controller: _fullNameController,
                            ),
                            const SizedBox(height: 16),

                            // Email Address Field
                            _buildFormField(
                              label: 'Email Address',
                              controller: _emailController,
                            ),
                            const SizedBox(height: 16),

                            // Phone Number Field
                            _buildFormField(
                              label: 'Phone Number',
                              controller: _phoneController,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Professional Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(
                                    Icons.work_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Professional Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Your professional background.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Designation Field
                            _buildFormField(
                              label: 'Designation',
                              controller: _designationController,
                            ),
                            const SizedBox(height: 16),

                            // Company/Organization Field
                            _buildFormField(
                              label: 'Company/Organization',
                              controller: _companyController,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Location Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Your current location.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Location Field
                            _buildFormField(
                              label: 'Location',
                              controller: _locationController,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Additional Roles Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(
                                    Icons.shield_outlined,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Additional Roles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Your roles and responsibilities.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Role Tags - Dynamic based on user data
                            _buildDynamicRoleTags(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Teacher Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Icon(
                                    Icons.school_outlined,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Teacher Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Your Art of Living teacher status',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Question
                            Row(
                              children: [
                                Text(
                                  'Are you an Art Of Living teacher?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Teacher Verification Box
                            _buildTeacherVerificationBox(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Edit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Show edit form
                            _showEditForm(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: false, // Make read-only
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white, // Keep white background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87, // Keep black text color
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicRoleTags() {
    // Get user roles from various possible fields
    final dynamic rolesDynamic = _userData != null
        ? (_userData!['selectedRoles'] ??
              _userData!['roles'] ??
              _userData!['userTags'])
        : null;

    List<String> userRoles = [];
    if (rolesDynamic is List) {
      userRoles = rolesDynamic.map((e) => e.toString()).toList();
    }

    if (userRoles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'No additional roles assigned',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: userRoles.map((role) => _buildRoleTag(role)).toList(),
    );
  }

  Widget _buildRoleTag(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightGreen.shade300, width: 1),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildTeacherDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherVerificationBox() {
    // Check if user is an AOL teacher
    final aolTeacherData = _userData?['aol_teacher'];
    final atolValidationData = aolTeacherData?['atolValidationData'];
    
    // Check if teacher verification is successful
    final bool isTeacherVerified = atolValidationData?['success'] == true;
    
    if (!isTeacherVerified) {
      // Show "Not an AOL Teacher" message
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not an AOL Teacher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'No teacher verification found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    
    // Get teacher details from API response
    final teacherDetails = atolValidationData?['data']?['teacherdetails'];
    final teacherCode = aolTeacherData?['aolTeacher']?['teacherCode'] ?? 'N/A';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.lightGreen.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification Header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher Verified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'AOL Teacher',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Teacher Details
          _buildTeacherDetail('Name', teacherDetails?['name'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildTeacherDetail('Teacher Code', teacherCode),
          const SizedBox(height: 8),
          _buildTeacherDetail(
            'Type',
            teacherDetails?['teacher_type'] ?? 'N/A',
          ),
          const SizedBox(height: 8),
          _buildTeacherDetail(
            'Programs',
            teacherDetails?['program_types_can_teach'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) async {
    _addProfileLog('✏️ _showEditForm() - Opening edit form...');
    // Show loading while fetching fresh user data
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Fetching profile...'),
            ],
          ),
        );
      },
    );

    Map<String, dynamic>? freshUserData;
    try {
      _addProfileLog('📡 Fetching fresh user data for edit...');
      final apiResult = await ActionService.getCurrentUser();
      if (apiResult['success'] == true) {
        freshUserData = apiResult['data'];
        _addProfileLog('✅ Fresh data fetched successfully');
        _addProfileLog('📋 Current profile photo: ${freshUserData?['profilePhoto']}');
      } else {
        _addProfileLog('❌ Failed to fetch fresh data: ${apiResult['message']}');
        // API failed - show error and don't proceed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiResult['message'] ?? 'Failed to fetch latest profile data.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(); // Close loading dialog
        return; // Don't proceed to edit screen
      }
    } catch (e) {
      _addProfileLog('❌ Error fetching fresh data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(); // Close loading dialog
      return; // Don't proceed to edit screen
    } finally {
      // Close the loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userData: freshUserData),
      ),
    );

    if (result != null) {
      _addProfileLog('📤 Edit form returned with result: $result');
      _addProfileLog('📋 Profile photo from result: ${result['profilePhoto']}');
      
      // Refresh user data from API to get the most up-to-date information
      try {
        _addProfileLog('🔄 Refreshing user data from API after edit...');
        _addProfileLog('📡 Calling ActionService.getCurrentUser()...');
        final apiResult = await ActionService.getCurrentUser();
        
        _addProfileLog('📥 API Response Status: ${apiResult['statusCode']}');
        _addProfileLog('📥 API Response Success: ${apiResult['success']}');
        _addProfileLog('📥 API Response Message: ${apiResult['message']}');
        
        if (apiResult['success'] == true) {
          _addProfileLog('✅ API refresh successful');
          _addProfileLog('📋 Full API Response Data: ${apiResult['data']}');
          _addProfileLog('📋 Profile photo from API: ${apiResult['data']?['profilePhoto']}');
          _addProfileLog('📋 Expected profile photo: ${result['profilePhoto']}');
          
          // Check if API returned the updated photo
          final apiPhoto = apiResult['data']?['profilePhoto'];
          final expectedPhoto = result['profilePhoto'];
          
          if (apiPhoto == expectedPhoto) {
            _addProfileLog('✅ Database has updated profile photo!');
          } else {
            _addProfileLog('❌ Database still has old profile photo!');
            _addProfileLog('🔍 API Photo: $apiPhoto');
            _addProfileLog('🔍 Expected: $expectedPhoto');
            _addProfileLog('⚠️ Backend database update issue detected!');
          }
          
          // If API returned old photo but we have updated photo, preserve the updated one
          if (apiResult['data']?['profilePhoto'] != result['profilePhoto'] && result['profilePhoto'] != null) {
            _addProfileLog('🛡️ Preserving updated profile photo from edit form');
            final preservedData = <String, dynamic>{...apiResult['data'] as Map<String, dynamic>, 'profilePhoto': result['profilePhoto']};
            setState(() {
              _userData = preservedData;
            });
            _addProfileLog('✅ Profile screen updated with preserved photo');
          } else {
            setState(() {
              _userData = apiResult['data'] as Map<String, dynamic>?;
            });
            _addProfileLog('✅ Profile screen updated with new data');
          }
          
          // Update form controllers with fresh data
          _fullNameController.text = _userData?['fullName'] ?? _userData?['name'] ?? '';
          _emailController.text = _userData?['email'] ?? '';
          
          // Handle phone number mapping
          final dynamic phoneField = _userData?['phoneNumber'] ?? _userData?['phone'];
          String phoneText = '';
          if (phoneField is Map) {
            final cc = (phoneField['countryCode'] ?? '').toString();
            final num = (phoneField['number'] ?? '').toString();
            phoneText = '$cc $num';
          } else if (phoneField is String) {
            phoneText = phoneField;
          }
          _phoneController.text = phoneText;
          
          _designationController.text = _userData?['designation'] ?? '';
          _companyController.text = _userData?['company'] ?? '';
          
          // Handle location mapping
          final dynamic fullAddress = _userData?['full_address'];
          String locationText = '';
          if (fullAddress is Map) {
            locationText = (fullAddress['street'] ?? '').toString();
          }
          if (locationText.isEmpty) {
            locationText = (_userData?['location'] ?? '').toString();
          }
          _locationController.text = locationText;
        } else {
          _addProfileLog('❌ API refresh failed: ${apiResult['message']}');
        }
      } catch (error) {
        _addProfileLog('❌ Error refreshing from API: $error');
        _addProfileLog('🔄 Falling back to returned data...');
        // Fallback to using returned data if API refresh fails
        setState(() {
          _userData = <String, dynamic>{...?_userData, ...result as Map<String, dynamic>};
        });
        _addProfileLog('✅ Profile screen updated with fallback data');
        
        _fullNameController.text = result['fullName'] ?? _fullNameController.text;
        _emailController.text = result['email'] ?? _emailController.text;
        _phoneController.text = result['phoneNumber'] ?? _phoneController.text;
        _designationController.text = result['designation'] ?? _designationController.text;
        _companyController.text = result['company'] ?? _companyController.text;
        _locationController.text = result['location'] ?? _locationController.text;
      }
    } else {
      _addProfileLog('⚠️ Edit form returned null (no changes made)');
    }
  }
}