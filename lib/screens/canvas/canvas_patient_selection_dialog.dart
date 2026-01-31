// lib/screens/canvas/canvas_patient_selection_dialog.dart
// Canvas Patient Selection Dialog with History + New Visit buttons

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';
import '../patient/patient_registration_screen.dart';

class CanvasPatientSelectionDialog extends StatefulWidget {
  const CanvasPatientSelectionDialog({super.key});

  @override
  State<CanvasPatientSelectionDialog> createState() =>
      _CanvasPatientSelectionDialogState();
}

class _CanvasPatientSelectionDialogState
    extends State<CanvasPatientSelectionDialog> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await DatabaseHelper.instance.getAllPatients();
      setState(() {
        _patients = patients;
        _filteredPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _patients;
      } else {
        _filteredPatients = _patients.where((patient) {
          final nameLower = patient.name.toLowerCase();
          final phoneLower = patient.phone.toLowerCase();
          final idLower = patient.id.toLowerCase();
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              phoneLower.contains(queryLower) ||
              idLower.contains(queryLower);
        }).toList();
      }
    });
  }

  String _formatLastVisit(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    }
    final years = (difference.inDays / 365).floor();
    return '$years ${years == 1 ? "year" : "years"} ago';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Canvas - Annotate Diagrams',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select patient or start blank canvas',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Option 1: Add New Patient
                  _buildOptionCard(
                    icon: Icons.person_add,
                    iconColor: Colors.orange.shade700,
                    iconBg: Colors.orange.shade100,
                    title: 'Add New Patient',
                    subtitle: 'Register patient and start annotation',
                    onTap: () async {
                      Navigator.pop(context);

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientRegistrationScreen(),
                        ),
                      );

                      if (result != null && context.mounted) {
                        Patient? patient;
                        if (result is Map && result['patient'] != null) {
                          patient = result['patient'] as Patient;
                        } else if (result is Patient) {
                          patient = result;
                        }

                        if (patient != null) {
                          Navigator.pushNamed(
                            context,
                            '/kidney',
                            arguments: patient,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Blank Canvas
                  _buildOptionCard(
                    icon: Icons.auto_fix_high,
                    iconColor: Colors.blue.shade700,
                    iconBg: Colors.blue.shade100,
                    title: 'Blank Canvas',
                    subtitle: 'Start without patient (demo mode)',
                    onTap: () {
                      // Create temporary demo patient
                      final tempPatient = Patient(
                        id: 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
                        name: 'Demo Canvas ${DateFormat('HH:mm').format(DateTime.now())}',
                        age: 0,
                        phone: 'N/A',
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        conditions: [],
                        visits: 0,
                      );

                      Navigator.pop(context, {
                        'patient': tempPatient,
                        'isBlankCanvas': true,
                      });
                    },
                  ),
                ],
              ),
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR SELECT EXISTING PATIENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPatients,
                decoration: InputDecoration(
                  hintText: 'Search patients by name, ID, or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterPatients('');
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Patient List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchController.text.isEmpty
                          ? Icons.person_off
                          : Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No patients registered yet'
                          : 'No patients found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatients[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFF97316),
                            child: Text(
                              patient.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Patient Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.badge,
                                        size: 14,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient.id,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.cake,
                                        size: 14,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${patient.age} years',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // History Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    '/patient-history',
                                    arguments: {'patient': patient},
                                  );
                                },
                                icon: const Icon(Icons.history,
                                    size: 16),
                                label: const Text('History'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  const Color(0xFFF97316),
                                  side: const BorderSide(
                                    color: Color(0xFFF97316),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // New Canvas Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, {
                                    'patient': patient,
                                    'isBlankCanvas': false,
                                  });
                                },
                                icon:
                                const Icon(Icons.draw, size: 16),
                                label: const Text('New Canvas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFFF97316),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}