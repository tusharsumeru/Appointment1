import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/reference-from/reference_card.dart';
import '../components/reference-from/reference_detail_screen.dart';
import '../components/reference-from/filter.dart';
import '../action/action.dart';

class ReferenceFromListScreen extends StatefulWidget {
  const ReferenceFromListScreen({super.key});

  @override
  State<ReferenceFromListScreen> createState() => _ReferenceFromListScreenState();
}

class _ReferenceFromListScreenState extends State<ReferenceFromListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Dynamic data for reference cards
  List<Map<String, dynamic>> _referenceData = [];
  bool _isLoading = true;
  bool _isApplyingFilters = false; // New flag for filter application
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredReferenceData = [];
  
  // Filter variables
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination variables
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      // Check if widget is still mounted before proceeding
      if (mounted && _searchController.text == _lastSearchTerm) {
        _applySearchFilter();
      }
    });
    _lastSearchTerm = _searchController.text;
  }

  String _lastSearchTerm = '';

  void _applySearchFilter() {
    if (!mounted) return;
    
    final searchTerm = _searchController.text.trim();
    
    if (searchTerm.isEmpty) {
      // If search is empty, reload data with current filters (excluding search)
      _loadReferenceDataWithFilters();
    } else {
      // Apply search filter locally for better UX
      _filterData();
    }
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];
    
    if (_selectedStatus != 'all') {
      activeFilters.add('Status: ${_capitalizeFirst(_selectedStatus)}');
    }
    
    if (_startDate != null) {
      activeFilters.add('From: ${_formatDate(_startDate!)}');
    }
    
    if (_endDate != null) {
      activeFilters.add('To: ${_formatDate(_endDate!)}');
    }
    
    if (activeFilters.isEmpty) {
      return 'No active filters';
    }
    
    return 'Active filters: ${activeFilters.join(', ')}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearFilters() {
    if (!mounted) return;
    
    _safeSetState(() {
      _selectedStatus = 'all';
      _startDate = null;
      _endDate = null;
      // Reset pagination when clearing filters
      _currentPage = 1;
      _hasMoreData = true;
    });
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to safely check if widget is mounted and update state
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadReferenceData() async {
    if (!mounted) return;
    await _loadReferenceDataWithFilters();
  }

  Future<void> _loadReferenceDataWithFilters({bool isRefresh = false}) async {
    try {
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        print('Widget no longer mounted, aborting API call');
        return;
      }

      // Reset pagination on refresh
      if (isRefresh) {
        _currentPage = 1;
        _hasMoreData = true;
        _referenceData.clear();
        _filteredReferenceData.clear();
      }

      // Only show loading state if it's not a refresh operation and not loading more
      if (!isRefresh && !_isLoadingMore) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      print('Loading reference data from API with filters...');
      print('Current filters - Status: $_selectedStatus, StartDate: $_startDate, EndDate: $_endDate');
      
      // Prepare filter parameters
      String? statusFilter;
      if (_selectedStatus != 'all') {
        statusFilter = _selectedStatus;
        print('Applying status filter: $statusFilter');
      }
      
      String? startDateFilter;
      if (_startDate != null) {
        startDateFilter = _startDate!.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
        print('Applying start date filter: $startDateFilter');
      }
      
      String? endDateFilter;
      if (_endDate != null) {
        endDateFilter = _endDate!.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
        print('Applying end date filter: $endDateFilter');
      }
      
      String? searchFilter;
      final searchTerm = _searchController.text.trim();
      if (searchTerm.isNotEmpty) {
        searchFilter = searchTerm;
        print('Applying search filter: $searchFilter');
      }
      
      print('Calling API with filters: status=$statusFilter, search=$searchFilter, startDate=$startDateFilter, endDate=$endDateFilter, page=$_currentPage');
      
      final result = await ActionService.getAllReferenceForms(
        status: statusFilter,
        search: searchFilter,
        startDate: startDateFilter,
        endDate: endDateFilter,
        page: _currentPage,
        limit: 10,
      );
      
      // Check if widget is still mounted after API call
      if (!mounted) {
        print('Widget disposed after API call, aborting setState');
        return;
      }
      
      print('API Response: $result');
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && data['forms'] != null) {
          final forms = List<Map<String, dynamic>>.from(data['forms']);
          final pagination = data['pagination'];
          
          // Update pagination data
          if (pagination != null) {
            _totalPages = pagination['totalPages'] ?? 1;
            _currentPage = pagination['currentPage'] ?? _currentPage;
            _totalItems = pagination['totalItems'] ?? 0;
            _hasMoreData = _currentPage < _totalPages;
          }
          
          setState(() {
            if (isRefresh) {
              _referenceData = forms;
              _filteredReferenceData = forms;
            } else {
              _referenceData.addAll(forms);
              _filteredReferenceData.addAll(forms);
            }
            _isLoading = false;
            _isLoadingMore = false;
          });
          
          print('✅ Successfully loaded ${forms.length} reference forms with applied filters');
          print('Pagination: Page $_currentPage of $_totalPages, Total: $_totalItems, HasMore: $_hasMoreData');
          print('Total forms in state: ${_referenceData.length}');
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isRefresh 
                    ? '✅ Data refreshed successfully! Found $_totalItems reference forms.'
                    : 'Filters applied successfully! Found $_totalItems reference forms.'
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              if (isRefresh) {
                _referenceData = [];
                _filteredReferenceData = [];
              }
              _errorMessage = 'No reference forms found with current filters';
              _isLoading = false;
              _isLoadingMore = false;
            });
          }
          print('⚠️ No forms found with current filters');
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load reference forms';
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
        print('❌ API error: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error loading reference data: $e');
      
      // Check if widget is still mounted before setState
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _isLoading = false;
          _isLoadingMore = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying filters: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _filterData() {
    if (!mounted) return;
    
    final searchTerm = _searchController.text.toLowerCase();
    
    // Apply search filter locally (for better UX)
    if (searchTerm.isEmpty) {
      _filteredReferenceData = List.from(_referenceData);
    } else {
      _filteredReferenceData = _referenceData.where((reference) {
        final name = (reference['name'] ?? '').toString().toLowerCase();
        final email = (reference['email'] ?? '').toString().toLowerCase();
        final phone = (reference['phone'] ?? '').toString().toLowerCase();
        final status = (reference['status'] ?? '').toString().toLowerCase();
        
        return name.contains(searchTerm) ||
               email.contains(searchTerm) ||
               phone.contains(searchTerm) ||
               status.contains(searchTerm);
      }).toList();
    }
    
    // Safely update the UI if widget is still mounted
    _safeSetState(() {
      // Trigger rebuild to show filtered results
    });
  }

  Future<void> _applyFilters() async {
    if (!mounted) return;
    
    try {
      print('Applying filters: status=$_selectedStatus, startDate=$_startDate, endDate=$_endDate');
      
      // Reset pagination when applying new filters
      _currentPage = 1;
      _hasMoreData = true;
      
      // Set applying filters state
      if (mounted) {
        setState(() {
          _isApplyingFilters = true;
        });
      }
      
      // Reload data from API with new filters
      await _loadReferenceDataWithFilters();
      
      // Clear applying filters state
      if (mounted) {
        setState(() {
          _isApplyingFilters = false;
        });
      }
    } catch (e) {
      print('Error applying filters: $e');
      
      // Clear applying filters state on error
      if (mounted) {
        setState(() {
          _isApplyingFilters = false;
        });
      }
      
      // Fallback to local filtering if API fails
      if (mounted) {
        _filterData();
      }
    }
  }

  Future<void> _loadMoreReferenceForms() async {
    if (!_hasMoreData || _isLoading || _isLoadingMore) return;
    
    if (mounted) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });
    }
    
    await _loadReferenceDataWithFilters();
  }

  void _onViewDetails(Map<String, dynamic> reference) {
    if (!mounted) return;
    
    print('Viewing details for reference: $reference');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReferenceDetailScreen(
          referenceData: reference,
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevent accidental dismissal
      enableDrag: false, // Prevent drag to dismiss
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ReferenceFormFilter(
        selectedStatus: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onStartDateChanged: (date) {
          setState(() {
            _startDate = date;
          });
        },
        onEndDateChanged: (date) {
          setState(() {
            _endDate = date;
          });
        },
        onClearFilters: _clearFilters,
        onApplyFilters: () async {
          // Close the bottom sheet first
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          // Show loading indicator
          if (mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Applying filters...'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 1),
                ),
              );
            } catch (e) {
              print('Error showing snackbar: $e');
            }
          }
          
          // Apply filters
          await _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Reference From List',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            if (_isLoading && !_isApplyingFilters) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ],
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
              if (mounted) {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white, // Keep screen background white
            child: _buildBody(),
          ),
          
          // Loading overlay when applying filters
          if (_isApplyingFilters)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Applying filters...',
                          style: TextStyle(
                            fontSize: 16,
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
            SizedBox(height: 16),
            Text(
              'Loading reference forms...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search reference forms...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        if (mounted) {
                          _searchController.clear();
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        // Filter Button and Active Filters Display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isApplyingFilters ? null : () {
                      if (mounted) {
                        _showFilterBottomSheet();
                      }
                    },
                    icon: _isApplyingFilters 
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        )
                      : const Icon(Icons.filter_list, size: 18),
                    label: Text(_isApplyingFilters ? 'Applying...' : 'Filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isApplyingFilters ? Colors.grey[300] : Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              

            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Reference List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              print('🔄 Pull-to-refresh triggered');
              await _loadReferenceDataWithFilters(isRefresh: true);
            },
            color: Colors.deepOrange,
            backgroundColor: Colors.white,
            strokeWidth: 3,
            child: _buildReferenceList(),
          ),
        ),
        
        // Pagination Info
        if (_referenceData.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${_referenceData.length} of $_totalItems reference forms',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        // Load More Button - Always visible
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: (_isLoadingMore || !_hasMoreData) ? null : () => _loadMoreReferenceForms(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasMoreData ? Colors.deepOrange : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoadingMore
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Loading...'),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.keyboard_arrow_down),
                      const SizedBox(width: 8),
                      Text(_hasMoreData ? 'Load More' : 'No More Data'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceList() {

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  _loadReferenceData();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredReferenceData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No reference forms found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'There are no reference forms to display.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredReferenceData.length,
      itemBuilder: (context, index) {
        final reference = _filteredReferenceData[index];
        print('Building reference card $index: $reference');
        return ReferenceCard(
          referenceData: reference,
          index: index, // Add index parameter for alternating colors
          onViewDetails: () => _onViewDetails(reference),
          onStatusUpdated: () {
            if (mounted) {
              _loadReferenceData();
            }
          },
        );
      },
    );
  }
}
