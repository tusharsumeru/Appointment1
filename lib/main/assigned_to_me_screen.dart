import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../action/jwt_utils.dart';
import 'global_search_screen.dart';

class AssignedToMeScreen extends StatefulWidget {
  const AssignedToMeScreen({super.key});

  @override
  State<AssignedToMeScreen> createState() => _AssignedToMeScreenState();
}

class _AssignedToMeScreenState extends State<AssignedToMeScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _currentUser;
  String? _currentUserId;
  
  // Pagination state
  int _currentPage = 1;
  bool _hasMoreAppointments = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndAppointments();
  }

  Future<void> _loadCurrentUserAndAppointments() async {
    await _loadCurrentUser();
    await _fetchAppointments();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // First try to get user data from JWT token
      final token = await StorageService.getToken();
      if (token != null) {
        // Extract MongoDB ID from JWT token
        final mongoId = JwtUtils.extractMongoId(token);
        if (mongoId != null) {
          setState(() {
            _currentUserId = mongoId;
          });
        }

        // Also get user info from JWT token
        final userInfo = JwtUtils.getUserInfoFromToken(token);
        if (userInfo != null) {
          setState(() {
            _currentUser = userInfo;
          });
        }
      }

      // Fallback to stored user data if JWT extraction fails
      if (_currentUser == null) {
        final userData = await StorageService.getUserData();
        setState(() {
          _currentUser = userData;
          _currentUserId = userData?['userId']?.toString();
        });
      }
    } catch (e) {
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the new method that extracts MongoDB ID from JWT token
      final result = await ActionService.getAssignedToMeAppointments(
        status: 'pending',
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
      final result = await ActionService.getAssignedToMeAppointments(
        page: nextPage,
        limit: 10,
        status: 'pending',
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
    
    // Find the appointment index
    final index = _appointments.indexWhere((appointment) {
      final appId = appointment['appointmentId']?.toString();
      final appMongoId = appointment['_id']?.toString();
      return appId == appointmentId || appMongoId == appointmentId;
    });
    
    
    if (index == -1) {
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
    
    // Optimistically update UI first
    setState(() {
      _appointments[index]['starred'] = !currentStarredStatus;
    });

    try {
      // Call the API to update starred status
      final desiredStarredStatus = !currentStarredStatus;
      final result = await ActionService.updateStarred(appointmentId, starred: desiredStarredStatus);
      
      if (result['success']) {
        // Update with the actual response from API
        final newStarredStatus = result['data']?['starred'] ?? !currentStarredStatus;
        
        // Check if the API response matches our expected toggle
        // If API returns the same status as before, it means the toggle didn't work as expected
        // In this case, we'll use our optimistic update
        final expectedNewStatus = !currentStarredStatus;
        final finalStatus = (newStarredStatus == expectedNewStatus) ? newStarredStatus : expectedNewStatus;
        
        
        setState(() {
          // Update the starred status in the list (keep appointment in assigned to me)
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
      setState(() {
        _appointments[index]['starred'] = currentStarredStatus;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
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
      drawer: const SidebarComponent(),
      appBar: AppBar(
        title: const Text(
          'Assigned to Me',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No appointments assigned to you',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You have no appointments assigned to you',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [

                    // Appointments List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _fetchAppointments();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refreshing assigned appointments...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: ListView.builder(
                          physics: const ClampingScrollPhysics(),
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
                            return AppointmentCard(
                              appointment: appointment,
                              index: index, // Pass the index for alternating colors
                              onStarToggle: (isStarred) async {
                                final appointmentId = appointment['appointmentId']?.toString() ?? 
                                                    appointment['_id']?.toString() ?? '';
                                await _toggleStar(appointmentId);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
} 