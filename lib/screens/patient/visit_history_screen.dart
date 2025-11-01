// ==================== VISIT HISTORY SCREEN ====================
// lib/screens/patient/visit_history_screen.dart
// ✅ Now shows BOTH canvas visits AND endocrine/medical template visits

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../models/visit.dart';
import '../../models/endocrine/endocrine_condition.dart';  // ✅ NEW IMPORT
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
  List<EndocrineCondition> _endocrineVisits = [];  // ✅ NEW: Store endocrine visits
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  // ✅ UPDATED: Load BOTH regular visits AND endocrine visits
  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    try {
      // Load regular visits (kidney/canvas)
      final regularVisits = await DatabaseHelper.instance.getPatientVisits(widget.patient.id);

      // ✅ NEW: Load endocrine visits (medical templates)
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
          // ✅ Show Endocrine/Medical Template Visits First
          if (_endocrineVisits.isNotEmpty) ...[
            _buildSectionHeader('Medical Templates', Icons.science, Colors.pink),
            const SizedBox(height: 12),
            ..._endocrineVisits.map((condition) => _buildEndocrineVisitCard(condition)),
            const SizedBox(height: 24),
          ],

          // Show Regular Canvas Visits
          if (_visits.isNotEmpty) ...[
            _buildSectionHeader('Canvas Diagrams', Icons.draw, Colors.blue),
            const SizedBox(height: 12),
            ..._visits.map((visit) => _buildVisitCard(visit)),
          ],
        ],
      ),
    );
  }

  // ✅ NEW: Section header
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

  // ✅ NEW: Build endocrine visit card
  Widget _buildEndocrineVisitCard(EndocrineCondition condition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openEndocrineVisit(condition),
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
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.science, color: Colors.pink.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          condition.diseaseName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(condition.createdAt),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(condition.status.toString().split('.').last),
                ],
              ),
              if (condition.chiefComplaint != null && condition.chiefComplaint!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  condition.chiefComplaint!,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.medication, '${condition.medications.length} meds'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.science, '${condition.labReadings.length} labs'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.warning_amber, '${condition.complications.length} issues'),
                ],
              ),
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

  // ✅ NEW: Open endocrine visit
  void _openEndocrineVisit(EndocrineCondition condition) {
    // Navigate back to the thyroid module screen
    Navigator.pushNamed(
      context,
      '/thyroid-module',
      arguments: {
        'patientId': widget.patient.id,
        'patientName': widget.patient.name,
        'diseaseId': condition.diseaseId,
        'diseaseName': condition.diseaseName,
      },
    );
  }

  // Existing method for regular visits
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.draw, color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.diagramType.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(visit.createdAt),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No visits yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Visit history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}