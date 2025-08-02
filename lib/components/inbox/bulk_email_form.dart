import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html;
import '../../action/action.dart';

class BulkEmailForm extends StatefulWidget {
  final List<Map<String, dynamic>> appointments;
  final VoidCallback? onSend;
  final VoidCallback? onClose;

  const BulkEmailForm({
    Key? key,
    required this.appointments,
    this.onSend,
    this.onClose,
  }) : super(key: key);

  @override
  State<BulkEmailForm> createState() => _BulkEmailFormState();
}

class _BulkEmailFormState extends State<BulkEmailForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailTemplateController = TextEditingController();
  final TextEditingController _templateDisplayController = TextEditingController();
  
  // Focus nodes for keyboard management
  final FocusNode _emailSubjectFocus = FocusNode();
  final FocusNode _emailTemplateFocus = FocusNode();
  
  // Form values
  String _selectedTemplate = '';
  
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
        
        // Clear existing templates
        _emailTemplates = [];
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
              'content': _htmlToRichText(template['content'] ?? template['templateData'] ?? template['body'] ?? ''),
              'originalHtml': template['content'] ?? template['templateData'] ?? template['body'] ?? '', // Store original HTML for backend
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
      });
    }
  }

  String _replacePlaceholders(String text) {
    String result = text;
    
    // First convert HTML to plain text if it contains HTML
    if (_containsHtml(text)) {
      result = _htmlToPlainText(text);
    }
    
    // For bulk email, we'll use generic placeholders or the first appointment as template
    final firstAppointment = widget.appointments.isNotEmpty ? widget.appointments.first : {};
    
    // Replace placeholders with actual appointment data
    result = result.replaceAll('{\$AID}', firstAppointment['appointmentId']?.toString() ?? firstAppointment['_id']?.toString() ?? '');
    result = result.replaceAll('{\$full_name}', firstAppointment['fullName']?.toString() ?? firstAppointment['name']?.toString() ?? 'Recipient');
    result = result.replaceAll('{\$ji}', 'Ji');
    result = result.replaceAll('{\$date}', firstAppointment['scheduledDate']?.toString() ?? '');
    result = result.replaceAll('{\$time}', firstAppointment['scheduledTime']?.toString() ?? '');
    result = result.replaceAll('{\$no_people}', firstAppointment['noOfPeople']?.toString() ?? '');
    result = result.replaceAll('{\$app_location}', firstAppointment['venue']?.toString() ?? '');
    result = result.replaceAll('{\$email_note}', 'Please arrive 15 minutes before your scheduled time.');
    result = result.replaceAll('{\$area}', firstAppointment['area']?.toString() ?? '');
    result = result.replaceAll('{\$designation}', firstAppointment['userCurrentDesignation']?.toString() ?? '');
    result = result.replaceAll('{\$mobile}', firstAppointment['mobile']?.toString() ?? '');
    result = result.replaceAll('{\$email}', firstAppointment['email']?.toString() ?? '');
    result = result.replaceAll('{\$subject}', _emailSubjectController.text.isNotEmpty 
        ? _emailSubjectController.text 
        : firstAppointment['subject']?.toString() ?? 'Meeting with Gurudev');
    result = result.replaceAll('{\$purpose}', firstAppointment['purpose']?.toString() ?? 'Seeking guidance from gurudev');
    
    return result;
  }

  String _replacePlaceholdersInHtml(String htmlContent) {
    // For bulk email, we'll use generic placeholders or the first appointment as template
    final firstAppointment = widget.appointments.isNotEmpty ? widget.appointments.first : {};
    
    // Replace placeholders with actual appointment data in HTML content
    String result = htmlContent;
    result = result.replaceAll('{\$AID}', firstAppointment['appointmentId']?.toString() ?? firstAppointment['_id']?.toString() ?? '');
    result = result.replaceAll('{\$full_name}', firstAppointment['fullName']?.toString() ?? firstAppointment['name']?.toString() ?? 'Recipient');
    result = result.replaceAll('{\$ji}', 'Ji');
    result = result.replaceAll('{\$date}', firstAppointment['scheduledDate']?.toString() ?? '');
    result = result.replaceAll('{\$time}', firstAppointment['scheduledTime']?.toString() ?? '');
    result = result.replaceAll('{\$no_people}', firstAppointment['noOfPeople']?.toString() ?? '');
    result = result.replaceAll('{\$app_location}', firstAppointment['venue']?.toString() ?? '');
    result = result.replaceAll('{\$email_note}', 'Please arrive 15 minutes before your scheduled time.');
    result = result.replaceAll('{\$area}', firstAppointment['area']?.toString() ?? '');
    result = result.replaceAll('{\$designation}', firstAppointment['userCurrentDesignation']?.toString() ?? '');
    result = result.replaceAll('{\$mobile}', firstAppointment['mobile']?.toString() ?? '');
    result = result.replaceAll('{\$email}', firstAppointment['email']?.toString() ?? '');
    result = result.replaceAll('{\$subject}', _emailSubjectController.text.isNotEmpty 
        ? _emailSubjectController.text 
        : firstAppointment['subject']?.toString() ?? 'Meeting with Gurudev');
    result = result.replaceAll('{\$purpose}', firstAppointment['purpose']?.toString() ?? 'Seeking guidance from gurudev');
    
    return result;
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
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
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
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
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

  void _sendBulkEmail() {
    if (_formKey.currentState!.validate()) {
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

      // Show confirmation dialog
      _showBulkEmailConfirmationDialog(subject, processedHtmlContent);
    }
  }

  void _showBulkEmailConfirmationDialog(String subject, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Bulk Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipients: ${widget.appointments.length} appointments'),
              const SizedBox(height: 8),
              Text('Subject: $subject'),
              const SizedBox(height: 8),
              const Text('Are you sure you want to send this bulk email?'),
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
                _sendBulkEmailToBackend(subject, content);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBulkEmailToBackend(String subject, String content) async {
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

      // Prepare recipients data from selected appointments
      List<Map<String, dynamic>> recipients = [];
      
      for (var appointment in widget.appointments) {
        // Extract email from appointment data
        String email = '';
        
        // Try different possible email fields
        if (appointment['email'] != null) {
          email = appointment['email'].toString();
        } else if (appointment['createdBy']?['email'] != null) {
          email = appointment['createdBy']['email'].toString();
        } else if (appointment['userEmail'] != null) {
          email = appointment['userEmail'].toString();
        }
        
        // Extract appointment ID
        String appointmentId = appointment['_id']?.toString() ?? 
                              appointment['appointmentId']?.toString() ?? '';
        
        // Extract name from appointment data
        String name = '';
        if (appointment['fullName'] != null) {
          name = appointment['fullName'].toString();
        } else if (appointment['name'] != null) {
          name = appointment['name'].toString();
        } else if (appointment['createdBy']?['fullName'] != null) {
          name = appointment['createdBy']['fullName'].toString();
        } else if (appointment['userName'] != null) {
          name = appointment['userName'].toString();
        }
        
        // Only add if we have valid email and appointment ID
        if (email.isNotEmpty && appointmentId.isNotEmpty) {
          recipients.add({
            'email': email,
            'appointmentId': appointmentId,
            'name': name.isNotEmpty ? name : 'Unknown',
          });
        }
      }

      // Prepare the request body according to your backend format
      Map<String, dynamic> requestBody = {
        'templateId': _selectedTemplate,
        'recipients': recipients,
        'tags': ['bulk-email', 'appointment'], // You can customize these tags
      };

      // Add subject and content if your backend needs them
      if (subject.isNotEmpty) {
        requestBody['subject'] = subject;
      }
      if (content.isNotEmpty) {
        requestBody['content'] = content;
      }

      print('📧 Sending bulk email request:');
      print('Template ID: $_selectedTemplate');
      print('Recipients count: ${recipients.length}');
      print('Request body: $requestBody');

      // Call the bulk email API
      final result = await ActionService.sendBulkEmail(
        templateId: _selectedTemplate,
        recipients: recipients,
        tags: ['bulk-email', 'appointment'],
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Handle API response
      if (result['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Bulk email sent to ${recipients.length} recipients!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Call the callback and close the form
        widget.onSend?.call();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send bulk email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending bulk email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.6,
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

  // Dismiss keyboard when tapping outside
  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _emailSubjectController.dispose();
    _emailTemplateController.dispose();
    _templateDisplayController.dispose();
    _scrollController.dispose();
    
    // Dispose focus nodes
    _emailSubjectFocus.dispose();
    _emailTemplateFocus.dispose();
    
    super.dispose();
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
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipients Info
                      Container(
                        width: double.infinity,
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
                                Icon(Icons.people, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Bulk Email Recipients',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.appointments.length} appointments selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
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
                      
                      // Subject Field
                      TextFormField(
                        controller: _emailSubjectController,
                        focusNode: _emailSubjectFocus,
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
                              child: SingleChildScrollView(
                                child: _buildEmailContentWidget(_emailTemplateController.text),
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
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _dismissKeyboard();
                        _sendBulkEmail();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Send Bulk Email'),
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
} 