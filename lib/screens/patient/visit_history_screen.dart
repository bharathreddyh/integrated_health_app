import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/patient.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../endocrine/thyroid_disease_module_screen.dart';

/// Visit History Screen
/// Shows all saved disease templates/conditions for a specific patient
/// Allows viewing and editing previously saved data
class VisitHistoryScreen extends StatefulWidget {
  final Patient patient;

  const VisitHistoryScreen({super.key, required this.patient});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late Future<List<EndocrineCondition>> _visitsFuture;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  void _loadVisits() {
    setState(() {
      _visitsFuture = DatabaseHelper.instance.getEndocrineVisitsByPatient(widget.patient.id);
    });
  }

  void _openCondition(EndocrineCondition condition) async {
    print('📱 Opening saved condition: ${condition.diseaseName}');
    print('   Condition ID: ${condition.id}');
    print('   Patient: ${condition.patientName}');

    // Navigate to the disease module screen with the saved condition
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThyroidDiseaseModuleScreen(
          patientId: condition.patientId,
          patientName: condition.patientName,
          diseaseId: condition.diseaseId,
          diseaseName: condition.diseaseName,
          conditionId: condition.id, // Pass the condition ID to load saved data
        ),
      ),
    );

    // Refresh the list after returning
    _loadVisits();
  }

  String _getConditionStatusBadge(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return 'Suspected';
      case DiagnosisStatus.provisional:
        return 'Provisional';
      case DiagnosisStatus.confirmed:
        return 'Confirmed';
      case DiagnosisStatus.ruledOut:
        return 'Ruled Out';
    }
  }

  Color _getConditionStatusColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return Colors.orange.shade400;
      case DiagnosisStatus.provisional:
        return Colors.blue.shade400;
      case DiagnosisStatus.confirmed:
        return Colors.green.shade400;
      case DiagnosisStatus.ruledOut:
        return Colors.grey.shade400;
    }
  }

  Color _getConditionStatusTextColor(DiagnosisStatus status) {
    switch (status) {
      case DiagnosisStatus.suspected:
        return Colors.orange.shade900;
      case DiagnosisStatus.provisional:
        return Colors.blue.shade900;
      case DiagnosisStatus.confirmed:
        return Colors.green.shade900;
      case DiagnosisStatus.ruledOut:
        return Colors.grey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Visit History - ${widget.patient.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: FutureBuilder<List<EndocrineCondition>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVisits,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final visits = snapshot.data ?? [];

          if (visits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 80,
                      color: Colors.grey.shade300),
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
                    'No saved disease templates for this patient yet',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadVisits(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visits.length,
              itemBuilder: (context, index) {
                final condition = visits[index];
                final lastUpdated = condition.lastUpdated;
                final statusColor = _getConditionStatusColor(condition.status);
                final statusTextColor = _getConditionStatusTextColor(condition.status);
                final statusText = _getConditionStatusBadge(condition.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _openCondition(condition),
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
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medical_information,
                                  color: Colors.purple,
                                  size: 24,
                                ),
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
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: statusTextColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${condition.gland} • ${condition.category}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Chief Complaint
                          if (condition.chiefComplaint != null && condition.chiefComplaint!.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    condition.chiefComplaint!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Visit Info
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(
                                'Last updated: ${_formatDate(lastUpdated)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const Spacer(),
                              if (condition.labReadings.isNotEmpty) ...[
                                Icon(Icons.science, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  '${condition.labReadings.length} lab tests',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
