import 'package:flutter/material.dart';

class StarForm extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onStar;
  final VoidCallback? onClose;

  const StarForm({
    Key? key,
    required this.appointment,
    this.onStar,
    this.onClose,
  }) : super(key: key);

  @override
  State<StarForm> createState() => _StarFormState();
}

class _StarFormState extends State<StarForm> {
  String _getAppointmentName() {
    return widget.appointment['userCurrentDesignation']?.toString() ?? 
           widget.appointment['email']?.toString() ?? 'Unknown';
  }

  String _getAppointmentId() {
    return widget.appointment['appointmentId']?.toString() ?? 
           widget.appointment['_id']?.toString() ?? '';
  }

  bool _isStarred() {
    return widget.appointment['starred'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final isStarred = _isStarred();
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Simple handle
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Simple header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  isStarred ? Icons.star : Icons.star_border,
                  color: isStarred ? Colors.amber : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isStarred ? 'Remove from Starred' : 'Add to Starred',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getAppointmentName(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isStarred ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(isStarred ? 'Remove from Starred' : 'Add to Starred'),
                  subtitle: Text('${_getAppointmentName()} - ${_getAppointmentId()}'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    widget.onStar?.call();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 