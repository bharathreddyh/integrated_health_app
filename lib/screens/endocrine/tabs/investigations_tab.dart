// ==================== ENHANCED TAB 5: INVESTIGATIONS WITH QUICK ADD ====================
// lib/screens/endocrine/tabs/investigations_tab.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';

// Lab Test Model
class LabTestOrder {
  final String name;
  final String category;
  String? notes;
  bool isUrgent;

  LabTestOrder({
    required this.name,
    required this.category,
    this.notes,
    this.isUrgent = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'notes': notes,
    'isUrgent': isUrgent,
  };

  factory LabTestOrder.fromJson(Map<String, dynamic> json) => LabTestOrder(
    name: json['name'] as String,
    category: json['category'] as String,
    notes: json['notes'] as String?,
    isUrgent: json['isUrgent'] as bool? ?? false,
  );
}

// Investigation Model
class Investigation {
  final String name;
  final String category;
  String? notes;
  bool isUrgent;

  Investigation({
    required this.name,
    required this.category,
    this.notes,
    this.isUrgent = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'notes': notes,
    'isUrgent': isUrgent,
  };

  factory Investigation.fromJson(Map<String, dynamic> json) => Investigation(
    name: json['name'] as String,
    category: json['category'] as String,
    notes: json['notes'] as String?,
    isUrgent: json['isUrgent'] as bool? ?? false,
  );
}

class InvestigationsTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const InvestigationsTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<InvestigationsTab> createState() => _InvestigationsTabState();
}

class _InvestigationsTabState extends State<InvestigationsTab> {
  // Lab Tests & Investigations
  List<LabTestOrder> _orderedLabTests = [];
  List<Investigation> _orderedInvestigations = [];

  // Auto-save
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  DateTime? _lastSaved;

  // Get disease-specific recommended tests and investigations
  List<Map<String, dynamic>> get _quickAddTests {
    final recommendations = _getRecommendedInvestigations();
    final tests = <Map<String, dynamic>>[];

    for (final rec in recommendations) {
      // Parse test names from recommendations
      if (rec.toLowerCase().contains('tsh')) {
        tests.add({'name': 'TSH', 'category': 'Thyroid Function', 'description': 'Thyroid Stimulating Hormone'});
      }
      if (rec.toLowerCase().contains('free t4') || rec.toLowerCase().contains('t4')) {
        tests.add({'name': 'Free T4', 'category': 'Thyroid Function', 'description': 'Free Thyroxine'});
      }
      if (rec.toLowerCase().contains('free t3') || rec.toLowerCase().contains('t3')) {
        tests.add({'name': 'Free T3', 'category': 'Thyroid Function', 'description': 'Free Triiodothyronine'});
      }
      if (rec.toLowerCase().contains('anti-tpo') || rec.toLowerCase().contains('tpo')) {
        tests.add({'name': 'Anti-TPO', 'category': 'Antibodies', 'description': 'Thyroid Peroxidase Antibody'});
      }
      if (rec.toLowerCase().contains('trab') || rec.toLowerCase().contains('receptor antibod')) {
        tests.add({'name': 'TSH Receptor Antibody (TRAb)', 'category': 'Antibodies', 'description': 'TSH receptor antibodies'});
      }
      if (rec.toLowerCase().contains('anti-thyroglobulin')) {
        tests.add({'name': 'Anti-Thyroglobulin Antibody', 'category': 'Antibodies', 'description': 'Thyroglobulin antibodies'});
      }
      if (rec.toLowerCase().contains('calcitonin')) {
        tests.add({'name': 'Calcitonin', 'category': 'Tumor Markers', 'description': 'Calcitonin level'});
      }
    }

    // Remove duplicates
    final uniqueTests = <String, Map<String, dynamic>>{};
    for (final test in tests) {
      uniqueTests[test['name'] as String] = test;
    }

    return uniqueTests.values.toList();
  }

  List<Map<String, dynamic>> get _quickAddInvestigations {
    final recommendations = _getRecommendedInvestigations();
    final investigations = <Map<String, dynamic>>[];

    for (final rec in recommendations) {
      // Parse investigation names from recommendations
      if (rec.toLowerCase().contains('ultrasound') || rec.toLowerCase().contains('usg thyroid')) {
        investigations.add({'name': 'USG Thyroid', 'category': 'Imaging', 'description': 'Thyroid ultrasound'});
      }
      if (rec.toLowerCase().contains('doppler')) {
        investigations.add({'name': 'Thyroid ultrasound with Doppler', 'category': 'Imaging', 'description': 'USG with blood flow assessment'});
      }
      if (rec.toLowerCase().contains('fnac') || rec.toLowerCase().contains('fine needle')) {
        investigations.add({'name': 'FNAC Thyroid', 'category': 'Biopsy', 'description': 'Fine needle aspiration cytology'});
      }
      if (rec.toLowerCase().contains('radioiodine') || rec.toLowerCase().contains('uptake scan')) {
        investigations.add({'name': 'Radioiodine Uptake Scan', 'category': 'Imaging', 'description': 'RAI uptake study'});
      }
      if (rec.toLowerCase().contains('eye examination')) {
        investigations.add({'name': 'Eye Examination', 'category': 'Other', 'description': 'Ophthalmology assessment'});
      }
      if (rec.toLowerCase().contains('ct') || rec.toLowerCase().contains('mri')) {
        investigations.add({'name': 'CT Neck with Contrast', 'category': 'Imaging', 'description': 'For staging/assessment'});
      }
      if (rec.toLowerCase().contains('ecg')) {
        investigations.add({'name': 'ECG', 'category': 'Cardiac Assessment', 'description': 'Electrocardiogram'});
      }
      if (rec.toLowerCase().contains('echo')) {
        investigations.add({'name': 'ECHO (Echocardiography)', 'category': 'Cardiac Assessment', 'description': '2D Echo'});
      }
    }

    // Remove duplicates
    final uniqueInvestigations = <String, Map<String, dynamic>>{};
    for (final inv in investigations) {
      uniqueInvestigations[inv['name'] as String] = inv;
    }

    return uniqueInvestigations.values.toList();
  }

  // Thyroid-specific Lab Tests (full list)
  static const Map<String, List<String>> _thyroidLabTests = {
    'Thyroid Function': [
      'TSH',
      'Free T3',
      'Free T4',
      'Total T3',
      'Total T4',
      'Reverse T3',
    ],
    'Antibodies': [
      'Anti-TPO (Thyroid Peroxidase Antibody)',
      'Anti-Thyroglobulin Antibody',
      'TSH Receptor Antibody (TRAb)',
    ],
    'Tumor Markers': [
      'Thyroglobulin',
      'Calcitonin',
      'CEA (Carcinoembryonic Antigen)',
    ],
    'General': [
      'Complete Blood Count (CBC)',
      'Liver Function Test (LFT)',
      'Kidney Function Test (KFT)',
      'Lipid Profile',
      'Serum Calcium',
      'Vitamin D',
      'Vitamin B12',
    ],
  };

  // Thyroid-specific Investigations (full list)
  static const Map<String, List<String>> _thyroidInvestigations = {
    'Imaging': [
      'USG Thyroid',
      'USG Neck',
      'Thyroid Scan (Tc-99m)',
      'Radioiodine Uptake Scan',
      'CT Neck with Contrast',
      'MRI Neck',
      'PET-CT',
    ],
    'Procedures': [
      'FNAC Thyroid',
      'Core Needle Biopsy',
      'Thyroid Biopsy',
    ],
    'Cardiac Assessment': [
      'ECG',
      'ECHO (Echocardiography)',
      '2D ECHO',
      'Holter Monitoring',
    ],
    'Other': [
      'X-Ray Chest',
      'Bone Density Scan (DEXA)',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    // Load from condition.orderedLabTests and orderedInvestigations
    if (widget.condition.orderedLabTests != null) {
      setState(() {
        _orderedLabTests = widget.condition.orderedLabTests!
            .map((test) => LabTestOrder.fromJson(test))
            .toList();
      });
    }

    if (widget.condition.orderedInvestigations != null) {
      setState(() {
        _orderedInvestigations = widget.condition.orderedInvestigations!
            .map((inv) => Investigation.fromJson(inv))
            .toList();
      });
    }
  }

  void _onDataChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final updatedCondition = widget.condition.copyWith(
        orderedLabTests: _orderedLabTests.map((t) => t.toJson()).toList(),
        orderedInvestigations: _orderedInvestigations.map((i) => i.toJson()).toList(),
      );

      widget.onUpdate(updatedCondition);

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
                Text('Investigations saved'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isSaving ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isSaving ? Colors.orange.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSaving)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                      ),
                    )
                  else
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Last saved: ${_formatTime(_lastSaved!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isSaving ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Lab Tests Card
          _buildLabTestsCard(),
          const SizedBox(height: 20),

          // Investigations Card
          _buildInvestigationsCard(),
        ],
      ),
    );
  }

  Widget _buildLabTestsCard() {
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
                const Icon(Icons.science, color: Colors.purple),
                const SizedBox(width: 12),
                const Text(
                  'LAB TESTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddLabTestDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_orderedLabTests.isEmpty ? 'Add Lab Tests' : 'Add More Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ordered Lab Tests
            if (_orderedLabTests.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.science_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No lab tests ordered',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._orderedLabTests.asMap().entries.map((entry) {
                final index = entry.key;
                final test = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.purple.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Icon(Icons.science, color: Colors.purple.shade700, size: 20),
                    ),
                    title: Text(
                      test.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            test.category,
                            style: TextStyle(fontSize: 10, color: Colors.purple.shade900),
                          ),
                        ),
                        if (test.isUrgent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 10, color: Colors.red.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  'URGENT',
                                  style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _removeLabTest(index),
                    ),
                  ),
                );
              }).toList(),

            // 🆕 Quick Add Section for Common Lab Tests
            if (_orderedLabTests.isNotEmpty || _quickAddTests.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Quick Add Recommended Tests:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAddTests.map((test) {
                  final isAlreadyAdded = _orderedLabTests.any((t) => t.name == test['name']);
                  return _buildQuickAddTestChip(test, isAlreadyAdded);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationsCard() {
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
                const Icon(Icons.medical_information, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'INVESTIGATIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddInvestigationDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_orderedInvestigations.isEmpty ? 'Add Investigations' : 'Add More'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ordered Investigations
            if (_orderedInvestigations.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.medical_information_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No investigations ordered',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._orderedInvestigations.asMap().entries.map((entry) {
                final index = entry.key;
                final investigation = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.medical_information, color: Colors.blue.shade700, size: 20),
                    ),
                    title: Text(
                      investigation.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            investigation.category,
                            style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
                          ),
                        ),
                        if (investigation.isUrgent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.priority_high, size: 10, color: Colors.red.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  'URGENT',
                                  style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _removeInvestigation(index),
                    ),
                  ),
                );
              }).toList(),

            // 🆕 Quick Add Section for Common Investigations
            if (_orderedInvestigations.isNotEmpty || _quickAddInvestigations.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Quick Add Recommended Investigations:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAddInvestigations.map((investigation) {
                  final isAlreadyAdded = _orderedInvestigations.any((i) => i.name == investigation['name']);
                  return _buildQuickAddInvestigationChip(investigation, isAlreadyAdded);
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🆕 Quick Add Test Chip Widget
  Widget _buildQuickAddTestChip(Map<String, dynamic> test, bool isAlreadyAdded) {
    return InkWell(
      onTap: isAlreadyAdded ? null : () => _quickAddLabTest(test),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAlreadyAdded ? Colors.grey.shade200 : Colors.purple.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAlreadyAdded ? Colors.grey.shade400 : Colors.purple.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
              size: 16,
              color: isAlreadyAdded ? Colors.grey.shade600 : Colors.purple.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              test['name'] as String,
              style: TextStyle(
                fontSize: 13,
                color: isAlreadyAdded ? Colors.grey.shade600 : Colors.purple.shade900,
                fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Quick Add Investigation Chip Widget
  Widget _buildQuickAddInvestigationChip(Map<String, dynamic> investigation, bool isAlreadyAdded) {
    return InkWell(
      onTap: isAlreadyAdded ? null : () => _quickAddInvestigation(investigation),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAlreadyAdded ? Colors.grey.shade200 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAlreadyAdded ? Colors.grey.shade400 : Colors.blue.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAlreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
              size: 16,
              color: isAlreadyAdded ? Colors.grey.shade600 : Colors.blue.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              investigation['name'] as String,
              style: TextStyle(
                fontSize: 13,
                color: isAlreadyAdded ? Colors.grey.shade600 : Colors.blue.shade900,
                fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 Quick Add Lab Test Method
  void _quickAddLabTest(Map<String, dynamic> test) {
    final newTest = LabTestOrder(
      name: test['name'] as String,
      category: test['category'] as String,
      notes: test['description'] as String?,
    );

    setState(() {
      _orderedLabTests.add(newTest);
    });

    _onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newTest.name} added'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🆕 Quick Add Investigation Method
  void _quickAddInvestigation(Map<String, dynamic> investigation) {
    final newInvestigation = Investigation(
      name: investigation['name'] as String,
      category: investigation['category'] as String,
      notes: investigation['description'] as String?,
    );

    setState(() {
      _orderedInvestigations.add(newInvestigation);
    });

    _onDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newInvestigation.name} added'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddLabTestDialog() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Lab Tests',
        categories: _thyroidLabTests,
        icon: Icons.science,
        color: Colors.purple,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (var testName in selected) {
          String category = '';
          _thyroidLabTests.forEach((cat, tests) {
            if (tests.contains(testName)) category = cat;
          });

          if (!_orderedLabTests.any((t) => t.name == testName)) {
            _orderedLabTests.add(LabTestOrder(name: testName, category: category));
          }
        }
      });
      _onDataChanged();
    }
  }

  Future<void> _showAddInvestigationDialog() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) => _MultiSelectDialog(
        title: 'Select Investigations',
        categories: _thyroidInvestigations,
        icon: Icons.medical_information,
        color: Colors.blue,
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        for (var invName in selected) {
          String category = '';
          _thyroidInvestigations.forEach((cat, invs) {
            if (invs.contains(invName)) category = cat;
          });

          if (!_orderedInvestigations.any((i) => i.name == invName)) {
            _orderedInvestigations.add(Investigation(name: invName, category: category));
          }
        }
      });
      _onDataChanged();
    }
  }

  void _removeLabTest(int index) {
    setState(() {
      _orderedLabTests.removeAt(index);
    });
    _onDataChanged();
  }

  void _removeInvestigation(int index) {
    setState(() {
      _orderedInvestigations.removeAt(index);
    });
    _onDataChanged();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  List<String> _getRecommendedInvestigations() {
    final diseaseId = widget.condition.diseaseId;
    final category = widget.condition.category;

    if (diseaseId == 'graves_disease') {
      return [
        'Thyroid ultrasound with Doppler',
        'TSH, Free T4, Free T3',
        'TSH receptor antibodies (TRAb)',
        'Anti-TPO antibodies',
        'Radioiodine uptake scan (if diagnosis unclear)',
        'Eye examination (for thyroid eye disease)',
      ];
    } else if (category == 'nodules' || category == 'cancer') {
      return [
        'Thyroid ultrasound with TIRADS scoring',
        'Fine needle aspiration cytology (FNAC)',
        'TSH level',
        'Calcitonin (if medullary carcinoma suspected)',
        'CT/MRI neck (for staging if cancer confirmed)',
      ];
    } else if (category == 'hypothyroidism') {
      return [
        'TSH, Free T4',
        'Anti-TPO antibodies',
        'Anti-thyroglobulin antibodies',
        'Thyroid ultrasound (if goiter present)',
      ];
    } else if (category == 'hyperthyroidism') {
      return [
        'TSH, Free T4, Free T3',
        'Thyroid ultrasound',
        'Radioiodine uptake scan',
        'TSH receptor antibodies (if Graves suspected)',
      ];
    }

    return ['Thyroid ultrasound', 'TSH, Free T4'];
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

// ==================== MULTI-SELECT DIALOG WIDGET ====================
class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final Map<String, List<String>> categories;
  final IconData icon;
  final Color color;

  const _MultiSelectDialog({
    required this.title,
    required this.categories,
    required this.icon,
    required this.color,
  });

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  final Set<String> _selectedItems = {};
  String? _expandedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<String>>> get _filteredCategories {
    if (_searchQuery.isEmpty) return widget.categories.entries.toList();

    final filtered = <String, List<String>>{};
    widget.categories.forEach((category, items) {
      final matchingItems = items
          .where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
      if (matchingItems.isNotEmpty) filtered[category] = matchingItems;
    });
    return filtered.entries.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header with title and selected count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: widget.color.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selectedItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_selectedItems.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Category list with checkboxes
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final entry = filteredCategories[index];
                  final category = entry.key;
                  final items = entry.value;
                  final isExpanded = _expandedCategory == category;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(widget.icon, color: widget.color),
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('${items.length} items'),
                          trailing: Icon(
                            isExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          onTap: () => setState(() {
                            _expandedCategory =
                            isExpanded ? null : category;
                          }),
                        ),
                        if (isExpanded)
                          Column(
                            children: items.map((item) {
                              final isSelected =
                              _selectedItems.contains(item);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(
                                  item,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: isSelected,
                                activeColor: widget.color,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedItems.add(item);
                                    } else {
                                      _selectedItems.remove(item);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _selectedItems.clear()),
                    child: const Text('Clear All'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedItems.toList()),
                    icon: const Icon(Icons.check),
                    label: Text('Add ${_selectedItems.length}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
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
}