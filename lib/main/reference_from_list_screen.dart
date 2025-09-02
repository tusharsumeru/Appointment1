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
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredReferenceData = [];
  
  // Filter variables
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
    _searchController.addListener(_filterData);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _startDate = null;
      _endDate = null;
    });
    _filterData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('Loading reference data from API...');
      final result = await ActionService.getAllReferenceForms();
      
      print('API Response: $result');
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && data['forms'] != null) {
          setState(() {
            _referenceData = List<Map<String, dynamic>>.from(data['forms']);
            _filteredReferenceData = List<Map<String, dynamic>>.from(data['forms']);
            _isLoading = false;
          });
          print('Loaded ${_referenceData.length} reference forms');
          print('First reference data: ${_referenceData.isNotEmpty ? _referenceData.first : 'No data'}');
        } else {
          setState(() {
            _errorMessage = 'No reference forms found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load reference forms';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reference data: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty && _selectedStatus == 'all' && _startDate == null && _endDate == null) {
        _filteredReferenceData = List.from(_referenceData);
      } else {
        _filteredReferenceData = _referenceData.where((reference) {
          // Search term filter
          final name = (reference['name'] ?? '').toString().toLowerCase();
          final email = (reference['email'] ?? '').toString().toLowerCase();
          final phone = (reference['phone'] ?? '').toString().toLowerCase();
          final status = (reference['status'] ?? '').toString().toLowerCase();
          
          bool matchesSearch = searchTerm.isEmpty || 
                              name.contains(searchTerm) ||
                              email.contains(searchTerm) ||
                              phone.contains(searchTerm) ||
                              status.contains(searchTerm);
          
          // Status filter
          bool matchesStatus = _selectedStatus == 'all' || 
                              status.toLowerCase() == _selectedStatus.toLowerCase();
          
          // Date filter
          bool matchesDate = true;
          if (_startDate != null || _endDate != null) {
            try {
              final createdAt = DateTime.parse(reference['createdAt'] ?? '');
              if (_startDate != null && createdAt.isBefore(_startDate!)) {
                matchesDate = false;
              }
              if (_endDate != null && createdAt.isAfter(_endDate!)) {
                matchesDate = false;
              }
            } catch (e) {
              matchesDate = false;
            }
          }
          
          return matchesSearch && matchesStatus && matchesDate;
        }).toList();
      }
    });
  }

  void _onViewDetails(Map<String, dynamic> reference) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        onApplyFilters: () {
          Navigator.pop(context);
          _filterData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Reference From List',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      drawer: const SidebarComponent(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: _buildBody(),
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
                        _searchController.clear();
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
        
        // Filter Button
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showFilterBottomSheet,
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Reference List
        Expanded(
          child: _buildReferenceList(),
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
              onPressed: _loadReferenceData,
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
          onViewDetails: () => _onViewDetails(reference),
          onStatusUpdated: () => _loadReferenceData(),
        );
      },
    );
  }
}
