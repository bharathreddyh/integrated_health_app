// lib/dialogs/canvas_patient_selection_dialog.dart
// Canvas patient selection dialog WITH SEARCH FUNCTIONALITY

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../screens/patient/patient_registration_screen.dart';
import '../screens/canvas/canvas_screen.dart';

class CanvasPatientSelectionDialog extends StatefulWidget {
  final List<Patient> patients;

  const CanvasPatientSelectionDialog({
    super.key,
    required this.patients,
  });

  @override
  State<CanvasPatientSelectionDialog> createState() =>
      _CanvasPatientSelectionDialogState();
}

class _CanvasPatientSelectionDialogState
    extends State<CanvasPatientSelectionDialog> {
  List<Patient> _filteredPatients = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredPatients = widget.patients;
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = widget.patients;
      } else {
        _filteredPatients = widget.patients.where((patient) {
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
        width: 600,
        height: 700,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Patient for Canvas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Choose a patient or open blank canvas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
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

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.orange.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Add New Patient Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const PatientRegistrationScreen(),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CanvasScreen(patient: patient),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.person_add, size: 20),
                      label: const Text(
                        'Add New Patient',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Skip - Open Blank Canvas Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog

                        // Open canvas without patient
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CanvasScreen(
                              patient: Patient(
                                id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
                                name: 'Quick Canvas',
                                age: 0,
                                phone: '',
                                date: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                conditions: [],
                                visits: 0,
                              ),
                            ),
                          ),
                        );

                        // Show info message
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Quick Canvas mode - Diagrams can be saved later',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.blue.shade700,
                                duration: Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.flash_on, size: 20),
                      label: const Text(
                        'Skip - Open Blank Canvas',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(
                          color: Colors.orange.shade700,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Divider with "OR" text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
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

            // ✅ NEW: Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPatients,
                decoration: InputDecoration(
                  hintText: 'Search patients by name, ID, or phone...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Patient List
            Expanded(
              child: _filteredPatients.isEmpty
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
                          ? 'No patients found'
                          : 'No patients match your search',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Add a patient or use quick canvas'
                          : 'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
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
                                size: 14,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              patient.id,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.cake,
                                size: 14,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${patient.age} years',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, patient);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Open Canvas'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}