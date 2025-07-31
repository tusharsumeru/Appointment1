import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class EmailForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onSend;
  final VoidCallback? onClose;

  const EmailForm({
    Key? key,
    required this.appointment,
    this.onSend,
    this.onClose,
  }) : super(key: key);

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final TextEditingController _ccEmailController = TextEditingController();
  final TextEditingController _bccEmailController = TextEditingController();
  final TextEditingController _darshanLineDateController = TextEditingController();
  final TextEditingController _darshanLineTimeController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailTemplateController = TextEditingController();
  
  // Focus nodes for keyboard management
  final FocusNode _ccEmailFocus = FocusNode();
  final FocusNode _bccEmailFocus = FocusNode();
  final FocusNode _darshanLineDateFocus = FocusNode();
  final FocusNode _darshanLineTimeFocus = FocusNode();
  final FocusNode _emailSubjectFocus = FocusNode();
  final FocusNode _emailTemplateFocus = FocusNode();
  
  // Form values
  String _selectedTemplate = '';
  bool _includeAppointeeEmail = true;
  bool _includeReferenceEmail = false;
  bool _showDarshanLineFields = false;
  
  // Email templates from JSON
  List<Map<String, String>> _emailTemplates = [
    {'value': '', 'label': 'Select Template'},
    {'value': '1', 'label': 'APPOINTMENT CONFIRMATION'},
    {'value': '2', 'label': 'APPOINTMENT RESCHEDULED'},
    {'value': '3', 'label': 'APPOINTMENT REMINDER'},
    {'value': '5', 'label': 'DARSHAN LINE'},
    {'value': '10', 'label': 'EMAIL FORWARD REQUEST'},
    {'value': '13', 'label': 'GUEST GUIDELINES'},
    {'value': '14', 'label': 'INFORM VDS'},
    {'value': '15', 'label': 'UNABLE TO PROCESS YOUR REQUEST'},
    {'value': '21', 'label': 'Customized Email'},
    {'value': '38', 'label': 'TB R/S Special Enclosure'},
    {'value': '39', 'label': 'TB R/S Rescheduled'},
    {'value': '40', 'label': 'Europe - Appointment & TBS confirmation'},
    {'value': '41', 'label': 'Europe - Appointment & TBS Rescheduling'},
    {'value': '42', 'label': 'SATSANG BACKSTAGE'},
  ];
  
  // Template data from JSON
  Map<String, Map<String, dynamic>> _templateData = {
    '1': {
      'subject': r'Confirmation of your appointment {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your appointment request {$AID} has been confirmed. Please find the details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

{$email_note}'''
    },
    '2': {
      'subject': r'IMP: Appointment rescheduled {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your appointment {$AID} has been rescheduled. Please find the new details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

{$email_note}'''
    },
    '3': {
      'subject': r'Gentle reminder of your appointment {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is a reminder email. Kindly note that your appointment request {$AID} is scheduled for today. Please find the details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

{$email_note}'''
    },
    '5': {
      'subject': r'Response to your appointment request {$AID} with Gurudev',
      'content': r'''Dear {$full_name} {$ji},

You can come for Gurudev's darshan at {$time} on {$date}. Kindly collect your Darshan pass from Secretariat office on the same day.

Requested for: {$no_people}
Area: {$area}
Location: {$app_location}

NOTE: Please note that our official photographer will be taking your pictures with Gurudev which will be uploaded on www.soulbook.me.'''
    },
    '10': {
      'subject': r'Inputs required for this request',
      'content': r'''Dear One,

Can you please provide inputs for following appointment request.

Name: {$full_name}
Designation: {$designation}
Mobile: {$mobile}
Email: {$email}
Reference Name: {$ref_by}
Reference Phone: {$ref_phone}
Subject: {$subject}
Purpose: {$purpose}
Preferred date: {$date}
Number of People: {$no_people}

NOTE: Please share your inputs on secretariat@artofliving.org, emails to this ID are not monitored.'''
    },
    '13': {
      'subject': r'Appointment guest guidelines',
      'content': r'''Dear {$ref_name} {$ji},

Your appointment with Gurudev (for {$appointee_name}) is scheduled on {$date} at {$time}. Total People: {$no_people}

Kindly come to secretariat office 15 mins prior to allotted time and meet with Shabnam/Chandrakant who will guide you.

We request you to ensure that the guests have had an ashram tour and have watched Love moves the world prior to Gurudev's appointment.

NOTE: Videography or photography (using mobile phones) would not be needed from your side as the Art of Living official photographer will take pictures which will be emailed the following day of the appointment.'''
    },
    '14': {
      'subject': r'Information regarding Pujas & Homas on your special occasion',
      'content': r'''Dear {$appointee_name} {$ji},

The Vaidic Dharma Sansthan desk (in cc) organizes Pujas & Homas for various occasions. You may contact them directly in case you are interested. You may contact VDS via phone on +91 9538186844 (M) / +91 80 67262639 (O).'''
    },
    '15': {
      'subject': r'Unable to process your appointment request',
      'content': r'''Dear {$appointee_name} {$ji},

We are unable to process your request at the moment. It could be due to the following reason(s):

1. Purpose not clear - We will need complete details of the reason for your appointment stating the context of the issue and the questions you have for Gurudev.

2. Details of contact person not complete - Please make sure the name, designation and contact details of the person wanting to meet and the reference person are clearly filled.

Request you to kindly re-fill in the appointment request.'''
    },
    '21': {
      'subject': r'Art of Living, Appointment',
      'content': r'''Dear {$full_name} {$ji},

This is a customized email for your appointment.

{$email_note}'''
    },
    '38': {
      'subject': r'IMP: Appointment {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your request {$AID} has been confirmed. Please show this message to the security guard near front enclosure at Shiva Temple.

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

{$email_note}'''
    },
    '39': {
      'subject': r'IMP: Appointment {$AID} Rescheduled',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your request {$AID} has been rescheduled. Please find the details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

{$email_note}'''
    },
    '40': {
      'subject': r'Confirmation of your appointment {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your appointment request {$AID} has been confirmed. Please find the details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

NOTE: Please come to the above location 15 minutes prior to your scheduled time.

Warm Regards,
The Art of Living Team Europe'''
    },
    '41': {
      'subject': r'IMP: Appointment rescheduled {$AID}',
      'content': r'''Dear {$full_name} {$ji},

This is to inform you that your appointment request {$AID} has been rescheduled. Please find the details below:

Date: {$date}
Time: {$time}
Requested for: {$no_people}
Location: {$app_location}

NOTE: Please come to the above location 15 minutes prior to your scheduled time.

Warm Regards,
The Art of Living Team Europe'''
    },
    '42': {
      'subject': r'Response to appointment request {$AID} with Gurudev',
      'content': r'''Dear {$full_name} {$ji},

An appointment may not be possible. However, you may take blessings from Gurudev when he enters/exits satsang. Please contact Shabnam/Chandrakanth at Secretariat office 15 mins before beginning of Satsang on that day.

Ps: The Vaidic Dharma Sansthan desk (in cc) organizes pujas & homas for various occasions. You may contact them directly in case you are interested. You may contact VDS via phone on - +91 9538186844 (M) / +91 80 67262639 (O).'''
    },
  };

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointeeEmail() {
    return widget.appointment['email']?.toString() ?? '';
  }

  String _getReferenceEmail() {
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['email']?.toString() ?? '';
    }
    return '';
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _loadEmailTemplates();
  // }

  // Future<void> _loadEmailTemplates() async {
  //   try {
  //     // Load JSON file
  //     final String jsonString = await rootBundle.loadString('emailtemplate.json');
  //     final Map<String, dynamic> jsonData = json.decode(jsonString);
  //     
  //     // Get email templates
  //     final List<dynamic> emailTemplates = jsonData['Email'] ?? [];
  //     
  //     // Clear existing templates and add default
  //     _emailTemplates = [{'value': '', 'label': 'Select Template'}];
  //     
  //     // Add templates from JSON
  //     for (var template in emailTemplates) {
  //       final String id = template['id'].toString();
  //       final String name = template['template_name'];
  //       final int status = template['status'] ?? 0;
  //       
  //       // Only add active templates (status = 1)
  //       if (status == 1) {
  //         _emailTemplates.add({
  //           'value': id,
  //           'label': name,
  //         });
  //         
  //         // Store template data for later use
  //         _templateData[id] = {
  //           'subject': template['template_subject'] ?? '',
  //           'content': template['template_data'] ?? '',
  //         };
  //       }
  //     }
  //     
  //     setState(() {});
  //   } catch (e) {
  //     print('Error loading email templates: $e');
  //   }
  // }

  @override
  void dispose() {
    _ccEmailController.dispose();
    _bccEmailController.dispose();
    _darshanLineDateController.dispose();
    _darshanLineTimeController.dispose();
    _emailSubjectController.dispose();
    _emailTemplateController.dispose();
    _scrollController.dispose();
    
    // Dispose focus nodes
    _ccEmailFocus.dispose();
    _bccEmailFocus.dispose();
    _darshanLineDateFocus.dispose();
    _darshanLineTimeFocus.dispose();
    _emailSubjectFocus.dispose();
    _emailTemplateFocus.dispose();
    
    super.dispose();
  }

  void _onTemplateChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedTemplate = value;
        _showDarshanLineFields = value == '5'; // Show darshan line fields for DARSHAN LINE template
      });
    }
  }

  String _replacePlaceholders(String text) {
    String result = text;
    
    // Extract data from appointment object
    final appointmentId = _getAppointmentId();
    final fullName = _getFullName();
    final ji = _getJi();
    final date = _getAppointmentDate();
    final time = _getAppointmentTime();
    final noPeople = _getNumberOfPeople();
    final appLocation = _getAppointmentLocation();
    final emailNote = _getEmailNote();
    final area = _getArea();
    final designation = _getDesignation();
    final mobile = _getMobile();
    final email = _getEmail();
    final refBy = _getReferenceBy();
    final refPhone = _getReferencePhone();
    final subject = _getSubject();
    final purpose = _getPurpose();
    final refName = _getReferenceName();
    final appointeeName = _getAppointeeName();
    
    // Replace placeholders with dynamic values
    result = result.replaceAll('{\$AID}', appointmentId);
    result = result.replaceAll('{\$full_name}', fullName);
    result = result.replaceAll('{\$ji}', ji);
    result = result.replaceAll('{\$date}', date);
    result = result.replaceAll('{\$time}', time);
    result = result.replaceAll('{\$no_people}', noPeople);
    result = result.replaceAll('{\$app_location}', appLocation);
    result = result.replaceAll('{\$email_note}', emailNote);
    result = result.replaceAll('{\$area}', area);
    result = result.replaceAll('{\$designation}', designation);
    result = result.replaceAll('{\$mobile}', mobile);
    result = result.replaceAll('{\$email}', email);
    result = result.replaceAll('{\$ref_by}', refBy);
    result = result.replaceAll('{\$ref_phone}', refPhone);
    result = result.replaceAll('{\$subject}', subject);
    result = result.replaceAll('{\$purpose}', purpose);
    result = result.replaceAll('{\$ref_name}', refName);
    result = result.replaceAll('{\$appointee_name}', appointeeName);
    result = result.replaceAll('{\$appointeeName}', appointeeName);
    
    return result;
  }

  // Helper methods to extract data from appointment object
  String _getFullName() {
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      return createdBy['fullName']?.toString() ?? '';
    }
    return widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getJi() {
    // Add "Ji" suffix for respectful address
    return 'Ji';
  }

  String _getAppointmentDate() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final date = scheduledDateTime['date']?.toString();
      if (date != null) {
        final dateTime = DateTime.tryParse(date);
        if (dateTime != null) {
          return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
        }
      }
    }
    
    // Fallback to preferred date range
    final preferredDateRange = widget.appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate']?.toString();
      if (fromDate != null) {
        final dateTime = DateTime.tryParse(fromDate);
        if (dateTime != null) {
          return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
        }
      }
    }
    
    return 'TBD';
  }

  String _getAppointmentTime() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final time = scheduledDateTime['time']?.toString();
      if (time != null) {
        // Convert 24-hour format to 12-hour format
        final timeParts = time.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = timeParts[1];
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
        }
        return time;
      }
    }
    return 'TBD';
  }

  String _getNumberOfPeople() {
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is List) {
      int totalCount = 1; // Include main applicant
      for (final group in accompanyUsers) {
        if (group is Map<String, dynamic>) {
          final users = group['users'];
          if (users is List) {
            totalCount += users.length;
          }
        }
      }
      return totalCount.toString();
    } else if (accompanyUsers is Map<String, dynamic>) {
      return (accompanyUsers['numberOfUsers'] ?? 1).toString();
    }
    return '1';
  }

  String _getAppointmentLocation() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      return scheduledDateTime['venueLabel']?.toString() ?? '';
    }
    
    final venue = widget.appointment['venue'];
    if (venue is Map<String, dynamic>) {
      return venue['name']?.toString() ?? '';
    }
    
    return 'Bangalore Ashram';
  }

  String _getEmailNote() {
    return 'Please arrive 15 minutes before your scheduled time.';
  }

  String _getArea() {
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    if (scheduledDateTime is Map<String, dynamic>) {
      final venueLabel = scheduledDateTime['venueLabel']?.toString() ?? '';
      if (venueLabel.contains('Satsang')) {
        return 'Satsang Hall';
      } else if (venueLabel.contains('Gurukul')) {
        return 'Gurukul';
      }
    }
    return 'Main Hall';
  }

  String _getDesignation() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['userCurrentCompany']?.toString() ?? 
           'Not specified';
  }

  String _getMobile() {
    final phoneNumber = widget.appointment['phoneNumber'];
    if (phoneNumber is Map<String, dynamic>) {
      final countryCode = phoneNumber['countryCode']?.toString() ?? '';
      final number = phoneNumber['number']?.toString() ?? '';
      return '$countryCode $number';
    }
    return 'Not provided';
  }

  String _getEmail() {
    return widget.appointment['email']?.toString() ?? 'Not provided';
  }

  String _getReferenceBy() {
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['name']?.toString() ?? '';
    }
    return 'Not specified';
  }

  String _getReferencePhone() {
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final phoneNumber = referencePerson['phoneNumber'];
      if (phoneNumber is Map<String, dynamic>) {
        final countryCode = phoneNumber['countryCode']?.toString() ?? '';
        final number = phoneNumber['number']?.toString() ?? '';
        return '$countryCode $number';
      }
    }
    return 'Not provided';
  }

  String _getSubject() {
    return widget.appointment['appointmentSubject']?.toString() ?? 'Meeting with Gurudev';
  }

  String _getPurpose() {
    return widget.appointment['appointmentPurpose']?.toString() ?? 'Not specified';
  }

  String _getReferenceName() {
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      return referencePerson['name']?.toString() ?? '';
    }
    return 'Not specified';
  }

  String _getAppointeeName() {
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      return createdBy['fullName']?.toString() ?? '';
    }
    return widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _sendEmail() {
    if (_formKey.currentState!.validate()) {
      // Here you would typically send the email data to your backend
      widget.onSend?.call();
      Navigator.of(context).pop();
    }
  }

  // Dismiss keyboard when tapping outside
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // Scroll to focused field
  void _scrollToFocusedField(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.hasFocus) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Adjust for keyboard
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipients Section Header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Recipients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      
                      // Appointee Email Checkbox
                      _buildCheckbox(
                        value: _includeAppointeeEmail,
                        onChanged: (value) => setState(() => _includeAppointeeEmail = value ?? true),
                        title: 'Appointee Email: ${_getAppointeeEmail()}',
                      ),
                      
                      // Reference Email Checkbox
                      _buildCheckbox(
                        value: _includeReferenceEmail,
                        onChanged: (value) => setState(() => _includeReferenceEmail = value ?? false),
                        title: 'Reference Email: ${_getReferenceEmail()}',
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Settings Section Header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Email Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      
                      // CC Email Field
                      TextFormField(
                        controller: _ccEmailController,
                        focusNode: _ccEmailFocus,
                        onTap: () => _scrollToFocusedField(_ccEmailFocus),
                        decoration: const InputDecoration(
                          labelText: 'CC',
                          hintText: 'CC Email ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                          helperText: 'Note: Please Add comma separated email id',
                          helperStyle: TextStyle(color: Colors.red),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // BCC Email Field
                      TextFormField(
                        controller: _bccEmailController,
                        focusNode: _bccEmailFocus,
                        onTap: () => _scrollToFocusedField(_bccEmailFocus),
                        decoration: const InputDecoration(
                          labelText: 'BCC',
                          hintText: 'BCC Email ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                          helperText: 'Note: Please Add comma separated email id',
                          helperStyle: TextStyle(color: Colors.red),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Template Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedTemplate.isEmpty ? null : _selectedTemplate,
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value ?? '';
                            // Populate subject and content if template is selected
                            if (value != null && value.isNotEmpty && _templateData.containsKey(value)) {
                              final template = _templateData[value]!;
                              _emailSubjectController.text = _replacePlaceholders(template['subject'] ?? '');
                              _emailTemplateController.text = _replacePlaceholders(template['content'] ?? '');
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email Template',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        isExpanded: true,
                        items: _emailTemplates.map((template) {
                          return DropdownMenuItem<String>(
                            value: template['value'],
                            child: Text(
                              template['label']!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subject Field
                      TextFormField(
                        controller: _emailSubjectController,
                        focusNode: _emailSubjectFocus,
                        onTap: () => _scrollToFocusedField(_emailSubjectFocus),
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Enter email subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email subject';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email Template Content
                      TextFormField(
                        controller: _emailTemplateController,
                        focusNode: _emailTemplateFocus,
                        onTap: () => _scrollToFocusedField(_emailTemplateFocus),
                        decoration: const InputDecoration(
                          labelText: 'Email Template',
                          hintText: 'Enter email content here...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email content';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _dismissKeyboard();
                        widget.onClose?.call();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _dismissKeyboard();
                        _sendEmail();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
} 