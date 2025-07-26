import 'package:flutter/material.dart';

class FilterButtonComponent extends StatelessWidget {
  final VoidCallback? onPressed;
  
  const FilterButtonComponent({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Filter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 