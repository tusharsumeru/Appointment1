import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _noPeopleController = TextEditingController(text: '1');
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _refNameController = TextEditingController();
  final TextEditingController _refMobileNoController = TextEditingController();
  final TextEditingController _refEmailController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _gurudevRemarkController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  
  // Form values
  String _selectedCountryCode = '+91';
  String _selectedRefCountryCode = '+91';
  String _selectedVenue = '';
  File? _selectedImage;
  bool _toBeOpt = false;
  bool _stopSendEmailMessage = false;
  bool _isTeacher = false;
  bool _isAttendingProgram = false;
  
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
    final now = DateTime.now();
    _dateController.text = DateFormat('yyyy-MM-dd').format(now);
    _timeController.text = '11:00';
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

  String _getSelectedCountryName(String countryCode) {
    final country = _countryCodes.firstWhere(
      (country) => country['code'] == countryCode,
      orElse: () => {'name': 'India', 'code': '+91'},
    );
    return '${country['name']} (${country['code']})';
  }

  void _showCountryCodeBottomSheet(BuildContext context, bool isMobile) {
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
                      final isSelected = isMobile 
                          ? _selectedCountryCode == country['code']
                          : _selectedRefCountryCode == country['code'];
                      
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
                            if (isMobile) {
                              _selectedCountryCode = country['code'] as String;
                            } else {
                              _selectedRefCountryCode = country['code'] as String;
                            }
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

  void _saveAppointment() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically send the data to your backend
      final appointmentData = {
        'fullName': _fullNameController.text,
        'noPeople': _noPeopleController.text,
        'designation': _designationController.text,
        'company': _companyController.text,
        'countryCode': _selectedCountryCode,
        'mobileNo': _mobileNoController.text,
        'email': _emailController.text,
        'isTeacher': _isTeacher,
        'refName': _refNameController.text,
        'refCountryCode': _selectedRefCountryCode,
        'refMobileNo': _refMobileNoController.text,
        'refEmail': _refEmailController.text,
        'venue': _selectedVenue,
        'purpose': _purposeController.text,
        'gurudevRemark': _gurudevRemarkController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'isAttendingProgram': _isAttendingProgram,
        'toBeOpt': _toBeOpt,
        'stopSendEmailMessage': _stopSendEmailMessage,
        'image': _selectedImage?.path,
      };
      
      print('Appointment Data: $appointmentData');
      widget.onSave?.call();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _noPeopleController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _mobileNoController.dispose();
    _emailController.dispose();
    _refNameController.dispose();
    _refMobileNoController.dispose();
    _refEmailController.dispose();
    _purposeController.dispose();
    _gurudevRemarkController.dispose();
    _dateController.dispose();
    _timeController.dispose();
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

  Widget _buildPhoneField({
    required String label,
    required TextEditingController controller,
    required String selectedCountryCode,
    required Function() onCountryCodeTap,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
                onTap: onCountryCodeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCountryFlag(_getSelectedCountryIso(selectedCountryCode)),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
              // Phone number field
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
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
        Row(
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
            ),
          ],
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

  Widget _buildRadioGroup({
    required String label,
    required String option1,
    required String option2,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // gray-700
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: !value ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !value ? Colors.blue[200]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !value ? Colors.blue : Colors.transparent,
                          border: Border.all(
                            color: !value ? Colors.blue : Colors.grey[400]!,
                          ),
                        ),
                        child: !value
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option1,
                        style: TextStyle(
                          fontWeight: !value ? FontWeight.w600 : FontWeight.normal,
                          color: !value ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: value ? Colors.blue[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value ? Colors.blue[200]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: value ? Colors.blue : Colors.transparent,
                          border: Border.all(
                            color: value ? Colors.blue : Colors.grey[400]!,
                          ),
                        ),
                        child: value
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option2,
                        style: TextStyle(
                          fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                          color: value ? Colors.blue[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? Colors.blue : Colors.grey[400]!,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      children: [
        // Preferred Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
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
                    Text(
                      _dateController.text.isEmpty ? 'Select Date' : _dateController.text,
                      style: TextStyle(
                        color: _dateController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a date within the next 6 months',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Preferred Time
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151), // gray-700
              ),
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
                    Text(
                      _timeController.text.isEmpty ? 'Select Time' : _timeController.text,
                      style: TextStyle(
                        color: _timeController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select any time in 24-hour format',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
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
            // Card 1: Personal Information
            _buildCard(
              title: 'Personal Information',
              subtitle: 'Enter the appointee\'s contact details',
              child: Column(
                children: [
                  // Full Name Field
                  _buildInputField(
                    label: 'Full Name',
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
                  
                  // Email Field
                  _buildInputField(
                    label: 'Email Address',
                    controller: _emailController,
                    placeholder: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phone Number',
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
                                                                                                  // Country code flag button
                                   GestureDetector(
                                     onTap: () => _showCountryCodeBottomSheet(context, true),
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                       decoration: BoxDecoration(
                                         border: Border(
                                           right: BorderSide(color: Colors.grey[200]!),
                                         ),
                                       ),
                                       child: Text(
                                         _getCountryFlag(_getSelectedCountryIso(_selectedCountryCode)),
                                         style: const TextStyle(fontSize: 18),
                                       ),
                                     ),
                                   ),
                                   // Country code display
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                     child: Text(
                                       _selectedCountryCode,
                                       style: const TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w500,
                                         color: Color(0xFF374151), // gray-700
                                       ),
                                     ),
                                   ),
                                   // Phone number field
                                   Expanded(
                                     child: TextFormField(
                                       controller: _mobileNoController,
                                       decoration: const InputDecoration(
                                         hintText: '',
                                         border: InputBorder.none,
                                         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                       ),
                                       keyboardType: TextInputType.phone,
                                     ),
                                   ),
                          ],
                        ),
                      ),
                    ],
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
                  
                  // Company/Organization Field
                  _buildInputField(
                    label: 'Company/Organization',
                    controller: _companyController,
                    placeholder: 'Organization name',
                    prefixIcon: const Icon(Icons.business, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Is Teacher Radio Group
                  _buildRadioGroup(
                    label: 'Is this person an Art Of Living teacher?',
                    option1: 'No',
                    option2: 'Yes',
                    value: _isTeacher,
                    onChanged: (value) {
                      setState(() {
                        _isTeacher = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Photo Upload
                  _buildPhotoUpload(),
                  const SizedBox(height: 24),
                  
                  // Reference Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reference Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151), // gray-700
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Information about the person who referred this appointee (if applicable)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                                                 // Reference Name Field
                         _buildInputField(
                           label: 'Reference Name',
                           controller: _refNameController,
                           placeholder: 'Name of the person who referred',
                           prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                         ),
                         const SizedBox(height: 16),
                         
                         // Reference Email Field
                         _buildInputField(
                           label: 'Reference Email',
                           controller: _refEmailController,
                           placeholder: 'email@example.com',
                           keyboardType: TextInputType.emailAddress,
                           prefixIcon: const Icon(Icons.email, color: Colors.grey),
                         ),
                        const SizedBox(height: 16),
                                                 // Reference Phone Field
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text(
                               'Reference Phone',
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
                                   // Country code flag button
                                   GestureDetector(
                                     onTap: () => _showCountryCodeBottomSheet(context, false),
                                     child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                       decoration: BoxDecoration(
                                         border: Border(
                                           right: BorderSide(color: Colors.grey[200]!),
                                         ),
                                       ),
                                       child: Text(
                                         _getCountryFlag(_getSelectedCountryIso(_selectedRefCountryCode)),
                                         style: const TextStyle(fontSize: 18),
                                       ),
                                     ),
                                   ),
                                   // Country code display
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                     child: Text(
                                       _selectedRefCountryCode,
                                       style: const TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w500,
                                         color: Color(0xFF374151), // gray-700
                                       ),
                                     ),
                                   ),
                                   // Phone number field
                                   Expanded(
                                     child: TextFormField(
                                       controller: _refMobileNoController,
                                       decoration: const InputDecoration(
                                         hintText: '',
                                         border: InputBorder.none,
                                         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                       ),
                                       keyboardType: TextInputType.phone,
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
                ],
              ),
            ),

            // Card 2: Appointment Details
            _buildCard(
              title: 'Appointment Details',
              subtitle: 'Provide details about the appointment',
              child: Column(
                children: [
                  // Venue Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151), // gray-700
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showVenueBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA).withOpacity(0.5), // zinc-50/50
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedVenue.isEmpty ? 'Select Venue' : _selectedVenue,
                                  style: TextStyle(
                                    color: _selectedVenue.isEmpty ? Colors.grey[500] : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Purpose Field
                  _buildInputField(
                    label: 'Purpose of Meeting',
                    controller: _purposeController,
                    placeholder: 'Describe the purpose of the meeting',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  
                  // Gurudev Remarks Field
                  _buildInputField(
                    label: 'Remarks for Gurudev',
                    controller: _gurudevRemarkController,
                    placeholder: 'Any special remarks or notes for Gurudev',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Special notes, context, or important information for Gurudev\'s attention',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Number of People
                  _buildInputField(
                    label: 'Number of People',
                    controller: _noPeopleController,
                    placeholder: 'Total number of attendees',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Is Attending Program Radio Group
                  _buildRadioGroup(
                    label: 'Is the appointee attending any program at the ashram during the preferred dates?',
                    option1: 'No',
                    option2: 'Yes',
                    value: _isAttendingProgram,
                    onChanged: (value) {
                      setState(() {
                        _isAttendingProgram = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Card 3: Preferred Date & Time
            _buildCard(
              title: 'Preferred Date & Time',
              subtitle: 'Select the preferred appointment schedule',
              child: Column(
                children: [
                  _buildDateTimeField(),
                  const SizedBox(height: 24),
                  
                  // Options Section
                  const Text(
                    'Select Options',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151), // gray-700
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckbox(
                    label: 'TBS/Req',
                    value: _toBeOpt,
                    onChanged: (value) {
                      setState(() {
                        _toBeOpt = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildCheckbox(
                    label: 'Don\'t send Email/SMS',
                    value: _stopSendEmailMessage,
                    onChanged: (value) {
                      setState(() {
                        _stopSendEmailMessage = value;
                      });
                    },
                  ),
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