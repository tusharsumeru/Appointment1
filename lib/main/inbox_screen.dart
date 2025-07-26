import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/gear_filter_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Fetch appointments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointments();
    });
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ActionService.getAppointmentsForSecretary();
      
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
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
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
      drawer: const SidebarComponent(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'Loading appointments...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _fetchAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Inbox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No pending appointments found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _fetchAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 80), // Space for gear icon
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
        // Gear Icon positioned at top right
        const Positioned(
          top: 16,
          right: 16,
          child: GearFilterComponent(),
        ),
      ],
    );
  }
} 