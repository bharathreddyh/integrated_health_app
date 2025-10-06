// lib/screens/lab_test/lab_test_management_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../models/lab_test.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';
import '../../data/lab_test_templates.dart';

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
  List<LabTest> _labTests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLabTests();
  }

  Future<void> _loadLabTests() async {
    try {
      final tests = await DatabaseHelper.instance.getLabTestsByVisit(widget.visitId);
      print('Loaded ${tests.length} lab tests'); // DEBUG
      setState(() {
        _labTests = tests;
        _loading = false;
      });
    } catch (e) {
      print('Error loading lab tests: $e'); // DEBUG
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading lab tests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _orderTest() async {
    final result = await showDialog<LabTest>(
      context: context,
      builder: (context) => OrderLabTestDialog(
        visitId: widget.visitId,
        patientId: widget.patientId,
      ),
    );

    if (result != null) {
      final doctorId = UserService.currentUserId ?? 'USR001';
      await DatabaseHelper.instance.insertLabTest(result, doctorId);
      _loadLabTests();
    }
  }

  Future<void> _enterResult(LabTest test) async {
    final result = await showDialog<LabTest>(
      context: context,
      builder: (context) => EnterResultDialog(labTest: test),
    );

    if (result != null) {
      final doctorId = UserService.currentUserId ?? 'USR001';
      await DatabaseHelper.instance.updateLabTest(result, doctorId);
      _loadLabTests();
    }
  }

  Future<void> _deleteTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test'),
        content: const Text('Are you sure you want to delete this lab test?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteLabTest(id);
      _loadLabTests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Tests'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Patient Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.cyan.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.cyan,
                  child: const Icon(Icons.science, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.patient.id} | Age: ${widget.patient.age}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats
          if (_labTests.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(
                    'Total Tests',
                    _labTests.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatChip(
                    'Pending',
                    _labTests.where((t) => t.status == LabTestStatus.pending).length.toString(),
                    Colors.orange,
                  ),
                  _buildStatChip(
                    'Abnormal',
                    _labTests.where((t) => t.isAbnormal).length.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ),

          // Test List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _labTests.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.science_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No lab tests ordered yet',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _labTests.length,
              itemBuilder: (context, index) {
                final test = _labTests[index];
                return _buildLabTestCard(test);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _orderTest,
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.add),
        label: const Text('Order Test'),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildLabTestCard(LabTest test) {
    final isPending = test.status == LabTestStatus.pending;
    final isAbnormal = test.isAbnormal && !isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAbnormal
                ? Colors.red.shade100
                : isPending
                ? Colors.orange.shade100
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isAbnormal
                ? Icons.warning
                : isPending
                ? Icons.pending
                : Icons.check_circle,
            color: isAbnormal
                ? Colors.red.shade700
                : isPending
                ? Colors.orange.shade700
                : Colors.green.shade700,
          ),
        ),
        title: Text(
          test.testName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Ordered: ${DateFormat('MMM dd, yyyy').format(test.orderedDate)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (test.status == LabTestStatus.completed && test.resultValue != null)
              Text(
                'Result: ${test.resultValue} ${test.resultUnit ?? ""}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAbnormal ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
          ],
        ),
        trailing: test.status == LabTestStatus.pending
            ? ElevatedButton.icon(
          onPressed: () => _enterResult(test),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Result'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Category', test.testCategory.displayName),
                const SizedBox(height: 8),
                _buildDetailRow('Status', test.status.name.toUpperCase()),
                if (test.resultValue != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Result Value', '${test.resultValue} ${test.resultUnit ?? ""}'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Normal Range', test.normalRangeDisplay),
                  if (test.resultDate != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Result Date',
                      DateFormat('MMM dd, yyyy').format(test.resultDate!),
                    ),
                  ],
                ],
                if (test.notes != null && test.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow('Notes', test.notes!),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (test.status == LabTestStatus.completed)
                      TextButton.icon(
                        onPressed: () => _enterResult(test),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Result'),
                      ),
                    TextButton.icon(
                      onPressed: () => _deleteTest(test.id!),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ORDER LAB TEST DIALOG
class OrderLabTestDialog extends StatefulWidget {
  final int visitId;
  final String patientId;

  const OrderLabTestDialog({
    super.key,
    required this.visitId,
    required this.patientId,
  });

  @override
  State<OrderLabTestDialog> createState() => _OrderLabTestDialogState();
}

class _OrderLabTestDialogState extends State<OrderLabTestDialog> {
  final _searchController = TextEditingController();
  LabTestTemplate? _selectedTemplate;
  final _notesController = TextEditingController();

  List<LabTestTemplate> _filteredTemplates = LabTestTemplates.flatList;

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _filterTemplates(String query) {
    setState(() {
      _filteredTemplates = query.isEmpty
          ? LabTestTemplates.flatList
          : LabTestTemplates.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Order Lab Test'),
      content: SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Tests',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterTemplates,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = _filteredTemplates[index];
                  final isSelected = _selectedTemplate == template;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.cyan.shade50,
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.cyan : Colors.grey.shade300,
                      child: Icon(
                        Icons.science,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    title: Text(template.name),
                    subtitle: Text(
                      '${template.category.displayName} • ${template.unit}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.cyan)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedTemplate = template;
                      });
                    },
                  );
                },
              ),
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedTemplate == null
              ? null
              : () {
            final test = LabTest(
              visitId: widget.visitId,
              patientId: widget.patientId,
              testName: _selectedTemplate!.name,
              testCategory: _selectedTemplate!.category,
              orderedDate: DateTime.now(),
              normalRangeMin: _selectedTemplate!.normalRangeMin,
              normalRangeMax: _selectedTemplate!.normalRangeMax,
              resultUnit: _selectedTemplate!.unit,
              status: LabTestStatus.pending,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
              createdAt: DateTime.now(),
            );
            Navigator.pop(context, test);
          },
          child: const Text('Order Test'),
        ),
      ],
    );
  }
}

// ENTER RESULT DIALOG
class EnterResultDialog extends StatefulWidget {
  final LabTest labTest;

  const EnterResultDialog({super.key, required this.labTest});

  @override
  State<EnterResultDialog> createState() => _EnterResultDialogState();
}

class _EnterResultDialogState extends State<EnterResultDialog> {
  late TextEditingController _resultController;
  late TextEditingController _notesController;
  late DateTime _resultDate;

  @override
  void initState() {
    super.initState();
    _resultController = TextEditingController(text: widget.labTest.resultValue ?? '');
    _notesController = TextEditingController(text: widget.labTest.notes ?? '');
    _resultDate = widget.labTest.resultDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Result - ${widget.labTest.testName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Normal Range: ${widget.labTest.normalRangeDisplay} ${widget.labTest.resultUnit ?? ""}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _resultController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Result Value',
                suffixText: widget.labTest.resultUnit,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _resultDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _resultDate = date);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('Result Date: ${DateFormat('MMM dd, yyyy').format(_resultDate)}'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_resultController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter result value')),
              );
              return;
            }

            final updatedTest = widget.labTest.copyWith(
              resultValue: _resultController.text,
              resultDate: _resultDate,
              status: LabTestStatus.completed,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
              isAbnormal: widget.labTest.copyWith(
                resultValue: _resultController.text,
              ).checkIfAbnormal(),
            );

            Navigator.pop(context, updatedTest);
          },
          child: const Text('Save Result'),
        ),
      ],
    );
  }
}