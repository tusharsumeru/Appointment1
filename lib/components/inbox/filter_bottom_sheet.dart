import 'package:flutter/material.dart';

class FilterBottomSheet extends StatelessWidget {
  final String selectedFilter;
  final List<Map<String, dynamic>> secretaries;
  final Function(String) onFilterSelected;

  const FilterBottomSheet({
    super.key,
    required this.selectedFilter,
    required this.secretaries,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue[500],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Options list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildFilterOption('All'),
                _buildFilterOption('Assigned'),
                _buildFilterOption('Unassigned'),
                // Add separator and secretary options
                if (secretaries.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  // Secretary options
                  ...secretaries.map((secretary) => _buildFilterOption(
                    secretary['fullName'] ?? 'Unknown',
                  )).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String option) {
    final isSelected = selectedFilter == option;
    
    return InkWell(
      onTap: () {
        onFilterSelected(option);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.blue[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Colors.blue[700],
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the filter bottom sheet
void showFilterBottomSheet({
  required BuildContext context,
  required String selectedFilter,
  required List<Map<String, dynamic>> secretaries,
  required Function(String) onFilterSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FilterBottomSheet(
      selectedFilter: selectedFilter,
      secretaries: secretaries,
      onFilterSelected: (option) {
        onFilterSelected(option);
        Navigator.of(context).pop();
      },
    ),
  );
} 

// Filter bottom sheet specifically for deleted appointments
class FilterBottomSheetForDeleted extends StatelessWidget {
  final String selectedFilter;
  final List<Map<String, dynamic>> secretaries;
  final Function(String) onFilterSelected;

  const FilterBottomSheetForDeleted({
    super.key,
    required this.selectedFilter,
    required this.secretaries,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    print('FilterBottomSheetForDeleted - secretaries: $secretaries'); // Debug print
    print('FilterBottomSheetForDeleted - secretaries length: ${secretaries.length}'); // Debug print
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red[500],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Deleted Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Options list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildFilterOption('All Deleted'),
                // Add separator and secretary options
                if (secretaries.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  // Secretary options
                  ...secretaries.map((secretary) {
                    print('Processing secretary: $secretary'); // Debug print
                    return _buildFilterOption(
                      secretary['fullName'] ?? 'Unknown',
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String option) {
    final isSelected = selectedFilter == option;
    
    return InkWell(
      onTap: () {
        onFilterSelected(option);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.red[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Colors.red[700],
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the filter bottom sheet for deleted appointments
void showFilterBottomSheetForDeleted({
  required BuildContext context,
  required String selectedFilter,
  required List<Map<String, dynamic>> secretaries,
  required Function(String) onFilterSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FilterBottomSheetForDeleted(
      selectedFilter: selectedFilter,
      secretaries: secretaries,
      onFilterSelected: (option) {
        onFilterSelected(option);
        Navigator.of(context).pop();
      },
    ),
  );
} 

// Filter bottom sheet specifically for starred appointments
class FilterBottomSheetForStarred extends StatelessWidget {
  final String selectedFilter;
  final List<Map<String, dynamic>> secretaries;
  final Function(String) onFilterSelected;

  const FilterBottomSheetForStarred({
    super.key,
    required this.selectedFilter,
    required this.secretaries,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    print('FilterBottomSheetForStarred - secretaries: $secretaries'); // Debug print
    print('FilterBottomSheetForStarred - secretaries length: ${secretaries.length}'); // Debug print
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Starred Appointments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Options list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildFilterOption('All Starred'),
                // Add separator and secretary options
                if (secretaries.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  // Secretary options
                  ...secretaries.map((secretary) {
                    print('Processing secretary: $secretary'); // Debug print
                    return _buildFilterOption(
                      secretary['fullName'] ?? 'Unknown',
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String option) {
    final isSelected = selectedFilter == option;
    
    return InkWell(
      onTap: () {
        onFilterSelected(option);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[50] : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.amber[700] : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 20,
                color: Colors.amber[700],
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the filter bottom sheet for starred appointments
void showFilterBottomSheetForStarred({
  required BuildContext context,
  required String selectedFilter,
  required List<Map<String, dynamic>> secretaries,
  required Function(String) onFilterSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => FilterBottomSheetForStarred(
      selectedFilter: selectedFilter,
      secretaries: secretaries,
      onFilterSelected: (option) {
        onFilterSelected(option);
        Navigator.of(context).pop();
      },
    ),
  );
} 