// lib/screens/diagnosis/ai_diagnosis_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/marker.dart';
import '../../models/lab_test.dart';
import '../../services/ai_diagnosis_service.dart';

class AIDiagnosisScreen extends StatefulWidget {
  final Patient patient;
  final List<Marker>? kidneyMarkers;
  final Map<String, String>? vitals;
  final List<LabTest>? labResults;

  const AIDiagnosisScreen({
    super.key,
    required this.patient,
    this.kidneyMarkers,
    this.vitals,
    this.labResults,
  });

  @override
  State<AIDiagnosisScreen> createState() => _AIDiagnosisScreenState();
}

class _AIDiagnosisScreenState extends State<AIDiagnosisScreen> {
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _historyController = TextEditingController();

  bool _isLoading = false;
  List<DiagnosisSuggestion> _suggestions = [];
  String? _errorMessage;

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _getDiagnosisSuggestions() async {
    if (_chiefComplaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter chief complaint'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _suggestions = [];
    });

    try {
      // Parse symptoms from text
      final symptoms = _symptomsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      final suggestions = await AIDiagnosisService.getDiagnosisSuggestions(
        patient: widget.patient,
        chiefComplaint: _chiefComplaintController.text,
        vitals: widget.vitals,
        symptoms: symptoms.isEmpty ? null : symptoms,
        kidneyMarkers: widget.kidneyMarkers,
        labResults: widget.labResults,
        patientHistory: _historyController.text.isEmpty
            ? null
            : _historyController.text,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnosis Assistant'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDisclaimerDialog,
            tooltip: 'About AI Assistant',
          ),
        ],
      ),
      body: Column(
        children: [
          // Disclaimer Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Assistant - Not a replacement for clinical judgment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                  // Patient Info Card
                  _buildPatientInfoCard(),
                  const SizedBox(height: 24),

                  // Input Section
                  _buildInputSection(),
                  const SizedBox(height: 24),

                  // Analyze Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getDiagnosisSuggestions,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.psychology),
                      label: Text(_isLoading ? 'Analyzing...' : 'Get AI Suggestions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Results Section
                  if (_suggestions.isNotEmpty) ...[
                    _buildResultsHeader(),
                    const SizedBox(height: 16),
                    ..._suggestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final suggestion = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSuggestionCard(suggestion, index + 1),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    widget.patient.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.patient.age} years • ${widget.patient.phone}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show available data
            if (widget.vitals != null || widget.kidneyMarkers != null || widget.labResults != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Available Data:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.vitals != null)
                    _buildDataChip('Vitals', Icons.favorite, Colors.red),
                  if (widget.kidneyMarkers != null && widget.kidneyMarkers!.isNotEmpty)
                    _buildDataChip('Kidney Imaging', Icons.image, Colors.blue),
                  if (widget.labResults != null && widget.labResults!.isNotEmpty)
                    _buildDataChip('Lab Results', Icons.science, Colors.orange),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clinical Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Chief Complaint
        TextField(
          controller: _chiefComplaintController,
          decoration: InputDecoration(
            labelText: 'Chief Complaint *',
            hintText: 'e.g., Flank pain for 2 days',
            prefixIcon: const Icon(Icons.medical_information),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Symptoms
        TextField(
          controller: _symptomsController,
          decoration: InputDecoration(
            labelText: 'Symptoms (one per line)',
            hintText: 'e.g.,\nSevere left flank pain\nNausea\nHematuria',
            prefixIcon: const Icon(Icons.list),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 4,
        ),
        const SizedBox(height: 16),

        // Medical History
        TextField(
          controller: _historyController,
          decoration: InputDecoration(
            labelText: 'Medical History (optional)',
            hintText: 'Previous conditions, medications, allergies...',
            prefixIcon: const Icon(Icons.history),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        Icon(Icons.psychology, color: Colors.purple.shade700, size: 24),
        const SizedBox(width: 8),
        const Text(
          'AI Diagnosis Suggestions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(DiagnosisSuggestion suggestion, int rank) {
    final urgencyColor = _getUrgencyColor(suggestion.urgency);
    final confidencePercent = (suggestion.confidence * 100).round();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: suggestion.urgency == 'emergency'
              ? Colors.red
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: urgencyColor.withOpacity(0.2),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: urgencyColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suggestion.diagnosis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildConfidenceBar(suggestion.confidence),
                const SizedBox(width: 8),
                Text(
                  '$confidencePercent% confidence',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                suggestion.urgency.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: urgencyColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reasoning
                _buildSectionTitle('Reasoning', Icons.lightbulb_outline),
                Text(
                  suggestion.reasoning,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Supporting Factors
                if (suggestion.supportingFactors.isNotEmpty) ...[
                  _buildSectionTitle('Supporting Factors', Icons.check_circle_outline),
                  ...suggestion.supportingFactors.map((factor) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 8),
                        Expanded(child: Text(factor, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Recommended Tests
                if (suggestion.recommendedTests.isNotEmpty) ...[
                  _buildSectionTitle('Recommended Tests', Icons.science),
                  ...suggestion.recommendedTests.map((test) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_right, size: 16, color: Colors.orange.shade600),
                        const SizedBox(width: 8),
                        Expanded(child: Text(test, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Differential Diagnoses
                if (suggestion.differentialDiagnoses.isNotEmpty) ...[
                  _buildSectionTitle('Differential Diagnoses', Icons.compare),
                  ...suggestion.differentialDiagnoses.map((diagnosis) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(child: Text(diagnosis, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Treatment Suggestions
                if (suggestion.treatmentSuggestions.isNotEmpty) ...[
                  _buildSectionTitle('Treatment Suggestions', Icons.healing),
                  ...suggestion.treatmentSuggestions.map((treatment) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medication, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(child: Text(treatment, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return Container(
      width: 80,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: confidence,
        child: Container(
          decoration: BoxDecoration(
            color: _getConfidenceColor(confidence),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('AI Diagnosis Assistant'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Important Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildDisclaimerPoint(
                '• This AI assistant analyzes patient data to suggest possible diagnoses.',
              ),
              _buildDisclaimerPoint(
                '• Suggestions are based on patterns in medical literature and should be used as a clinical decision support tool.',
              ),
              _buildDisclaimerPoint(
                '• The AI does NOT replace clinical judgment, physical examination, or specialist consultation.',
              ),
              _buildDisclaimerPoint(
                '• Always verify findings with appropriate diagnostic tests.',
              ),
              _buildDisclaimerPoint(
                '• Final diagnosis and treatment decisions must be made by qualified healthcare professionals.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'In case of emergency, seek immediate medical attention.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}