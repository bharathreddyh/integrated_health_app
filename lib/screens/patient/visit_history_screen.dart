// lib/screens/patient/visit_history_screen.dart
// ✅ FIXED: Now passes specific condition ID when opening saved templates

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
          : RefreshIndicator(
        onRefresh: _loadVisits,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_endocrineVisits.isNotEmpty) ...[
              _buildSectionHeader(
                Icons.science,
                'Medical Templates',
                Colors.pink,
              ),
              ..._endocrineVisits.map((condition) => _buildEndocrineVisitCard(condition)),
              const SizedBox(height: 24),
            ],
            if (_visits.isNotEmpty) ...[
              _buildSectionHeader(
                Icons.draw,
                'Canvas Diagrams',
                Colors.blue,
              ),
              ..._visits.map((visit) => _buildVisitCard(visit)),
            ],
          ],
        ),
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
            'No Visit History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient has no recorded visits yet',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
      ),
    );
  }

  Widget _buildEndocrineVisitCard(EndocrineCondition condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _editEndocrineVisit(condition),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy • h:mm a').format(condition.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(condition.status.toString().split('.').last),
                ],
              ),
              if (condition.chiefComplaint != null ||
                  condition.labReadings.isNotEmpty ||
                  condition.medications.isNotEmpty) ...[
                const Divider(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (condition.chiefComplaint != null && condition.chiefComplaint!.isNotEmpty)
                      _buildInfoChip(Icons.notes, 'Chief Complaint'),
                    if (condition.labReadings.isNotEmpty)
                      _buildInfoChip(Icons.science, '${condition.labReadings.length} Labs'),
                    if (condition.medications.isNotEmpty)
                      _buildInfoChip(Icons.medication, '${condition.medications.length} Meds'),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteEndocrineVisit(condition),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editEndocrineVisit(condition),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Visit visit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitViewScreen(
                visit: visit,
                patient: widget.patient,
              ),
            ),
          );
        },
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
                      '${visit.system.toUpperCase()} - ${visit.diagramType}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • h:mm a').format(visit.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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

  // ✅ FIXED: Now passes the specific condition ID
  void _editEndocrineVisit(EndocrineCondition condition) async {
    print('📱 Opening template: ${condition.diseaseName}');
    print('   Condition ID: ${condition.id}');
    print('   Patient: ${widget.patient.name}');

    final result = await Navigator.pushNamed(
      context,
      '/thyroid-module',
      arguments: {
        'patientId': widget.patient.id,
        'patientName': widget.patient.name,
        'diseaseId': condition.diseaseId,
        'diseaseName': condition.diseaseName,
        'conditionId': condition.id,  // ✅ CRITICAL FIX: Pass the specific condition ID
      },
    );

    if (result != null) {
      _loadVisits();
    }
  }

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
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(condition.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.deleteEndocrineVisit(condition.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Template deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadVisits();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error deleting: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}