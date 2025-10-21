// lib/screens/consultation/three_page_consultation_screen.dart
// ✅ WITH: No data reset + Edit button + Confirmation prompt

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/patient.dart';
import '../../models/consultation_data.dart';
import '../../services/database_helper.dart';
import '../../services/consultation_pdf_service.dart';
import '../pdf/pdf_viewer_screen.dart';
import '../pdf/pdf_viewer_screen.dart';  // For ThreePagePDFViewer
import 'page1_patient_data_entry.dart';
import 'page2_system_selector.dart';
import 'page3_diagnosis_treatment.dart';

class ThreePageConsultationScreen extends StatefulWidget {
  final Patient patient;

  const ThreePageConsultationScreen({
    super.key,
    required this.patient,
  });

  @override
  State<ThreePageConsultationScreen> createState() => _ThreePageConsultationScreenState();
}

class _ThreePageConsultationScreenState extends State<ThreePageConsultationScreen> {
  late PageController _pageController;
  late ConsultationData consultationData;
  int _currentPage = 0;
  bool _isLoadingDraft = true;
  String? _generatedPdfPath; // ✅ Store PDF path

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    consultationData = ConsultationData(patient: widget.patient);
    _pageController.addListener(_onPageChanged);
    _loadDraftData();
  }

  Future<void> _loadDraftData() async {
    setState(() => _isLoadingDraft = true);

    try {
      final draft = await DatabaseHelper.instance.loadDraftConsultation(
        widget.patient.id,
      );

      if (draft != null && mounted) {
        final shouldLoad = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.restore, color: Colors.blue.shade700),
                SizedBox(width: 12),
                Text('Draft Found'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A draft consultation was found for this patient.'),
                SizedBox(height: 12),
                if (draft['lastSaved'] != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Last saved: ${_formatDateTime(DateTime.parse(draft['lastSaved']))}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                Text(
                  'Would you like to continue from where you left off?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Start Fresh'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: Icon(Icons.restore),
                label: Text('Continue Draft'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (shouldLoad == true) {
          consultationData.loadFromDraft(draft);
        } else {
          await DatabaseHelper.instance.deleteDraftConsultation(widget.patient.id);
        }
      }
    } catch (e) {
      print('Error loading draft: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDraft = false);
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (_pageController.page != null) {
      final newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ✅ FEATURE 3: Confirmation when leaving Page 2
  void _nextPage() async {
    if (_currentPage == 1) {
      // Show confirmation dialog for Page 2
      final shouldContinue = await _showPage2Confirmation();
      if (shouldContinue != true) return;
    }

    if (_currentPage < 2) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  // ✅ FEATURE 3: Page 2 Confirmation Dialog
  Future<bool?> _showPage2Confirmation() async {
    final templateCount = consultationData.selectedTemplateIds.length;
    final anatomyCount = consultationData.selectedAnatomies.length;

    // Get saved diagrams count from Page 2 state
    final visits = await DatabaseHelper.instance.getAllVisitsForPatient(
      patientId: consultationData.patient.id,
    );
    final diagramCount = visits.where((v) => v.canvasImage != null).length;

    final totalSelections = templateCount + anatomyCount + diagramCount;

    if (totalSelections == 0) {
      return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700),
              SizedBox(width: 8),
              Text('No Items Selected'),
            ],
          ),
          content: Text(
            'You haven\'t selected any diagrams, templates, or anatomy views. '
                'These won\'t be included in the PDF report.\n\n'
                'Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            SizedBox(width: 8),
            Text('Ready to Create Treatment Plan?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have selected:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (diagramCount > 0)
              _buildConfirmationRow(
                Icons.photo_library,
                '$diagramCount Saved Kidney Diagram${diagramCount == 1 ? '' : 's'}',
                Colors.blue,
              ),
            if (templateCount > 0)
              _buildConfirmationRow(
                Icons.medical_information,
                '$templateCount Disease Template${templateCount == 1 ? '' : 's'}',
                Colors.purple,
              ),
            if (anatomyCount > 0)
              _buildConfirmationRow(
                Icons.category,
                '$anatomyCount Anatomy Diagram${anatomyCount == 1 ? '' : 's'}',
                Colors.teal,
              ),
            SizedBox(height: 12),
            Text(
              'These will be included in the final PDF report.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: Icon(Icons.arrow_back),
            label: Text('Go Back'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: Icon(Icons.arrow_forward),
            label: Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Color _getPageColor(int pageIndex) {
    switch (pageIndex) {
      case 0: return Colors.blue.shade700;
      case 1: return Colors.purple.shade700;
      case 2: return Colors.green.shade700;
      default: return Colors.grey.shade700;
    }
  }

  String _getPageTitle(int pageIndex) {
    switch (pageIndex) {
      case 0: return 'Patient Data';
      case 1: return 'System Selection';
      case 2: return 'Diagnosis & Treatment';
      default: return '';
    }
  }

  IconData _getPageIcon(int pageIndex) {
    switch (pageIndex) {
      case 0: return Icons.person;
      case 1: return Icons.medical_services;
      case 2: return Icons.assignment;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDraft) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading consultation...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: consultationData,
      child: WillPopScope(
        onWillPop: () async {
          // ✅ FEATURE 1: Confirm before exiting
          return await _confirmExit();
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildPageIndicators(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Page1PatientDataEntry(),
                    Page2SystemSelector(),
                    Page3DiagnosisTreatment(),
                  ],
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FEATURE 1: Confirm exit
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Consultation?'),
        content: Text(
          _generatedPdfPath != null
              ? 'PDF has been generated. Exit and delete draft?'
              : 'Your progress is auto-saved. Exit consultation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == true && _generatedPdfPath != null) {
      // Delete draft only when exiting after PDF generation
      await DatabaseHelper.instance.deleteDraftConsultation(widget.patient.id);
    }

    return result ?? false;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () async {
          if (await _confirmExit()) {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.patient.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      backgroundColor: _getPageColor(_currentPage),
      foregroundColor: Colors.white,
      actions: [
        // Completion percentage
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Consumer<ConsultationData>(
              builder: (context, data, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${data.completionPercentage.toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(child: _buildPageIndicator(i)),
            if (i < 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: _currentPage > i ? _getPageColor(i) : Colors.grey.shade400,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageIndex) {
    final isActive = _currentPage == pageIndex;
    final isCompleted = _isPageCompleted(pageIndex);
    final pageColor = _getPageColor(pageIndex);

    return GestureDetector(
      onTap: () => _goToPage(pageIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? pageColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? pageColor : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : (isActive ? pageColor : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Icon(_getPageIcon(pageIndex), color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getPageTitle(pageIndex),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? pageColor : Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isPageCompleted(int pageIndex) {
    switch (pageIndex) {
      case 0: return consultationData.isPage1Complete;
      case 1: return consultationData.isPage2Complete;
      case 2: return consultationData.isPage3Complete;
      default: return false;
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentPage > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousPage,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: _getPageColor(_currentPage)),
                    foregroundColor: _getPageColor(_currentPage),
                  ),
                ),
              ),
            if (_currentPage > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _currentPage < 2 ? _nextPage : _onFinish,
                icon: Icon(_currentPage < 2 ? Icons.arrow_forward : Icons.check),
                label: Text(_currentPage < 2 ? 'Next Page' : 'Generate PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getPageColor(_currentPage),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onFinish() {
    if (!consultationData.canGeneratePDF) {
      _showIncompleteDialog();
      return;
    }
    _generatePDF();
  }

  void _showIncompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Incomplete Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please complete the following:'),
            const SizedBox(height: 12),
            if (!consultationData.isPage1Complete)
              _buildRequirementItem('Page 1: Enter vitals and chief complaint'),
            if (!consultationData.isPage2Complete)
              _buildRequirementItem('Page 2: Select at least one template or diagram'),
            if (!consultationData.isPage3Complete)
              _buildRequirementItem('Page 3: Enter diagnosis'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Generating PDF...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'consultation_${widget.patient.id}_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';

      await ConsultationPDFService.generateConsultationPDF(
        consultationData,
        filePath,
      );

      // ✅ FEATURE 1: Store PDF path but DON'T delete draft yet
      setState(() {
        _generatedPdfPath = filePath;
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('PDF Generated Successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => _viewPDF(),
            ),
          ),
        );

        // Automatically open PDF viewer
        await _viewPDF();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ CORRECTED _viewPDF() method
  Future<void> _viewPDF() async {
    if (_generatedPdfPath == null) return;

    final pdfBytes = await File(_generatedPdfPath!).readAsBytes();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreePagePDFViewer(
          pdfBytes: pdfBytes,
          title: 'Consultation - ${widget.patient.name}',
          onEditPressed: () {
            Navigator.pop(context); // Close PDF viewer
            // Stay in consultation screen for editing
          },
        ),
      ),
    );
  }
}