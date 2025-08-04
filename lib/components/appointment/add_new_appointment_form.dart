import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../action/action.dart';

class AddNewAppointmentForm extends StatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const AddNewAppointmentForm({
    Key? key,
    this.onSave,
    this.onCancel,
  }) : super(key: key);

  @override
  State<AddNewAppointmentForm> createState() => _AddNewAppointmentFormState();
}

class _AddNewAppointmentFormState extends State<AddNewAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noPeopleController = TextEditingController(text: '1');
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  
  // Form values
  String _selectedCountryCode = '+91';
  String _selectedVenue = '';
  bool _tbsRequired = false;
  bool _dontSendNotifications = false;
  File? _selectedImage;
  File? _selectedAttachment;
  
  // Venue options
  final List<String> _venueOptions = [
    'Secretariat Office A1',
    'Special Enclosure - Shiva Temple',
    'Yoga School',
    'Radha Kunj',
    'Shiva Temple',
    'Satsang Backstage',
    'Gurukul',
  ];

  // Country codes (using the JSON we created)
  List<Map<String, dynamic>> _countryCodes = [];

  @override
  void initState() {
    super.initState();
    _loadCountryCodes();
    _setDefaultDate();
  }

  void _loadCountryCodes() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context).loadString('lib/data/country_codes.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _countryCodes = List<Map<String, dynamic>>.from(jsonData['countries']);
      });
    } catch (e) {
      // Fallback to basic country codes if JSON fails to load
      _countryCodes = [
        {'name': 'India', 'iso': 'IN', 'code': '+91'},
        {'name': 'United States', 'iso': 'US', 'code': '+1'},
        {'name': 'United Kingdom', 'iso': 'GB', 'code': '+44'},
        {'name': 'Canada', 'iso': 'CA', 'code': '+1'},
        {'name': 'Australia', 'iso': 'AU', 'code': '+61'},
      ];
    }
  }

  void _setDefaultDate() {
    // Leave date and time empty by default
    _dateController.text = '';
    _timeController.text = '';
  }

  String _getCountryFlag(String isoCode) {
    // Convert ISO code to flag emoji
    final codePoints = isoCode.toUpperCase().codeUnits.map((e) => e + 127397).toList();
    return String.fromCharCodes(codePoints);
  }

  String _getSelectedCountryIso(String countryCode) {
    final country = _countryCodes.firstWhere(
      (country) => country['code'] == countryCode,
      orElse: () => {'iso': 'IN'},
    );
    return country['iso'] as String;
  }

  void _showCountryCodeBottomSheet(BuildContext context) {
    List<Map<String, dynamic>> filteredCountries = List.from(_countryCodes);
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Select Country Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                      if (searchQuery.isEmpty) {
                        filteredCountries = List.from(_countryCodes);
                      } else {
                        filteredCountries = _countryCodes.where((country) {
                          final name = country['name'].toString().toLowerCase();
                          final code = country['code'].toString().toLowerCase();
                          return name.contains(searchQuery) || code.contains(searchQuery);
                        }).toList();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Country list
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = _selectedCountryCode == country['code'];
                      
                      return ListTile(
                        leading: Text(
                          _getCountryFlag(country['iso'] as String),
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          '${country['name']} (${country['code']})',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.black87,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                        onTap: () {
                          this.setState(() {
                            _selectedCountryCode = country['code'] as String;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVenueBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Select Venue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search venue...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
            const SizedBox(height: 16),
            // Venue list
            Expanded(
              child: ListView.builder(
                itemCount: _venueOptions.length,
                itemBuilder: (context, index) {
                  final venue = _venueOptions[index];
                  final isSelected = _selectedVenue == venue;
                  
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(
                      venue,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () {
                      setState(() {
                        _selectedVenue = venue;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _pickAttachment() async {
    // For now, we'll use image picker as a placeholder
    // In a real app, you'd want to use file_picker package
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedAttachment = File(pickedFile.path);
      });
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
    });
  }

  void _saveAppointment() async {
    // Validate all required fields
    bool isValid = true;
    String errorMessage = '';
    
    // Validate name
    if (_fullNameController.text.trim().isEmpty) {
      isValid = false;
      errorMessage = 'Please enter name';
    }
    // Validate designation
    else if (_designationController.text.trim().isEmpty) {
      isValid = false;
      errorMessage = 'Please enter designation';
    }
    // Validate date
    else if (_dateController.text.trim().isEmpty) {
      isValid = false;
      errorMessage = 'Please select date';
    }
    // Validate time
    else if (_timeController.text.trim().isEmpty) {
      isValid = false;
      errorMessage = 'Please select time';
    }

    // Validate venue
    else if (_selectedVenue.isEmpty) {
      isValid = false;
      errorMessage = 'Please select venue';
    }
    
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Call the ActionService to create the appointment
        final result = await ActionService.createQuickAppointment(
          fullName: _fullNameController.text,
          emailId: _emailController.text,
          phoneNumber: '$_selectedCountryCode${_mobileNoController.text}',
          designation: _designationController.text,
          company: '', // Company field
          isTeacher: false, // Is teacher field
          photo: _selectedImage != null ? {
            'url': _selectedImage!.path,
            'filename': _selectedImage!.path.split('/').last,
          } : null,
          referenceDetails: {
            'name': _fullNameController.text, // Use full name as reference
            'email': _emailController.text,
            'phone': '$_selectedCountryCode${_mobileNoController.text}',
          },
          location: _selectedVenue,
          purpose: _purposeController.text,
          remarksForGurudev: _remarkController.text,
          numberOfPeople: int.tryParse(_noPeopleController.text) ?? 1,
          preferredDate: _dateController.text,
          preferredTime: _timeController.text,
          tbsRequired: _tbsRequired,
          dontSendNotifications: _dontSendNotifications,
          attachment: _selectedAttachment != null ? {
            'url': _selectedAttachment!.path,
            'filename': _selectedAttachment!.path.split('/').last,
          } : null,
          programDetails: {
            'isAttending': false, // Default to false
          },
        );

        // Close loading dialog
        Navigator.of(context).pop();

        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Appointment created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to inbox screen after successful creation
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/inbox',
            (route) => false, // Remove all previous routes
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create appointment'),
              backgroundColor: Colors.red,
            ),
          );
        }

      } catch (error) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating appointment: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        print('Error creating appointment: $error');
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _designationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _emailController.dispose();
    _noPeopleController.dispose();
    _mobileNoController.dispose();
    _purposeController.dispose();
    _remarkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937), // gray-800
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    int? maxLines = 1,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(color: Colors.grey[500]),
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
          'Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              // Country code button
              GestureDetector(
                onTap: () => _showCountryCodeBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCountryFlag(_getSelectedCountryIso(_selectedCountryCode)),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              // Phone number field
              Expanded(
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 16),
                      child: Text(
                        '$_selectedCountryCode ',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _mobileNoController,
                        decoration: const InputDecoration(
                          hintText: 'Enter mobile number',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                          counterText: '', // Remove the character counter
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload a clear photo of the appointee or take a new one',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        // Upload from Device
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 32,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload from Device',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose an existing photo from your device',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Take Photo
        GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 32,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use your device camera to take a new photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo uploaded successfully',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Tap to remove',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload any relevant documents or files',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 16),
        // Upload Attachment
        GestureDetector(
          onTap: _pickAttachment,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file,
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                                 Expanded(
                   child: Text(
                     'Choose file',
                     style: TextStyle(
                       color: Colors.grey[500],
                       fontSize: 16,
                     ),
                   ),
                 ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              ],
            ),
          ),
        ),
        if (_selectedAttachment != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attachment uploaded successfully',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        _selectedAttachment!.path.split('/').last,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _removeAttachment,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red[600],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Row(
      children: [
        // Date Field with Label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151), // gray-700
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dateController.text.isEmpty ? 'Select Date' : _dateController.text,
                          style: TextStyle(
                            color: _dateController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Time Field with Label
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151), // gray-700
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _timeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _timeController.text.isEmpty ? 'Select Time' : _timeController.text,
                          style: TextStyle(
                            color: _timeController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String selectedValue,
    required String placeholder,
    required VoidCallback onTap,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedValue.isEmpty ? placeholder : selectedValue,
                    style: TextStyle(
                      color: selectedValue.isEmpty ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Select Option',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            // TBS/Req checkbox
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _tbsRequired = !_tbsRequired;
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _tbsRequired ? const Color(0xFFF97316) : Colors.white, // orange-600
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _tbsRequired ? const Color(0xFFF97316) : const Color(0xFFCBD5E1), // slate-300
                        width: 1,
                      ),
                    ),
                    child: _tbsRequired
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _tbsRequired = !_tbsRequired;
                    });
                  },
                  child: const Text(
                    'TBS/Req',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155), // slate-700
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Don't send Email/SMS checkbox
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _dontSendNotifications = !_dontSendNotifications;
                    });
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _dontSendNotifications ? const Color(0xFFF97316) : Colors.white, // orange-600
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _dontSendNotifications ? const Color(0xFFF97316) : const Color(0xFFCBD5E1), // slate-300
                        width: 1,
                      ),
                    ),
                    child: _dontSendNotifications
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _dontSendNotifications = !_dontSendNotifications;
                    });
                  },
                  child: const Text(
                    'Don\'t send Email/SMS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155), // slate-700
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Personal Information (Required Fields)
            _buildCard(
              title: 'Personal Information',
              subtitle: 'Enter the required appointment details',
              child: Column(
                children: [
                  // Name Field
                  _buildInputField(
                    label: 'Name',
                    controller: _fullNameController,
                    placeholder: 'Enter full name',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Designation Field
                  _buildInputField(
                    label: 'Designation',
                    controller: _designationController,
                    placeholder: 'Professional title',
                    prefixIcon: const Icon(Icons.work_outline, color: Colors.grey),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter designation';
                      }
                      return null;
                    },
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and Time
                  _buildDateTimeField(),
                  const SizedBox(height: 16),
                  
                  // Select Option
                  _buildCheckboxOptions(),
                  const SizedBox(height: 16),
                  
                  // Selected Venue
                  _buildSelectionField(
                    label: 'Selected Venue',
                    selectedValue: _selectedVenue,
                    placeholder: 'Select venue',
                    onTap: () => _showVenueBottomSheet(context),
                    icon: Icons.location_on,
                    isRequired: true,
                  ),
                ],
              ),
            ),

            // Card 2: Optional Fields
            _buildCard(
              title: 'Optional Fields',
              subtitle: 'Additional information (optional)',
              child: Column(
                children: [
                  // Email Field
                  _buildInputField(
                    label: 'Email',
                    controller: _emailController,
                    placeholder: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Number of People
                  _buildInputField(
                    label: 'No. of People',
                    controller: _noPeopleController,
                    placeholder: 'Total number of attendees',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.people_outline, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Photo Upload
                  _buildPhotoUpload(),
                  const SizedBox(height: 16),
                  
                  // Mobile Number
                  _buildPhoneField(),
                ],
              ),
            ),

            // Card 3: Appointment Details
            _buildCard(
              title: 'Appointment Details',
              subtitle: 'Provide details about the appointment',
              child: Column(
                children: [
                  // Purpose Field
                  _buildInputField(
                    label: 'Purpose',
                    controller: _purposeController,
                    placeholder: 'Describe the purpose of the meeting',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Remark Field
                  _buildInputField(
                    label: 'Remark',
                    controller: _remarkController,
                    placeholder: 'Any additional remarks or notes',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Attachment Upload
                  _buildAttachmentUpload(),
                ],
              ),
            ),

            // Submit Button
            Container(
              width: double.infinity,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ElevatedButton(
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF97316), // orange-500
                        Color(0xFFEAB308), // yellow-500
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Quick Appointment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
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
} 
