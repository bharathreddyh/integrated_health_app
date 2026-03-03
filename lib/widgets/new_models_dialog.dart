// lib/widgets/new_models_dialog.dart
// Dialog shown when new 3D models are available for download from Firebase.
// Offers: Download Now (with progress), Download in Background, or Later.

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/model_catalog_service.dart';
import '../services/model_3d_service.dart';

/// Manages background model downloads as a singleton.
/// Emits progress so any screen can show a subtle indicator.
class BackgroundDownloadManager {
  static final BackgroundDownloadManager instance = BackgroundDownloadManager._();
  BackgroundDownloadManager._();

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  final _progressController = StreamController<BackgroundDownloadProgress>.broadcast();
  Stream<BackgroundDownloadProgress> get progressStream => _progressController.stream;

  Future<void> downloadModels(List<RemoteModelEntry> models) async {
    if (_isDownloading) return;
    _isDownloading = true;

    final service = Model3DService.instance;

    for (int i = 0; i < models.length; i++) {
      final model = models[i];
      _progressController.add(BackgroundDownloadProgress(
        modelName: model.name,
        currentIndex: i,
        totalCount: models.length,
        fileProgress: 0.0,
      ));

      try {
        await service.downloadAsset(
          model.toAssetInfo(),
          onProgress: (p) {
            _progressController.add(BackgroundDownloadProgress(
              modelName: model.name,
              currentIndex: i,
              totalCount: models.length,
              fileProgress: p,
            ));
          },
        );
      } catch (e) {
        print('Background download failed for ${model.name}: $e');
      }
    }

    await ModelCatalogService.instance.markModelsAsKnown(models);
    _isDownloading = false;

    _progressController.add(BackgroundDownloadProgress(
      modelName: '',
      currentIndex: models.length,
      totalCount: models.length,
      fileProgress: 1.0,
      isComplete: true,
    ));
  }

  void dispose() {
    _progressController.close();
  }
}

class BackgroundDownloadProgress {
  final String modelName;
  final int currentIndex;
  final int totalCount;
  final double fileProgress;
  final bool isComplete;

  BackgroundDownloadProgress({
    required this.modelName,
    required this.currentIndex,
    required this.totalCount,
    required this.fileProgress,
    this.isComplete = false,
  });

  double get overallProgress =>
      totalCount == 0 ? 0 : (currentIndex + fileProgress) / totalCount;
}

class NewModelsDialog extends StatefulWidget {
  final List<RemoteModelEntry> newModels;

  const NewModelsDialog({super.key, required this.newModels});

  /// Show the dialog. Returns:
  /// - 'downloaded' if user waited for full download
  /// - 'background' if user chose background download
  /// - 'later' / null if dismissed
  static Future<String?> show(BuildContext context, List<RemoteModelEntry> newModels) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewModelsDialog(newModels: newModels),
    );
  }

  @override
  State<NewModelsDialog> createState() => _NewModelsDialogState();
}

class _NewModelsDialogState extends State<NewModelsDialog> {
  bool _isDownloading = false;
  int _downloadedCount = 0;
  double _currentProgress = 0.0;
  String _currentModelName = '';

  String get _totalSize {
    final bytes = widget.newModels.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _downloadAll() async {
    setState(() {
      _isDownloading = true;
      _downloadedCount = 0;
    });

    final service = Model3DService.instance;
    final catalog = ModelCatalogService.instance;

    for (int i = 0; i < widget.newModels.length; i++) {
      final model = widget.newModels[i];
      setState(() {
        _currentModelName = model.name;
        _currentProgress = 0.0;
      });

      try {
        await service.downloadAsset(
          model.toAssetInfo(),
          onProgress: (p) {
            setState(() => _currentProgress = p);
          },
        );
      } catch (e) {
        print('Failed to download ${model.name}: $e');
      }

      setState(() => _downloadedCount = i + 1);
    }

    await catalog.markModelsAsKnown(widget.newModels);

    if (mounted) {
      Navigator.pop(context, 'downloaded');
    }
  }

  void _downloadInBackground() {
    final catalog = ModelCatalogService.instance;
    catalog.markModelsAsKnown(widget.newModels);
    BackgroundDownloadManager.instance.downloadModels(widget.newModels);
    Navigator.pop(context, 'background');
  }

  Future<void> _downloadLater() async {
    final catalog = ModelCatalogService.instance;
    await catalog.dismissModels(widget.newModels);
    await catalog.markModelsAsKnown(widget.newModels);
    if (mounted) Navigator.pop(context, 'later');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: _isDownloading ? _buildDownloadProgress() : _buildPrompt(),
      ),
    );
  }

  Widget _buildPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.view_in_ar, color: Color(0xFF8B5CF6), size: 32),
        ),
        const SizedBox(height: 20),

        // Title
        Text(
          widget.newModels.length == 1
              ? 'New 3D Model Available'
              : '${widget.newModels.length} New 3D Models Available',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Model list
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.newModels.length,
            itemBuilder: (context, index) {
              final model = widget.newModels[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${model.subcategory} - ${model.categoryId.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      model.formattedSize,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Total size
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(
                'Total: $_totalSize',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Download Now button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadAll,
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text(
              'Download Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Download in Background button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _downloadInBackground,
            icon: const Icon(Icons.downloading_rounded, size: 18),
            label: const Text(
              'Download in Background',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6), width: 1),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Later button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _downloadLater,
            child: Text(
              'Later',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    final overallProgress = widget.newModels.isEmpty
        ? 0.0
        : (_downloadedCount + _currentProgress) / widget.newModels.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.downloading_rounded, color: Color(0xFF8B5CF6), size: 48),
        const SizedBox(height: 20),
        const Text(
          'Downloading Models...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentModelName,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Overall progress
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: overallProgress,
            minHeight: 8,
            backgroundColor: const Color(0xFF334155),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$_downloadedCount / ${widget.newModels.length} models',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ],
    );
  }
}

/// A persistent bottom banner that shows background download progress.
/// Add this as a widget in your screen's stack/column.
class BackgroundDownloadBanner extends StatefulWidget {
  const BackgroundDownloadBanner({super.key});

  @override
  State<BackgroundDownloadBanner> createState() => _BackgroundDownloadBannerState();
}

class _BackgroundDownloadBannerState extends State<BackgroundDownloadBanner>
    with SingleTickerProviderStateMixin {
  StreamSubscription<BackgroundDownloadProgress>? _subscription;
  BackgroundDownloadProgress? _progress;
  bool _visible = false;
  bool _completedRecently = false;

  @override
  void initState() {
    super.initState();
    _visible = BackgroundDownloadManager.instance.isDownloading;
    _subscription = BackgroundDownloadManager.instance.progressStream.listen((p) {
      if (!mounted) return;
      setState(() {
        _progress = p;
        if (p.isComplete) {
          _completedRecently = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() { _visible = false; _completedRecently = false; });
          });
        } else {
          _visible = true;
          _completedRecently = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final p = _progress;
    if (p == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _completedRecently ? const Color(0xFF064E3B) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _completedRecently ? const Color(0xFF10B981) : const Color(0xFF334155),
        ),
      ),
      child: _completedRecently ? _buildCompleted(p) : _buildProgress(p),
    );
  }

  Widget _buildProgress(BackgroundDownloadProgress p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading: ${p.modelName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${p.currentIndex}/${p.totalCount}',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p.overallProgress,
            minHeight: 4,
            backgroundColor: const Color(0xFF334155),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(BackgroundDownloadProgress p) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
        const SizedBox(width: 12),
        Text(
          '${p.totalCount} model${p.totalCount == 1 ? '' : 's'} downloaded',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
