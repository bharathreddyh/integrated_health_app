// lib/screens/prescription/prescription_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prescription.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  final Patient patient;

  const PrescriptionHistoryScreen({
    Key? key,
    required this.patient,
  }) : super(key: key);

  @override
  State<PrescriptionHistoryScreen> createState() =>
      _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  final _db = DatabaseHelper.instance;
  List<Prescription> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _isLoading = true);
    final prescriptions = await _db.getPrescriptionsByPatient(widget.patient.id!);
    setState(() {
      _prescriptions = prescriptions;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription History'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Patient info card
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.teal,
                    child: Text(
                      widget.patient.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${widget.patient.id} | Age: ${widget.patient.age}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Statistics bar
          if (_prescriptions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.medication,
                    label: 'Total Prescriptions',
                    value: _prescriptions.length.toString(),
                  ),
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Latest',
                    value: _formatDate(_prescriptions.first.createdAt),
                  ),
                ],
              ),
            ),

          // Prescriptions list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _prescriptions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No prescription history',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prescriptions will appear here',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = _prescriptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Icon(
                        Icons.medication,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    title: Text(
                      prescription.medicationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      'Prescribed: ${_formatDate(prescription.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              icon: Icons.medication_liquid,
                              label: 'Dosage',
                              value: prescription.dosage,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.schedule,
                              label: 'Frequency',
                              value: prescription.frequency,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              icon: Icons.timer,
                              label: 'Duration',
                              value: prescription.duration,
                            ),
                            if (prescription.instructions != null &&
                                prescription.instructions!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                icon: Icons.info_outline,
                                label: 'Instructions',
                                value: prescription.instructions!,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}