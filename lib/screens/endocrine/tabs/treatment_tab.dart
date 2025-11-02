// ==================== UPDATED TAB 4: TREATMENT ====================
// lib/screens/endocrine/tabs/treatment_tab.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';
import '../../../services/database_helper.dart';

class TreatmentTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const TreatmentTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<TreatmentTab> createState() => _TreatmentTabState();
}

class _TreatmentTabState extends State<TreatmentTab> {
  String _treatmentApproach = 'medical';
  final _treatmentGoalController = TextEditingController();
  final _monitoringPlanController = TextEditingController();
  final _dietPlanController = TextEditingController();
  final _lifestyleController = TextEditingController();

  // Toggles
  bool _includeDiet = false;
  bool _includeLifestyle = false;

  // Advanced treatments state
  int _raiStatus = 0; // 0=Not planned, 1=Planned, 2=Completed
  int _surgeryStatus = 0;
  String? _surgeryType;

  // Auto-save
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  DateTime? _lastSaved;

  // Diet Plan Templates
  static const Map<String, String> _dietTemplates = {
    'Hypothyroidism': '''
• Increase iodine-rich foods (seafood, iodized salt)
• Include selenium sources (Brazil nuts, fish, eggs)
• Avoid excessive goitrogens (raw cruciferous vegetables)
• Maintain adequate protein intake
• Include zinc-rich foods
• Stay well hydrated (8-10 glasses/day)''',

    'Hyperthyroidism': '''
• Limit iodine intake (avoid kelp, seaweed)
• Include calcium-rich foods (milk, yogurt, cheese)
• Adequate calories to prevent weight loss
• Avoid caffeine and stimulants
• Small frequent meals (5-6 times/day)
• Include magnesium-rich foods''',

    'Post-Thyroidectomy': '''
• High calcium diet (1200-1500 mg/day)
• Vitamin D supplementation
• Regular balanced meals to maintain metabolism
• Monitor for hypocalcemia symptoms
• Adequate protein for healing''',

    'Thyroid Cancer': '''
• Low iodine diet before RAI (if applicable)
• Antioxidant-rich foods (berries, vegetables)
• Adequate protein for healing
• Stay hydrated
• Small frequent nutritious meals''',
  };

  // Lifestyle Templates
  static const Map<String, String> _lifestyleTemplates = {
    'General': '''
• Regular sleep schedule (7-8 hours)
• Stress management (meditation, yoga)
• Moderate exercise (30 min daily walking)
• Avoid smoking and excess alcohol
• Regular medication compliance
• Regular follow-ups''',

    'Hyperthyroidism': '''
• Avoid strenuous exercise initially
• Practice relaxation techniques daily
• Ensure adequate rest (8-9 hours)
• Monitor heart rate regularly
• Avoid heat exposure and hot baths
• Reduce caffeine intake''',

    'Hypothyroidism': '''
• Regular aerobic exercise (gradually increase)
• Weight management program
• Adequate sleep (7-9 hours)
• Stress reduction techniques
• Take medication on empty stomach
• Avoid soy products with medication''',
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();

    // Add listeners for auto-save
    _treatmentGoalController.addListener(_onTextChanged);
    _monitoringPlanController.addListener(_onTextChanged);
    _dietPlanController.addListener(_onTextChanged);
    _lifestyleController.addListener(_onTextChanged);
    _dietPlanController.text = widget.condition.treatmentPlan!.dietPlan;
    _lifestyleController.text = widget.condition.treatmentPlan!.lifestylePlan;
    _includeDiet = widget.condition.treatmentPlan!.dietPlan.isNotEmpty;
    _includeLifestyle = widget.condition.treatmentPlan!.lifestylePlan.isNotEmpty;
  }

  void _loadExistingData() {
    if (widget.condition.treatmentPlan != null) {
      _treatmentApproach = widget.condition.treatmentPlan!.approach;
      _treatmentGoalController.text = widget.condition.treatmentPlan!.goal;
      _monitoringPlanController.text = widget.condition.treatmentPlan!.monitoringPlan;
    } else if (widget.diseaseConfig.monitoringPlan != null) {
      _monitoringPlanController.text = widget.diseaseConfig.monitoringPlan!;
    }

    // Load advanced treatment status from additionalData if available
    if (widget.condition.additionalData != null) {
      _raiStatus = widget.condition.additionalData!['raiStatus'] as int? ?? 0;
      _surgeryStatus = widget.condition.additionalData!['surgeryStatus'] as int? ?? 0;
      _surgeryType = widget.condition.additionalData!['surgeryType'] as String?;
    }
  }

  void _onTextChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedPlan = TreatmentPlan(
        approach: _treatmentApproach,
        goal: _treatmentGoalController.text,
        monitoringPlan: _monitoringPlanController.text,
        dietPlan: _includeDiet ? _dietPlanController.text : '',
        lifestylePlan: _includeLifestyle ? _lifestyleController.text : '',
      );

      // Save advanced treatment status to additionalData
      final updatedAdditionalData = Map<String, dynamic>.from(widget.condition.additionalData ?? {});
      updatedAdditionalData['raiStatus'] = _raiStatus;
      updatedAdditionalData['surgeryStatus'] = _surgeryStatus;
      updatedAdditionalData['surgeryType'] = _surgeryType;

      final updatedCondition = widget.condition.copyWith(
        treatmentPlan: updatedPlan,
        additionalData: updatedAdditionalData,
      );

      widget.onUpdate(updatedCondition);

      await DatabaseHelper.instance.updateEndocrineCondition(updatedCondition);

      setState(() {
        _lastSaved = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Treatment plan saved'),
              ],
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Auto-save error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-save indicator
          if (_isSaving || _lastSaved != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _isSaving ? Colors.blue.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSaving ? Colors.blue.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _isSaving ? 'Saving...' : 'Saved',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSaving ? Colors.blue.shade700 : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_lastSaved != null) ...[
                    const Spacer(),
                    Text(
                      'Last saved: ${_formatTime(_lastSaved!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),

          // Treatment Approach Card
          _buildTreatmentApproachCard(),
          const SizedBox(height: 20),

          // Medications Card
          _buildMedicationsCard(),
          const SizedBox(height: 20),

          // Advanced Treatments
          if (_showAdvancedTreatments()) ...[
            _buildAdvancedTreatmentsCard(),
            const SizedBox(height: 20),
          ],

          // Diet Plan Card
          _buildToggleCard(
            title: 'Diet Plan',
            icon: Icons.restaurant,
            color: Colors.orange,
            isSelected: _includeDiet,
            onToggle: (value) {
              setState(() {
                _includeDiet = value;
                if (!value) _dietPlanController.clear();
              });
              _autoSave();
            },
            content: _includeDiet ? _buildDietSection() : null,
          ),
          const SizedBox(height: 20),

          // Lifestyle Modifications Card
          _buildToggleCard(
            title: 'Lifestyle Modifications',
            icon: Icons.directions_run,
            color: Colors.green,
            isSelected: _includeLifestyle,
            onToggle: (value) {
              setState(() {
                _includeLifestyle = value;
                if (!value) _lifestyleController.clear();
              });
              _autoSave();
            },
            content: _includeLifestyle ? _buildLifestyleSection() : null,
          ),
          const SizedBox(height: 20),

          // Treatment Targets Card
          _buildTreatmentTargetsCard(),
          const SizedBox(height: 20),

          // Monitoring Plan Card
          _buildMonitoringPlanCard(),
          const SizedBox(height: 20),

          // Follow-up Schedule Card
          _buildFollowUpCard(),
          const SizedBox(height: 20),

          // Patient Education Card
          _buildPatientEducationCard(),
          const SizedBox(height: 20),

          // Treatment Summary Card
          _buildTreatmentSummary(),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(bool) onToggle,
    Widget? content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => onToggle(!isSelected),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: isSelected,
                    onChanged: onToggle,
                    activeColor: color,
                  ),
                ],
              ),
            ),
          ),
          if (isSelected && content != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildDietSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dietTemplates.keys.map((key) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  _dietPlanController.text = _dietTemplates[key]!;
                });
                _autoSave();
              },
              child: Text(key),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dietPlanController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter diet recommendations...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.orange.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _lifestyleTemplates.keys.map((key) {
            return OutlinedButton(
              onPressed: () {
                setState(() {
                  _lifestyleController.text = _lifestyleTemplates[key]!;
                });
                _autoSave();
              },
              child: Text(key),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _lifestyleController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Enter lifestyle recommendations...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.green.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentSummary() {
    final totalItems = widget.condition.medications.length +
        (_includeDiet ? 1 : 0) +
        (_includeLifestyle ? 1 : 0);

    final completionPercentage = totalItems > 0 ? (totalItems / 5 * 100).clamp(0, 100) : 0;

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
                Icon(Icons.summarize, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Treatment Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Medications', '${widget.condition.medications.length} prescribed'),
            _buildSummaryRow('Diet Plan', _includeDiet ? 'Included' : 'Not included'),
            _buildSummaryRow('Lifestyle', _includeLifestyle ? 'Included' : 'Not included'),

            const Divider(height: 24),

            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              '${completionPercentage.toInt()}% Treatment Plan Complete',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildTreatmentApproachCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TREATMENT APPROACH',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildApproachOption('medical', 'Medical Management', 'Medications only', Icons.medication),
            const SizedBox(height: 12),
            if (_showRadioiodineOption())
              _buildApproachOption('radioactive_iodine', 'Radioactive Iodine', 'RAI therapy planned', Icons.warning_amber),
            if (_showRadioiodineOption()) const SizedBox(height: 12),
            if (_showSurgeryOption())
              _buildApproachOption('surgery', 'Surgical Management', 'Surgery planned', Icons.local_hospital),
            if (_showSurgeryOption()) const SizedBox(height: 12),
            _buildApproachOption('observation', 'Observation Only', 'No active treatment', Icons.visibility),
          ],
        ),
      ),
    );
  }

  Widget _buildApproachOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _treatmentApproach == value;
    return InkWell(
      onTap: () => setState(() => _treatmentApproach = value),
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
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade600),
            const SizedBox(width: 12),
            Radio<String>(
              value: value,
              groupValue: _treatmentApproach,
              onChanged: (val) => setState(() => _treatmentApproach = val!),
              activeColor: const Color(0xFF2563EB),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationsCard() {
    final configTreatments = widget.diseaseConfig.treatments;
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
                const Text('MEDICATIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddMedicationDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Medication'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.condition.medications.where((m) => m.isActive).isNotEmpty) ...[
              ...widget.condition.medications.where((m) => m.isActive).map((med) => _buildMedicationCard(med)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('No medications prescribed yet', style: TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ],
            if (configTreatments != null && configTreatments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Common Medications for this Condition:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 12),
              ...configTreatments.map((treatment) => _buildSuggestedMedication(treatment)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(medication.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editMedication(medication)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _removeMedication(medication)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${medication.dose} - ${medication.frequency}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (medication.indication.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('For: ${medication.indication}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 8),
          Text('Started: ${_formatDate(medication.startDate)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildSuggestedMedication(dynamic treatment) {
    final name = treatment['name'] as String;
    final defaultDose = treatment['defaultDose'] as String?;
    final notes = treatment['notes'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (defaultDose != null) ...[
                  const SizedBox(height: 2),
                  Text(defaultDose, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
                if (notes != null) ...[
                  const SizedBox(height: 2),
                  Text(notes, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          TextButton(onPressed: () => _quickAddMedication(treatment), child: const Text('Quick Add')),
        ],
      ),
    );
  }

  Widget _buildAdvancedTreatmentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADVANCED TREATMENTS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            if (_showRadioiodineOption()) ...[
              const Text('Radioactive Iodine Therapy', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildStatusRadioGroup(['Not planned', 'Planned', 'Completed'], _raiStatus, (value) {
                setState(() => _raiStatus = value);
                _autoSave();
              }),
              const SizedBox(height: 20),
            ],
            if (_showSurgeryOption()) ...[
              const Text('Surgical Management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildStatusRadioGroup(['Not planned', 'Planned', 'Completed'], _surgeryStatus, (value) {
                setState(() => _surgeryStatus = value);
                _autoSave();
              }),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _surgeryType,
                decoration: const InputDecoration(labelText: 'Procedure Type', border: OutlineInputBorder(), isDense: true),
                items: ['Total Thyroidectomy', 'Subtotal Thyroidectomy', 'Hemithyroidectomy', 'Lobectomy']
                    .map((proc) => DropdownMenuItem(value: proc, child: Text(proc))).toList(),
                onChanged: (value) {
                  setState(() => _surgeryType = value);
                  _autoSave();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRadioGroup(List<String> options, int selectedIndex, Function(int) onChanged) {
    return Wrap(
      spacing: 16,
      children: options.asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              value: entry.key,
              groupValue: selectedIndex,
              onChanged: (value) => onChanged(value as int),
            ),
            Text(entry.value),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTreatmentTargetsCard() {
    final targets = widget.diseaseConfig.targets;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TREATMENT TARGETS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: _treatmentGoalController,
              decoration: const InputDecoration(labelText: 'Treatment Goal', hintText: 'e.g., Achieve euthyroid state', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            if (targets != null && targets.isNotEmpty) ...[
              const Text('Target Lab Values:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...targets.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    Text('${entry.key}:', style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(entry.value.toString(), style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringPlanCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MONITORING PLAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: _monitoringPlanController,
              decoration: const InputDecoration(
                labelText: 'Monitoring Schedule',
                hintText: 'e.g., Check TFT every 6 weeks until stable',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            const Text('Regular Monitoring:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            CheckboxListTile(title: const Text('Check lab tests regularly'), value: true, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Monitor for side effects'), value: true, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Adjust medications as needed'), value: true, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FOLLOW-UP SCHEDULE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF2563EB)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Next Visit', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          widget.condition.nextVisit != null ? _formatDate(widget.condition.nextVisit!) : 'Not scheduled',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: () => _selectFollowUpDate(context), child: const Text('Set Date')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientEducationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PATIENT EDUCATION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            CheckboxListTile(title: const Text('Explained disease process'), value: false, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Discussed treatment options'), value: false, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Warned about side effects'), value: false, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Advised on medication compliance'), value: false, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
            CheckboxListTile(title: const Text('Provided written information'), value: false, onChanged: (value) {}, contentPadding: EdgeInsets.zero),
          ],
        ),
      ),
    );
  }

  bool _showRadioiodineOption() => widget.condition.category == 'hyperthyroidism' || widget.condition.category == 'cancer';
  bool _showSurgeryOption() => widget.condition.category == 'hyperthyroidism' || widget.condition.category == 'nodules' || widget.condition.category == 'cancer';
  bool _showAdvancedTreatments() => _showRadioiodineOption() || _showSurgeryOption();

  void _showAddMedicationDialog(BuildContext context) {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final frequencyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medication Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: doseController, decoration: const InputDecoration(labelText: 'Dose (e.g., 50 mg)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: frequencyController, decoration: const InputDecoration(labelText: 'Frequency (e.g., Once daily)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newMed = Medication(
                  id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  dose: doseController.text,
                  frequency: frequencyController.text,
                  startDate: DateTime.now(),
                );
                final updatedMeds = List<Medication>.from(widget.condition.medications)..add(newMed);
                widget.onUpdate(widget.condition.copyWith(medications: updatedMeds));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editMedication(Medication medication) {
    final nameController = TextEditingController(text: medication.name);
    final doseController = TextEditingController(text: medication.dose);
    final frequencyController = TextEditingController(text: medication.frequency);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medication'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Medication Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: doseController, decoration: const InputDecoration(labelText: 'Dose (e.g., 50 mg)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: frequencyController, decoration: const InputDecoration(labelText: 'Frequency (e.g., Once daily)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedMed = Medication(
                  id: medication.id,
                  name: nameController.text,
                  dose: doseController.text,
                  frequency: frequencyController.text,
                  startDate: medication.startDate,
                  indication: medication.indication,
                  isActive: medication.isActive,
                );

                final updatedMeds = widget.condition.medications.map((m) {
                  return m.id == medication.id ? updatedMed : m;
                }).toList();

                widget.onUpdate(widget.condition.copyWith(medications: updatedMeds));
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medication updated successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _quickAddMedication(dynamic treatment) {
    final newMed = Medication(
      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
      name: treatment['name'] as String,
      dose: treatment['defaultDose'] as String? ?? '',
      frequency: treatment['frequency'] as String? ?? 'As directed',
      startDate: DateTime.now(),
    );
    final updatedMeds = List<Medication>.from(widget.condition.medications)..add(newMed);
    widget.onUpdate(widget.condition.copyWith(medications: updatedMeds));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newMed.name} added'), backgroundColor: Colors.green));
  }

  void _removeMedication(Medication medication) {
    final updatedMeds = List<Medication>.from(widget.condition.medications)..remove(medication);
    widget.onUpdate(widget.condition.copyWith(medications: updatedMeds));
  }

  Future<void> _selectFollowUpDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: widget.condition.nextVisit ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      // TODO: Update follow-up date in condition
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _treatmentGoalController.dispose();
    _monitoringPlanController.dispose();
    _dietPlanController.dispose();
    _lifestyleController.dispose();
    super.dispose();
  }
}