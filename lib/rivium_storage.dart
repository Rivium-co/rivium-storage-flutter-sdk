/// RiviumStorage Flutter SDK
///
/// Official Flutter SDK for RiviumStorage file storage and image transformation service.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:rivium_storage/rivium_storage.dart';
///
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
library rivium_storage;

export 'src/rivium_storage.dart';
export 'src/models.dart';
