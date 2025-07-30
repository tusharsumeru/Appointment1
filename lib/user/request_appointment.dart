import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import 'user_screen.dart';
import 'appointment_details_screen.dart';

class RequestAppointmentScreen extends StatefulWidget {
  final AppointmentType selectedType;

  const RequestAppointmentScreen({
    super.key,
    required this.selectedType,
  });

  @override
  State<RequestAppointmentScreen> createState() => _RequestAppointmentScreenState();
}

class _RequestAppointmentScreenState extends State<RequestAppointmentScreen> {
  String get _appointmentTypeText {
    switch (widget.selectedType) {
      case AppointmentType.myself:
        return 'Myself';
      case AppointmentType.guest:
        return 'Guest';
    }
  }

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  
  // Form state
  bool _isTeacher = false;
  bool _isFormValid = false;
  


  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _fullNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _designationController.text.isNotEmpty &&
          _companyController.text.isNotEmpty;
    });
  }

  void _showSuccessAndNavigate() {
    // Navigate to appointment details form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          personalInfo: {
            'fullName': _fullNameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'designation': _designationController.text,
            'company': _companyController.text,
            'isTeacher': _isTeacher,
            'appointmentType': widget.selectedType,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Appointment - $_appointmentTypeText'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: const SidebarComponent(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your contact details',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  _buildTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    placeholder: 'Enter your full name',
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),

                  // Email Address
                  _buildTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    placeholder: 'your@email.com',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  _buildPhoneField(),
                  const SizedBox(height: 20),

                  // Designation
                  _buildTextField(
                    label: 'Designation',
                    controller: _designationController,
                    placeholder: 'Your professional title',
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),

                  // Company/Organization
                  _buildTextField(
                    label: 'Company/Organization',
                    controller: _companyController,
                    placeholder: 'Your organization name',
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 24),

                  // Teacher Question
                  const Text(
                    'Are you an Art Of Living teacher? *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        groupValue: _isTeacher,
                        onChanged: (value) {
                          setState(() {
                            _isTeacher = value!;
                          });
                        },
                      ),
                      const Text('No'),
                      const SizedBox(width: 32),
                      Radio<bool>(
                        value: true,
                        groupValue: _isTeacher,
                        onChanged: (value) {
                          setState(() {
                            _isTeacher = value!;
                          });
                        },
                      ),
                      const Text('Yes'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _showSuccessAndNavigate : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Country Code Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => _validateForm(),
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 