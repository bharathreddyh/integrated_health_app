// lib/screens/lab_test/lab_test_management_screen.dart

import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/lab_test.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';

class LabTestManagementScreen extends StatefulWidget {
  final int visitId;
  final String patientId;
  final Patient patient;

  const LabTestManagementScreen({
    super.key,
    required this.visitId,
    required this.patientId,
    required this.patient,
  });

  @override
  State<LabTestManagementScreen> createState() => _LabTestManagementScreenState();
}

class _LabTestManagementScreenState extends State<LabTestManagementScreen> {
  String _selectedSystem = 'renal';
  List<LabTest> _savedTests = [];
  bool _isLoading = true;

  // Controllers for each test (created dynamically)
  final Map<String, TextEditingController> _testControllers = {};

  final Map<String, List<Map<String, dynamic>>> _testsBySystem = {
    'renal': [
      {
        'name': 'Serum Creatinine',
        'category': 'renal',
        'unit': 'mg/dL',
        'normalMin': '0.6',
        'normalMax': '1.2',
      },
      {
        'name': 'Blood Urea Nitrogen (BUN)',
        'category': 'renal',
        'unit': 'mg/dL',
        'normalMin': '7',
        'normalMax': '20',
      },
      {
        'name': 'eGFR',
        'category': 'renal',
        'unit': 'mL/min/1.73m²',
        'normalMin': '90',
        'normalMax': '120',
      },
      {
        'name': 'Serum Sodium',
        'category': 'renal',
        'unit': 'mEq/L',
        'normalMin': '135',
        'normalMax': '145',
      },
      {
        'name': 'Serum Potassium',
        'category': 'renal',
        'unit': 'mEq/L',
        'normalMin': '3.5',
        'normalMax': '5.0',
      },
      {
        'name': 'Urine Protein',
        'category': 'renal',
        'unit': 'mg/dL',
        'normalMin': '0',
        'normalMax': '10',
      },
    ],
    'endocrine': [
      {
        'name': 'Fasting Blood Sugar',
        'category': 'endocrine',
        'unit': 'mg/dL',
        'normalMin': '70',
        'normalMax': '100',
      },
      {
        'name': 'HbA1c',
        'category': 'endocrine',
        'unit': '%',
        'normalMin': '4.0',
        'normalMax': '5.6',
      },
      {
        'name': 'TSH',
        'category': 'endocrine',
        'unit': 'mIU/L',
        'normalMin': '0.4',
        'normalMax': '4.0',
      },
      {
        'name': 'T4 (Free)',
        'category': 'endocrine',
        'unit': 'ng/dL',
        'normalMin': '0.8',
        'normalMax': '1.8',
      },
    ],
    'hematology': [
      {
        'name': 'Hemoglobin',
        'category': 'hematology',
        'unit': 'g/dL',
        'normalMin': '12',
        'normalMax': '16',
      },
      {
        'name': 'WBC Count',
        'category': 'hematology',
        'unit': 'cells/µL',
        'normalMin': '4000',
        'normalMax': '11000',
      },
      {
        'name': 'Platelet Count',
        'category': 'hematology',
        'unit': 'cells/µL',
        'normalMin': '150000',
        'normalMax': '400000',
      },
      {
        'name': 'Hematocrit',
        'category': 'hematology',
        'unit': '%',
        'normalMin': '36',
        'normalMax': '46',
      },
    ],
    'biochemistry': [
      {
        'name': 'Total Cholesterol',
        'category': 'biochemistry',
        'unit': 'mg/dL',
        'normalMin': '0',
        'normalMax': '200',
      },
      {
        'name': 'LDL Cholesterol',
        'category': 'biochemistry',
        'unit': 'mg/dL',
        'normalMin': '0',
        'normalMax': '100',
      },
      {
        'name': 'HDL Cholesterol',
        'category': 'biochemistry',
        'unit': 'mg/dL',
        'normalMin': '40',
        'normalMax': '60',
      },
      {
        'name': 'Triglycerides',
        'category': 'biochemistry',
        'unit': 'mg/dL',
        'normalMin': '0',
        'normalMax': '150',
      },
      {
        'name': 'ALT',
        'category': 'biochemistry',
        'unit': 'U/L',
        'normalMin': '7',
        'normalMax': '56',
      },
      {
        'name': 'AST',
        'category': 'biochemistry',
        'unit': 'U/L',
        'normalMin': '10',
        'normalMax': '40',
      },
    ],
    'cardiac': [
      {
        'name': 'Troponin I',
        'category': 'cardiac',
        'unit': 'ng/mL',
        'normalMin': '0',
        'normalMax': '0.04',
      },
      {
        'name': 'CK-MB',
        'category': 'cardiac',
        'unit': 'ng/mL',
        'normalMin': '0',
        'normalMax': '5',
      },
      {
        'name': 'BNP',
        'category': 'cardiac',
        'unit': 'pg/mL',
        'normalMin': '0',
        'normalMax': '100',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSavedTests();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var system in _testsBySystem.keys) {
      for (var test in _testsBySystem[system]!) {
        _testControllers[test['name']] = TextEditingController();
      }
    }
  }

  Future<void> _loadSavedTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tests = await DatabaseHelper.instance.getLabTestsByVisit(widget.visitId);
      setState(() {
        _savedTests = tests;
        _isLoading = false;
      });

      // Pre-fill controllers with existing values
      for (var test in tests) {
        if (_testControllers.containsKey(test.testName)) {
          _testControllers[test.testName]!.text = test.resultValue ?? '';
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading tests: $e');
    }
  }

  Future<void> _saveAllTests() async {
    final doctorId = UserService.currentUserId ?? 'USR001';
    int savedCount = 0;

    try {
      for (var testDef in _testsBySystem[_selectedSystem]!) {
        final controller = _testControllers[testDef['name']]!;

        if (controller.text.isNotEmpty) {
          final value = double.tryParse(controller.text);
          if (value != null) {
            final normalMin = double.tryParse(testDef['normalMin']) ?? 0;
            final normalMax = double.tryParse(testDef['normalMax']) ?? 0;
            final isAbnormal = value < normalMin || value > normalMax;

            final labTest = LabTest(
              visitId: widget.visitId,
              patientId: widget.patientId,
              testName: testDef['name'],
              testCategory: testDef['category'],
              orderedDate: DateTime.now(),
              resultDate: DateTime.now(),
              resultValue: controller.text,
              resultUnit: testDef['unit'],
              normalRangeMin: testDef['normalMin'],
              normalRangeMax: testDef['normalMax'],
              isAbnormal: isAbnormal,
              status: 'completed',
              createdAt: DateTime.now(),
            );

            // Check if test already exists
            final existing = _savedTests.firstWhere(
                  (t) => t.testName == testDef['name'],
              orElse: () => LabTest(
                visitId: widget.visitId,
                patientId: widget.patientId,
                testName: '',
                testCategory: '',
                orderedDate: DateTime.now(),
                status: 'pending',
                createdAt: DateTime.now(),
              ),
            );

            if (existing.testName.isNotEmpty) {
              // Update existing
              final updated = labTest.copyWith(id: existing.id);
              await DatabaseHelper.instance.updateLabTest(updated, doctorId);
            } else {
              // Create new
              await DatabaseHelper.instance.insertLabTest(labTest, doctorId);
            }
            savedCount++;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved $savedCount test result${savedCount != 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadSavedTests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving tests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearSystem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Values'),
        content: Text('Clear all entered values for ${_getSystemName(_selectedSystem)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        for (var testDef in _testsBySystem[_selectedSystem]!) {
          _testControllers[testDef['name']]!.clear();
        }
      });
    }
  }

  String _getSystemName(String key) {
    switch (key) {
      case 'renal':
        return 'Renal Function Tests';
      case 'endocrine':
        return 'Endocrine Tests';
      case 'hematology':
        return 'Hematology';
      case 'biochemistry':
        return 'Biochemistry';
      case 'cardiac':
        return 'Cardiac Markers';
      default:
        return key;
    }
  }

  String _getSystemIcon(String key) {
    switch (key) {
      case 'renal':
        return '🫘';
      case 'endocrine':
        return '📊';
      case 'hematology':
        return '🩸';
      case 'biochemistry':
        return '🧪';
      case 'cardiac':
        return '❤️';
      default:
        return '🔬';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lab Test Results', style: TextStyle(fontSize: 18)),
            Text(
              widget.patient.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.cyan.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearSystem,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // System Selector
          _buildSystemSelector(),

          // Test Entry Form
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTestEntryForm(),
          ),

          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSystemSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _testsBySystem.keys.map((system) {
            final isSelected = _selectedSystem == system;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getSystemIcon(system)),
                    const SizedBox(width: 6),
                    Text(_getSystemName(system)),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSystem = system;
                    });
                  }
                },
                selectedColor: Colors.cyan.shade100,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.cyan.shade900 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTestEntryForm() {
    final tests = _testsBySystem[_selectedSystem]!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final testDef = tests[index];
        final controller = _testControllers[testDef['name']]!;

        return _buildTestField(testDef, controller);
      },
    );
  }

  Widget _buildTestField(Map<String, dynamic> testDef, TextEditingController controller) {
    final normalMin = testDef['normalMin'];
    final normalMax = testDef['normalMax'];
    final unit = testDef['unit'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    testDef['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  _buildResultStatus(controller.text, normalMin, normalMax),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Normal Range: $normalMin - $normalMax $unit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Enter result value',
                suffixText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStatus(String value, String normalMin, String normalMax) {
    final numValue = double.tryParse(value);
    final min = double.tryParse(normalMin);
    final max = double.tryParse(normalMax);

    if (numValue == null || min == null || max == null) {
      return const SizedBox.shrink();
    }

    final isNormal = numValue >= min && numValue <= max;
    final isLow = numValue < min;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNormal
            ? Colors.green.shade100
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNormal ? Icons.check_circle : Icons.warning,
            size: 14,
            color: isNormal ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isNormal ? 'Normal' : (isLow ? 'Low' : 'High'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isNormal ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final hasValues = _testControllers.values.any((c) => c.text.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasValues ? _saveAllTests : null,
                icon: const Icon(Icons.save),
                label: const Text('Save All Results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _testControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}