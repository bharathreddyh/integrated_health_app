// ==================== TAB 2: ANATOMY & PATHOPHYSIOLOGY ====================
// lib/screens/endocrine/tabs/anatomy_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';

class AnatomyTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig; // Changed from Map<String, dynamic>
  final Function(EndocrineCondition) onUpdate;

  const AnatomyTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<AnatomyTab> createState() => _AnatomyTabState();
}

class _AnatomyTabState extends State<AnatomyTab> {
  String _selectedView = 'normal';
  List<Annotation> _annotations = [];

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

          // Main Anatomy Diagram
          _buildAnatomyDiagramCard(),
          const SizedBox(height: 20),

          // Pathophysiology Section
          _buildPathophysiologyCard(),
          const SizedBox(height: 20),

          // Disease-Specific Anatomical Changes
          _buildAnatomicalChangesCard(),
          const SizedBox(height: 20),

          // Annotations List
          if (_annotations.isNotEmpty) _buildAnnotationsCard(),
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
            const Text(
              'SELECT VIEW',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildViewChip('normal', 'Normal Anatomy', Icons.account_box),
                _buildViewChip('anterior', 'Anterior View', Icons.person),
                _buildViewChip('lateral', 'Lateral View', Icons.accessibility),
                _buildViewChip('cross', 'Cross-Section', Icons.layers),
                _buildViewChip('microscopic', 'Microscopic', Icons.biotech),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChip(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedView = value);
      },
      selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2563EB),
    );
  }

  Widget _buildAnatomyDiagramCard() {
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
                const Icon(Icons.image, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                Text(
                  _getViewTitle(_selectedView),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Anatomy Diagram
            GestureDetector(
              onTapDown: _handleTapOnDiagram,
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Stack(
                  children: [
                    // Placeholder diagram
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _getDiagramIcon(_selectedView),
                          const SizedBox(height: 16),
                          Text(
                            _getViewTitle(_selectedView),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thyroid Gland Anatomy',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '(Tap to add annotations)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Annotations overlay
                    ..._annotations.map((annotation) => Positioned(
                      left: annotation.x,
                      top: annotation.y,
                      child: _buildAnnotationMarker(annotation),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open full-screen annotation tool
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Annotate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Upload custom image
                  },
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload Image'),
                ),
                const Spacer(),
                if (_annotations.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _annotations.clear());
                    },
                    icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                    label: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Anatomical Labels
            _buildAnatomicalLabels(),
          ],
        ),
      ),
    );
  }

  Widget _buildPathophysiologyCard() {
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
                Icon(Icons.device_hub, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Text(
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

            // Disease description from config
            if (widget.diseaseConfig.description.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disease Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.diseaseConfig.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Disease mechanism flowchart
            const Text(
              'Disease Mechanism',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildPathophysiologyFlowchart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPathophysiologyFlowchart() {
    // Get disease-specific pathophysiology steps
    final steps = _getPathophysiologySteps();

    return Column(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _buildFlowchartStep(i + 1, steps[i]),
          if (i < steps.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.arrow_downward, color: Color(0xFF2563EB)),
            ),
        ],
      ],
    );
  }

  Widget _buildFlowchartStep(int number, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnatomicalChangesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DISEASE-SPECIFIC ANATOMICAL CHANGES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            ..._getAnatomicalChanges().map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      change,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAnatomicalLabels() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Anatomical Structures:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLabelChip('Right Lobe', Colors.red),
              _buildLabelChip('Left Lobe', Colors.blue),
              _buildLabelChip('Isthmus', Colors.green),
              _buildLabelChip('Pyramidal Lobe', Colors.orange),
              _buildLabelChip('Trachea', Colors.purple),
              _buildLabelChip('Blood Vessels', Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChip(String label, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildAnnotationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ANNOTATIONS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ..._annotations.asMap().entries.map((entry) {
              final index = entry.key;
              final annotation = entry.value;
              return _buildAnnotationListItem(index, annotation);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotationListItem(int index, Annotation annotation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: annotation.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              annotation.label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () {
              setState(() => _annotations.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationMarker(Annotation annotation) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: annotation.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${_annotations.indexOf(annotation) + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
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
      case 'cross':
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
      case 'cross':
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

  List<String> _getAnatomicalChanges() {
    final diseaseId = widget.condition.diseaseId;

    if (diseaseId == 'graves_disease') {
      return [
        'Diffuse thyroid enlargement (goiter)',
        'Increased vascularity (thyroid bruit may be present)',
        'Hyperplastic follicular cells',
        'Decreased colloid in follicles',
        'Orbital tissue expansion (in thyroid eye disease)',
        'Pretibial skin thickening (in some cases)',
      ];
    } else if (diseaseId == 'hashimotos_thyroiditis') {
      return [
        'Diffuse lymphocytic infiltration',
        'Follicular destruction and atrophy',
        'Firm, lobulated goiter',
        'Oncocytic (Hürthle) cell metaplasia',
        'Progressive gland fibrosis',
      ];
    } else if (diseaseId.contains('toxic') || diseaseId.contains('adenoma')) {
      return [
        'Single or multiple autonomous nodules',
        'Hyperplastic nodular tissue',
        'Surrounding thyroid tissue suppressed',
        'Variable gland enlargement',
        'Increased vascularity in nodules',
      ];
    } else if (widget.condition.category == 'cancer') {
      return [
        'Solid thyroid mass or nodule',
        'Irregular borders (may be infiltrative)',
        'Possible lymph node involvement',
        'Potential capsular invasion',
        'Calcifications may be present',
        'Increased vascularity in malignant areas',
      ];
    } else if (widget.condition.category == 'hypothyroidism') {
      return [
        'Thyroid gland may be small, normal, or enlarged',
        'Reduced follicular activity',
        'Increased TSH stimulation effects',
        'May show fibrosis or atrophy',
      ];
    }

    return [
      'Variable thyroid gland changes depending on specific condition',
      'May include size changes, texture changes, or nodular formation',
      'Vascular changes may be present',
      'Surrounding tissue may be affected',
    ];
  }

  void _handleTapOnDiagram(TapDownDetails details) {
    showDialog(
      context: context,
      builder: (context) {
        final labelController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Annotation'),
          content: TextField(
            controller: labelController,
            decoration: const InputDecoration(
              labelText: 'Annotation Label',
              hintText: 'e.g., Enlarged right lobe',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (labelController.text.isNotEmpty) {
                  setState(() {
                    _annotations.add(Annotation(
                      x: details.localPosition.dx - 16,
                      y: details.localPosition.dy - 16,
                      label: labelController.text,
                      color: const Color(0xFFDC2626),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// Simple annotation model
class Annotation {
  final double x;
  final double y;
  final String label;
  final Color color;

  Annotation({
    required this.x,
    required this.y,
    required this.label,
    required this.color,
  });
}