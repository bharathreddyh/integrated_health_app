// ==================== TAB 2: LABS & TRENDS ====================
// lib/screens/endocrine/tabs/labs_trends_tab.dart

import 'package:flutter/material.dart';
import '../../../models/endocrine/endocrine_condition.dart';
import '../../../config/thyroid_disease_config.dart';

import '../../../widgets/simple_lab_chart.dart'; // Custom chart - no external package needed!

class LabsTrendsTab extends StatefulWidget {
  final EndocrineCondition condition;
  final ThyroidDiseaseConfig diseaseConfig;
  final Function(EndocrineCondition) onUpdate;

  const LabsTrendsTab({
    super.key,
    required this.condition,
    required this.diseaseConfig,
    required this.onUpdate,
  });

  @override
  State<LabsTrendsTab> createState() => _LabsTrendsTabState();
}

class _LabsTrendsTabState extends State<LabsTrendsTab> {
  String? _selectedTestForGraph;

  @override
  Widget build(BuildContext context) {
    final labTests = widget.diseaseConfig.labTests;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Add Button
          ElevatedButton.icon(
            onPressed: () => _showAddLabReadingDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Lab Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Lab Test Cards
          if (labTests != null && labTests.isNotEmpty)
            ...labTests.map((test) => _buildLabTestCard(test as Map<String, dynamic>))
          else
            _buildEmptyState(),

          const SizedBox(height: 24),

          // Trend Graph Section
          if (widget.condition.labReadings.isNotEmpty) ...[
            _buildTrendGraphSection(),
            const SizedBox(height: 24),
          ],

          // All Readings Table
          _buildAllReadingsTable(),
        ],
      ),
    );
  }

  Widget _buildLabTestCard(Map<String, dynamic> test) {
    final testName = test['name'] as String;
    final unit = test['unit'] as String;
    final normalMin = test['normalMin'] as double?;
    final normalMax = test['normalMax'] as double?;

    // Get latest reading for this test
    final latestReading = widget.condition.labReadings
        .where((r) => r.testName == testName)
        .fold<LabReading?>(
      null,
          (prev, curr) => (prev == null || curr.date.isAfter(prev.date)) ? curr : prev,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Normal: ${normalMin ?? '-'} - ${normalMax ?? '-'} $unit',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (latestReading != null)
                  _buildAbnormalityBadge(latestReading.abnormalityType),
              ],
            ),
            const SizedBox(height: 16),

            if (latestReading != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAbnormalityColor(latestReading.abnormalityType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getAbnormalityColor(latestReading.abnormalityType),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${latestReading.value} $unit',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getAbnormalityColor(latestReading.abnormalityType),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last tested: ${_formatDate(latestReading.date)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showGraphForTest(testName),
                      icon: const Icon(Icons.show_chart),
                      tooltip: 'View Trend',
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'No readings recorded yet',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Add New Reading Button
            TextButton.icon(
              onPressed: () => _showAddReadingForTest(context, test),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New Reading'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbnormalityBadge(AbnormalityType type) {
    String text;
    Color color;

    switch (type) {
      case AbnormalityType.low:
        text = '🔴 LOW';
        color = Colors.red;
        break;
      case AbnormalityType.normal:
        text = '🟢 NORMAL';
        color = Colors.green;
        break;
      case AbnormalityType.high:
        text = '🔴 HIGH';
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTrendGraphSection() {
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
                  'TREND GRAPHS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedTestForGraph,
                  hint: const Text('Select Test'),
                  items: _getAvailableTestsForGraph()
                      .map((test) => DropdownMenuItem(
                    value: test,
                    child: Text(test),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTestForGraph = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_selectedTestForGraph != null)
              _buildLineChart(_selectedTestForGraph!)
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  'Select a test to view trend',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(String testName) {
    final readings = widget.condition.labReadings
        .where((r) => r.testName == testName)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (readings.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text('No data available'),
      );
    }

    // Placeholder chart - you'll need fl_chart package
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Graph for $testName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${readings.length} readings available',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '(Line chart with readings over time)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllReadingsTable() {
    if (widget.condition.labReadings.isEmpty) {
      return const SizedBox();
    }

    final sortedReadings = List<LabReading>.from(widget.condition.labReadings)
      ..sort((a, b) => b.date.compareTo(a.date));

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
                  'ALL READINGS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Export to CSV/Excel
                  },
                  icon: const Icon(Icons.file_download, size: 16),
                  label: const Text('Export Data'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Test')),
                  DataColumn(label: Text('Value')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Notes')),
                ],
                rows: sortedReadings
                    .map((reading) => DataRow(
                  cells: [
                    DataCell(Text(_formatDate(reading.date))),
                    DataCell(Text(reading.testName)),
                    DataCell(Text('${reading.value} ${reading.unit}')),
                    DataCell(_buildStatusIndicator(reading.abnormalityType)),
                    DataCell(Text(
                      reading.notes.isEmpty ? '-' : reading.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                  ],
                ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AbnormalityType type) {
    IconData icon;
    Color color;

    switch (type) {
      case AbnormalityType.low:
        icon = Icons.arrow_downward;
        color = Colors.red;
        break;
      case AbnormalityType.normal:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case AbnormalityType.high:
        icon = Icons.arrow_upward;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No lab tests configured',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getAvailableTestsForGraph() {
    return widget.condition.labReadings.map((r) => r.testName).toSet().toList();
  }

  void _showGraphForTest(String testName) {
    setState(() {
      _selectedTestForGraph = testName;
    });
    // Optionally scroll to graph section
  }

  void _showAddLabReadingDialog(BuildContext context) {
    final labTests = widget.diseaseConfig.labTests;
    if (labTests == null || labTests.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Lab Reading'),
        content: const Text('Select a test to add a reading'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddReadingForTest(BuildContext context, Map<String, dynamic> test) {
    final valueController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${test['name']} Reading'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Value (${test['unit']})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              final value = double.tryParse(valueController.text);
              if (value != null) {
                final newReading = LabReading(
                  testName: test['name'] as String,
                  value: value,
                  unit: test['unit'] as String,
                  normalMin: test['normalMin'] as double?,
                  normalMax: test['normalMax'] as double?,
                  date: selectedDate,
                  notes: notesController.text,
                );

                final updatedReadings = List<LabReading>.from(widget.condition.labReadings)
                  ..add(newReading);

                widget.onUpdate(
                  widget.condition.copyWith(labReadings: updatedReadings),
                );

                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getAbnormalityColor(AbnormalityType type) {
    switch (type) {
      case AbnormalityType.low:
      case AbnormalityType.high:
        return Colors.red;
      case AbnormalityType.normal:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}