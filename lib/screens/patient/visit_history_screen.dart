// ==================== UPDATED VISIT HISTORY SCREEN ====================
// lib/screens/patient/visit_history_screen.dart
// ✅ Shows BOTH canvas visits AND endocrine/medical template visits
// ✅ EDIT/DELETE functionality for medical templates

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../models/visit.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../services/database_helper.dart';
import '../kidney/visit_view_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  final Patient patient;

  const VisitHistoryScreen({super.key, required this.patient});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  List<Visit> _visits = [];
  List<EndocrineCondition> _endocrineVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  // Load BOTH regular visits AND endocrine visits
  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    try {
      final regularVisits = await DatabaseHelper.instance.getPatientVisits(widget.patient.id);
      final endocrineVisits = await DatabaseHelper.instance.getEndocrineVisitsByPatient(widget.patient.id);

      if (mounted) {
        setState(() {
          _visits = regularVisits;
          _endocrineVisits = endocrineVisits;
          _isLoading = false;
        });
        print('✅ Loaded ${regularVisits.length} canvas visits + ${endocrineVisits.length} medical templates');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading visits: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${widget.patient.name} - Visit History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty && _endocrineVisits.isEmpty
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Medical Templates Section
          if (_endocrineVisits.isNotEmpty) ...[
            _buildSectionHeader('Medical Templates', Icons.science, Colors.pink),
            const SizedBox(height: 12),
            ..._endocrineVisits.map((condition) => _buildEndocrineVisitCard(condition)),
            const SizedBox(height: 24),
          ],

          // Canvas Diagrams Section
          if (_visits.isNotEmpty) ...[
            _buildSectionHeader('Canvas Diagrams', Icons.draw, Colors.blue),
            const SizedBox(height: 12),
            ..._visits.map((visit) => _buildVisitCard(visit)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No visit history yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new visit to see records here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Endocrine visit card with EDIT/DELETE options
  Widget _buildEndocrineVisitCard(EndocrineCondition condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _editEndocrineVisit(condition),  // ✅ Tap to edit
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.science, color: Colors.pink, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition.diseaseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(condition.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ EDIT/DELETE BUTTONS
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.blue,
                        tooltip: 'Edit',
                        onPressed: () => _editEndocrineVisit(condition),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        tooltip: 'Delete',
                        onPressed: () => _deleteEndocrineVisit(condition),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(condition.status.toString().split('.').last),
                  if (condition.severity != null)
                    _buildInfoChip(Icons.warning_amber, condition.severity.toString().split('.').last),
                  if (condition.labReadings.isNotEmpty)
                    _buildInfoChip(Icons.science, '${condition.labReadings.length} labs'),
                  if (condition.medications.isNotEmpty)
                    _buildInfoChip(Icons.medication, '${condition.medications.length} meds'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'suspected': Colors.orange,
      'provisional': Colors.blue,
      'confirmed': Colors.green,
      'ruledOut': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[status] ?? Colors.grey),
      ),
      child: Text(
        status == 'ruledOut' ? 'Ruled Out' : status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors[status] ?? Colors.grey,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  // ✅ EDIT: Open endocrine visit for editing
  void _editEndocrineVisit(EndocrineCondition condition) async {
    final result = await Navigator.pushNamed(
      context,
      '/thyroid-module',
      arguments: {
        'patientId': widget.patient.id,
        'patientName': widget.patient.name,
        'diseaseId': condition.diseaseId,
        'diseaseName': condition.diseaseName,
      },
    );

    // Reload visits after returning
    if (result != null) {
      _loadVisits();
    }
  }

  // ✅ DELETE: Delete endocrine visit with confirmation
  void _deleteEndocrineVisit(EndocrineCondition condition) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Delete Template?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this medical template?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.diseaseName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(condition.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ✅ Delete from database
        await DatabaseHelper.instance.deleteEndocrineVisit(condition.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${condition.diseaseName} deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Reload visits
          _loadVisits();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Existing method for regular canvas visits
  Widget _buildVisitCard(Visit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openVisit(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.draw, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.system.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(visit.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openVisit(Visit visit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisitViewScreen(
          patient: widget.patient,
          visit: visit,
        ),
      ),
    );
  }
}