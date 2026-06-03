import 'package:flutter/material.dart';
import 'package:metadata_web/metadata_web.dart';
import 'package:metadata_core/metadata_core.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metadata Web Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        cardColor: const Color(0xFF1E1B29),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<MediaFile> _files = [];
  final Map<String, MetadataResult> _metadataMap = {};
  bool _isScanning = false;
  String _status = 'Ready to scan files';
  double _progress = 0.0;
  MediaFile? _selectedFile;

  Future<void> _handleFolderPick() async {
    try {
      setState(() {
        _isScanning = true;
        _status = 'Picking folder...';
        _progress = 0.0;
        _files.clear();
        _metadataMap.clear();
        _selectedFile = null;
      });

      final pickedFiles = await WebFolderPicker.pickFolder();
      if (pickedFiles.isEmpty) {
        setState(() {
          _isScanning = false;
          _status = 'No folder selected';
        });
        return;
      }

      await _scanFileList(pickedFiles);
    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _scanFileList(List<dynamic> fileList) async {
    final scanner = WebFileScanner();
    await for (final progress in scanner.scanFiles(fileList)) {
      setState(() {
        _status = progress.status;
        _progress = progress.totalFiles > 0
            ? progress.processedFiles / progress.totalFiles
            : 0.0;

        if (progress.currentFile != null) {
          _files.add(progress.currentFile!);
          if (progress.metadata != null) {
            _metadataMap[progress.currentFile!.id] = progress.metadata!;
          }
        }
      });
    }
    setState(() {
      _isScanning = false;
      _status = 'Successfully scanned ${_files.length} files!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0B14),
              Color(0xFF161224),
              Color(0xFF1E1435),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildUploadZone(),
                const SizedBox(height: 24),
                if (_isScanning) _buildProgressBar(),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildFilesList(),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: _buildDetailsPanel(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder_copy_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Klikr Metadata Web',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Web-specific high-performance metadata extraction',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadZone() {
    return DragTarget<Object>(
      onAcceptWithDetails: (details) {
        // Drag and drop scanning
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B29).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.purpleAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.purpleAccent.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                        radius: 1.2,
                        center: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.purpleAccent,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select a folder to extract rich metadata',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isScanning ? null : _handleFolderPick,
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Pick Directory'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepPurpleAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B29),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList() {
    if (_files.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B29).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'No scanned files yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B29).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scanned Media (${_files.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _status,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isSelected = _selectedFile?.id == file.id;
                final metadata = _metadataMap[file.id];

                return Card(
                  elevation: isSelected ? 8 : 0,
                  color: isSelected
                      ? Colors.purpleAccent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.purpleAccent.withValues(alpha: 0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedFile = file;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      key: ValueKey(file.id),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: file.thumbnailPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      file.thumbnailPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    file.mimeType.startsWith('video/')
                                        ? Icons.video_collection_rounded
                                        : Icons.image_rounded,
                                    color: Colors.purpleAccent.withValues(alpha: 0.7),
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  file.relativePath,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(file.size / 1024).toStringAsFixed(1)} KB • ${file.mimeType}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (metadata != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.greenAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Colors.greenAccent,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'EXIF',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white30,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel() {
    final file = _selectedFile!;
    final metadata = _metadataMap[file.id];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B29),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Metadata Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPreviewSection(file),
                const SizedBox(height: 24),
                _buildInfoTile('File Name', file.fileName),
                _buildInfoTile('Relative Path', file.relativePath),
                _buildInfoTile('Mime Type', file.mimeType),
                _buildInfoTile(
                    'File Size', '${(file.size / 1024).toStringAsFixed(1)} KB'),
                _buildInfoTile('Scanned Time', file.createdAt.toString()),
                if (metadata != null) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'EXIF / Media Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (metadata.imageMetadata?.width != null)
                    _buildInfoTile('Dimensions',
                        '${metadata.imageMetadata!.width} x ${metadata.imageMetadata!.height}'),
                  if (metadata.device?.brand != null)
                    _buildInfoTile('Camera Make', metadata.device!.brand!),
                  if (metadata.device?.model != null)
                    _buildInfoTile('Camera Model', metadata.device!.model!),
                  if (metadata.imageMetadata?.exposureTime != null)
                    _buildInfoTile('Exposure Time',
                        metadata.imageMetadata!.exposureTime!.toString()),
                  if (metadata.imageMetadata?.fNumber != null)
                    _buildInfoTile(
                        'F-Number', 'f/${metadata.imageMetadata!.fNumber}'),
                  if (metadata.imageMetadata?.iso != null)
                    _buildInfoTile(
                        'ISO Speed', metadata.imageMetadata!.iso!.toString()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(MediaFile file) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          file.path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                file.mimeType.startsWith('video/')
                    ? Icons.video_library_outlined
                    : Icons.image_outlined,
                size: 64,
                color: Colors.white24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
