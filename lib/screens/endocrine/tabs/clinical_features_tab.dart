// ==================== TAB 3: CLINICAL FEATURES ====================
// lib/screens/endocrine/tabs/clinical_features_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../services/database_helper.dart';

class ClinicalFeaturesTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const ClinicalFeaturesTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<ClinicalFeaturesTab> createState() => _ClinicalFeaturesTabState();
}

class _ClinicalFeaturesTabState extends State<ClinicalFeaturesTab> {
  // Selected symptoms tracking
  Set<String> selectedSymptoms = {};

  // Thyroid-specific examination data
  bool _goiterPresent = false;
  String _goiterGrade = '1a';
  String _consistency = 'soft';
  bool _nodulesPresent = false;
  bool _bruitPresent = false;
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

// Graves' specific (if applicable)
  bool _tedPresent = false;
  final _proptosisController = TextEditingController();
  bool _lidRetraction = false;
  bool _lidLag = false;
  bool _diplopia = false;

  @override
  void initState() {
    super.initState();
    // Initialize from condition if data exists
    selectedSymptoms = Set<String>.from(widget.condition.selectedSymptoms ?? []);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _proptosisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Physical Examination Card
          _buildPhysicalExaminationCard(),
          const SizedBox(height: 20),

          // Thyroid Examination Card
          _buildThyroidExaminationCard(),
          const SizedBox(height: 20),

          // Symptoms Card
          _buildSymptomsCard(),
          const SizedBox(height: 20),

          // Signs Card
          _buildSignsCard(),
          const SizedBox(height: 20),

          // Disease-Specific Features
          if (_isGravesDisease()) ...[
            _buildGravesSpecificCard(),
            const SizedBox(height: 20),
          ],

          // Clinical Photos Section
          _buildClinicalPhotosCard(),
        ],
      ),
    );
  }

  Widget _buildPhysicalExaminationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PHYSICAL EXAMINATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Placeholder for neck diagram
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.accessibility_new,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Neck Examination Diagram',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mark thyroid gland, goiter, nodules',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Open annotation tool
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Annotate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
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

  Widget _buildThyroidExaminationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THYROID EXAMINATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Goiter Present
            Row(
              children: [
                const Text(
                  'Goiter Present:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 20),
                Radio(
                  value: true,
                  groupValue: _goiterPresent,
                  onChanged: (value) => setState(() => _goiterPresent = value!),
                ),
                const Text('Yes'),
                const SizedBox(width: 16),
                Radio(
                  value: false,
                  groupValue: _goiterPresent,
                  onChanged: (value) => setState(() => _goiterPresent = value!),
                ),
                const Text('No'),
              ],
            ),

            if (_goiterPresent) ...[
              const SizedBox(height: 16),

              // Goiter Grade
              const Text('Grade:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['1a', '1b', '2', '3'].map((grade) {
                  return ChoiceChip(
                    label: Text(grade),
                    selected: _goiterGrade == grade,
                    onSelected: (selected) {
                      if (selected) setState(() => _goiterGrade = grade);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Consistency
              const Text('Consistency:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['Soft', 'Firm', 'Hard'].map((cons) {
                  return ChoiceChip(
                    label: Text(cons),
                    selected: _consistency == cons.toLowerCase(),
                    onSelected: (selected) {
                      if (selected) setState(() => _consistency = cons.toLowerCase());
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Size
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Width (cm)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('×', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Nodules
            CheckboxListTile(
              title: const Text('Nodules Present'),
              value: _nodulesPresent,
              onChanged: (value) => setState(() => _nodulesPresent = value!),
              contentPadding: EdgeInsets.zero,
            ),

            // Bruit
            CheckboxListTile(
              title: const Text('Bruit Present'),
              value: _bruitPresent,
              onChanged: (value) => setState(() => _bruitPresent = value!),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    final symptoms = _getSymptoms();

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
                const Icon(Icons.healing, color: Color(0xFFDC2626), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'SYMPTOMS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    '${ selectedSymptoms.length}/${symptoms.length} selected',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Select symptoms present in this patient:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),

            if (symptoms.isNotEmpty)
              ...symptoms.map((symptom) => _buildSymptomCheckbox(symptom))
            else
              Text(
                'No symptoms defined for this condition',
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

  Widget _buildSymptomCheckbox(String symptom) {
    final isSelected = selectedSymptoms.contains(symptom);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedSymptoms.remove(symptom);
            } else {
              selectedSymptoms.add(symptom);
            }
          });
          _updateConditionSymptoms();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDC2626).withOpacity(0.05) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFDC2626).withOpacity(0.3) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getSymptomIcon(symptom),
                size: 20,
                color: isSelected ? const Color(0xFFDC2626) : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  symptom,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFFDC2626) : Colors.grey.shade800,
                  ),
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedSymptoms.add(symptom);
                    } else {
                      selectedSymptoms.remove(symptom);
                    }
                  });
                  _updateConditionSymptoms();
                },
                activeColor: const Color(0xFFDC2626),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignsCard() {
    final signs = widget.diseaseConfig.signs;
    if (signs == null || signs.isEmpty) return const SizedBox();

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
                Icon(Icons.visibility, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  'SIGNS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...signs.map((sign) => _buildFeatureCheckbox(
              sign as String,
              FeatureType.sign,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCheckbox(String name, FeatureType type) {
    // Check if this feature is already in the condition
    final existingFeature = widget.condition.clinicalFeatures.firstWhere(
          (f) => f.name == name && f.type == type,
      orElse: () => ClinicalFeature(
        id: 'temp_$name',
        name: name,
        type: type,
        isPresent: false,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        title: Text(name, style: const TextStyle(fontSize: 14)),
        value: existingFeature.isPresent,
        onChanged: (value) {
          final updatedFeatures = List<ClinicalFeature>.from(widget.condition.clinicalFeatures);

          // Remove old entry if exists
          updatedFeatures.removeWhere((f) => f.name == name && f.type == type);

          // Add updated entry
          updatedFeatures.add(ClinicalFeature(
            id: existingFeature.id,
            name: name,
            type: type,
            isPresent: value!,
          ));

          widget.onUpdate(widget.condition.copyWith(clinicalFeatures: updatedFeatures));
        },
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildGravesSpecificCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GRAVES' SPECIFIC FEATURES",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),

            // Thyroid Eye Disease Section
            const Text(
              'Thyroid Eye Disease (TED)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            CheckboxListTile(
              title: const Text('TED Present'),
              value: _tedPresent,
              onChanged: (value) => setState(() => _tedPresent = value!),
              contentPadding: EdgeInsets.zero,
            ),

            if (_tedPresent) ...[
              const SizedBox(height: 16),

              // Eye diagram placeholder
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👁️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Eye Examination Diagram',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _proptosisController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Proptosis (mm)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              CheckboxListTile(
                title: const Text('Lid Retraction'),
                value: _lidRetraction,
                onChanged: (value) => setState(() => _lidRetraction = value!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Lid Lag'),
                value: _lidLag,
                onChanged: (value) => setState(() => _lidLag = value!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Diplopia'),
                value: _diplopia,
                onChanged: (value) => setState(() => _diplopia = value!),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],

            const SizedBox(height: 20),

            // Pretibial Myxedema
            const Text(
              'Pretibial Myxedema',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🦵', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    'Leg Diagram - Mark affected areas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
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

  Widget _buildClinicalPhotosCard() {
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
                const Text(
                  'CLINICAL PHOTOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open camera/gallery
                  },
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.condition.images.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No clinical photos uploaded',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: widget.condition.images.length,
                itemBuilder: (context, index) {
                  final image = widget.condition.images[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(child: Text(image.type)),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              // TODO: Remove image
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }


  List<String> _getSymptoms() {
    final diseaseId = widget.condition.diseaseId;

    if (diseaseId == 'graves_disease') {
      return [
        'Weight loss despite increased appetite',
        'Heat intolerance and excessive sweating',
        'Tremor (fine tremor of hands)',
        'Palpitations and rapid heart rate',
        'Nervousness and anxiety',
        'Fatigue and muscle weakness',
        'Frequent bowel movements',
        'Goiter (enlarged thyroid)',
        'Eye problems (Graves\' ophthalmopathy)',
        'Sleep disturbances',
        'Menstrual irregularities',
        'Hair thinning',
      ];
    } else if (diseaseId == 'primary_hypothyroidism' || diseaseId == 'hashimotos_thyroiditis') {
      return [
        'Fatigue and weakness',
        'Weight gain',
        'Cold intolerance',
        'Constipation',
        'Dry skin and hair',
        'Hair loss or thinning',
        'Depression or mood changes',
        'Memory problems',
        'Muscle aches and stiffness',
        'Joint pain',
        'Swelling (face, hands, feet)',
        'Slow heart rate',
        'Menstrual irregularities',
        'Hoarse voice',
      ];
    } else if (diseaseId == 'toxic_multinodular_goiter') {
      return [
        'Weight loss',
        'Heat intolerance',
        'Rapid heart rate',
        'Tremor',
        'Nervousness',
        'Fatigue',
        'Palpable thyroid nodules',
        'Difficulty swallowing',
        'Shortness of breath',
      ];
    } else if (diseaseId == 'subacute_thyroiditis') {
      return [
        'Neck pain (anterior neck)',
        'Pain radiating to jaw or ears',
        'Tender thyroid gland',
        'Fever',
        'Fatigue',
        'Initial hyperthyroid symptoms',
        'Later hypothyroid symptoms',
        'Muscle aches',
      ];
    }

    // Default symptoms for other conditions
    return [
      'Fatigue',
      'Weight changes',
      'Temperature intolerance',
      'Heart rate changes',
      'Mood changes',
      'Sleep disturbances',
    ];
  }

  IconData _getSymptomIcon(String symptom) {
    if (symptom.toLowerCase().contains('weight')) return Icons.monitor_weight;
    if (symptom.toLowerCase().contains('heart') || symptom.toLowerCase().contains('palpitation')) return Icons.favorite;
    if (symptom.toLowerCase().contains('tremor')) return Icons.vibration;
    if (symptom.toLowerCase().contains('eye')) return Icons.visibility;
    if (symptom.toLowerCase().contains('pain')) return Icons.healing;
    if (symptom.toLowerCase().contains('temperature') || symptom.toLowerCase().contains('heat') || symptom.toLowerCase().contains('cold')) return Icons.thermostat;
    if (symptom.toLowerCase().contains('fatigue') || symptom.toLowerCase().contains('tired')) return Icons.battery_0_bar;
    if (symptom.toLowerCase().contains('mood') || symptom.toLowerCase().contains('anxiety') || symptom.toLowerCase().contains('depression')) return Icons.psychology;
    if (symptom.toLowerCase().contains('sleep')) return Icons.bedtime;
    if (symptom.toLowerCase().contains('hair')) return Icons.face_retouching_natural;
    if (symptom.toLowerCase().contains('skin')) return Icons.face;
    if (symptom.toLowerCase().contains('goiter') || symptom.toLowerCase().contains('neck')) return Icons.face_retouching_natural;
    return Icons.health_and_safety;
  }

  void _updateConditionSymptoms() {
    final updatedCondition = widget.condition.copyWith(
        selectedSymptoms: selectedSymptoms.toList()
    );
    widget.onUpdate(updatedCondition);
    DatabaseHelper.instance.updateEndocrineCondition(updatedCondition);
  }
  bool _isGravesDisease() {
    return widget.condition.diseaseId == 'graves_disease';
  }
}