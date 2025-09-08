import 'package:flutter/material.dart';
import '../action/action.dart';
import '../components/inbox/appointment_card.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/inbox/appointment_detail_page.dart';
import '../components/inbox/filter_bottom_sheet.dart';
import 'global_search_screen.dart';


class DeletedAppointmentsScreen extends StatefulWidget {
  const DeletedAppointmentsScreen({super.key});

  @override
  State<DeletedAppointmentsScreen> createState() => _DeletedAppointmentsScreenState();
}

class _DeletedAppointmentsScreenState extends State<DeletedAppointmentsScreen> {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _hasNextPage = true; // Initialize to true like starred screen
  bool _hasPrevPage = false;
  
  // Filter state
  String _selectedFilter = 'All Deleted';
  List<Map<String, dynamic>> _secretaries = [];
  bool _isLoadingSecretaries = false;
  
  // Star toggle loading state
  Set<String> _starToggleLoadingIds = {};
  
  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDeletedAppointments();
    _fetchSecretaries();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasNextPage && !_isLoading && !_isLoadingMore) {
        _loadNextPage();
      }
    }
  }

  Future<void> _loadDeletedAppointments({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _appointments.clear();
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ActionService.getDeletedAppointments(
        page: _currentPage,
        limit: 10,
        assignedSecretary: _getFilterValueForAPI(),
      );

      if (result['success']) {
        final data = result['data'];
        final appointments = data['appointments'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        


        setState(() {
          if (refresh || _currentPage == 1) {
            _appointments = appointments.map((appointment) {
              if (appointment is Map<String, dynamic>) {
                return appointment;
              } else if (appointment is Map) {
                return Map<String, dynamic>.from(appointment);
              } else {
                return <String, dynamic>{};
              }
            }).toList();
          } else {
            _appointments.addAll(appointments.map((appointment) {
              if (appointment is Map<String, dynamic>) {
                return appointment;
              } else if (appointment is Map) {
                return Map<String, dynamic>.from(appointment);
              } else {
                return <String, dynamic>{};
              }
            }).toList());
          }

          if (pagination != null) {
            _currentPage = pagination['currentPage'] ?? 1;
            _totalPages = pagination['totalPages'] ?? 1;
            _totalCount = pagination['totalCount'] ?? 0;
            _hasNextPage = pagination['hasNextPage'] ?? false;
            _hasPrevPage = pagination['hasPrevPage'] ?? false;
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load deleted appointments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_hasNextPage && !_isLoading && !_isLoadingMore) {
      setState(() {
        _isLoadingMore = true;
      });

      try {
        final nextPage = _currentPage + 1;
        final result = await ActionService.getDeletedAppointments(
          page: nextPage,
          limit: 10,
          assignedSecretary: _getFilterValueForAPI(),
        );

        if (result['success']) {
          final data = result['data'];
          final appointments = data['appointments'] as List<dynamic>? ?? [];
          final pagination = data['pagination'] as Map<String, dynamic>?;

          if (appointments.isNotEmpty) {
            setState(() {
              _appointments.addAll(appointments.map((appointment) {
                if (appointment is Map<String, dynamic>) {
                  return appointment;
                } else if (appointment is Map) {
                  return Map<String, dynamic>.from(appointment);
                } else {
                  return <String, dynamic>{};
                }
              }).toList());

              if (pagination != null) {
                _currentPage = pagination['currentPage'] ?? nextPage;
                _totalPages = pagination['totalPages'] ?? 1;
                _totalCount = pagination['totalCount'] ?? 0;
                _hasNextPage = pagination['hasNextPage'] ?? false;
                _hasPrevPage = pagination['hasPrevPage'] ?? false;
              }
            });
          } else {
            setState(() {
              _hasNextPage = false;
            });
          }
        } else {
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load more appointments: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
  }

  Future<void> _toggleStar(String appointmentId) async {
    
    // Find the appointment index before making the API call
    final index = _appointments.indexWhere((appointment) => 
      appointment['_id'] == appointmentId || 
      appointment['appointmentId'] == appointmentId
    );
    
    
    if (index == -1) {
      return;
    }

    // Add to loading state
    setState(() {
      _starToggleLoadingIds.add(appointmentId);
    });

    // Get current starred status
    final currentStarredStatus = _appointments[index]['starred'] ?? false;
    
    // Optimistically update UI first (like inbox screen)
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
        final expectedNewStatus = !currentStarredStatus;
        final finalStatus = (newStarredStatus == expectedNewStatus) ? newStarredStatus : expectedNewStatus;
        
        
        setState(() {
          // Update the starred status in the list
          if (index < _appointments.length) {
            _appointments[index]['starred'] = finalStatus;
          }
        });
        
        // Show success message
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
        // Check if it's a 404 error (appointment not found - likely because it's deleted)
        if (result['statusCode'] == 404) {
          // Revert the optimistic update
          setState(() {
            _appointments[index]['starred'] = currentStarredStatus;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Star functionality is not available for deleted appointments'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Revert the optimistic update on other failures
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
      }
    } catch (e) {
      // Revert the optimistic update on error
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

  Future<void> _fetchSecretaries() async {
    setState(() {
      _isLoadingSecretaries = true;
    });

    try {
      final result = await ActionService.getAllSecretaries(
        limit: 4,
        isActive: true,
      );


      if (result['success']) {
        final data = result['data'];
        
        if (data != null && data['secretaries'] != null) {
          final List<dynamic> secretariesData = data['secretaries'];
          
          setState(() {
            _secretaries = secretariesData.cast<Map<String, dynamic>>();
          });
          
        } else {
        }
      } else {
      }
    } catch (e) {
    } finally {
      setState(() {
        _isLoadingSecretaries = false;
      });
    }
  }

  void _showFilterBottomSheet() {
    
    // Pre-load secretaries if not already loaded
    if (_secretaries.isEmpty && !_isLoadingSecretaries) {
      _fetchSecretaries();
    }

    
    showFilterBottomSheetForDeleted(
      context: context,
      secretaries: _secretaries,
      selectedFilter: _selectedFilter,
      onFilterSelected: (String filter) {
        setState(() {
          _selectedFilter = filter;
          _currentPage = 1;
          _appointments.clear();
          _hasNextPage = true; // Reset to true when filter changes
        });
        _loadDeletedAppointments(refresh: true);
      },
    );
  }

  String? _getFilterValueForAPI() {
    switch (_selectedFilter) {
      case 'All Deleted':
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
            onTap: _isLoadingMore ? null : _loadNextPage,
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
          'Deleted Appointments',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: Column(
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
                    _loadDeletedAppointments(refresh: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing deleted appointments...'),
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
          
          // Header with count and clear all button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_appointments.length} Deleted Appointment${_appointments.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_appointments.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Deleted'),
                          content: const Text('Are you sure you want to permanently delete all appointments from the deleted list?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Clear all deleted appointments
                                setState(() {
                                  _appointments.clear();
                                  _totalCount = 0;
                                  _hasNextPage = false;
                                });
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('All deleted appointments cleared'),
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
            child: _buildAppointmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_isLoading && _appointments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDeletedAppointments(refresh: true),
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
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No deleted appointments found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted appointments will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDeletedAppointments(refresh: true),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        controller: _scrollController,
        padding: EdgeInsets.zero,
        itemCount: _appointments.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _appointments.length) {
            // Load more button
            return _hasNextPage
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
              await _toggleStar(appointmentId);
            },
            onTap: () {
              // Navigate to appointment detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailPage(
                    appointment: appointment,
                    isFromDeletedAppointments: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 