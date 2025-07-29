import 'package:flutter/material.dart';

class ExportDataCard extends StatelessWidget {
  final String fullName;
  final String phone;
  final String email;
  final String designation;
  final String location;
  final String time;
  final String noOfPeople;
  final String namesOfPeople;
  final String secretaryName;
  final VoidCallback? onTap;

  const ExportDataCard({
    super.key,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.designation,
    required this.location,
    required this.time,
    required this.noOfPeople,
    required this.namesOfPeople,
    required this.secretaryName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Contact Information
                _buildInfoRow(Icons.phone, 'Phone', phone),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.email, 'Email', email),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.work, 'Designation', designation),
                
                const SizedBox(height: 16),
                
                // Appointment Details
                _buildInfoRow(Icons.location_on, 'Location', location),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, 'Time', time),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.people, 'No. of People', noOfPeople),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person, 'Names of People', namesOfPeople),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.admin_panel_settings, 'Secretary', secretaryName),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 