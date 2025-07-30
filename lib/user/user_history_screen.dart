import 'package:flutter/material.dart';
import '../components/user/user_appointment_card.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Text(
                'My Appointment History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Appointment History Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                                     // First Card - Completed Appointment
                   UserAppointmentCard(
                     appointmentId: 'APT-74e68a9e',
                     status: 'Completed',
                     userName: 'Kaveri B',
                     userTitle: 'Office Operations Specialist',
                     company: 'Sumeru Digital',
                     appointmentDateRange: '7/29/2025 to 7/31/2025',
                     attendeesCount: 1,
                     purpose: 'Welcome to hello world',
                     assignedTo: 'Meera Prashanth',
                     dateRange: '7/29/2025 to 7/31/2025',
                     daysCount: 3,
                     email: 'kaveri@sumerudigital.com',
                     phone: '+919347653480',
                     location: 'Coimbatore, Tamil Nadu, India',
                     onEditPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('Edit functionality coming soon!'),
                           backgroundColor: Colors.blue,
                         ),
                       );
                     },
                   ),

                   // Second Card - Scheduled Appointment
                   UserAppointmentCard(
                     appointmentId: 'APT-8f92b1c3',
                     status: 'Scheduled',
                     userName: 'Priya Sharma',
                     userTitle: 'Software Developer',
                     company: 'Tech Solutions Inc',
                     appointmentDateRange: '8/15/2025 to 8/17/2025',
                     attendeesCount: 2,
                     purpose: 'Project discussion and planning meeting',
                     assignedTo: 'Rajesh Kumar',
                     dateRange: '8/15/2025 to 8/17/2025',
                     daysCount: 3,
                     email: 'priya.sharma@techsolutions.com',
                     phone: '+919876543210',
                     location: 'Mumbai, Maharashtra, India',
                     onEditPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(
                           content: Text('Edit functionality coming soon!'),
                           backgroundColor: Colors.blue,
                         ),
                       );
                     },
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 