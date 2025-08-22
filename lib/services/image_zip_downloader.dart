import 'dart:typed_data';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Simple progress object you can plug into your UI.
class ZipProgress {
  final int filesDone;
  final int filesTotal;
  final String? currentUrl;
  final int currentBytes;
  final int? currentTotalBytes;
  const ZipProgress({
    required this.filesDone,
    required this.filesTotal,
    this.currentUrl,
    this.currentBytes = 0,
    this.currentTotalBytes,
  });
}

class ImageZipDownloader {
  ImageZipDownloader({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  /// Map content-type → extension. Extend if you need more types.
  String _extFromContentType(String? ctype, {String fallback = 'jpg'}) {
    if (ctype == null) return fallback;
    final t = ctype.split(';').first.trim().toLowerCase();
    switch (t) {
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      case 'image/bmp':
        return 'bmp';
      case 'image/svg+xml':
        return 'svg';
      case 'image/heic':
        return 'heic';
      default:
        return fallback;
    }
  }

  /// Core API:
  /// - Downloads all [imageUrls] with up to [concurrency] parallel requests.
  /// - Zips them and saves to Downloads/Files with [zipName].
  /// - Reports progress through [onProgress].
  /// Returns a saved path on Android, or '' on iOS (Files sheet).
  Future<String> saveImagesAsZipToDownloads({
    required List<String> imageUrls,
    String zipName = 'images_bundle.zip',
    int concurrency = 4,
    void Function(ZipProgress p)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (imageUrls.isEmpty) {
      throw ArgumentError('imageUrls cannot be empty');
    }
    if (!zipName.toLowerCase().endsWith('.zip')) {
      zipName = '$zipName.zip';
    }

    // Guard: sane concurrency
    concurrency = concurrency.clamp(1, 8);

    // Download with concurrency: process in windows of [concurrency]
    final filesTotal = imageUrls.length;
    var filesDone = 0;

    // Create archive and populate in order (we'll preserve index-based names)
    final archive = Archive();

    // Work list with index to preserve deterministic names
    final indexed = List.generate(imageUrls.length, (i) => (i, imageUrls[i]));

    // Helper to download a single URL
    Future<void> _fetchOne(int index, String url) async {
      onProgress?.call(ZipProgress(
        filesDone: filesDone,
        filesTotal: filesTotal,
        currentUrl: url,
        currentBytes: 0,
        currentTotalBytes: null,
      ));

      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {'Accept': 'image/*'},
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (rec, total) {
          onProgress?.call(ZipProgress(
            filesDone: filesDone,
            filesTotal: filesTotal,
            currentUrl: url,
            currentBytes: rec,
            currentTotalBytes: total > 0 ? total : null,
          ));
        },
      );

      if (resp.statusCode == 200 && resp.data != null) {
        // derive a filename
        final headers = resp.headers.map;
        final ctype = headers['content-type']?.first;
        final ext = _extFromContentType(ctype);
        final fileName = 'img_${index + 1}.$ext';

        final bytes = Uint8List.fromList(resp.data!);
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      } else {
        // if one fails, we skip it (or you can throw to enforce all-or-nothing)
        // throw Exception('Failed to download $url (${resp.statusCode})');
      }

      filesDone++;
      onProgress?.call(ZipProgress(
        filesDone: filesDone,
        filesTotal: filesTotal,
        currentUrl: url,
        currentBytes: 0,
        currentTotalBytes: null,
      ));
    }

    // Process in batches to cap parallelism
    for (var i = 0; i < indexed.length; i += concurrency) {
      final batch = indexed.skip(i).take(concurrency).toList();
      await Future.wait(batch.map((item) => _fetchOne(item.$1, item.$2)));
    }

    // Encode ZIP
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw Exception('Failed to create ZIP archive');
    }

    // Save ZIP file and share it
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/$zipName');
    await zipFile.writeAsBytes(zipped);

    // Share the ZIP file
    await Share.shareXFiles(
      [XFile(zipFile.path)],
      text: 'Divine Pictures ZIP - ${imageUrls.length} images',
      subject: 'Divine Pictures ZIP',
    );

    return zipFile.path;
  }

  /// Alternative method to save directly to Downloads folder (Android only)
  Future<String?> saveImagesAsZipToDownloadsFolder({
    required List<String> imageUrls,
    String zipName = 'images_bundle.zip',
    int concurrency = 4,
    void Function(ZipProgress p)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (imageUrls.isEmpty) {
      throw ArgumentError('imageUrls cannot be empty');
    }
    if (!zipName.toLowerCase().endsWith('.zip')) {
      zipName = '$zipName.zip';
    }

    // Check if we're on Android
    if (!Platform.isAndroid) {
      throw UnsupportedError('Direct download to Downloads folder is only supported on Android');
    }

    // Request storage permission with comprehensive handling
    List<Permission> permissions = [];
    
    // For Android 13+ (API 33+), we need different permissions
    if (Platform.isAndroid) {
      // Try multiple permission types for better compatibility
      permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.photos,
        Permission.videos,
      ];
    }
    
    bool permissionGranted = false;
    String permissionError = '';
    
    for (Permission permission in permissions) {
      try {
        PermissionStatus status = await permission.status;
        
        if (status.isDenied) {
          status = await permission.request();
        }
        
        if (status.isGranted) {
          permissionGranted = true;
          break;
        } else if (status.isPermanentlyDenied) {
          permissionError = 'Storage permission is permanently denied. Please enable it in Settings > Apps > [App Name] > Permissions > Storage';
        } else {
          permissionError = 'Storage permission is required to save ZIP file. Please grant storage permission.';
        }
      } catch (e) {
        print('Error requesting permission $permission: $e');
        continue;
      }
    }
    
    if (!permissionGranted) {
      throw Exception(permissionError);
    }

    // Guard: sane concurrency
    concurrency = concurrency.clamp(1, 8);

    // Download with concurrency: process in windows of [concurrency]
    final filesTotal = imageUrls.length;
    var filesDone = 0;

    // Create archive and populate in order (we'll preserve index-based names)
    final archive = Archive();

    // Work list with index to preserve deterministic names
    final indexed = List.generate(imageUrls.length, (i) => (i, imageUrls[i]));

    // Helper to download a single URL
    Future<void> _fetchOne(int index, String url) async {
      onProgress?.call(ZipProgress(
        filesDone: filesDone,
        filesTotal: filesTotal,
        currentUrl: url,
        currentBytes: 0,
        currentTotalBytes: null,
      ));

      final resp = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          headers: {'Accept': 'image/*'},
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (rec, total) {
          onProgress?.call(ZipProgress(
            filesDone: filesDone,
            filesTotal: filesTotal,
            currentUrl: url,
            currentBytes: rec,
            currentTotalBytes: total > 0 ? total : null,
          ));
        },
      );

      if (resp.statusCode == 200 && resp.data != null) {
        // derive a filename
        final headers = resp.headers.map;
        final ctype = headers['content-type']?.first;
        final ext = _extFromContentType(ctype);
        final fileName = 'img_${index + 1}.$ext';

        final bytes = Uint8List.fromList(resp.data!);
        archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
      }

      filesDone++;
      onProgress?.call(ZipProgress(
        filesDone: filesDone,
        filesTotal: filesTotal,
        currentUrl: url,
        currentBytes: 0,
        currentTotalBytes: null,
      ));
    }

    // Process in batches to cap parallelism
    for (var i = 0; i < indexed.length; i += concurrency) {
      final batch = indexed.skip(i).take(concurrency).toList();
      await Future.wait(batch.map((item) => _fetchOne(item.$1, item.$2)));
    }

    // Encode ZIP
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw Exception('Failed to create ZIP archive');
    }

    // Try to save to Downloads folder on Android
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        // Test if we can write to the directory
        final testFile = File('${downloadsDir.path}/test_write_permission.tmp');
        try {
          await testFile.writeAsString('test');
          await testFile.delete();
          
          // If we can write, save the ZIP file
          final zipFile = File('${downloadsDir.path}/$zipName');
          await zipFile.writeAsBytes(zipped);
          return zipFile.path;
        } catch (writeError) {
          print('Cannot write to Downloads folder: $writeError');
          throw Exception('Cannot write to Downloads folder. Please check storage permissions.');
        }
      } else {
        print('Downloads folder does not exist');
      }
    } catch (e) {
      print('Failed to access Downloads folder: $e');
    }
    
    // Fallback to app documents directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final zipFile = File('${appDir.path}/$zipName');
      await zipFile.writeAsBytes(zipped);
      return zipFile.path;
    } catch (e) {
      throw Exception('Failed to save ZIP file: $e');
    }
  }
}
