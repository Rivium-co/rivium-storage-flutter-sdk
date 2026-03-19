/// RiviumStorage configuration
class RiviumStorageConfig {
  /// API Key for project identification (rv_live_xxx or rv_test_xxx)
  final String apiKey;

  /// Base URL for RiviumStorage API (internal, not configurable)
  final String baseUrl;

  /// Request timeout in seconds
  final int timeout;

  /// Optional user ID for bucket policy enforcement.
  /// When set, sent as x-user-id header on all requests.
  /// Used for {userId} path matching in security rules.
  /// Can be changed at runtime via [RiviumStorage.setUserId].
  String? userId;

  RiviumStorageConfig({
    required this.apiKey,
    this.baseUrl = 'https://storage.rivium.co',
    this.timeout = 30,
    this.userId,
  });
}

/// Bucket model
class Bucket {
  final String id;
  final String name;
  final String projectId;
  final String organizationId;
  final String visibility;
  final List<String>? allowedMimeTypes;
  final int? maxFileSize;
  final bool policiesEnabled;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bucket({
    required this.id,
    required this.name,
    required this.projectId,
    required this.organizationId,
    required this.visibility,
    this.allowedMimeTypes,
    this.maxFileSize,
    required this.policiesEnabled,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(
      id: json['id'] as String,
      name: json['name'] as String,
      projectId: json['projectId'] as String,
      organizationId: json['organizationId'] as String,
      visibility: json['visibility'] as String,
      allowedMimeTypes: (json['allowedMimeTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      maxFileSize: json['maxFileSize'] as int?,
      policiesEnabled: json['policiesEnabled'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Storage file model
class StorageFile {
  final String id;
  final String bucketId;
  final String path;
  final String fileName;
  final String mimeType;
  final int size;
  final String? checksum;
  final String storageKey;
  final Map<String, dynamic>? metadata;
  final String? uploadedBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? url;

  StorageFile({
    required this.id,
    required this.bucketId,
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.size,
    this.checksum,
    required this.storageKey,
    this.metadata,
    this.uploadedBy,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.url,
  });

  factory StorageFile.fromJson(Map<String, dynamic> json) {
    return StorageFile(
      id: json['id'] as String,
      bucketId: json['bucketId'] as String,
      path: json['path'] as String,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      size: json['size'] as int,
      checksum: json['checksum'] as String?,
      storageKey: json['storageKey'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      uploadedBy: json['uploadedBy'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      url: json['url'] as String?,
    );
  }
}

/// List files result
class ListFilesResult {
  final List<StorageFile> files;
  final String? nextCursor;

  ListFilesResult({
    required this.files,
    this.nextCursor,
  });

  factory ListFilesResult.fromJson(Map<String, dynamic> json) {
    return ListFilesResult(
      files: (json['files'] as List<dynamic>)
          .map((e) => StorageFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

/// Upload options
class UploadOptions {
  /// Content type (MIME type) of the file
  final String? contentType;

  /// Custom metadata to attach to the file
  final Map<String, dynamic>? metadata;

  const UploadOptions({
    this.contentType,
    this.metadata,
  });
}

/// List files options
class ListFilesOptions {
  /// Filter files by path prefix
  final String? prefix;

  /// Maximum number of files to return
  final int? limit;

  /// Cursor for pagination
  final String? cursor;

  const ListFilesOptions({
    this.prefix,
    this.limit,
    this.cursor,
  });
}

/// Image transformation options
class ImageTransforms {
  /// Target width in pixels
  final int? width;

  /// Target height in pixels
  final int? height;

  /// Resize mode: cover, contain, fill, inside, outside
  final String? fit;

  /// Output format: jpeg, png, webp, avif
  final String? format;

  /// Compression quality (1-100)
  final int? quality;

  /// Blur amount (0-100)
  final int? blur;

  /// Sharpen amount (0-100)
  final int? sharpen;

  /// Rotation in degrees (90, 180, 270)
  final int? rotate;

  const ImageTransforms({
    this.width,
    this.height,
    this.fit,
    this.format,
    this.quality,
    this.blur,
    this.sharpen,
    this.rotate,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    if (fit != null) params['fit'] = fit!;
    if (format != null) params['f'] = format!;
    if (quality != null) params['q'] = quality.toString();
    if (blur != null) params['blur'] = blur.toString();
    if (sharpen != null) params['sharpen'] = sharpen.toString();
    if (rotate != null) params['rotate'] = rotate.toString();
    return params;
  }
}

/// Delete many files result
class DeleteManyResult {
  /// Number of files successfully deleted
  final int deleted;

  DeleteManyResult({required this.deleted});

  factory DeleteManyResult.fromJson(Map<String, dynamic> json) {
    return DeleteManyResult(
      deleted: json['deleted'] as int? ?? 0,
    );
  }
}

/// RiviumStorage error
class RiviumStorageException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  RiviumStorageException(this.message, {this.statusCode, this.code});

  @override
  String toString() => 'RiviumStorageException: $message (code: $code, status: $statusCode)';
}
