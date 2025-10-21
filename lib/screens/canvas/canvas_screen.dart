import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/visit.dart';
import '../../models/condition_tool.dart';
import '../../models/drawing_path.dart';
import '../../services/voice_command_service.dart';
import '../../services/database_helper.dart';
import '../../services/multi_image_pdf_service.dart';
import '../../widgets/voice_feedback_overlay.dart';
import '../../widgets/image_selection_dialog.dart';
import '../patient/visit_history_screen.dart';
import 'widgets/kidney_canvas.dart';
import 'widgets/tool_panel.dart';
import 'widgets/drawing_tool_panel.dart';
import '../../services/user_service.dart';
import '../../config/canvas_system_config.dart';

class CanvasScreen extends StatefulWidget {
  final Patient patient;
  final Visit? existingVisit;
  final String? preSelectedSystem;
  final String? preSelectedDiagramType;

  const CanvasScreen({
    super.key,
    required this.patient,
    this.existingVisit,
    this.preSelectedSystem,
    this.preSelectedDiagramType,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  String selectedSystem = 'kidney';
  String selectedPreset = 'anatomical';
  String selectedTool = 'pan';
  List<Marker> markers = [];
  List<DrawingPath> drawingPaths = [];
  int? selectedMarkerIndex;
  int? selectedPathIndex;
  double zoom = 1.0;
  Offset pan = Offset.zero;

  late Patient patient;
  final GlobalKey _canvasKey = GlobalKey();

  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _isVoiceInitialized = false;
  bool _waitingForClick = false;
  String? _pendingToolType;
  double? _pendingToolSize;
  String _voiceStatus = '';

  int? _currentVisitId;
  bool _isEditingMode = false;

  String _selectedDrawingTool = 'none';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _showDrawingPanel = false;

  @override
  void initState() {
    super.initState();

    patient = widget.patient;

    // PRIORITY-BASED INITIALIZATION
    if (widget.existingVisit != null) {
      _loadExistingVisit();
    } else if (widget.preSelectedSystem != null) {
      selectedSystem = widget.preSelectedSystem!;

      if (!CanvasSystemConfig.systems.containsKey(selectedSystem)) {
        selectedSystem = 'kidney';
      }

      if (widget.preSelectedDiagramType != null) {
        final systemConfig = CanvasSystemConfig.systems[selectedSystem];
        final allDiagrams = systemConfig?.allDiagrams ?? {};

        if (allDiagrams.containsKey(widget.preSelectedDiagramType)) {
          selectedPreset = widget.preSelectedDiagramType!;
        } else {
          selectedPreset = systemConfig?.anatomyDiagrams.keys.first ?? 'anatomical';
        }
      } else {
        final systemConfig = CanvasSystemConfig.systems[selectedSystem];
        selectedPreset = systemConfig?.anatomyDiagrams.keys.first ?? 'anatomical';
      }
    } else {
      selectedSystem = 'kidney';
      selectedPreset = 'anatomical';
      _loadAnnotations();
    }

    _initializeVoice();
  }

  void _loadExistingVisit() {
    final visit = widget.existingVisit!;
    setState(() {
      selectedSystem = visit.system;
      selectedPreset = visit.diagramType;
      markers = List<Marker>.from(visit.markers);
      drawingPaths = List<DrawingPath>.from(visit.drawingPaths);
      _currentVisitId = visit.id;
      _isEditingMode = true;
    });
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isVoiceInitialized = initialized;
    });
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice commands not available. Please check microphone permissions.'),
          ),
        );
      }
    }
  }

  Future<void> _loadAnnotations() async {
    try {
      final visit = await DatabaseHelper.instance.getLatestVisit(
        patientId: patient.id,
        diagramType: selectedPreset,
      );

      if (visit != null && visit.system == selectedSystem && mounted) {
        setState(() {
          markers = List<Marker>.from(visit.markers);
          drawingPaths = List<DrawingPath>.from(visit.drawingPaths);
          _currentVisitId = visit.id;
        });
      }
    } catch (e) {
      print('Error loading visit: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    try {
      final canvasImage = await _captureCanvas();

      final visit = Visit(
        id: _currentVisitId,
        patientId: patient.id,
        system: selectedSystem,
        diagramType: selectedPreset,
        markers: markers,
        drawingPaths: drawingPaths,
        notes: null,
        createdAt: DateTime.now(),
        canvasImage: canvasImage,
      );

      final doctorId = UserService.currentUserId ?? 'USR001';

      if (_currentVisitId == null) {
        final id = await DatabaseHelper.instance.createVisit(visit, doctorId);
        setState(() {
          _currentVisitId = id;
        });
      } else {
        await DatabaseHelper.instance.updateVisit(visit, doctorId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditingMode ? 'Diagram updated successfully' : 'Visit saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSilently() async {
    try {
      final canvasImage = await _captureCanvas();

      final visit = Visit(
        id: _currentVisitId,
        patientId: patient.id,
        system: selectedSystem,
        diagramType: selectedPreset,
        markers: markers,
        drawingPaths: drawingPaths,
        notes: null,
        createdAt: DateTime.now(),
        canvasImage: canvasImage,
      );

      final doctorId = UserService.currentUserId ?? 'USR001';

      if (_currentVisitId == null) {
        final id = await DatabaseHelper.instance.createVisit(visit, doctorId);
        _currentVisitId = id;
      } else {
        await DatabaseHelper.instance.updateVisit(visit, doctorId);
      }
    } catch (e) {
      print('Error saving: $e');
    }
  }

  Future<void> _proceedToConsultation() async {
    if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
      await _saveSilently();
    }

    if (mounted) {
      Navigator.pop(context, _currentVisitId);
    }
  }

  Future<void> _handlePrintPDF() async {
    try {
      final allVisits = await DatabaseHelper.instance.getAllVisitsForPatient(
        patientId: patient.id,
      );

      final systemVisits = allVisits.where((v) => v.system == selectedSystem).toList();

      if (systemVisits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No saved diagrams found for this system'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final selectedVisits = await showDialog<List<Visit>>(
        context: context,
        builder: (context) => ImageSelectionDialog(
          patient: patient,
          visits: systemVisits,
          currentSystem: selectedSystem,
        ),
      );

      if (selectedVisits != null && selectedVisits.isNotEmpty) {
        await MultiImagePDFService.generateDiagramsPDF(
          patient: patient,
          selectedVisits: selectedVisits,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _undoDrawing() {
    if (drawingPaths.isNotEmpty) {
      setState(() {
        drawingPaths = List.from(drawingPaths)..removeLast();
        selectedPathIndex = null;
      });
    }
  }

  void _deleteSelectedPath() {
    if (selectedPathIndex != null && selectedPathIndex! < drawingPaths.length) {
      setState(() {
        drawingPaths = List.from(drawingPaths)..removeAt(selectedPathIndex!);
        selectedPathIndex = null;
      });
    }
  }

  // ✅ NEW: Clear only markers
  void _clearMarkers() {
    setState(() {
      markers = [];
      selectedMarkerIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All markers cleared'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ NEW: Clear only drawings
  void _clearDrawings() {
    setState(() {
      drawingPaths = [];
      selectedPathIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All drawings cleared'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ✅ UPDATED: Clear all (both markers and drawings)
  void _clearAll() {
    setState(() {
      markers = [];
      drawingPaths = [];
      selectedMarkerIndex = null;
      selectedPathIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All markers and drawings cleared'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  List<ConditionTool> get _currentTools {
    final systemConfig = CanvasSystemConfig.systems[selectedSystem];
    return systemConfig?.tools ?? _defaultTools;
  }

  List<ConditionTool> get _defaultTools => const [
    ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
    ConditionTool(id: 'marker', name: 'Marker', color: Colors.blue, defaultSize: 10),
  ];

  Map<String, Map<String, String>> get _currentDiagrams {
    final systemConfig = CanvasSystemConfig.systems[selectedSystem];
    if (systemConfig == null) {
      return {
        'anatomy': {'anatomical': 'Default Diagram'},
      };
    }

    return {
      'anatomy': Map.fromEntries(
        systemConfig.anatomyDiagrams.entries.map(
              (e) => MapEntry(e.key, e.value.name),
        ),
      ),
      'templates': Map.fromEntries(
        systemConfig.systemTemplates.entries.map(
              (e) => MapEntry(e.key, e.value.name),
        ),
      ),
    };
  }

  Future<Uint8List?> _captureCanvas() async {
    try {
      RenderRepaintBoundary boundary =
      _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
  }

  void _handleVoiceCommand(String recognizedText) {
    setState(() {
      _voiceStatus = 'Heard: "$recognizedText"';
    });

    final command = _voiceService.parseCommand(recognizedText);

    setState(() {
      _voiceStatus = command.getFeedbackMessage();
    });

    _executeCommand(command);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _voiceStatus = '';
        });
      }
    });
  }

  void _executeCommand(VoiceCommand command) {
    switch (command.type) {
      case CommandType.navigation:
        _executeNavigationCommand(command);
        break;
      case CommandType.zoom:
        _executeZoomCommand(command);
        break;
      case CommandType.placeTool:
        _executePlaceToolCommand(command);
        break;
      case CommandType.editMarker:
        _executeEditMarkerCommand(command);
        break;
      case CommandType.generateSummary:
        break;
      case CommandType.unknown:
        break;
    }
  }

  void _executeNavigationCommand(VoiceCommand command) async {
    final preset = command.parameters['preset'] as String?;
    final allDiagrams = _currentDiagrams;
    final combinedDiagrams = {...allDiagrams['anatomy']!, ...allDiagrams['templates']!};

    if (preset != null && combinedDiagrams.containsKey(preset)) {
      if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save Current Diagram?'),
            content: const Text('Do you want to save the current diagram before switching?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Don\'t Save'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          await _saveAnnotations();
        }
      }

      setState(() {
        selectedPreset = preset;
        markers = [];
        drawingPaths = [];
        selectedMarkerIndex = null;
        selectedPathIndex = null;
      });

      await _loadAnnotations();
    }
  }

  void _executeZoomCommand(VoiceCommand command) {
    final action = command.parameters['action'] as String?;
    setState(() {
      if (action == 'in') {
        zoom = (zoom + 0.2).clamp(0.5, 3.0);
      } else if (action == 'out') {
        zoom = (zoom - 0.2).clamp(0.5, 3.0);
      } else if (action == 'reset') {
        zoom = 1.0;
        pan = Offset.zero;
      }
    });
  }

  void _executePlaceToolCommand(VoiceCommand command) {
    final toolType = command.parameters['toolType'] as String?;
    final size = command.parameters['size'] as double?;

    if (toolType != null) {
      setState(() {
        _waitingForClick = true;
        _pendingToolType = toolType;
        _pendingToolSize = size;
        selectedTool = 'pan';
      });
    }
  }

  void _executeEditMarkerCommand(VoiceCommand command) {
    final markerNumber = command.parameters['markerNumber'] as int?;
    final action = command.parameters['action'] as String?;

    if (markerNumber == null) return;

    int index;
    if (markerNumber == -1) {
      index = markers.length - 1;
    } else {
      index = markerNumber - 1;
    }

    if (index < 0 || index >= markers.length) {
      setState(() {
        _voiceStatus = 'Marker $markerNumber does not exist';
      });
      return;
    }

    if (action == 'delete') {
      setState(() {
        markers = List.from(markers)..removeAt(index);
        selectedMarkerIndex = null;
      });
    } else {
      setState(() {
        selectedMarkerIndex = index;
      });
    }
  }

  void _startVoiceListening() async {
    if (!_isVoiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice commands not initialized'),
        ),
      );
      return;
    }

    setState(() {
      _voiceStatus = 'Listening...';
    });

    await _voiceService.startListening(_handleVoiceCommand);
  }

  void _cancelWaitingForClick() {
    setState(() {
      _waitingForClick = false;
      _pendingToolType = null;
      _pendingToolSize = null;
      _voiceStatus = 'Placement cancelled';
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _voiceStatus = '';
        });
      }
    });
  }

  String _getImagePath(String system, String preset) {
    final systemConfig = CanvasSystemConfig.systems[system];
    if (systemConfig == null) {
      return 'assets/images/placeholder_$system.png';
    }

    final diagram = systemConfig.allDiagrams[preset];
    return diagram?.imagePath ?? 'assets/images/placeholder_$system.png';
  }

  @override
  Widget build(BuildContext context) {
    final systemConfig = CanvasSystemConfig.systems[selectedSystem];
    final systemName = systemConfig?.name ?? 'Unknown System';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Stack(
          children: [
            Row(
              children: [
                // LEFT SIDEBAR
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      Expanded(
                        child: ToolPanel(
                          tools: _currentTools,
                          selectedTool: selectedTool,
                          onToolSelected: (tool) {
                            setState(() {
                              selectedTool = tool;
                              _selectedDrawingTool = 'none';
                            });
                          },
                          markers: markers,
                          selectedMarkerIndex: selectedMarkerIndex,
                          onMarkerDeleted: () {
                            if (selectedMarkerIndex != null) {
                              setState(() {
                                markers = List.from(markers)..removeAt(selectedMarkerIndex!);
                                selectedMarkerIndex = null;
                              });
                            }
                          },
                          onMarkerLabelChanged: (newLabel) {
                            if (selectedMarkerIndex != null) {
                              setState(() {
                                markers = List.from(markers);
                                markers[selectedMarkerIndex!] =
                                    markers[selectedMarkerIndex!].copyWith(label: newLabel);
                              });
                            }
                          },
                          onMarkerSizeChanged: (newSize) {
                            if (selectedMarkerIndex != null) {
                              setState(() {
                                markers = List.from(markers);
                                markers[selectedMarkerIndex!] =
                                    markers[selectedMarkerIndex!].copyWith(size: newSize);
                              });
                            }
                          },
                          zoom: zoom,
                          onZoomChanged: (newZoom) {
                            setState(() {
                              zoom = newZoom;
                            });
                          },
                          onResetView: () {
                            setState(() {
                              zoom = 1.0;
                              pan = Offset.zero;
                            });
                          },
                          // ✅ UPDATED: Wire up the three clear callbacks
                          onClearAll: _clearAll,
                          onClearMarkers: _clearMarkers,
                          onClearDrawings: _clearDrawings,
                          drawingPathsCount: drawingPaths.length,
                        ),
                      ),

                      // DRAWING PANEL
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showDrawingPanel = !_showDrawingPanel;
                                  if (_showDrawingPanel) {
                                    _selectedDrawingTool = 'pen';
                                    selectedTool = 'pan';
                                  } else {
                                    _selectedDrawingTool = 'none';
                                    selectedPathIndex = null;
                                  }
                                });
                              },
                              icon: Icon(_showDrawingPanel ? Icons.close : Icons.draw),
                              label: Text(_showDrawingPanel ? 'Close Drawing' : 'Free-Hand Draw'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showDrawingPanel ? Colors.orange : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            if (_showDrawingPanel) ...[
                              const SizedBox(height: 16),
                              DrawingToolPanel(
                                selectedColor: _drawingColor,
                                strokeWidth: _strokeWidth,
                                hasDrawings: drawingPaths.isNotEmpty,
                                hasSelection: selectedPathIndex != null,
                                onColorChanged: (color) => setState(() => _drawingColor = color),
                                onStrokeWidthChanged: (width) => setState(() => _strokeWidth = width),
                                onUndo: _undoDrawing,
                                onDeleteSelected: _deleteSelectedPath,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN CONTENT
                Expanded(
                  child: Column(
                    children: [
                      // TOP HEADER BAR
                      Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
                                  final shouldSave = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Save Current Diagram?'),
                                      content: const Text(
                                          'Do you want to save the current diagram before going back?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Don\'t Save'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Save'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldSave == true) {
                                    await _saveAnnotations();
                                  }
                                }
                                if (mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Canvas Tool',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_isEditingMode) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.orange.shade300),
                                          ),
                                          child: Text(
                                            'EDITING',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    'Patient: ${patient.name}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // SYSTEM SELECTOR
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                value: selectedSystem,
                                decoration: const InputDecoration(
                                  labelText: 'System',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: CanvasSystemConfig.systems.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(
                                      '${entry.value.icon} ${entry.value.name}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value != null && value != selectedSystem) {
                                    if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
                                      final shouldSave = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Save Current Diagram?'),
                                          content: const Text(
                                              'Do you want to save before switching systems?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Don\'t Save'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldSave == true) {
                                        await _saveAnnotations();
                                      }
                                    }

                                    setState(() {
                                      selectedSystem = value;
                                      selectedPreset = CanvasSystemConfig
                                          .systems[value]?.anatomyDiagrams.keys.first ??
                                          'anatomical';
                                      markers = [];
                                      drawingPaths = [];
                                      selectedMarkerIndex = null;
                                      selectedPathIndex = null;
                                      selectedTool = 'pan';
                                      _currentVisitId = null;
                                    });

                                    await _loadAnnotations();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // DIAGRAM SELECTOR
                            SizedBox(
                              width: 220,
                              child: _buildDiagramDropdown(),
                            ),
                            const SizedBox(width: 16),

                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VisitHistoryScreen(patient: patient),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.history, size: 18),
                              label: const Text('History', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_isVoiceInitialized)
                              ElevatedButton.icon(
                                onPressed: _voiceService.isListening ? null : _startVoiceListening,
                                icon: Icon(
                                  _voiceService.isListening ? Icons.mic : Icons.mic_none,
                                  size: 18,
                                ),
                                label: Text(
                                  _voiceService.isListening ? 'Listening...' : 'Voice',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _voiceService.isListening
                                      ? Colors.grey
                                      : const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // CANVAS AREA
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade100,
                          child: Center(
                            child: Container(
                              width: 600,
                              height: 400,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: RepaintBoundary(
                                key: _canvasKey,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: KidneyCanvas(
                                    selectedPreset: selectedPreset,
                                    markers: markers,
                                    drawingPaths: drawingPaths,
                                    selectedMarkerIndex: selectedMarkerIndex,
                                    selectedPathIndex: selectedPathIndex,
                                    selectedTool: selectedTool,
                                    tools: _currentTools,
                                    zoom: zoom,
                                    pan: pan,
                                    waitingForClick: _waitingForClick,
                                    pendingToolType: _pendingToolType,
                                    pendingToolSize: _pendingToolSize,
                                    selectedDrawingTool: _selectedDrawingTool,
                                    drawingColor: _drawingColor,
                                    strokeWidth: _strokeWidth,
                                    onMarkerAdded: (marker) {
                                      setState(() {
                                        markers = List.from(markers)..add(marker);
                                        selectedMarkerIndex = markers.length - 1;
                                        selectedTool = 'pan';
                                        _waitingForClick = false;
                                        _pendingToolType = null;
                                        _pendingToolSize = null;
                                        _voiceStatus = 'Marker placed successfully';
                                      });

                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (mounted) {
                                          setState(() {
                                            _voiceStatus = '';
                                          });
                                        }
                                      });
                                    },
                                    onMarkerSelected: (index) {
                                      setState(() {
                                        selectedMarkerIndex = index == -1 ? null : index;
                                      });
                                    },
                                    onMarkerMoved: (index, newRelativePosition) {
                                      setState(() {
                                        markers = List.from(markers);
                                        markers[index] = markers[index].copyWith(
                                          x: newRelativePosition.dx,
                                          y: newRelativePosition.dy,
                                        );
                                      });
                                    },
                                    onMarkerResized: (index, newSize) {
                                      setState(() {
                                        markers = List.from(markers);
                                        markers[index] = markers[index].copyWith(size: newSize);
                                      });
                                    },
                                    onPanChanged: (newPan) {
                                      setState(() {
                                        pan = newPan;
                                      });
                                    },
                                    onDrawingPathAdded: (path) {
                                      setState(() {
                                        drawingPaths = List.from(drawingPaths)..add(path);
                                        selectedPathIndex = null;
                                      });
                                    },
                                    onDrawingPathSelected: (index) {
                                      setState(() {
                                        selectedPathIndex = index == -1 ? null : index;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // BOTTOM BAR
                      Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        patient.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          patient.id,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Markers: ${markers.length}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Drawings: ${drawingPaths.length}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ACTION BUTTONS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // PRINT PDF BUTTON
                                ElevatedButton.icon(
                                  onPressed: _handlePrintPDF,
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  label: const Text('Print PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // SAVE BUTTON
                                ElevatedButton.icon(
                                  onPressed: (markers.isEmpty && drawingPaths.isEmpty)
                                      ? null
                                      : _saveAnnotations,
                                  icon: const Icon(Icons.save, size: 16),
                                  label: Text(_isEditingMode ? 'Update' : 'Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // PROCEED TO CONSULTATION BUTTON
                                ElevatedButton.icon(
                                  onPressed: _proceedToConsultation,
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('Proceed to Consultation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              ],
            ),

            // VOICE FEEDBACK OVERLAY
            VoiceFeedbackOverlay(
              message: _voiceStatus,
              isListening: _voiceService.isListening,
              waitingForClick: _waitingForClick,
              onCancel: _cancelWaitingForClick,
            ),
          ],
        ),
      ),
    );
  }

  // DIAGRAM DROPDOWN WITH SECTIONS
  Widget _buildDiagramDropdown() {
    final diagrams = _currentDiagrams;
    final anatomyDiagrams = diagrams['anatomy'] ?? {};
    final templates = diagrams['templates'] ?? {};

    return DropdownButtonFormField<String>(
      value: selectedPreset,
      decoration: const InputDecoration(
        labelText: 'Diagram Type',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      isExpanded: true,
      items: [
        // ANATOMY DIAGRAMS SECTION
        if (anatomyDiagrams.isNotEmpty)
          const DropdownMenuItem<String>(
            enabled: false,
            value: null,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '📋 Anatomy Diagrams',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ...anatomyDiagrams.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }),

        // SYSTEM TEMPLATES SECTION
        if (templates.isNotEmpty) ...[
          const DropdownMenuItem<String>(
            enabled: false,
            value: null,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '🏥 System Templates',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
          ...templates.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  entry.value,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            );
          }),
        ],
      ],
      onChanged: (value) async {
        if (value != null) {
          if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
            final shouldSave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Save Current Diagram?'),
                content: const Text(
                    'Do you want to save the current diagram before switching?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Don\'t Save'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );

            if (shouldSave == true) {
              await _saveAnnotations();
            }
          }

          setState(() {
            selectedPreset = value;
            markers = [];
            drawingPaths = [];
            selectedMarkerIndex = null;
            selectedPathIndex = null;
            _currentVisitId = null;
          });

          await _loadAnnotations();
        }
      },
    );
  }
}