import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

import 'models/patient.dart';
import 'models/marker.dart';
import 'models/visit.dart';
import 'models/condition_tool.dart';
import 'models/drawing_path.dart';
import 'services/voice_command_service.dart';
import 'services/database_helper.dart';
import 'services/multi_image_pdf_service.dart';
import 'widgets/voice_feedback_overlay.dart';
import 'widgets/image_selection_dialog.dart';
import 'screens/patient/visit_history_screen.dart';
import 'widgets/thyroid_canvas.dart';
import 'widgets/thyroid_tool_panel.dart';
import 'widgets/drawing_tool_panel.dart';
import 'services/user_service.dart';

/// Reimagined Thyroid Canvas Screen with Horizontal Carousel
class ThyroidCanvasScreen extends StatefulWidget {
  final Patient patient;
  final Visit? existingVisit;
  final String? preSelectedDiagramType;

  const ThyroidCanvasScreen({
    super.key,
    required this.patient,
    this.existingVisit,
    this.preSelectedDiagramType,
  });

  @override
  State<ThyroidCanvasScreen> createState() => _ThyroidCanvasScreenState();
}

class _ThyroidCanvasScreenState extends State<ThyroidCanvasScreen>
    with SingleTickerProviderStateMixin {
  // Canvas State
  String selectedDiagramId = 'anatomical';
  String selectedDiagramCategory = 'anatomy'; // 'anatomy' or 'disease'
  String selectedTool = 'pan';
  List<Marker> markers = [];
  List<DrawingPath> drawingPaths = [];
  int? selectedMarkerIndex;
  int? selectedPathIndex;
  double zoom = 1.0;
  Offset pan = Offset.zero;

  late Patient patient;
  final GlobalKey _canvasKey = GlobalKey();

  // Voice Commands
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _isVoiceInitialized = false;
  bool _waitingForClick = false;
  String? _pendingToolType;
  double? _pendingToolSize;
  String _voiceStatus = '';

  // Visit Tracking
  int? _currentVisitId;
  int? _originalVisitId;
  bool _isEditingMode = false;

  // Drawing Tools
  String _selectedDrawingTool = 'none';
  Color _drawingColor = Colors.black;
  double _strokeWidth = 3.0;

  // UI State
  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  late TabController _categoryTabController;

  // Carousel Controllers
  final PageController _anatomyCarouselController = PageController(viewportFraction: 0.25);
  final PageController _diseaseCarouselController = PageController(viewportFraction: 0.25);

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
    _categoryTabController = TabController(length: 2, vsync: this);

    if (widget.existingVisit != null) {
      _loadExistingVisit();
    } else if (widget.preSelectedDiagramType != null) {
      selectedDiagramId = widget.preSelectedDiagramType!;
      _loadAnnotations();
    } else {
      selectedDiagramId = 'anatomical';
      _loadAnnotations();
    }

    _initializeVoice();
  }

  void _loadExistingVisit() {
    final visit = widget.existingVisit!;
    setState(() {
      selectedDiagramId = visit.diagramType;
      markers = List<Marker>.from(visit.markers);
      drawingPaths = List<DrawingPath>.from(visit.drawingPaths);
      _originalVisitId = visit.id;
      _currentVisitId = null;
      _isEditingMode = true;
    });
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    setState(() => _isVoiceInitialized = initialized);
    if (!initialized && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice commands not available'),
        ),
      );
    }
  }

  Future<void> _loadAnnotations() async {
    try {
      final visit = await DatabaseHelper.instance.getLatestVisit(
        patientId: patient.id,
        diagramType: selectedDiagramId,
      );

      if (visit != null && mounted) {
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
        id: null,
        patientId: patient.id,
        system: 'thyroid',
        diagramType: selectedDiagramId,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditingMode
                ? 'New edited version created'
                : 'Diagram saved successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
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
        id: null,
        patientId: patient.id,
        system: 'thyroid',
        diagramType: selectedDiagramId,
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
      print('Error saving: $e');
    }
  }

  Future<Uint8List?> _captureCanvas() async {
    try {
      final RenderRepaintBoundary boundary =
      _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing canvas: $e');
      return null;
    }
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

  Future<void> _handlePrintPDF() async {
    try {
      final allVisits = await DatabaseHelper.instance.getAllVisitsForPatient(patient.id);

      if (allVisits.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No diagrams to print'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      final selectedVisits = await showDialog<List<Visit>>(
        context: context,
        builder: (context) => ImageSelectionDialog(visits: allVisits),
      );

      if (selectedVisits == null || selectedVisits.isEmpty) return;

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
              content: Text('PDF generated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
        'selectedSystem': 'thyroid',
      },
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _categoryTabController.dispose();
    _anatomyCarouselController.dispose();
    _diseaseCarouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildAppBar(),
          _buildCarouselSection(),
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    // LEFT PANEL
                    if (_showLeftPanel) _buildLeftPanel(),

                    // MAIN CANVAS
                    Expanded(child: _buildCanvasArea()),

                    // RIGHT PANEL
                    if (_showRightPanel) _buildRightPanel(),
                  ],
                ),
                // VOICE OVERLAY
                VoiceFeedbackOverlay(
                  message: _voiceStatus,
                  isListening: _voiceService.isListening,
                  waitingForClick: _waitingForClick,
                  onCancel: () {
                    setState(() {
                      _waitingForClick = false;
                      _pendingToolType = null;
                      _pendingToolSize = null;
                      _voiceStatus = '';
                    });
                  },
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thyroid Imaging',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Voice Button
            if (_isVoiceInitialized)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _voiceService.isListening
                      ? Colors.red.shade400
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    _voiceService.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    if (_voiceService.isListening) {
                      final result = await _voiceService.stopListening();
                      if (result != null && result.isNotEmpty) {
                        // Handle voice command
                      }
                    } else {
                      setState(() => _voiceStatus = 'Listening...');
                      await _voiceService.startListening();
                    }
                  },
                ),
              ),

            // History Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisitHistoryScreen(
                        patient: patient,
                        diagramType: selectedDiagramId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Category Tabs
          TabBar(
            controller: _categoryTabController,
            indicatorColor: const Color(0xFF1E3A8A),
            labelColor: const Color(0xFF1E3A8A),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(
                icon: Icon(Icons.anatomy, size: 20),
                text: 'Anatomy',
              ),
              Tab(
                icon: Icon(Icons.medical_services, size: 20),
                text: 'Diseases',
              ),
            ],
            onTap: (index) {
              setState(() {
                selectedDiagramCategory = index == 0 ? 'anatomy' : 'disease';
              });
            },
          ),

          // Carousel
          SizedBox(
            height: 140,
            child: TabBarView(
              controller: _categoryTabController,
              children: [
                _buildAnatomyCarousel(),
                _buildDiseaseCarousel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnatomyCarousel() {
    final anatomyDiagrams = [
      DiagramCard(
        id: 'anatomical',
        name: 'Anatomical View',
        imagePath: 'assets/images/thyroid/anatomical.png',
        icon: Icons.view_in_ar,
      ),
      DiagramCard(
        id: 'anterior',
        name: 'Anterior View',
        imagePath: 'assets/images/thyroid/anterior.png',
        icon: Icons.front_hand,
      ),
      DiagramCard(
        id: 'lateral',
        name: 'Lateral View',
        imagePath: 'assets/images/thyroid/lateral.png',
        icon: Icons.view_sidebar,
      ),
      DiagramCard(
        id: 'cross_section',
        name: 'Cross Section',
        imagePath: 'assets/images/thyroid/cross_section.png',
        icon: Icons.layers,
      ),
      DiagramCard(
        id: 'ultrasound',
        name: 'Ultrasound Guide',
        imagePath: 'assets/images/thyroid/ultrasound.png',
        icon: Icons.sensors,
      ),
    ];

    return _buildDiagramCarousel(anatomyDiagrams, _anatomyCarouselController);
  }

  Widget _buildDiseaseCarousel() {
    final diseaseDiagrams = [
      DiagramCard(
        id: 'goiter',
        name: 'Goiter',
        imagePath: 'assets/images/thyroid/diseases/goiter.png',
        icon: Icons.warning_amber,
      ),
      DiagramCard(
        id: 'nodules',
        name: 'Thyroid Nodules',
        imagePath: 'assets/images/thyroid/diseases/nodules.png',
        icon: Icons.circle,
      ),
      DiagramCard(
        id: 'hashimoto',
        name: "Hashimoto's",
        imagePath: 'assets/images/thyroid/diseases/hashimoto.png',
        icon: Icons.healing,
      ),
      DiagramCard(
        id: 'graves',
        name: "Graves' Disease",
        imagePath: 'assets/images/thyroid/diseases/graves.png',
        icon: Icons.local_fire_department,
      ),
      DiagramCard(
        id: 'cancer',
        name: 'Thyroid Cancer',
        imagePath: 'assets/images/thyroid/diseases/cancer.png',
        icon: Icons.coronavirus,
      ),
    ];

    return _buildDiagramCarousel(diseaseDiagrams, _diseaseCarouselController);
  }

  Widget _buildDiagramCarousel(List<DiagramCard> diagrams, PageController controller) {
    return PageView.builder(
      controller: controller,
      itemCount: diagrams.length,
      itemBuilder: (context, index) {
        final diagram = diagrams[index];
        final isSelected = selectedDiagramId == diagram.id;

        return GestureDetector(
          onTap: () async {
            if (markers.isNotEmpty || drawingPaths.isNotEmpty) {
              await _saveAnnotations();
            }

            setState(() {
              selectedDiagramId = diagram.id;
              markers = [];
              drawingPaths = [];
              selectedMarkerIndex = null;
              selectedPathIndex = null;
              _currentVisitId = null;
            });

            await _loadAnnotations();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image or Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A8A).withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    diagram.icon,
                    size: 32,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  diagram.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 18, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Annotation Tools',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _showLeftPanel = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ThyroidToolPanel(
                    selectedTool: selectedTool,
                    onToolSelected: (tool, type, size) {
                      setState(() {
                        selectedTool = tool;
                        if (tool == 'marker') {
                          _waitingForClick = true;
                          _pendingToolType = type;
                          _pendingToolSize = size;
                        }
                      });
                    },
                    onDeleteMarker: selectedMarkerIndex != null
                        ? () {
                      setState(() {
                        markers.removeAt(selectedMarkerIndex!);
                        selectedMarkerIndex = null;
                      });
                      _saveSilently();
                    }
                        : null,
                    onClearAll: markers.isNotEmpty
                        ? () {
                      setState(() {
                        markers.clear();
                        selectedMarkerIndex = null;
                      });
                      _saveSilently();
                    }
                        : null,
                    markerCount: markers.length,
                  ),
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
                    onDeletePath: selectedPathIndex != null
                        ? () {
                      setState(() {
                        drawingPaths.removeAt(selectedPathIndex!);
                        selectedPathIndex = null;
                      });
                      _saveSilently();
                    }
                        : null,
                    onClearAll: drawingPaths.isNotEmpty
                        ? () {
                      setState(() {
                        drawingPaths.clear();
                        selectedPathIndex = null;
                      });
                      _saveSilently();
                    }
                        : null,
                    pathCount: drawingPaths.length,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _showRightPanel = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    'Patient Information',
                    [
                      _buildInfoRow('Name', patient.name),
                      _buildInfoRow('ID', patient.id),
                      _buildInfoRow('Age', '${patient.age ?? 'N/A'} years'),
                      _buildInfoRow('Gender', patient.gender ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    'Current Session',
                    [
                      _buildInfoRow('Diagram', _getDiagramName()),
                      _buildInfoRow('Markers', '${markers.length}'),
                      _buildInfoRow('Drawings', '${drawingPaths.length}'),
                      _buildInfoRow(
                          'Status', _isEditingMode ? 'Editing' : 'New'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuickTips(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'Quick Tips',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTipItem('Scroll through diagrams in the carousel'),
          _buildTipItem('Use markers to annotate findings'),
          _buildTipItem('Draw free-form annotations'),
          _buildTipItem('Changes auto-save'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue.shade700)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Column(
      children: [
        // Toggle Buttons
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              if (!_showLeftPanel)
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _showLeftPanel = true),
                  tooltip: 'Show Tools',
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      '${(zoom * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_showRightPanel)
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _showRightPanel = true),
                  tooltip: 'Show Info',
                ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RepaintBoundary(
                key: _canvasKey,
                child: ThyroidCanvas(
                  selectedPreset: selectedDiagramId,
                  selectedTool: selectedTool,
                  markers: markers,
                  drawingPaths: drawingPaths,
                  selectedMarkerIndex: selectedMarkerIndex,
                  selectedPathIndex: selectedPathIndex,
                  zoom: zoom,
                  pan: pan,
                  onMarkerTap: _handleMarkerTap,
                  onMarkerSelected: (index) {
                    setState(() {
                      if (selectedMarkerIndex == index) {
                        selectedMarkerIndex = null;
                      } else {
                        selectedMarkerIndex = index;
                        selectedPathIndex = null;
                      }
                    });
                  },
                  onPathSelected: (index) {
                    setState(() {
                      if (selectedPathIndex == index) {
                        selectedPathIndex = null;
                      } else {
                        selectedPathIndex = index;
                        selectedMarkerIndex = null;
                      }
                    });
                  },
                  onZoomChanged: (newZoom) => setState(() => zoom = newZoom),
                  onPanChanged: (newPan) => setState(() => pan = newPan),
                  selectedDrawingTool: _selectedDrawingTool,
                  drawingColor: _drawingColor,
                  strokeWidth: _strokeWidth,
                  onDrawingPathAdded: (path) {
                    setState(() => drawingPaths.add(path));
                    _saveSilently();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Clear Button
          OutlinedButton.icon(
            onPressed: (markers.isEmpty && drawingPaths.isEmpty)
                ? null
                : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All?'),
                  content: const Text(
                      'This will remove all markers and drawings.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          markers.clear();
                          drawingPaths.clear();
                          selectedMarkerIndex = null;
                          selectedPathIndex = null;
                        });
                        Navigator.pop(context);
                        _saveSilently();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.shade300),
            ),
          ),

          Row(
            children: [
              // PDF Button
              ElevatedButton.icon(
                onPressed: _handlePrintPDF,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Generate PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(width: 12),

              // Save Button
              ElevatedButton.icon(
                onPressed: (markers.isEmpty && drawingPaths.isEmpty)
                    ? null
                    : _saveAnnotations,
                icon: const Icon(Icons.save, size: 18),
                label: Text(_isEditingMode ? 'Update' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 12),

              // Proceed Button
              ElevatedButton.icon(
                onPressed: _proceedToConsultation,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Consultation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDiagramName() {
    final diagrams = {
      'anatomical': 'Anatomical View',
      'anterior': 'Anterior View',
      'lateral': 'Lateral View',
      'cross_section': 'Cross Section',
      'ultrasound': 'Ultrasound Guide',
      'goiter': 'Goiter',
      'nodules': 'Thyroid Nodules',
      'hashimoto': "Hashimoto's",
      'graves': "Graves' Disease",
      'cancer': 'Thyroid Cancer',
    };
    return diagrams[selectedDiagramId] ?? selectedDiagramId;
  }
}

// Helper class for diagram cards
class DiagramCard {
  final String id;
  final String name;
  final String imagePath;
  final IconData icon;

  DiagramCard({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.icon,
  });
}