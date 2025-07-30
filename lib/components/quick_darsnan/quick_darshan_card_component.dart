import 'package:flutter/material.dart';

class QuickDarshanCardComponent extends StatelessWidget {
  final String name;
  final String mobileNumber;
  final int numberOfPeople;
  final String appointmentDate;
  final String status;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onAddPressed;

  const QuickDarshanCardComponent({
    super.key,
    required this.name,
    required this.mobileNumber,
    required this.numberOfPeople,
    required this.appointmentDate,
    required this.status,
    this.onCallPressed,
    this.onMessagePressed,
    this.onAddPressed,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details in label-value format
          _buildLabelValue('Mobile Number', mobileNumber),
          const SizedBox(height: 8),
          _buildLabelValue('No. of People', numberOfPeople.toString()),
          const SizedBox(height: 8),
          _buildLabelValue('Appointment Date', appointmentDate),
          const SizedBox(height: 16),
          // Action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.phone, onCallPressed, 'Call'),
              _buildActionIcon(Icons.email, onMessagePressed, 'Message'),
              _buildActionIcon(Icons.add, onAddPressed, 'Add'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback? onPressed, String label) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
} 