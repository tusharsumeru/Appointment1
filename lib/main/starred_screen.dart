import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../components/inbox/filter_bottom_sheet.dart';
import '../action/action.dart';
import 'global_search_screen.dart';

class StarredScreen extends StatefulWidget {
  const StarredScreen({super.key});

  @override
  State<StarredScreen> createState() => _StarredScreenState();
}

class _StarredScreenState extends State<StarredScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMoreAppointments = true;
  bool _isLoadingMore = false;
  
  // Filter state
  String _selectedFilter = 'All Starred';
  List<Map<String, dynamic>> _secretaries = [];
  bool _isLoadingSecretaries = false;
  
  // Star toggle loading state
  Set<String> _starToggleLoadingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _fetchSecretaries();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ActionService.getAppointmentsForSecretary(
        starred: true,
        assignedSecretary: _getFilterValueForAPI(),
      );
      
      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];
        
        if (appointmentsData.isNotEmpty) {
          _appointments = appointmentsData.cast<Map<String, dynamic>>();
        } else {
          _appointments = [];
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to fetch appointments';
        _appointments = [];
      }
    } catch (e) {
      _error = 'Network error: $e';
      _appointments = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAppointments() async {
    if (_isLoadingMore || !_hasMoreAppointments) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await ActionService.getAppointmentsForSecretary(
        starred: true,
        page: nextPage,
        limit: 10,
        assignedSecretary: _getFilterValueForAPI(),
      );
      
      if (result['success']) {
        final List<dynamic> newData = result['data'] ?? [];
        if (newData.isNotEmpty) {
          setState(() {
            _appointments.addAll(newData.cast<Map<String, dynamic>>());
            _currentPage = nextPage;
            _hasMoreAppointments = newData.length >= 10; // Assuming 10 is the page size
          });
        } else {
          setState(() {
            _hasMoreAppointments = false;
          });
        }
      } else {
        setState(() {
          _hasMoreAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more appointments: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleStar(String appointmentId) async {
    print('🔍 _toggleStar called with appointmentId: $appointmentId');
    print('🔍 Current appointments count: ${_appointments.length}');
    
    // Find the appointment index before making the API call
    final index = _appointments.indexWhere((appointment) => 
      appointment['_id'] == appointmentId || 
      appointment['appointmentId'] == appointmentId
    );
    
    print('🔍 Found appointment at index: $index');
    
    if (index == -1) {
      print('❌ Appointment not found in starred list: $appointmentId');
      return;
    }

    // Add to loading state
    setState(() {
      _starToggleLoadingIds.add(appointmentId);
    });

    // Get current starred status
    final currentStarredStatus = _appointments[index]['starred'] ?? false;
    print('🔍 Current starred status: $currentStarredStatus');
    
    // Optimistically update UI first (like inbox screen)
    setState(() {
      _appointments[index]['starred'] = !currentStarredStatus;
    });
    print('🔍 Optimistically updated to: ${!currentStarredStatus}');

    try {
      // Call the API to update starred status
      final desiredStarredStatus = !currentStarredStatus;
      final result = await ActionService.updateStarred(appointmentId, starred: desiredStarredStatus);
      print('🔍 API result: $result');
      
      if (result['success']) {
        // Update with the actual response from API
        final newStarredStatus = result['data']?['starred'] ?? !currentStarredStatus;
        print('🔍 New starred status from API: $newStarredStatus');
        
        // Check if the API response matches our expected toggle
        final expectedNewStatus = !currentStarredStatus;
        final finalStatus = (newStarredStatus == expectedNewStatus) ? newStarredStatus : expectedNewStatus;
        
        print('🔍 Expected status: $expectedNewStatus, final status: $finalStatus');
        
        setState(() {
          // Update the starred status in the list
          if (index < _appointments.length) {
            _appointments[index]['starred'] = finalStatus;
          }
          
          // If unstarred, remove from starred screen
          if (!finalStatus) {
            print('🔍 Removing unstarred appointment from starred screen');
            _appointments.removeAt(index);
          }
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(finalStatus ? 'Appointment starred!' : 'Removed from favorites'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Revert the optimistic update on failure
        print('🔍 API failed, reverting to: $currentStarredStatus');
        setState(() {
          _appointments[index]['starred'] = currentStarredStatus;
        });
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update starred status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Revert the optimistic update on error
      print('🔍 Exception occurred: $e');
      setState(() {
        _appointments[index]['starred'] = currentStarredStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Remove from loading state
      setState(() {
        _starToggleLoadingIds.remove(appointmentId);
      });
    }
  }

  void _deleteAppointment(String appointmentId) {
    setState(() {
      _appointments.removeWhere((appointment) => appointment['_id'] == appointmentId);
    });
  }

  Future<void> _fetchSecretaries() async {
    print('🔍 _fetchSecretaries() called');
    setState(() {
      _isLoadingSecretaries = true;
    });

    try {
      final result = await ActionService.getAllSecretaries(
        limit: 4,
        isActive: true,
      );

      print('🔍 Secretaries API result: $result');

      if (result['success']) {
        final data = result['data'];
        print('🔍 Secretaries data: $data');
        
        if (data != null && data['secretaries'] != null) {
          final List<dynamic> secretariesData = data['secretaries'];
          print('🔍 Secretaries list: $secretariesData');
          
          setState(() {
            _secretaries = secretariesData.cast<Map<String, dynamic>>();
          });
          
          print('🔍 Final secretaries list: $_secretaries');
          print('🔍 Secretaries count: ${_secretaries.length}');
        } else {
          print('🔍 No secretaries data found in response');
        }
      } else {
        print('🔍 Secretaries API call failed: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error fetching secretaries: $e');
    } finally {
      setState(() {
        _isLoadingSecretaries = false;
      });
      print('🔍 _isLoadingSecretaries set to false');
    }
  }

  void _showFilterBottomSheet() {
    print('🔍 _showFilterBottomSheet() called');
    print('🔍 Current secretaries count: ${_secretaries.length}');
    print('🔍 Current secretaries: $_secretaries');
    print('🔍 _isLoadingSecretaries: $_isLoadingSecretaries');
    
    // Pre-load secretaries if not already loaded
    if (_secretaries.isEmpty && !_isLoadingSecretaries) {
      print('🔍 Fetching secretaries before showing bottom sheet');
      _fetchSecretaries();
    }

    print('🔍 Showing bottom sheet with secretaries: $_secretaries');
    
    showFilterBottomSheetForStarred(
      context: context,
      secretaries: _secretaries,
      selectedFilter: _selectedFilter,
      onFilterSelected: (String filter) {
        print('🔍 Filter selected: $filter');
        setState(() {
          _selectedFilter = filter;
          _currentPage = 1;
          _hasMoreAppointments = true;
        });
        _fetchAppointments();
      },
    );
  }

  String? _getFilterValueForAPI() {
    switch (_selectedFilter) {
      case 'All Starred':
        return null; // No filter needed
      default:
        final secretary = _secretaries.firstWhere(
          (secretary) => secretary['fullName'] == _selectedFilter,
          orElse: () => {},
        );
        final secretaryId = secretary['_id']?.toString();
        return secretaryId; // Return secretary ID for assignedSecretary parameter
    }
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        color: Colors.white.withOpacity(0.5),
        backgroundBlendMode: BlendMode.overlay,
      ),
      child: Container(
        width: double.infinity,
        height: 44, // h-11 equivalent
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // from-blue-600 to-indigo-600
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.2), // shadow-blue-500/20
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoadingMore ? null : _loadMoreAppointments,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: _isLoadingMore 
                    ? const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF4338CA)], // disabled state
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], // from-blue-600 to-indigo-600
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
                          'Load More Appointments',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Starred Appointments',
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
        elevation: 4,
        shadowColor: Colors.orange.withOpacity(0.3),
        centerTitle: false,
        foregroundColor: Colors.white,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Starred Appointments',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Star appointments to see them here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter and Refresh buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                                                     // Filter dropdown button
                           GestureDetector(
                             onTap: _isLoadingSecretaries ? null : _showFilterBottomSheet,
                             child: Container(
                               height: 36,
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 border: Border.all(color: Colors.grey[200]!),
                                 borderRadius: BorderRadius.circular(8),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.05),
                                     blurRadius: 2,
                                     offset: const Offset(0, 1),
                                   ),
                                 ],
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   if (_isLoadingSecretaries) ...[
                                     const SizedBox(
                                       width: 16,
                                       height: 16,
                                       child: CircularProgressIndicator(
                                         strokeWidth: 2,
                                         valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                       ),
                                     ),
                                     const SizedBox(width: 8),
                                   ],
                                   Text(
                                     _isLoadingSecretaries ? 'Loading...' : _selectedFilter,
                                     style: TextStyle(
                                       fontSize: 16,
                                       color: _isLoadingSecretaries ? Colors.grey[500] : Colors.grey[700],
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   Icon(
                                     Icons.keyboard_arrow_down,
                                     size: 16,
                                     color: _isLoadingSecretaries ? Colors.grey[400] : Colors.grey[500],
                                   ),
                                 ],
                               ),
                             ),
                           ),
                          const Spacer(),
                          // Refresh button
                          InkWell(
                            onTap: () {
                              _fetchAppointments();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refreshing starred appointments...'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Refresh',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Header with count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_appointments.length} Starred Appointment${_appointments.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Clear All Starred'),
                                  content: const Text('Are you sure you want to remove all appointments from starred?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Remove all starred appointments
                                        setState(() {
                                          for (final appointment in _appointments) {
                                            appointment['starred'] = false;
                                          }
                                          _appointments.clear();
                                        });
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('All starred appointments cleared'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Appointments List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _appointments.length + (_hasMoreAppointments ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show load more button at the end
                          if (index == _appointments.length) {
                            return _hasMoreAppointments
                                ? _buildLoadMoreButton()
                                : const SizedBox.shrink();
                          }
                          
                          final appointment = _appointments[index];
                          final appointmentId = appointment['appointmentId']?.toString() ?? 
                                              appointment['_id']?.toString() ?? '';
                          final isStarToggleLoading = _starToggleLoadingIds.contains(appointmentId);
                          
                          return AppointmentCard(
                            appointment: appointment,
                            index: index, // Pass the index for alternating colors
                            onStarToggle: isStarToggleLoading ? null : (isStarred) async {
                              print('🔍 AppointmentCard onStarToggle called with isStarred: $isStarred');
                              print('🔍 Appointment ID: $appointmentId');
                              await _toggleStar(appointmentId);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
} 