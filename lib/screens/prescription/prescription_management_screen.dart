import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/prescription.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  final int visitId;
  final String patientId;
  final Patient patient;

  const PrescriptionManagementScreen({
    super.key,
    required this.visitId,
    required this.patientId,
    required this.patient,
  });

  @override
  State<PrescriptionManagementScreen> createState() =>
      _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState
    extends State<PrescriptionManagementScreen> {
  List<Prescription> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prescriptions = await DatabaseHelper.instance
        .getPrescriptionsByVisit(widget.visitId);
    setState(() {
      _prescriptions = prescriptions;
      _loading = false;
    });
  }

  Future<void> _addPrescription() async {
    final result = await showDialog<Prescription>(
      context: context,
      builder: (context) => PrescriptionDialog(
        visitId: widget.visitId,
        patientId: widget.patientId,
      ),
    );

    if (result != null) {
      // Get current doctor ID
      final doctorId = UserService.currentUserId ?? 'USR001';
      await DatabaseHelper.instance.insertPrescription(result, doctorId);
      _loadPrescriptions();
    }
  }

  Future<void> _editPrescription(Prescription prescription) async {
    final result = await showDialog<Prescription>(
      context: context,
      builder: (context) => PrescriptionDialog(
        visitId: widget.visitId,
        patientId: widget.patientId,
        prescription: prescription,
      ),
    );

    if (result != null) {
      // Get current doctor ID
      final doctorId = UserService.currentUserId ?? 'USR001';
      await DatabaseHelper.instance.updatePrescription(result, doctorId);
      _loadPrescriptions();
    }
  }


  Future<void> _deletePrescription(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePrescription(id);
      _loadPrescriptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    widget.patient.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${widget.patient.id} | Age: ${widget.patient.age}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _prescriptions.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No prescriptions yet',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600),
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
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      prescription.medicationName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                            '${prescription.dosage} • ${prescription.frequency}'),
                        Text('Duration: ${prescription.duration}'),
                        if (prescription.instructions != null &&
                            prescription.instructions!.isNotEmpty)
                          Text(
                            prescription.instructions!,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editPrescription(prescription),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.red),
                          onPressed: () =>
                              _deletePrescription(prescription.id!),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPrescription,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }
}

class PrescriptionDialog extends StatefulWidget {
  final int visitId;
  final String patientId;
  final Prescription? prescription;

  const PrescriptionDialog({
    super.key,
    required this.visitId,
    required this.patientId,
    this.prescription,
  });

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _instructionsController;
  String _frequency = 'Once daily';
  String _duration = '7 days';

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 6 hours',
    'Every 8 hours',
    'As needed',
  ];

  final List<String> _durations = [
    '3 days',
    '5 days',
    '7 days',
    '10 days',
    '14 days',
    '1 month',
    '3 months',
    'Ongoing',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.prescription?.medicationName ?? '');
    _dosageController =
        TextEditingController(text: widget.prescription?.dosage ?? '');
    _instructionsController =
        TextEditingController(text: widget.prescription?.instructions ?? '');
    _frequency = widget.prescription?.frequency ?? 'Once daily';
    _duration = widget.prescription?.duration ?? '7 days';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.prescription == null ? 'Add Medication' : 'Edit Medication'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 500mg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) => setState(() => _frequency = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _duration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                border: OutlineInputBorder(),
              ),
              items: _durations
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (value) => setState(() => _duration = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Instructions (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill required fields')),
              );
              return;
            }

            final prescription = Prescription(
              id: widget.prescription?.id,
              visitId: widget.visitId,
              patientId: widget.patientId,
              medicationName: _nameController.text,
              dosage: _dosageController.text,
              frequency: _frequency,
              duration: _duration,
              instructions: _instructionsController.text,
              createdAt: widget.prescription?.createdAt ?? DateTime.now(),
            );

            Navigator.pop(context, prescription);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}