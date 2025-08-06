import 'package:flutter/material.dart';

class PersonCardComponent extends StatefulWidget {
  final String name;
  final String darshanType;
  final String darshanLineDate;
  final String requestedDate;
  final int peopleCount;
  final String status;
  final String emailStatus; // Add email status parameter
  final bool isSelected;
  final Function(bool)? onSelectionChanged;
  final VoidCallback? onBellPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onAddPressed;
  final VoidCallback? onCallPressed;
  final VoidCallback? onGroupPressed;
  final VoidCallback? onStarPressed;
  final VoidCallback? onDeletePressed;
  final int index; // Add index parameter for alternating colors

  const PersonCardComponent({
    super.key,
    required this.name,
    required this.darshanType,
    required this.darshanLineDate,
    required this.requestedDate,
    required this.peopleCount,
    required this.status,
    required this.emailStatus, // Add email status parameter
    this.isSelected = false,
    this.onSelectionChanged,
    this.onBellPressed,
    this.onMessagePressed,
    this.onAddPressed,
    this.onCallPressed,
    this.onGroupPressed,
    this.onStarPressed,
    this.onDeletePressed,
    required this.index, // Add index parameter
  });

  @override
  State<PersonCardComponent> createState() => _PersonCardComponentState();
}

class _PersonCardComponentState extends State<PersonCardComponent> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: widget.index % 2 == 0 ? Colors.white : Color(0xFFFFF3E0), // Alternating colors like inbox
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox at top right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select this appointment',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Checkbox(
                  value: widget.isSelected,
                  onChanged: (bool? value) {
                    widget.onSelectionChanged?.call(value ?? false);
                  },
                  activeColor: Colors.deepPurple,
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
            _buildLabelValue('Email', widget.emailStatus),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSimpleActionIcon(Icons.email_outlined, 'Email', widget.onBellPressed),
                const SizedBox(width: 16),
                _buildSimpleActionIcon(Icons.message_outlined, 'Message', widget.onMessagePressed),
                const SizedBox(width: 16),
                _buildSimpleActionIcon(Icons.phone_outlined, 'Call', widget.onAddPressed),
              ],
            ),
          ],
        ),
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
            width: 140,
            child: Text(
              '$label:',
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
              style: TextStyle(
                fontSize: 14,
                color: _getEmailStatusColor(value),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEmailStatusColor(String emailStatus) {
    if (emailStatus == 'Email Sent') {
      return Colors.green;
    } else {
      return Colors.black87;
    }
  }

  Widget _buildSimpleActionIcon(IconData icon, String label, VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: Colors.black87,
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
