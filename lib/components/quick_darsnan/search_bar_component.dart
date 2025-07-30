import 'package:flutter/material.dart';

class SearchBarComponent extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const SearchBarComponent({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: TextField(
        controller: controller,
        onSubmitted: onSearch,
        decoration: InputDecoration(
          hintText: 'Search by name or darshan type...',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade500,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () {
                    controller.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          // Trigger rebuild for clear button visibility
        },
      ),
    );
  }
} 