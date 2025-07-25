import 'package:flutter/material.dart';

class EmailForm extends StatefulWidget {
  final String appointmentId;
  final String appointmentName;
  final String appointeeEmail;
  final VoidCallback? onSend;
  final VoidCallback? onClose;

  const EmailForm({
    Key? key,
    required this.appointmentId,
    required this.appointmentName,
    required this.appointeeEmail,
    this.onSend,
    this.onClose,
  }) : super(key: key);

  @override
  State<EmailForm> createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _ccEmailController = TextEditingController();
  final TextEditingController _bccEmailController = TextEditingController();
  final TextEditingController _darshanLineDateController = TextEditingController();
  final TextEditingController _darshanLineTimeController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailTemplateController = TextEditingController();
  
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

  @override
  void dispose() {
    _ccEmailController.dispose();
    _bccEmailController.dispose();
    _darshanLineDateController.dispose();
    _darshanLineTimeController.dispose();
    _emailSubjectController.dispose();
    _emailTemplateController.dispose();
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
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.email, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Send Email',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      title: 'Appointee Email: ${widget.appointeeEmail}',
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
                    
                    // Email Template Section Header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Email Template',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Email Template Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTemplate.isEmpty ? null : _selectedTemplate,
                      decoration: const InputDecoration(
                        labelText: 'Select Template',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: _emailTemplates.map((template) {
                        return DropdownMenuItem(
                          value: template['value'],
                          child: Text(
                            template['label']!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: _onTemplateChanged,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a template';
                        }
                        return null;
                      },
                    ),
                    
                    // Darshan Line Fields (conditional)
                    if (_showDarshanLineFields) ...[
                      const SizedBox(height: 16),
                      
                      // Darshan Line Section Header
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Darshan Line Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      
                      // Darshan Line Date
                      TextFormField(
                        controller: _darshanLineDateController,
                        decoration: const InputDecoration(
                          labelText: 'Darshan Line Date',
                          hintText: 'Darshan Line Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            _darshanLineDateController.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Darshan Line Time
                      TextFormField(
                        controller: _darshanLineTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Darshan Line Time',
                          hintText: 'Darshan Line Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            _darshanLineTimeController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          }
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Email Content Section Header
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Email Content',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    
                    // Email Subject
                    TextFormField(
                      controller: _emailSubjectController,
                      decoration: const InputDecoration(
                        labelText: 'Email Subject',
                        hintText: 'Email Subject',
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
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onClose?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendEmail,
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
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
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