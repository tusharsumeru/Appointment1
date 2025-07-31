import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/dasharn/filter_button_component.dart';
import '../components/dasharn/person_card_component.dart';
import '../components/dasharn/filter_modal_component.dart';
import '../components/common/search_bar_component.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showFilterModal = false;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments(); // Fetch on load
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments({String? search}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ActionService.fetchAppointments(search: search);
      setState(() {
        _appointments = data;
      });
      print("📦 Appointments Fetched: $_appointments");
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print("❌ Error fetching appointments: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    _fetchAppointments(); // Re-fetch with applied filters
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
    _fetchAppointments(search: query);
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      final date = DateTime.parse(dateValue.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatPreferredDateRange(Map<String, dynamic>? preferredDateRange) {
    if (preferredDateRange == null) return 'N/A';
    
    try {
      final fromDate = DateTime.parse(preferredDateRange['fromDate']?.toString() ?? '');
      final toDate = DateTime.parse(preferredDateRange['toDate']?.toString() ?? '');
      
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      
      final fromFormatted = '${fromDate.day} ${months[fromDate.month - 1]} ${fromDate.year}';
      final toFormatted = '${toDate.day} ${months[toDate.month - 1]} ${toDate.year}';
      
      return '$fromFormatted to $toFormatted';
    } catch (e) {
      return 'Invalid Date Range';
    }
  }

  int _getPeopleCount(Map<String, dynamic> item) {
    try {
      final accompanyUsers = item['accompanyUsers'];
      if (accompanyUsers is Map<String, dynamic>) {
        final users = accompanyUsers['users'];
        if (users is List) {
          return users.length + 1; // +1 for the main user
        }
      }
      return 1; // Default to 1 if no accompany users found
    } catch (e) {
      print('Error calculating people count: $e');
      return 1; // Default to 1 on error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Darshan Line'),
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
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _bulkUpload,
                          icon: const Icon(Icons.upload, color: Colors.white),
                          label: const Text('Bulk Upload'),
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
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _zoomLink,
                          icon: const Icon(Icons.video_call, color: Colors.white),
                          label: const Text('Zoom Link'),
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

                // Appointment list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text('Error: $_error'))
                          : ListView.builder(
                              itemCount: _appointments.length,
                              itemBuilder: (context, index) {
                                final item = _appointments[index];
                                return PersonCardComponent(
                                  name: item['createdBy']?['fullName'] ?? 'No Name',
                                  darshanType: item['venue']?['name'] ?? 'N/A',
                                  darshanLineDate: _formatDate(item['scheduledDateTime']?['date']),
                                  requestedDate: _formatPreferredDateRange(item['preferredDateRange']),
                                  peopleCount: _getPeopleCount(item),
                                  status: item['status'] ?? 'Scheduled',
                                  onBellPressed: () {},
                                  onMessagePressed: () {},
                                  onAddPressed: () {},
                                  onCallPressed: () {},
                                  onGroupPressed: () {},
                                  onStarPressed: () {},
                                  onDeletePressed: () {},
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Filter Modal
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
