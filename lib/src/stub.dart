import 'package:metadata_core/metadata_core.dart';

/// Stub implementation used on non-web platforms.
/// All methods throw [UnsupportedError] at runtime — this package only
/// functions on the web platform.

/// Stub for [WebFileWithMetadata] on non-web platforms.
class WebFileWithMetadata {
  /// The underlying file object (web.File on web).
  final dynamic file;

  /// The full file path of the item.
  final String fullPath;

  /// Creates a [WebFileWithMetadata] stub.
  WebFileWithMetadata(this.file, this.fullPath);
}

/// Stub for [WebFileScanner] on non-web platforms.
class WebFileScanner implements IFileScanner {
  @override
  Stream<ScanProgress> scan(String path, {bool recursive = true}) =>
      throw UnsupportedError('WebFileScanner requires a web platform');

  @override
  Stream<ScanProgress> scanFiles(List<dynamic> files) =>
      throw UnsupportedError('WebFileScanner requires a web platform');
}

/// Stub for [IndexedDBCache] on non-web platforms.
class IndexedDBCache implements IStorageProvider {
  @override
  Future<void> saveMetadata(MetadataResult result) =>
      throw UnsupportedError('IndexedDBCache requires a web platform');

  @override
  Future<MetadataResult?> getMetadata(String fileId) =>
      throw UnsupportedError('IndexedDBCache requires a web platform');

  @override
  Future<List<MetadataResult>> getAllMetadata() =>
      throw UnsupportedError('IndexedDBCache requires a web platform');
}

/// Stub for [WebFolderPicker] on non-web platforms.
class WebFolderPicker {
  /// Throws [UnsupportedError] on non-web platforms.
  static Future<List<dynamic>> pickFolder() =>
      throw UnsupportedError('WebFolderPicker requires a web platform');
}

/// Stub for [WebDropTraverser] on non-web platforms.
class WebDropTraverser {
  /// Throws [UnsupportedError] on non-web platforms.
  static Future<List<WebFileWithMetadata>> traverseDrop(dynamic event) =>
      throw UnsupportedError('WebDropTraverser requires a web platform');
}
