import 'package:flutter/material.dart';

class GearFilterComponent extends StatefulWidget {
  const GearFilterComponent({super.key});

  @override
  State<GearFilterComponent> createState() => _GearFilterComponentState();
}

class _GearFilterComponentState extends State<GearFilterComponent> {
  String _selectedFilter = '';
  String _selectedLocation = '';
  bool _showChecks = false;

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

  void _toggleShowChecks(bool? value) {
    setState(() {
      _showChecks = value ?? false;
    });
  }

  Widget _buildFilterOption(String value) {
    bool isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          if (value == 'All') {
            _selectedFilter = '';
          } else {
            _selectedFilter = value;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationOption(String value) {
    bool isSelected = _selectedLocation == value;
    return InkWell(
      onTap: () {
        setState(() {
          if (value == 'All') {
            _selectedLocation = '';
          } else {
            _selectedLocation = value;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          value,
          style: TextStyle(
            color: isSelected ? Colors.deepPurple : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter & Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),


            // Filter By
            const Text(
              'Filter By',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              onSelected: (String value) {
                // This won't be called since we're using custom items
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFilter.isEmpty ? 'All' : _selectedFilter,
                      style: TextStyle(
                        color: _selectedFilter.isEmpty ? Colors.grey : Colors.black,
                        fontWeight: _selectedFilter.isEmpty ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Container(
                    width: 300,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildFilterOption('All'),
                                  _buildFilterOption('Assigned'),
                                  _buildFilterOption('Unassigned'),
                                  _buildFilterOption('Karthik K (KK)'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildFilterOption('Krishna S (KS)'),
                                  _buildFilterOption('Meera P (MP)'),
                                  _buildFilterOption('Vishal M (VM)'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Filter
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              onSelected: (String value) {
                // This won't be called since we're using custom items
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedLocation.isEmpty ? 'All' : _selectedLocation,
                      style: TextStyle(
                        color: _selectedLocation.isEmpty ? Colors.grey : Colors.black,
                        fontWeight: _selectedLocation.isEmpty ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Container(
                    width: 300,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLocationOption('All'),
                                  _buildLocationOption('Location 1'),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildLocationOption('Location 2'),
                                  _buildLocationOption('Location 3'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show Checks Option
            Row(
              children: [
                Checkbox(
                  value: _showChecks,
                  onChanged: _toggleShowChecks,
                  activeColor: Colors.deepPurple,
                ),
                const Text(
                  'Show Selection Options',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters applied')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if any filters are active
    bool hasActiveFilters = _selectedFilter.isNotEmpty || 
                          _selectedLocation.isNotEmpty || 
                          _showChecks;
    
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: _showFilterModal,
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilters ? Colors.orange : Colors.deepPurple,
              size: 20,
            ),
            label: Text(
              'Filter',
              style: TextStyle(
                color: hasActiveFilters ? Colors.orange : Colors.deepPurple,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: hasActiveFilters ? Colors.orange : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              elevation: 1,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
          ),
        ),
        // Show badge if filters are active
        if (hasActiveFilters)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
            ),
          ),
      ],
    );
  }
} 