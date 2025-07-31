import 'package:flutter/material.dart';

class PersonCardComponent extends StatefulWidget {
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
  State<PersonCardComponent> createState() => _PersonCardComponentState();
}

class _PersonCardComponentState extends State<PersonCardComponent> {
  bool _isChecked = false;

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
          // Checkbox row
          Row(
            children: [
              Checkbox(
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
                activeColor: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select this appointment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLabelValue('Name', widget.name),
          _buildLabelValue('Darshan Type', widget.darshanType),
          _buildLabelValue('Darshan Line Date', widget.darshanLineDate),
          _buildLabelValue('Requested Date', widget.requestedDate),
          _buildLabelValue('No. of People', widget.peopleCount.toString()),
          _buildLabelValue('Status', widget.status),
          _buildLabelValue('Email', 'Not Sent'),
          const SizedBox(height: 16),
          // Action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.phone, 'Call', widget.onCallPressed),
              _buildActionIcon(Icons.email, 'Email', widget.onMessagePressed),
              _buildActionIcon(Icons.add, 'Sms', widget.onAddPressed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Fixed width for consistent alignment
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 