// ==================== CORRECTED ANATOMY TAB ====================
// lib/screens/endocrine/tabs/anatomy_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../models/patient.dart';
import '../../canvas/canvas_screen.dart';

class AnatomyTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;
  final Patient patient;

  const AnatomyTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
    required this.patient,
  });

  @override
  State<AnatomyTab> createState() => _AnatomyTabState();
}

class _AnatomyTabState extends State<AnatomyTab> {
  String _selectedView = 'anterior';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View Selector
          _buildViewSelector(),
          const SizedBox(height: 20),

          // Main Anatomy Diagram Card
          _buildAnatomyDiagramCard(),
          const SizedBox(height: 20),

          // Pathophysiology Section
          _buildPathophysiologyCard(),
          const SizedBox(height: 20),

          // Clinical Features Section (using signs from config)
          _buildClinicalFeaturesCard(),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'SELECT VIEW',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildViewChip('anterior', 'Anterior View', Icons.person),
                _buildViewChip('lateral', 'Lateral View', Icons.accessibility),
                _buildViewChip('cross_section', 'Cross-Section', Icons.layers),
                _buildViewChip('microscopic', 'Microscopic', Icons.biotech),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChip(String view, String label, IconData icon) {
    final isSelected = _selectedView == view;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedView = view;
        });
      },
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAnatomyDiagramCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.biotech, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  _getViewTitle(_selectedView),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Thyroid Gland Anatomy',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Placeholder Diagram
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getDiagramIcon(_selectedView),
                    const SizedBox(height: 16),
                    Text(
                      'Tap "Open Canvas" to view and annotate',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // OPEN CANVAS BUTTON
            ElevatedButton.icon(
              onPressed: () => _openCanvas(),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text(
                'Open Canvas & Annotate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),

            const SizedBox(height: 12),
            Text(
              'Full canvas tool with markers, drawing, and zoom',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCanvas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CanvasScreen(
          patient: widget.patient,
          preSelectedSystem: 'thyroid',
          preSelectedDiagramType: _selectedView,
          existingVisit: null,
        ),
      ),
    );
  }

  Widget _buildPathophysiologyCard() {
    final steps = _getPathophysiologySteps();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 20, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'PATHOPHYSIOLOGY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 13),
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

  Widget _buildClinicalFeaturesCard() {
    // Use signs from diseaseConfig instead of anatomicalChanges
    final signs = widget.diseaseConfig.signs;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, size: 20, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Text(
                  'CLINICAL SIGNS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Physical examination findings in ${widget.diseaseConfig.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...signs.map((sign) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, size: 20, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sign,
                        style: const TextStyle(fontSize: 13),
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

  Widget _getDiagramIcon(String view) {
    IconData icon;
    switch (view) {
      case 'anterior':
        icon = Icons.person;
        break;
      case 'lateral':
        icon = Icons.accessibility;
        break;
      case 'cross_section':
        icon = Icons.layers;
        break;
      case 'microscopic':
        icon = Icons.biotech;
        break;
      default:
        icon = Icons.account_box;
    }

    return Icon(icon, size: 100, color: Colors.grey.shade400);
  }

  String _getViewTitle(String view) {
    switch (view) {
      case 'anterior':
        return 'Anterior View';
      case 'lateral':
        return 'Lateral View';
      case 'cross_section':
        return 'Cross-Section';
      case 'microscopic':
        return 'Microscopic View';
      default:
        return 'Normal Anatomy';
    }
  }

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
        'Compensatory increase in TSH from pituitary',
        'Progressive thyroid dysfunction',
        'Systemic hypometabolic state develops',
      ];
    } else if (diseaseId == 'hashimotos_thyroiditis') {
      return [
        'Autoimmune attack on thyroid tissue',
        'Lymphocytic infiltration of thyroid gland',
        'Destruction of thyroid follicles',
        'Gradual decline in thyroid hormone production',
        'Compensatory TSH elevation',
        'Progressive hypothyroidism develops',
      ];
    } else if (diseaseId == 'subacute_thyroiditis') {
      return [
        'Viral infection triggers thyroid inflammation',
        'Thyroid follicle destruction releases stored hormones',
        'Transient hyperthyroidism phase (1-3 months)',
        'Gland becomes depleted of hormone stores',
        'Hypothyroid phase follows (months)',
        'Usually resolves with return to normal function',
      ];
    } else if (diseaseId.contains('cancer') || diseaseId.contains('carcinoma')) {
      return [
        'Malignant transformation of thyroid cells',
        'Uncontrolled cellular proliferation',
        'Formation of thyroid nodule or mass',
        'Potential local invasion',
        'Risk of lymph node metastasis',
        'Distant metastasis in advanced cases',
      ];
    } else {
      // Generic pathophysiology for other thyroid conditions
      return [
        'Disease-specific pathophysiology',
        'Cellular and molecular changes in thyroid tissue',
        'Progression of thyroid dysfunction',
        'Systemic effects of hormone imbalance',
      ];
    }
  }
}