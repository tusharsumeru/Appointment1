import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';

class StarredScreen extends StatefulWidget {
  const StarredScreen({super.key});

  @override
  State<StarredScreen> createState() => _StarredScreenState();
}

class _StarredScreenState extends State<StarredScreen> {
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
        // Filter starred appointments
        _appointments = allAppointments
            .cast<Map<String, dynamic>>()
            .where((appointment) => appointment['isStarred'] == true)
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
        // Remove from starred list if unstarred
        if (!(_appointments[index]['isStarred'] == true)) {
          _appointments.removeAt(index);
        }
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
      appBar: AppBar(
        title: const Text('Starred Appointments'),
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
      drawer: const SidebarComponent(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Starred Appointments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Star appointments to see them here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_appointments.length} Starred Appointment${_appointments.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear All Starred'),
                                  content: const Text('Are you sure you want to remove all appointments from starred?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Remove all starred appointments
                                        setState(() {
                                          for (final appointment in _appointments) {
                                            appointment['isStarred'] = false;
                                          }
                                          _appointments.clear();
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('All starred appointments cleared'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Appointments List
                    Expanded(
                      child: ListView.builder(
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
                    ),
                  ],
                ),
    );
  }
} 