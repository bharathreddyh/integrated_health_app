// ==================== AI PDF GENERATOR BUTTON WIDGET ====================
// lib/widgets/ai_pdf_generator_button.dart
// ✅ Beautiful UI widget for AI PDF generation
// ✅ Progress indicators and animations
// ✅ Success dialog with open/share options

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/endocrine/endocrine_condition.dart';
import '../models/patient.dart';
import '../services/ai_medical_report_service.dart';

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

class _AIPDFGeneratorButtonState extends State<AIPDFGeneratorButton> {
  bool _isGenerating = false;
  String _currentStep = '';
  String? _generatedPdfPath;

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _buildLoadingState();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateAIPDF,
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'Generate AI Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          // Animated progress indicator
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
                Icon(
                  Icons.auto_awesome,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Current step
          Text(
            _currentStep,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Progress steps
          _buildProgressSteps(),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {'icon': Icons.folder_open, 'label': 'Collecting Data'},
      {'icon': Icons.psychology, 'label': 'AI Processing'},
      {'icon': Icons.picture_as_pdf, 'label': 'Generating PDF'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = _currentStep.toLowerCase().contains(step['label'].toString().toLowerCase());

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue.shade600 : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                step['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step['label'] as String,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.blue.shade900 : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _generateAIPDF() async {
    setState(() {
      _isGenerating = true;
      _currentStep = 'Collecting data from all tabs...';
    });

    try {
      // Generate AI-powered PDF
      final pdfPath = await AIMedicalReportService.generateAIPoweredReport(
        condition: widget.condition,
        patient: widget.patient,
        onProgress: (step) {
          if (mounted) {
            setState(() {
              _currentStep = step;
            });
          }
        },
      );

      setState(() {
        _generatedPdfPath = pdfPath;
        _isGenerating = false;
      });

      // Show success dialog
      if (mounted) {
        _showSuccessDialog();
        widget.onSuccess?.call();
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // Success title
              const Text(
                'Report Generated Successfully!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Success message
              Text(
                'Your AI-powered medical report is ready to view.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (_generatedPdfPath != null) {
                          await Share.shareXFiles([XFile(_generatedPdfPath!)]);
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (_generatedPdfPath != null) {
                          await OpenFile.open(_generatedPdfPath!);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Generation Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Failed to generate AI report:'),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAIPDF();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}