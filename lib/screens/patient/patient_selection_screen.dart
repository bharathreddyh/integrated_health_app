import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../models/medical_condition.dart';

class PatientSelectionScreen extends StatefulWidget {
  const PatientSelectionScreen({super.key});

  @override
  State<PatientSelectionScreen> createState() => _PatientSelectionScreenState();
}

class _PatientSelectionScreenState extends State<PatientSelectionScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected conditions for new patient
  final Set<String> _selectedConditions = {};

  // Common preexisting conditions
  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Arthritis',
    'GERD',
    'Migraine',
    'Depression',
    'Anxiety',
    'Thyroid Disorder',
    'Heart Disease',
    'Kidney Disease',
    'Chronic Pain',
  ];

  List<Patient> _patients = [
    Patient(
      id: 'P001',
      name: 'Rajesh Kumar',
      age: 45,
      phone: '9876543210',
      date: '2025-09-28',
      conditions: ['Diabetes', 'Hypertension'],
      visits: 12,
    ),
    Patient(
      id: 'P002',
      name: 'Priya Sharma',
      age: 32,
      phone: '9876543211',
      date: '2025-09-29',
      conditions: ['Asthma'],
      visits: 8,
    ),
    Patient(
      id: 'P003',
      name: 'Amit Patel',
      age: 58,
      phone: '9876543212',
      date: '2025-09-25',
      conditions: ['GERD', 'Arthritis'],
      visits: 15,
    ),
  ];

  List<Patient> get _filteredPatients {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _patients;

    return _patients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.id.toLowerCase().contains(query) ||
          patient.phone.contains(query);
    }).toList();
  }

  bool _showNewPatientModal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Patient',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Search existing patient or register new patient',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showNewPatientModal = true),
                        icon: const Icon(Icons.add),
                        label: const Text('New Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name, patient ID, or phone number...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                // Patient List
                Expanded(
                  child: _filteredPatients.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No patients found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                      : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: _filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = _filteredPatients[index];
                      return _buildPatientCard(patient);
                    },
                  ),
                ),
              ],
            ),
          ),

          // New Patient Modal
          if (_showNewPatientModal)
            GestureDetector(
              onTap: () => setState(() => _showNewPatientModal = false),
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping modal content
                    child: Container(
                      width: 680,
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Modal Header
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Register New Patient',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Quick patient registration',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() => _showNewPatientModal = false);
                                      _clearForm();
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),

                            // Form
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Patient Name *',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _ageController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: 'Age *',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: InputDecoration(
                                            labelText: 'Phone *',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Preexisting Conditions Section
                                  const Text(
                                    'Preexisting Conditions (Optional)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Select all conditions that apply',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Condition Chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _commonConditions.map((condition) {
                                      final isSelected = _selectedConditions.contains(condition);
                                      return FilterChip(
                                        label: Text(condition),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedConditions.add(condition);
                                            } else {
                                              _selectedConditions.remove(condition);
                                            }
                                          });
                                        },
                                        selectedColor: const Color(0xFFDCEAFE),
                                        checkmarkColor: const Color(0xFF1E40AF),
                                        backgroundColor: Colors.grey.shade100,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? const Color(0xFF1E40AF)
                                              : Colors.grey.shade700,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      labelText: 'Additional Notes (Optional)',
                                      hintText: 'Allergies, medications, special considerations...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Footer
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _showNewPatientModal = false);
                                      _clearForm();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _saveNewPatient,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Save & Continue'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return InkWell(
      onTap: () => _selectPatient(patient),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getInitials(patient.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          patient.id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${patient.age} years • ${patient.phone}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (patient.conditions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: patient.conditions.take(3).map((condition) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEAFE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            condition,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  void _selectPatient(Patient patient) {
    _showConditionSelectionDialog(patient);
  }

  void _showConditionSelectionDialog(Patient patient) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          height: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Condition for ${patient.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _getConditions().length,
                  itemBuilder: (context, index) {
                    final condition = _getConditions()[index];
                    return _buildConditionCard(patient, condition);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionCard(Patient patient, MedicalCondition condition) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close condition dialog
        Navigator.pop(context); // Close patient selection
        Navigator.pushNamed(
          context,
          '/condition',
          arguments: {
            'condition': condition,
            'patient': patient,
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: condition.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: condition.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(condition.icon, color: condition.color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                condition.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveNewPatient() {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final newPatient = Patient(
      id: 'P${(_patients.length + 1).toString().padLeft(3, '0')}',
      name: _nameController.text,
      age: int.parse(_ageController.text),
      phone: _phoneController.text,
      date: DateTime.now().toString().split(' ')[0],
      conditions: _selectedConditions.toList(),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    setState(() {
      _patients.insert(0, newPatient);
      _showNewPatientModal = false;
    });

    _clearForm();

    // Auto-select the new patient
    Future.delayed(const Duration(milliseconds: 300), () {
      _selectPatient(newPatient);
    });
  }

  void _clearForm() {
    _nameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _notesController.clear();
    _selectedConditions.clear();
  }

  List<MedicalCondition> _getConditions() {
    return const [
      MedicalCondition(
        id: 'diabetes',
        name: 'Type 2 Diabetes',
        description: 'Blood sugar management',
        icon: Icons.monitor_heart,
        color: Color(0xFFDC2626),
        todayCount: 3,
        totalCount: 45,
      ),
      MedicalCondition(
        id: 'hypertension',
        name: 'Hypertension',
        description: 'High blood pressure',
        icon: Icons.favorite,
        color: Color(0xFFEF4444),
        todayCount: 2,
        totalCount: 38,
      ),
      MedicalCondition(
        id: 'asthma',
        name: 'Asthma',
        description: 'Respiratory condition',
        icon: Icons.air,
        color: Color(0xFF10B981),
        todayCount: 1,
        totalCount: 22,
      ),
      MedicalCondition(
        id: 'arthritis',
        name: 'Arthritis',
        description: 'Joint inflammation',
        icon: Icons.accessibility_new,
        color: Color(0xFFF59E0B),
        todayCount: 2,
        totalCount: 31,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}