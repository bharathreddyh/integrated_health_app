import 'package:flutter/material.dart';
import '../../models/patient.dart';
import '../../widgets/patient_filter_widget.dart';
import '../patient/patient_registration_screen.dart';
import 'patient_data_edit_screen.dart';

class PatientSelectionScreen extends StatefulWidget {
  const PatientSelectionScreen({super.key});

  @override
  State<PatientSelectionScreen> createState() => _PatientSelectionScreenState();
}

class _PatientSelectionScreenState extends State<PatientSelectionScreen> {
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  bool _showFilters = false;

  final _searchController = TextEditingController();

  Set<String> _selectedConditions = {};
  SortOption _sortOption = SortOption.dateDesc;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final patients = await PatientStore.getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      var filtered = List<Patient>.from(_patients);

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        filtered = filtered.where((patient) {
          return patient.name.toLowerCase().contains(query) ||
              patient.id.toLowerCase().contains(query) ||
              patient.phone.contains(query);
        }).toList();
      }

      if (_selectedConditions.isNotEmpty) {
        filtered = filtered.where((patient) {
          return patient.conditions.any((c) => _selectedConditions.contains(c));
        }).toList();
      }

      if (_dateRange != null) {
        filtered = filtered.where((patient) {
          final patientDate = DateTime.parse(patient.date);
          return patientDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
              patientDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      switch (_sortOption) {
        case SortOption.nameAsc:
          filtered.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortOption.nameDesc:
          filtered.sort((a, b) => b.name.compareTo(a.name));
          break;
        case SortOption.dateAsc:
          filtered.sort((a, b) => a.date.compareTo(b.date));
          break;
        case SortOption.dateDesc:
          filtered.sort((a, b) => b.date.compareTo(a.date));
          break;
        case SortOption.ageAsc:
          filtered.sort((a, b) => a.age.compareTo(b.age));
          break;
        case SortOption.ageDesc:
          filtered.sort((a, b) => b.age.compareTo(a.age));
          break;
      }

      _filteredPatients = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedConditions.clear();
      _dateRange = null;
      _sortOption = SortOption.dateDesc;
      _applyFiltersAndSort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Select Patient'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, ID, or phone...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applyFiltersAndSort();
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => _applyFiltersAndSort(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PatientRegistrationScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadPatients();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Patient'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_selectedConditions.isNotEmpty || _dateRange != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Showing ${_filteredPatients.length} of ${_patients.length} patients',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPatients.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                    onRefresh: _loadPatients,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        return _buildPatientCard(_filteredPatients[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showFilters)
            PatientFilterWidget(
              selectedConditions: _selectedConditions,
              sortOption: _sortOption,
              dateRange: _dateRange,
              onConditionsChanged: (conditions) {
                setState(() {
                  _selectedConditions = conditions;
                });
                _applyFiltersAndSort();
              },
              onSortChanged: (option) {
                setState(() {
                  _sortOption = option;
                });
                _applyFiltersAndSort();
              },
              onDateRangeChanged: (range) {
                setState(() {
                  _dateRange = range;
                });
                _applyFiltersAndSort();
              },
              onClearFilters: _clearFilters,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty && _selectedConditions.isEmpty && _dateRange == null
                ? 'No patients registered yet'
                : 'No patients found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty && _selectedConditions.isEmpty && _dateRange == null
                ? 'Click "New Patient" to register'
                : 'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDataEditScreen(patient: patient),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF3B82F6),
                child: Text(
                  patient.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                      patient.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          patient.id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.cake, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.age} yrs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          patient.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (patient.conditions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
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
                                fontSize: 10,
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
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      patient.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
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