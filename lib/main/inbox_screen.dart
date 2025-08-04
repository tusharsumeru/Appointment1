import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/gear_filter_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Pagination variables
  int _currentPage = 1;
  int _pageSize = 10;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    // Load appointments when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Always fetch fresh data from API
      await _fetchAppointmentsFromAPI();
    } catch (error) {
      print('Error loading appointments: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAppointmentsFromAPI({bool isLoadMore = false}) async {
    try {
      final result = await ActionService.getAppointmentsForSecretary(
        status: 'pending',
        screen: 'inbox',
        page: isLoadMore ? _currentPage + 1 : 1,
        limit: _pageSize,
      );
      
      if (result['success']) {
        final List<dynamic> appointmentsData = result['data'] ?? [];
        
        // Show all appointments including starred ones
        print('🔍 Fetch - total appointments: ${appointmentsData.length}');
        
        if (isLoadMore) {
          // Append new data to existing list
          if (appointmentsData.isNotEmpty) {
            _appointments.addAll(appointmentsData.cast<Map<String, dynamic>>());
            _currentPage++;
            _hasMoreData = appointmentsData.length >= _pageSize;
          } else {
            _hasMoreData = false;
          }
        } else {
          // Replace existing data
          if (appointmentsData.isNotEmpty) {
            _appointments = appointmentsData.cast<Map<String, dynamic>>();
            _currentPage = 1;
            _hasMoreData = appointmentsData.length >= _pageSize;
          } else {
            _appointments = [];
            _currentPage = 1;
            _hasMoreData = false;
          }
        }
        _error = null;
      } else {
        _error = result['message'] ?? 'Failed to fetch appointments';
        if (!isLoadMore) {
          _appointments = [];
        }
      }
    } catch (e) {
      _error = 'Network error: $e';
      if (!isLoadMore) {
        _appointments = [];
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // This method is called when refresh button is clicked
  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Reset pagination when refreshing
    _currentPage = 1;
    _hasMoreData = true;

    await _fetchAppointmentsFromAPI(isLoadMore: false);
  }

  Future<void> _toggleStar(String appointmentId) async {
    print('🔍 Toggle Star - appointmentId: $appointmentId');
    print('🔍 Toggle Star - total appointments: ${_appointments.length}');
    
    // Find the appointment index
    final index = _appointments.indexWhere((appointment) {
      final appId = appointment['appointmentId']?.toString();
      final appMongoId = appointment['_id']?.toString();
      print('🔍 Toggle Star - checking appointment: appId=$appId, appMongoId=$appMongoId');
      return appId == appointmentId || appMongoId == appointmentId;
    });
    
    print('🔍 Toggle Star - found index: $index');
    
    if (index == -1) {
      print('🔍 Toggle Star - appointment not found!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get current starred status
    final currentStarredStatus = _appointments[index]['starred'] == true;
    print('🔍 Toggle Star - current starred status: $currentStarredStatus');
    
    // Optimistically update UI first
    setState(() {
      _appointments[index]['starred'] = !currentStarredStatus;
    });
    print('🔍 Toggle Star - optimistically updated to: ${!currentStarredStatus}');

    try {
      // Call the API to update starred status
      final desiredStarredStatus = !currentStarredStatus;
      final result = await ActionService.updateStarred(appointmentId, starred: desiredStarredStatus);
      print('🔍 Toggle Star - API result: $result');
      
      if (result['success']) {
        // Update with the actual response from API
        final newStarredStatus = result['data']?['starred'] ?? !currentStarredStatus;
        print('🔍 Toggle Star - new starred status from API: $newStarredStatus');
        
        // Check if the API response matches our expected toggle
        // If API returns the same status as before, it means the toggle didn't work as expected
        // In this case, we'll use our optimistic update
        final expectedNewStatus = !currentStarredStatus;
        final finalStatus = (newStarredStatus == expectedNewStatus) ? newStarredStatus : expectedNewStatus;
        
        print('🔍 Toggle Star - expected status: $expectedNewStatus, final status: $finalStatus');
        
        setState(() {
          // Update the starred status in the list (keep appointment in inbox)
          if (index < _appointments.length) {
            _appointments[index]['starred'] = finalStatus;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(finalStatus ? 'Appointment starred!' : 'Appointment unstarred!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Revert the optimistic update on failure
        print('🔍 Toggle Star - API failed, reverting to: $currentStarredStatus');
        setState(() {
          _appointments[index]['starred'] = currentStarredStatus;
        });
        
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
      print('🔍 Toggle Star - Exception occurred: $e');
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
    }
  }

  void _deleteAppointment(String appointmentId) {
    setState(() {
      _appointments.removeWhere((appointment) => appointment['_id'] == appointmentId);
    });
  }

  Future<void> _loadMoreAppointments() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    await _fetchAppointmentsFromAPI(isLoadMore: true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inbox'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [],
      ),
      drawer: const SidebarComponent(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'Loading appointments...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _fetchAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            const Text(
              'Inbox',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'No pending appointments found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _fetchAppointments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header bar with filter and refresh
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Filter section
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue[500],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Filter dropdown button
                  Container(
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
                        Text(
                          'Meera P',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Refresh button
              InkWell(
                onTap: () {
                  _fetchAppointments();
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
        // Content area
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 20), // Adjusted padding
                itemCount: _appointments.length + (_hasMoreData ? 1 : 0), // +1 for load more button
          itemBuilder: (context, index) {
            // Show load more button at the end
            if (index == _appointments.length) {
              return _buildLoadMoreButton();
            }
            
            final appointment = _appointments[index];
            return AppointmentCard(
              appointment: appointment,
              onStarToggle: (isStarred) async {
                print('🔍 Inbox onStarToggle - received isStarred: $isStarred');
                final appointmentId = appointment['appointmentId']?.toString() ?? 
                                    appointment['_id']?.toString() ?? '';
                print('🔍 Inbox onStarToggle - appointmentId: $appointmentId');
                await _toggleStar(appointmentId);
              },

              onRefresh: () {
                // Refresh the appointments list when secretary is updated
                _fetchAppointments();
              },
            );
          },
        ),
      ],
    ),
        ),
      ],
    );
  }
} 