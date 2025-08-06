import 'package:flutter/material.dart';
import '../../action/action.dart';
import '../../action/storage_service.dart';
import '../../action/jwt_utils.dart';

class AssignForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Function(String)? onAssignTo;
  final VoidCallback? onClose;
  final VoidCallback? onRefresh; // Add refresh callback

  const AssignForm({
    Key? key,
    required this.appointment,
    this.onAssignTo,
    this.onClose,
    this.onRefresh, // Add refresh callback parameter
  }) : super(key: key);

  @override
  State<AssignForm> createState() => _AssignFormState();
}

class _AssignFormState extends State<AssignForm> {
  List<Map<String, dynamic>> _availableAssignees = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _assignedSecretaryId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSecretaries();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Get current user ID from JWT token
      final token = await StorageService.getToken();
      if (token != null) {
        final mongoId = JwtUtils.extractMongoId(token);
        setState(() {
          _currentUserId = mongoId;
        });
      }

      // Get assigned secretary name from appointment data (same as appointment card)
      final assignedSecretary = widget.appointment['assignedSecretary'];
      if (assignedSecretary is Map<String, dynamic>) {
        setState(() {
          _assignedSecretaryId = assignedSecretary['fullName']?.toString();
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadSecretaries() async {
    print('DEBUG: _loadSecretaries() called');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Extract location ID from appointment data
      final locationId = _extractLocationId();
      print('DEBUG: Extracted locationId = $locationId');
      
      if (locationId == null) {
        print('DEBUG: No location ID found - showing error');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location information not available';
          _availableAssignees = [];
        });
        return;
      }

      print('DEBUG: Calling API with locationId = $locationId');
      // Call the API to get secretaries for this location
      final result = await ActionService.getAssignedSecretariesByAshramLocation(
        locationId: locationId,
      );

      print('DEBUG: API result = $result');

      if (result['success']) {
        final List<dynamic> secretariesData = result['data'] ?? [];
        print('DEBUG: Secretaries data count = ${secretariesData.length}');
        
        // Transform the API response to match our expected format
        final List<Map<String, dynamic>> secretaries = secretariesData.map((secretary) {
          final secretaryId = secretary['secretaryId']?.toString() ?? '';
          final secretaryName = secretary['fullName']?.toString() ?? '';
          final isCurrentUser = secretaryId == _currentUserId;
          final isAssigned = secretaryName == _assignedSecretaryId;
          
          print('DEBUG: Processing secretary - ID: $secretaryId, Name: $secretaryName, isCurrentUser: $isCurrentUser, isAssigned: $isAssigned');
          
          return {
            'id': secretaryId,
            'name': secretaryName,
            'isCurrentUser': isCurrentUser,
            'isAssigned': isAssigned,
          };
        }).toList();

        print('DEBUG: Final secretaries list count = ${secretaries.length}');
        setState(() {
          _availableAssignees = secretaries;
          _isLoading = false;
        });
      } else {
        print('DEBUG: API call failed - ${result['message']}');
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Failed to load secretaries';
          _availableAssignees = [];
        });
      }
    } catch (error) {
      print('DEBUG: Exception in _loadSecretaries: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error: $error';
        _availableAssignees = [];
      });
    }
  }

  String? _extractLocationId() {
    print('DEBUG: _extractLocationId() called');
    print('DEBUG: Appointment keys: ${widget.appointment.keys.toList()}');
    
    // Try to get location ID from various possible fields
    final appointmentLocation = widget.appointment['appointmentLocation'];
    print('DEBUG: appointmentLocation = $appointmentLocation');
    if (appointmentLocation != null) {
      if (appointmentLocation is Map<String, dynamic>) {
        final id = appointmentLocation['_id']?.toString();
        print('DEBUG: Extracted _id from appointmentLocation = $id');
        return id;
      }
      print('DEBUG: Using appointmentLocation as string = ${appointmentLocation.toString()}');
      return appointmentLocation.toString();
    }

    final location = widget.appointment['location'];
    print('DEBUG: location = $location');
    if (location != null) {
      if (location is Map<String, dynamic>) {
        final id = location['_id']?.toString();
        print('DEBUG: Extracted _id from location = $id');
        return id;
      }
      print('DEBUG: Using location as string = ${location.toString()}');
      return location.toString();
    }

    final venue = widget.appointment['venue'];
    print('DEBUG: venue = $venue');
    if (venue != null) {
      if (venue is Map<String, dynamic>) {
        final id = venue['_id']?.toString();
        print('DEBUG: Extracted _id from venue = $id');
        return id;
      }
      print('DEBUG: Using venue as string = ${venue.toString()}');
      return venue.toString();
    }

    // Try scheduledDateTime.venue as well
    final scheduledDateTime = widget.appointment['scheduledDateTime'];
    print('DEBUG: scheduledDateTime = $scheduledDateTime');
    if (scheduledDateTime is Map<String, dynamic>) {
      final venue = scheduledDateTime['venue'];
      print('DEBUG: venue from scheduledDateTime = $venue');
      if (venue != null) {
        if (venue is Map<String, dynamic>) {
          final id = venue['_id']?.toString();
          print('DEBUG: Extracted _id from scheduledDateTime.venue = $id');
          return id;
        }
        print('DEBUG: Using scheduledDateTime.venue as string = ${venue.toString()}');
        return venue.toString();
      }
    }

    // If no location ID found, return null
    print('DEBUG: No location ID found - returning null');
    return null;
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _assignTo(String assigneeId, String assigneeName) async {
    try {
      setState(() {
        _isAssigning = true;
        _errorMessage = null;
      });

      // Call the API to update assigned secretary
      final result = await ActionService.updateAssignedSecretary(
        appointmentId: _getAppointmentId(),
        secretaryId: assigneeId,
      );

      if (result['success']) {
        // Success - call the callback, refresh parent, and close
        widget.onAssignTo?.call('${_getAppointmentId()}|$assigneeId|$assigneeName');
        widget.onRefresh?.call(); // Trigger refresh of parent screen
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assigned to $assigneeName successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        Navigator.pop(context);
      } else {
        // Show error message
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to assign secretary';
          _isAssigning = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Network error: $error';
        _isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                const Text(
                  'Available secretaries for this location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_isAssigning)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Error message if any
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Secretary list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading secretaries...'),
                        ],
                      ),
                    ),
                  )
                : _availableAssignees.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No secretaries available for this location',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _availableAssignees.map((assignee) {
                            final isAssigned = assignee['isAssigned'] == true;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isAssigned 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAssigned 
                                      ? Colors.green.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                                  width: isAssigned ? 2 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: _isAssigning ? null : () async {
                                  await _assignTo(assignee['id'], assignee['name']);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isAssigned 
                                            ? Colors.green[100]
                                            : Colors.indigo[100],
                                        child: Text(
                                          _getInitials(assignee['name']),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isAssigned ? Colors.green : Colors.indigo,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          assignee['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isAssigned ? Colors.green[700] : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isAssigned)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        )
                                      else
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
} 