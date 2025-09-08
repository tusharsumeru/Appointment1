import 'package:flutter/material.dart';
import '../components/sidebar/sidebar_component.dart';
import '../components/unique_phone_code/unique_phone_code_component.dart';

class UniquePhoneCodeScreen extends StatefulWidget {
  const UniquePhoneCodeScreen({super.key});

  @override
  State<UniquePhoneCodeScreen> createState() => _UniquePhoneCodeScreenState();
}

class _UniquePhoneCodeScreenState extends State<UniquePhoneCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unique Phone Code'),
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const SidebarComponent(currentRoute: 'uniquePhoneCode'),
      body: const Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.phone_android,
                  size: 80,
                  color: Color(0xFFF97316),
                ),
                Text(
                  '***',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: UniquePhoneCodeComponent(),
          ),
        ],
      ),
    );
  }
}
