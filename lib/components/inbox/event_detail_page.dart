import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../user/event_appointment_screen.dart';
import '../../action/action.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onEventUpdated; // Callback to refresh after update

  const EventDetailPage({
    super.key,
    required this.event,
    this.onEventUpdated,
  });

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late Map<String, dynamic> _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  Future<void> _refreshEventData() async {
    final eventId = _currentEvent['eventId']?.toString();
    if (eventId != null && eventId.isNotEmpty) {
      final eventResult = await ActionService.getEventById(eventId);
      if (mounted && eventResult['success'] == true) {
        setState(() {
          _currentEvent = eventResult['data'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: const Color(0xFFF97316), // Orange color
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            // Action Buttons Card
            _buildActionButtonsCard(),
            const SizedBox(height: 0),
            // Event Information Card
            _buildEventInformationCard(),
            const SizedBox(height: 0),
            // Event Description Card
            _buildEventDescriptionCard(),
            const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Schedule Button
          _buildActionButton(
            icon: Icons.schedule,
            label: 'Schedule',
            onTap: () => _showScheduleBottomSheet(),
            hoverColor: Colors.blue,
          ),
          // Edit Button
          _buildActionButton(
            icon: Icons.edit,
            label: 'Edit',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventAppointmentScreen(
                    eventData: _currentEvent,
                  ),
                ),
              );
              
              if (result == true) {
                await _refreshEventData();
                if (widget.onEventUpdated != null) {
                  widget.onEventUpdated!();
                }
              }
            },
            hoverColor: Colors.blue,
          ),
          // Delete Button
          _buildActionButton(
            icon: Icons.delete,
            label: 'Delete',
            onTap: () => _showDeleteConfirmation(),
            hoverColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color hoverColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInformationCard() {
    final event = _currentEvent;
    final eventId = event['eventId']?.toString() ?? '';
    final eventName = event['eventName']?.toString() ?? 
                     event['name']?.toString() ?? 
                     'Event';
    final eventStatus = event['eventStatus']?.toString() ?? 
                       event['status']?.toString() ?? 
                       'pending';
    final eventCapacity = event['eventCapacity'] ?? 0;
    final scheduledDate = event['scheduledDate']?.toString();
    final eventFromDateTime = event['fromDateTime']?.toString() ?? 
                             event['eventFromDateTime']?.toString();
    final eventToDateTime = event['toDateTime']?.toString() ?? 
                           event['eventToDateTime']?.toString();
    final createdAt = event['createdAt']?.toString() ?? '';
    final eventLocation = event['eventLocation']?.toString() ?? 
                         event['location']?.toString() ?? 
                         'N/A';
    final eventImage = event['eventImage']?.toString() ?? '';
    final createdBy = event['createdBy'];
    final createdByName = _getCreatedByName(createdBy);
    final createdByEmail = _getCreatedByEmail(createdBy);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with event info
          Row(
            children: [
              // Event Image (Square)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: eventImage.isNotEmpty
                      ? Image.network(
                          eventImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.event,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.event,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Event Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Event ID: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    eventId,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: eventId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event ID copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Event Details Rows
          _buildStatusAndCapacityRow(eventStatus, eventCapacity.toString()),
          // Show scheduled date as "Appointment Date" if scheduled, otherwise show from/to dates
          if (scheduledDate != null && scheduledDate.isNotEmpty && scheduledDate != 'null')
            _buildMainCardDetailRow('Appointment Date', _formatDateTime(scheduledDate), Icons.calendar_today),
          if (scheduledDate == null || scheduledDate.isEmpty || scheduledDate == 'null') ...[
            if (eventFromDateTime != null && eventFromDateTime.isNotEmpty)
              _buildMainCardDetailRow('From Date', _formatDateTime(eventFromDateTime), Icons.calendar_today),
            if (eventToDateTime != null && eventToDateTime.isNotEmpty)
              _buildMainCardDetailRow('To Date', _formatDateTime(eventToDateTime), Icons.calendar_today),
          ],
          if (createdAt.isNotEmpty)
            _buildMainCardDetailRow('Created On', _formatDateOnly(createdAt), Icons.access_time),
          _buildMainCardDetailRow('Location', eventLocation, Icons.location_on),
          _buildMainCardDetailRow('Created By', createdByName, Icons.person),
          if (createdByEmail.isNotEmpty)
            _buildMainCardDetailRow('Email', createdByEmail, Icons.email),
        ],
      ),
    );
  }

  Widget _buildMainCardDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndCapacityRow(String status, String capacity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          // Status
          Text(
            'Status: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4), // Light yellow
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B4513), // Brown
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  status.toLowerCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B4513), // Brown
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Capacity
          Icon(Icons.people, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            'Capacity: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            capacity,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescriptionCard() {
    final event = _currentEvent;
    final eventDescription = event['eventDescription']?.toString() ?? '';
    
    if (eventDescription.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: const Color(0xFF1976D2),
              ),
              const SizedBox(width: 8),
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            eventDescription,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateOnly(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    
    try {
      final dateUtc = DateTime.parse(dateStr);
      final date = dateUtc.toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    
    try {
      final dateUtc = DateTime.parse(dateStr);
      final date = dateUtc.toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      // Format time in 12-hour format
      int hour = date.hour;
      String period = 'AM';
      if (hour == 0) {
        hour = 12;
      } else if (hour == 12) {
        period = 'PM';
      } else if (hour > 12) {
        hour = hour - 12;
        period = 'PM';
      }
      
      final minute = date.minute.toString().padLeft(2, '0');
      
      return '${months[date.month - 1]} ${date.day}, ${date.year} ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return dateStr;
    }
  }

  String _getCreatedByName(dynamic createdBy) {
    if (createdBy is Map<String, dynamic>) {
      return createdBy['fullName']?.toString() ?? 'N/A';
    }
    return 'N/A';
  }

  String _getCreatedByEmail(dynamic createdBy) {
    if (createdBy is Map<String, dynamic>) {
      return createdBy['email']?.toString() ?? '';
    }
    return '';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent() async {
    // TODO: Implement delete API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delete functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showScheduleBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleEventBottomSheet(
        event: _currentEvent,
        onScheduleSuccess: () {
          Navigator.of(context).pop();
          _refreshEventData();
          if (widget.onEventUpdated != null) {
            widget.onEventUpdated!();
          }
        },
      ),
    );
  }

}

class _ScheduleEventBottomSheet extends StatefulWidget {
  final Map<String, dynamic> event;
  final VoidCallback onScheduleSuccess;

  const _ScheduleEventBottomSheet({
    required this.event,
    required this.onScheduleSuccess,
  });

  @override
  State<_ScheduleEventBottomSheet> createState() => _ScheduleEventBottomSheetState();
}

class _ScheduleEventBottomSheetState extends State<_ScheduleEventBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedStatus = 'scheduled';
  bool _isLoading = false;

  // API status values - only show Scheduled and Rejected for scheduling
  final List<String> _statusOptions = [
    'scheduled',
    'rejected',
  ];

  // Map API values to display text
  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill venue
    final eventLocation = widget.event['eventLocation']?.toString() ?? 
                         widget.event['location']?.toString() ?? '';
    _venueController.text = eventLocation;
    
    // Pre-fill with existing scheduled date/time if available, otherwise use fromDateTime
    final scheduledDate = widget.event['scheduledDate']?.toString();
    final eventFromDateTime = widget.event['fromDateTime']?.toString() ?? 
                             widget.event['eventFromDateTime']?.toString();
    
    // Prefer scheduledDate if available, otherwise use fromDateTime
    final dateToUse = (scheduledDate != null && scheduledDate.isNotEmpty && scheduledDate != 'null') 
        ? scheduledDate 
        : eventFromDateTime;
    
    if (dateToUse != null && dateToUse.isNotEmpty) {
      try {
        final dateUtc = DateTime.parse(dateToUse);
        final date = dateUtc.toLocal();
        _selectedDate = date;
        _selectedTime = TimeOfDay.fromDateTime(date);
        _dateController.text = _formatDateForDisplay(date);
        _timeController.text = _formatTimeForDisplay(_selectedTime!);
      } catch (e) {
        print('Error parsing event date: $e');
      }
    }
    
    // Pre-fill status from event data if available
    final eventStatus = widget.event['eventStatus']?.toString() ?? 
                       widget.event['status']?.toString() ?? '';
    if (eventStatus.isNotEmpty && _statusOptions.contains(eventStatus.toLowerCase())) {
      _selectedStatus = eventStatus.toLowerCase();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  String _formatDateForDisplay(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${date.day} ${months[date.month - 1]} ${date.year} (${weekdays[date.weekday - 1]})';
  }

  String _formatTimeForDisplay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = _formatDateForDisplay(pickedDate);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = _formatTimeForDisplay(pickedTime);
      });
    }
  }

  Future<void> _scheduleEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final eventId = widget.event['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Combine date and time into a DateTime object in local time
    final DateTime combinedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    
    // Convert to UTC and format as ISO 8601 string for scheduledDate
    final DateTime utcDateTime = combinedDateTime.toUtc();
    final scheduledDate = utcDateTime.toIso8601String();
    
    // Get venue from controller
    final eventLocation = _venueController.text.trim();

    print('📅 Sending reschedule request:');
    print('   Event ID: $eventId');
    print('   Status: $_selectedStatus');
    print('   Scheduled Date: $scheduledDate');
    print('   Event Location: $eventLocation');
    print('   Combined DateTime (local): ${combinedDateTime.toIso8601String()}');
    print('   Combined DateTime (UTC): ${utcDateTime.toIso8601String()}');

    final result = await ActionService.rescheduleEvent(
      eventId: eventId,
      status: _selectedStatus,
      scheduledDate: scheduledDate,
      eventLocation: eventLocation.isNotEmpty ? eventLocation : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Event scheduled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onScheduleSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to schedule event'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventName = widget.event['eventName']?.toString() ?? 
                     widget.event['name']?.toString() ?? 
                     'Event';
    
    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Event',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set the scheduled date, time, and venue for this event.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name Section
                    Text(
                      'EVENT NAME',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        eventName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Scheduled Date & Time Section
                    const Text(
                      'Scheduled Date & Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Date Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Date '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dateController.text.isEmpty ? 'Select Date' : _dateController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _dateController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Time Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Time '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _timeController.text.isEmpty ? 'Select Time' : _timeController.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _timeController.text.isEmpty ? Colors.grey[500] : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Venue Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Venue '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _venueController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[700]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Venue is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Event Status Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(text: 'Event Status '),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue[700]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          items: _statusOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(_getStatusDisplayText(status)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedStatus = newValue;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _scheduleEvent,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Schedule Event',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
