import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_card.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../action/jwt_utils.dart';

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
      print('Error loading current user: $e');
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the new method that extracts MongoDB ID from JWT token
      final result = await ActionService.getAssignedToMeAppointments();
      
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
    // Call the API to update starred status
    final result = await ActionService.updateStarred(appointmentId);
    
    if (result['success']) {
      setState(() {
        final index = _appointments.indexWhere((appointment) => appointment['_id'] == appointmentId);
        if (index != -1) {
          // Update the starred status based on API response
          final newStarredStatus = result['data']?['starred'] ?? false;
          _appointments[index]['starred'] = newStarredStatus;
        }
      });
    } else {
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
        title: const Text('Assigned to Me'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAppointments();
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
              : ListView.builder(
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
                      onStarToggle: (isStarred) async {
                        final appointmentId = appointment['appointmentId']?.toString() ?? 
                                            appointment['_id']?.toString() ?? '';
                        await _toggleStar(appointmentId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isStarred ? 'Added to favorites' : 'Removed from favorites'),
                              backgroundColor: Colors.green,
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: Colors.white,
                                onPressed: () async {
                                  await _toggleStar(appointmentId);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
} 