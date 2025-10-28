// lib/widgets/ai_pdf_generator_button.dart
// 🤖 UI COMPONENT FOR AI-POWERED PDF GENERATION
// Beautiful loading states, progress tracking, and PDF viewing

import 'package:flutter/material.dart';
import 'dart:io';
import '../services/ai_medical_report_service.dart';
import '../models/endocrine/endocrine_condition.dart';
import '../models/patient.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class AIPDFGeneratorButton extends StatefulWidget {
  final EndocrineCondition condition;
  final Patient patient;
  final VoidCallback? onSuccess;

  const AIPDFGeneratorButton({
    super.key,
    required this.condition,
    required this.patient,
    this.onSuccess,
  });

  @override
  State<AIPDFGeneratorButton> createState() => _AIPDFGeneratorButtonState();
}

class _AIPDFGeneratorButtonState extends State<AIPDFGeneratorButton>
    with SingleTickerProviderStateMixin {
  bool _isGenerating = false;
  String _currentStep = '';
  double _progress = 0.0;
  late AnimationController _animationController;
  String? _generatedPdfPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateAIPDF() async {
    setState(() {
      _isGenerating = true;
      _currentStep = 'Initializing AI analysis...';
      _progress = 0.1;
    });

    try {
      // Step 1: Data collection
      setState(() {
        _currentStep = 'Collecting data from all tabs...';
        _progress = 0.3;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: AI processing
      setState(() {
        _currentStep = 'Processing with Claude AI...';
        _progress = 0.6;
      });

      // Generate the report
      final pdfPath = await AIMedicalReportService.generateAIPoweredReport(
        condition: widget.condition,
        patient: widget.patient,
      );

      // Step 3: PDF generation
      setState(() {
        _currentStep = 'Generating PDF document...';
        _progress = 0.9;
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Complete
      setState(() {
        _currentStep = 'Complete!';
        _progress = 1.0;
        _generatedPdfPath = pdfPath;
      });

      // Show success dialog
      await Future.delayed(const Duration(milliseconds: 500));
      _showSuccessDialog(pdfPath);

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
        _currentStep = '';
        _progress = 0.0;
      });
    }
  }

  void _showSuccessDialog(String pdfPath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Report Generated!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your AI-powered medical report has been successfully generated.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Medical Report',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pdfPath.split('/').last,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _sharePDF(pdfPath),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openPDF(pdfPath),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Generation Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to generate the AI-powered report.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.red.shade900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateAIPDF();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPDF(String pdfPath) async {
    try {
      final result = await OpenFile.open(pdfPath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open PDF: ${result.message}'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _sharePDF(String pdfPath) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'AI Medical Report - ${widget.patient.name}',
        text: 'AI-powered medical report generated by Clinic Clarity Suite',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _buildLoadingView();
    }

    return _buildGenerateButton();
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateAIPDF,
        icon: const Icon(Icons.auto_awesome, size: 24),
        label: const Text(
          'Generate AI-Powered Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated AI Icon
          RotationTransition(
            turns: _animationController,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.indigo.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Progress text
          Text(
            _currentStep,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 8),

          // Progress percentage
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator('Data', _progress >= 0.3),
              const SizedBox(width: 8),
              _buildStepIndicator('AI', _progress >= 0.6),
              const SizedBox(width: 8),
              _buildStepIndicator('PDF', _progress >= 0.9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(String label, bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green.shade400 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isComplete ? Colors.green.shade700 : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isComplete ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}