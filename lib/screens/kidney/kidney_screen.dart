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
import '../../services/voice_command_service.dart';
import '../../services/database_helper.dart';
import '../../widgets/voice_feedback_overlay.dart';
import '../patient/visit_history_screen.dart';
import '../prescription/prescription_management_screen.dart';
import 'widgets/kidney_canvas.dart';
import 'widgets/tool_panel.dart';
import 'pdf_preview_screen.dart';

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
  int? selectedMarkerIndex;
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
    _initializeVoice();
    _loadAnnotations();
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

      if (visit != null && mounted) {
        setState(() {
          markers = List<Marker>.from(visit.markers);
          _currentVisitId = visit.id;
        });
      }
    } catch (e) {
      print('Error loading visit: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    try {
      final visit = Visit(
        id: _currentVisitId,
        patientId: patient.id,
        diagramType: selectedPreset,
        markers: markers,
        notes: null,
        createdAt: DateTime.now(),
      );

      if (_currentVisitId == null) {
        final id = await DatabaseHelper.instance.createVisit(visit);
        setState(() {
          _currentVisitId = id;
        });
      } else {
        await DatabaseHelper.instance.updateVisit(visit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
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
      final visit = Visit(
        id: _currentVisitId,
        patientId: patient.id,
        diagramType: selectedPreset,
        markers: markers,
        notes: null,
        createdAt: DateTime.now(),
      );

      if (_currentVisitId == null) {
        final id = await DatabaseHelper.instance.createVisit(visit);
        _currentVisitId = id;
      } else {
        await DatabaseHelper.instance.updateVisit(visit);
      }
    } catch (e) {
      print('Error saving: $e');
    }
  }

  Future<void> _openPrescriptions() async {
    if (_currentVisitId == null && markers.isNotEmpty) {
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

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  final List<ConditionTool> tools = const [
    ConditionTool(
      id: 'pan',
      name: 'Pan Tool',
      color: Colors.grey,
      defaultSize: 0,
    ),
    ConditionTool(
      id: 'calculi',
      name: 'Calculi',
      color: Colors.grey,
      defaultSize: 8,
    ),
    ConditionTool(
      id: 'cyst',
      name: 'Cyst',
      color: Color(0xFF2563EB),
      defaultSize: 12,
    ),
    ConditionTool(
      id: 'tumor',
      name: 'Tumor',
      color: Color(0xFF7C2D12),
      defaultSize: 16,
    ),
    ConditionTool(
      id: 'inflammation',
      name: 'Inflammation',
      color: Color(0xFFEA580C),
      defaultSize: 14,
    ),
    ConditionTool(
      id: 'blockage',
      name: 'Blockage',
      color: Color(0xFF9333EA),
      defaultSize: 10,
    ),
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
        _executeGenerateSummary();
        break;
      case CommandType.unknown:
        break;
    }
  }

  void _executeNavigationCommand(VoiceCommand command) async {
    final preset = command.parameters['preset'] as String?;
    if (preset != null && presets.containsKey(preset)) {
      if (markers.isNotEmpty) {
        await _saveAnnotations();
      }

      setState(() {
        selectedPreset = preset;
        markers.clear();
        selectedMarkerIndex = null;
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
        markers.removeAt(index);
        selectedMarkerIndex = null;
      });
    } else {
      setState(() {
        selectedMarkerIndex = index;
      });
    }
  }

  void _executeGenerateSummary() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final canvasImage = await _captureCanvas();

    if (mounted) Navigator.pop(context);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFPreviewScreen(
            patient: patient,
            markers: markers,
            canvasImage: canvasImage,
            visitId: _currentVisitId, // FIXED: Pass visit ID
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Stack(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 280,
                  child: ToolPanel(
                    tools: tools,
                    selectedTool: selectedTool,
                    onToolSelected: (tool) {
                      setState(() {
                        selectedTool = tool;
                      });
                    },
                    markers: markers,
                    selectedMarkerIndex: selectedMarkerIndex,
                    onMarkerDeleted: () {
                      if (selectedMarkerIndex != null) {
                        setState(() {
                          markers.removeAt(selectedMarkerIndex!);
                          selectedMarkerIndex = null;
                        });
                      }
                    },
                    onMarkerLabelChanged: (newLabel) {
                      if (selectedMarkerIndex != null) {
                        setState(() {
                          markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(label: newLabel);
                        });
                      }
                    },
                    onMarkerSizeChanged: (newSize) {
                      if (selectedMarkerIndex != null) {
                        setState(() {
                          markers[selectedMarkerIndex!] = markers[selectedMarkerIndex!].copyWith(size: newSize);
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
                    onClearAll: () {
                      setState(() {
                        markers.clear();
                        selectedMarkerIndex = null;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      // HEADER - Rx button removed from here
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
                                if (markers.isNotEmpty) {
                                  await _saveAnnotations();
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
                                  const Text(
                                    'Kidney Diagram Tool',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                value: selectedPreset,
                                decoration: const InputDecoration(
                                  labelText: 'Select Diagram',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: presets.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value, style: const TextStyle(fontSize: 12)),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value != null) {
                                    if (markers.isNotEmpty) {
                                      await _saveAnnotations();
                                    }

                                    setState(() {
                                      selectedPreset = value;
                                      markers.clear();
                                      selectedMarkerIndex = null;
                                    });

                                    await _loadAnnotations();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: markers.isEmpty ? null : _saveAnnotations,
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('Save', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                          ],
                        ),
                      ),

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
                                    selectedMarkerIndex: selectedMarkerIndex,
                                    selectedTool: selectedTool,
                                    tools: tools,
                                    zoom: zoom,
                                    pan: pan,
                                    waitingForClick: _waitingForClick,
                                    pendingToolType: _pendingToolType,
                                    pendingToolSize: _pendingToolSize,
                                    onMarkerAdded: (marker) {
                                      setState(() {
                                        markers.add(marker);
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
                                        markers[index] = markers[index].copyWith(
                                          x: newRelativePosition.dx,
                                          y: newRelativePosition.dy,
                                        );
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
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // FOOTER - FIXED: Rx button added here
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
                                        'Age: ${patient.age}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Phone: ${patient.phone}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(width: 24),
                                      Text(
                                        'Date: ${patient.date}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  if (patient.conditions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: patient.conditions.map((condition) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCEAFE),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            condition,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF1E40AF),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // FIXED: Rx button moved here (footer)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _openPrescriptions,
                                  icon: const Icon(Icons.medication, size: 16),
                                  label: const Text('Prescriptions'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF14B8A6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_currentVisitId == null) {
                                      await _saveSilently();
                                    }

                                    if (_currentVisitId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to create visit')),
                                      );
                                      return;
                                    }

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );

                                    final freshPatient = await DatabaseHelper.instance.getPatient(patient.id);

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Vitals loaded: ${freshPatient?.vitals != null ? "YES" : "NO"}'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }

                                    final canvasImage = await _captureCanvas();

                                    if (context.mounted) Navigator.pop(context);

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PDFPreviewScreen(
                                            patient: freshPatient ?? patient,
                                            markers: markers,
                                            canvasImage: canvasImage,
                                            visitId: _currentVisitId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.description, size: 16),
                                  label: const Text('Generate Summary'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
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
}