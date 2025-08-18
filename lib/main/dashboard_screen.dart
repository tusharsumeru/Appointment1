import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/dasharn/filter_button_component.dart';
import '../components/dasharn/person_card_component.dart';
import '../components/dasharn/filter_modal_component.dart';
import '../components/common/search_bar_component.dart';
import '../components/inbox/email_form.dart';
import '../components/inbox/message_form.dart';
import '../components/inbox/call_form.dart';
import '../components/inbox/bulk_email_form.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import 'global_search_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  bool _showFilterModal = false;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 10;
  bool _hasMoreData = true;

  // Filter variables
  String _selectedEmailStatus = '';
  String _selectedDarshanType = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Select all functionality
  bool _selectAll = false;
  Set<String> _selectedAppointments = {};

  // Animation controllers
  AnimationController? _buttonAnimationController;
  Animation<double>? _buttonScaleAnimation;
  Animation<double>? _buttonOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController!,
      curve: Curves.easeOutBack,
    ));
    
    _buttonOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    _fetchAppointments(); // Fetch on load
  }

  @override
  void dispose() {
    _searchController.dispose();
    _buttonAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments({String? search, bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMoreData = true;
      });
    }

    try {
      final data = await ActionService.fetchAppointments(
        search: search,
        page: isLoadMore ? _currentPage + 1 : 1,
        pageSize: _pageSize,
      );
      
      if (isLoadMore) {
        // Append new data to existing list
        if (data.isNotEmpty) {
          setState(() {
            _appointments.addAll(data);
            _filteredAppointments = _appointments;
            _currentPage++;
            _hasMoreData = data.length >= _pageSize;
          });
          print("🔍 Load More - data.length: ${data.length}, pageSize: $_pageSize, hasMoreData: $_hasMoreData");
        } else {
          setState(() {
            _hasMoreData = false;
          });
          print("🔍 Load More - no more data, hasMoreData: $_hasMoreData");
        }
      } else {
        // Replace data for fresh load
        setState(() {
          _appointments = data;
          _filteredAppointments = data;
          _currentPage = 1;
          // Always show load more button initially, even if data.length < pageSize
          // This allows users to try loading more even if the first page is small
          _hasMoreData = data.length > 0;
        });
        print("🔍 Fresh Load - data.length: ${data.length}, pageSize: $_pageSize, hasMoreData: $_hasMoreData");
      }
      
      print("📦 Appointments Fetched: ${_appointments.length} total");
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      print("❌ Error fetching appointments: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
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
      _currentPage = 1;
      _hasMoreData = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters cleared!')),
    );
  }

  void _applyFiltersToData() {
    // Reset pagination when filters are applied
    _currentPage = 1;
    _hasMoreData = true;
    
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

      // Filter by email status
      if (_selectedEmailStatus.isNotEmpty) {
        final appointmentEmailStatus = _getEmailStatus(appointment);
        if (appointmentEmailStatus != _selectedEmailStatus) {
          return false;
        }
      }

      // Filter by date range
      if (_fromDate != null || _toDate != null) {
        final scheduledDate = appointment['scheduledDateTime']?['date'];
        if (scheduledDate != null) {
          try {
            final appointmentDate = DateTime.parse(scheduledDate.toString());
            
            // Normalize dates to start of day for proper comparison
            final normalizedAppointmentDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
            
            if (_fromDate != null) {
              final normalizedFromDate = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
              if (normalizedAppointmentDate.isBefore(normalizedFromDate)) {
                return false;
              }
            }
            
            if (_toDate != null) {
              final normalizedToDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);
              if (normalizedAppointmentDate.isAfter(normalizedToDate)) {
                return false;
              }
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

  // void _bulkUpload() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Bulk Upload pressed')),
  //   );
  // }

  // void _zoomLink() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Zoom Link pressed')),
  //   );
  // }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        // Select all filtered appointments
        _selectedAppointments = _filteredAppointments
            .map((appointment) => appointment['_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      } else {
        // Deselect all
        _selectedAppointments.clear();
      }
    });
    
    // Animate button
    _animateButton();
  }

  void _toggleAppointmentSelection(String appointmentId) {
    setState(() {
      if (_selectedAppointments.contains(appointmentId)) {
        _selectedAppointments.remove(appointmentId);
        _selectAll = false; // Uncheck select all if any item is unchecked
      } else {
        _selectedAppointments.add(appointmentId);
        // Check if all items are now selected
        final allIds = _filteredAppointments
            .map((appointment) => appointment['_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _selectAll = _selectedAppointments.length == allIds.length;
      }
    });
    
    // Animate button
    _animateButton();
  }

  void _animateButton() {
    if (_buttonAnimationController != null) {
      if (_selectedAppointments.isNotEmpty) {
        _buttonAnimationController!.forward();
      } else {
        _buttonAnimationController!.reverse();
      }
    }
  }

  // Call functionality
  Future<void> _makePhoneCall(Map<String, dynamic> appointment) async {
    // Get the phone number from appointment data
    final phoneNumber = _getAppointeeMobile(appointment);
    
    if (phoneNumber.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create the phone URL
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getAppointeeMobile(Map<String, dynamic> appointment) {
    final phoneNumber = appointment['phoneNumber'];
    if (phoneNumber is Map<String, dynamic>) {
      final countryCode = phoneNumber['countryCode']?.toString() ?? '';
      final number = phoneNumber['number']?.toString() ?? '';
      if (countryCode.isNotEmpty && number.isNotEmpty) {
        return '$countryCode$number';
      }
    }
    return phoneNumber?.toString() ?? '';
  }

  // Email functionality
  void _showEmailForm(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildActionHeader('Send Email'),
            Expanded(
              child: EmailForm(
                appointment: appointment,
                onSend: () {
                  // Refresh appointment data after sending email
                  _fetchAppointments();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SMS functionality
  void _showMessageForm(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildActionHeader('Send SMS'),
            Expanded(child: MessageForm(appointment: appointment)),
          ],
        ),
      ),
    );
  }

  // Call form functionality
  void _showCallForm(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildActionHeader('Make Call'),
            Expanded(child: CallForm(appointment: appointment)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    _fetchAppointments(search: query);
  }

  void _loadMore() {
    if (!_isLoadingMore && _hasMoreData) {
      _fetchAppointments(isLoadMore: true);
    }
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: _isLoadingMore 
            ? const LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF553C9A)], // darker purple when loading
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // purple gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
                  child: InkWell(
            onTap: _isLoadingMore ? null : () {
              print("🔍 Load more button tapped!");
              _loadMore();
            },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: _isLoadingMore 
                  ? const LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF553C9A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingMore) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Loading more...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Load More Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dot indicator
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendBulkEmail() {
    if (_selectedAppointments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one appointment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get selected appointments
    final selectedAppointments = _filteredAppointments
        .where((appointment) => _selectedAppointments.contains(appointment['_id']?.toString() ?? ''))
        .toList();

    // Show bulk email form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildActionHeader('Bulk Email (${selectedAppointments.length} recipients)'),
            Expanded(
              child: BulkEmailForm(
                appointments: selectedAppointments,
                onSend: () {
                  Navigator.pop(context);
                  // Refresh appointment data after sending bulk email
                  _fetchAppointments();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bulk email sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onClose: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

  String _getEmailStatus(Map<String, dynamic> appointment) {
    // Get emailStatus from appointment data
    final emailStatus = appointment['emailStatus']?.toString();
    
    // If emailStatus is "sent", show "Email Sent"
    // If emailStatus is null or empty, show "Not Sent"
    if (emailStatus == 'sent') {
      return 'Email Sent';
    } else {
      return 'Not Sent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Darshan Line',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange, Colors.orange, Colors.orangeAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: const SidebarComponent(),
      body: Stack(
        children: [
          Container(
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Action buttons
                // Padding(
                //   padding: const EdgeInsets.all(16),
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: ElevatedButton.icon(
                //           onPressed: () {},
                //           icon: const Icon(Icons.upload, color: Colors.white),
                //           label: const Text(
                //             'Bulk Upload',
                //             style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                //           ),
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor: Colors.deepPurple,
                //             foregroundColor: Colors.white,
                //             padding: const EdgeInsets.symmetric(vertical: 12),
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //           ),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: ElevatedButton.icon(
                //           onPressed: () {},
                //           icon: const Icon(Icons.video_call, color: Colors.white),
                //           label: const Text(
                //             'Zoom Link',
                //             style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                //           ),
                //           style: ElevatedButton.styleFrom(
                //             backgroundColor: Colors.deepPurple,
                //             foregroundColor: Colors.white,
                //             padding: const EdgeInsets.symmetric(vertical: 12),
                //             shape: RoundedRectangleBorder(
                //               borderRadius: BorderRadius.circular(8),
                //             ),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: CommonSearchBarComponent(
                    controller: _searchController,
                    onSearch: _performSearch,
                    hintText: 'Search by name, role, or date...',
                  ),
                ),

                const SizedBox(height: 12),

                // Select All and Filter section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Select All Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(),
                            activeColor: Colors.deepPurple,
                          ),
                          const Text(
                            'Select All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Filter button
                      Row(
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
                               itemCount: _filteredAppointments.length + (_hasMoreData ? 1 : 0),
                               itemBuilder: (context, index) {
                                 // Debug print to check load more logic
                                 print("🔍 ListView - index: $index, total: ${_filteredAppointments.length}, hasMoreData: $_hasMoreData");
                                 
                                 // Show load more button at the end
                                 if (index == _filteredAppointments.length) {
                                   print("🔍 Showing load more button at index: $index");
                                   return _buildLoadMoreButton();
                                 }
                                 
                                 final item = _filteredAppointments[index];
                                return PersonCardComponent(
                                  name: item['createdBy']?['fullName'] ?? 'No Name',
                                  darshanType: item['venue']?['name'] ?? 'N/A',
                                  darshanLineDate: _formatDate(item['scheduledDateTime']?['date']),
                                  requestedDate: _formatPreferredDateRange(item['preferredDateRange']),
                                  peopleCount: _getPeopleCount(item),
                                  status: _getAppointmentStatus(item),
                                  emailStatus: _getEmailStatus(item),
                                  isSelected: _selectedAppointments.contains(item['_id']?.toString() ?? ''),
                                  index: index, // Add index for alternating colors
                                  onSelectionChanged: (isSelected) {
                                    _toggleAppointmentSelection(item['_id']?.toString() ?? '');
                                  },
                                  onBellPressed: () {
                                    // Show email form (first icon)
                                    _showEmailForm(item);
                                  },
                                  onMessagePressed: () {
                                    // Show SMS form (second icon)
                                    _showMessageForm(item);
                                  },
                                  onAddPressed: () {
                                    // Direct call functionality (third icon)
                                    _makePhoneCall(item);
                                  },
                                  onCallPressed: () {
                                    // Direct call functionality - opens phone dialer
                                    _makePhoneCall(item);
                                  },
                                  onGroupPressed: () {
                                    // Show email form
                                    _showEmailForm(item);
                                  },
                                  onStarPressed: () {
                                    // Star functionality (placeholder)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Star functionality coming soon')),
                                    );
                                  },
                                  onDeletePressed: () {
                                    // Delete functionality (placeholder)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Delete functionality coming soon')),
                                    );
                                  },
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
      // Floating bottom button for bulk actions
      floatingActionButton: _buttonAnimationController != null
          ? AnimatedBuilder(
              animation: _buttonAnimationController!,
              builder: (context, child) {
                return AnimatedOpacity(
                  opacity: _buttonOpacityAnimation?.value ?? 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Transform.scale(
                    scale: _buttonScaleAnimation?.value ?? 1.0,
                    child: _selectedAppointments.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue[700]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Count text
                                  Text(
                                    '${_selectedAppointments.length} items selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Email button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _sendBulkEmail,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.email,
                                                size: 16,
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Send Bulk Email',
                                                style: TextStyle(
                                                  color: Colors.blue[600],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
