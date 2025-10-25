// lib/widgets/investigation_finding_card.dart
// Beautiful card widget to display investigation findings (USG, CT, MRI, FNAC, etc.)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvestigationFindingCard extends StatelessWidget {
  final String id;
  final String investigationType; // 'ultrasound', 'ct', 'mri', 'biopsy', 'nuclear', 'cardiac', 'other'
  final String investigationName;
  final DateTime performedDate;
  final String findings;
  final String impression;
  final Map<String, dynamic>? structuredData;
  final String? performedBy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  const InvestigationFindingCard({
    super.key,
    required this.id,
    required this.investigationType,
    required this.investigationName,
    required this.performedDate,
    required this.findings,
    required this.impression,
    this.structuredData,
    this.performedBy,
    this.onEdit,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTypeColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with investigation name and type badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        investigationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(performedDate),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTypeBadge(),
              ],
            ),

            const SizedBox(height: 16),

            // Structured data display (if available)
            if (structuredData != null && structuredData!.isNotEmpty)
              _buildStructuredDataSection(),

            // Findings section
            if (findings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.description,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Findings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      findings,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Impression section
            if (impression.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            size: 16, color: Colors.purple.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Impression',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      impression,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.purple.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Performed by info
            if (performedBy != null && performedBy!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Performed by: $performedBy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onViewDetails != null)
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: _getTypeColor(),
                    ),
                  ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    color: Colors.blue,
                    tooltip: 'Edit Finding',
                    splashRadius: 20,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: Colors.red,
                    tooltip: 'Delete Finding',
                    splashRadius: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build structured data section based on investigation type
  Widget _buildStructuredDataSection() {
    if (investigationType == 'ultrasound' &&
        investigationName.contains('Thyroid')) {
      return _buildUSGThyroidData();
    } else if (investigationType == 'biopsy' &&
        investigationName.contains('FNAC')) {
      return _buildFNACData();
    } else if (investigationType == 'cardiac' &&
        investigationName.contains('ECHO')) {
      return _buildECHOData();
    } else {
      // Generic structured data display
      return _buildGenericStructuredData();
    }
  }

  // USG Thyroid specific display
  Widget _buildUSGThyroidData() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 6),
              Text(
                'Thyroid Dimensions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (structuredData!['rightLobeLength'] != null)
            _buildDimensionRow(
              'Right Lobe',
              '${structuredData!['rightLobeLength']} × ${structuredData!['rightLobeWidth']} × ${structuredData!['rightLobeDepth']} cm',
            ),
          if (structuredData!['leftLobeLength'] != null)
            _buildDimensionRow(
              'Left Lobe',
              '${structuredData!['leftLobeLength']} × ${structuredData!['leftLobeWidth']} × ${structuredData!['leftLobeDepth']} cm',
            ),
          if (structuredData!['isthmusThickness'] != null)
            _buildDimensionRow(
              'Isthmus',
              '${structuredData!['isthmusThickness']} mm',
            ),
          const SizedBox(height: 8),
          if (structuredData!['echogenicity'] != null)
            _buildInfoChip(
              'Echogenicity',
              structuredData!['echogenicity'],
              Colors.green,
            ),
          if (structuredData!['nodulesPresent'] == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Nodules: ${structuredData!['noduleCount'] ?? 'Present'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FNAC specific display
  Widget _buildFNACData() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, size: 16, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              Text(
                'Biopsy Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (structuredData!['bethesdaCategory'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getBethesdaColor(structuredData!['bethesdaCategory']),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Bethesda ${structuredData!['bethesdaCategory']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getBethesdaDescription(structuredData!['bethesdaCategory']),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (structuredData!['site'] != null) ...[
            const SizedBox(height: 8),
            _buildDimensionRow('Site', structuredData!['site']),
          ],
        ],
      ),
    );
  }

  // ECHO specific display
  Widget _buildECHOData() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Text(
                'Cardiac Assessment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (structuredData!['ejectionFraction'] != null)
            Row(
              children: [
                Text(
                  'Ejection Fraction: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${structuredData!['ejectionFraction']}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Generic structured data display
  Widget _buildGenericStructuredData() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...structuredData!.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Wrap(
      spacing: 4,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: HSLColor.fromColor(color).withLightness(0.2).toColor(),
            ),
          ),
        ),
      ],
    );
  }

  // Build type badge
  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getTypeColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _getTypeLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Get color based on investigation type
  Color _getTypeColor() {
    switch (investigationType) {
      case 'ultrasound':
        return Colors.green.shade600;
      case 'ct':
        return Colors.blue.shade600;
      case 'mri':
        return Colors.purple.shade600;
      case 'biopsy':
        return Colors.orange.shade600;
      case 'nuclear':
        return Colors.teal.shade600;
      case 'cardiac':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get icon based on investigation type
  IconData _getTypeIcon() {
    switch (investigationType) {
      case 'ultrasound':
        return Icons.waves;
      case 'ct':
        return Icons.scanner;
      case 'mri':
        return Icons.medical_services;
      case 'biopsy':
        return Icons.biotech;
      case 'nuclear':
        return Icons.science;
      case 'cardiac':
        return Icons.favorite;
      default:
        return Icons.description;
    }
  }

  // Get label based on investigation type
  String _getTypeLabel() {
    switch (investigationType) {
      case 'ultrasound':
        return 'ULTRASOUND';
      case 'ct':
        return 'CT SCAN';
      case 'mri':
        return 'MRI';
      case 'biopsy':
        return 'BIOPSY';
      case 'nuclear':
        return 'NUCLEAR MED';
      case 'cardiac':
        return 'CARDIAC';
      default:
        return 'OTHER';
    }
  }

  // Get Bethesda category color
  Color _getBethesdaColor(String category) {
    switch (category) {
      case 'I':
        return Colors.grey.shade600;
      case 'II':
        return Colors.green.shade600;
      case 'III':
      case 'IV':
        return Colors.orange.shade600;
      case 'V':
      case 'VI':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Get Bethesda category description
  String _getBethesdaDescription(String category) {
    switch (category) {
      case 'I':
        return 'Non-diagnostic/Unsatisfactory';
      case 'II':
        return 'Benign';
      case 'III':
        return 'Atypia of Undetermined Significance';
      case 'IV':
        return 'Follicular Neoplasm/Suspicious';
      case 'V':
        return 'Suspicious for Malignancy';
      case 'VI':
        return 'Malignant';
      default:
        return '';
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}