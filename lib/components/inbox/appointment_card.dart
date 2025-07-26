import 'package:flutter/material.dart';
import 'appointment_detail_page.dart';
import 'appointment_schedule_form.dart';
import 'email_form.dart';
import 'darshan_line_form.dart';
import 'reminder_form.dart';
import 'call_form.dart';
import 'assign_form.dart';
import 'star_form.dart';
import 'delete_form.dart';

class AppointmentCard extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onTap;
  final Function(bool)? onStarToggle;
  final VoidCallback? onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onStarToggle,
    this.onDelete,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {
  @override
  Widget build(BuildContext context) {
    // Extract only essential data
    final String id = widget.appointment['_id']?.toString() ?? '';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailPage(appointment: widget.appointment),
            ),
          );
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
                  // Created by Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(createdByImage),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Handle image loading error
                    },
                    child: createdByImage.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
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
                        if (createdAt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Created: $createdAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Star button
                  IconButton(
                    onPressed: () {
                      widget.onStarToggle?.call(!isStarred);
                    },
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred ? Colors.amber : Colors.grey,
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Essential details only
              if (preferredDateRange.isNotEmpty) ...[
                _buildDetailRow('Preferred Dates', preferredDateRange),
                const SizedBox(height: 4),
              ],
              if (attendeeCount > 0) ...[
                _buildDetailRow('Attendees', '$attendeeCount person${attendeeCount > 1 ? 's' : ''}'),
                const SizedBox(height: 4),
              ],
              if (_getAssignedSecretary().isNotEmpty) ...[
                _buildDetailRow('Assigned To', _getAssignedSecretary()),
                const SizedBox(height: 4),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.schedule,
                    label: 'Reminder',
                    color: Colors.blue,
                    onTap: () => _showActionBottomSheet(context, 'reminder'),
                  ),
                  _buildActionButton(
                    icon: Icons.email,
                    label: 'Email',
                    color: Colors.green,
                    onTap: () => _showActionBottomSheet(context, 'email'),
                  ),
                  _buildActionButton(
                    icon: Icons.queue,
                    label: 'Darshan',
                    color: Colors.orange,
                    onTap: () => _showActionBottomSheet(context, 'darshan'),
                  ),
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Call',
                    color: Colors.purple,
                    onTap: () => _showActionBottomSheet(context, 'call'),
                  ),
                  _buildActionButton(
                    icon: Icons.assignment_ind,
                    label: 'Assign',
                    color: Colors.teal,
                    onTap: () => _showActionBottomSheet(context, 'assign'),
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: () => _showActionBottomSheet(context, 'delete'),
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
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      return accompanyUsers['numberOfUsers'] ?? 1;
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

  Widget _buildActionContent(String action) {
    switch (action) {
      case 'reminder':
        return _buildReminderContent();
      case 'email':
        return _buildEmailContent();
      case 'darshan':
        return _buildDarshanLineContent();
      case 'call':
        return _buildCallContent();
      case 'assign':
        return _buildAssignContent();
      case 'delete':
        return _buildDeleteContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Set Reminder'),
          Expanded(child: ReminderForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildEmailContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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

  Widget _buildDarshanLineContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Darshan Line'),
          Expanded(child: DarshanLineForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildCallContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Assign Appointment'),
          Expanded(child: AssignForm(appointment: widget.appointment)),
        ],
      ),
    );
  }

  Widget _buildDeleteContent() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildActionHeader('Delete Appointment'),
          Expanded(child: DeleteForm(
            appointment: widget.appointment,
            onDelete: widget.onDelete,
          )),
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
          Icon(
            _getActionIcon(title),
            color: _getActionColor(title),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
      case 'set reminder':
        return Icons.schedule;
      case 'send email':
        return Icons.email;
      case 'darshan line':
        return Icons.queue;
      case 'make call':
        return Icons.call;
      case 'assign appointment':
        return Icons.assignment_ind;
      case 'delete appointment':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'set reminder':
        return Colors.blue;
      case 'send email':
        return Colors.green;
      case 'darshan line':
        return Colors.orange;
      case 'make call':
        return Colors.purple;
      case 'assign appointment':
        return Colors.teal;
      case 'delete appointment':
        return Colors.red;
      default:
        return Colors.grey;
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
           widget.appointment['userCurrentCompany']?.toString() ?? '';
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