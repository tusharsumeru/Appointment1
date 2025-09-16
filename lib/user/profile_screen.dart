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
    try {
      // Only fetch fresh data from API
      final apiResult = await ActionService.getCurrentUser();

      if (apiResult['success'] == true) {
        final freshUserData = apiResult['data'];

        // Update cached data in StorageService (for other parts of app)
        await StorageService.saveUserData(freshUserData);

        setState(() {
          _userData = freshUserData;
          _isLoading = false;
        });

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
          phoneText = '$cc$num'; // Combined format without space
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF97316),
                  ),
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
                        backgroundColor: const Color(0xFFF97316),
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
                  physics: const ClampingScrollPhysics(), // Prevent overscroll/stretching
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
                                  color: const Color(
                                    0xFFF97316,
                                  ).withOpacity(0.3),
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
                                                color: const Color(
                                                  0xFFF97316,
                                                ).withOpacity(0.1),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: const Color(
                                                    0xFFF97316,
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: const Color(
                                          0xFFF97316,
                                        ).withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: const Color(0xFFF97316),
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
                              'Your Art of Living teacher status (non-editable)',
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
                                  'Are you an Art of Living teacher?',
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
                            const SizedBox(height: 16),
                            _buildSupportBox(),
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
                            backgroundColor: const Color(0xFFF97316),
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

  Widget _buildSupportBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If you want to edit this information Please contact support.',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.blue.shade200, height: 1),
          const SizedBox(height: 12),
          Text(
            'Contact Support:',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '📧 Email: support@sumerudigital.com',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📞 Phone: +91-8971227735',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '🕒 Support Hours: 9:00 AM - 6:00 PM (Monday to Friday)',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Reach out to us and we'll help you update your teacher status and information.",
            style: TextStyle(
              color: Colors.blue.shade500,
              fontSize: 11,
            ),
          ),
        ],
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
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
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
    final aolTeacher = aolTeacherData?['aolTeacher'];

    // Determine international teacher status
    final bool isInternationalTeacher = (aolTeacherData?['isInternational'] == true) ||
        (aolTeacherData?['teacher_type']?.toString().toLowerCase().contains('taol') == true);

    // Check if teacher verification is successful (only for non-international)
    final bool isTeacherVerified = !isInternationalTeacher &&
        (atolValidationData?['verified'] == true || aolTeacher?['isTeacher'] == true);

    // Get teacher details (common)
    final rawTeacherdetails = (atolValidationData?['teacherdetails']) ??
        (atolValidationData?['data']?['teacherdetails']);
    final Map<String, dynamic>? teacherDetails =
        rawTeacherdetails is Map<String, dynamic> ? rawTeacherdetails : null;
    final teacherCode = aolTeacher?['teacherCode'] ?? 'N/A';
    final teacherEmail = aolTeacher?['teacherEmail'] ?? 'N/A';
    // For international teachers, show simplified type
    final String teacherType = isInternationalTeacher 
        ? (aolTeacherData?['teacher_type']?.toString().toLowerCase().contains('total') == true 
            ? 'Total Teacher' 
            : 'Teacher')
        : (aolTeacherData?['teacher_type'] ?? 'N/A');
    final teacherPhoneNumber = aolTeacher?['teacherPhoneNumber'];
    final phoneNumber = teacherPhoneNumber != null
        ? '${teacherPhoneNumber['countryCode']} ${teacherPhoneNumber['number']}'
        : 'N/A';
    final coursesTeaching = aolTeacher?['coursesTeaching'] as List<dynamic>?;
    final programsRaw = (coursesTeaching != null && coursesTeaching.isNotEmpty)
        ? coursesTeaching
        : teacherDetails?['program_types_can_teach'];
    final String programs = programsRaw is List
        ? programsRaw.map((e) => e.toString()).join(', ')
        : (programsRaw?.toString() ?? 'N/A');

    // If international teacher: show details but with Not Verified heading
    if (isInternationalTeacher) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (title + subtitle)
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teacher Information Available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Teacher details found but not verified',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details (hide name and phone for international)
            _buildTeacherDetail('Teacher Code', teacherCode),
            const SizedBox(height: 8),
            _buildTeacherDetail('Teacher Email', teacherEmail),
            const SizedBox(height: 8),
            _buildTeacherDetail('Type', teacherType),
            const SizedBox(height: 8),
            _buildTeacherDetail('Programs', programs),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 12),
            Text(
              'Teacher information needs verification. Edit your profile to verify.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!isTeacherVerified) {
      // Show basic not verified message for non-international unverified users
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
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
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teacher not Verified',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Verified (non-international): show verified header and details
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.lightGreen.shade200, width: 1),
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
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TeacherVerified',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    'Teacher',
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

          // Teacher Details (include name/phone for non-international)
          _buildTeacherDetail('Name', teacherDetails?['name'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildTeacherDetail('Type', teacherType),
          const SizedBox(height: 8),
          _buildTeacherDetail('Teacher Code', teacherCode),
          const SizedBox(height: 8),
          _buildTeacherDetail('Teacher Email', teacherEmail),
          const SizedBox(height: 8),
          if (phoneNumber != 'N/A') ...[
            _buildTeacherDetail('Phone Number', phoneNumber),
            const SizedBox(height: 8),
          ],
          _buildTeacherDetail(
            'Programs',
            programs,
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) async {
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
      final apiResult = await ActionService.getCurrentUser();
      if (apiResult['success'] == true) {
        freshUserData = apiResult['data'];
      } else {
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
      // Refresh user data from API to get the most up-to-date information
      try {
        final apiResult = await ActionService.getCurrentUser();

        if (apiResult['success'] == true) {
          // Check if API returned the updated photo
          final apiPhoto = apiResult['data']?['profilePhoto'];
          final expectedPhoto = result['profilePhoto'];

          // If API returned old photo but we have updated photo, preserve the updated one
          if (apiResult['data']?['profilePhoto'] != result['profilePhoto'] &&
              result['profilePhoto'] != null) {
            final preservedData = <String, dynamic>{
              ...apiResult['data'] as Map<String, dynamic>,
              'profilePhoto': result['profilePhoto'],
            };
            setState(() {
              _userData = preservedData;
            });
          } else {
            setState(() {
              _userData = apiResult['data'] as Map<String, dynamic>?;
            });
          }

          // Update form controllers with fresh data
          _fullNameController.text =
              _userData?['fullName'] ?? _userData?['name'] ?? '';
          _emailController.text = _userData?['email'] ?? '';

          // Handle phone number mapping
          final dynamic phoneField =
              _userData?['phoneNumber'] ?? _userData?['phone'];
          String phoneText = '';
          if (phoneField is Map) {
            final cc = (phoneField['countryCode'] ?? '').toString();
            final num = (phoneField['number'] ?? '').toString();
            phoneText = '$cc$num'; // Combined format without space
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
          // API refresh failed - continue with existing logic
        }
      } catch (error) {
        // Fallback to using returned data if API refresh fails
        setState(() {
          _userData = <String, dynamic>{
            ...?_userData,
            ...result as Map<String, dynamic>,
          };
        });

        _fullNameController.text =
            result['fullName'] ?? _fullNameController.text;
        _emailController.text = result['email'] ?? _emailController.text;
        _phoneController.text = result['phoneNumber'] ?? _phoneController.text;
        _designationController.text =
            result['designation'] ?? _designationController.text;
        _companyController.text = result['company'] ?? _companyController.text;
        _locationController.text =
            result['location'] ?? _locationController.text;
      }
    } else {
      // Edit form returned null (no changes made)
    }
  }
}
