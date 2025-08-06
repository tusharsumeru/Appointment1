import 'package:flutter/material.dart';
import '../action/storage_service.dart';
import 'profile_edit_screen.dart';

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
    print('🚀 ProfileScreen._loadUserData() - Starting to load user data...');
    
    try {
      print('📡 Calling StorageService.getUserData()...');
      final userData = await StorageService.getUserData();
      
      print('✅ StorageService.getUserData() completed successfully');
      print('📋 Raw userData received: $userData');
      print('📋 userData type: ${userData.runtimeType}');
      print('📋 userData is null: ${userData == null}');
      
             if (userData != null) {
         print('🔍 Detailed userData analysis:');
         print('   - userData keys: ${userData.keys.toList()}');
         print('   - userData length: ${userData.length}');
         
         // Log each field individually
         print('📝 Individual field values:');
         print('   - fullName: ${userData['fullName']} (type: ${userData['fullName']?.runtimeType})');
         print('   - name: ${userData['name']} (type: ${userData['name']?.runtimeType})');
         print('   - email: ${userData['email']} (type: ${userData['email']?.runtimeType})');
         print('   - phoneNumber: ${userData['phoneNumber']} (type: ${userData['phoneNumber']?.runtimeType})');
         print('   - phone: ${userData['phone']} (type: ${userData['phone']?.runtimeType})');
         print('   - designation: ${userData['designation']} (type: ${userData['designation']?.runtimeType})');
         print('   - company: ${userData['company']} (type: ${userData['company']?.runtimeType})');
         print('   - location: ${userData['location']} (type: ${userData['location']?.runtimeType})');
         print('   - profilePhoto: ${userData['profilePhoto']} (type: ${userData['profilePhoto']?.runtimeType})');
         print('   - userTags: ${userData['userTags']} (type: ${userData['userTags']?.runtimeType})');
         
         // Log any additional fields that might be present
         print('🔍 Additional fields found:');
         userData.forEach((key, value) {
           if (!['fullName', 'name', 'email', 'phoneNumber', 'phone', 'designation', 'company', 'location', 'profilePhoto', 'userTags'].contains(key)) {
             print('   - $key: $value (type: ${value.runtimeType})');
           }
         });
       }
      
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
      
      print('🎯 Setting form field values...');
      
      // Set initial values for form fields with logging
      final fullName = userData?['fullName'] ?? userData?['name'] ?? '';
      final email = userData?['email'] ?? '';
      
      // Handle phone number object structure
      String phone = '';
      if (userData?['phoneNumber'] != null) {
        if (userData!['phoneNumber'] is Map<String, dynamic>) {
          final phoneObj = userData['phoneNumber'] as Map<String, dynamic>;
          final countryCode = phoneObj['countryCode'] ?? '';
          final number = phoneObj['number'] ?? '';
          phone = '$countryCode$number';
        } else {
          phone = userData['phoneNumber'].toString();
        }
             } else if (userData?['phone'] != null) {
         phone = userData!['phone'].toString();
       }
      
      final designation = userData?['designation'] ?? '';
      final company = userData?['company'] ?? '';
      
      // Handle location from full_address
      String location = '';
      if (userData?['full_address'] != null && userData!['full_address'] is Map<String, dynamic>) {
        final addressObj = userData['full_address'] as Map<String, dynamic>;
        location = addressObj['street'] ?? '';
      } else {
        location = userData?['location'] ?? '';
      }
      
      print('📝 Form field values set:');
      print('   - fullName: $fullName');
      print('   - email: $email');
      print('   - phone: $phone');
      print('   - designation: $designation');
      print('   - company: $company');
      print('   - location: $location');
      
      _fullNameController.text = fullName;
      _emailController.text = email;
      _phoneController.text = phone;
      _designationController.text = designation;
      _companyController.text = company;
      _locationController.text = location;
      
      print('✅ ProfileScreen._loadUserData() completed successfully');
      
    } catch (error) {
      print('❌ Error in ProfileScreen._loadUserData(): $error');
      print('❌ Error type: ${error.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      
      setState(() {
        _isLoading = false;
      });
      
      print('🔄 Setting default values due to error...');
      
      // Set default values if data loading fails
      _fullNameController.text = 'Kaveri B';
      _emailController.text = 'kaveri@sumerudigital.com';
      _phoneController.text = '+919347653480';
      _designationController.text = 'Office Operations Specialist';
      _companyController.text = 'Sumeru Digital';
      _locationController.text = 'Coimbatore, Tamil Nadu, India';
      
      print('✅ Default values set successfully');
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
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              )
            : SingleChildScrollView(
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.deepPurple.withOpacity(0.1),
                                          child: const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.deepPurple,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.deepPurple.withOpacity(0.1),
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
                                  _userData?['fullName'] ?? _userData?['name'] ?? 'Kaveri B',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userData?['designation'] ?? 'Office Operations Specialist',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _userData?['company'] ?? 'Sumeru Digital',
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
                          
                                                     // Role Tags
                           Wrap(
                             spacing: 8.0,
                             runSpacing: 8.0,
                             children: _buildUserTags(),
                           ),
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
                          Container(
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
                                          'true Teacher',
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
                                _buildTeacherDetail('Name', 'Kiran Patule'),
                                const SizedBox(height: 8),
                                _buildTeacherDetail('Teacher Code', 'MH1458'),
                                const SizedBox(height: 8),
                                _buildTeacherDetail('Type', 'True AOL Teacher'),
                                const SizedBox(height: 8),
                                _buildTeacherDetail('Programs', 'Happiness Program'),
                              ],
                            ),
                          ),
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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

     List<Widget> _buildUserTags() {
     // Get userTags from the user data
     final userTags = _userData?['userTags'];
     
     print('🏷️ Building user tags...');
     print('   - userTags: $userTags');
     print('   - userTags type: ${userTags.runtimeType}');
     
     if (userTags == null) {
       print('   - userTags is null, showing placeholder');
       return [
         _buildRoleTag('No roles assigned'),
       ];
     }
     
     if (userTags.isEmpty) {
       print('   - userTags is empty, showing placeholder');
       return [
         _buildRoleTag('No roles assigned'),
       ];
     }
     
     // Convert userTags array to list of widgets
     final tagWidgets = userTags.map<Widget>((tag) {
       final tagString = tag.toString();
       print('   - Creating tag: $tagString');
       return _buildRoleTag(tagString);
     }).toList();
     
     print('   - Created ${tagWidgets.length} tag widgets');
     return tagWidgets;
   }

   Widget _buildRoleTag(String role) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
       decoration: BoxDecoration(
         color: Colors.lightGreen.shade100,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: Colors.lightGreen.shade300,
           width: 1,
         ),
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

  void _showEditForm(BuildContext context) async {
    print('🚀 ProfileScreen._showEditForm() - Opening edit form...');
    print('📋 Current _userData being passed to edit form: $_userData');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(userData: _userData),
      ),
    );
    
    print('📡 Edit form closed, result received: $result');
    print('📋 Result type: ${result.runtimeType}');
    print('📋 Result is null: ${result == null}');
    
    if (result != null) {
      print('✅ Processing edit form result...');
      print('📝 Result data: $result');
      print('📝 Result keys: ${result.keys.toList()}');
      
      // Log each field in the result
      result.forEach((key, value) {
        print('   - $key: $value (type: ${value.runtimeType})');
      });
      
      // Handle the updated data
      print('🔄 Merging result with existing _userData...');
      print('📋 Original _userData: $_userData');
      
      setState(() {
        _userData = {...?_userData, ...result};
      });
      
      print('📋 Updated _userData: $_userData');
      
      // Update the form controllers with new data
      print('🎯 Updating form controllers with new data...');
      
      final newFullName = result['fullName'] ?? _fullNameController.text;
      final newEmail = result['email'] ?? _emailController.text;
      final newPhone = result['phoneNumber'] ?? _phoneController.text;
      final newDesignation = result['designation'] ?? _designationController.text;
      final newCompany = result['company'] ?? _companyController.text;
      final newLocation = result['location'] ?? _locationController.text;
      
      print('📝 New form field values:');
      print('   - fullName: $newFullName');
      print('   - email: $newEmail');
      print('   - phone: $newPhone');
      print('   - designation: $newDesignation');
      print('   - company: $newCompany');
      print('   - location: $newLocation');
      
      _fullNameController.text = newFullName;
      _emailController.text = newEmail;
      _phoneController.text = newPhone;
      _designationController.text = newDesignation;
      _companyController.text = newCompany;
      _locationController.text = newLocation;
      
      print('✅ Form controllers updated successfully');
    } else {
      print('ℹ️ No result received from edit form (user cancelled or no changes)');
    }
  }
}
 