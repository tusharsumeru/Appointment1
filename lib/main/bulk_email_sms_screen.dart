import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/common/search_bar_component.dart';
import 'global_search_screen.dart';

class BulkEmailSmsScreen extends StatefulWidget {
  const BulkEmailSmsScreen({super.key});

  @override
  State<BulkEmailSmsScreen> createState() => _BulkEmailSmsScreenState();
}

class _BulkEmailSmsScreenState extends State<BulkEmailSmsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter;
  String? _selectedScheduledOption;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  void _onFilterPressed() {
    _showFilterModal();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterModal(
        selectedFilter: _selectedFilter,
        selectedScheduledOption: _selectedScheduledOption,
        onFilterSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
            if (filter != 'Scheduled') {
              _selectedScheduledOption = null;
            }
          });
        },
        onScheduledOptionSelected: (option) {
          setState(() {
            _selectedScheduledOption = option;
          });
        },
      ),
    );
  }

  String get todayDate {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Send Bulk Email & SMS',
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
      ),
      drawer: const SidebarComponent(),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Top row: date and filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.deepPurple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        todayDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt, color: Colors.deepPurple),
                    onPressed: _onFilterPressed,
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: CommonSearchBarComponent(
                controller: _searchController,
                onSearch: _performSearch,
                hintText: 'Search recipients, emails, or phone numbers...',
              ),
            ),
            // Cards list
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _RecipientCard(
                    name: 'John Doe',
                    scheduledDateTime: '15/05/2025 09:00 AM',
                    venue: 'Sri Krishna Temple, Mathura, Uttar Pradesh - Main Darshan Hall, Ground Floor, Near Prasad Counter',
                    numberOfPeople: 3,
                    onCallPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call pressed')),
                      );
                    },
                    onMessagePressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message pressed')),
                      );
                    },
                    onAddPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add pressed')),
                      );
                    },
                  ),
                  _RecipientCard(
                    name: 'Jane Smith',
                    scheduledDateTime: '16/05/2025 02:30 PM',
                    venue: 'Sri Radha Krishna Temple, Vrindavan, Uttar Pradesh - Special Darshan Area, First Floor, VIP Section',
                    numberOfPeople: 2,
                    onCallPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Call pressed')),
                      );
                    },
                    onMessagePressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message pressed')),
                      );
                    },
                    onAddPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add pressed')),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Send pressed')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterModal extends StatelessWidget {
  final String? selectedFilter;
  final String? selectedScheduledOption;
  final Function(String) onFilterSelected;
  final Function(String) onScheduledOptionSelected;

  const _FilterModal({
    required this.selectedFilter,
    required this.selectedScheduledOption,
    required this.onFilterSelected,
    required this.onScheduledOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
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
          // Handle bar
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filter Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Filter options
          ListTile(
            title: const Text('Scheduled'),
            trailing: selectedFilter == 'Scheduled' 
                ? const Icon(Icons.check, color: Colors.deepPurple)
                : null,
            onTap: () {
              onFilterSelected('Scheduled');
            },
          ),
          // Scheduled sub-options
          if (selectedFilter == 'Scheduled') ...[
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('All'),
                    trailing: selectedScheduledOption == 'All' 
                        ? const Icon(Icons.check, color: Colors.deepPurple)
                        : null,
                    onTap: () {
                      onScheduledOptionSelected('All');
                    },
                  ),
                  ListTile(
                    title: const Text('Morning'),
                    trailing: selectedScheduledOption == 'Morning' 
                        ? const Icon(Icons.check, color: Colors.deepPurple)
                        : null,
                    onTap: () {
                      onScheduledOptionSelected('Morning');
                    },
                  ),
                  ListTile(
                    title: const Text('Evening'),
                    trailing: selectedScheduledOption == 'Evening' 
                        ? const Icon(Icons.check, color: Colors.deepPurple)
                        : null,
                    onTap: () {
                      onScheduledOptionSelected('Evening');
                    },
                  ),
                  ListTile(
                    title: const Text('Night'),
                    trailing: selectedScheduledOption == 'Night' 
                        ? const Icon(Icons.check, color: Colors.deepPurple)
                        : null,
                    onTap: () {
                      onScheduledOptionSelected('Night');
                    },
                  ),
                ],
              ),
            ),
          ],
          ListTile(
            title: const Text('TBR/S'),
            trailing: selectedFilter == 'TBR/S' 
                ? const Icon(Icons.check, color: Colors.deepPurple)
                : null,
            onTap: () {
              onFilterSelected('TBR/S');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatefulWidget {
  final String name;
  final String scheduledDateTime;
  final String venue;
  final int numberOfPeople;
  final VoidCallback? onCallPressed;
  final VoidCallback? onMessagePressed;
  final VoidCallback? onAddPressed;

  const _RecipientCard({
    required this.name,
    required this.scheduledDateTime,
    required this.venue,
    required this.numberOfPeople,
    this.onCallPressed,
    this.onMessagePressed,
    this.onAddPressed,
  });

  @override
  State<_RecipientCard> createState() => _RecipientCardState();
}

class _RecipientCardState extends State<_RecipientCard> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with checkbox and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox
              Checkbox(
                value: _isChecked,
                onChanged: (value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
                activeColor: Colors.deepPurple,
              ),
              // Name
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Details in label-value format
          _buildLabelValue('Scheduled Date & Time', widget.scheduledDateTime),
          const SizedBox(height: 8),
          _buildLabelValue('Venue', widget.venue),
          const SizedBox(height: 8),
          _buildLabelValue('No. of People', widget.numberOfPeople.toString()),
          const SizedBox(height: 16),
          // Action icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionIcon(Icons.phone, widget.onCallPressed, 'Call'),
              _buildActionIcon(Icons.email, widget.onMessagePressed, 'Message'),
              _buildActionIcon(Icons.add, widget.onAddPressed, 'Add'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback? onPressed, String label) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
} 