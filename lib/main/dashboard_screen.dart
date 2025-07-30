import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/dasharn/filter_button_component.dart';
import '../components/dasharn/person_card_component.dart';
import '../components/dasharn/filter_modal_component.dart';
import '../components/common/search_bar_component.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showFilterModal = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilter() {
    setState(() {
      _showFilterModal = true;
    });
  }

  void _hideFilter() {
    setState(() {
      _showFilterModal = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _showFilterModal = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied successfully!')),
    );
  }

  void _bulkUpload() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk Upload pressed')),
    );
  }

  void _zoomLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zoom Link pressed')),
    );
  }

  void _performSearch(String query) {
    // Handle search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: Stack(
        children: [
          Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Action buttons below header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Bulk Upload Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _bulkUpload,
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: const Text(
                            'Bulk Upload',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Zoom Link Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _zoomLink,
                          icon: const Icon(Icons.video_call, color: Colors.white),
                          label: const Text(
                            'Zoom Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CommonSearchBarComponent(
                    controller: _searchController,
                    onSearch: _performSearch,
                    hintText: 'Search by name, role, or date...',
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Filter button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showFilter,
                        child: const FilterButtonComponent(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Cards list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Dummy Card 1
                      PersonCardComponent(
                        name: 'Sarah Johnson',
                        darshanType: 'P1',
                        darshanLineDate: '2025-05-10',
                        requestedDate: '2025-05-01',
                        peopleCount: 3,
                        onBellPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bell pressed for Sarah')),
                          );
                        },
                        onMessagePressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message pressed for Sarah')),
                          );
                        },
                        onAddPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add pressed for Sarah')),
                          );
                        },
                        onCallPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Call pressed for Sarah')),
                          );
                        },
                        onGroupPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group pressed for Sarah')),
                          );
                        },
                        onStarPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Star pressed for Sarah')),
                          );
                        },
                        onDeletePressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete pressed for Sarah')),
                          );
                        },
                      ),
                      // Dummy Card 2
                      PersonCardComponent(
                        name: 'Michael Chen',
                        darshanType: 'SB',
                        darshanLineDate: '2025-05-11',
                        requestedDate: '2025-05-02',
                        peopleCount: 2,
                        onBellPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bell pressed for Michael')),
                          );
                        },
                        onMessagePressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message pressed for Michael')),
                          );
                        },
                        onAddPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add pressed for Michael')),
                          );
                        },
                        onCallPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Call pressed for Michael')),
                          );
                        },
                        onGroupPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group pressed for Michael')),
                          );
                        },
                        onStarPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Star pressed for Michael')),
                          );
                        },
                        onDeletePressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete pressed for Michael')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Modal Overlay
          if (_showFilterModal)
            Positioned.fill(
              child: FilterModalComponent(
                onClose: _hideFilter,
                onApplyFilters: _applyFilters,
              ),
            ),
        ],
      ),
    );
  }
} 