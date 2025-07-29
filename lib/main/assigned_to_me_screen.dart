import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../action/jwt_utils.dart';

class AssignedToMeScreen extends StatefulWidget {
  const AssignedToMeScreen({super.key});

  @override
  State<AssignedToMeScreen> createState() => _AssignedToMeScreenState();
}

class _AssignedToMeScreenState extends State<AssignedToMeScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentUser;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndAppointments();
  }

  Future<void> _loadCurrentUserAndAppointments() async {
    await _loadCurrentUser();
    await _fetchAppointments();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // First try to get user data from JWT token
      final token = await StorageService.getToken();
      if (token != null) {
        // Extract MongoDB ID from JWT token
        final mongoId = JwtUtils.extractMongoId(token);
        if (mongoId != null) {
          setState(() {
            _currentUserId = mongoId;
          });
        }

        // Also get user info from JWT token
        final userInfo = JwtUtils.getUserInfoFromToken(token);
        if (userInfo != null) {
          setState(() {
            _currentUser = userInfo;
          });
        }
      }

      // Fallback to stored user data if JWT extraction fails
      if (_currentUser == null) {
        final userData = await StorageService.getUserData();
        setState(() {
          _currentUser = userData;
          _currentUserId = userData?['userId']?.toString();
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the new method that extracts MongoDB ID from JWT token
      final result = await ActionService.getAssignedToMeAppointments();
      
      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];
        
        if (appointmentsData.isNotEmpty) {
          _appointments = appointmentsData.cast<Map<String, dynamic>>();
        } else {
          _appointments = [];
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to fetch appointments';
        _appointments = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _appointments = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStar(String appointmentId) async {
    // Call the API to update starred status
    final result = await ActionService.updateStarred(appointmentId);
    
    if (result['success']) {
      setState(() {
        final index = _appointments.indexWhere((appointment) => appointment['_id'] == appointmentId);
        if (index != -1) {
          // Update the starred status based on API response
          final newStarredStatus = result['data']?['starred'] ?? false;
          _appointments[index]['starred'] = newStarredStatus;
        }
      });
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update starred status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteAppointment(String appointmentId) {
    setState(() {
      _appointments.removeWhere((appointment) => appointment['_id'] == appointmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: const SidebarComponent(),
      appBar: AppBar(
        title: const Text('Assigned to Me'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAppointments();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No appointments assigned to you',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have no appointments assigned to you',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments[index];
                    return AppointmentCard(
                      appointment: appointment,
                      onStarToggle: (isStarred) async {
                        final appointmentId = appointment['appointmentId']?.toString() ?? 
                                            appointment['_id']?.toString() ?? '';
                        await _toggleStar(appointmentId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isStarred ? 'Added to favorites' : 'Removed from favorites'),
                              backgroundColor: Colors.green,
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: Colors.white,
                                onPressed: () async {
                                  await _toggleStar(appointmentId);
                                },
                              ),
                            ),
                          );
                        }
                      },
                      onDelete: () {
                        _deleteAppointment(appointment['_id']?.toString() ?? '');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${appointment['name']?.toString() ?? ''} deleted'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
} 