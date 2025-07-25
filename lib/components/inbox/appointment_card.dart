import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import 'appointment_schedule_form.dart';
import 'email_form.dart';
import 'darshan_line_form.dart';
import 'reminder_form.dart';
import 'call_form.dart';
import 'assign_form.dart';
import 'star_form.dart';
import 'delete_form.dart';

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final Function(String)? onStatusChange;
  final Function(String)? onEmail;
  final Function(String)? onDarshanLineChange;
  final Function(String)? onBackstageChange;
  final Function(String)? onAssignTo;
  final Function(bool)? onStarToggle;
  final VoidCallback? onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onStatusChange,
    this.onEmail,
    this.onDarshanLineChange,
    this.onBackstageChange,
    this.onAssignTo,
    this.onStarToggle,
    this.onDelete,
  });

  @override
  State<AppointmentCard> createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> {

    void _showActionBottomSheet(String actionType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            

            
            // Content based on action type
            Expanded(
              child: _buildActionContent(actionType),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'reminder':
        return Icons.notifications_active;
      case 'email':
        return Icons.email_outlined;
      case 'darshan':
        return Icons.queue;
      case 'call':
        return Icons.phone;
      case 'assign':
        return Icons.group_add;
      case 'star':
        return Icons.star;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'reminder':
        return Colors.orange;
      case 'email':
        return Colors.blue;
      case 'darshan':
        return Colors.purple;
      case 'call':
        return Colors.green;
      case 'assign':
        return Colors.indigo;
      case 'star':
        return widget.appointment.isStarred ? Colors.amber : Colors.grey;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionTitle(String actionType) {
    switch (actionType) {
      case 'reminder':
        return 'Set Reminder';
      case 'email':
        return 'Send Email';
      case 'darshan':
        return 'Move to Line';
      case 'call':
        return 'Call Options';
      case 'assign':
        return 'Assign to Team';
      case 'star':
        return widget.appointment.isStarred ? 'Remove from Favorites' : 'Add to Favorites';
      case 'delete':
        return 'Delete Appointment';
      default:
        return 'Action';
    }
  }

  Widget _buildActionContent(String actionType) {
    switch (actionType) {
      case 'reminder':
        return _buildReminderContent();
      case 'email':
        return _buildEmailContent();
      case 'call':
        return _buildCallContent();
      case 'assign':
        return _buildAssignContent();
      case 'star':
        return _buildStarContent();
      case 'delete':
        return _buildDeleteContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReminderContent() {
    return AppointmentScheduleForm(
      appointmentId: widget.appointment.id,
      appointmentName: widget.appointment.name,
      onSave: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment scheduled for ${widget.appointment.name}'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onClose: () {
        // Close the bottom sheet
        Navigator.pop(context);
      },
    );
  }



  Widget _buildEmailContent() {
    return EmailForm(
      appointmentId: widget.appointment.id,
      appointmentName: widget.appointment.name,
      appointeeEmail: 'bishnupriyatripathy1997@gmail.com', // This should come from appointment data
      onSend: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email sent for ${widget.appointment.name}'),
            backgroundColor: Colors.green,
          ),
        );
      },
      onClose: () {
        Navigator.pop(context);
      },
    );
  }

  void _showReminderOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReminderForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment scheduled for ${widget.appointment.name}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEmailOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmailForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        appointeeEmail: 'bishnupriyatripathy1997@gmail.com',
        onSend: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email sent for ${widget.appointment.name}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDarshanLineOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DarshanLineForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        onDarshanLineChange: (value) {
          Navigator.pop(context);
          widget.onDarshanLineChange?.call(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved ${widget.appointment.name} to $value'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onBackstageChange: (value) {
          Navigator.pop(context);
          widget.onBackstageChange?.call(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved ${widget.appointment.name} to $value'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCallOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        phoneNumber: widget.appointment.phoneNumber,
        onCall: () {
          // Handle call action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${widget.appointment.name}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAssignOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssignForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        availableAssignees: widget.appointment.availableAssignees,
        onAssignTo: (value) {
          widget.onAssignTo?.call(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assigned ${widget.appointment.name}'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStarOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StarForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        isStarred: widget.appointment.isStarred,
        onStarToggle: (value) {
          widget.onStarToggle?.call(value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.appointment.isStarred 
                ? 'Removed from favorites' 
                : 'Added to favorites'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeleteForm(
        appointmentId: widget.appointment.id,
        appointmentName: widget.appointment.name,
        onDelete: () {
          widget.onDelete?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${widget.appointment.name}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onClose: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCallContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: Text('Call ${widget.appointment.name}'),
            subtitle: Text(widget.appointment.phoneNumber),
            onTap: () {
              Navigator.pop(context);
              // Handle call action
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: widget.appointment.availableAssignees.map((assignee) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo[100],
              child: Text(
                assignee.initials,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            title: Text(assignee.name),
            onTap: () {
              Navigator.pop(context);
              widget.onAssignTo?.call('${widget.appointment.id}|${assignee.id}|${assignee.name}');
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStarContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              widget.appointment.isStarred ? Icons.star : Icons.star_border,
              color: widget.appointment.isStarred ? Colors.amber : Colors.grey,
            ),
            title: Text(widget.appointment.isStarred ? 'Remove from Favorites' : 'Add to Favorites'),
            onTap: () {
              Navigator.pop(context);
              widget.onStarToggle?.call(!widget.appointment.isStarred);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text('Delete Appointment'),
            subtitle: Text('This action cannot be undone'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Appointment'),
                    ],
                  ),
                  content: Text('Are you sure you want to delete this appointment for ${widget.appointment.name}? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required String actionType,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: IconButton(
          onPressed: () => _showActionBottomSheet(actionType),
          icon: Icon(icon, color: color, size: 20),
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Image + Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        widget.appointment.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 30),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Name and Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.appointment.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Role
                        Text(
                          widget.appointment.role,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Middle: Number of people (left) + Date & Time (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Number of people and assignment
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.appointment.attendeeCount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.appointment.assignedTo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Right: Date & Time
                  Text(
                    '${widget.appointment.date} ${widget.appointment.time}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Date Range
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.appointment.dateRange,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons at bottom - left to right
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status/Reminder button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showReminderOptions(),
                          icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                          tooltip: 'Set Reminder',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Email button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showEmailOptions(),
                          icon: const Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                          tooltip: 'Send Email',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Darshan line button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showDarshanLineOptions(),
                          icon: const Icon(Icons.queue, color: Colors.purple, size: 20),
                          tooltip: 'Move to Line',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Call button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showCallOptions(),
                          icon: const Icon(Icons.phone, color: Colors.green, size: 20),
                          tooltip: 'Call',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Assign button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showAssignOptions(),
                          icon: const Icon(Icons.group_add, color: Colors.indigo, size: 20),
                          tooltip: 'Assign to Team',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Star/Favorite button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showStarOptions(),
                          icon: Icon(
                            widget.appointment.isStarred ? Icons.star : Icons.star_border,
                            color: widget.appointment.isStarred ? Colors.amber : Colors.grey,
                            size: 20
                          ),
                          tooltip: widget.appointment.isStarred ? 'Remove from Favorites' : 'Add to Favorites',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                    
                    // Delete button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => _showDeleteOptions(),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Delete Appointment',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 