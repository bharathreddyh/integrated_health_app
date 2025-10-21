// ==================== TAB 1: OVERVIEW ====================
// lib/screens/endocrine/tabs/overview_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';

class OverviewTab extends StatelessWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const OverviewTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease Information Card
          _buildDiseaseInformationCard(),
          const SizedBox(height: 20),

          // Diagnosis Status Card
          _buildDiagnosisStatusCard(context),
          const SizedBox(height: 20),

          // Diagnostic Criteria Card
          _buildDiagnosticCriteriaCard(context),
          const SizedBox(height: 20),

          // Severity Card (if applicable)
          if (_showSeverity()) ...[
            _buildSeverityCard(context),
            const SizedBox(height: 20),
          ],

          // Complications Card
          _buildComplicationsCard(context),
          const SizedBox(height: 20),

          // Clinical Notes Card
          _buildNotesCard(context),
        ],
      ),
    );
  }

  Widget _buildDiseaseInformationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 12),
                Text(
                  'DISEASE INFORMATION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for anatomy diagram
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🦋',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thyroid Gland Anatomy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '(Diagram placeholder)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Disease description
            const Text(
              'What is this condition?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              diseaseConfig.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            if (diseaseConfig.icd10 != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ICD-10: ${diseaseConfig.icd10}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisStatusCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIAGNOSIS STATUS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Status Radio Buttons
            _buildStatusOption(
              context,
              DiagnosisStatus.suspected,
              'Suspected',
              'Pending confirmatory tests',
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              DiagnosisStatus.confirmed,
              'Confirmed',
              'Diagnosis confirmed by investigations',
            ),
            const SizedBox(height: 12),
            _buildStatusOption(
              context,
              DiagnosisStatus.ruledOut,
              'Ruled Out',
              'Diagnosis excluded',
            ),
            const SizedBox(height: 20),

            // Diagnosis Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 12),
                const Text(
                  'Date of Diagnosis:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  condition.diagnosisDate != null
                      ? _formatDate(condition.diagnosisDate!)
                      : 'Not set',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _selectDiagnosisDate(context),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
      BuildContext context,
      DiagnosisStatus status,
      String title,
      String subtitle,
      ) {
    final isSelected = condition.status == status;

    return InkWell(
      onTap: () {
        onUpdate(condition.copyWith(status: status));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<DiagnosisStatus>(
              value: status,
              groupValue: condition.status,
              onChanged: (value) {
                if (value != null) {
                  onUpdate(condition.copyWith(status: value));
                }
              },
              activeColor: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticCriteriaCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DIAGNOSTIC CRITERIA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildCriteriaCheckbox(
              'Clinical features present',
              Icons.medical_services,
            ),
            _buildCriteriaCheckbox(
              'Laboratory tests consistent',
              Icons.science,
            ),
            _buildCriteriaCheckbox(
              'Imaging studies done',
              Icons.camera_alt,
            ),
            _buildCriteriaCheckbox(
              'Specialist consultation obtained',
              Icons.person,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaCheckbox(String text, IconData icon) {
    // TODO: Store checkbox state properly
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Checkbox(
            value: false, // TODO: Make this functional
            onChanged: (value) {
              // TODO: Update state
            },
            activeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEVERITY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildSeverityOption(context, DiseaseSeverity.mild, 'Mild'),
            _buildSeverityOption(context, DiseaseSeverity.moderate, 'Moderate'),
            _buildSeverityOption(context, DiseaseSeverity.severe, 'Severe'),
            _buildSeverityOption(context, DiseaseSeverity.critical, 'Critical'),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityOption(BuildContext context, DiseaseSeverity severity, String label) {
    final isSelected = condition.severity == severity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          onUpdate(condition.copyWith(severity: severity));
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _getSeverityColor(severity).withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? _getSeverityColor(severity) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Radio<DiseaseSeverity>(
                value: severity,
                groupValue: condition.severity,
                onChanged: (value) {
                  if (value != null) {
                    onUpdate(condition.copyWith(severity: value));
                  }
                },
                activeColor: _getSeverityColor(severity),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplicationsCard(BuildContext context) {
    final complications = diseaseConfig.complications;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COMPLICATIONS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            if (complications != null && complications.isNotEmpty)
              ...complications.map((comp) => _buildComplicationCheckbox(comp as String))
            else
              Text(
                'No complications listed for this condition',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplicationCheckbox(String complication) {
    // TODO: Store in actual state
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 20, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              complication,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Checkbox(
            value: false, // TODO: Make functional
            onChanged: (value) {
              // TODO: Update state
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CLINICAL NOTES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 6,
              controller: TextEditingController(text: condition.notes),
              decoration: InputDecoration(
                hintText: 'Enter clinical notes, observations, or additional information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                onUpdate(condition.copyWith(notes: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _showSeverity() {
    // Show severity for most conditions except subclinical ones
    return !condition.diseaseId.contains('subclinical');
  }

  Color _getSeverityColor(DiseaseSeverity severity) {
    switch (severity) {
      case DiseaseSeverity.mild:
        return Colors.green;
      case DiseaseSeverity.moderate:
        return Colors.orange;
      case DiseaseSeverity.severe:
        return Colors.red;
      case DiseaseSeverity.critical:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDiagnosisDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: condition.diagnosisDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      // TODO: Update diagnosis date in condition
    }
  }
}