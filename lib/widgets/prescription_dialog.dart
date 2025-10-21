// lib/widgets/prescription_dialog.dart

import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../services/whisper_voice_service.dart';

class PrescriptionDialog extends StatefulWidget {
  final Prescription? prescription; // For editing existing prescription

  const PrescriptionDialog({
    super.key,
    this.prescription,
  });

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _medicationController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;

  String _selectedFrequency = 'Once daily';
  String _selectedDuration = '7 days';
  String? _activeVoiceField;

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As needed (SOS)',
    'Before meals',
    'After meals',
    'At bedtime',
  ];

  final List<String> _durations = [
    '3 days',
    '5 days',
    '7 days',
    '10 days',
    '14 days',
    '21 days',
    '30 days',
    '2 months',
    '3 months',
    '6 months',
    'Ongoing',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if editing
    _medicationController = TextEditingController(
      text: widget.prescription?.medicationName ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.prescription?.dosage ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.prescription?.instructions ?? '',
    );

    if (widget.prescription != null) {
      _selectedFrequency = widget.prescription!.frequency;
      _selectedDuration = widget.prescription!.duration;
    }
  }

  void _startVoiceDictation(String fieldName, TextEditingController controller) {
    setState(() {
      _activeVoiceField = fieldName;
    });

    final voiceService = WhisperVoiceService.instance;
    voiceService.onTranscription = (transcription) {
      if (_activeVoiceField == fieldName && mounted) {
        setState(() {
          controller.text = transcription;
          _activeVoiceField = null;
        });
      }
    };

    voiceService.startListening();
  }

  void _savePrescription() {
    if (_formKey.currentState!.validate()) {
      final prescription = Prescription(
        id: widget.prescription?.id,
        visitId: 0, // Will be set later
        patientId: '', // Will be set later
        medicationName: _medicationController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _selectedFrequency,
        duration: _selectedDuration,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        createdAt: widget.prescription?.createdAt ?? DateTime.now(),
      );

      Navigator.pop(context, prescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.prescription != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.medication,
            color: Colors.teal.shade700,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'Edit Medication' : 'Add Medication'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medication Name
                _buildTextField(
                  controller: _medicationController,
                  label: 'Medication Name',
                  hint: 'e.g., Paracetamol',
                  icon: Icons.medical_services,
                  fieldName: 'medication',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dosage
                _buildTextField(
                  controller: _dosageController,
                  label: 'Dosage',
                  hint: 'e.g., 500mg or 1 tablet',
                  icon: Icons.colorize,
                  fieldName: 'dosage',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter dosage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: Icon(Icons.schedule, color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                  ),
                  items: _frequencies.map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFrequency = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Duration Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedDuration,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.teal.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.teal.shade50,
                  ),
                  items: _durations.map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Instructions (Optional)
                _buildTextField(
                  controller: _instructionsController,
                  label: 'Instructions (Optional)',
                  hint: 'e.g., Take with food, avoid alcohol',
                  icon: Icons.info_outline,
                  fieldName: 'instructions',
                  maxLines: 3,
                  isRequired: false,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _savePrescription,
          icon: const Icon(Icons.check),
          label: Text(isEditing ? 'Update' : 'Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String fieldName,
    int maxLines = 1,
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _startVoiceDictation(fieldName, controller),
              icon: Icon(
                _activeVoiceField == fieldName ? Icons.mic : Icons.mic_none,
                color: _activeVoiceField == fieldName ? Colors.red : Colors.teal,
                size: 20,
              ),
              tooltip: 'Voice Dictation',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.teal.shade700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.teal.shade50,
          ),
          validator: isRequired ? validator : null,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}