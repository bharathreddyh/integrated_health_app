import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/canvas_system_config.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  Map<String, List<File>> _imagesBySystem = {};
  List<String> _systemIds = [];
  bool _loading = true;
  TabController? _tabController;

  static const _systemColors = <String, Color>{
    'thyroid': Color(0xFFF59E0B),
    'kidney': Color(0xFF3B82F6),
    'cardiac': Color(0xFFEF4444),
    'pulmonary': Color(0xFF10B981),
    'neuro': Color(0xFF8B5CF6),
    'hepatic': Color(0xFFF97316),
    'gynaecology': Color(0xFFEC4899),
    'obstetrics': Color(0xFFA855F7),
  };

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedImages() async {
    final appDir = await getApplicationSupportDirectory();
    final annotationsDir = Directory('${appDir.path}/models_cache/annotations');

    Map<String, List<File>> grouped = {};

    // Also check old flat directory for backward compat
    final oldDir = Directory('${appDir.path}/models_cache');
    if (await oldDir.exists()) {
      final oldFiles = oldDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      if (oldFiles.isNotEmpty) {
        grouped['general'] = oldFiles;
      }
    }

    // Load system subdirectories
    if (await annotationsDir.exists()) {
      for (final entity in annotationsDir.listSync()) {
        if (entity is Directory) {
          final systemId = entity.path.split('/').last;
          final files = entity
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.png'))
              .toList()
            ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
          if (files.isNotEmpty) {
            grouped[systemId] = files;
          }
        }
      }
    }

    // Build ordered system list: known systems first (in config order), then unknown
    final knownOrder = CanvasSystemConfig.systems.keys.toList();
    final systemIds = <String>[];
    for (final id in knownOrder) {
      if (grouped.containsKey(id)) systemIds.add(id);
    }
    for (final id in grouped.keys) {
      if (!systemIds.contains(id)) systemIds.add(id);
    }

    if (mounted) {
      _tabController?.dispose();
      _tabController = systemIds.isNotEmpty
          ? TabController(length: systemIds.length, vsync: this)
          : null;
      setState(() {
        _imagesBySystem = grouped;
        _systemIds = systemIds;
        _loading = false;
      });
    }
  }

  String _systemDisplayName(String id) {
    final config = CanvasSystemConfig.systems[id];
    if (config != null) return '${config.icon} ${config.name}';
    if (id == 'general') return '📁 General';
    return id[0].toUpperCase() + id.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.blue,
                indicatorWeight: 3,
                tabs: _systemIds.map((id) {
                  final count = _imagesBySystem[id]?.length ?? 0;
                  return Tab(text: '${_systemDisplayName(id)} ($count)');
                }).toList(),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: Colors.grey.shade200),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _systemIds.isEmpty
              ? _buildEmptyState()
              : TabBarView(
                  controller: _tabController,
                  children: _systemIds.map((id) {
                    return _buildSystemImages(id, _imagesBySystem[id] ?? []);
                  }).toList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No saved annotations yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Draw on 3D models and save to see them here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemImages(String systemId, List<File> images) {
    if (images.isEmpty) {
      return Center(
        child: Text('No images for this system', style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${images.length} saved annotation${images.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                'Tap to view  |  Long press to delete',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final file = images[index];
                final modified = file.lastModifiedSync();
                final dateStr =
                    '${modified.day}/${modified.month}/${modified.year} ${modified.hour}:${modified.minute.toString().padLeft(2, '0')}';
                final rawName = file.path.split('/').last.replaceAll('.png', '');
                final displayName = rawName
                    .replaceAll(RegExp(r'_\d{13}$'), '')
                    .replaceAll('_', ' ')
                    .replaceAll('3d annotation', 'Annotation')
                    .trim();
                final label = displayName.isEmpty ? 'Annotation' : displayName;
                final color = _systemColors[systemId] ?? Colors.blueGrey;

                return GestureDetector(
                  onTap: () => _showFullImage(file, label),
                  onLongPress: () => _confirmDelete(file, systemId),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: const Color(0xFF1E293B),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
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

  void _showFullImage(File file, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 1),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(File file, String systemId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await file.delete();
              _loadSavedImages(); // reload
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image deleted'), backgroundColor: Colors.orange),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
