# metadata_web

A powerful web-specific metadata extraction implementation for Flutter, seamlessly integrating with web browsers to extract EXIF and media data. It utilizes native Web APIs to traverse directories and parse media files directly in the browser.

## Features

- **Folder Drag-and-Drop Traversal**: Utilize native JavaScript interop (`DataTransferItem`) to recursively read folders dropped into the browser.
- **Web File Scanning**: Read files directly from `web.File` instances or standard lists.
- **EXIF Extraction on Web**: Extract EXIF data from images efficiently on the browser before uploading.
- **Standardized Models**: Built on top of `metadata_core` for consistent typed interfaces.

## Getting started

Add `metadata_web` to your `pubspec.yaml`:

```yaml
dependencies:
  metadata_web: ^0.0.1
```

## Usage

### 1. Import the package

```dart
import 'package:metadata_web/metadata_web.dart';
import 'package:metadata_core/metadata_core.dart';
import 'package:web/web.dart' as web; // If using web native types
```

### 2. Scanning Web Files for Metadata

You can pass a list of web files (e.g., obtained from an `<input type="file">`) to `WebFileScanner` to automatically extract their metadata and EXIF information:

```dart
final webScanner = WebFileScanner();

// Example: `files` is a List of web.File objects from a file picker
webScanner.scanFiles(files).listen((progress) {
  print('Processing: ${progress.processedFiles}/${progress.totalFiles}');
  
  if (progress.currentFile != null) {
    print('Found file: ${progress.currentFile!.fileName}');
    print('MIME type: ${progress.currentFile!.mimeType}');
    
    // Metadata is extracted automatically during scanning
    final metadata = progress.metadata;
    if (metadata != null) {
      print('Dimensions: ${metadata.imageMetadata?.width}x${metadata.imageMetadata?.height}');
    }
  }
});
```

### 3. Folder Drag-and-Drop Traversal

If you want to handle dropping a folder into your web app and recursively fetching all files:

```dart
// Inside a drop event handler where `event` is a `web.DragEvent`
final filesWithMetadata = await WebDropTraverser.traverseDrop(event);

for (var webFile in filesWithMetadata) {
  print('File Path: ${webFile.fullPath}');
  // You can then pass these files to WebFileScanner to extract metadata!
}
```

## Additional information

Please refer to the issue tracker for reporting bugs or requesting features.
