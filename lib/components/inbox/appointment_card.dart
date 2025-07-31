import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'appointment_detail_page.dart';
import 'appointment_schedule_form.dart';
import 'email_form.dart';
import 'message_form.dart';
import 'reminder_form.dart';
import 'call_form.dart';
import 'assign_form.dart';
import 'star_form.dart';

import '../../action/action.dart';

class AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onTap;
  final Function(bool)? onStarToggle;
  final VoidCallback? onRefresh; // Add refresh callback

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onStarToggle,
    this.onRefresh, // Add refresh callback parameter
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  @override
  Widget build(BuildContext context) {
    // Extract only essential data
    final String id =
        widget.appointment['appointmentId']?.toString() ??
        widget.appointment['_id']?.toString() ??
        '';
    final String createdByName = _getCreatedByName();
    final String createdByDesignation = _getCreatedByDesignation();
    final String createdByImage = _getCreatedByImage();
    final String createdAt = _getCreatedAt();
    final String preferredDateRange = _getPreferredDateRange();
    final int attendeeCount = _getAttendeeCount();
    final bool isStarred = widget.appointment['starred'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap:
            widget.onTap ??
            () async {
              // Show loading indicator
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Loading appointment details...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              // Get appointment ID
              final appointmentId = widget.appointment['appointmentId']?.toString() ?? 
                                  widget.appointment['_id']?.toString() ?? '';
              
              if (appointmentId.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Appointment ID not found'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Fetch detailed appointment data using the new API
              final result = await ActionService.getAppointmentByIdDetailed(appointmentId);
              
              if (context.mounted) {
                if (result['success']) {
                  // Navigate to detail page with comprehensive data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailPage(
                        appointment: result['data'],
                      ),
                    ),
                  );
                } else {
                  // Show error and fallback to existing data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to load detailed appointment data'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                  // Fallback to existing data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailPage(
                        appointment: widget.appointment,
                      ),
                    ),
                  );
                }
              }
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with created by info
              Row(
                children: [
                  // Created by Avatar (Square Box)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: createdByImage.isNotEmpty
                          ? Image.network(
                              createdByImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 25,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 25,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Created by name and designation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createdByName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (createdByDesignation.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            createdByDesignation,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                      ],
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 12),

              // Essential details only
              if (preferredDateRange.isNotEmpty) ...[
                _buildPreferredDateWidget(preferredDateRange),
                const SizedBox(height: 2),
              ],

              const SizedBox(height: 4),

              // Footer section with assigned secretary and people count
              _buildFooterSection(),

              const SizedBox(height: 8),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.schedule,
                    label: 'Schedule',
                    color: Colors.black,
                    onTap: () => _showActionBottomSheet(context, 'reminder'),
                  ),
                  _buildActionButton(
                    icon: Icons.email,
                    label: 'Email',
                    color: Colors.black,
                    onTap: () => _showActionBottomSheet(context, 'email'),
                  ),
                  _buildActionButton(
                    icon: Icons.message,
                    label: 'Message',
                    color: Colors.black,
                    onTap: () => _showActionBottomSheet(context, 'message'),
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Call',
                    color: Colors.black,
                    onTap: _makePhoneCall,
                  ),
                  _buildActionButton(
                    icon: Icons.assignment_ind,
                    label: 'Assign',
                    color: Colors.black,
                    onTap: () => _showActionBottomSheet(context, 'assign'),
                  ),
                  _buildActionButton(
                    icon: isStarred ? Icons.star : Icons.star_border,
                    label: 'Star',
                    color: isStarred ? Colors.amber : Colors.black,
                    onTap: () async {
                      // Show loading indicator
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Updating starred status...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }

                      // Call the API to update starred status
                      final result = await ActionService.updateStarred(id);

                      if (result['success']) {
                        // Update local state and notify parent
                        final newStarredStatus =
                            result['data']?['starred'] ?? !isStarred;
                        widget.onStarToggle?.call(newStarredStatus);

                        // Show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newStarredStatus
                                    ? 'Added to favorites'
                                    : 'Removed from favorites',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        // Show error message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ??
                                    'Failed to update starred status',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferredDateWidget(String dateRange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.amber[50]!.withOpacity(0.6),
            Colors.orange[50]!.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber[200]!.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dateRange,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    final assignedSecretary = _getAssignedSecretary();
    final attendeeCount = _getAttendeeCount();
    
    return Container(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          // Assigned secretary section
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 18,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignedSecretary.isNotEmpty ? assignedSecretary : 'Unassigned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: assignedSecretary.isNotEmpty ? Colors.grey[700] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // People count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300]!.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '$attendeeCount ${attendeeCount == 1 ? 'Person' : 'People'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPhoneNumber(dynamic phoneData) {
    if (phoneData is Map<String, dynamic>) {
      final countryCode = phoneData['countryCode']?.toString() ?? '';
      final number = phoneData['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode $number';
      }
    }
    return phoneData?.toString() ?? '';
  }

  int _getAttendeeCount() {
    final accompanyUsers = widget.appointment['accompanyUsers'];
    if (accompanyUsers is Map<String, dynamic>) {
      return accompanyUsers['numberOfUsers'] ?? 0;
    }
    return 1;
  }

  void _showActionBottomSheet(BuildContext context, String action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionContent(action),
    );
  }

  Future<void> _makePhoneCall() async {
    // Get the phone number from appointment data
    final phoneNumber = _getAppointeeMobile();
    
    if (phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create the phone URL
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAppointeeMobile() {
    final phoneNumber = widget.appointment['phoneNumber'];
    if (phoneNumber is Map<String, dynamic>) {
      final countryCode = phoneNumber['countryCode']?.toString() ?? '';
      final number = phoneNumber['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode$number';
      }
    }
    return phoneNumber?.toString() ?? '';
  }

  Widget _buildActionContent(String action) {
    switch (action) {
      case 'reminder':
        return _buildReminderContent();
      case 'email':
        return _buildEmailContent();
      case 'message':
        return _buildMessageContent();
      case 'call':
        return _buildCallContent();
      case 'assign':
        return _buildAssignContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Schedule Appointment'),
          Expanded(child: ReminderForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildEmailContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Send Email'),
          Expanded(child: EmailForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Send SMS'),
          Expanded(child: MessageForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Make Call'),
          Expanded(child: CallForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildAssignContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Assign Secretary'),
          Expanded(
            child: AssignForm(
              appointment: widget.appointment,
              onRefresh: widget.onRefresh, // Pass refresh callback
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(_getActionIcon(title), color: _getActionColor(title), size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'schedule':
        return Icons.schedule;
      case 'set reminder':
        return Icons.schedule;
      case 'send email':
        return Icons.email;
      case 'send sms':
        return Icons.message;
      case 'make call':
        return Icons.call;
      case 'assign appointment':
        return Icons.assignment_ind;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'schedule':
        return Colors.black;
      case 'set reminder':
        return Colors.black;
      case 'send email':
        return Colors.black;
      case 'send sms':
        return Colors.black;
      case 'make call':
        return Colors.black;
      case 'assign appointment':
        return Colors.black;
      default:
        return Colors.black;
    }
  }

  // New methods to get new fields
  String _getCreatedByName() {
    final createdBy = widget.appointment['createdBy'];
    if (createdBy is Map<String, dynamic>) {
      return createdBy['fullName']?.toString() ?? '';
    }
    return '';
  }

  String _getCreatedByDesignation() {
    // Use the main appointment's user designation since createdBy doesn't have this field
    return widget.appointment['userCurrentDesignation']?.toString() ??
        widget.appointment['userCurrentCompany']?.toString() ??
        '';
  }

  String _getCreatedByImage() {
    // Use the main appointment's profilePhoto since createdBy doesn't have this field
    return widget.appointment['profilePhoto']?.toString() ??
        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face';
  }

  String _getCreatedAt() {
    final createdAt = widget.appointment['createdAt'];
    if (createdAt is String) {
      final date = DateTime.tryParse(createdAt);
      if (date != null) {
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
    }
    return '';
  }

  String _getPreferredDateRange() {
    final preferredDateRange = widget.appointment['preferredDateRange'];
    if (preferredDateRange is Map<String, dynamic>) {
      final fromDate = preferredDateRange['fromDate']?.toString() ?? '';
      final toDate = preferredDateRange['toDate']?.toString() ?? '';
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        // Format dates for display in one line
        final from = DateTime.tryParse(fromDate);
        final to = DateTime.tryParse(toDate);
        if (from != null && to != null) {
          return '${from.day}/${from.month}/${from.year} to ${to.day}/${to.month}/${to.year}';
        }
      }
    }
    return '';
  }

  String _getAssignedSecretary() {
    final assignedSecretary = widget.appointment['assignedSecretary'];
    if (assignedSecretary is Map<String, dynamic>) {
      return assignedSecretary['fullName']?.toString() ?? '';
    }
    return '';
  }

  // New methods to get user contact information
  String _getUserMobile() {
    // Try to get userMobile from the appointment data
    final userMobile = widget.appointment['userMobile'];
    
    // Handle userMobile as an object with countryCode and number
    if (userMobile is Map<String, dynamic>) {
      final countryCode = userMobile['countryCode']?.toString() ?? '';
      final number = userMobile['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode $number';
      }
    }
    
    // Handle userMobile as a string
    if (userMobile is String && userMobile.isNotEmpty) {
      return userMobile;
    }
    
    // Try phoneNumber field (from the actual data structure)
    final phoneNumber = widget.appointment['phoneNumber'];
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
    
    // Try to get from userData if available
    final userData = widget.appointment['userData'];
    if (userData is Map<String, dynamic>) {
      final mobile = userData['phoneNumber']?.toString();
      if (mobile != null && mobile.isNotEmpty) {
        return mobile;
      }
    }
    
    // Try other possible field names
    final possibleMobileFields = ['mobile', 'userPhone', 'contactNumber', 'phone'];
    for (final field in possibleMobileFields) {
      final value = widget.appointment[field]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    return '';
  }

  String _getUserEmail() {
    // Try to get userEmail from the appointment data
    final userEmail = widget.appointment['userEmail']?.toString();
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    }
    
    // Try email field (from the actual data structure)
    final email = widget.appointment['email']?.toString();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    
    // Try to get from userData if available
    final userData = widget.appointment['userData'];
    if (userData is Map<String, dynamic>) {
      final email = userData['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    
    // Try other possible field names
    final possibleEmailFields = ['userEmail', 'contactEmail', 'primaryEmail'];
    for (final field in possibleEmailFields) {
      final value = widget.appointment[field]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    return '';
  }

  String _getReferencePhoneNumber() {
    // Try to get referencePhoneNumber from the appointment data
    final referencePhoneNumber = widget.appointment['referencePhoneNumber']?.toString();
    if (referencePhoneNumber != null && referencePhoneNumber.isNotEmpty) {
      return referencePhoneNumber;
    }
    
    // Try referencePerson.phoneNumber (from the actual data structure)
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
    
    // Try to get from userData if available
    final userData = widget.appointment['userData'];
    if (userData is Map<String, dynamic>) {
      final refPhone = userData['referencePhoneNumber']?.toString();
      if (refPhone != null && refPhone.isNotEmpty) {
        return refPhone;
      }
    }
    
    // Try other possible field names
    final possibleRefPhoneFields = ['referencePhone', 'refPhone', 'emergencyPhone', 'contactPhone'];
    for (final field in possibleRefPhoneFields) {
      final value = widget.appointment[field]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    return '';
  }

  String _getReferenceEmail() {
    // Try to get referenceEmail from the appointment data
    final referenceEmail = widget.appointment['referenceEmail']?.toString();
    if (referenceEmail != null && referenceEmail.isNotEmpty) {
      return referenceEmail;
    }
    
    // Try referencePerson.email (from the actual data structure)
    final referencePerson = widget.appointment['referencePerson'];
    if (referencePerson is Map<String, dynamic>) {
      final email = referencePerson['email']?.toString();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    
    // Try to get from userData if available
    final userData = widget.appointment['userData'];
    if (userData is Map<String, dynamic>) {
      final refEmail = userData['referenceEmail']?.toString();
      if (refEmail != null && refEmail.isNotEmpty) {
        return refEmail;
      }
    }
    
    // Try other possible field names
    final possibleRefEmailFields = ['referenceEmail', 'refEmail', 'emergencyEmail', 'contactEmail'];
    for (final field in possibleRefEmailFields) {
      final value = widget.appointment[field]?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    
    return '';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
