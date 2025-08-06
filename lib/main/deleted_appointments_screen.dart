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
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  
  // Filter state
  String _selectedFilter = 'All Deleted';
  List<Map<String, dynamic>> _secretaries = [];
  bool _isLoadingSecretaries = false;
  
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
    
    showFilterBottomSheetForDeleted(
      context: context,
      secretaries: _secretaries,
      selectedFilter: _selectedFilter,
      onFilterSelected: (String filter) {
        print('🔍 Filter selected: $filter');
        setState(() {
          _selectedFilter = filter;
          _currentPage = 1;
          _appointments.clear();
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
        title: const Text('Deleted Appointments'),
        backgroundColor: Colors.white,
        elevation: 0,
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
          
          // Results Count
          if (_totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    '$_totalCount deleted appointment${_totalCount == 1 ? '' : 's'} found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_hasNextPage || _hasPrevPage)
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
          return AppointmentCard(
            appointment: appointment,
            index: index, // Pass the index for alternating colors
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