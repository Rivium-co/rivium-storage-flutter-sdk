<p align="center">
  <a href="https://rivium.co">
    <img src="https://rivium.co/logo.png" alt="Rivium" width="120" />
  </a>
</p>

<h3 align="center">Rivium Storage Flutter SDK</h3>

<p align="center">
  File storage and image transformation SDK for Flutter with upload, download, and on-the-fly image processing.
</p>

<p align="center">
  <a href="https://pub.dev/packages/rivium_storage"><img src="https://img.shields.io/pub/v/rivium_storage.svg" alt="pub.dev" /></a>
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart 3.0+" />
  <img src="https://img.shields.io/badge/Flutter-all_platforms-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License" />
</p>

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rivium_storage: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:rivium_storage/rivium_storage.dart';

// Initialize
final storage = RiviumStorage(apiKey: 'rv_live_xxx');

// Upload a file
final file = await storage.upload(
  'my-bucket',
  'images/photo.jpg',
  imageBytes,
  options: UploadOptions(contentType: 'image/jpeg'),
);

// Get a thumbnail URL
final thumbnailUrl = storage.getTransformUrl(
  file.id,
  transforms: ImageTransforms(width: 200, height: 200, fit: 'cover'),
);

// Download a file
final bytes = await storage.download(file.id);
```

## Features

- **Upload & Download** — Upload files to buckets, download by ID or path
- **Image Transformations** — Resize, crop, blur, sharpen, rotate, format conversion (WebP, AVIF, JPEG, PNG) on the fly
- **Bucket Management** — List, get by ID or name
- **File Operations** — List with prefix filtering, pagination, get metadata, delete single or batch
- **URL Generation** — Public URLs, download URLs, and transform URLs for direct use in `Image.network()`
- **Security Rules** — User-scoped access with `setUserId()` for bucket policy enforcement
- **Pure Dart** — Works on all Flutter platforms (iOS, Android, Web, macOS, Windows, Linux)

## Documentation

For full documentation, visit [rivium.co/docs](https://rivium.co/cloud/rivium-storage/docs).
- [Rivium Cloud](https://rivium.co/cloud)
- [Rivium Console](https://console.rivium.co)

## License

MIT License — see [LICENSE](LICENSE) for details.
