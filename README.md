# metadata_web

A powerful web-specific metadata extraction implementation for Flutter, seamlessly integrating with web browsers to extract EXIF and media data. It utilizes native Web APIs to traverse directories and parse media files directly in the browser.

## Features

- **Image EXIF Extraction**: Extract EXIF data and dimensions from images efficiently on the browser before uploading.
- **Video Thumbnail Extraction**: Automatically capture a thumbnail frame from video files using the browser's Canvas API.
- **Folder Picker**: Open the browser's native directory picker and retrieve all files inside.
- **Folder Drag-and-Drop Traversal**: Recursively read folders dropped into the browser using native JavaScript interop (`DataTransferItem`).
- **Web File Scanning**: Scan `web.File` instances or drop-traversal results in a single unified stream.
- **Standardized Models**: Built on top of `metadata_core` for consistent typed interfaces across platforms.

## Getting started

Add `metadata_web` to your `pubspec.yaml`:

```yaml
dependencies:
  metadata_web: ^0.0.4
```

## Usage

### 1. Import the package

```dart
import 'package:metadata_web/metadata_web.dart';
import 'package:metadata_core/metadata_core.dart';
import 'package:web/web.dart' as web; // for drop events
```

### 2. Scan files for metadata

Pass a list of `web.File` objects (e.g., from a file input) to `WebFileScanner`. It emits a progress stream that includes the extracted metadata and an auto-generated thumbnail URL for both images and videos:

```dart
final scanner = WebFileScanner();

scanner.scanFiles(files).listen((progress) {
  print('${progress.processedFiles}/${progress.totalFiles}: ${progress.status}');

  final file = progress.currentFile;
  if (file != null) {
    print('Name: ${file.fileName}');
    print('MIME: ${file.mimeType}');
    print('Thumbnail URL: ${file.thumbnailPath}'); // works for images and videos

    final meta = progress.metadata;
    if (meta != null) {
      print('Dimensions: ${meta.imageMetadata?.width}x${meta.imageMetadata?.height}');
    }
  }
});
```

### 3. Pick a folder via browser dialog

`WebFolderPicker` opens the browser's native directory picker and returns a flat list of all files inside:

```dart
final files = await WebFolderPicker.pickFolder();
if (files.isNotEmpty) {
  final scanner = WebFileScanner();
  scanner.scanFiles(files).listen((progress) {
    // handle progress
  });
}
```

### 4. Folder drag-and-drop traversal

`WebDropTraverser` recursively walks a drag-and-drop event's file system entries, preserving relative paths:

```dart
// Inside a DragEvent handler
final filesWithMetadata = await WebDropTraverser.traverseDrop(event);

final scanner = WebFileScanner();
scanner.scanFiles(filesWithMetadata).listen((progress) {
  final file = progress.currentFile;
  if (file != null) {
    print('Relative path: ${file.relativePath}');
  }
});
```

## Example

A full interactive example app is included in the [`example/`](example/) directory. It demonstrates folder picking, drag-and-drop scanning, live progress, image/video thumbnail previews, and EXIF detail inspection — all in a dark-themed Flutter Web UI.

## Additional information

Please refer to the [issue tracker](https://github.com/Dinesh-DLanzer/metadata_web/issues) for reporting bugs or requesting features.
