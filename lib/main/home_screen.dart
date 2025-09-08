import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../action/storage_service.dart';
import 'add_new_screen.dart';
import 'global_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await StorageService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getWelcomeMessage() {
    if (_isLoading) return 'Loading...';
    
    String? userRole = _userData?['role']?.toString().toLowerCase();
    String userName = _userData?['fullName'] ?? _userData?['firstName'] ?? 'User';
    
    switch (userRole) {
      case 'secretary':
        return 'Welcome back, $userName! You\'re logged in as Secretary.';
      case 'admin':
        return 'Welcome back, $userName! You\'re logged in as Administrator.';
      case 'user':
      case 'client':
        return 'Welcome back, $userName!';
      default:
        return 'Welcome back, $userName!';
    }
  }

  String _getSubtitle() {
    if (_isLoading) return 'Loading...';
    
    String? userRole = _userData?['role']?.toString().toLowerCase();
    
    switch (userRole) {
      case 'secretary':
        return 'Manage appointments and schedules efficiently';
      case 'admin':
        return 'Administrative dashboard and user management';
      case 'user':
      case 'client':
        return 'View and manage your appointments';
      default:
        return 'This is your main dashboard';
    }
  }

  String _getActionText() {
    if (_isLoading) return 'Loading...';
    
    String? userRole = _userData?['role']?.toString().toLowerCase();
    
    switch (userRole) {
      case 'secretary':
        return 'Tap the + button to add a new appointment';
      case 'admin':
        return 'Tap the + button to add a new user';
      case 'user':
      case 'client':
        return 'Tap the + button to request an appointment';
      default:
        return 'Tap the + button to get started';
    }
  }

  IconData _getMainIcon() {
    if (_isLoading) return Icons.home;
    
    String? userRole = _userData?['role']?.toString().toLowerCase();
    
    switch (userRole) {
      case 'secretary':
        return Icons.manage_accounts;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'user':
      case 'client':
        return Icons.person;
      default:
        return Icons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointment App',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.deepOrange, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                _getMainIcon(),
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _getWelcomeMessage(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _getSubtitle(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Text(
              _getActionText(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNewScreen(),
            ),
          );
        },
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
} 