// lib/screens/medical_templates/patient_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';
import '../patient/patient_registration_screen.dart';

class MedicalTemplatePatientSelectionDialog extends StatefulWidget {
  const MedicalTemplatePatientSelectionDialog({super.key});

  @override
  State<MedicalTemplatePatientSelectionDialog> createState() =>
      _MedicalTemplatePatientSelectionDialogState();
}

class _MedicalTemplatePatientSelectionDialogState
    extends State<MedicalTemplatePatientSelectionDialog> {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFF7E22CE)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.healing, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Templates',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Select patient or start quick assessment',
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
                color: Colors.purple.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.purple.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Option 1: Add New Patient
                  _buildOptionCard(
                    icon: Icons.person_add,
                    iconColor: Colors.purple.shade700,
                    iconBg: Colors.purple.shade100,
                    title: 'Add New Patient',
                    subtitle: 'Register patient and start assessment',
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
                            '/medical-systems',
                            arguments: {
                              'patient': patient,
                              'isQuickMode': false,
                            },
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: Quick Template (Temp Patient)
                  _buildOptionCard(
                    icon: Icons.flash_on,
                    iconColor: Colors.orange.shade700,
                    iconBg: Colors.orange.shade100,
                    title: 'Quick Template',
                    subtitle: 'Start without patient (create temporary record)',
                    onTap: () {
                      // Create temporary patient
                      final tempPatient = Patient(
                        id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
                        name: 'Quick Assessment ${DateFormat('MMM dd, HH:mm').format(DateTime.now())}',
                        age: 0,
                        phone: 'N/A',
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        conditions: [],
                        visits: 0,
                      );

                      Navigator.pop(context, {
                        'patient': tempPatient,
                        'quickMode': true,
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF9333EA),
                        child: Text(
                          patient.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.badge,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(patient.id,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.cake,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('${patient.age} years',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context, {
                            'patient': patient,
                            'quickMode': false,
                          });
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Select'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
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
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
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
                  const SizedBox(height: 4),
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
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade400),
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