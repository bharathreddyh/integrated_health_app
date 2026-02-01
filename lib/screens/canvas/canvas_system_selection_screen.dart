import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/canvas_system_config.dart';
import '../../models/patient.dart';
import '../../services/database_helper.dart';
import '../patient/patient_registration_screen.dart';
import 'canvas_screen.dart';

class CanvasSystemSelectionScreen extends StatelessWidget {
  const CanvasSystemSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final systems = CanvasSystemConfig.systems.entries.toList();
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final availableHeight = screenHeight - appBarHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Select System',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: _calcAspectRatio(availableHeight, systems.length),
          ),
          itemCount: systems.length,
          itemBuilder: (context, index) {
            final entry = systems[index];
            final config = entry.value;
            return _SystemCard(
              config: config,
              onTap: () => _selectPatientThenOpen(context, config),
            );
          },
        ),
      ),
    );
  }

  double _calcAspectRatio(double availableHeight, int itemCount) {
    final rows = (itemCount / 4).ceil();
    final gridHeight = availableHeight - 32; // padding
    final tileHeight = (gridHeight - (rows - 1) * 14) / rows;
    // We'll calculate from width later; just use a reasonable ratio
    return 1.0; // square-ish tiles
  }

  Future<void> _selectPatientThenOpen(BuildContext context, SystemConfig system) async {
    final patients = await DatabaseHelper.instance.getAllPatients();

    if (!context.mounted) return;

    if (patients.isEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Patients'),
          content: const Text('Register a patient or open a blank canvas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, 'blank'),
              child: const Text('Blank Canvas'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'register'),
              child: const Text('Register Patient'),
            ),
          ],
        ),
      );

      if (!context.mounted || action == null || action == 'cancel') return;

      if (action == 'register') {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientRegistrationScreen()),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CanvasScreen(
            patient: Patient(
              id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
              name: 'Quick Canvas',
              age: 0,
              phone: '',
              date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              conditions: [],
              visits: 0,
            ),
            preSelectedSystem: system.id,
          ),
        ),
      );
      return;
    }

    final selected = await showDialog<Patient>(
      context: context,
      builder: (ctx) => _PatientPickerDialog(patients: patients),
    );

    if (selected != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CanvasScreen(
            patient: selected,
            preSelectedSystem: system.id,
          ),
        ),
      );
    }
  }
}

class _SystemCard extends StatelessWidget {
  final SystemConfig config;
  final VoidCallback onTap;

  const _SystemCard({required this.config, required this.onTap});

  static const _systemColors = <String, List<Color>>{
    'thyroid': [Color(0xFFF59E0B), Color(0xFFD97706)],
    'kidney': [Color(0xFF3B82F6), Color(0xFF2563EB)],
    'cardiac': [Color(0xFFEF4444), Color(0xFFDC2626)],
    'pulmonary': [Color(0xFF10B981), Color(0xFF059669)],
    'neuro': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'hepatic': [Color(0xFFF97316), Color(0xFFEA580C)],
    'gynaecology': [Color(0xFFEC4899), Color(0xFFDB2777)],
    'obstetrics': [Color(0xFFA855F7), Color(0xFF9333EA)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _systemColors[config.id] ?? [Colors.blueGrey, Colors.blueGrey.shade700];
    final diagramCount = config.anatomyDiagrams.length + config.systemTemplates.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                config.icon,
                style: const TextStyle(fontSize: 52),
              ),
              const SizedBox(height: 12),
              Text(
                config.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$diagramCount diagrams',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientPickerDialog extends StatefulWidget {
  final List<Patient> patients;
  const _PatientPickerDialog({required this.patients});

  @override
  State<_PatientPickerDialog> createState() => _PatientPickerDialogState();
}

class _PatientPickerDialogState extends State<_PatientPickerDialog> {
  final _searchController = TextEditingController();
  late List<Patient> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.patients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.patients;
      } else {
        final q = query.toLowerCase();
        _filtered = widget.patients.where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.phone.contains(q) ||
            p.id.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Select Patient',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No patients found', style: TextStyle(color: Colors.grey.shade500)),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final p = _filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3B82F6),
                              child: Text(
                                p.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${p.id} | ${p.age} yrs'),
                            onTap: () => Navigator.pop(context, p),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
