// lib/screens/kidney/kidney_screen.dart - UNIFIED WHISPER VOICE SYSTEM

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/visit.dart';
import '../../models/condition_tool.dart';
import '../../models/prescription.dart';
import '../../models/drawing_path.dart';
import '../../services/database_helper.dart';
import '../patient/visit_history_screen.dart';
import '../prescription/prescription_management_screen.dart';
import 'widgets/kidney_canvas.dart';
import 'widgets/tool_panel.dart';
import 'widgets/drawing_tool_panel.dart';
import 'pdf_preview_screen.dart';
import '../../services/user_service.dart';
import '../lab_test/lab_test_management_screen.dart';
import '../../services/medical_dictation_service.dart';
import '../../widgets/floating_voice_button.dart';
import '../patient/patient_data_edit_screen.dart';

class KidneyScreen extends StatefulWidget {
  final Patient? patient;

  const KidneyScreen({super.key, this.patient});

  @override
  State<KidneyScreen> createState() => _KidneyScreenState();
}

class _KidneyScreenState extends State<KidneyScreen> {
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

  bool _waitingForClick = false;
  String? _pendingToolType;
  double? _pendingToolSize;
  String _voiceStatus = '';

  int? _currentVisitId;

  // Drawing state
  String _selectedDrawingTool = 'none';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _showDrawingPanel = false;

  @override
  void initState() {
    super.initState();
    patient = widget.patient ?? Patient(
      id: 'TEMP001',
      name: 'John Doe',
      age: 45,
      phone: '0000000000',
      date: DateTime.now().toString().split(' ')[0],
    );
    _loadAnnotations();

    // REGISTER FOR UNIFIED VOICE COMMANDS (both medical and kidney-specific)
    FloatingVoiceButtonState.registerDictationCallback(_handleUnifiedVoiceCommand);
  }

  Future<void> _loadAnnotations() async {
    if (widget.patient == null) return;

    try {
      final visit = await DatabaseHelper.instance.getLatestVisit(
        patientId: patient.id,
        diagramType: 'kidney',
      );

      if (visit != null && mounted) {
        setState(() {
          _currentVisitId = visit.id;
          markers = visit.markers;
          drawingPaths = visit.drawingPaths ?? [];
        });
      }
    } catch (e) {
      print('Error loading annotations: $e');
    }
  }

  // ==================== UNIFIED VOICE COMMAND HANDLER ====================
  void _handleUnifiedVoiceCommand(DictationResult result) {
    final text = result.originalText.toLowerCase().trim();
    print('🎤 Kidney screen received: "$text"');

    // First check if it's a kidney-specific command
    if (_isKidneyCommand(text)) {
      _handleKidneyCommand(text);
      return;
    }

    // Otherwise, handle as medical dictation
    _handleMedicalDictation(result);
  }

  // ==================== KIDNEY-SPECIFIC COMMAND DETECTION ====================
  bool _isKidneyCommand(String text) {
    return _containsAny(text, [
      // Navigation commands
      'anatomical', 'simple', 'cross section', 'nephron',
      'polycystic', 'pyelonephritis', 'glomerulonephritis',
      'switch to', 'show', 'load',

      // Zoom commands
      'zoom in', 'zoom out', 'reset zoom', 'reset view',

      // Place tool commands
      'place', 'add', 'mark', 'put',
      'calculi', 'stone', 'cyst', 'tumor', 'inflammation', 'blockage',

      // Edit marker commands
      'delete marker', 'remove marker', 'select marker',
      'marker', 'first', 'second', 'third', 'last',

      // Generate summary
      'generate', 'create summary', 'make pdf',
    ]);
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // ==================== KIDNEY COMMAND HANDLER ====================
  void _handleKidneyCommand(String text) {
    print('🎯 Processing kidney command: "$text"');

    setState(() {
      _voiceStatus = 'Processing: "$text"';
    });

    // NAVIGATION COMMANDS
    if (_containsAny(text, ['anatomical', 'detailed', 'anatomy'])) {
      _changePreset('anatomical', 'Detailed Anatomy');
    } else if (_containsAny(text, ['simple', 'basic'])) {
      _changePreset('simple', 'Simple Diagram');
    } else if (_containsAny(text, ['cross section', 'cross-section', 'section'])) {
      _changePreset('crossSection', 'Cross-Section View');
    } else if (text.contains('nephron')) {
      _changePreset('nephron', 'Nephron');
    } else if (text.contains('polycystic')) {
      _changePreset('polycystic', 'Polycystic Kidney Disease');
    } else if (_containsAny(text, ['pyelonephritis', 'pyelo'])) {
      _changePreset('pyelonephritis', 'Pyelonephritis');
    } else if (_containsAny(text, ['glomerulonephritis', 'glomero'])) {
      _changePreset('glomerulonephritis', 'Glomerulonephritis');
    }

    // ZOOM COMMANDS
    else if (_containsAny(text, ['zoom in', 'zoomin'])) {
      _executeZoom('in');
    } else if (_containsAny(text, ['zoom out', 'zoomout'])) {
      _executeZoom('out');
    } else if (_containsAny(text, ['reset zoom', 'reset view'])) {
      _executeZoom('reset');
    }

    // PLACE TOOL COMMANDS
    else if (_containsAny(text, ['place', 'add', 'mark', 'put'])) {
      _handlePlaceCommand(text);
    }

    // DELETE MARKER COMMANDS
    else if (_containsAny(text, ['delete', 'remove'])) {
      _handleDeleteCommand(text);
    }

    // GENERATE SUMMARY
    else if (_containsAny(text, ['generate', 'create summary', 'make pdf'])) {
      _generateSummary();
    }

    // UNKNOWN KIDNEY COMMAND
    else {
      setState(() {
        _voiceStatus = 'Command not recognized';
      });
    }

    // Clear status after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _voiceStatus = '';
        });
      }
    });
  }

  void _changePreset(String preset, String displayName) async {
    await _saveSilently();
    setState(() {
      selectedPreset = preset;
      markers.clear();
      drawingPaths.clear();
      _currentVisitId = null;
      _voiceStatus = '✓ Switched to $displayName';
    });
  }

  void _executeZoom(String action) {
    setState(() {
      if (action == 'in') {
        zoom = (zoom * 1.2).clamp(0.5, 3.0);
        _voiceStatus = '✓ Zoomed in';
      } else if (action == 'out') {
        zoom = (zoom / 1.2).clamp(0.5, 3.0);
        _voiceStatus = '✓ Zoomed out';
      } else if (action == 'reset') {
        zoom = 1.0;
        pan = Offset.zero;
        _voiceStatus = '✓ View reset';
      }
    });
  }

  void _handlePlaceCommand(String text) {
    String? toolType;
    double? size;

    // Detect tool type
    if (_containsAny(text, ['calculi', 'calculus', 'stone', 'kidney stone'])) {
      toolType = 'calculi';
    } else if (text.contains('cyst')) {
      toolType = 'cyst';
    } else if (_containsAny(text, ['tumor', 'tumour', 'mass'])) {
      toolType = 'tumor';
    } else if (_containsAny(text, ['inflammation', 'inflamed'])) {
      toolType = 'inflammation';
    } else if (_containsAny(text, ['blockage', 'obstruction', 'block'])) {
      toolType = 'blockage';
    }

    if (toolType == null) {
      setState(() {
        _voiceStatus = '❌ Tool not recognized. Try: "place calculi" or "add cyst"';
      });
      return;
    }

    // Extract size
    final sizePattern = RegExp(r'(\d+)\s*(?:mm|millimeter)?');
    final sizeMatch = sizePattern.firstMatch(text);
    if (sizeMatch != null) {
      size = double.tryParse(sizeMatch.group(1) ?? '');
    }

    // Parse word numbers
    if (size == null) {
      final wordNumbers = {
        'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0,
        'six': 6.0, 'seven': 7.0, 'eight': 8.0, 'nine': 9.0, 'ten': 10.0,
        'fifteen': 15.0, 'twenty': 20.0, 'thirty': 30.0,
      };
      for (var entry in wordNumbers.entries) {
        if (text.contains(entry.key)) {
          size = entry.value;
          break;
        }
      }
    }

    setState(() {
      selectedTool = toolType!;
      _waitingForClick = true;
      _pendingToolType = toolType;
      _pendingToolSize = size;
      _voiceStatus = size != null
          ? '✓ Ready to place ${toolType.toUpperCase()} (${size}mm) - Tap location'
          : '✓ Ready to place ${toolType.toUpperCase()} - Tap location';
    });
  }

  void _handleDeleteCommand(String text) {
    int? markerNumber;

    // Try to find marker number
    final numberMatch = RegExp(r'marker\s+(\d+)|number\s+(\d+)').firstMatch(text);
    if (numberMatch != null) {
      markerNumber = int.tryParse(numberMatch.group(1) ?? numberMatch.group(2) ?? '');
    }

    // Try word numbers
    if (markerNumber == null) {
      final wordNumbers = {
        'first': 1, 'one': 1,
        'second': 2, 'two': 2,
        'third': 3, 'three': 3,
        'fourth': 4, 'four': 4,
        'fifth': 5, 'five': 5,
        'last': -1,
      };
      for (var entry in wordNumbers.entries) {
        if (text.contains(entry.key)) {
          markerNumber = entry.value;
          break;
        }
      }
    }

    if (markerNumber == null) {
      setState(() {
        _voiceStatus = '❌ Marker number not found. Try: "delete marker 1"';
      });
      return;
    }

    int actualIndex;
    if (markerNumber == -1) {
      actualIndex = markers.length - 1;
    } else {
      actualIndex = markerNumber - 1;
    }

    if (actualIndex < 0 || actualIndex >= markers.length) {
      setState(() {
        _voiceStatus = '❌ Marker $markerNumber not found';
      });
      return;
    }

    setState(() {
      markers.removeAt(actualIndex);
      selectedMarkerIndex = null;
      _voiceStatus = '✓ Deleted marker $markerNumber';
    });
  }

  void _generateSummary() async {
    setState(() {
      _voiceStatus = '✓ Generating summary...';
    });
    await _saveSilently();
    _openPDFPreview();
  }

  // ==================== MEDICAL DICTATION HANDLER ====================
  void _handleMedicalDictation(DictationResult result) {
    print('📋 Processing medical dictation: ${result.type}');

    setState(() {
      switch (result.type) {
        case DictationType.vitals:
          final vitalsText = result.data.entries
              .map((e) => '${e.key}: ${e.value}')
              .join(', ');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📊 Vitals captured: $vitalsText'),
              backgroundColor: Colors.blue.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Save to Patient',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDataEditScreen(patient: patient),
                    ),
                  );
                },
              ),
            ),
          );
          break;

        case DictationType.prescription:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Prescription: ${result.data['medicationName']}'),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open Rx',
                textColor: Colors.white,
                onPressed: _openPrescriptions,
              ),
            ),
          );
          break;

        case DictationType.labTest:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.science, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Lab test: ${result.data['testName']}')),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open Lab',
                textColor: Colors.white,
                onPressed: _openLabTests,
              ),
            ),
          );
          break;

        case DictationType.diagnosis:
        case DictationType.treatment:
        case DictationType.notes:
          final noteType = result.type == DictationType.diagnosis
              ? 'diagnosis'
              : result.type == DictationType.treatment
              ? 'treatment'
              : 'notes';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📝 Clinical $noteType captured!'),
              backgroundColor: Colors.purple.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View/Edit',
                textColor: Colors.white,
                onPressed: () async {
                  await _saveSilently();
                  _openPDFPreview();
                },
              ),
            ),
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.feedback}'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
          break;
      }
    });
  }

  // ==================== HELPER METHODS ====================
  Future<void> _saveSilently() async {
    if (markers.isEmpty && drawingPaths.isEmpty) return;

    try {
      final visit = Visit(
        id: _currentVisitId,
        patientId: patient.id,
        diagramType: 'kidney',
        markers: markers,
        drawingPaths: drawingPaths,
        createdAt: DateTime.now(),
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

  Future<void> _openPrescriptions() async {
    if (_currentVisitId == null && (markers.isNotEmpty || drawingPaths.isNotEmpty)) {
      await _saveSilently();
    }

    if (_currentVisitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add markers first then save')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionManagementScreen(
          visitId: _currentVisitId!,
          patientId: patient.id,
          patient: patient,
        ),
      ),
    );
  }

  Future<void> _openLabTests() async {
    if (_currentVisitId == null && (markers.isNotEmpty || drawingPaths.isNotEmpty)) {
      await _saveSilently();
    }

    if (_currentVisitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add markers first then save')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabTestManagementScreen(
          visitId: _currentVisitId!,
          patientId: patient.id,
          patient: patient,
        ),
      ),
    );
  }

  void _openPDFPreview() async {
    final canvasImage = await _captureCanvas();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFPreviewScreen(
            patient: patient,
            markers: markers,
            canvasImage: canvasImage,
            visitId: _currentVisitId,
          ),
        ),
      );
    }
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

  @override
  void dispose() {
    // UNREGISTER DICTATION
    _FloatingVoiceButtonState.registerDictationCallback(null);
    super.dispose();
  }

  final List<ConditionTool> tools = const [
    ConditionTool(id: 'pan', name: 'Pan Tool', color: Colors.grey, defaultSize: 0),
    ConditionTool(id: 'calculi', name: 'Calculi', color: Colors.grey, defaultSize: 8),
    ConditionTool(id: 'cyst', name: 'Cyst', color: Color(0xFF2563EB), defaultSize: 12),
    ConditionTool(id: 'tumor', name: 'Tumor', color: Color(0xFF7C2D12), defaultSize: 16),
    ConditionTool(id: 'inflammation', name: 'Inflammation', color: Color(0xFFEA580C), defaultSize: 14),
    ConditionTool(id: 'blockage', name: 'Blockage', color: Color(0xFF9333EA), defaultSize: 10),
  ];

  final Map<String, String> presets = {
    'anatomical': 'Detailed Anatomy',
    'simple': 'Simple Diagram',
    'crossSection': 'Cross-Section View',
    'nephron': 'Nephron',
    'polycystic': 'Polycystic Kidney Disease',
    'pyelonephritis': 'Pyelonephritis',
    'glomerulonephritis': 'Glomerulonephritis',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${patient.age}y • ${patient.phone}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Voice Status Indicator
                  if (_voiceStatus.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _voiceStatus.startsWith('✓')
                            ? Colors.green.shade50
                            : _voiceStatus.startsWith('❌')
                            ? Colors.red.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _voiceStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: _voiceStatus.startsWith('✓')
                              ? Colors.green.shade700
                              : _voiceStatus.startsWith('❌')
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitHistoryScreen(patient: patient),
                        ),
                      );
                    },
                    tooltip: 'Visit History',
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: Row(
              children: [
                // Left Sidebar - Tools
                Container(
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: ToolPanel(
                    tools: tools,
                    selectedTool: selectedTool,
                    onToolSelected: (toolId) {
                      setState(() {
                        selectedTool = toolId;
                        selectedMarkerIndex = null;
                        _waitingForClick = toolId != 'pan';
                        _pendingToolType = toolId != 'pan' ? toolId : null;
                        _pendingToolSize = null;
                      });
                    },
                    onDrawingToolSelected: () {
                      setState(() {
                        _showDrawingPanel = !_showDrawingPanel;
                      });
                    },
                    showDrawingPanel: _showDrawingPanel,
                  ),
                ),

                // Canvas
                Expanded(
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: KidneyCanvas(
                      selectedPreset: selectedPreset,
                      markers: markers,
                      drawingPaths: drawingPaths,
                      selectedMarkerIndex: selectedMarkerIndex,
                      selectedPathIndex: selectedPathIndex,
                      selectedTool: selectedTool,
                      tools: tools,
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
                          markers.add(marker);
                          _waitingForClick = false;
                          _pendingToolType = null;
                          _pendingToolSize = null;
                          selectedTool = 'pan';
                          _voiceStatus = '✓ Marker placed';
                        });
                      },
                      onMarkerSelected: (index) {
                        setState(() {
                          selectedMarkerIndex = index;
                          selectedPathIndex = null;
                        });
                      },
                      onMarkerMoved: (index, newPosition) {
                        setState(() {
                          markers[index] = markers[index].copyWith(position: newPosition);
                        });
                      },
                      onMarkerResized: (index, newSize) {
                        setState(() {
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
                        });
                      },
                      onDrawingPathSelected: (index) {
                        setState(() {
                          selectedPathIndex = index;
                          selectedMarkerIndex = null;
                        });
                      },
                    ),
                  ),
                ),

                // Right Sidebar - Drawing Tools (if shown)
                if (_showDrawingPanel)
                  Container(
                    width: 200,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey, width: 0.5)),
                    ),
                    child: DrawingToolPanel(
                      selectedTool: _selectedDrawingTool,
                      selectedColor: _drawingColor,
                      strokeWidth: _strokeWidth,
                      onToolSelected: (tool) {
                        setState(() {
                          _selectedDrawingTool = tool;
                        });
                      },
                      onColorSelected: (color) {
                        setState(() {
                          _drawingColor = color;
                        });
                      },
                      onStrokeWidthChanged: (width) {
                        setState(() {
                          _strokeWidth = width;
                        });
                      },
                      onUndo: _undoDrawing,
                      onDeleteSelected: _deleteSelectedPath,
                      canUndo: drawingPaths.isNotEmpty,
                      hasSelection: selectedPathIndex != null,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Bar
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              presets[selectedPreset] ?? selectedPreset,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${markers.length} markers',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.draw, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${drawingPaths.length} drawings',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openPrescriptions,
                  icon: const Icon(Icons.medication, size: 20),
                  label: const Text('Prescriptions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openLabTests,
                  icon: const Icon(Icons.science, size: 20),
                  label: const Text('Lab Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _saveSilently();
                    _openPDFPreview();
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text('Generate PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}