import 'package:flutter/material.dart';
import 'components/private_album_component.dart';
import 'user_sidebar.dart';

class PrivateAlbumScreen extends StatefulWidget {
  const PrivateAlbumScreen({super.key});

  @override
  State<PrivateAlbumScreen> createState() => _PrivateAlbumScreenState();
}

class _PrivateAlbumScreenState extends State<PrivateAlbumScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Album Access'),
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
      body: const PrivateAlbumComponent(),
    );
  }
}

