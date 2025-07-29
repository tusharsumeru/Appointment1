import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';

class AssignedToMeScreen extends StatefulWidget {
  const AssignedToMeScreen({super.key});

  @override
  State<AssignedToMeScreen> createState() => _AssignedToMeScreenState();
}

class _AssignedToMeScreenState extends State<AssignedToMeScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ActionService.getAppointmentsForSecretary();
      
      if (result['success']) {
        final List<dynamic> allAppointments = result['data'] ?? [];
        // Filter appointments assigned to KK
        _appointments = allAppointments
            .cast<Map<String, dynamic>>()
            .where((appointment) => 
                appointment['assignedTo']?.toString().contains('KK') == true)
            .toList();
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

  void _toggleStar(String appointmentId) {
    setState(() {
      final index = _appointments.indexWhere((appointment) => appointment['_id'] == appointmentId);
      if (index != -1) {
        _appointments[index]['isStarred'] = !(_appointments[index]['isStarred'] == true);
      }
    });
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
        title: const Text('Assigned to Me (KK)'),
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
                        'You have no appointments assigned to KK',
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
                      onStarToggle: (isStarred) {
                        _toggleStar(appointment['_id']?.toString() ?? '');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isStarred ? 'Added to favorites' : 'Removed from favorites'),
                            backgroundColor: Colors.green,
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                _toggleStar(appointment['_id']?.toString() ?? '');
                              },
                            ),
                          ),
                        );
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