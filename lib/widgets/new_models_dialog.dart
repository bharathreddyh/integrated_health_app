// lib/widgets/new_models_dialog.dart
// Dialog shown when new 3D models are available for download from Firebase.

import 'package:flutter/material.dart';
import '../services/model_catalog_service.dart';
import '../services/model_3d_service.dart';

class NewModelsDialog extends StatefulWidget {
  final List<RemoteModelEntry> newModels;

  const NewModelsDialog({super.key, required this.newModels});

  /// Show the dialog and return true if user chose to download.
  static Future<bool> show(BuildContext context, List<RemoteModelEntry> newModels) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewModelsDialog(newModels: newModels),
    );
    return result ?? false;
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
      Navigator.pop(context, true);
    }
  }

  Future<void> _downloadLater() async {
    final catalog = ModelCatalogService.instance;
    await catalog.dismissModels(widget.newModels);
    await catalog.markModelsAsKnown(widget.newModels);
    if (mounted) Navigator.pop(context, false);
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
