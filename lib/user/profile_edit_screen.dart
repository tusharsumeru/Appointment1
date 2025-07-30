import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ProfileEditScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  // Role checkboxes state
  final Map<String, bool> _roleCheckboxes = {
    'Ashramite': false,
    'Ashram Sevak (Short-term)': false,
    'Swamiji / Brahmachari': false,
    'Ashram HOD': false,
    'Trustee': false,
    'State Apex / STC': false,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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

  void _initializeControllers() {
    _fullNameController.text = widget.userData?['fullName'] ?? widget.userData?['name'] ?? 'Kaveri B';
    _emailController.text = widget.userData?['email'] ?? 'kaveri@sumerudigital.com';
    _phoneController.text = widget.userData?['phoneNumber'] ?? widget.userData?['phone'] ?? '+919347653480';
    _designationController.text = widget.userData?['designation'] ?? 'Office Operations Specialist';
    _companyController.text = widget.userData?['company'] ?? 'Sumeru Digital';
    _locationController.text = widget.userData?['location'] ?? 'Coimbatore, Tamil Nadu, India';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Photo Section
                    _buildSectionHeader('Profile Photo', Icons.camera_alt_outlined),
                    const SizedBox(height: 16),
                    
                    // Profile Photo Card
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
                        children: [
                          // Current Profile Photo Display
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.lightGreen.shade300,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: widget.userData?['profilePhoto'] != null
                                  ? Image.network(
                                      widget.userData!['profilePhoto'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.lightGreen.shade50,
                                          child: const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.green,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.lightGreen.shade50,
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.green,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Current Profile Photo Text
                          Text(
                            'Current Profile Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          Text(
                            'Profile photo from server',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Action Buttons
                          Column(
                            children: [
                              // Upload Different Photo Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Upload photo functionality coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Upload Different Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Take New Photo Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Camera functionality coming soon!'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take New Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Delete Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Delete photo functionality coming soon!'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete Photo'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    side: BorderSide(color: Colors.red.shade300),
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
                          
                          // Form Fields
                          _buildFormField('Full Name', _fullNameController),
                          const SizedBox(height: 16),
                          
                          _buildFormField('Email Address', _emailController),
                          const SizedBox(height: 16),
                          
                          _buildFormField('Phone Number', _phoneController),
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
                          
                          // Form Fields
                          _buildFormField('Designation', _designationController),
                          const SizedBox(height: 16),
                          
                          _buildFormField('Company/Organization', _companyController),
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
                          
                          // Form Field
                          _buildFormField('Location', _locationController),
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
                          
                          // Role Checkboxes
                          _buildRoleCheckbox('Ashramite'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Ashram Sevak (Short-term)'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Swamiji / Brahmachari'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Ashram HOD'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('Trustee'),
                          const SizedBox(height: 12),
                          _buildRoleCheckbox('State Apex / STC'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Save Button at Bottom
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
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
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            color: Colors.deepPurple,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
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
            fillColor: Colors.grey.shade50,
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
  
  Widget _buildRoleCheckbox(String role) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _roleCheckboxes[role] = !(_roleCheckboxes[role] ?? false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.lightGreen.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _roleCheckboxes[role] == true ? Colors.green : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _roleCheckboxes[role] == true ? Colors.green : Colors.lightGreen.shade300,
                  width: 2,
                ),
              ),
              child: _roleCheckboxes[role] == true
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Role Text
            Expanded(
              child: Text(
                role,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _roleCheckboxes[role] == true ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final updatedData = {
      'fullName': _fullNameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
      'designation': _designationController.text,
      'company': _companyController.text,
      'location': _locationController.text,
      'selectedRoles': _roleCheckboxes.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList(),
    };
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate back
    Navigator.pop(context, updatedData);
  }
} 