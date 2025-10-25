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
import 'widgets/thyroid_canvas.dart';
import 'widgets/thyroid_tool_panel.dart';
import 'widgets/drawing_tool_panel.dart';
import '../../services/user_service.dart';
import '../../config/canvas_system_config.dart';

class ThyroidCanvasScreen extends StatefulWidget {
  final Patient patient;
  final Visit? existingVisit;
  final String? preSelectedSystem;
  final String? preSelectedDiagramType;

  const ThyroidCanvasScreen({
    super.key,
    required this.patient,
    this.existingVisit,
    this.preSelectedSystem,
    this.preSelectedDiagramType,
  });

  @override
  State<ThyroidCanvasScreen> createState() => _ThyroidCanvasScreenState();
}

class _ThyroidCanvasScreenState extends State<ThyroidCanvasScreen> {
  String selectedSystem = 'thyroid';
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
  int? _originalVisitId;  // Track original visit when editing
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
      selectedSystem = 'thyroid';
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
      _originalVisitId = visit.id;  // Store original ID
      _currentVisitId = null;  // Clear current ID so it creates a new visit
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

      // When editing, always create a new visit marked as "edited"
      // Keep the original visit unchanged
      final visit = Visit(
        id: null,  // Always null to force creation of new visit
        patientId: patient.id,
        system: selectedSystem,
        diagramType: selectedPreset,
        markers: markers,
        drawingPaths: drawingPaths,
        notes: null,
        createdAt: DateTime.now(),
        canvasImage: canvasImage,
        isEdited: _isEditingMode,  // Mark as edited if we're in editing mode
        originalVisitId: _isEditingMode ? _originalVisitId : null,  // Link to original
      );

      final doctorId = UserService.currentUserId ?? 'USR001';

      // Always create a new visit (never update)
      final id = await DatabaseHelper.instance.createVisit(visit, doctorId);
      setState(() {
        _currentVisitId = id;
        // After saving edited version, treat it as the new "current" version
        if (_isEditingMode) {
          _originalVisitId = id;  // Update original ref in case of further edits
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditingMode
                ? 'New edited version created - original preserved'
                : 'Diagram saved successfully'),
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

      // When editing, always create a new visit marked as "edited"
      final visit = Visit(
        id: null,  // Always null to force creation
        patientId: patient.id,
        system: selectedSystem,
        diagramType: selectedPreset,
        markers: markers,
        drawingPaths: drawingPaths,
        notes: null,
        createdAt: DateTime.now(),
        canvasImage: canvasImage,
        isEdited: _isEditingMode,
        originalVisitId: _isEditingMode ? _originalVisitId : null,
      );

      final doctorId = UserService.currentUserId ?? 'USR001';
      final id = await DatabaseHelper.instance.createVisit(visit, doctorId);
      setState(() {
        _currentVisitId = id;
        if (_isEditingMode) {
          _originalVisitId = id;
        }
      });
    } catch (e) {
      print('Error silently saving visit: $e');
    }
  }

  Future<Uint8List?> _captureCanvas() async {
    try {
      final RenderRepaintBoundary boundary =
      _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
  }

  Map<String, Map<String, String>> get _currentDiagrams {
    final systemConfig = CanvasSystemConfig.systems[selectedSystem];
    if (systemConfig == null) {
      return {
        'anatomy': {},
        'templates': {},
      };
    }

    return {
      'anatomy': systemConfig.anatomyDiagrams.entries.map(
            (entry) => MapEntry(entry.key, entry.value.name),
      ).fold({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      }),
      'templates': systemConfig.systemTemplates.entries.map(
            (entry) => MapEntry(entry.key, entry.value.name),
      ).fold({}, (map, entry) {
        map[entry.key] = entry.value;
        return map;
      }),
    };
  }

  void _handleMarkerTap(Offset localPosition) {
    if (selectedTool == 'marker') {
      setState(() {
        final marker = Marker(
          position: localPosition,
          type: _pendingToolType ?? 'Nodule',
          size: _pendingToolSize ?? 15,
        );
        markers.add(marker);
        selectedMarkerIndex = markers.length - 1;
        _waitingForClick = false;
        _pendingToolType = null;
        _pendingToolSize = null;
      });
      _saveSilently();
    }
  }

  void _handleMarkerSelection(int index) {
    setState(() {
      if (selectedMarkerIndex == index) {
        selectedMarkerIndex = null;
      } else {
        selectedMarkerIndex = index;
        selectedPathIndex = null;
      }
    });
  }

  void _handlePathSelection(int index) {
    setState(() {
      if (selectedPathIndex == index) {
        selectedPathIndex = null;
      } else {
        selectedPathIndex = index;
        selectedMarkerIndex = null;
      }
    });
  }

  void _deleteSelectedMarker() {
    if (selectedMarkerIndex != null) {
      setState(() {
        markers.removeAt(selectedMarkerIndex!);
        selectedMarkerIndex = null;
      });
      _saveSilently();
    }
  }

  void _deleteSelectedPath() {
    if (selectedPathIndex != null) {
      setState(() {
        drawingPaths.removeAt(selectedPathIndex!);
        selectedPathIndex = null;
      });
      _saveSilently();
    }
  }

  void _clearAllMarkers() {
    setState(() {
      markers.clear();
      selectedMarkerIndex = null;
    });
    _saveSilently();
  }

  void _clearAllPaths() {
    setState(() {
      drawingPaths.clear();
      selectedPathIndex = null;
    });
    _saveSilently();
  }

  void _handleVoiceCommand(String command) async {
    setState(() {
      _voiceStatus = 'Processing: "$command"';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final lowerCommand = command.toLowerCase().trim();

    // Check for marker placement commands
    if (lowerCommand.contains('add') || lowerCommand.contains('place') || lowerCommand.contains('mark')) {
      String? toolType;
      double? toolSize;

      if (lowerCommand.contains('nodule')) {
        toolType = 'Nodule';
        toolSize = 15;
      } else if (lowerCommand.contains('cyst')) {
        toolType = 'Cyst';
        toolSize = 18;
      } else if (lowerCommand.contains('calcification')) {
        toolType = 'Calcification';
        toolSize = 10;
      } else if (lowerCommand.contains('inflammation')) {
        toolType = 'Inflammation';
        toolSize = 20;
      } else if (lowerCommand.contains('tumor')) {
        toolType = 'Tumor';
        toolSize = 25;
      }

      if (toolType != null) {
        setState(() {
          selectedTool = 'marker';
          _waitingForClick = true;
          _pendingToolType = toolType;
          _pendingToolSize = toolSize;
          _voiceStatus = 'Click on diagram to place $toolType';
        });
        return;
      }
    }

    // Check for diagram switching
    if (lowerCommand.contains('switch') || lowerCommand.contains('show') || lowerCommand.contains('change')) {
      final diagrams = _currentDiagrams;
      final anatomyDiagrams = diagrams['anatomy'] as Map<String, String>? ?? {};
      final templates = diagrams['templates'] as Map<String, String>? ?? {};

      String? targetDiagram;
      for (var entry in anatomyDiagrams.entries) {
        if (lowerCommand.contains(entry.value.toLowerCase())) {
          targetDiagram = entry.key;
          break;
        }
      }

      if (targetDiagram == null) {
        for (var entry in templates.entries) {
          if (lowerCommand.contains(entry.value.toLowerCase())) {
            targetDiagram = entry.key;
            break;
          }
        }
      }

      if (targetDiagram != null && targetDiagram != selectedPreset) {
        if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
          await _saveAnnotations();
        }

        setState(() {
          selectedPreset = targetDiagram!;
          markers = [];
          drawingPaths = [];
          selectedMarkerIndex = null;
          selectedPathIndex = null;
          _currentVisitId = null;
          _voiceStatus = 'Switched to ${anatomyDiagrams[targetDiagram] ?? templates[targetDiagram]}';
        });

        await _loadAnnotations();
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _voiceStatus = '');
        return;
      }
    }

    // Delete commands
    if (lowerCommand.contains('delete') || lowerCommand.contains('remove') || lowerCommand.contains('clear')) {
      if (lowerCommand.contains('all')) {
        if (lowerCommand.contains('marker')) {
          _clearAllMarkers();
          setState(() => _voiceStatus = 'All markers cleared');
        } else if (lowerCommand.contains('drawing') || lowerCommand.contains('path')) {
          _clearAllPaths();
          setState(() => _voiceStatus = 'All drawings cleared');
        } else {
          markers.clear();
          drawingPaths.clear();
          setState(() => _voiceStatus = 'All annotations cleared');
          _saveSilently();
        }
      } else {
        if (selectedMarkerIndex != null) {
          _deleteSelectedMarker();
          setState(() => _voiceStatus = 'Marker deleted');
        } else if (selectedPathIndex != null) {
          _deleteSelectedPath();
          setState(() => _voiceStatus = 'Drawing deleted');
        } else {
          setState(() => _voiceStatus = 'No item selected to delete');
        }
      }

      await Future.delayed(const Duration(seconds: 2));
      setState(() => _voiceStatus = '');
      return;
    }

    // Save command
    if (lowerCommand.contains('save')) {
      await _saveAnnotations();
      setState(() => _voiceStatus = 'Diagram saved');
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _voiceStatus = '');
      return;
    }

    // Default response
    setState(() {
      _voiceStatus = 'Command not recognized. Try: "add nodule", "switch to anatomical", "delete all markers", "save"';
    });

    await Future.delayed(const Duration(seconds: 3));
    setState(() => _voiceStatus = '');
  }

  void _cancelWaitingForClick() {
    setState(() {
      _waitingForClick = false;
      _pendingToolType = null;
      _pendingToolSize = null;
      _voiceStatus = '';
    });
  }

  Future<void> _handlePrintPDF() async {
    try {
      // Get all visits for this patient
      final allVisits = await DatabaseHelper.instance.getAllVisitsForPatient(patient.id);

      if (allVisits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No diagrams to print. Please save at least one diagram.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show dialog to select which diagrams to include
      if (!mounted) return;

      final selectedVisits = await showDialog<List<Visit>>(
        context: context,
        builder: (context) => ImageSelectionDialog(visits: allVisits),
      );

      if (selectedVisits == null || selectedVisits.isEmpty) {
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Generate PDF with selected visits
      final pdfBytes = await MultiImagePdfService.generateMultiImagePdf(
        patient: patient,
        visits: selectedVisits,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (pdfBytes != null) {
        await MultiImagePdfService.savePdf(pdfBytes, patient);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PDF generated and saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToConsultation() {
    Navigator.pushNamed(
      context,
      '/three-page-consultation',
      arguments: {
        'patient': patient,
        'selectedSystem': selectedSystem,
      },
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thyroid Diagram',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              patient.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          // Voice Command Button
          if (_isVoiceInitialized)
            IconButton(
              icon: Icon(
                _voiceService.isListening ? Icons.mic : Icons.mic_none,
                color: _voiceService.isListening ? Colors.red : Colors.white,
              ),
              onPressed: () async {
                if (_voiceService.isListening) {
                  final result = await _voiceService.stopListening();
                  if (result != null && result.isNotEmpty) {
                    _handleVoiceCommand(result);
                  }
                } else {
                  setState(() => _voiceStatus = 'Listening...');
                  await _voiceService.startListening();
                }
              },
              tooltip: 'Voice Commands',
            ),

          // View History Button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VisitHistoryScreen(
                    patient: patient,
                    diagramType: selectedPreset,
                  ),
                ),
              );
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // MAIN CONTENT
            Row(
              children: [
                // LEFT SIDEBAR - TOOL PANELS
                Container(
                  width: 280,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // System Selector (if multiple systems supported in future)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'System',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.medical_services, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thyroid',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Diagram Type Dropdown
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: _buildDiagramDropdown(),
                      ),

                      // Tool Panels (Scrollable)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // THYROID TOOL PANEL
                              ThyroidToolPanel(
                                selectedTool: selectedTool,
                                onToolSelected: (tool, type, size) {
                                  setState(() {
                                    selectedTool = tool;
                                    if (tool == 'marker') {
                                      _waitingForClick = true;
                                      _pendingToolType = type;
                                      _pendingToolSize = size;
                                    } else {
                                      _waitingForClick = false;
                                      _pendingToolType = null;
                                      _pendingToolSize = null;
                                    }
                                  });
                                },
                                onDeleteMarker: selectedMarkerIndex != null ? _deleteSelectedMarker : null,
                                onClearAll: markers.isNotEmpty ? _clearAllMarkers : null,
                                markerCount: markers.length,
                              ),

                              // DRAWING TOOL PANEL
                              DrawingToolPanel(
                                selectedTool: _selectedDrawingTool,
                                selectedColor: _drawingColor,
                                strokeWidth: _strokeWidth,
                                onToolSelected: (tool) {
                                  setState(() {
                                    _selectedDrawingTool = tool;
                                    if (tool != 'none') {
                                      selectedTool = 'draw';
                                    } else {
                                      selectedTool = 'pan';
                                    }
                                  });
                                },
                                onColorChanged: (color) {
                                  setState(() => _drawingColor = color);
                                },
                                onStrokeWidthChanged: (width) {
                                  setState(() => _strokeWidth = width);
                                },
                                onDeletePath: selectedPathIndex != null ? _deleteSelectedPath : null,
                                onClearAll: drawingPaths.isNotEmpty ? _clearAllPaths : null,
                                pathCount: drawingPaths.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN CANVAS AREA
                Expanded(
                  child: Column(
                    children: [
                      // CANVAS
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: RepaintBoundary(
                              key: _canvasKey,
                              child: ThyroidCanvas(
                                selectedPreset: selectedPreset,
                                selectedTool: selectedTool,
                                markers: markers,
                                drawingPaths: drawingPaths,
                                selectedMarkerIndex: selectedMarkerIndex,
                                selectedPathIndex: selectedPathIndex,
                                zoom: zoom,
                                pan: pan,
                                onMarkerTap: _handleMarkerTap,
                                onMarkerSelected: _handleMarkerSelection,
                                onPathSelected: _handlePathSelection,
                                onZoomChanged: (newZoom) => setState(() => zoom = newZoom),
                                onPanChanged: (newPan) => setState(() => pan = newPan),
                                selectedDrawingTool: _selectedDrawingTool,
                                drawingColor: _drawingColor,
                                strokeWidth: _strokeWidth,
                                onDrawingPathAdded: (path) {
                                  setState(() {
                                    drawingPaths.add(path);
                                  });
                                  _saveSilently();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      // BOTTOM PANEL - PATIENT INFO & ACTIONS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          children: [
                            // PATIENT INFO
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        patient.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                      const Spacer(),
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