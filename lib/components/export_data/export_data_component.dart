import 'package:flutter/material.dart';
import 'export_data_card_component.dart';

class ExportDataComponent extends StatefulWidget {
  final String? initialSearchQuery;
  final Function(String)? onSearchChanged;
  final Function(Map<String, dynamic>)? onFiltersApplied;
  
  const ExportDataComponent({
    super.key,
    this.initialSearchQuery,
    this.onSearchChanged,
    this.onFiltersApplied,
  });

  @override
  State<ExportDataComponent> createState() => _ExportDataComponentState();
}

class _ExportDataComponentState extends State<ExportDataComponent> {
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state variables
  String _selectedLocation = 'All Locations';
  String _selectedSecretary = 'All Secretaries';
  String _selectedTime = 'All Time';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildFilterModal();
      },
    );
  }

  Widget _buildFilterModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Swipe indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdowns - Stacked vertically
                _buildDropdown(
                  value: _selectedLocation,
                  hint: 'All Locations',
                  onTap: () => _showLocationDropdown(),
                ),
                
                const SizedBox(height: 16),
                
                _buildDropdown(
                  value: _selectedSecretary,
                  hint: 'All Secretaries',
                  onTap: () => _showSecretaryDropdown(),
                ),
                
                const SizedBox(height: 16),
                
                _buildDropdown(
                  value: _selectedTime,
                  hint: 'All Time',
                  onTap: () => _showTimeDropdown(),
                ),
                
                const SizedBox(height: 20),
                
                // Bottom Row - Date Range
                Row(
                  children: [
                    const Text(
                      'Date Range:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateField(
                        value: _fromDate,
                        hint: 'From Date',
                        onTap: () => _selectFromDate(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'to',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateField(
                        value: _toDate,
                        hint: 'To Date',
                        onTap: () => _selectToDate(),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Clear Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _clearFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value == hint ? hint : value,
                style: TextStyle(
                  fontSize: 14,
                  color: value == hint ? Colors.grey.shade600 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? hint : _formatDate(value),
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDropdown() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return _buildSelectionModal(
          'Select Location',
          [
            'All Locations',
            'Mumbai',
            'Delhi',
            'Bangalore',
            'Chennai',
            'Hyderabad',
            'Pune',
            'Kolkata',
            'Ahmedabad',
          ],
          _selectedLocation,
          (value) {
            setState(() {
              _selectedLocation = value;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showSecretaryDropdown() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return _buildSelectionModal(
          'Select Secretary',
          ['All Secretaries', 'Secretary 1', 'Secretary 2', 'Secretary 3'],
          _selectedSecretary,
          (value) {
            setState(() {
              _selectedSecretary = value;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showTimeDropdown() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return _buildSelectionModal(
          'Select Time',
          [
            'All Time',
            'Today',
            'Tomorrow',
            'Upcoming',
            'Past',
          ],
          _selectedTime,
          (value) {
            setState(() {
              _selectedTime = value;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildSelectionModal(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onSelect,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...options.map((option) => ListTile(
            title: Text(option),
            onTap: () => onSelect(option),
            trailing: selectedValue == option
                ? const Icon(Icons.check, color: Colors.deepPurple)
                : null,
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearFilters() {
    setState(() {
      _selectedLocation = 'All Locations';
      _selectedSecretary = 'All Secretaries';
      _selectedTime = 'All Time';
      _fromDate = null;
      _toDate = null;
    });
    Navigator.pop(context);
  }

  Map<String, dynamic> _getCurrentFilters() {
    return {
      'search': _searchController.text,
      'location': _selectedLocation,
      'secretary': _selectedSecretary,
      'time': _selectedTime,
      'fromDate': _fromDate,
      'toDate': _toDate,
    };
  }

  // Dummy data for cards
  final List<Map<String, String>> _dummyData = [
    {
      'fullName': 'Rajesh Kumar',
      'phone': '+91 98765 43210',
      'email': 'rajesh.kumar@example.com',
      'designation': 'Software Engineer',
      'location': 'Mumbai Ashram',
      'time': '10:00 AM - 11:00 AM',
      'noOfPeople': '3',
      'namesOfPeople': 'Rajesh Kumar, Priya Kumar, Arjun Kumar',
      'secretaryName': 'Secretary 1',
    },
    {
      'fullName': 'Priya Sharma',
      'phone': '+91 87654 32109',
      'email': 'priya.sharma@example.com',
      'designation': 'Marketing Manager',
      'location': 'Delhi Ashram',
      'time': '2:00 PM - 3:00 PM',
      'noOfPeople': '2',
      'namesOfPeople': 'Priya Sharma, Amit Sharma',
      'secretaryName': 'Secretary 2',
    },
    {
      'fullName': 'Amit Patel',
      'phone': '+91 76543 21098',
      'email': 'amit.patel@example.com',
      'designation': 'Business Analyst',
      'location': 'Bangalore Ashram',
      'time': '4:00 PM - 5:00 PM',
      'noOfPeople': '1',
      'namesOfPeople': 'Amit Patel',
      'secretaryName': 'Secretary 3',
    },
    {
      'fullName': 'Sneha Reddy',
      'phone': '+91 65432 10987',
      'email': 'sneha.reddy@example.com',
      'designation': 'Project Manager',
      'location': 'Chennai Ashram',
      'time': '11:00 AM - 12:00 PM',
      'noOfPeople': '4',
      'namesOfPeople': 'Sneha Reddy, Ravi Reddy, Meera Reddy, Karthik Reddy',
      'secretaryName': 'Secretary 1',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar (Full Width)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search data to export...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        if (widget.onSearchChanged != null) {
                          widget.onSearchChanged!('');
                        }
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                // Trigger rebuild to show/hide clear button
              });
              if (widget.onSearchChanged != null) {
                widget.onSearchChanged!(value);
              }
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Filter Button (Compact with Icon and Text)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showFilterModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Cards Section
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _dummyData.length,
                  itemBuilder: (context, index) {
                    final data = _dummyData[index];
                    return ExportDataCard(
                      fullName: data['fullName']!,
                      phone: data['phone']!,
                      email: data['email']!,
                      designation: data['designation']!,
                      location: data['location']!,
                      time: data['time']!,
                      noOfPeople: data['noOfPeople']!,
                      namesOfPeople: data['namesOfPeople']!,
                      secretaryName: data['secretaryName']!,
                      onTap: () {
                        // Handle card tap
                        print('Card tapped: ${data['fullName']}');
                      },
                    );
                  },
                ),
              ),
              
              // Export All Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle export all data
                    print('Exporting all data...');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exporting all data...'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download, size: 20),
                  label: const Text(
                    'Export All Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 