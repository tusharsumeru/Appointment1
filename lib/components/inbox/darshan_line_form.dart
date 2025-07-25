import 'package:flutter/material.dart';

class DarshanLineForm extends StatefulWidget {
  final String appointmentId;
  final String appointmentName;
  final Function(String)? onDarshanLineChange;
  final Function(String)? onBackstageChange;
  final VoidCallback? onClose;

  const DarshanLineForm({
    Key? key,
    required this.appointmentId,
    required this.appointmentName,
    this.onDarshanLineChange,
    this.onBackstageChange,
    this.onClose,
  }) : super(key: key);

  @override
  State<DarshanLineForm> createState() => _DarshanLineFormState();
}

class _DarshanLineFormState extends State<DarshanLineForm> {
  String? selectedOption;

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
                  Icons.queue,
                  color: Colors.purple[600],
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Move to Line',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Simple options list
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSimpleOption('P1', 'Priority Line 1', Icons.queue, Colors.purple),
              _buildSimpleOption('P2', 'Priority Line 2', Icons.queue, Colors.purple),
              _buildSimpleOption('SB', 'Side Backstage', Icons.curtains, Colors.orange),
              _buildSimpleOption('PB', 'Priority Backstage', Icons.curtains, Colors.orange),
              _buildSimpleOption('Z', 'Zone', Icons.block, Colors.red),
            ],
          ),
          
          // Simple action buttons
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedOption != null ? () {
                      if (selectedOption!.startsWith('P')) {
                        widget.onDarshanLineChange?.call(selectedOption!);
                      } else {
                        widget.onBackstageChange?.call(selectedOption!);
                      }
                      Navigator.pop(context);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Move'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleOption(String value, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                color: color,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedOption == value ? color : Colors.grey[400]!,
                  width: 2,
                ),
                color: selectedOption == value ? color : Colors.transparent,
              ),
              child: selectedOption == value
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
} 