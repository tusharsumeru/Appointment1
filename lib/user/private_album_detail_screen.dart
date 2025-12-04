import 'package:flutter/material.dart';
import 'components/private_album_detail_component.dart';

class PrivateAlbumDetailScreen extends StatelessWidget {
  final Map<String, dynamic> album;

  const PrivateAlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final albumId = album['album_id'] ?? album['_id'] ?? '';
    final title = albumId.isNotEmpty ? 'Private Album/$albumId' : 'Private Album';
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PrivateAlbumDetailComponent(album: album),
    );
  }
}

