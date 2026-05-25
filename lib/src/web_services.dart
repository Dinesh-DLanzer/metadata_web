import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:metadata_core/metadata_core.dart';
import 'package:flutter/foundation.dart';

// Native extension to support deep folder traversal
extension DataTransferItemExtension on web.DataTransferItem {
  @JS('webkitGetAsEntry')
  external JSObject? webkitGetAsEntry();
}

extension FileSystemEntryExtension on JSObject {
  @JS('isFile')
  external bool get isFile;

  @JS('isDirectory')
  external bool get isDirectory;

  @JS('fullPath')
  external String get fullPath;

  @JS('createReader')
  external JSObject createReader();

  @JS('file')
  external void file(JSFunction success, JSFunction error);
}

extension DirectoryReaderExtension on JSObject {
  @JS('readEntries')
  external void readEntries(JSFunction success, JSFunction error);
}

// Wrapper to safely pass file + metadata without modifying native JS objects
class WebFileWithMetadata {
  final web.File file;
  final String fullPath;
  WebFileWithMetadata(this.file, this.fullPath);
}

class WebFileScanner implements IFileScanner {
  @override
  Stream<ScanProgress> scan(String path, {bool recursive = true}) async* {
    yield ScanProgress(totalFiles: 0, processedFiles: 0, status: 'Direct path scanning not supported on Web');
  }

  @override
  Stream<ScanProgress> scanFiles(List<dynamic> files) async* {
    int total = files.length;
    int processed = 0;

    for (var item in files) {
      processed++;
      
      final dynamic file = item is WebFileWithMetadata ? item.file : item;
      final String? customPath = item is WebFileWithMetadata ? item.fullPath : null;

      final String name = _getProperty(file, 'name') ?? 'unknown';
      final int size = _getProperty(file, 'size') ?? 0;
      
      // Use customPath if available, otherwise fallback to webkitRelativePath
      String relativePath = customPath ?? _getProperty(file, 'webkitRelativePath') ?? name;
      
      // Strip leading slash from fullPath if present
      if (relativePath.startsWith('/')) {
        relativePath = relativePath.substring(1);
      }

      MetadataResult? metadata;
      String? thumbnailPath;
      final bool isImage = file.type.startsWith('image/') || _isImageExtension(name);
      final bool isVideo = _getProperty(file, 'type')?.startsWith('video/') ?? false;
      
      if (file is web.File && isImage) {
        try {
          final arrayBuffer = await file.arrayBuffer().toDart;
          final bytes = arrayBuffer.toDart.asUint8List();
          metadata = await ExifMetadataExtractor.extractFromBytes(processed.toString(), bytes);
          
          final thumbBytes = await ExifMetadataExtractor.extractThumbnailBytes(bytes);
          if (thumbBytes != null && thumbBytes.isNotEmpty) {
            try {
              final uint8List = Uint8List.fromList(thumbBytes);
              final blob = web.Blob([uint8List.toJS].toJS);
              thumbnailPath = web.URL.createObjectURL(blob);
            } catch (_) {}
          }
          
          // Fallback dimensions logic
          if (metadata.imageMetadata?.width == null) {
            final completer = Completer<web.HTMLImageElement>();
            final img = web.document.createElement('img') as web.HTMLImageElement;
            final blob = web.Blob([file].toJS);
            final url = web.URL.createObjectURL(blob);
            img.src = url;
            img.onload = (web.Event e) {
              completer.complete(img);
              web.URL.revokeObjectURL(url);
            }.toJS;
            img.onerror = (JSAny e, JSAny f) {
              completer.completeError('Failed to load image for dimensions');
            }.toJS;
            
            try {
              final loadedImg = await completer.future.timeout(const Duration(milliseconds: 500));
              metadata = metadata.copyWith(
                imageMetadata: (metadata.imageMetadata ?? const ImageMetadata()).copyWith(
                  width: loadedImg.naturalWidth,
                  height: loadedImg.naturalHeight,
                ),
              );
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('WebFileScanner: Error extracting metadata for $name: $e');
        }
      }

      if (file is web.File && isVideo) {
        try {
          final completer = Completer<String?>();
          final video = web.document.createElement('video') as web.HTMLVideoElement;
          video.muted = true;
          video.preload = 'metadata';
          video.playsInline = true;
          final blob = web.Blob([file].toJS);
          final url = web.URL.createObjectURL(blob);
          video.src = url;

          video.onloadeddata = (web.Event e) {
            if (video.duration > 1.0) {
              video.currentTime = 1.0;
            } else {
              video.currentTime = 0.0;
            }
          }.toJS;

          video.onseeked = (web.Event e) {
            try {
              final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
              canvas.width = video.videoWidth;
              canvas.height = video.videoHeight;
              final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
              if (ctx != null) {
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                completer.complete(canvas.toDataURL('image/jpeg', 0.7.toJS));
              } else {
                completer.complete(null);
              }
            } catch (_) {
              completer.complete(null);
            } finally {
              web.URL.revokeObjectURL(url);
            }
          }.toJS;

          video.onerror = (JSAny e, JSAny f) {
            completer.complete(null);
            web.URL.revokeObjectURL(url);
          }.toJS;

          thumbnailPath = await completer.future.timeout(const Duration(seconds: 2), onTimeout: () {
            web.URL.revokeObjectURL(url);
            return null;
          });
        } catch (_) {}
      }

      String objectUrl = '';
      if (file is web.File) {
        try {
          final blob = web.Blob([file].toJS);
          objectUrl = web.URL.createObjectURL(blob);
        } catch (_) {}
      }

      final mediaFile = MediaFile(
        id: processed.toString(),
        fileName: name,
        path: objectUrl,
        thumbnailPath: thumbnailPath,
        relativePath: relativePath,
        size: size,
        mimeType: _getProperty(file, 'type') ?? 'image/jpeg',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );

      yield ScanProgress(
        totalFiles: total,
        processedFiles: processed,
        currentFile: mediaFile,
        metadata: metadata,
        status: 'Processing: ${mediaFile.fileName}',
      );
    }
    yield ScanProgress(totalFiles: total, processedFiles: processed, status: 'Complete');
  }

  dynamic _getProperty(dynamic obj, String prop) {
    try {
      if (obj is web.File) {
        if (prop == 'name') return obj.name;
        if (prop == 'size') return obj.size;
        if (prop == 'type') return obj.type;
        if (prop == 'webkitRelativePath') return obj.webkitRelativePath;
      }
      
      final dynamic dObj = obj;
      if (prop == 'name') return dObj.name;
      if (prop == 'size') return dObj.size;
      if (prop == 'type') return dObj.mimeType ?? dObj.type;
      if (prop == 'path') return dObj.path;
      
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isImageExtension(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') || 
           lower.endsWith('.jpeg') || 
           lower.endsWith('.png') || 
           lower.endsWith('.webp') || 
           lower.endsWith('.heic') || 
           lower.endsWith('.heif');
  }
}

class IndexedDBCache implements IStorageProvider {
  @override
  Future<List<MetadataResult>> getAllMetadata() async {
    return [];
  }

  @override
  Future<MetadataResult?> getMetadata(String fileId) async {
    return null;
  }

  @override
  Future<void> saveMetadata(MetadataResult result) async {
  }
}

class WebFolderPicker {
  static Future<List<dynamic>> pickFolder() async {
    final completer = Completer<List<dynamic>>();
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.setAttribute('webkitdirectory', '');
    input.setAttribute('directory', '');
    input.multiple = true;

    input.onchange = (web.Event e) {
      final files = input.files;
      if (files != null) {
        final List<dynamic> result = [];
        for (int i = 0; i < files.length; i++) {
          result.add(files.item(i));
        }
        completer.complete(result);
      } else {
        completer.complete([]);
      }
    }.toJS;

    input.click();
    return completer.future;
  }
}

class WebDropTraverser {
  static Future<List<WebFileWithMetadata>> traverseDrop(web.DragEvent event) async {
    final items = event.dataTransfer?.items;
    if (items == null) return [];

    final List<WebFileWithMetadata> files = [];
    final List<Future> futures = [];

    for (int i = 0; i < items.length; i++) {
      final item = (items as dynamic)[i];
      if (item is web.DataTransferItem) {
        final entry = item.webkitGetAsEntry();
        if (entry != null) {
          futures.add(_traverseEntry(entry, files));
        }
      }
    }

    await Future.wait(futures);
    return files;
  }

  static Future<void> _traverseEntry(JSObject entry, List<WebFileWithMetadata> files) async {
    if (entry.isFile) {
      final web.File file = await _getFileFromEntry(entry);
      // Store file and its full path in the wrapper
      files.add(WebFileWithMetadata(file, entry.fullPath));
    } else if (entry.isDirectory) {
      final reader = entry.createReader();
      final List<dynamic> entries = await _readEntries(reader);
      for (final child in entries) {
        await _traverseEntry(child as JSObject, files);
      }
    }
  }

  static Future<web.File> _getFileFromEntry(JSObject entry) {
    final completer = Completer<web.File>();
    entry.file((web.File file) {
      completer.complete(file);
    }.toJS, (JSAny? err) {
      completer.completeError(err ?? 'Unknown error');
    }.toJS);
    return completer.future;
  }

  static Future<List<dynamic>> _readEntries(JSObject reader) {
    final completer = Completer<List<dynamic>>();
    (reader as dynamic).readEntries((JSArray entries) {
      completer.complete(entries.toDart);
    }.toJS, (JSAny? err) {
      completer.completeError(err ?? 'Unknown error');
    }.toJS);
    return completer.future;
  }
}
