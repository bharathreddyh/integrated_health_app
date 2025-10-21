// ==================== UPDATED TAB 5: INVESTIGATIONS ====================
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

  // Thyroid-specific Lab Tests
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

  // Thyroid-specific Investigations
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
    // TODO: Load lab tests and investigations from condition.additionalData
  }

  void _onDataChanged() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // TODO: Save lab tests and investigations to condition.additionalData

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

          // Recommended Investigations Card
          _buildDiseaseSpecificInvestigationsCard(),
          const SizedBox(height: 20),

          // Lab Tests Card
          _buildLabTestsCard(),
          const SizedBox(height: 20),

          // Investigations Card
          _buildInvestigationsCard(),
          const SizedBox(height: 20),

          // Investigation Summary
          _buildInvestigationSummary(),
        ],
      ),
    );
  }

  Widget _buildDiseaseSpecificInvestigationsCard() {
    final recommendations = _getRecommendedInvestigations();

    if (recommendations.isEmpty) return const SizedBox();

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
                const Icon(Icons.checklist, color: Color(0xFF2563EB)),
                const SizedBox(width: 12),
                const Text(
                  'RECOMMENDED INVESTIGATIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'For ${widget.diseaseConfig.name}:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendations.map((test) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      test,
                      style: const TextStyle(fontSize: 13),
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
                        Text(
                          test.category,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (test.isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            test.isUrgent ? Icons.flag : Icons.flag_outlined,
                            color: test.isUrgent ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _orderedLabTests[index].isUrgent = !test.isUrgent;
                            });
                            _onDataChanged();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _orderedLabTests.removeAt(index);
                            });
                            _onDataChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),

            // Add Lab Tests Button
            ElevatedButton.icon(
              onPressed: _showLabTestsDialog,
              icon: const Icon(Icons.add),
              label: Text(_orderedLabTests.isEmpty ? 'Add Lab Tests' : 'Add More Tests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
            ),
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
                        Text(
                          investigation.category,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (investigation.isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            investigation.isUrgent ? Icons.flag : Icons.flag_outlined,
                            color: investigation.isUrgent ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _orderedInvestigations[index].isUrgent = !investigation.isUrgent;
                            });
                            _onDataChanged();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _orderedInvestigations.removeAt(index);
                            });
                            _onDataChanged();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),

            // Add Investigations Button
            ElevatedButton.icon(
              onPressed: _showInvestigationsDialog,
              icon: const Icon(Icons.add),
              label: Text(_orderedInvestigations.isEmpty ? 'Add Investigations' : 'Add More Investigations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationSummary() {
    final totalItems = _orderedLabTests.length + _orderedInvestigations.length;

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
                  'Investigation Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Lab Tests Ordered', '${_orderedLabTests.length}'),
            _buildSummaryRow('Investigations Ordered', '${_orderedInvestigations.length}'),
            _buildSummaryRow('Total Items', '$totalItems'),

            if (totalItems > 0) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$totalItems investigation${totalItems == 1 ? '' : 's'} planned',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          Text(value, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showLabTestsDialog() async {
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

  Future<void> _showInvestigationsDialog() async {
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

// Multi-Select Dialog Widget
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
      final matchingItems = items.where((item) => item.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                border: Border(bottom: BorderSide(color: widget.color.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  if (_selectedItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(16)),
                      child: Text('${_selectedItems.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; })) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: Colors.grey.shade400), const SizedBox(height: 16), Text('No results found', style: TextStyle(color: Colors.grey.shade600))]))
                  : ListView.builder(
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final entry = filteredCategories[index];
                  final category = entry.key;
                  final items = entry.value;
                  final isExpanded = _expandedCategory == category;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(widget.icon, color: widget.color),
                          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${items.length} items'),
                          trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                          onTap: () => setState(() => _expandedCategory = isExpanded ? null : category),
                        ),
                        if (isExpanded)
                          Column(
                            children: items.map((item) {
                              final isSelected = _selectedItems.contains(item);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(item, style: const TextStyle(fontSize: 14)),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade300))),
              child: Row(
                children: [
                  TextButton(onPressed: () => setState(() => _selectedItems.clear()), child: const Text('Clear All')),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedItems.isEmpty ? null : () => Navigator.pop(context, _selectedItems.toList()),
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