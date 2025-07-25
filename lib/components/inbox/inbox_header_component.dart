import 'package:flutter/material.dart';

class InboxHeaderComponent extends StatefulWidget {
  const InboxHeaderComponent({super.key});

  @override
  State<InboxHeaderComponent> createState() => _InboxHeaderComponentState();
}

class _InboxHeaderComponentState extends State<InboxHeaderComponent> {
  bool _selectAll = false;
  bool _showChecks = false;
  String _selectedFilter = '';
  String _selectedLocation = '';
  bool _showDeleteButton = false;

  final List<String> _filterOptions = [
    'All',
    'Assigned',
    'Unassigned',
    'Karthik K (KK)',
    'Krishna S (KS)',
    'Meera P (MP)',
    'Vishal M (VM)',
  ];

  final List<String> _locationOptions = [
    'All',
    'Location 1',
    'Location 2',
    'Location 3',
  ];

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      _showDeleteButton = _selectAll;
    });
  }

  void _toggleShowChecks(bool? value) {
    setState(() {
      _showChecks = value ?? false;
    });
  }

  void _showActionMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'assign',
          child: Text('Assign'),
        ),
        const PopupMenuItem(
          value: 'add_star',
          child: Text('Add Star'),
        ),
        const PopupMenuItem(
          value: 'remove_star',
          child: Text('Remove Star'),
        ),
        const PopupMenuItem(
          value: 'move_to_darshan',
          child: Text('Move to Darshan'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
    ).then((value) {
      if (value != null) {
        // Handle action selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $value')),
        );
      }
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Selected'),
          content: const Text('Are you sure you want to delete the selected items?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectAll = false;
                  _showDeleteButton = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Items deleted successfully')),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Select All Checkbox
            Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  activeColor: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select All',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Action Dropdown
            PopupMenuButton<String>(
              onSelected: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Action: $value')),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Action',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'assign',
                  child: Text('Assign'),
                ),
                const PopupMenuItem(
                  value: 'add_star',
                  child: Text('Add Star'),
                ),
                const PopupMenuItem(
                  value: 'remove_star',
                  child: Text('Remove Star'),
                ),
                const PopupMenuItem(
                  value: 'move_to_darshan',
                  child: Text('Move to Darshan'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Filter By
            Row(
              children: [
                const Text(
                  'Filter By',
                  style: TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedFilter.isEmpty ? null : _selectedFilter,
                    hint: const Text('All', style: TextStyle(fontSize: 10)),
                    underline: Container(),
                    style: const TextStyle(fontSize: 10),
                    items: _filterOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Location Filter
            Row(
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedLocation.isEmpty ? null : _selectedLocation,
                    hint: const Text('All', style: TextStyle(fontSize: 10)),
                    underline: Container(),
                    style: const TextStyle(fontSize: 10),
                    items: _locationOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLocation = newValue ?? '';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Show Checks
            Row(
              children: [
                Checkbox(
                  value: _showChecks,
                  onChanged: _toggleShowChecks,
                  activeColor: Colors.deepPurple,
                ),
                const Text(
                  'Select',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Delete Button
            if (_showDeleteButton)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

            // Reload Button
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing...')),
                );
              },
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Reload',
            ),
          ],
        ),
      ),
    );
  }
} 