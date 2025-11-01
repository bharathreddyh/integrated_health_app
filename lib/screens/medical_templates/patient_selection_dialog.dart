// lib/screens/medical_templates/patient_selection_dialog.dart
// ✅ UPDATED: Option 1 - Two-Column Compact Layout + History + New Visit buttons

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

  // Helper method to format last visit date
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
        width: 700, // Optimal width for content
        height: 720, // ✅ INCREASED from 700 to show more patients
        child: Column(
          children: [
            // ========== HEADER ==========
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Templates',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select patient or start quick assessment',
                          style: TextStyle(
                            fontSize: 13, // Slightly smaller
                            color: Colors.white.withOpacity(0.9),
                          ),
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

            // ========== ✨ NEW: COMPACT 2-COLUMN ACTION BUTTONS ✨ ==========
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  // Column 1: Add New Patient
                  Expanded(
                    child: _buildCompactActionCard(
                      icon: Icons.person_add,
                      iconColor: Colors.purple.shade700,
                      iconBg: Colors.purple.shade100,
                      title: 'Add New Patient',
                      subtitle: 'Register & assess',
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
                  ),

                  const SizedBox(width: 12),

                  // Column 2: Quick Template
                  Expanded(
                    child: _buildCompactActionCard(
                      icon: Icons.flash_on,
                      iconColor: Colors.orange.shade700,
                      iconBg: Colors.orange.shade100,
                      title: 'Quick Template',
                      subtitle: 'Temp record mode',
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
                  ),
                ],
              ),
            ),

            // ========== DIVIDER (More Compact) ==========
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 16
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SELECT EXISTING PATIENT',
                      style: TextStyle(
                        fontSize: 10, // Reduced from 11
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),

            // ========== SEARCH BAR ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPatients,
                decoration: InputDecoration(
                  hintText: 'Search patients by name, ID, or phone...',
                  hintStyle: const TextStyle(fontSize: 14), // Slightly smaller
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12, // Compact padding
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ========== PATIENT LIST (Now with ~100px more space!) ==========
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
                      size: 48, // Slightly smaller
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No patients registered yet'
                          : 'No patients found',
                      style: TextStyle(
                        fontSize: 14, // Slightly smaller
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
                    margin: const EdgeInsets.only(bottom: 10), // Reduced from 12
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(14), // Slightly more compact
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 26, // Reduced from 28
                            backgroundColor: const Color(0xFF9333EA),
                            child: Text(
                              patient.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18, // Reduced from 20
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Patient Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 15, // Reduced from 16
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.badge,
                                        size: 13, // Reduced from 14
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient.id,
                                      style: TextStyle(
                                        fontSize: 11, // Reduced from 13
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.cake,
                                        size: 13,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${patient.age} years',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ========== ACTION BUTTONS (Compact) ==========
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // History Button
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Navigate to patient history
                                  Navigator.pushNamed(
                                    context,
                                    '/patient-history',
                                    arguments: {'patient': patient},
                                  );
                                },
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text(
                                  'History',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF9333EA),
                                  side: const BorderSide(
                                    color: Color(0xFF9333EA),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, // More compact
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // New Visit Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Close dialog and return patient
                                  Navigator.pop(context, {
                                    'patient': patient,
                                    'quickMode': false,
                                  });
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'New Visit',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, // More compact
                                    vertical: 8,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
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

  // ========== ✨ NEW: COMPACT ACTION CARD HELPER METHOD ✨ ==========
  Widget _buildCompactActionCard({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ========== OLD METHOD - NO LONGER USED ==========
  // Kept for reference, but can be deleted
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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