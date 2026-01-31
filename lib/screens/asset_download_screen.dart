// lib/screens/asset_download_screen.dart
// Shows downloadable 3D assets grouped by medical system.
// Users can select which systems to download, see sizes, and track progress.

import 'package:flutter/material.dart';
import '../services/model_3d_service.dart';

class AssetDownloadScreen extends StatefulWidget {
  /// If true, shows as first-launch setup with a Skip button.
  /// If false, shows as a settings page with a back button.
  final bool isFirstLaunch;

  const AssetDownloadScreen({super.key, this.isFirstLaunch = false});

  @override
  State<AssetDownloadScreen> createState() => _AssetDownloadScreenState();
}

class _AssetDownloadScreenState extends State<AssetDownloadScreen> {
  final _service = Model3DService.instance;

  // Track selected systems for download
  final Set<String> _selected = {};

  // Download state per system
  final Map<String, _DownloadState> _downloadStates = {};
  final Map<String, double> _progress = {};
  final Map<String, String> _errors = {};

  // Cache status
  final Map<String, bool> _cached = {};
  bool _loadingCache = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStatus();
  }

  Future<void> _loadCacheStatus() async {
    for (final system in Model3DService.systemAssets) {
      if (system.assets.isEmpty) continue;
      final status = await _service.getSystemCacheStatus(system.systemId);
      final allCached = status.values.isNotEmpty && status.values.every((v) => v);
      _cached[system.systemId] = allCached;
    }
    if (mounted) setState(() => _loadingCache = false);
  }

  int get _selectedTotalBytes {
    int total = 0;
    for (final id in _selected) {
      final system = Model3DService.systemAssets.firstWhere(
        (s) => s.systemId == id,
      );
      total += system.totalSizeBytes;
    }
    return total;
  }

  String get _selectedFormattedSize {
    final mb = _selectedTotalBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = _selectedTotalBytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _downloadSelected() async {
    if (_selected.isEmpty) return;

    setState(() => _isDownloading = true);

    for (final systemId in _selected.toList()) {
      if (_cached[systemId] == true) continue;

      setState(() {
        _downloadStates[systemId] = _DownloadState.downloading;
        _progress[systemId] = 0.0;
        _errors.remove(systemId);
      });

      try {
        await _service.downloadSystem(
          systemId,
          onProgress: (p) {
            if (mounted) setState(() => _progress[systemId] = p);
          },
        );
        if (mounted) {
          setState(() {
            _downloadStates[systemId] = _DownloadState.done;
            _cached[systemId] = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _downloadStates[systemId] = _DownloadState.error;
            _errors[systemId] = e.toString();
          });
        }
      }
    }

    setState(() => _isDownloading = false);
  }

  Future<void> _deleteSystem(String systemId) async {
    await _service.clearSystemCache(systemId);
    setState(() {
      _cached[systemId] = false;
      _downloadStates.remove(systemId);
      _progress.remove(systemId);
    });
  }

  void _finish() async {
    await Model3DService.markSetupDone();
    if (mounted) {
      if (widget.isFirstLaunch) {
        Navigator.of(context).pushReplacementNamed('/doctor-home');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = Model3DService.systemAssets;
    final hasAvailable = available.any((s) => s.assets.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.isFirstLaunch ? 'Download 3D Assets' : 'Manage Downloads'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        leading: widget.isFirstLaunch
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (widget.isFirstLaunch)
            TextButton(
              onPressed: _isDownloading ? null : _finish,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isFirstLaunch
                      ? 'Choose which medical systems to download.\nYou can change this later in Settings.'
                      : 'Download or remove 3D model assets per system.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '${_selected.length} selected  ·  $_selectedFormattedSize',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // System list
          Expanded(
            child: _loadingCache
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: available.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildSystemCard(available[index]);
                    },
                  ),
          ),

          // Bottom action bar
          if (hasAvailable)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading || _selected.isEmpty
                          ? null
                          : _downloadSelected,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isDownloading
                            ? 'Downloading...'
                            : _selected.isEmpty
                                ? 'Select systems to download'
                                : 'Download Selected ($_selectedFormattedSize)',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isFirstLaunch || _isDownloading) ...[
                    // nothing extra
                  ] else ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(SystemAssetGroup system) {
    final hasAssets = system.assets.isNotEmpty;
    final isCached = _cached[system.systemId] == true;
    final state = _downloadStates[system.systemId];
    final progress = _progress[system.systemId] ?? 0.0;
    final error = _errors[system.systemId];
    final isSelected = _selected.contains(system.systemId);
    final color = Color(system.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.5) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: hasAssets && !isCached && !_isDownloading
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(system.systemId);
                      } else {
                        _selected.add(system.systemId);
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // System icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      IconData(system.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          system.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          system.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Size + status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasAssets)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCached
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            system.formattedSize,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCached
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Coming soon',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      if (isCached)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Downloaded',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else if (hasAssets && !_isDownloading)
                        Checkbox(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(system.systemId);
                              } else {
                                _selected.remove(system.systemId);
                              }
                            });
                          },
                          activeColor: color,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Progress bar during download
          if (state == _DownloadState.downloading) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],

          // Error message with retry
          if (state == _DownloadState.error && error != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download failed',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        _downloadStates[system.systemId] = _DownloadState.downloading;
                        _progress[system.systemId] = 0.0;
                        _errors.remove(system.systemId);
                      });
                      try {
                        await _service.downloadSystem(
                          system.systemId,
                          onProgress: (p) {
                            if (mounted) {
                              setState(() => _progress[system.systemId] = p);
                            }
                          },
                        );
                        if (mounted) {
                          setState(() {
                            _downloadStates[system.systemId] = _DownloadState.done;
                            _cached[system.systemId] = true;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _downloadStates[system.systemId] = _DownloadState.error;
                            _errors[system.systemId] = e.toString();
                          });
                        }
                      }
                    },
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          // Delete button for cached systems
          if (isCached && !widget.isFirstLaunch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _deleteSystem(system.systemId),
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                  label: Text(
                    'Remove',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                  ),
                ),
              ),
            ),

          // Asset list for systems with content
          if (hasAssets && (isSelected || isCached || state != null))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: system.assets.map((asset) {
                  final assetMb = asset.sizeBytes / (1024 * 1024);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.view_in_ar, size: 14, color: color),
                        const SizedBox(width: 8),
                        Text(
                          asset.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          '${assetMb.toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

enum _DownloadState { downloading, done, error }
