import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/reference-from/reference_card.dart';
import '../components/reference-from/reference_detail_screen.dart';
import '../components/reference-from/filter.dart';
import '../components/reference-from/bulk_email_bottom_sheet.dart';
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
  int _totalItems = 0;
  int _itemsPerPage = 20;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;


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
    });
    _applyFilters();
  }

  // Pagination navigation methods
  void _goToNextPage() {
    if (_hasNextPage && !_isLoading) {
      _loadReferenceDataWithFilters(page: _currentPage + 1);
    }
  }

  void _goToPreviousPage() {
    if (_hasPreviousPage && !_isLoading) {
      _loadReferenceDataWithFilters(page: _currentPage - 1);
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages && page != _currentPage && !_isLoading) {
      _loadReferenceDataWithFilters(page: page);
    }
  }

  // Get count of approved forms only
  int _getApprovedFormsCount() {
    return _filteredReferenceData.where((form) {
      final status = (form['status'] ?? '').toString().toLowerCase();
      return status == 'approved';
    }).length;
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

  Future<void> _loadReferenceDataWithFilters({bool isRefresh = false, int? page}) async {
    try {
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        return;
      }

      // Reset to page 1 on refresh or when applying new filters
      if (isRefresh || page == null) {
        _currentPage = 1;
      } else {
        _currentPage = page;
      }

      // Clear data on refresh
      if (isRefresh) {
        _referenceData.clear();
        _filteredReferenceData.clear();
      }

      // Show loading state
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      
      // Prepare filter parameters
      String? statusFilter;
      if (_selectedStatus != 'all') {
        statusFilter = _selectedStatus;
      }
      
      String? startDateFilter;
      if (_startDate != null) {
        startDateFilter = _startDate!.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
      }
      
      String? endDateFilter;
      if (_endDate != null) {
        endDateFilter = _endDate!.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
      }
      
      String? searchFilter;
      final searchTerm = _searchController.text.trim();
      if (searchTerm.isNotEmpty) {
        searchFilter = searchTerm;
      }
      
      
      final result = await ActionService.getAllReferenceForms(
        status: statusFilter,
        search: searchFilter,
        startDate: startDateFilter,
        endDate: endDateFilter,
        page: _currentPage,
        limit: _itemsPerPage,
      );
      
      // Check if widget is still mounted after API call
      if (!mounted) {
        return;
      }
      
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && data['forms'] != null) {
          final forms = List<Map<String, dynamic>>.from(data['forms']);
          
          // Parse pagination information
          final pagination = data['pagination'];
          if (pagination != null) {
            _totalPages = pagination['totalPages'] ?? 1;
            _totalItems = pagination['totalItems'] ?? 0;
            _hasNextPage = pagination['hasNextPage'] ?? false;
            _hasPreviousPage = pagination['hasPreviousPage'] ?? false;
          }
          
          setState(() {
            _referenceData = forms;
            _filteredReferenceData = forms;
            _isLoading = false;
          });
          
          
          // Data loaded successfully - no need for toast message
        } else {
          if (mounted) {
            setState(() {
              _referenceData = [];
              _filteredReferenceData = [];
              _errorMessage = 'No reference forms found with current filters';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load reference forms';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      
      // Check if widget is still mounted before setState
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading data: $e';
          _isLoading = false;
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
      // Clear existing data when applying filters
      _referenceData.clear();
      _filteredReferenceData.clear();
      
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


  void _onViewDetails(Map<String, dynamic> reference) {
    if (!mounted) return;
    
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
          
          // Filters are being applied - loading overlay will show
          
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
        // Search Bar and Filter Button in one row
        Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Search Field - Expandable
              Expanded(
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
              
              // Spacing between search and filter
              const SizedBox(width: 12),
              
              // Filter Button
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
        ),
        
        // Bulk Email Button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _showBulkEmailBottomSheet();
                },
                icon: const Icon(
                  Icons.mail,
                  size: 16,
                  color: Colors.blue,
                ),
                label: Text(
                  'Bulk Email (${_getApprovedFormsCount()})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue.shade200),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Reference List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadReferenceDataWithFilters(isRefresh: true);
            },
            color: Colors.deepOrange,
            backgroundColor: Colors.white,
            strokeWidth: 3,
            child: _buildReferenceList(),
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
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _filteredReferenceData.length + (_totalPages > 1 ? 1 : 0), // Add 1 for pagination if needed
      itemBuilder: (context, index) {
        // Show pagination controls after all cards
        if (index == _filteredReferenceData.length && _totalPages > 1) {
          return _buildPaginationControls();
        }
        
        final reference = _filteredReferenceData[index];
        return ReferenceCard(
          referenceData: reference,
          index: index, // Add index parameter for alternating colors
          onViewDetails: () => _onViewDetails(reference),
          onStatusUpdated: () {
            if (mounted) {
              // Refresh data with current filters and search
              _loadReferenceDataWithFilters(isRefresh: true);
            }
          },
        );
      },
    );
  }

  void _showBulkEmailBottomSheet() {
    // Filter to show only approved forms
    final approvedForms = _filteredReferenceData.where((form) {
      final status = (form['status'] ?? '').toString().toLowerCase();
      return status == 'approved';
    }).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BulkEmailBottomSheet(
        referenceForms: approvedForms,
        onSendBulkEmail: (selectedForms, message) async {
          print('📧 onSendBulkEmail callback started with ${selectedForms.length} forms');
          print('📧 Selected forms data: $selectedForms');
          try {
            // Extract selected forms with valid emails (matching JavaScript logic)
            final selectedFormsData = selectedForms
                .map((form) => {
                      'appointmentId': form['id'] ?? form['_id'] ?? 'reference-form-${form['id']}',
                      'email': form['email'],
                      'name': form['name'],
                    })
                .where((form) => form['email'] != null)
                .toList();

            if (selectedFormsData.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No valid email addresses found in selected forms."),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            print('📧 Prepared ${selectedFormsData.length} recipients for API call');
            print('📧 Recipients: $selectedFormsData');
            
            // Debug each recipient individually
            for (int i = 0; i < selectedFormsData.length; i++) {
              final recipient = selectedFormsData[i];
              print('📧 Recipient $i: email=${recipient['email']}, name=${recipient['name']}, appointmentId=${recipient['appointmentId']}');
            }

            // Use the specific reference form approved template
            const templateId = '68bed8fc7b0353b2a4db5776';
            print('📧 Using Reference Form Approved template ID: $templateId');
            print('📧 Note: This template may not populate all variables correctly for reference forms');

            // Call the bulk email API with tags (matching JavaScript logic)
            print('📧 Calling ActionService.sendBulkEmail...');
            print('📧 Note: Template variables may be empty since reference forms don\'t have appointment data');
            final result = await ActionService.sendBulkEmail(
              templateId: templateId,
              recipients: selectedFormsData,
              tags: ["reference-forms", "bulk"],
              message: message ?? "",
            );
            print('📧 API call completed with result: $result');

            // Show result message (matching JavaScript logic)
            if (result['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bulk email sent to ${selectedFormsData.length} approved applicants successfully!',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Failed to send bulk email'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error sending bulk email: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page info
          Text(
            'Page $_currentPage of $_totalPages (${_totalItems} total items)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Pagination buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              ElevatedButton.icon(
                onPressed: _hasPreviousPage && !_isLoading ? _goToPreviousPage : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasPreviousPage && !_isLoading ? Colors.deepOrange : Colors.grey[300],
                  foregroundColor: _hasPreviousPage && !_isLoading ? Colors.white : Colors.grey[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Page numbers (show up to 5 pages)
              ..._buildPageNumbers(),
              
              const SizedBox(width: 16),
              
              // Next button
              ElevatedButton.icon(
                onPressed: _hasNextPage && !_isLoading ? _goToNextPage : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasNextPage && !_isLoading ? Colors.deepOrange : Colors.grey[300],
                  foregroundColor: _hasNextPage && !_isLoading ? Colors.white : Colors.grey[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    
    // Calculate which pages to show
    int startPage = (_currentPage - 2).clamp(1, _totalPages);
    int endPage = (_currentPage + 2).clamp(1, _totalPages);
    
    // Adjust if we're near the beginning or end
    if (endPage - startPage < 4) {
      if (startPage == 1) {
        endPage = (startPage + 4).clamp(1, _totalPages);
      } else {
        startPage = (endPage - 4).clamp(1, _totalPages);
      }
    }
    
    // Add first page and ellipsis if needed
    if (startPage > 1) {
      pageNumbers.add(_buildPageButton(1));
      if (startPage > 2) {
        pageNumbers.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
    }
    
    // Add page numbers
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(i));
    }
    
    // Add ellipsis and last page if needed
    if (endPage < _totalPages) {
      if (endPage < _totalPages - 1) {
        pageNumbers.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey[600])),
          ),
        );
      }
      pageNumbers.add(_buildPageButton(_totalPages));
    }
    
    return pageNumbers;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == _currentPage;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: !_isLoading ? () => _goToPage(page) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentPage ? Colors.deepOrange : Colors.white,
          foregroundColor: isCurrentPage ? Colors.white : Colors.grey[700],
          elevation: isCurrentPage ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isCurrentPage ? Colors.deepOrange : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(40, 36),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
