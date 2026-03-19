import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rivium_storage/rivium_storage.dart';

/// RiviumStorage Flutter SDK - Complete Example
///
/// This example demonstrates ALL capabilities of the RiviumStorage SDK:
/// - Bucket operations (list, get by ID, get by name)
/// - File operations (upload, list, get, download, delete)
/// - URL generation (public URL, transform URL, download URL)
/// - Image transformations (resize, format, quality, effects)
/// - Error handling
///
/// How it works:
/// - Only the API key and bucket name are configured manually.
/// - All IDs (bucket ID, file IDs, paths) are captured from API responses
///   and reused by subsequent operations — nothing is hardcoded.
/// - Run the buttons top-to-bottom for the best experience.

void main() {
  runApp(const RiviumStorageExampleApp());
}

// ============================================================
// Configuration — only these two values need to be set
// ============================================================

// Replace with your actual API key from the Rivium Console
const String apiKey = 'YOUR_API_KEY';
const String bucketName = 'my-bucket';

// User ID for bucket policy enforcement (sent as x-user-id header)
// Set to null to test unauthenticated access
const String userId = 'demo-user-123';

class RiviumStorageExampleApp extends StatelessWidget {
  const RiviumStorageExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiviumStorage Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  final RiviumStorage storage =
      RiviumStorage(apiKey: apiKey, userId: userId, timeout: 30);
  final List<LogEntry> logs = [];
  final ScrollController _scrollController = ScrollController();

  // State captured from API responses — no hardcoded IDs
  String? _lastBucketId;
  String? _lastFileId;
  String? _lastFilePath;
  String? _lastImageFileId;
  final List<String> _uploadedFileIds = [];

  void log(String message, {bool isError = false}) {
    setState(() {
      logs.add(LogEntry(message, isError: isError));
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearLogs() {
    setState(() {
      logs.clear();
    });
  }

  @override
  void dispose() {
    storage.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RiviumStorage SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Buttons section
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bucket Operations
                  const SectionHeader(title: '📦 Bucket Operations'),
                  ExampleButton(
                    label: 'List All Buckets',
                    onPressed: () => _listBuckets(),
                  ),
                  ExampleButton(
                    label: 'Get Bucket by ID',
                    onPressed: () => _getBucketById(),
                  ),
                  ExampleButton(
                    label: 'Get Bucket by Name',
                    onPressed: () => _getBucketByName(),
                  ),

                  // File Operations
                  const SectionHeader(title: '📄 File Operations'),
                  ExampleButton(
                    label: 'Upload Text File',
                    onPressed: () => _uploadTextFile(),
                  ),
                  ExampleButton(
                    label: 'Upload Image (PNG)',
                    onPressed: () => _uploadImage(),
                  ),
                  ExampleButton(
                    label: 'List Files',
                    onPressed: () => _listFiles(),
                  ),
                  ExampleButton(
                    label: 'Get File by ID',
                    onPressed: () => _getFileById(),
                  ),
                  ExampleButton(
                    label: 'Get File by Path',
                    onPressed: () => _getFileByPath(),
                  ),
                  ExampleButton(
                    label: 'Download File',
                    onPressed: () => _downloadFile(),
                  ),
                  ExampleButton(
                    label: 'Delete File',
                    onPressed: () => _deleteFile(),
                  ),
                  ExampleButton(
                    label: 'Delete by Path',
                    onPressed: () => _deleteByPath(),
                  ),
                  ExampleButton(
                    label: 'Delete Multiple Files',
                    onPressed: () => _deleteMany(),
                  ),

                  // URL Generation
                  const SectionHeader(title: '🔗 URL Generation'),
                  ExampleButton(
                    label: 'Generate All URL Types',
                    onPressed: () => _generateUrls(),
                  ),

                  // Image Transforms
                  const SectionHeader(title: '🖼️ Image Transformations'),
                  ExampleButton(
                    label: 'Show All Transform Options',
                    onPressed: () => _showTransforms(),
                  ),

                  // Policy Testing
                  const SectionHeader(title: '🛡️ Policy Testing'),
                  ExampleButton(
                    label: 'Test: No Rules (allow all)',
                    onPressed: () => _testNoRules(),
                  ),
                  ExampleButton(
                    label: 'Test: Private (login required)',
                    onPressed: () => _testPrivate(),
                  ),
                  ExampleButton(
                    label: 'Test: Public Read',
                    onPressed: () => _testPublicRead(),
                  ),
                  ExampleButton(
                    label: 'Test: User Folders',
                    onPressed: () => _testUserFolders(),
                  ),
                  ExampleButton(
                    label: 'Test: Images Only',
                    onPressed: () => _testImagesOnly(),
                  ),
                  ExampleButton(
                    label: 'Test: Bucket Settings (size & type)',
                    onPressed: () => _testBucketSettings(),
                  ),

                  // Error Handling
                  const SectionHeader(title: '⚠️ Error Handling'),
                  ExampleButton(
                    label: 'Demonstrate Error Handling',
                    onPressed: () => _demonstrateErrorHandling(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Log output section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Output Log',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${logs.length} entries',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[900],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final entry = logs[index];
                  return Text(
                    entry.message,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color:
                          entry.isError ? Colors.red[300] : Colors.green[300],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Bucket Operations
  // ============================================================

  Future<void> _listBuckets() async {
    log('Listing all buckets...');
    try {
      final buckets = await storage.listBuckets();
      log('✅ Found ${buckets.length} bucket(s):');
      for (final bucket in buckets) {
        log('   - ${bucket.name} (${bucket.visibility}) [${bucket.id}]');
      }
      // Store the first bucket ID for subsequent operations
      if (buckets.isNotEmpty) {
        _lastBucketId = buckets.first.id;
        log('');
        log('   ℹ️ Stored bucket ID: ${_lastBucketId!} for next operations');
      }
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _getBucketById() async {
    if (_lastBucketId == null) {
      log('⚠️ No bucket ID available. Run "List All Buckets" first.',
          isError: true);
      return;
    }
    log('Getting bucket by ID: $_lastBucketId');
    try {
      final bucket = await storage.getBucket(_lastBucketId!);
      log('✅ Bucket: ${bucket.name}');
      log('   - ID: ${bucket.id}');
      log('   - Visibility: ${bucket.visibility}');
      log('   - Policies Enabled: ${bucket.policiesEnabled}');
      log('   - Active: ${bucket.isActive}');
      if (bucket.allowedMimeTypes != null) {
        log('   - Allowed MIME: ${bucket.allowedMimeTypes!.join(", ")}');
      }
      if (bucket.maxFileSize != null) {
        log('   - Max File Size: ${_formatBytes(bucket.maxFileSize!)}');
      }
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _getBucketByName() async {
    log('Getting bucket by name: $bucketName');
    try {
      final bucket = await storage.getBucketByName(bucketName);
      log('✅ Found: ${bucket.name} (${bucket.id})');
      // Also store the bucket ID from this response
      _lastBucketId = bucket.id;
      log('   ℹ️ Stored bucket ID: ${bucket.id}');
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  // ============================================================
  // File Operations
  // ============================================================

  Future<void> _uploadTextFile() async {
    if (_lastBucketId == null) {
      log('⚠️ No bucket ID available. Run "List All Buckets" or "Get Bucket by Name" first.',
          isError: true);
      return;
    }

    final content =
        'Hello, RiviumStorage! Timestamp: ${DateTime.now().millisecondsSinceEpoch}';
    final data = Uint8List.fromList(content.codeUnits);
    final path = 'examples/test-${DateTime.now().millisecondsSinceEpoch}.txt';

    log('Uploading text file: $path');
    try {
      final file = await storage.upload(
        _lastBucketId!,
        path,
        data,
        options: const UploadOptions(
          contentType: 'text/plain',
          metadata: {'author': 'Flutter Example', 'version': '1.0'},
        ),
      );
      log('✅ Uploaded: ${file.fileName}');
      log('   - ID: ${file.id}');
      log('   - Path: ${file.path}');
      log('   - Size: ${_formatBytes(file.size)}');
      log('   - MIME: ${file.mimeType}');
      if (file.url != null) {
        log('   - URL: ${file.url}');
      }
      // Store for subsequent operations
      _lastFileId = file.id;
      _lastFilePath = file.path;
      _uploadedFileIds.add(file.id);
      log('   ℹ️ Stored file ID: ${file.id}');
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _uploadImage() async {
    if (_lastBucketId == null) {
      log('⚠️ No bucket ID available. Run "List All Buckets" or "Get Bucket by Name" first.',
          isError: true);
      return;
    }

    // 1x1 red PNG
    final redPixelPNG = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53,
      0xDE,
      0x00,
      0x00,
      0x00,
      0x0C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0xD7,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x00,
      0x03,
      0x00,
      0x01,
      0x00,
      0x05,
      0xFE,
      0xD4,
      0xEF,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82
    ]);
    final path =
        'examples/images/sample-${DateTime.now().millisecondsSinceEpoch}.png';

    log('Uploading image: $path');
    try {
      final file = await storage.upload(
        _lastBucketId!,
        path,
        redPixelPNG,
        options: const UploadOptions(contentType: 'image/png'),
      );
      log('✅ Uploaded: ${file.fileName}');
      log('   - ID: ${file.id}');
      log('   - Size: ${_formatBytes(file.size)}');
      // Store image file ID for URL generation and transforms
      _lastImageFileId = file.id;
      _lastFileId = file.id;
      _lastFilePath = file.path;
      _uploadedFileIds.add(file.id);
      log('   ℹ️ Stored image file ID: ${file.id}');
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _listFiles() async {
    if (_lastBucketId == null) {
      log('⚠️ No bucket ID available. Run "List All Buckets" or "Get Bucket by Name" first.',
          isError: true);
      return;
    }

    log('Listing files (prefix: examples/, limit: 10)...');
    try {
      final result = await storage.listFiles(
        _lastBucketId!,
        options: const ListFilesOptions(prefix: 'examples/', limit: 10),
      );
      log('✅ Found ${result.files.length} file(s):');
      for (final file in result.files) {
        log('   - ${file.path} (${_formatBytes(file.size)}) [${file.id}]');
      }
      if (result.nextCursor != null) {
        log('   (More files available, cursor: ${result.nextCursor!.substring(0, 20)}...)');
      }
      // Store first file from listing if we don't have one yet
      if (result.files.isNotEmpty && _lastFileId == null) {
        _lastFileId = result.files.first.id;
        _lastFilePath = result.files.first.path;
        log('');
        log('   ℹ️ Stored file ID: ${_lastFileId!} from listing');
      }
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _getFileById() async {
    if (_lastFileId == null) {
      log('⚠️ No file ID available. Upload a file or run "List Files" first.',
          isError: true);
      return;
    }
    log('Getting file by ID: $_lastFileId');
    try {
      final file = await storage.getFile(_lastFileId!);
      log('✅ Found: ${file.fileName}');
      log('   - Path: ${file.path}');
      log('   - Size: ${_formatBytes(file.size)}');
      log('   - MIME: ${file.mimeType}');
      log('   - Created: ${file.createdAt}');
      log('   - Updated: ${file.updatedAt}');
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _getFileByPath() async {
    if (_lastBucketId == null || _lastFilePath == null) {
      log('⚠️ No bucket or file path available. Upload a file first.',
          isError: true);
      return;
    }
    log('Getting file by path: $_lastFilePath');
    try {
      final file = await storage.getFileByPath(_lastBucketId!, _lastFilePath!);
      log('✅ Found: ${file.fileName} (${file.id})');
      log('   - Size: ${_formatBytes(file.size)}');
      log('   - MIME: ${file.mimeType}');
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _downloadFile() async {
    if (_lastFileId == null) {
      log('⚠️ No file ID available. Upload a file first.', isError: true);
      return;
    }
    log('Downloading file: $_lastFileId');
    try {
      final data = await storage.download(_lastFileId!);
      log('✅ Downloaded ${_formatBytes(data.length)}');
      // Show content preview for small text files
      if (data.length < 200) {
        try {
          final content = String.fromCharCodes(data);
          log('   Content: "$content"');
        } catch (_) {
          log('   (Binary content)');
        }
      }
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _deleteFile() async {
    if (_lastFileId == null) {
      log('⚠️ No file ID available. Upload a file first.', isError: true);
      return;
    }
    log('Deleting file: $_lastFileId');
    try {
      await storage.delete(_lastFileId!);
      log('✅ Deleted successfully');
      _uploadedFileIds.remove(_lastFileId);
      _lastFileId = _uploadedFileIds.isNotEmpty ? _uploadedFileIds.last : null;
      _lastFilePath = null;
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _deleteByPath() async {
    if (_lastBucketId == null || _lastFilePath == null) {
      log('⚠️ No bucket or file path available. Upload a file first.',
          isError: true);
      return;
    }
    log('Deleting file by path: $_lastFilePath');
    try {
      await storage.deleteByPath(_lastBucketId!, _lastFilePath!);
      log('✅ Deleted successfully');
      _uploadedFileIds.remove(_lastFileId);
      _lastFileId = _uploadedFileIds.isNotEmpty ? _uploadedFileIds.last : null;
      _lastFilePath = null;
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  Future<void> _deleteMany() async {
    if (_uploadedFileIds.isEmpty) {
      log('⚠️ No uploaded file IDs tracked. Upload some files first.',
          isError: true);
      return;
    }
    // Copy the list since we'll clear it
    final idsToDelete = List<String>.from(_uploadedFileIds);
    log('Deleting ${idsToDelete.length} file(s): ${idsToDelete.join(', ')}');
    try {
      final result = await storage.deleteMany(idsToDelete);
      log('✅ Deleted ${result.deleted} file(s)');
      _uploadedFileIds.clear();
      _lastFileId = null;
      _lastFilePath = null;
      _lastImageFileId = null;
    } on RiviumStorageException catch (e) {
      log('❌ Error: ${e.message}', isError: true);
    }
  }

  // ============================================================
  // URL Generation
  // ============================================================

  void _generateUrls() {
    if (_lastFileId == null) {
      log('⚠️ No file ID available. Upload a file first.', isError: true);
      return;
    }
    final fileId = _lastFileId!;

    log('Generating URLs for file: $fileId');
    log('');

    // Public URL
    final publicUrl = storage.getUrl(fileId);
    log('📎 Public URL:');
    log('   $publicUrl');

    // Download URL
    final downloadUrl = storage.getDownloadUrl(fileId);
    log('');
    log('📥 Download URL:');
    log('   $downloadUrl');

    // Transform URL (thumbnail)
    final thumbnailUrl = storage.getTransformUrl(
      fileId,
      transforms: const ImageTransforms(width: 200, height: 200),
    );
    log('');
    log('🖼️ Thumbnail URL (200x200):');
    log('   $thumbnailUrl');

    // Transform URL (advanced)
    final advancedUrl = storage.getTransformUrl(
      fileId,
      transforms: const ImageTransforms(
        width: 800,
        height: 600,
        fit: 'cover',
        format: 'webp',
        quality: 85,
      ),
    );
    log('');
    log('🎨 Advanced Transform URL:');
    log('   $advancedUrl');
  }

  // ============================================================
  // Image Transformations
  // ============================================================

  void _showTransforms() {
    // Prefer the image file, fall back to any file
    final fileId = _lastImageFileId ?? _lastFileId;
    if (fileId == null) {
      log('⚠️ No file ID available. Upload an image first.', isError: true);
      return;
    }

    log('Image Transform Examples (file: $fileId):');
    log('=' * 50);

    final transforms = <String, ImageTransforms>{
      'Resize 200x200': const ImageTransforms(width: 200, height: 200),
      'Width only (auto height)': const ImageTransforms(width: 400),
      'Height only (auto width)': const ImageTransforms(height: 300),
      'Fit: cover':
          const ImageTransforms(width: 200, height: 200, fit: 'cover'),
      'Fit: contain':
          const ImageTransforms(width: 200, height: 200, fit: 'contain'),
      'Fit: fill': const ImageTransforms(width: 200, height: 200, fit: 'fill'),
      'Format: WebP': const ImageTransforms(width: 200, format: 'webp'),
      'Format: AVIF': const ImageTransforms(width: 200, format: 'avif'),
      'Format: JPEG': const ImageTransforms(width: 200, format: 'jpeg'),
      'Quality: 50%':
          const ImageTransforms(width: 200, format: 'jpeg', quality: 50),
      'Quality: 90%':
          const ImageTransforms(width: 200, format: 'jpeg', quality: 90),
      'Blur effect': const ImageTransforms(width: 200, blur: 10),
      'Sharpen effect': const ImageTransforms(width: 200, sharpen: 50),
      'Rotate 90°': const ImageTransforms(rotate: 90),
      'Rotate 180°': const ImageTransforms(rotate: 180),
      'Rotate 270°': const ImageTransforms(rotate: 270),
      'Combined transforms': const ImageTransforms(
        width: 400,
        height: 300,
        fit: 'cover',
        format: 'webp',
        quality: 80,
        sharpen: 20,
      ),
    };

    for (final entry in transforms.entries) {
      final url = storage.getTransformUrl(fileId, transforms: entry.value);
      log('');
      log('${entry.key}:');
      log('   $url');
    }
  }

  // ============================================================
  // Policy Testing
  // ============================================================
  //
  // These tests show what each template allows/blocks.
  // Apply the matching template in Dashboard > Bucket > Security Rules
  // before running each test.

  /// Helper: try an upload and report result
  Future<String> _tryUpload(String path, Uint8List data,
      {String? contentType}) async {
    try {
      final file = await storage.upload(
        _lastBucketId!,
        path,
        data,
        options: UploadOptions(contentType: contentType),
      );
      // Clean up: delete the uploaded file
      try {
        await storage.delete(file.id);
      } catch (_) {}
      return '✅ ALLOWED';
    } on RiviumStorageException catch (e) {
      if (e.statusCode == 403) return '❌ DENIED (${e.message})';
      return '⚠️ ERROR (${e.message})';
    }
  }

  /// Helper: try listing files and report result
  Future<String> _tryList() async {
    try {
      await storage.listFiles(_lastBucketId!);
      return '✅ ALLOWED';
    } on RiviumStorageException catch (e) {
      if (e.statusCode == 403) return '❌ DENIED';
      return '⚠️ ERROR (${e.message})';
    }
  }

  /// Helper: create test data
  Uint8List _textData() => Uint8List.fromList('test content'.codeUnits);

  Uint8List _pngData() => Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x00,
        0x00,
        0x02,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0xFD,
        0xD4,
        0x9A,
        0x73,
        0x00,
        0x00,
        0x00,
        0x14,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x62,
        0xF8,
        0x0F,
        0x00,
        0x01,
        0x01,
        0x00,
        0x05,
        0x18,
        0xD8,
        0x4D,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

  Future<void> _ensureBucket() async {
    if (_lastBucketId != null) return;
    log('⚠️ No bucket. Running "List All Buckets" first...');
    await _listBuckets();
    if (_lastBucketId == null) {
      log('❌ No bucket available. Create one in the dashboard first.',
          isError: true);
    }
  }

  // ----------------------------------------------------------
  // Test: No Rules
  // ----------------------------------------------------------
  Future<void> _testNoRules() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: No Rules (no policy on bucket)');
    log('  Dashboard: Delete the policy from bucket');
    log('  When no policy exists, all access is allowed');
    log('═══════════════════════════════════════');
    log('');
    log('Current userId: ${storage.userId ?? "none (unauthenticated)"}');
    log('');

    final ts = DateTime.now().millisecondsSinceEpoch;
    log('Upload text file:   ${await _tryUpload('test/no-rules-$ts.txt', _textData())}');
    log('Upload image:       ${await _tryUpload('test/no-rules-$ts.png', _pngData(), contentType: 'image/png')}');
    log('List files:         ${await _tryList()}');
    log('');
    log('Expected: Everything ✅ ALLOWED (no policy = no restrictions)');
  }

  // ----------------------------------------------------------
  // Test: Private template
  // ----------------------------------------------------------
  Future<void> _testPrivate() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: Private Template');
    log('  Dashboard: Apply "Private" template');
    log('  Rule: Allow only authenticated users');
    log('  (default-deny: unauthenticated = denied)');
    log('═══════════════════════════════════════');
    log('');

    final ts = DateTime.now().millisecondsSinceEpoch;

    // Test WITH userId
    log('── With userId: ${storage.userId} ──');
    log('Upload text:   ${await _tryUpload('test/private-$ts.txt', _textData())}');
    log('Upload image:  ${await _tryUpload('test/private-$ts.png', _pngData(), contentType: 'image/png')}');
    log('List files:    ${await _tryList()}');
    log('');

    // Test WITHOUT userId
    final savedUserId = storage.userId;
    storage.setUserId(null);
    log('── Without userId (unauthenticated) ──');
    log('Upload text:   ${await _tryUpload('test/private-anon-$ts.txt', _textData())}');
    log('List files:    ${await _tryList()}');
    storage.setUserId(savedUserId);

    log('');
    log('Expected:');
    log('  With userId:    Everything ✅ ALLOWED');
    log('  Without userId: Everything ❌ DENIED');
  }

  // ----------------------------------------------------------
  // Test: Public Read template
  // ----------------------------------------------------------
  Future<void> _testPublicRead() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: Public Read Template');
    log('  Dashboard: Apply "Public Read" template');
    log('  Rule: Anyone can read/list,');
    log('        auth required to write/delete');
    log('═══════════════════════════════════════');
    log('');

    final ts = DateTime.now().millisecondsSinceEpoch;

    // Test WITH userId
    log('── With userId: ${storage.userId} ──');
    log('Upload text:   ${await _tryUpload('test/public-$ts.txt', _textData())}');
    log('List files:    ${await _tryList()}');
    log('');

    // Test WITHOUT userId
    final savedUserId = storage.userId;
    storage.setUserId(null);
    log('── Without userId (unauthenticated) ──');
    log('List files:    ${await _tryList()}');
    log('Upload text:   ${await _tryUpload('test/public-anon-$ts.txt', _textData())}');
    storage.setUserId(savedUserId);

    log('');
    log('Expected:');
    log('  With userId:    Upload ✅, List ✅');
    log('  Without userId: List ✅, Upload ❌');
  }

  // ----------------------------------------------------------
  // Test: User Folders template
  // ----------------------------------------------------------
  Future<void> _testUserFolders() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: User Folders Template');
    log('  Dashboard: Apply "User Folders" template');
    log('  Rule: Auth users can read/list all,');
    log('        write/delete only in users/{userId}/');
    log('═══════════════════════════════════════');
    log('');

    final uid = storage.userId ?? 'demo-user-123';
    final ts = DateTime.now().millisecondsSinceEpoch;

    log('── With userId: $uid ──');
    log('');
    log('Upload to own folder (users/$uid/):');
    log('  users/$uid/photo.txt:        ${await _tryUpload('users/$uid/photo-$ts.txt', _textData())}');
    log('  users/$uid/sub/doc.txt:      ${await _tryUpload('users/$uid/sub/doc-$ts.txt', _textData())}');
    log('');
    log('Upload to OTHER user folder:');
    log('  users/other-user/hack.txt:   ${await _tryUpload('users/other-user/hack-$ts.txt', _textData())}');
    log('');
    log('Upload to root (no user folder):');
    log('  test/random.txt:             ${await _tryUpload('test/random-$ts.txt', _textData())}');
    log('');
    log('List files:                    ${await _tryList()}');

    // Test without userId
    final savedUserId = storage.userId;
    storage.setUserId(null);
    log('');
    log('── Without userId (unauthenticated) ──');
    log('Upload:   ${await _tryUpload('users/anon/test-$ts.txt', _textData())}');
    log('List:     ${await _tryList()}');
    storage.setUserId(savedUserId);

    log('');
    log('Expected:');
    log('  Own folder:     ✅ ALLOWED');
    log('  Other folder:   ❌ DENIED');
    log('  Root path:      ❌ DENIED');
    log('  List:           ✅ ALLOWED');
    log('  No userId:      ❌ DENIED (all)');
  }

  // ----------------------------------------------------------
  // Test: Images Only template
  // ----------------------------------------------------------
  Future<void> _testImagesOnly() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: Images Only Template');
    log('  Dashboard: Apply "Images Only" template');
    log('  Rule: Anyone can read/list/delete,');
    log('        only auth users can upload images');
    log('        (JPEG/PNG/GIF/WebP, 5MB max)');
    log('═══════════════════════════════════════');
    log('');

    final ts = DateTime.now().millisecondsSinceEpoch;

    log('── With userId: ${storage.userId} ──');
    log('');
    log('Upload PNG image:        ${await _tryUpload('test/image-$ts.png', _pngData(), contentType: 'image/png')}');
    log('Upload text file:        ${await _tryUpload('test/doc-$ts.txt', _textData(), contentType: 'text/plain')}');
    log('Upload PDF:              ${await _tryUpload('test/doc-$ts.pdf', _textData(), contentType: 'application/pdf')}');
    log('List files:              ${await _tryList()}');

    // Test without userId
    final savedUserId = storage.userId;
    storage.setUserId(null);
    log('');
    log('── Without userId (unauthenticated) ──');
    log('Upload PNG:   ${await _tryUpload('test/anon-$ts.png', _pngData(), contentType: 'image/png')}');
    log('Upload text:  ${await _tryUpload('test/anon-$ts.txt', _textData())}');
    log('List files:   ${await _tryList()}');
    storage.setUserId(savedUserId);

    log('');
    log('Expected:');
    log('  PNG image:      ✅ ALLOWED');
    log('  Text file:      ❌ DENIED (not an image)');
    log('  PDF file:       ❌ DENIED (not an image)');
    log('  List:           ✅ ALLOWED (read is open)');
    log('  No userId PNG:  ❌ DENIED (auth required for upload)');
    log('  No userId List: ✅ ALLOWED (read is open)');
  }

  // ----------------------------------------------------------
  // Test: Bucket Settings (maxFileSize & allowedMimeTypes)
  // ----------------------------------------------------------
  Future<void> _testBucketSettings() async {
    await _ensureBucket();
    if (_lastBucketId == null) return;

    log('');
    log('═══════════════════════════════════════');
    log('  TEST: Bucket Settings');
    log('  (independent of policy rules)');
    log('═══════════════════════════════════════');
    log('');
    log('These are enforced by the bucket config,');
    log('NOT by security rules. They always apply');
    log('even when policies are disabled.');
    log('');

    final ts = DateTime.now().millisecondsSinceEpoch;

    // -- Test allowedMimeTypes --
    log('── Allowed MIME Types ──');
    log('Dashboard: Settings tab → Allowed File Types');
    log('');
    log('Upload PNG:   ${await _tryUpload('test/settings-$ts.png', _pngData(), contentType: 'image/png')}');
    log('Upload text:  ${await _tryUpload('test/settings-$ts.txt', _textData(), contentType: 'text/plain')}');
    log('Upload PDF:   ${await _tryUpload('test/settings-$ts.pdf', _textData(), contentType: 'application/pdf')}');
    log('');

    // -- Test maxFileSize --
    log('── Max File Size ──');
    log('Dashboard: Settings tab → Max File Size');
    log('');
    log('Small file (< 1KB):');
    log('  Upload:       ${await _tryUpload('test/small-$ts.txt', _textData())}');
    log('');

    // Create a large file (~2MB) to test size limits
    final largeData = Uint8List(2 * 1024 * 1024); // 2MB of zeros
    log('Large file (~2MB):');
    log('  Upload:       ${await _tryUpload('test/large-$ts.bin', largeData, contentType: 'application/octet-stream')}');
    log('');

    log('── How to test ──');
    log('');
    log('1. Set Allowed File Types to "image/*"');
    log('   → PNG ✅, text ❌, PDF ❌');
    log('');
    log('2. Add "application/pdf" to Allowed File Types');
    log('   → PNG ✅, text ❌, PDF ✅');
    log('');
    log('3. Remove all file type restrictions');
    log('   → Everything ✅');
    log('');
    log('4. Set Max File Size to 1 MB');
    log('   → Small ✅, Large (~2MB) ❌');
    log('');
    log('5. Set Max File Size to 10 MB');
    log('   → Both ✅');
  }

  // ============================================================
  // Error Handling
  // ============================================================

  Future<void> _demonstrateErrorHandling() async {
    log('Testing error handling with invalid file ID...');
    try {
      await storage.getFile('non-existent-file-id');
    } on RiviumStorageException catch (e) {
      log('');
      log('Caught RiviumStorageException:', isError: true);
      log('   Message: ${e.message}', isError: true);
      if (e.statusCode != null) {
        log('   Status Code: ${e.statusCode}', isError: true);
      }
      if (e.code != null) {
        log('   Error Code: ${e.code}', isError: true);
      }
      log('');
      log('Error handling example complete!');
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

// ============================================================
// UI Components
// ============================================================

class LogEntry {
  final String message;
  final bool isError;

  LogEntry(this.message, {this.isError = false});
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class ExampleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ExampleButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
        child: Text(label),
      ),
    );
  }
}
