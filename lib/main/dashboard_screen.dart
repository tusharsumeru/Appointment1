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
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool _isLoading = false;
  String? _error;

  // Filter variables
  String _selectedEmailStatus = '';
  String _selectedDarshanType = '';
  DateTime? _fromDate;
  DateTime? _toDate;

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
          _filteredAppointments = data; // Initially show all appointments
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
    _applyFiltersToData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied successfully!')),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedEmailStatus = '';
      _selectedDarshanType = '';
      _fromDate = null;
      _toDate = null;
      _filteredAppointments = _appointments; // Show all appointments
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters cleared!')),
    );
  }

  void _applyFiltersToData() {
    // If no filters are set, show all appointments
    if (_selectedEmailStatus.isEmpty && 
        _selectedDarshanType.isEmpty && 
        _fromDate == null && 
        _toDate == null) {
      _filteredAppointments = _appointments;
      return;
    }

    _filteredAppointments = _appointments.where((appointment) {
      // Filter by darshan type
      if (_selectedDarshanType.isNotEmpty) {
        final venueName = appointment['venue']?['name']?.toString() ?? '';
        if (venueName != _selectedDarshanType) {
          return false;
        }
      }

      // Filter by email status (for now, all show "Not Sent")
      if (_selectedEmailStatus.isNotEmpty) {
        // Since all appointments currently show "Not Sent", this filter will work
        // when email status is actually implemented in the API
        if (_selectedEmailStatus != 'Not Sent') {
          return false;
        }
      }

      // Filter by date range
      if (_fromDate != null || _toDate != null) {
        final scheduledDate = appointment['scheduledDateTime']?['date'];
        if (scheduledDate != null) {
          try {
            final appointmentDate = DateTime.parse(scheduledDate.toString());
            
            if (_fromDate != null && appointmentDate.isBefore(_fromDate!)) {
              return false;
            }
            
            if (_toDate != null && appointmentDate.isAfter(_toDate!)) {
              return false;
            }
          } catch (e) {
            // If date parsing fails, exclude the appointment
            return false;
          }
        }
      }

      return true;
    }).toList();
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
      final allAccompanyUsers = item['accompanyUsers'] ?? [];
      int accompanyCount = 0;

      for (final group in allAccompanyUsers) {
        final groupUsers = group['users']?.length ?? 0;
        accompanyCount += (groupUsers as int);
      }

      final peopleCount = accompanyCount + 1; // Include main applicant
      return peopleCount;
    } catch (e) {
      print('Error calculating people count: $e');
      return 1; // Default to 1 on error
    }
  }

  String _getAppointmentStatus(Map<String, dynamic> appointment) {
    // Try to get mainStatus from checkInStatus object first
    final checkInStatus = appointment['checkInStatus'];
    if (checkInStatus is Map<String, dynamic>) {
      final mainStatus = checkInStatus['mainStatus']?.toString();
      if (mainStatus != null && mainStatus.isNotEmpty) {
        return mainStatus;
      }
    }
    
    // Fallback to appointmentStatus.status
    final appointmentStatus = appointment['appointmentStatus'];
    if (appointmentStatus is Map<String, dynamic>) {
      final status = appointmentStatus['status']?.toString();
      if (status != null && status.isNotEmpty) {
        return status;
      }
    }
    
    // Final fallback to direct mainStatus field
    return appointment['mainStatus']?.toString() ?? 'Unknown';
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
                          label: const Text(
                            'Bulk Upload',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
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
                          label: const Text(
                            'Zoom Link',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
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
                       // Clear Filter Button
                       if (_selectedEmailStatus.isNotEmpty || 
                           _selectedDarshanType.isNotEmpty || 
                           _fromDate != null || 
                           _toDate != null)
                         GestureDetector(
                           onTap: _clearFilters,
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.red.shade100,
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: Colors.red.shade300),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Icon(
                                   Icons.clear,
                                   size: 16,
                                   color: Colors.red.shade700,
                                 ),
                                 const SizedBox(width: 4),
                                 Text(
                                   'Clear',
                                   style: TextStyle(
                                     fontSize: 12,
                                     fontWeight: FontWeight.w500,
                                     color: Colors.red.shade700,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ),
                       if (_selectedEmailStatus.isNotEmpty || 
                           _selectedDarshanType.isNotEmpty || 
                           _fromDate != null || 
                           _toDate != null)
                         const SizedBox(width: 8),
                       // Filter Button
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
                               itemCount: _filteredAppointments.length,
                               itemBuilder: (context, index) {
                                 final item = _filteredAppointments[index];
                                return PersonCardComponent(
                                  name: item['createdBy']?['fullName'] ?? 'No Name',
                                  darshanType: item['venue']?['name'] ?? 'N/A',
                                  darshanLineDate: _formatDate(item['scheduledDateTime']?['date']),
                                  requestedDate: _formatPreferredDateRange(item['preferredDateRange']),
                                  peopleCount: _getPeopleCount(item),
                                  status: _getAppointmentStatus(item),
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
                 initialEmailStatus: _selectedEmailStatus,
                 initialDarshanType: _selectedDarshanType,
                 initialFromDate: _fromDate,
                 initialToDate: _toDate,
                 onFiltersChanged: (emailStatus, darshanType, fromDate, toDate) {
                   setState(() {
                     _selectedEmailStatus = emailStatus;
                     _selectedDarshanType = darshanType;
                     _fromDate = fromDate;
                     _toDate = toDate;
                   });
                 },
               ),
             ),
        ],
      ),
    );
  }
}
