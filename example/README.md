# RiviumStorage Flutter Example

This example demonstrates all capabilities of the RiviumStorage Flutter SDK.

## Features Demonstrated

### Bucket Operations
- List all buckets
- Get bucket by ID
- Get bucket by name

### File Operations
- Upload files with metadata
- Upload images
- List files with pagination
- Get file by ID
- Get file by path
- Download file content
- Delete single file
- Delete file by path
- Delete multiple files (bulk delete)

### URL Generation
- Public URL for files
- Download URL
- Transform URL for images

### Image Transformations
- Resize (width, height)
- Fit modes (cover, contain, fill)
- Format conversion (webp, avif, jpeg, png)
- Quality adjustment
- Blur effect
- Sharpen effect
- Rotation

### Error Handling
- RiviumStorageException handling
- Error codes and status codes

## Running the Example

### Prerequisites
- Flutter 3.0+
- Dart 3.0+

### Setup

1. Navigate to the example directory:
   ```bash
   cd /path/to/rivium_storage_project/examples/flutter
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API key in `lib/main.dart`:
   ```dart
   const String apiKey = 'rv_live_your_api_key_here';
   const String bucketId = 'your-bucket-id';
   ```

4. Run the app:
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android

   # Web
   flutter run -d chrome

   # macOS
   flutter run -d macos
   ```

## Project Structure

```
examples/flutter/
├── lib/
│   └── main.dart          # Complete example app
├── pubspec.yaml           # Dependencies (links to SDK)
└── README.md
```

## Code Snippets

### Initialize SDK

```dart
import 'package:rivium_storage/rivium_storage.dart';

final storage = RiviumStorage(apiKey: 'rv_live_xxx');
```

### Upload File

```dart
final file = await storage.upload(
  'my-bucket',
  'images/photo.jpg',
  imageBytes,
  options: UploadOptions(
    contentType: 'image/jpeg',
    metadata: {'userId': '123', 'type': 'avatar'},
  ),
);
print('Uploaded: ${file.id}');
```

### List Files with Pagination

```dart
String? cursor;
do {
  final result = await storage.listFiles(
    'my-bucket',
    options: ListFilesOptions(
      prefix: 'images/',
      limit: 50,
      cursor: cursor,
    ),
  );

  for (final file in result.files) {
    print('${file.path}: ${file.size} bytes');
  }

  cursor = result.nextCursor;
} while (cursor != null);
```

### Generate Transform URL

```dart
final thumbnailUrl = storage.getTransformUrl(
  file.id,
  transforms: ImageTransforms(
    width: 200,
    height: 200,
    fit: 'cover',
    format: 'webp',
    quality: 80,
  ),
);
```

### Error Handling

```dart
try {
  final file = await storage.getFile('file-id');
  print('Found: ${file.fileName}');
} on RiviumStorageException catch (e) {
  print('Error: ${e.message}');
  if (e.statusCode != null) {
    print('HTTP Status: ${e.statusCode}');
  }
}
```

## Widget Integration Examples

### Upload Button with Progress

```dart
class UploadButton extends StatefulWidget {
  @override
  State<UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<UploadButton> {
  final storage = RiviumStorage(apiKey: 'rv_live_xxx');
  bool uploading = false;
  StorageFile? uploadedFile;

  Future<void> upload() async {
    setState(() => uploading = true);

    try {
      final file = await storage.upload(
        'my-bucket',
        'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg',
        imageBytes,
        options: UploadOptions(contentType: 'image/jpeg'),
      );
      setState(() => uploadedFile = file);
    } on RiviumStorageException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: uploading ? null : upload,
          child: uploading
              ? CircularProgressIndicator()
              : Text('Upload'),
        ),
        if (uploadedFile != null)
          Text('Uploaded: ${uploadedFile!.fileName}'),
      ],
    );
  }
}
```

### Image with Transforms

```dart
class TransformedImage extends StatelessWidget {
  final String fileId;
  final storage = RiviumStorage(apiKey: 'rv_live_xxx');

  TransformedImage({required this.fileId});

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = storage.getTransformUrl(
      fileId,
      transforms: ImageTransforms(
        width: 200,
        height: 200,
        fit: 'cover',
        format: 'webp',
      ),
    );

    return Image.network(
      thumbnailUrl,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stack) {
        return Icon(Icons.error, size: 50);
      },
    );
  }
}
```

### File List with Delete

```dart
class FileListView extends StatefulWidget {
  final String bucketId;

  FileListView({required this.bucketId});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  final storage = RiviumStorage(apiKey: 'rv_live_xxx');
  List<StorageFile> files = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() => loading = true);
    try {
      final result = await storage.listFiles(widget.bucketId);
      setState(() => files = result.files);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      await storage.delete(fileId);
      setState(() {
        files.removeWhere((f) => f.id == fileId);
      });
    } on RiviumStorageException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return ListTile(
          leading: Icon(Icons.insert_drive_file),
          title: Text(file.fileName),
          subtitle: Text('${file.size} bytes'),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => deleteFile(file.id),
          ),
        );
      },
    );
  }
}
```

### Bucket Selector

```dart
class BucketSelector extends StatefulWidget {
  final Function(Bucket) onSelected;

  BucketSelector({required this.onSelected});

  @override
  State<BucketSelector> createState() => _BucketSelectorState();
}

class _BucketSelectorState extends State<BucketSelector> {
  final storage = RiviumStorage(apiKey: 'rv_live_xxx');
  List<Bucket> buckets = [];
  Bucket? selected;

  @override
  void initState() {
    super.initState();
    loadBuckets();
  }

  Future<void> loadBuckets() async {
    final result = await storage.listBuckets();
    setState(() {
      buckets = result;
      if (result.isNotEmpty) {
        selected = result.first;
        widget.onSelected(selected!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Bucket>(
      value: selected,
      items: buckets.map((bucket) {
        return DropdownMenuItem(
          value: bucket,
          child: Text('${bucket.name} (${bucket.visibility})'),
        );
      }).toList(),
      onChanged: (bucket) {
        if (bucket != null) {
          setState(() => selected = bucket);
          widget.onSelected(bucket);
        }
      },
    );
  }
}
```

## Image Transform Options

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `width` | int? | Target width in pixels | `200` |
| `height` | int? | Target height in pixels | `200` |
| `fit` | String? | Resize mode | `'cover'`, `'contain'`, `'fill'` |
| `format` | String? | Output format | `'webp'`, `'avif'`, `'jpeg'`, `'png'` |
| `quality` | int? | Compression (1-100) | `80` |
| `blur` | int? | Blur amount (0-100) | `10` |
| `sharpen` | int? | Sharpen amount (0-100) | `50` |
| `rotate` | int? | Rotation degrees | `90`, `180`, `270` |

## Requirements

- Flutter 3.0+
- Dart 3.0+

## Supported Platforms

- iOS 11.0+
- Android API 16+
- Web
- macOS 10.13+
- Windows
- Linux

## License

MIT License
