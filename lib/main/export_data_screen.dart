import 'package:flutter/material.dart';
import '../components/export_data/export_data_component.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  String _currentSearchQuery = '';
  Map<String, dynamic> _currentFilters = {};

  void _onSearchChanged(String query) {
    setState(() {
      _currentSearchQuery = query;
    });
    // Handle search logic here
    print('Search query: $query');
  }

  void _onFiltersApplied(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
    });
    // Handle filter logic here
    print('Filters applied: $filters');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Export Data',
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
      ),
      body: Container(
        color: Colors.grey[50],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Export Data Component
                Expanded(
                  child: ExportDataComponent(
                    initialSearchQuery: _currentSearchQuery,
                    onSearchChanged: _onSearchChanged,
                    onFiltersApplied: _onFiltersApplied,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 