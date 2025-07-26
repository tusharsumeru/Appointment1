import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/quick_darsnan/date_selector_component.dart';
import '../components/common/search_bar_component.dart';
import '../components/quick_darsnan/quick_darshan_card_component.dart';

class QuickDarshanLineScreen extends StatefulWidget {
  const QuickDarshanLineScreen({super.key});

  @override
  State<QuickDarshanLineScreen> createState() => _QuickDarshanLineScreenState();
}

class _QuickDarshanLineScreenState extends State<QuickDarshanLineScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _performSearch(String query) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Darshan Line'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: const SidebarComponent(),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // Date selector and search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date selector
                  DateSelectorComponent(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  CommonSearchBarComponent(
                    controller: _searchController,
                    onSearch: _performSearch,
                    hintText: 'Search by name or darshan type...',
                  ),
                ],
              ),
            ),
            // Cards list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  QuickDarshanCardComponent(
                    name: 'John Doe',
                    mobileNumber: '+91 98765 43210',
                    numberOfPeople: 3,
                    appointmentDate: '15/05/2025',
                    status: 'Confirmed',
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
                  QuickDarshanCardComponent(
                    name: 'Jane Smith',
                    mobileNumber: '+91 87654 32109',
                    numberOfPeople: 2,
                    appointmentDate: '16/05/2025',
                    status: 'Pending',
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
          ],
        ),
      ),
    );
  }
} 