import 'package:flutter/material.dart';
import '../models/endocrine/lab_test_result.dart';
import 'package:intl/intl.dart';

class LabTestResultCard extends StatelessWidget {
  final LabTestResult result;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewTrend;

  const LabTestResultCard({
    super.key,
    required this.result,
    this.onEdit,
    this.onDelete,
    this.onViewTrend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with test name and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    result.testName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),

            // Value and reference range
            Row(
              children: [
                // Test value
                Text(
                  '${result.value} ${result.unit}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 16),
                // Reference range
                Expanded(
                  child: Text(
                    'Normal: ${result.normalMin}-${result.normalMax} ${result.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and lab info
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Date
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(result.testDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // Lab name (if provided)
                if (result.reportedBy != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_hospital,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.reportedBy!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Notes section (if present)
            if (result.notes != null && result.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_alt,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Trend button (only show if callback provided)
                if (onViewTrend != null)
                  TextButton.icon(
                    onPressed: onViewTrend,
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('Trend'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                    ),
                  ),
                const SizedBox(width: 8),
                // Edit button
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    color: Colors.blue,
                    tooltip: 'Edit Result',
                    splashRadius: 20,
                  ),
                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                    tooltip: 'Delete Result',
                    splashRadius: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build status badge (Normal/High/Low)
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Get status color based on result
  Color _getStatusColor() {
    switch (result.status) {
      case 'high':
      case 'low':
        return Colors.red.shade600;
      case 'normal':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get status icon
  IconData _getStatusIcon() {
    switch (result.status) {
      case 'high':
        return Icons.arrow_upward;
      case 'low':
        return Icons.arrow_downward;
      case 'normal':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  // Get status text
  String _getStatusText() {
    switch (result.status) {
      case 'high':
        return 'HIGH';
      case 'low':
        return 'LOW';
      case 'normal':
        return 'NORMAL';
      default:
        return 'UNKNOWN';
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}