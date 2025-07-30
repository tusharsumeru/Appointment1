import 'package:flutter/material.dart';

class MessageForm extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const MessageForm({
    super.key,
    required this.appointment,
  });

  @override
  State<MessageForm> createState() => _MessageFormState();
}

class _MessageFormState extends State<MessageForm> {
  final TextEditingController _otherSmsController = TextEditingController();
  final TextEditingController _smsContentController = TextEditingController();
  
  bool _appointeeMobileChecked = false;
  bool _referenceMobileChecked = false;
  String? _selectedTemplate;
  
  List<String> smsTemplates = [
    'Appointment Confirmation',
    'Appointment Reminder',
    'Appointment Cancellation',
    'Custom Message'
  ];

  @override
  void initState() {
    super.initState();
    _loadAppointmentData();
  }

  void _loadAppointmentData() {
    // Set default values based on appointment data
    _appointeeMobileChecked = true;
    _referenceMobileChecked = true;
    
    // Set default SMS content
    _smsContentController.text = _getDefaultSmsContent();
  }

  String _getDefaultSmsContent() {
    final firstName = widget.appointment['userFirstName']?.toString() ?? '';
    final appointmentId = widget.appointment['appointmentId']?.toString() ?? '';
    final location = widget.appointment['location']?.toString() ?? '';
    final scheduledDate = widget.appointment['scheduledDate']?.toString() ?? '';
    final scheduledTime = widget.appointment['scheduledTime']?.toString() ?? '';
    
    return 'Dear $firstName, your appointment (ID: $appointmentId) has been confirmed. Location: $location, Date: $scheduledDate, Time: $scheduledTime.';
  }

  String _getAppointeeMobile() {
    final userPhone = widget.appointment['userPhone'];
    if (userPhone is Map<String, dynamic>) {
      final countryCode = userPhone['countryCode']?.toString() ?? '';
      final number = userPhone['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode$number';
      }
    }
    return widget.appointment['userPhone']?.toString() ?? '';
  }

  String _getReferenceMobile() {
    final referencePhone = widget.appointment['referencePhone'];
    if (referencePhone is Map<String, dynamic>) {
      final countryCode = referencePhone['countryCode']?.toString() ?? '';
      final number = referencePhone['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode$number';
      }
    }
    return widget.appointment['referencePhone']?.toString() ?? '';
  }

  void _onTemplateChanged(String? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null && template != 'Custom Message') {
        _smsContentController.text = _getTemplateContent(template);
      }
    });
  }

  String _getTemplateContent(String template) {
    final firstName = widget.appointment['userFirstName']?.toString() ?? '';
    final appointmentId = widget.appointment['appointmentId']?.toString() ?? '';
    final location = widget.appointment['location']?.toString() ?? '';
    final scheduledDate = widget.appointment['scheduledDate']?.toString() ?? '';
    final scheduledTime = widget.appointment['scheduledTime']?.toString() ?? '';
    final referenceName = widget.appointment['referenceName']?.toString() ?? '';
    final secretaryName = widget.appointment['assignedSecretary']?['fullName']?.toString() ?? '';
    final company = widget.appointment['userCurrentCompany']?.toString() ?? '';
    final designation = widget.appointment['userCurrentDesignation']?.toString() ?? '';

    switch (template) {
      case 'Appointment Confirmation':
        return 'Dear $firstName, your appointment (ID: $appointmentId) has been confirmed. Location: $location, Date: $scheduledDate, Time: $scheduledTime.';
      case 'Appointment Reminder':
        return 'Reminder: Your appointment (ID: $appointmentId) is scheduled for $scheduledDate at $scheduledTime. Location: $location.';
      case 'Appointment Cancellation':
        return 'Dear $firstName, your appointment (ID: $appointmentId) scheduled for $scheduledDate at $scheduledTime has been cancelled.';
      default:
        return _getDefaultSmsContent();
    }
  }

  Future<void> _sendSms() async {
    // Validate inputs
    if (!_appointeeMobileChecked && !_referenceMobileChecked && _otherSmsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one mobile number or enter other SMS numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_smsContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter SMS content'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For now, just show a success message (UI only)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SMS functionality will be implemented later'),
        backgroundColor: Colors.blue,
      ),
    );
    
    // Close the form
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mobile number selection
          const Text(
            'Select Mobile Numbers:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Appointee Mobile
          Row(
            children: [
              Checkbox(
                value: _appointeeMobileChecked,
                onChanged: (value) {
                  setState(() {
                    _appointeeMobileChecked = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Appointee Mobile: ${_getAppointeeMobile()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          // Reference Mobile
          Row(
            children: [
              Checkbox(
                value: _referenceMobileChecked,
                onChanged: (value) {
                  setState(() {
                    _referenceMobileChecked = value ?? false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Reference Mobile: ${_getReferenceMobile()}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Other SMS Numbers
          const Text(
            'Other SMS Numbers:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherSmsController,
            decoration: const InputDecoration(
              hintText: 'Enter comma-separated mobile numbers with country code',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Note: Please add comma-separated mobile numbers with country code',
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          
          const SizedBox(height: 16),
          
          // SMS Template
          const Text(
            'SMS Template:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedTemplate,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Select Template'),
            items: smsTemplates.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Text(template),
              );
            }).toList(),
            onChanged: _onTemplateChanged,
          ),
          
          const SizedBox(height: 16),
          
          // SMS Content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SMS Content:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _smsContentController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'SMS content will appear here when you select a template, or you can type your own message. Use {firstname}, {appointmentId}, etc. as placeholders.',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Available placeholders: {firstname}, {appointmentId}, {location}, {scheduledDate}, {scheduledTime}, {referenceName}, {secretaryName}, {company}, {designation}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendSms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
          
          // Add some bottom padding to prevent overflow
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _otherSmsController.dispose();
    _smsContentController.dispose();
    super.dispose();
  }
} 