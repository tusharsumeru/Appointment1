import 'package:flutter/material.dart';
import '../../action/action.dart';

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
  
  // State variables for appointment data
  late Map<String, dynamic> _appointmentData;
  late String _firstName;
  late String _fullName;
  late String _appointmentId;
  late String _location;
  late String _scheduledDate;
  late String _scheduledTime;
  late String _referenceName;
  late String _secretaryName;
  late String _company;
  late String _designation;
  late String _appointeeMobile;
  late String _referenceMobile;
  
  bool _appointeeMobileChecked = false;
  bool _referenceMobileChecked = false;
  String? _selectedTemplate;
  bool _isLoading = false;
  
  List<Map<String, dynamic>> smsTemplates = [];
  List<String> smsTemplateNames = [];

  @override
  void initState() {
    super.initState();
    _initializeAppointmentData();
    _loadSmsTemplates();
  }

  void _initializeAppointmentData() {
    // Store appointment data in local state for easy access
    _appointmentData = widget.appointment;
    
    // Extract and store all relevant data
    _firstName = _extractFirstName();
    _fullName = _extractFullName();
    _appointmentId = _extractAppointmentId();
    _location = _extractLocation();
    _scheduledDate = _extractScheduledDate();
    _scheduledTime = _extractScheduledTime();
    _referenceName = _extractReferenceName();
    _secretaryName = _extractSecretaryName();
    _company = _extractCompany();
    _designation = _extractDesignation();
    _appointeeMobile = _extractAppointeeMobile();
    _referenceMobile = _extractReferenceMobile();
    
    // Set default values - unchecked by default
    _appointeeMobileChecked = false;
    _referenceMobileChecked = false;
    
    // Set default SMS content
    _smsContentController.text = _getDefaultSmsContent();
  }

  // Data extraction methods - now centralized and reusable
  String _extractFirstName() {
    final createdBy = _appointmentData['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final fullName = createdBy['fullName']?.toString() ?? '';
      if (fullName.isNotEmpty) {
        final nameParts = fullName.split(' ');
        return nameParts.isNotEmpty ? nameParts[0] : fullName;
      }
    }
    return '';
  }

  String _extractFullName() {
    // Try userFullName first (from the actual data structure)
    final userFullName = _appointmentData['userFullName']?.toString();
    
    if (userFullName != null && userFullName.isNotEmpty) {
      return userFullName;
    }
    
    // Fallback to createdBy.fullName
    final createdBy = _appointmentData['createdBy'];
    
    if (createdBy is Map<String, dynamic>) {
      final createdByFullName = createdBy['fullName']?.toString() ?? '';
      return createdByFullName;
    }
    
    return '';
  }

  String _extractAppointmentId() {
    return _appointmentData['appointmentId']?.toString() ?? 
           _appointmentData['_id']?.toString() ?? '';
  }

  String _extractLocation() {
    return _appointmentData['location']?.toString() ?? '';
  }

  String _extractScheduledDate() {
    final scheduledDate = _appointmentData['scheduledDate'];
    if (scheduledDate is String && scheduledDate.isNotEmpty) {
      final date = DateTime.tryParse(scheduledDate);
      if (date != null) {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
    return scheduledDate?.toString() ?? '';
  }

  String _extractScheduledTime() {
    final scheduledTime = _appointmentData['scheduledTime'];
    if (scheduledTime is String && scheduledTime.isNotEmpty) {
      return scheduledTime;
    }
    return '';
  }

  String _extractReferenceName() {
    final referencePerson = _appointmentData['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['fullName']?.toString() ?? '';
    }
    return _appointmentData['referenceName']?.toString() ?? '';
  }

  String _extractSecretaryName() {
    final assignedSecretary = _appointmentData['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      return assignedSecretary['fullName']?.toString() ?? '';
    }
    return '';
  }

  String _extractCompany() {
    return _appointmentData['userCurrentCompany']?.toString() ?? '';
  }

  String _extractDesignation() {
    return _appointmentData['userCurrentDesignation']?.toString() ?? '';
  }

  String _extractAppointeeMobile() {
    final phoneNumber = _appointmentData['phoneNumber'];
    if (phoneNumber is Map<String, dynamic>) {
      final countryCode = phoneNumber['countryCode']?.toString() ?? '';
      final number = phoneNumber['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode$number';
      }
    }
    return phoneNumber?.toString() ?? '';
  }

  String _extractReferenceMobile() {
    final referencePerson = _appointmentData['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final phoneNumber = referencePerson['phoneNumber'];
      if (phoneNumber is Map<String, dynamic>) {
        final countryCode = phoneNumber['countryCode']?.toString() ?? '';
        final number = phoneNumber['number']?.toString() ?? '';
        if (countryCode.isNotEmpty && number.isNotEmpty) {
          return '$countryCode$number';
        }
      }
      return phoneNumber?.toString() ?? '';
    }
    return '';
  }

  // Get people count from accompanyUsers
  int _getPeopleCount() {
    final accompanyUsers = _appointmentData['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      return accompanyUsers['numberOfUsers'] ?? 1;
    }
    return 1; // Default to 1 if no accompanyUsers data
  }

  // Get Ji title (honorific) based on gender or other criteria
  String _getJiTitle() {
    // You can customize this based on your requirements
    // For now, returning a generic honorific
    return 'Ji';
  }

  // Get appropriate label for each placeholder key
  String _getLabelForKey(String key) {
    switch (key.toLowerCase()) {
      case 'aid':
      case 'appointmentid':
        return 'Appointment ID';
      case 'fullname':
        return 'Full Name';
      case 'firstname':
        return 'First Name';
      case 'location':
        return 'Location';
      case 'scheduleddate':
        return 'Scheduled Date';
      case 'scheduledtime':
        return 'Scheduled Time';
      case 'referencename':
        return 'Reference Name';
      case 'secretaryname':
        return 'Secretary Name';
      case 'company':
        return 'Company';
      case 'designation':
        return 'Designation';
      case 'people':
        return 'Number of People';
      case 'ji':
        return 'Honorific';
      default:
        return key; // Return the key itself if no specific label is defined
    }
  }

  // Getter methods for easy access to appointment data
  Map<String, dynamic> get appointmentData => _appointmentData;
  String get firstName => _firstName;
  String get fullName => _fullName;
  String get appointmentId => _appointmentId;
  String get location => _location;
  String get scheduledDate => _scheduledDate;
  String get scheduledTime => _scheduledTime;
  String get referenceName => _referenceName;
  String get secretaryName => _secretaryName;
  String get company => _company;
  String get designation => _designation;
  String get appointeeMobile => _appointeeMobile;
  String get referenceMobile => _referenceMobile;

  // Example method showing how to access appointment data in message content
  void _insertAppointmentDataIntoMessage() {
    final currentText = _smsContentController.text;
    final cursorPosition = _smsContentController.selection.baseOffset;
    
    // Example: Insert appointment ID at cursor position
    final newText = currentText.substring(0, cursorPosition) + 
                   'Appointment ID: $appointmentId' + 
                   currentText.substring(cursorPosition);
    
    _smsContentController.text = newText;
    _smsContentController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPosition + 'Appointment ID: $appointmentId'.length),
    );
  }

  // Method to get all available appointment data as a formatted string
  String _getAppointmentDataSummary() {
    return '''
Appointment Details:
- ID: $appointmentId
- First Name: $firstName
- Full Name: $fullName
- Location: $location
- Date: $scheduledDate
- Time: $scheduledTime
- Company: $company
- Designation: $designation
- Secretary: $secretaryName
- Reference: $referenceName
- Mobile: $appointeeMobile
- Reference Mobile: $referenceMobile
''';
  }

  Future<void> _loadSmsTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ActionService.getAllSmsTemplates(isActive: true);
      
      if (result['success']) {
        final templates = result['data'] as List<dynamic>;
        setState(() {
          smsTemplates = templates.cast<Map<String, dynamic>>();
          smsTemplateNames = templates.map((template) => template['name']?.toString() ?? '').toList();
          
          // Select the first template by default if available
          if (smsTemplateNames.isNotEmpty) {
            _selectedTemplate = smsTemplateNames.first;
            _smsContentController.text = _getTemplateContent(_selectedTemplate!);
          }
        });
      } else {
        // If API fails, use empty list
        setState(() {
          smsTemplateNames = [];
        });
      }
    } catch (error) {
      // If error, show empty list
      setState(() {
        smsTemplateNames = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDefaultSmsContent() {
    return 'Dear $firstName, your appointment (ID: $appointmentId) has been confirmed. Location: $location, Date: $scheduledDate, Time: $scheduledTime.';
  }

  void _onTemplateChanged(String? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null) {
        _smsContentController.text = _getTemplateContent(template);
      }
    });
  }

  String _getTemplateContent(String template) {
    // First try to find the template in the API data
    final apiTemplate = smsTemplates.firstWhere(
      (t) => t['name']?.toString() == template,
      orElse: () => <String, dynamic>{},
    );

    if (apiTemplate.isNotEmpty) {
      String content = apiTemplate['content']?.toString() ?? '';
      return _replacePlaceholders(content);
    }

    // Fallback to hardcoded templates
    return _getDefaultSmsContent();
  }

  String _replacePlaceholders(String content) {
    final Map<String, String> placeholderMap = {
      'firstname': _firstName,
      'fullname': _fullName,
      'appointmentId': _appointmentId,
      'AID': _appointmentId,
      'location': _location,
      'scheduledDate': _scheduledDate,
      'scheduledTime': _scheduledTime,
      'referenceName': _referenceName,
      'secretaryName': _secretaryName,
      'company': _company,
      'designation': _designation,
      'people': _getPeopleCount().toString(),
      'ji': _getJiTitle(),
      // Empty placeholders for pending appointments
      'date': '', // Empty since appointment is pending
      'time': '', // Empty since appointment is pending
      'sms_app_location': '', // Empty since appointment is pending
    };

    String replacer(Match match) {
      final key = match.group(1) ?? '';
      
      // Handle all $ prefixed placeholders (same as regular placeholders)
      if (key.startsWith(r'$')) {
        final normalizedKey = key.substring(1); // Remove the $ prefix
        final value = placeholderMap[normalizedKey];
        return value ?? match.group(0)!;
      }
      
      // Handle regular placeholders (without $)
      final value = placeholderMap[key];
      
      return value ?? match.group(0)!;
    }

    final regex = RegExp(r'\{(\$?[a-zA-Z0-9_]+)\}');
    return content.replaceAllMapped(regex, replacer);
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Get selected template ID if a template is selected
      String? selectedTemplateId;
      if (_selectedTemplate != null) {
        final selectedTemplate = smsTemplates.firstWhere(
          (template) => template['name']?.toString() == _selectedTemplate,
          orElse: () => <String, dynamic>{},
        );
        selectedTemplateId = selectedTemplate['_id']?.toString();
      }

      // Prepare template data for placeholder replacement
      Map<String, dynamic> templateData = {
        'firstname': _firstName,
        'fullname': _fullName,
        'appointmentId': _appointmentId,
        'AID': _appointmentId,
        'location': _location,
        'scheduledDate': _scheduledDate,
        'scheduledTime': _scheduledTime,
        'referenceName': _referenceName,
        'secretaryName': _secretaryName,
        'company': _company,
        'designation': _designation,
        'people': _getPeopleCount(),
        'ji': _getJiTitle(),
      };

      final result = await ActionService.sendAppointmentSms(
        appointeeMobile: _appointeeMobile,
        referenceMobile: _referenceMobile,
        useAppointee: _appointeeMobileChecked,
        useReference: _referenceMobileChecked,
        otherSms: _otherSmsController.text.trim().isNotEmpty ? _otherSmsController.text.trim() : null,
        selectedTemplateId: selectedTemplateId,
        smsContent: _smsContentController.text.trim(),
        templateData: templateData,
      );

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'SMS sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Close the form
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send SMS'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  'Appointee Mobile: ${_appointeeMobile}',
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
                  'Reference Mobile: ${_referenceMobile}',
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
              hintText: 'Other SMS Numbers',
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
            hint: _isLoading ? const Text('Loading templates...') : const Text('Select Template'),
            items: smsTemplateNames.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Text(template),
              );
            }).toList(),
            onChanged: _isLoading ? null : _onTemplateChanged,
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
            'Available placeholders: {firstname}, {fullname}, {appointmentId}, {AID}, {people}, {ji}, {location}, {scheduledDate}, {scheduledTime}, {referenceName}, {secretaryName}, {company}, {designation}',
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
                  onPressed: _isLoading ? null : _sendSms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Send'),
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