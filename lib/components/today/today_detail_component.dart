import 'package:flutter/material.dart';

class TodayDetailComponent extends StatefulWidget {
  final String categoryTitle;
  final Color categoryColor;
  final IconData categoryIcon;
  final List<Map<String, dynamic>> appointments;

  const TodayDetailComponent({
    super.key,
    required this.categoryTitle,
    required this.categoryColor,
    required this.categoryIcon,
    required this.appointments,
  });

  @override
  State<TodayDetailComponent> createState() => _TodayDetailComponentState();
}

class _TodayDetailComponentState extends State<TodayDetailComponent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.categoryIcon,
                  color: widget.categoryColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: widget.categoryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.appointments.length} appointments',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Appointments list
          Expanded(
            child: widget.appointments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments in this category',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = widget.appointments[index];
                      return _buildAppointmentCard(appointment, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with time and status
            Row(
              children: [
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getTimeForAppointment(appointment),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.categoryColor,
                    ),
                  ),
                ),
                const Spacer(),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(appointment['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(appointment['status']),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // User information
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.categoryColor.withOpacity(0.2),
                  child: Text(
                    _getUserInitials(appointment),
                    style: TextStyle(
                      color: widget.categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAppointmentName(appointment),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserEmail(appointment),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Location information
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getLocation(appointment),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Additional details
            if (_getUserDesignation(appointment).isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.work,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getUserDesignation(appointment),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeForAppointment(Map<String, dynamic> appointment) {
    // Try multiple time fields in order of preference
    final timeString = appointment['scheduledTime']?.toString() ?? 
                      appointment['preferredTime']?.toString() ?? 
                      appointment['createdAt']?.toString();
    
    if (timeString == null) return 'No time';
    
    try {
      final time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }

  String _getAppointmentName(Map<String, dynamic> appointment) {
    return appointment['userCurrentDesignation']?.toString() ?? 
           appointment['email']?.toString() ?? 'Unknown';
  }

  String _getUserEmail(Map<String, dynamic> appointment) {
    return appointment['email']?.toString() ?? 'No email';
  }

  String _getUserDesignation(Map<String, dynamic> appointment) {
    return appointment['userCurrentDesignation']?.toString() ?? '';
  }

  String _getUserInitials(Map<String, dynamic> appointment) {
    final name = _getAppointmentName(appointment);
    if (name == 'Unknown') return 'U';
    
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String _getLocation(Map<String, dynamic> appointment) {
    // First try to get location from appointmentLocation object
    final appointmentLocation = appointment['appointmentLocation'];
    if (appointmentLocation is Map<String, dynamic>) {
      final name = appointmentLocation['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Fallback to other location fields
    final location = appointment['location'];
    if (location is Map<String, dynamic>) {
      final name = location['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    
    // Try other string fields
    final locationString = appointment['locationName']?.toString() ?? 
                          appointment['venue']?.toString() ?? 
                          appointment['address']?.toString() ?? 
                          appointment['city']?.toString() ?? 
                          appointment['state']?.toString() ?? 
                          appointment['country']?.toString();
    
    if (locationString != null && locationString.isNotEmpty) {
      return locationString;
    }
    
    return 'Location not specified';
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'pending':
      case 'tbs':
      case 'requested':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Unknown';
    
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'tbs':
        return 'TBS';
      case 'requested':
        return 'Requested';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
} 