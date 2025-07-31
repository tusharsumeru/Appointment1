import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
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

      if (result['success']) {
        final List<dynamic> templates = result['data'] ?? [];
        
        // Clear existing templates and add default
        _emailTemplates = [{'value': '', 'label': 'Select Template'}];
        _templateData.clear();
        
        // Add templates from API
        for (var template in templates) {
          final String id = template['_id']?.toString() ?? '';
          final String name = template['name'] ?? template['templateName'] ?? 'Unknown Template';
          final bool isActive = template['isActive'] ?? true;
          
          // Only add active templates
          if (isActive && id.isNotEmpty) {
            _emailTemplates.add({
              'value': id,
              'label': name,
            });
            
            // Store template data for later use
            _templateData[id] = {
              'subject': template['subject'] ?? template['templateSubject'] ?? '',
              'content': template['content'] ?? template['templateData'] ?? template['body'] ?? '',
              'category': template['category'] ?? '',
              'tags': template['tags'] ?? [],
              'region': template['region'] ?? '',
            };
          }
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
    // Try multiple possible fields for the name
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['fullName']?.toString() ??
           widget.appointment['name']?.toString() ??
           widget.appointment['userName']?.toString() ??
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointeeEmail() {
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
    
    // Add CC emails if provided
    if (_ccEmailController.text.isNotEmpty) {
      final ccEmails = _ccEmailController.text
          .split(',')
          .map((email) => email.trim())
          .where((email) => email.isNotEmpty)
          .toList();
      recipients.addAll(ccEmails);
    }
    
    return recipients;
  }

  Map<String, dynamic> _getEmailData() {
    return {
      'recipients': _getRecipientEmails(),
      'bcc': _bccEmailController.text.isNotEmpty 
          ? _bccEmailController.text
              .split(',')
              .map((email) => email.trim())
              .where((email) => email.isNotEmpty)
              .toList()
          : [],
      'subject': _emailSubjectController.text,
      'content': _emailTemplateController.text,
      'templateId': _selectedTemplate.isNotEmpty ? _selectedTemplate : null,
      'appointmentId': _getAppointmentId(),
      'includeAppointeeEmail': _includeAppointeeEmail,
      'includeReferenceEmail': _includeReferenceEmail,
      'darshanLineDate': _darshanLineDateController.text,
      'darshanLineTime': _darshanLineTimeController.text,
    };
  }

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
    
    // Get appointment data
    final appointment = widget.appointment;
    final appointmentId = _getAppointmentId();
    final fullName = _getAppointmentName();
    final email = _getAppointeeEmail();
    
    // Replace placeholders with actual appointment data
    result = result.replaceAll('{\$AID}', appointmentId);
    result = result.replaceAll('{\$full_name}', fullName);
    result = result.replaceAll('{\$ji}', 'Ji');
    result = result.replaceAll('{\$date}', _darshanLineDateController.text.isNotEmpty 
        ? _darshanLineDateController.text 
        : appointment['scheduledDate']?.toString() ?? 'TBD');
    result = result.replaceAll('{\$time}', _darshanLineTimeController.text.isNotEmpty 
        ? _darshanLineTimeController.text 
        : appointment['scheduledTime']?.toString() ?? 'TBD');
    result = result.replaceAll('{\$no_people}', appointment['noOfPeople']?.toString() ?? '1');
    result = result.replaceAll('{\$app_location}', appointment['venue']?.toString() ?? 'Bangalore Ashram');
    result = result.replaceAll('{\$email_note}', 'Please arrive 15 minutes before your scheduled time.');
    result = result.replaceAll('{\$area}', appointment['area']?.toString() ?? 'Main Hall');
    result = result.replaceAll('{\$designation}', appointment['userCurrentDesignation']?.toString() ?? 'Guest');
    result = result.replaceAll('{\$mobile}', appointment['mobile']?.toString() ?? '+91 9876543210');
    result = result.replaceAll('{\$email}', email);
    result = result.replaceAll('{\$ref_by}', _getReferenceName());
    result = result.replaceAll('{\$ref_phone}', _getReferencePhone());
    result = result.replaceAll('{\$subject}', _emailSubjectController.text.isNotEmpty 
        ? _emailSubjectController.text 
        : appointment['subject']?.toString() ?? 'Meeting with Gurudev');
    result = result.replaceAll('{\$purpose}', appointment['purpose']?.toString() ?? 'Seeking guidance on spiritual matters');
    result = result.replaceAll('{\$ref_name}', _getReferenceName());
    result = result.replaceAll('{\$appointee_name}', fullName);
    result = result.replaceAll('{\$appointeeName}', fullName);
    
    return result;
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
      if (_emailSubjectController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an email subject'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_emailTemplateController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter email content'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get email data
      final emailData = _getEmailData();
      
      // Show confirmation dialog
      _showEmailConfirmationDialog(emailData);
    }
  }

  void _showEmailConfirmationDialog(Map<String, dynamic> emailData) {
    final recipients = emailData['recipients'] as List<String>;
    final bcc = emailData['bcc'] as List<String>;
    
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
              if (bcc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('BCC: ${bcc.join(', ')}'),
              ],
              const SizedBox(height: 8),
              Text('Subject: ${emailData['subject']}'),
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
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(16),
            child: Scrollbar(
              child: ListView.builder(
                itemCount: _emailTemplates.length,
                itemBuilder: (context, index) {
                  final template = _emailTemplates[index];
                  final isSelected = template['value'] == _selectedTemplate;
                  
                  return ListTile(
                    title: Text(template['label']!),
                    selected: isSelected,
                    onTap: () {
                      if (template['value']?.isNotEmpty ?? false) {
                        setState(() {
                          _selectedTemplate = template['value']!;
                          // Populate subject and content if template is selected
                          if (_templateData.containsKey(template['value'])) {
                            final templateData = _templateData[template['value']]!;
                            _emailSubjectController.text = _replacePlaceholders(templateData['subject'] ?? '');
                            _emailTemplateController.text = _replacePlaceholders(templateData['content'] ?? '');
                          }
                        });
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendEmailToBackend(Map<String, dynamic> emailData) {
      // Here you would typically send the email data to your backend
    // For now, we'll just call the callback and close the form
    print('Sending email with data: $emailData');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    widget.onSend?.call();
      Navigator.of(context).pop();
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
                          controller: TextEditingController(
                            text: _emailTemplates.firstWhere(
                              (template) => template['value'] == _selectedTemplate,
                              orElse: () => {'value': '', 'label': 'Select Template'},
                            )['label'],
                          ),
                        decoration: const InputDecoration(
                          labelText: 'Email Template',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
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
                           labelText: 'Email Body',
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