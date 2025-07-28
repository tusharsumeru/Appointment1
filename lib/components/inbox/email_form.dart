import 'package:flutter/material.dart';

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
  
  // Email templates
  final List<Map<String, String>> _emailTemplates = [
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
                        title: 'Reference Email:',
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