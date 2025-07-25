import 'package:flutter/material.dart';

class StarForm extends StatefulWidget {
  final String appointmentId;
  final String appointmentName;
  final bool isStarred;
  final Function(bool)? onStarToggle;
  final VoidCallback? onClose;

  const StarForm({
    Key? key,
    required this.appointmentId,
    required this.appointmentName,
    required this.isStarred,
    this.onStarToggle,
    this.onClose,
  }) : super(key: key);

  @override
  State<StarForm> createState() => _StarFormState();
}

class _StarFormState extends State<StarForm> {
  @override
  Widget build(BuildContext context) {
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
                  widget.isStarred ? Icons.star : Icons.star_border,
                  color: widget.isStarred ? Colors.amber[600] : Colors.grey[600],
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isStarred ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
                      color: (widget.isStarred ? Colors.amber : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isStarred ? Icons.star : Icons.star_border,
                      color: widget.isStarred ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(widget.isStarred ? 'Remove from Favorites' : 'Add to Favorites'),
                  subtitle: Text('${widget.appointmentName}'),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    widget.onStarToggle?.call(!widget.isStarred);
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