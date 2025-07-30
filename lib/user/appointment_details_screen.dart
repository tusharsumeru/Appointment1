import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import 'user_screen.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> personalInfo;

  const AppointmentDetailsScreen({
    super.key,
    required this.personalInfo,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  // Form controllers
  final TextEditingController _locationController = TextEditingController(text: 'Bengaluru, India');
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _peopleCountController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  
  // Form state
  bool _isFormValid = false;
  String? _selectedSecretary;
  String? _selectedFile;
  bool _isAttendingProgram = false;

  final List<String> _secretaries = [
    'Select a secretary',
    'Secretary 1',
    'Secretary 2',
    'Secretary 3',
  ];

  @override
  void initState() {
    super.initState();
    _validateForm();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _purposeController.dispose();
    _peopleCountController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _locationController.text.isNotEmpty &&
          _purposeController.text.isNotEmpty &&
          _peopleCountController.text.isNotEmpty &&
          _fromDateController.text.isNotEmpty &&
          _toDateController.text.isNotEmpty;
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      _validateForm();
    }
  }

  void _chooseFile() {
    // TODO: Implement file picker
    setState(() {
      _selectedFile = 'sample_document.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File selection feature coming soon!'),
      ),
    );
  }

  void _submitForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment request submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Navigate to success screen or back to main
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
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
                    'Appointment Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Provide details about your requested appointment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Appointment Location
                  _buildTextField(
                    label: 'Appointment Location',
                    controller: _locationController,
                    placeholder: 'Select location',
                    onChanged: (value) => _validateForm(),
                    hasDropdown: true,
                  ),
                  const SizedBox(height: 20),

                  // Secretary Contact
                  _buildDropdownField(
                    label: 'Have you been in touch with any secretary regarding your appointment?',
                    value: _selectedSecretary,
                    items: _secretaries,
                    onChanged: (value) {
                      setState(() {
                        _selectedSecretary = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Purpose of Meeting
                  _buildTextArea(
                    label: 'Purpose of Meeting',
                    controller: _purposeController,
                    placeholder: 'Please describe the purpose of your meeting in detail',
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),

                  // Number of People
                  _buildTextField(
                    label: 'Number of People',
                    controller: _peopleCountController,
                    placeholder: 'Number of people (including yourself)',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),

                  // Attachment
                  _buildFileUpload(),
                  const SizedBox(height: 20),

                  // Date Range Section
                  const Text(
                    'Select your preferred date range *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // From Date
                  _buildDateField(
                    label: 'From Date',
                    controller: _fromDateController,
                    onTap: () => _selectDate(context, _fromDateController),
                  ),
                  const SizedBox(height: 20),

                  // To Date
                  _buildDateField(
                    label: 'To Date',
                    controller: _toDateController,
                    onTap: () => _selectDate(context, _toDateController),
                  ),
                  const SizedBox(height: 20),

                  // Program Attendance Question
                  const Text(
                    'Are you attending any program at the Bangalore Ashram during these dates? *',
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
                        groupValue: _isAttendingProgram,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingProgram = value!;
                          });
                        },
                      ),
                      const Text('No'),
                      const SizedBox(width: 32),
                      Radio<bool>(
                        value: true,
                        groupValue: _isAttendingProgram,
                        onChanged: (value) {
                          setState(() {
                            _isAttendingProgram = value!;
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
                      onPressed: _isFormValid ? _submitForm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit',
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
    bool hasDropdown = false,
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
            suffixIcon: hasDropdown
                ? Icon(Icons.arrow_drop_down, color: Colors.grey[600])
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item == 'Select a secretary' ? null : item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required TextEditingController controller,
    required String placeholder,
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
          onChanged: onChanged,
          maxLines: 4,
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

  Widget _buildFileUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'You can attach a project proposal, report, or invitation (Max size: 5MB)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile ?? 'No file chosen',
                style: TextStyle(
                  color: _selectedFile != null ? Colors.black87 : Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'dd-mm-yyyy',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 