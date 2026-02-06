// lib/screens/setup/asset_download_screen.dart
// First-launch screen for downloading 3D model assets

import 'package:flutter/material.dart';
import '../../services/model_3d_service.dart';

class AssetDownloadScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const AssetDownloadScreen({super.key, required this.onComplete});

  @override
  State<AssetDownloadScreen> createState() => _AssetDownloadScreenState();
}

class _AssetDownloadScreenState extends State<AssetDownloadScreen> {
  final _service = Model3DService.instance;
  final Map<String, bool> _selectedSystems = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadComplete = {};
  bool _isDownloading = false;
  String? _currentlyDownloading;

  @override
  void initState() {
    super.initState();
    // Pre-select systems that have assets
    for (final system in Model3DService.availableSystems) {
      _selectedSystems[system.systemId] = true;
      _downloadProgress[system.systemId] = 0.0;
      _downloadComplete[system.systemId] = false;
    }
    _checkExistingDownloads();
  }

  Future<void> _checkExistingDownloads() async {
    for (final system in Model3DService.availableSystems) {
      final status = await _service.getSystemCacheStatus(system.systemId);
      final allDownloaded = status.values.every((v) => v);
      if (allDownloaded && status.isNotEmpty) {
        setState(() {
          _downloadComplete[system.systemId] = true;
          _downloadProgress[system.systemId] = 1.0;
        });
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() => _isDownloading = true);

    final systemsToDownload = _selectedSystems.entries
        .where((e) => e.value && !(_downloadComplete[e.key] ?? false))
        .map((e) => e.key)
        .toList();

    for (final systemId in systemsToDownload) {
      setState(() => _currentlyDownloading = systemId);

      try {
        await _service.downloadSystem(
          systemId,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _downloadProgress[systemId] = progress);
            }
          },
        );
        if (mounted) {
          setState(() => _downloadComplete[systemId] = true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    setState(() {
      _isDownloading = false;
      _currentlyDownloading = null;
    });

    await Model3DService.markSetupDone();
    widget.onComplete();
  }

  void _skip() async {
    await Model3DService.markSetupDone();
    widget.onComplete();
  }

  int get _selectedCount =>
      _selectedSystems.values.where((v) => v).length;

  int get _totalSelectedSize {
    int total = 0;
    for (final entry in _selectedSystems.entries) {
      if (entry.value) {
        final system = Model3DService.availableSystems
            .firstWhere((s) => s.systemId == entry.key);
        total += system.totalSizeBytes;
      }
    }
    return total;
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final availableSystems = Model3DService.availableSystems;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.download_rounded,
                    size: 64,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Download 3D Models',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select which medical systems to download.\nYou can download more later from settings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // System list
            Expanded(
              child: availableSystems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('No downloads available'),
                          const SizedBox(height: 8),
                          Text(
                            'All content is bundled with the app',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableSystems.length,
                      itemBuilder: (context, index) {
                        final system = availableSystems[index];
                        final isSelected = _selectedSystems[system.systemId] ?? false;
                        final progress = _downloadProgress[system.systemId] ?? 0.0;
                        final isComplete = _downloadComplete[system.systemId] ?? false;
                        final isCurrentlyDownloading =
                            _currentlyDownloading == system.systemId;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: _isDownloading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSystems[system.systemId] = !isSelected;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Checkbox or status icon
                                  if (isComplete)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 28)
                                  else if (isCurrentlyDownloading)
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  else
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: _isDownloading
                                          ? null
                                          : (v) {
                                              setState(() {
                                                _selectedSystems[system.systemId] =
                                                    v ?? false;
                                              });
                                            },
                                    ),
                                  const SizedBox(width: 12),

                                  // System icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(system.colorValue)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      system.icon,
                                      color: Color(system.colorValue),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // System info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          system.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          system.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        if (isCurrentlyDownloading) ...[
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.grey[200],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(progress * 100).toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Size badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      system.formattedSize,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
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

            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_selectedCount > 0 && !_isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '$_selectedCount system(s) selected • ${_formatSize(_totalSelectedSize)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // Skip button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDownloading ? null : _skip,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Skip for Now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Download button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_isDownloading || _selectedCount == 0)
                              ? null
                              : _startDownload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isDownloading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Downloading...'),
                                  ],
                                )
                              : Text('Download ${_selectedCount > 0 ? "($_selectedCount)" : ""}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
