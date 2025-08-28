import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import '../../action/action.dart';

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
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailTemplateController = TextEditingController();
  final TextEditingController _templateDisplayController = TextEditingController();
  
  // Focus nodes for keyboard management
  final FocusNode _ccEmailFocus = FocusNode();
  final FocusNode _bccEmailFocus = FocusNode();
  final FocusNode _emailSubjectFocus = FocusNode();
  final FocusNode _emailTemplateFocus = FocusNode();
  
  // Form values
  String _selectedTemplate = '';
  bool _includeAppointeeEmail = true;
  bool _includeReferenceEmail = false;
  bool _showRescheduleForm = false;
  DateTime? _newDate;
  TimeOfDay? _newTime;
  String _newVenue = '';
  String _newVenueName = '';
  
  // Email templates from API
  List<Map<String, String>> _emailTemplates = [
    {'value': '', 'label': 'Select Template'},
  ];
  
  // Template data from API
  Map<String, Map<String, dynamic>> _templateData = {};
  
  // Loading state
  bool _isLoadingTemplates = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmailTemplates();
  }

  Future<void> _loadEmailTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _errorMessage = null;
    });

    try {
      // Get email templates from API
      final result = await ActionService.getAllEmailTemplates(
        isActive: true, // Only get active templates
      );

      // Debug: Test HTML conversion (uncomment to test)
      // _testHtmlConversion();

      if (result['success']) {
        final List<dynamic> templates = result['data'] ?? [];
        
        // Clear existing templates
        _emailTemplates = [];
        _templateData.clear();
        
        // Add templates from API
        for (var template in templates) {
          final String id = template['_id']?.toString() ?? '';
          final String name = template['name'] ?? template['templateName'] ?? 'Unknown Template';
          final bool isActive = template['isActive'] ?? true;
          
          // Debug logging for each template
          print('📋 Template Found:');
          print('  - ID: $id');
          print('  - Name: "$name"');
          print('  - Is Active: $isActive');
          
          // Only add active templates
          if (isActive && id.isNotEmpty) {
            _emailTemplates.add({
              'value': id,
              'label': name,
            });
            
            // Store template data for later use
            _templateData[id] = {
              'subject': template['subject'] ?? template['templateSubject'] ?? '',
              'content': _htmlToRichText(template['content'] ?? template['templateData'] ?? template['body'] ?? ''),
              'originalHtml': template['content'] ?? template['templateData'] ?? template['body'] ?? '', // Store original HTML for backend
              'category': template['category'] ?? '',
              'tags': template['tags'] ?? [],
              'region': template['region'] ?? '',
            };
          }
        }
        
        // Debug logging for final template list
        print('📚 Final Template List:');
        for (var template in _emailTemplates) {
          print('  - ${template['value']}: "${template['label']}"');
        }
        
        setState(() {});
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load email templates';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading email templates: $e';
      });
    } finally {
      setState(() {
        _isLoadingTemplates = false;
      });
    }
  }



  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  String _getAppointmentName() {
    // Use createdBy.fullName to match backend logic exactly
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      final createdByFullName = createdBy['fullName']?.toString();
      if (createdByFullName != null && createdByFullName.isNotEmpty) {
        return createdByFullName;
      }
    }
    
    // If createdBy.fullName is not available, use userFullName as fallback
    final userFullName = widget.appointment['userFullName']?.toString();
    if (userFullName != null && userFullName.isNotEmpty) {
      return userFullName;
    }
    
    // Try multiple possible fields for the name
    final fullName = widget.appointment['fullName']?.toString();
    final name = widget.appointment['name']?.toString();
    final userName = widget.appointment['userName']?.toString();
    final userCurrentDesignation = widget.appointment['userCurrentDesignation']?.toString();
    final email = widget.appointment['email']?.toString();
    
    return fullName ?? name ?? userName ?? userCurrentDesignation ?? email ?? 'Unknown';
  }

  String _getAppointeeEmail() {
    // Check if this is a guest appointment first
    final appointmentType = widget.appointment['appointmentType']?.toString();
    final guestInformation = widget.appointment['guestInformation'];
    
    if (appointmentType == 'guest' && guestInformation is Map<String, dynamic>) {
      final guestEmail = guestInformation['emailId']?.toString();
      if (guestEmail != null && guestEmail.isNotEmpty) {
        return guestEmail;
      }
    }
    
    // Check if this is a quick appointment
    final apptType = widget.appointment['appt_type']?.toString();
    final quickApt = widget.appointment['quick_apt'];
    
    if (apptType == 'quick' && quickApt is Map<String, dynamic>) {
      final optional = quickApt['optional'];
      if (optional is Map<String, dynamic>) {
        final email = optional['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    }
    
    // Try multiple possible fields for the appointee email
    // Primary: email field (from the actual data structure)
    final email = widget.appointment['email']?.toString();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    
    // Secondary: userEmail field
    final userEmail = widget.appointment['userEmail']?.toString();
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    }
    
    // Fallback: appointeeEmail field
    final appointeeEmail = widget.appointment['appointeeEmail']?.toString();
    if (appointeeEmail != null && appointeeEmail.isNotEmpty) {
      return appointeeEmail;
    }
    
    return '';
  }

  String _getReferenceEmail() {
    // Try multiple possible fields for the reference email
    // Primary: referencePerson.email (from the actual data structure)
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final email = referencePerson['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    
    // Secondary: referenceEmail field
    final referenceEmail = widget.appointment['referenceEmail']?.toString();
    if (referenceEmail != null && referenceEmail.isNotEmpty) {
      return referenceEmail;
    }
    
    // Fallback: other possible field names
    final refEmail = widget.appointment['refEmail']?.toString();
    if (refEmail != null && refEmail.isNotEmpty) {
      return refEmail;
    }
    
    final refByEmail = widget.appointment['refByEmail']?.toString();
    if (refByEmail != null && refByEmail.isNotEmpty) {
      return refByEmail;
    }
    
    final referenceByEmail = widget.appointment['referenceByEmail']?.toString();
    if (referenceByEmail != null && referenceByEmail.isNotEmpty) {
      return referenceByEmail;
    }
    
    return '';
  }

  String _getReferenceName() {
    // Try multiple possible fields for the reference name
    // Primary: referencePerson.name (from the actual data structure)
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final name = referencePerson['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Secondary: other possible field names
    final refName = widget.appointment['refName']?.toString();
    if (refName != null && refName.isNotEmpty) {
      return refName;
    }
    
    final refBy = widget.appointment['refBy']?.toString();
    if (refBy != null && refBy.isNotEmpty) {
      return refBy;
    }
    
    final referenceName = widget.appointment['referenceName']?.toString();
    if (referenceName != null && referenceName.isNotEmpty) {
      return referenceName;
    }
    
    final referenceBy = widget.appointment['referenceBy']?.toString();
    if (referenceBy != null && referenceBy.isNotEmpty) {
      return referenceBy;
    }
    
    return 'Unknown Reference';
  }

  String _getReferencePhone() {
    // Try multiple possible fields for the reference phone
    // Primary: referencePerson.phoneNumber (from the actual data structure)
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final phoneNumber = referencePerson['phoneNumber'];
      if (phoneNumber is Map<String, dynamic>) {
        final countryCode = phoneNumber['countryCode']?.toString() ?? '';
        final number = phoneNumber['number']?.toString() ?? '';
        if (countryCode.isNotEmpty && number.isNotEmpty) {
          return '$countryCode $number';
        }
      }
      
      // Handle phoneNumber as a string
      if (phoneNumber is String && phoneNumber.isNotEmpty) {
        return phoneNumber;
      }
    }
    
    // Secondary: other possible field names
    final refPhone = widget.appointment['refPhone']?.toString();
    if (refPhone != null && refPhone.isNotEmpty) {
      return refPhone;
    }
    
    final referencePhone = widget.appointment['referencePhone']?.toString();
    if (referencePhone != null && referencePhone.isNotEmpty) {
      return referencePhone;
    }
    
    final refByPhone = widget.appointment['refByPhone']?.toString();
    if (refByPhone != null && refByPhone.isNotEmpty) {
      return refByPhone;
    }
    
     return '';
   }

         String _getNumberOfPeople() {
    // Use the same source as appointment_card.dart
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      final numberOfUsers = accompanyUsers['numberOfUsers'];
      if (numberOfUsers != null) {
        return numberOfUsers.toString();
      }
    }
    
    // Fallback to other fields if accompanyUsers not available
    final noOfPeople = widget.appointment['noOfPeople']?.toString();
    if (noOfPeople != null && noOfPeople.isNotEmpty) {
      return noOfPeople;
    }
    
    final numberOfPeople = widget.appointment['numberOfPeople']?.toString();
    if (numberOfPeople != null && numberOfPeople.isNotEmpty) {
      return numberOfPeople;
    }
    
    final peopleCount = widget.appointment['peopleCount']?.toString();
    if (peopleCount != null && peopleCount.isNotEmpty) {
      return peopleCount;
    }
    
    final count = widget.appointment['count']?.toString();
    if (count != null && count.isNotEmpty) {
      return count;
    }
    
    // Return empty string if no data found
    return '';
  }

  bool _isRescheduleTemplate() {
    // Simple check: if template ID matches the reschedule template ID, show the card
    final isReschedule = _selectedTemplate == '6885fbc5d64696d83a0d7f16';
    print('🔍 RESCHEDULE CHECK: $_selectedTemplate == 6885fbc5d64696d83a0d7f16 = $isReschedule');
    return isReschedule;
  }

  Future<void> _selectNewDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _newDate) {
      setState(() {
        _newDate = picked;
      });
    }
  }

  Future<void> _selectNewTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _newTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _newTime) {
      setState(() {
        _newTime = picked;
      });
    }
  }

  // Helper method to format time consistently for backend
  String _formatTimeForBackend(TimeOfDay? time) {
    if (time == null) return '';
    
    // Format as HH:MM (24-hour format) to match existing time format
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showVenueBottomSheet() {
    // List of venues like in the image
    final List<String> venues = [
      'Secretariat Office A1',
      'Special Enclosure - Shiva Temple',
      'Yoga School',
      'Radha Kunj',
      'Shiva Temple',
      'Satsang Backstage',
      'Gurukul',
      'Pooja Backstage',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Venue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return ListTile(
                      title: Text(venue),
                      onTap: () {
                        setState(() {
                          _newVenue = venue; // Use venue name as ID for simplicity
                          _newVenueName = venue;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getRecipientEmails() {
    List<String> recipients = [];
    
    // Add appointee email if selected
    if (_includeAppointeeEmail) {
      final appointeeEmail = _getAppointeeEmail();
      if (appointeeEmail.isNotEmpty) {
        recipients.add(appointeeEmail);
      }
    }
    
    // Add reference email if selected
    if (_includeReferenceEmail) {
      final referenceEmail = _getReferenceEmail();
      if (referenceEmail.isNotEmpty) {
        recipients.add(referenceEmail);
      }
    }
    
    return recipients;
  }

  List<String> _getAllRecipientsIncludingCC() {
    List<String> allRecipients = [];
    
    // Add main recipients
    allRecipients.addAll(_getRecipientEmails());
    
    // Add CC emails (as a fallback since backend might not handle CC separately)
    allRecipients.addAll(_getCCEmails());
    
    return allRecipients;
  }

  List<String> _getCCEmails() {
    if (_ccEmailController.text.isEmpty) {
      return [];
    }
    
    return _ccEmailController.text
        .split(',')
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty && RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email))
        .toList();
  }

  List<String> _getBCCEmails() {
    if (_bccEmailController.text.isEmpty) {
      return [];
    }
    
    return _bccEmailController.text
        .split(',')
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty && RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email))
        .toList();
  }

  Map<String, dynamic> _getEmailData() {
    // Get the original HTML content for the selected template
    String originalHtmlContent = '';
    if (_selectedTemplate.isNotEmpty && _templateData.containsKey(_selectedTemplate)) {
      final templateData = _templateData[_selectedTemplate];
      if (templateData != null) {
        originalHtmlContent = templateData['originalHtml'] ?? '';
      }
    }
    
    // Apply placeholder replacements to the original HTML content
    String processedHtmlContent = _replacePlaceholdersInHtml(originalHtmlContent);
    
    // Use the edited content from the controller if available, otherwise use original
    String finalContent = _emailTemplateController.text.isNotEmpty 
        ? _emailTemplateController.text 
        : originalHtmlContent;
    
    return {
      'recipients': _getRecipientEmails(),
      'cc': _getCCEmails(),
      'bcc': _getBCCEmails(),
      'subject': _emailSubjectController.text,
      'content': originalHtmlContent, // Send original template content with placeholders
      'templateId': _selectedTemplate.isNotEmpty ? _selectedTemplate : null,
      'appointmentId': _getAppointmentId(),
      'includeAppointeeEmail': _includeAppointeeEmail,
      'includeReferenceEmail': _includeReferenceEmail,
      'darshanLineDate': widget.appointment['scheduledDateTime']?['date']?.toString() ?? '',
      'darshanLineTime': widget.appointment['scheduledDateTime']?['time']?.toString() ?? '',
      'rescheduleDate': _newDate?.toIso8601String(),
      'rescheduleTime': _formatTimeForBackend(_newTime),
      'rescheduleVenue': _newVenue,
      'rescheduleVenueName': _newVenueName,
    };
  }

  @override
  void dispose() {
    _ccEmailController.dispose();
    _bccEmailController.dispose();
    _emailSubjectController.dispose();
    _emailTemplateController.dispose();
    _templateDisplayController.dispose();
    _scrollController.dispose();
    
    // Dispose focus nodes
    _ccEmailFocus.dispose();
    _bccEmailFocus.dispose();
    _emailSubjectFocus.dispose();
    _emailTemplateFocus.dispose();
    
    super.dispose();
  }

  void _onTemplateChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedTemplate = value;
        // Update display controller
        final selectedTemplate = _emailTemplates.firstWhere(
          (template) => template['value'] == value,
          orElse: () => {'value': '', 'label': 'Select Template'},
        );
        _templateDisplayController.text = selectedTemplate['label']!;
        

        
        // Check if this is the reschedule template
        _showRescheduleForm = _isRescheduleTemplate();
        print('📧 TEMPLATE SELECTED: $value');
        print('🔄 SHOW RESCHEDULE FORM: $_showRescheduleForm');
        
        // Clear reschedule form if not reschedule template
        if (!_showRescheduleForm) {
          _newDate = null;
        }
        
        // Populate email template controller with processed content
        if (_templateData.containsKey(value)) {
          final templateData = _templateData[value];
          if (templateData != null) {
            final originalHtml = templateData['originalHtml'] ?? '';
            final processedContent = _replacePlaceholdersInHtml(originalHtml);
            _emailTemplateController.text = processedContent;
          }
        }
      });
    }
  }

  String _replacePlaceholders(String text) {
    String result = text;
    
    // First convert HTML to plain text if it contains HTML
    if (_containsHtml(text)) {
      result = _htmlToPlainText(text);
    }
    
    // Get appointment data
    final appointment = widget.appointment;
    final appointmentId = _getAppointmentId();
    final fullName = _getAppointmentName();
    final email = _getAppointeeEmail();
    final numberOfPeople = _getNumberOfPeople();
    
    // Replace placeholders with actual appointment data
    result = result.replaceAll('{\$AID}', appointmentId);
    result = result.replaceAll('{\$full_name}', fullName);
    result = result.replaceAll('{\$ji}', 'Ji');
    result = result.replaceAll('{\$date}', appointment['scheduledDateTime']?['date']?.toString() ?? '');
    result = result.replaceAll('{\$time}', appointment['scheduledDateTime']?['time']?.toString() ?? '');
    result = result.replaceAll('{\$no_people}', numberOfPeople);
    result = result.replaceAll('{\$app_location}', appointment['scheduledDateTime']?['venueLabel']?.toString() ?? '');
    result = result.replaceAll('{\$email_note}', 'Please arrive 15 minutes before your scheduled time.');
    result = result.replaceAll('{\$area}', appointment['area']?.toString() ?? '');
    result = result.replaceAll('{\$designation}', appointment['userCurrentDesignation']?.toString() ?? '');
    result = result.replaceAll('{\$mobile}', appointment['mobile']?.toString() ?? '');
    result = result.replaceAll('{\$email}', email);
    result = result.replaceAll('{\$ref_by}', _getReferenceName());
    result = result.replaceAll('{\$ref_phone}', _getReferencePhone());
    result = result.replaceAll('{\$subject}', _emailSubjectController.text.isNotEmpty 
        ? _emailSubjectController.text 
        : appointment['subject']?.toString() ?? 'Meeting with Gurudev');
    result = result.replaceAll('{\$purpose}', appointment['purpose']?.toString() ?? 'Seeking guidance from gurudev');
    result = result.replaceAll('{\$ref_name}', _getReferenceName());
    result = result.replaceAll('{\$appointee_name}', fullName);
    result = result.replaceAll('{\$appointeeName}', fullName);
    
    return result;
  }

  String _replacePlaceholdersInHtml(String htmlContent) {
    // Get appointment data
    final appointment = widget.appointment;
    final appointmentId = _getAppointmentId();
    final fullName = _getAppointmentName();
    final email = _getAppointeeEmail();
    final numberOfPeople = _getNumberOfPeople();
    
    // Replace placeholders with actual appointment data in HTML content
    String result = htmlContent;
    
    result = result.replaceAll('{\$AID}', appointmentId);
    result = result.replaceAll('{\$full_name}', fullName);
    result = result.replaceAll('{\$ji}', 'Ji');
    result = result.replaceAll('{\$date}', appointment['scheduledDateTime']?['date']?.toString() ?? '');
    result = result.replaceAll('{\$time}', appointment['scheduledDateTime']?['time']?.toString() ?? '');
    result = result.replaceAll('{\$no_people}', numberOfPeople);
    result = result.replaceAll('{\$app_location}', appointment['scheduledDateTime']?['venueLabel']?.toString() ?? '');
    result = result.replaceAll('{\$email_note}', 'Please arrive 15 minutes before your scheduled time.');
    result = result.replaceAll('{\$area}', appointment['area']?.toString() ?? '');
    result = result.replaceAll('{\$designation}', appointment['userCurrentDesignation']?.toString() ?? '');
    result = result.replaceAll('{\$mobile}', appointment['mobile']?.toString() ?? '');
    result = result.replaceAll('{\$email}', email);
    result = result.replaceAll('{\$ref_by}', _getReferenceName());
    result = result.replaceAll('{\$ref_phone}', _getReferencePhone());
    result = result.replaceAll('{\$subject}', _emailSubjectController.text.isNotEmpty 
        ? _emailSubjectController.text 
        : appointment['subject']?.toString() ?? 'Meeting with Gurudev');
    result = result.replaceAll('{\$purpose}', appointment['purpose']?.toString() ?? 'Seeking guidance from gurudev');
    result = result.replaceAll('{\$ref_name}', _getReferenceName());
    result = result.replaceAll('{\$appointee_name}', fullName);
    result = result.replaceAll('{\$appointeeName}', fullName);
    
    return result;
  }

  // Helper method for month names
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper method to convert HTML to rich text with images
  String _htmlToRichText(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    try {
      // Parse HTML
      final document = html.parse(htmlString);
      
      // Extract text content with better structure preservation
      String text = '';
      
      // Process each element to preserve paragraph breaks and handle images
      void processElement(dynamic element) {
        if (element.nodeType == 3) { // TEXT_NODE
          text += element.text ?? '';
        } else if (element.nodeType == 1) { // ELEMENT_NODE
          final tagName = element.localName?.toLowerCase();
          
          // Handle images - add placeholder text
          if (tagName == 'img') {
            final src = element.attributes['src'] ?? '';
            final alt = element.attributes['alt'] ?? 'Image';
            if (src.isNotEmpty) {
              text += '\n[IMAGE: $alt - $src]\n';
            }
          }
          
          // Add line breaks for block elements
          if (tagName == 'p' || tagName == 'div' || tagName == 'h1' || tagName == 'h2' || 
              tagName == 'h3' || tagName == 'h4' || tagName == 'h5' || tagName == 'h6' || 
              tagName == 'br' || tagName == 'li') {
            if (text.isNotEmpty && !text.endsWith('\n')) {
              text += '\n';
            }
          }
          
          // Process child nodes
          for (var child in element.nodes) {
            processElement(child);
          }
          
          // Add line breaks after block elements
          if (tagName == 'p' || tagName == 'div' || tagName == 'h1' || tagName == 'h2' || 
              tagName == 'h3' || tagName == 'h4' || tagName == 'h5' || tagName == 'h6' || 
              tagName == 'li') {
            if (!text.endsWith('\n')) {
              text += '\n';
            }
          }
        }
      }
      
      // Process the document body
      if (document.body != null) {
        for (var child in document.body!.nodes) {
          processElement(child);
        }
      }
      
      // Clean up common HTML entities and formatting
      text = text
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&ldquo;', '"')
          .replaceAll('&rdquo;', '"')
          .replaceAll('&lsquo;', "'")
          .replaceAll('&rsquo;', "'")
          .replaceAll('&hellip;', '...')
          .replaceAll('&mdash;', '—')
          .replaceAll('&ndash;', '–')
          .replaceAll('&copy;', '©');
      
      // Clean up multiple line breaks and normalize spacing
      text = text
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Replace 3+ line breaks with 2
          .replaceAll(RegExp(r'[ \t]+'), ' ') // Replace multiple spaces/tabs with single space
          .replaceAll(RegExp(r'\n[ \t]+'), '\n') // Remove leading spaces after line breaks
          .replaceAll(RegExp(r'[ \t]+\n'), '\n') // Remove trailing spaces before line breaks
          .trim();
      
      // Add specific formatting for better readability
      text = text
          .replaceAll(RegExp(r'\nDear'), '\n\nDear') // Double line break before "Dear"
          .replaceAll(RegExp(r'\nWarm Regards,'), '\n\nWarm Regards,') // Double line break before "Warm Regards"
          .replaceAll(RegExp(r'\nNOTE:'), '\n\nNOTE:') // Double line break before "NOTE"
          .replaceAll(RegExp(r'\nFollow'), '\n\nFollow'); // Double line break before "Follow"
      
      return text;
    } catch (e) {
      // If HTML parsing fails, return the original string
      print('Error parsing HTML: $e');
      return htmlString;
    }
  }

  // Helper method to convert HTML to plain text (for backward compatibility)
  String _htmlToPlainText(String htmlString) {
    if (htmlString.isEmpty) return '';
    
    try {
      // Parse HTML
      final document = html.parse(htmlString);
      
      // Extract text content with better structure preservation
      String text = '';
      
      // Process each element to preserve paragraph breaks
      void processElement(dynamic element) {
        if (element.nodeType == 3) { // TEXT_NODE
          text += element.text ?? '';
        } else if (element.nodeType == 1) { // ELEMENT_NODE
          final tagName = element.localName?.toLowerCase();
          
          // Add line breaks for block elements
          if (tagName == 'p' || tagName == 'div' || tagName == 'h1' || tagName == 'h2' || 
              tagName == 'h3' || tagName == 'h4' || tagName == 'h5' || tagName == 'h6' || 
              tagName == 'br' || tagName == 'li') {
            if (text.isNotEmpty && !text.endsWith('\n')) {
              text += '\n';
            }
          }
          
          // Process child nodes
          for (var child in element.nodes) {
            processElement(child);
          }
          
          // Add line breaks after block elements
          if (tagName == 'p' || tagName == 'div' || tagName == 'h1' || tagName == 'h2' || 
              tagName == 'h3' || tagName == 'h4' || tagName == 'h5' || tagName == 'h6' || 
              tagName == 'li') {
            if (!text.endsWith('\n')) {
              text += '\n';
            }
          }
        }
      }
      
      // Process the document body
      if (document.body != null) {
        for (var child in document.body!.nodes) {
          processElement(child);
        }
      }
      
      // Clean up common HTML entities and formatting
      text = text
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', "'")
          .replaceAll('&apos;', "'")
          .replaceAll('&ldquo;', '"')
          .replaceAll('&rdquo;', '"')
          .replaceAll('&lsquo;', "'")
          .replaceAll('&rsquo;', "'")
          .replaceAll('&hellip;', '...')
          .replaceAll('&mdash;', '—')
          .replaceAll('&ndash;', '–')
          .replaceAll('&copy;', '©');
      
      // Clean up multiple line breaks and normalize spacing
      text = text
          .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Replace 3+ line breaks with 2
          .replaceAll(RegExp(r'[ \t]+'), ' ') // Replace multiple spaces/tabs with single space
          .replaceAll(RegExp(r'\n[ \t]+'), '\n') // Remove leading spaces after line breaks
          .replaceAll(RegExp(r'[ \t]+\n'), '\n') // Remove trailing spaces before line breaks
          .trim();
      
      // Add specific formatting for better readability
      text = text
          .replaceAll(RegExp(r'\nDear'), '\n\nDear') // Double line break before "Dear"
          .replaceAll(RegExp(r'\nWarm Regards,'), '\n\nWarm Regards,') // Double line break before "Warm Regards"
          .replaceAll(RegExp(r'\nNOTE:'), '\n\nNOTE:') // Double line break before "NOTE"
          .replaceAll(RegExp(r'\nFollow'), '\n\nFollow'); // Double line break before "Follow"
      
      return text;
    } catch (e) {
      // If HTML parsing fails, return the original string
      print('Error parsing HTML: $e');
      return htmlString;
    }
  }

  // Helper method to check if image is a social media icon
  bool _isSocialMediaIcon(String altText, String imageUrl) {
    final socialMediaKeywords = [
      'twitter', 'facebook', 'youtube', 'instagram', 'linkedin',
      'tw.png', 'fb.png', 'yt.png', 'inst.png', 'in.png'
    ];
    
    final lowerAlt = altText.toLowerCase();
    final lowerUrl = imageUrl.toLowerCase();
    
    return socialMediaKeywords.any((keyword) => 
        lowerAlt.contains(keyword) || lowerUrl.contains(keyword));
  }

  // Helper method to check if string contains HTML
  bool _containsHtml(String text) {
    return text.contains('<') && text.contains('>') && 
           (text.contains('<p>') || text.contains('<div>') || text.contains('<br>') || 
            text.contains('<h') || text.contains('<span>') || text.contains('<strong>') ||
            text.contains('<b>') || text.contains('<i>') || text.contains('<em>'));
  }



  // Build email content widget with images
  Widget _buildEmailContentWidget(String content) {
    if (content.isEmpty) {
      return const Text(
        'Enter email content here...',
        style: TextStyle(color: Colors.grey),
      );
    }

    // Split content by image placeholders
    final parts = content.split(RegExp(r'\[IMAGE: .*? - .*?\]'));
    final imageMatches = RegExp(r'\[IMAGE: (.*?) - (.*?)\]').allMatches(content);
    
    List<Widget> widgets = [];
    
    for (int i = 0; i < parts.length; i++) {
      // Add text part
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        );
      }
      
      // Add image if available
      if (i < imageMatches.length) {
        final match = imageMatches.elementAt(i);
        final altText = match.group(1) ?? '';
        final imageUrl = match.group(2) ?? '';
        
        if (imageUrl.isNotEmpty) {
          // Check if it's a social media icon
          bool isSocialMediaIcon = _isSocialMediaIcon(altText, imageUrl);
          
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (altText.isNotEmpty && !isSocialMediaIcon)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        altText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Container(
                    width: isSocialMediaIcon ? 20 : double.infinity,
                    height: isSocialMediaIcon ? 20 : 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(isSocialMediaIcon ? 4 : 8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSocialMediaIcon ? 4 : 8),
                      child: Image.network(
                        imageUrl,
                        fit: isSocialMediaIcon ? BoxFit.contain : BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: isSocialMediaIcon ? 12 : 24,
                              height: isSocialMediaIcon ? 12 : 24,
                              child: CircularProgressIndicator(
                                strokeWidth: isSocialMediaIcon ? 1.5 : 2.0,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: isSocialMediaIcon ? 12 : 48,
                                  color: Colors.grey.shade400,
                                ),
                                if (!isSocialMediaIcon) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image not available',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    imageUrl,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }



  void _sendEmail() {
    if (_formKey.currentState!.validate()) {
      // Validate that at least one recipient is selected
      final recipients = _getRecipientEmails();
      
      if (recipients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one recipient (Appointee or Reference email)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate that subject and content are not empty
      final subject = _emailSubjectController.text.trim();
      final content = _emailTemplateController.text.trim();
      
      if (subject.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an email subject'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
             content: Text('Please select an email template'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Validate reschedule fields if it's a reschedule template
      if (_showRescheduleForm) {
        if (_newDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a new date for rescheduling'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (_newTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a new time for rescheduling'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (_newVenueName.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a new venue for rescheduling'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // Get email data
      final emailData = _getEmailData();
      
      // FIXED: Send email directly without confirmation dialog
      _sendEmailToBackend(emailData);
    }
  }

  void _showEmailConfirmationDialog(Map<String, dynamic> emailData) {
    final recipients = (emailData['recipients'] as List<dynamic>).cast<String>();
    final cc = (emailData['cc'] as List<dynamic>).cast<String>();
    final bcc = (emailData['bcc'] as List<dynamic>).cast<String>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To: ${recipients.join(', ')}'),
              if (cc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('CC: ${cc.join(', ')}'),
              ],
              if (bcc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('BCC: ${bcc.join(', ')}'),
              ],
              const SizedBox(height: 8),
              Text('Subject: ${emailData['subject']}'),
              
              // Show reschedule details if applicable
              if (_showRescheduleForm && _newDate != null && _newTime != null && _newVenueName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Reschedule Details:',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('New Date: ${_newDate!.day}/${_newDate!.month}/${_newDate!.year}'),
                      Text('New Time: ${_newTime!.format(context)}'),
                      Text('New Venue: $_newVenueName'),
                    ],
                  ),
                ),
              ],
              
              if (cc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: CC recipients will receive the email as main recipients due to backend limitations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text('Are you sure you want to send this email?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendEmailToBackend(emailData);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  void _showEmailTemplateModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95, // Made even wider
            height: MediaQuery.of(context).size.height * 0.6, // Made more rectangular
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Email Template',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Divider
                Divider(color: Colors.grey.shade300, height: 1),
                const SizedBox(height: 20),
                // Template list
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: _emailTemplates.length,
                      itemBuilder: (context, index) {
                        final template = _emailTemplates[index];
                        final isSelected = template['value'] == _selectedTemplate;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade50 : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(
                              template['label']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            trailing: isSelected 
                              ? Icon(
                                  Icons.check_circle,
                                  color: Colors.blue.shade700,
                                  size: 24,
                                )
                              : null,
                            onTap: () {
                              setState(() {
                                _selectedTemplate = template['value']!;
                                _templateDisplayController.text = template['label']!;
                                
                                // Check if this is the reschedule template
                                _showRescheduleForm = _isRescheduleTemplate();
                                print('📧 TEMPLATE SELECTED IN MODAL: ${template['value']}');
                                print('🔄 SHOW RESCHEDULE FORM: $_showRescheduleForm');
                                
                                // Clear reschedule form if not reschedule template
                                if (!_showRescheduleForm) {
                                  _newDate = null;
                                  _newTime = null;
                                  _newVenue = '';
                                  _newVenueName = '';
                                }
                                
                                // Populate subject and content if template is selected
                                if (_templateData.containsKey(template['value'])) {
                                  final templateData = _templateData[template['value']]!;
                                  
                                  _emailSubjectController.text = _replacePlaceholders(templateData['subject'] ?? '');
                                  _emailTemplateController.text = _replacePlaceholders(templateData['content'] ?? '');
                                }
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendEmailToBackend(Map<String, dynamic> emailData) async {
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

      // Extract data from emailData
      final recipients = (emailData['recipients'] as List<dynamic>).cast<String>();
      final cc = (emailData['cc'] as List<dynamic>).cast<String>();
      final bcc = (emailData['bcc'] as List<dynamic>).cast<String>();
      final subject = emailData['subject'] as String;
      final content = emailData['content'] as String;
      final templateId = emailData['templateId'] as String?;
      final includeAppointeeEmail = emailData['includeAppointeeEmail'] as bool;
      final includeReferenceEmail = emailData['includeReferenceEmail'] as bool;

      // Get appointee email
      final appointeeEmail = _getAppointeeEmail();
      
      // Get reference email
      final referenceEmail = _getReferenceEmail();
      
      // WORKAROUND: Since the backend API doesn't seem to properly process the CC field,
      // we're including CC emails in the main appointee email field as a fallback.
      // This ensures CC recipients still receive the email while maintaining the UI separation.
      // TODO: Remove this workaround once the backend properly supports CC field processing.
      final allRecipients = _getAllRecipientsIncludingCC();
      final mainRecipients = _getRecipientEmails();
      
      // If we have CC emails and they're not in main recipients, add them
      String combinedAppointeeEmail = appointeeEmail;
      if (cc.isNotEmpty && !mainRecipients.contains(cc.first)) {
        // Add CC emails to the appointee email field as a workaround
        combinedAppointeeEmail = '$appointeeEmail,${cc.join(',')}';
      }
      
      // Debug logging
      print('📧 Email sending debug info:');
      print('Original appointee email: $appointeeEmail');
      print('CC emails: $cc');
      print('Combined appointee email: $combinedAppointeeEmail');
      print('BCC emails: $bcc');
      
      final result = await ActionService.sendAppointmentEmailAction(
        appointeeEmail: combinedAppointeeEmail,
        referenceEmail: referenceEmail.isNotEmpty ? referenceEmail : null,
        cc: cc.isNotEmpty ? cc.join(',') : null, // Still send CC field in case backend fixes it
        bcc: bcc.isNotEmpty ? bcc.join(',') : null,
        subject: subject,
        body: content,
        selectedTemplateId: templateId,
        appointmentId: emailData['appointmentId'], // 👈 Pass appointmentId as separate parameter
        rescheduleDate: emailData['rescheduleDate'],
        rescheduleTime: emailData['rescheduleTime'],
        rescheduleVenue: emailData['rescheduleVenue'],
        rescheduleVenueName: emailData['rescheduleVenueName'],
        templateData: {
          'appointmentId': emailData['appointmentId'],
          'fullName': _getAppointmentName(), // This now uses createdBy.fullName to match backend
          'email': _getAppointeeEmail(),
          'numberOfPeople': _getNumberOfPeople(),
          'userCurrentDesignation': widget.appointment['userCurrentDesignation']?.toString() ?? '',
          'purpose': widget.appointment['purpose']?.toString() ?? '',
          'subject': widget.appointment['subject']?.toString() ?? '',
          'venue': widget.appointment['scheduledDateTime']?['venueLabel']?.toString() ?? '',
          'scheduledDate': widget.appointment['scheduledDateTime']?['date']?.toString() ?? '',
          'scheduledTime': widget.appointment['scheduledDateTime']?['time']?.toString() ?? '',
          'mobile': widget.appointment['mobile']?.toString() ?? '',
          'area': widget.appointment['area']?.toString() ?? '',
          'userCurrentCompany': widget.appointment['userCurrentCompany']?.toString() ?? '',
          'appointmentType': widget.appointment['appointmentType']?.toString() ?? '',
          'preferredDateRange': widget.appointment['preferredDateRange']?.toString() ?? '',
          'referenceName': _getReferenceName(),
          'referencePhone': _getReferencePhone(),
        },
        useAppointee: includeAppointeeEmail,
        useReference: includeReferenceEmail,
        otherEmail: null, // Not currently used in the form
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text('Success'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['message'] ?? 'Email sent successfully!'),
                  if (cc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Note: CC emails were included in the main recipients due to backend limitations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Use a microtask to ensure dialog is closed before calling callback
                    Future.microtask(() {
                      widget.onSend?.call();
                      // Close form if it's still open and we're still mounted
                      if (mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Text('Error'),
                ],
              ),
              content: Text(result['message'] ?? 'Failed to send email. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Text('Error'),
              ],
            ),
            content: Text('Error sending email: $e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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
                        subtitle: _getAppointeeEmail().isNotEmpty ? null : 'No email available',
                      ),
                      
                      // Reference Email Checkbox
                      _buildCheckbox(
                        value: _includeReferenceEmail,
                        onChanged: (value) => setState(() => _includeReferenceEmail = value ?? false),
                        title: 'Reference Email: ${_getReferenceEmail()}',
                        subtitle: _getReferenceEmail().isNotEmpty ? null : 'No reference email available',
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
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emails = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                            for (String email in emails) {
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                                return 'Please enter valid email addresses separated by commas';
                              }
                            }
                          }
                          return null;
                        },
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
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final emails = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                            for (String email in emails) {
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
                                return 'Please enter valid email addresses separated by commas';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      
                      
                      // Email Template Selection
                      if (_isLoadingTemplates)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 16),
                                Text('Loading email templates...'),
                              ],
                            ),
                          ),
                        )
                      else if (_errorMessage != null)
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error loading templates',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: _loadEmailTemplates,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          readOnly: true,
                          onTap: _showEmailTemplateModal,
                          controller: _templateDisplayController,
                        decoration: const InputDecoration(
                          labelText: 'Email Template',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Reschedule Form (only shown for reschedule template)
                      if (_showRescheduleForm) ...[
                        // Debug log for UI
                        Builder(
                          builder: (context) {
                            print('🎨 UI: Showing reschedule form, _showRescheduleForm = $_showRescheduleForm');
                            return const SizedBox.shrink();
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reschedule Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // New Date
                              InkWell(
                                onTap: _selectNewDate,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.grey.shade600),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _newDate != null
                                              ? 'New Date: ${_newDate!.day}/${_newDate!.month}/${_newDate!.year}'
                                              : 'Select New Date',
                                          style: TextStyle(
                                            color: _newDate != null ? Colors.black : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // New Time
                              InkWell(
                                onTap: _selectNewTime,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: Colors.grey.shade600),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _newTime != null
                                              ? 'New Time: ${_newTime!.format(context)}'
                                              : 'Select New Time',
                                          style: TextStyle(
                                            color: _newTime != null ? Colors.black : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // New Venue
                              InkWell(
                                onTap: _showVenueBottomSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, color: Colors.grey.shade600),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _newVenueName.isNotEmpty
                                              ? 'New Venue: $_newVenueName'
                                              : 'Select New Venue',
                                          style: TextStyle(
                                            color: _newVenueName.isNotEmpty ? Colors.black : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              Text(
                                'Note: This date will be included in the reschedule email.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
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
                       Container(
                         width: double.infinity,
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey.shade400),
                           borderRadius: BorderRadius.circular(4),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Padding(
                               padding: const EdgeInsets.all(12.0),
                               child: Text(
                                 'Email Body',
                                 style: TextStyle(
                                   color: Colors.grey.shade700,
                                   fontSize: 16,
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ),
                             Container(
                               height: 300,
                               width: double.infinity,
                               padding: const EdgeInsets.all(12.0),
                               child: TextFormField(
                                 controller: _emailTemplateController,
                                 maxLines: null,
                                 expands: true,
                                 decoration: const InputDecoration(
                                   hintText: 'Email content will appear here...',
                                   border: InputBorder.none,
                                   contentPadding: EdgeInsets.zero,
                                 ),
                                 style: const TextStyle(fontSize: 14),
                               ),
                             ),
                           ],
                         ),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
              title,
              style: const TextStyle(fontSize: 16),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 