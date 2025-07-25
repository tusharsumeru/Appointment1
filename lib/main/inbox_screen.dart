import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/gear_filter_component.dart';
import '../components/inbox/appointment_card.dart';
import '../models/appointment.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Appointment> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    appointments = [
      Appointment(
        id: '203',
        imageUrl: 'https://aolstaging.abhosting.co.in/uploads/ff5b6151db2fd0b04f7fdd9537f38262.jpg',
        name: 'Bishnupriya tripathy',
        role: 'Store manager',
        date: '12 May 2025',
        time: '6:42 pm',
        dateRange: '2025-05-12 to 2025-05-12',
        attendeeCount: 2,
        assignedTo: 'KK',
        isStarred: false,
        phoneNumber: '+919861382431',
        availableAssignees: [
          Assignee(id: '2', name: 'Karthik K', initials: 'KK'),
          Assignee(id: '3', name: 'Krishna S', initials: 'KS'),
          Assignee(id: '4', name: 'Meera P', initials: 'MP'),
          Assignee(id: '5', name: 'Vishal M', initials: 'VM'),
        ],
        createdAt: DateTime.now(),
      ),
      Appointment(
        id: '204',
        imageUrl: 'https://via.placeholder.com/150',
        name: 'John Doe',
        role: 'Customer',
        date: '13 May 2025',
        time: '10:30 am',
        dateRange: '2025-05-13 to 2025-05-13',
        attendeeCount: 1,
        assignedTo: 'KS',
        isStarred: true,
        phoneNumber: '+919876543210',
        availableAssignees: [
          Assignee(id: '2', name: 'Karthik K', initials: 'KK'),
          Assignee(id: '3', name: 'Krishna S', initials: 'KS'),
          Assignee(id: '4', name: 'Meera P', initials: 'MP'),
          Assignee(id: '5', name: 'Vishal M', initials: 'VM'),
        ],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void _handleStatusChange(String appointmentId) {
    // Handle status change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status changed for appointment $appointmentId')),
    );
  }

  void _handleEmail(String appointmentId) {
    // Handle email action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email sent for appointment $appointmentId')),
    );
  }

  void _handleDarshanLineChange(String value) {
    // Handle darshan line change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved to $value')),
    );
  }

  void _handleBackstageChange(String value) {
    // Handle backstage change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Moved to backstage $value')),
    );
  }

  void _handleAssignTo(String data) {
    // Handle assign to
    final parts = data.split('|');
    if (parts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned to ${parts[2]}')),
      );
    }
  }

  void _handleStarToggle(bool isStarred) {
    // Handle star toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isStarred ? 'Starred' : 'Unstarred')),
    );
  }

  void _handleDelete() {
    // Handle delete
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment deleted')),
    );
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
      ),
      drawer: const SidebarComponent(),
      body: Stack(
        children: [
          appointments.isEmpty
              ? Center(
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
                        'Your appointments will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 80), // Space for gear icon
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return AppointmentCard(
                      appointment: appointment,
                      onTap: () {
                        // Handle appointment tap
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Selected ${appointment.name}')),
                        );
                      },
                      onStatusChange: _handleStatusChange,
                      onEmail: _handleEmail,
                      onDarshanLineChange: _handleDarshanLineChange,
                      onBackstageChange: _handleBackstageChange,
                      onAssignTo: _handleAssignTo,
                      onStarToggle: _handleStarToggle,
                      onDelete: _handleDelete,
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
      ),
    );
  }
} 