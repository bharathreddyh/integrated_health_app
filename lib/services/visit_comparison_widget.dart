// ==================== VISIT COMPARISON WIDGET ====================
// lib/widgets/visit_comparison_widget.dart

import 'package:flutter/material.dart';
import '../models/endocrine/endocrine_condition.dart';

class VisitComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> comparisonData;

  const VisitComparisonWidget({
    super.key,
    required this.comparisonData,
  });

  @override
  Widget build(BuildContext context) {
    if (!comparisonData['hasComparison']) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No previous visit data available for comparison'),
        ),
      );
    }

    final current = comparisonData['currentVisit'];
    final previous = comparisonData['previousVisit'];
    final changes = comparisonData['changes'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue.shade700),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison with Previous Visit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Previous: ${_formatDate(previous['date'])}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Lab Changes
        if (changes['labs'].isNotEmpty) ...[
          _buildSectionHeader('Laboratory Values'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: (changes['labs'] as Map<String, dynamic>).entries.map((entry) {
                  final testName = entry.key;
                  final data = entry.value as Map<String, dynamic>;
                  return _buildLabChangeRow(testName, data);
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Clinical Features Changes
        if (changes['features']['new'].isNotEmpty || changes['features']['resolved'].isNotEmpty) ...[
          _buildSectionHeader('Clinical Features'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if ((changes['features']['new'] as List).isNotEmpty) ...[
                    _buildFeatureChangeSection(
                      'New Symptoms/Signs',
                      changes['features']['new'],
                      Colors.orange,
                      Icons.add_circle_outline,
                    ),
                  ],
                  if ((changes['features']['resolved'] as List).isNotEmpty) ...[
                    if ((changes['features']['new'] as List).isNotEmpty)
                      Divider(height: 24),
                    _buildFeatureChangeSection(
                      'Resolved',
                      changes['features']['resolved'],
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],

        // Medication Changes
        if (changes['medications']['new'].isNotEmpty || changes['medications']['stopped'].isNotEmpty) ...[
          _buildSectionHeader('Medications'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if ((changes['medications']['new'] as List).isNotEmpty) ...[
                    _buildMedicationChangeSection(
                      'New Medications',
                      changes['medications']['new'],
                      Colors.blue,
                      Icons.medication,
                    ),
                  ],
                  if ((changes['medications']['stopped'] as List).isNotEmpty) ...[
                    if ((changes['medications']['new'] as List).isNotEmpty)
                      Divider(height: 24),
                    _buildMedicationChangeSection(
                      'Stopped',
                      changes['medications']['stopped'],
                      Colors.red,
                      Icons.cancel,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildLabChangeRow(String testName, Map<String, dynamic> data) {
    final trend = data['trend'] as String;
    final trendIcon = trend == 'up' ? Icons.trending_up : Icons.trending_down;
    final trendColor = trend == 'up' ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              testName,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              '${data['previous']}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '${data['current']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                SizedBox(width: 4),
                Text(
                  '${data['percentChange']}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChangeSection(String title, List features, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) => Chip(
            label: Text(feature),
            backgroundColor: color.withOpacity(0.1),
            labelStyle: TextStyle(color: color, fontSize: 12),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMedicationChangeSection(String title, List medications, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ...medications.map((med) => Padding(
          padding: const EdgeInsets.only(left: 26, bottom: 4),
          child: Text('• $med', style: TextStyle(fontSize: 13)),
        )),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}