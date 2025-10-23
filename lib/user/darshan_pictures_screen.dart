import 'package:flutter/material.dart';
import 'darshan_pictures_component.dart';
import 'user_sidebar.dart';

class DarshanPicturesScreen extends StatelessWidget {
  const DarshanPicturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Darshan Pictures'),
        backgroundColor: const Color(0xFFF97316),
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
      body: const DarshanPicturesComponent(),
    );
  }
}
