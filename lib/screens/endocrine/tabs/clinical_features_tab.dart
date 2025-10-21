// ==================== TAB 3: CLINICAL FEATURES ====================
// lib/screens/endocrine/tabs/clinical_features_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';


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
  // Thyroid-specific examination data
  bool _goiterPresent = false;
  String _goiterGrade = '1a';
  String _consistency = 'soft';
  bool _nodulesPresent = false;
  bool _bruitPresent = false;
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  // Vitals
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _hrController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();

  // Graves' specific (if applicable)
  bool _tedPresent = false;
  final _proptosisController = TextEditingController();
  bool _lidRetraction = false;
  bool _lidLag = false;
  bool _diplopia = false;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _weightController.dispose();
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

          // Vitals Card
          _buildVitalsCard(),
          const SizedBox(height: 20),

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
    final symptoms = widget.diseaseConfig.symptoms;
    if (symptoms == null || symptoms.isEmpty) return const SizedBox();

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
                Icon(Icons.psychology, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  'SYMPTOMS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ...symptoms.map((symptom) => _buildFeatureCheckbox(
              symptom as String,
              FeatureType.symptom,
            )),
          ],
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

  Widget _buildVitalsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VITALS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bpSystolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BP Systolic',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: TextField(
                    controller: _bpDiastolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BP Diastolic',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Heart Rate',
                      suffixText: 'bpm',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _tempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Temperature',
                      suffixText: '°C',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                isDense: true,
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

  bool _isGravesDisease() {
    return widget.condition.diseaseId == 'graves_disease';
  }
}