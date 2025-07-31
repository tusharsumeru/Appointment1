import 'package:flutter/material.dart';

class PersonCardComponent extends StatelessWidget {
  final String name;
  final String darshanType;
  final String darshanLineDate;
  final String requestedDate;
  final int peopleCount;
  final String status;
  final VoidCallback? onBellPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onGroupPressed;
  final VoidCallback? onStarPressed;
  final VoidCallback? onDeletePressed;

  const PersonCardComponent({
    super.key,
    required this.name,
    required this.darshanType,
    required this.darshanLineDate,
    required this.requestedDate,
    required this.peopleCount,
    required this.status,
    this.onBellPressed,
    this.onMessagePressed,
    this.onAddPressed,
    this.onCallPressed,
    this.onGroupPressed,
    this.onStarPressed,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _buildLabelValue('Name', name),
          const SizedBox(height: 8),
          _buildLabelValue('Darshan Type', darshanType),
          const SizedBox(height: 8),
          _buildLabelValue('Darshan Line Date', darshanLineDate),
          const SizedBox(height: 8),
          _buildLabelValue('Requested Date', requestedDate),
          const SizedBox(height: 8),
          _buildLabelValue('No. of People', peopleCount.toString()),
          const SizedBox(height: 8),
          _buildLabelValue('Status', status),
          const SizedBox(height: 8),
          _buildLabelValue('Email', 'Not Sent'),
          const SizedBox(height: 16),
          // Action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.phone, onCallPressed),
              _buildActionIcon(Icons.email, onMessagePressed),
              _buildActionIcon(Icons.add, onAddPressed),
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

  Widget _buildActionIcon(IconData icon, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
} 