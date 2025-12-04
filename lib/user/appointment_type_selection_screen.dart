import 'package:flutter/material.dart';
import 'user_sidebar.dart';
import 'request_appointment.dart';
import 'event_appointment_screen.dart';
import '../action/action.dart';

class AppointmentTypeSelectionScreen extends StatefulWidget {
  const AppointmentTypeSelectionScreen({super.key});

  @override
  State<AppointmentTypeSelectionScreen> createState() => _AppointmentTypeSelectionScreenState();
}

class _AppointmentTypeSelectionScreenState extends State<AppointmentTypeSelectionScreen> {
  String? _selectedAppointmentType;
  bool _isVDSUser = false;

  @override
  void initState() {
    super.initState();
    _checkVDSUser();
  }

  Future<void> _checkVDSUser() async {
    final isVDS = await ActionService.isVDSUser();
    setState(() {
      _isVDSUser = isVDS;
    });
  }

  List<Map<String, String>> get _appointmentTypes {
    final types = [
      {
        'id': 'myself',
        'title': 'Request appointment for Myself',
        'description': 'Schedule an appointment for yourself',
      },
      {
        'id': 'guest',
        'title': 'Request appointment for a Guest',
        'description': 'Schedule an appointment for someone else',
      },
    ];

    // Add event option only for VDS users
    if (_isVDSUser) {
      types.add({
        'id': 'event',
        'title': 'Request appointment for events',
        'description': 'Schedule an appointment for events',
      });
    }

    return types;
  }

  void _continueToRequestAppointment() {
    if (_selectedAppointmentType != null) {
      if (_selectedAppointmentType == 'event') {
        // Navigate to event appointment screen for VDS users
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EventAppointmentScreen(),
          ),
        );
      } else {
        // Navigate to regular request appointment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestAppointmentScreen(
              selectedType: _selectedAppointmentType!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Type'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316), // Orange
                Color(0xFFEAB308), // Yellow
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
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
      drawer: const UserSidebar(),
      body: Container(
        color: Colors.grey.shade50,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  const Text(
                    'Appointment Type',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select who this appointment is for',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Appointment Type Options
                  ..._appointmentTypes.map((type) => _buildAppointmentTypeCard(type)).toList(),
                  
                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedAppointmentType != null ? _continueToRequestAppointment : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 1,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentTypeCard(Map<String, String> type) {
    final isSelected = _selectedAppointmentType == type['id'];
    
    // Use orange theme for all appointment types
    final selectedColor = Colors.orange;
    final selectedLightColor = Colors.orange.shade50;
    final selectedBorderColor = Colors.orange.shade300;
    final selectedTextColor = Colors.orange.shade800;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAppointmentType = type['id'];
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? selectedLightColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? selectedBorderColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Radio Button
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? selectedColor : Colors.white,
                  border: Border.all(
                    color: isSelected ? selectedColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Text(
                  type['title']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? selectedTextColor : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 