import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_sidebar.dart';
import '../action/action.dart';
import '../action/storage_service.dart';
import '../auth/login_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@sumerudigital.com',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+918971227735');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // ----------------------------
  // CONFIRM DELETE POPUP
  // ----------------------------
  void _confirmDelete(BuildContext context) {
    // Preserve the screen context so we can still navigate after closing dialog
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
          "This will permanently delete your account. Are you sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAccount(rootContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // DELETE ACCOUNT FUNCTION
  // ----------------------------
Future<void> _deleteAccount(BuildContext context) async {
  try {
    final result = await ActionService.deleteUserAccount();

    if (!context.mounted) return;

    if (result['success'] == true) {
      print("🔥 API success → Logging out and redirecting.");
        await StorageService.logout();
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      // Even if API fails, force logout to keep user out of a bad state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['message'] ?? "Account deletion failed") +
                " — you have been logged out.",
          ),
        ),
      );
      await StorageService.logout();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
  } catch (e) {
    if (!context.mounted) return;
      // On unexpected errors, still logout for safety
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
      await StorageService.logout();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF97316), // Orange
                Color(0xFFEAB308), // Yellow
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const UserSidebar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const SizedBox(height: 40),

              // ----------------------------
              // CONTACT SUPPORT CARD
              // ----------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Support:',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _launchEmail,
                      child: Row(
                        children: [
                          Icon(Icons.email, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'support@sumerudigital.com',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _launchPhone,
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+91-9164899868',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.access_time, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Support Hours: 9:00 AM - 6:00 PM (Monday to Friday)',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reach out to us during support hours and we\'ll help you with any issues or questions.',
                      style: TextStyle(
                        color: Colors.blue.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------
              // SUPPORT INFORMATION CARD
              // ----------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Support Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our team is here to help you with any technical issues, account questions, or general inquiries.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------
              // DELETE ACCOUNT BUTTON
              // ----------------------------
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _confirmDelete(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 110,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Delete Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 45),
            ],
          ),
        ),
      ),
    );
  }
}
