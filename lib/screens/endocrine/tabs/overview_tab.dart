// ==================== TAB 1: OVERVIEW (REDESIGNED) ====================
// lib/screens/endocrine/tabs/overview_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';

class OverviewTab extends StatefulWidget {
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
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  // State for checkboxes
  Set<String> selectedCriteria = {};
  Set<String> selectedComplications = {};

  @override
  void initState() {
    super.initState();
    // Initialize from condition if data exists
    selectedCriteria = Set<String>.from(widget.condition.selectedDiagnosticCriteria ?? []);
    selectedComplications = Set<String>.from(widget.condition.selectedComplications ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Disease Information Card (Keep existing with placeholder)
          _buildDiseaseInformationCard(),
          const SizedBox(height: 20),

          // 2. Pathophysiology Card (Moved from anatomy tab)
          _buildPathophysiologyCard(),
          const SizedBox(height: 20),

          // 4. Diagnostic Criteria Card (Modified - removed specialist consultation)
          _buildDiagnosticCriteriaCard(),
          const SizedBox(height: 20),

          // 5. Severity Card (Keep existing)
          if (_showSeverity()) ...[
            _buildSeverityCard(),
            const SizedBox(height: 20),
          ],

          // 6. Complications Card (Enhanced with functional checkboxes)
          _buildComplicationsCard(),
          const SizedBox(height: 20),

          // 7. Clinical Notes Card (Keep existing)
          _buildNotesCard(),
        ],
      ),
    );
  }

  // 1. DISEASE INFORMATION (Keep existing)
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
              widget.diseaseConfig.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            if (widget.diseaseConfig.icd10 != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ICD-10: ${widget.diseaseConfig.icd10}',
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

  // 2. PATHOPHYSIOLOGY (Moved from anatomy tab)
  Widget _buildPathophysiologyCard() {
    final steps = _getPathophysiologySteps();

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
                Icon(Icons.timeline, color: Color(0xFF7C3AED), size: 24),
                SizedBox(width: 12),
                Text(
                  'PATHOPHYSIOLOGY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Disease progression and mechanisms:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step description
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          step,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // 3. SYMPTOMS (New with checkboxes)
  Widget _buildDiagnosticCriteriaCard() {
    final criteria = _getDiagnosticCriteria();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Color(0xFF059669), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'DIAGNOSTIC CRITERIA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    '${selectedCriteria.length}/${criteria.length} completed',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF059669).withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Mark completed diagnostic steps:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            ...criteria.map((criterion) => _buildCriteriaCheckbox(criterion)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaCheckbox(Map<String, dynamic> criterion) {
    final text = criterion['text'] as String;
    final icon = criterion['icon'] as IconData;
    final isSelected = selectedCriteria.contains(text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedCriteria.remove(text);
            } else {
              selectedCriteria.add(text);
            }
          });
          _updateConditionCriteria();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF059669).withOpacity(0.05) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF059669).withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF059669) : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF059669) : Colors.grey.shade800,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedCriteria.add(text);
                    } else {
                      selectedCriteria.remove(text);
                    }
                  });
                  _updateConditionCriteria();
                },
                activeColor: const Color(0xFF059669),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. SEVERITY (Keep existing)
  Widget _buildSeverityCard() {
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
                Icon(Icons.speed, color: Color(0xFFEA580C), size: 24),
                SizedBox(width: 12),
                Text(
                  'SEVERITY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSeverityOption(DiseaseSeverity.mild, 'Mild'),
            _buildSeverityOption(DiseaseSeverity.moderate, 'Moderate'),
            _buildSeverityOption(DiseaseSeverity.severe, 'Severe'),
            _buildSeverityOption(DiseaseSeverity.critical, 'Critical'),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityOption(DiseaseSeverity severity, String label) {
    final isSelected = widget.condition.severity == severity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          widget.onUpdate(widget.condition.copyWith(severity: severity));
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
                groupValue: widget.condition.severity,
                onChanged: (value) {
                  if (value != null) {
                    widget.onUpdate(widget.condition.copyWith(severity: value));
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

  // 6. COMPLICATIONS (Enhanced with functional checkboxes)
  Widget _buildComplicationsCard() {
    final complications = widget.diseaseConfig.complications ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'COMPLICATIONS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                const Spacer(),
                if (complications.isNotEmpty)
                  Chip(
                    label: Text(
                      '${selectedComplications.length}/${complications.length} present',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFFD97706).withOpacity(0.1),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (complications.isNotEmpty) ...[
              Text(
                'Mark complications present in this patient:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              ...complications.map((comp) => _buildComplicationCheckbox(comp as String))
            ] else
              Text(
                'No complications listed for this condition',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplicationCheckbox(String complication) {
    final isSelected = selectedComplications.contains(complication);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedComplications.remove(complication);
            } else {
              selectedComplications.add(complication);
            }
          });
          _updateConditionComplications();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD97706).withOpacity(0.05) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFD97706).withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 20,
                color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  complication,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade800,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedComplications.add(complication);
                    } else {
                      selectedComplications.remove(complication);
                    }
                  });
                  _updateConditionComplications();
                },
                activeColor: const Color(0xFFD97706),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 7. CLINICAL NOTES (Keep existing)
  Widget _buildNotesCard() {
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
                Icon(Icons.note_add, color: Color(0xFF6366F1), size: 24),
                SizedBox(width: 12),
                Text(
                  'CLINICAL NOTES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 6,
              controller: TextEditingController(text: widget.condition.notes),
              decoration: InputDecoration(
                hintText: 'Enter clinical notes, observations, or additional information...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) {
                widget.onUpdate(widget.condition.copyWith(notes: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<String> _getPathophysiologySteps() {
    final diseaseId = widget.condition.diseaseId;

    if (diseaseId == 'graves_disease') {
      return [
        'TSH receptor antibodies (TSH-R Ab) produced by immune system',
        'Antibodies bind to TSH receptors on thyroid follicular cells',
        'Continuous stimulation of thyroid gland (independent of TSH)',
        'Excessive synthesis and release of T3 and T4',
        'Negative feedback suppresses TSH to near-zero levels',
        'Systemic hypermetabolic state develops',
      ];
    } else if (diseaseId == 'primary_hypothyroidism') {
      return [
        'Thyroid gland failure (autoimmune, iodine deficiency, etc.)',
        'Decreased production of T3 and T4',
        'Pituitary increases TSH production (feedback mechanism)',
        'Elevated TSH attempts to stimulate failing thyroid',
        'Persistent hypothyroid state despite high TSH',
      ];
    } else if (diseaseId == 'hashimotos_thyroiditis') {
      return [
        'Autoimmune attack on thyroid tissue',
        'Anti-TPO and anti-thyroglobulin antibodies produced',
        'Gradual destruction of thyroid follicles',
        'Progressive decline in thyroid hormone production',
        'Compensatory TSH elevation',
        'Eventually leads to overt hypothyroidism',
      ];
    } else if (diseaseId == 'toxic_multinodular_goiter') {
      return [
        'Multiple thyroid nodules develop over years',
        'Some nodules gain autonomous function',
        'Independent thyroid hormone production',
        'TSH suppression due to excess hormones',
        'Hyperthyroid symptoms develop',
      ];
    } else if (diseaseId == 'subacute_thyroiditis') {
      return [
        'Viral infection triggers thyroid inflammation',
        'Initial release of stored thyroid hormones (hyperthyroid phase)',
        'Thyroid gland damage and reduced hormone production',
        'Hypothyroid phase as stores deplete',
        'Gradual recovery in most cases',
      ];
    }

    return [
      'Thyroid gland dysfunction',
      'Altered hormone production',
      'Metabolic changes',
      'Clinical manifestations',
    ];
  }

  List<Map<String, dynamic>> _getDiagnosticCriteria() {
    return [
      {'text': 'Clinical examination performed', 'icon': Icons.medical_services},
      {'text': 'Thyroid function tests ordered', 'icon': Icons.science},
      {'text': 'Imaging studies done', 'icon': Icons.camera_alt},
      // Removed: 'Specialist consultation obtained'
    ];
  }

  bool _showSeverity() {
    return !widget.condition.diseaseId.contains('subclinical');
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

  void _updateConditionCriteria() {
    widget.onUpdate(widget.condition.copyWith(selectedDiagnosticCriteria: selectedCriteria.toList()));
  }

  void _updateConditionComplications() {
    widget.onUpdate(widget.condition.copyWith(selectedComplications: selectedComplications.toList()));
  }
}