import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'models.dart';

export 'models.dart';

/// RiviumStorage Flutter SDK
///
/// Official SDK for RiviumStorage file storage and image transformation service.
///
/// Example:
/// ```dart
/// final storage = RiviumStorage(apiKey: 'rv_live_xxx');
///
/// // Upload a file
/// final file = await storage.upload(
///   'my-bucket',
///   'images/photo.jpg',
///   imageBytes,
///   options: UploadOptions(contentType: 'image/jpeg'),
/// );
///
/// // Get transformed URL
/// final thumbnailUrl = storage.getTransformUrl(
///   file.id,
///   transforms: ImageTransforms(width: 200, height: 200),
/// );
/// ```
class RiviumStorage {
  final RiviumStorageConfig _config;
  final http.Client _client;

  /// Create a new RiviumStorage instance
  ///
  /// [apiKey] - Your project API key (rv_live_xxx or rv_test_xxx)
  /// [userId] - Optional user ID for bucket policy enforcement.
  ///   When set, sent as x-user-id header so security rules can match {userId} paths.
  /// [timeout] - Optional request timeout in seconds (default: 30)
  RiviumStorage({
    required String apiKey,
    String? userId,
    int timeout = 30,
    http.Client? httpClient,
  })  : _config = RiviumStorageConfig(
          apiKey: apiKey,
          userId: userId,
          timeout: timeout,
        ),
        _client = httpClient ?? http.Client();

  /// Set the user ID for policy enforcement.
  /// Call this after user login so security rules with {userId} work.
  void setUserId(String? userId) {
    _config.userId = userId;
  }

  /// Get the current user ID
  String? get userId => _config.userId;

  /// Dispose the HTTP client
  void dispose() {
    _client.close();
  }

  // ==========================================
  // Private Helpers
  // ==========================================

  Map<String, String> get _headers {
    final headers = {
      'x-api-key': _config.apiKey,
      'Content-Type': 'application/json',
    };
    if (_config.userId != null) {
      headers['x-user-id'] = _config.userId!;
    }
    return headers;
  }

  Future<T> _request<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    final uri = Uri.parse('${_config.baseUrl}$endpoint');

    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: _headers)
              .timeout(Duration(seconds: _config.timeout));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
              .timeout(Duration(seconds: _config.timeout));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
              .timeout(Duration(seconds: _config.timeout));
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: _headers)
              .timeout(Duration(seconds: _config.timeout));
          break;
        default:
          throw RiviumStorageException('Unknown HTTP method: $method');
      }
    } catch (e) {
      if (e is RiviumStorageException) rethrow;
      throw RiviumStorageException('Network error: $e');
    }

    if (response.statusCode >= 400) {
      String message = 'HTTP ${response.statusCode}';
      try {
        final error = jsonDecode(response.body);
        message = error['message'] ?? message;
      } catch (_) {}
      throw RiviumStorageException(message, statusCode: response.statusCode);
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      return {} as T;
    }

    final data = jsonDecode(response.body);

    if (fromJson != null) {
      return fromJson(data as Map<String, dynamic>);
    }

    if (fromJsonList != null) {
      return fromJsonList(data as List<dynamic>);
    }

    return data as T;
  }

  // ==========================================
  // Bucket Operations
  // ==========================================

  /// List all buckets in the project
  Future<List<Bucket>> listBuckets() async {
    return _request<List<Bucket>>(
      'GET',
      '/api/v1/buckets',
      fromJsonList: (list) =>
          list.map((e) => Bucket.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Get bucket by ID
  Future<Bucket> getBucket(String bucketId) async {
    return _request<Bucket>(
      'GET',
      '/api/v1/buckets/$bucketId',
      fromJson: Bucket.fromJson,
    );
  }

  /// Get bucket by name
  Future<Bucket> getBucketByName(String name) async {
    return _request<Bucket>(
      'GET',
      '/api/v1/buckets/name/$name',
      fromJson: Bucket.fromJson,
    );
  }

  // ==========================================
  // File Operations
  // ==========================================

  /// Upload a file to a bucket
  ///
  /// [bucketId] - Bucket ID or name
  /// [path] - File path within the bucket
  /// [data] - File content as bytes
  /// [options] - Upload options (contentType, metadata)
  Future<StorageFile> upload(
    String bucketId,
    String path,
    Uint8List data, {
    UploadOptions options = const UploadOptions(),
  }) async {
    final uri = Uri.parse('${_config.baseUrl}/api/v1/buckets/$bucketId/files');

    // Detect content type
    final contentType = options.contentType ??
        lookupMimeType(path) ??
        'application/octet-stream';

    // Create multipart request
    final request = http.MultipartRequest('POST', uri);
    request.headers['x-api-key'] = _config.apiKey;
    if (_config.userId != null) {
      request.headers['x-user-id'] = _config.userId!;
    }

    // Add file
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      data,
      filename: path.split('/').last,
      contentType: MediaType.parse(contentType),
    ));

    // Add path
    request.fields['path'] = path;

    // Add metadata
    if (options.metadata != null) {
      request.fields['metadata'] = jsonEncode(options.metadata);
    }

    try {
      final streamedResponse = await request.send().timeout(
            Duration(seconds: _config.timeout),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 400) {
        String message = 'Upload failed: ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          message = error['message'] ?? message;
        } catch (_) {}
        throw RiviumStorageException(message, statusCode: response.statusCode);
      }

      return StorageFile.fromJson(jsonDecode(response.body));
    } catch (e) {
      if (e is RiviumStorageException) rethrow;
      throw RiviumStorageException('Upload error: $e');
    }
  }

  /// List files in a bucket
  Future<ListFilesResult> listFiles(
    String bucketId, {
    ListFilesOptions options = const ListFilesOptions(),
  }) async {
    final params = <String, String>{};
    if (options.prefix != null) params['prefix'] = options.prefix!;
    if (options.limit != null) params['limit'] = options.limit.toString();
    if (options.cursor != null) params['cursor'] = options.cursor!;

    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    return _request<ListFilesResult>(
      'GET',
      '/api/v1/buckets/$bucketId/files$query',
      fromJson: ListFilesResult.fromJson,
    );
  }

  /// Get file by ID
  Future<StorageFile> getFile(String fileId) async {
    return _request<StorageFile>(
      'GET',
      '/api/v1/files/$fileId',
      fromJson: StorageFile.fromJson,
    );
  }

  /// Get file by path in bucket
  Future<StorageFile> getFileByPath(String bucketId, String path) async {
    return _request<StorageFile>(
      'GET',
      '/api/v1/buckets/$bucketId/files/$path',
      fromJson: StorageFile.fromJson,
    );
  }

  /// Download file content
  Future<Uint8List> download(String fileId) async {
    final uri = Uri.parse('${_config.baseUrl}/api/v1/files/$fileId/download');

    try {
      final downloadHeaders = {'x-api-key': _config.apiKey};
      if (_config.userId != null) {
        downloadHeaders['x-user-id'] = _config.userId!;
      }
      final response = await _client
          .get(uri, headers: downloadHeaders)
          .timeout(Duration(seconds: _config.timeout));

      if (response.statusCode >= 400) {
        throw RiviumStorageException(
          'Download failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      return response.bodyBytes;
    } catch (e) {
      if (e is RiviumStorageException) rethrow;
      throw RiviumStorageException('Download error: $e');
    }
  }

  /// Delete a file by ID
  Future<void> delete(String fileId) async {
    await _request<Map<String, dynamic>>(
      'DELETE',
      '/api/v1/files/$fileId',
    );
  }

  /// Delete a file by path in bucket
  Future<void> deleteByPath(String bucketId, String path) async {
    await _request<Map<String, dynamic>>(
      'DELETE',
      '/api/v1/buckets/$bucketId/files/$path',
    );
  }

  /// Delete multiple files by IDs
  ///
  /// Returns the number of files successfully deleted
  Future<DeleteManyResult> deleteMany(List<String> fileIds) async {
    return _request<DeleteManyResult>(
      'POST',
      '/api/v1/files/delete-many',
      body: {'ids': fileIds},
      fromJson: DeleteManyResult.fromJson,
    );
  }

  // ==========================================
  // URL Generation
  // ==========================================

  /// Get public URL for a file (only works for public buckets)
  String getUrl(String fileId) {
    return '${_config.baseUrl}/api/v1/files/$fileId/url';
  }

  /// Get URL with image transformations
  ///
  /// [fileId] - The file ID
  /// [transforms] - Image transformation options
  String getTransformUrl(String fileId, {ImageTransforms? transforms}) {
    final params = transforms?.toQueryParams() ?? {};
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    return '${_config.baseUrl}/api/v1/transform/$fileId$query';
  }

  /// Get download URL (for direct access without SDK)
  String getDownloadUrl(String fileId) {
    return '${_config.baseUrl}/api/v1/files/$fileId/download';
  }
}
