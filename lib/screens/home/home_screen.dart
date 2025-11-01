import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/database_helper.dart';
import '../../models/patient.dart';
import '../patient/patient_data_edit_screen.dart';
import '../../models/visit.dart';
import '../canvas/canvas_screen.dart';
import '../patient/patient_registration_screen.dart';
import 'package:intl/intl.dart';
import '../medical_templates/patient_selection_dialog.dart';
import '../canvas/canvas_patient_selection_dialog.dart';
import '../patient/visit_history_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Patient> _searchResults = [];
  bool _isSearching = false;


  final _searchFocusNode = FocusNode();
  final TextEditingController _dialogSearchController = TextEditingController();
  List<Patient> _filteredPatientsForDialog = [];


  Future<List<Visit>> _getMyVisits() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'visits',
      where: 'doctor_id = ?',
      whereArgs: [UserService.currentUserId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Visit.fromMap(m)).toList();
  }

  Future<Map<String, int>> _getMyStats() async {
    final visits = await _getMyVisits();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final todayVisits = visits.where((v) => v.createdAt.isAfter(todayStart)).length;

    final weekStart = today.subtract(Duration(days: 7));
    final weekVisits = visits.where((v) => v.createdAt.isAfter(weekStart)).length;

    return {
      'today': todayVisits,
      'week': weekVisits,
      'total': visits.length,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _dialogSearchController.dispose(); // ✅ ADD THIS LINE
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await DatabaseHelper.instance.searchPatients(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 4,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user.specialty ?? 'General Medicine',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        FutureBuilder<Map<String, int>>(
                          future: _getMyStats(),
                          builder: (context, snapshot) {
                            final stats = snapshot.data ?? {'today': 0, 'week': 0, 'total': 0};
                            return Column(
                              children: [
                                _buildQuickStat('Today', '${stats['today']} visits', Icons.people_outline, Colors.blue),
                                const SizedBox(height: 12),
                                _buildQuickStat('This Week', '${stats['week']} consultations', Icons.medical_services_outlined, Colors.green),
                                const SizedBox(height: 12),
                                _buildQuickStat('Total', '${stats['total']} summaries', Icons.description_outlined, Colors.orange),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSidebarAction('Recent Patients', Icons.history, Colors.indigo, () {}),
                        _buildSidebarAction('Templates', Icons.file_copy_outlined, Colors.purple, () {}),
                        _buildSidebarAction('Settings', Icons.settings_outlined, Colors.grey, () {}),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildSidebarAction('Logout', Icons.logout, Colors.red, () {
                          UserService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Column(
                children: [
                  // Top Bar with Search
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) => _performSearch(value),
                              decoration: InputDecoration(
                                hintText: 'Search patients, conditions, or summaries...',
                                hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search, size: 24, color: Colors.grey.shade600),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                  onPressed: _clearSearch,
                                )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Grid OR Search Results
                  Expanded(
                    child: _searchController.text.isNotEmpty
                        ? _buildSearchResults()
                        : _buildDashboardContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No patients found for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Text(
                'Search Results (${_searchResults.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final patient = _searchResults[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDataEditScreen(patient: patient),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            patient.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(patient.id, style: TextStyle(color: Colors.grey.shade600)),
                                  const SizedBox(width: 20),
                                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(patient.phone, style: TextStyle(color: Colors.grey.shade600)),
                                  const SizedBox(width: 20),
                                  Icon(Icons.cake, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${patient.age} years', style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                              if (patient.conditions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  children: patient.conditions.take(3).map((condition) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: 3x3 Grid Dashboard
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clinic Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text('Select an action to begin', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 32),

          // ✅ UPDATED: 3x3 GRID LAYOUT
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 48) / 3;

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  // ROW 1
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.play_circle_outline,
                      title: 'Start Consultation',
                      subtitle: 'Begin patient session',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                      ),
                      onTap: () => Navigator.pushNamed(context, '/patient-selection'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.draw,
                      title: 'Canvas',
                      subtitle: 'Annotate diagrams',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                      ),
                      onTap: () => _openCanvasWithPatientSelection(),
                    ),
                  ),
                  // ✅ CHANGED: Medical Templates (was Library)
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.healing, // ✅ CHANGED from Icons.description_outlined
                      title: 'Medical Templates',
                      subtitle: 'Disease assessment & tracking', // ✅ CHANGED subtitle
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9333EA), Color(0xFF7E22CE)], // Purple
                      ),
                      onTap: () async {
                        // ✅ NEW: Show patient selection dialog
                        final result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (context) => const MedicalTemplatePatientSelectionDialog(),
                        );

                        if (result != null && mounted) {
                          final patient = result['patient'] as Patient?;
                          final isQuickMode = result['quickMode'] as bool? ?? false;

                          if (patient != null) {
                            // Navigate to Medical Systems Screen
                            Navigator.pushNamed(
                              context,
                              '/medical-systems',
                              arguments: {
                                'patient': patient,
                                'isQuickMode': isQuickMode,
                              },
                            );
                          }
                        }
                      },
                    ),
                  ),

                  // ROW 2
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.history,
                      title: 'Past Summaries',
                      subtitle: 'Patient records',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                      ),
                      onTap: () {
                        // TODO: Navigate to past summaries
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Past Summaries - Coming Soon'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      },
                    ),
                  ),
                  // ✅ CHANGED: Library (was Quick Access)
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.local_library_outlined,
                      title: 'Library',
                      subtitle: 'Medical resources',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      onTap: () {
                        // TODO: Navigate to library screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Library - Coming Soon'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change language',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      ),
                      onTap: () {
                        // TODO: Open language selector
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Language Settings - Coming Soon'),
                            backgroundColor: Colors.indigo,
                          ),
                        );
                      },
                    ),
                  ),

                  // ROW 3
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'WhatsApp',
                      subtitle: 'Share summaries',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                      ),
                      onTap: () {
                        // TODO: Open WhatsApp integration
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('WhatsApp Integration - Coming Soon'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'Practice insights',
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      onTap: () {
                        // TODO: Navigate to analytics
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Analytics - Coming Soon'),
                            backgroundColor: Colors.cyan,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin',
                      subtitle: 'System settings',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      onTap: () {
                        // TODO: Navigate to admin panel
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Admin Panel - Coming Soon'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Unified Feature Card Widget
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> _openCanvasWithPatientSelection() async {
    final patients = await DatabaseHelper.instance.getAllPatients();

    if (!mounted) return;

    // Handle empty patient list
    if (patients.isEmpty) {
      _showEmptyPatientsDialog();
      return;
    }

    // ✅ CORRECT: Use the existing method
    final selectedPatient = await showDialog<Patient>(
      context: context,
      builder: (context) => _buildPatientSelectionDialog(patients),
    );

    if (selectedPatient != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CanvasScreen(patient: selectedPatient),
        ),
      );
    }
  }
  void _filterPatientsInDialog(String query, List<Patient> allPatients) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatientsForDialog = allPatients;
      } else {
        _filteredPatientsForDialog = allPatients.where((patient) {
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
// ✅ NEW: Empty patients dialog with 3 options
  void _showEmptyPatientsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_off,
                  size: 40,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'No Patients Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'You haven\'t registered any patients yet.\nChoose an option below to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Option 1: Add New Patient
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog

                    // Navigate to registration
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientRegistrationScreen(),
                        settings: RouteSettings(
                          arguments: {'returnTo': 'canvas'},
                        ),
                      ),
                    );

                    // Handle result
                    if (result != null && mounted) {
                      if (result is Map && result['patient'] != null) {
                        final patient = result['patient'] as Patient;
                        if (result['action'] == 'annotate') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CanvasScreen(patient: patient),
                            ),
                          );
                        }
                      } else if (result is Patient) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CanvasScreen(patient: result),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text(
                    'Add New Patient',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Open Blank Canvas
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog

                    // Open blank canvas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CanvasScreen(
                          patient: Patient(
                            id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
                            name: 'Quick Canvas',
                            age: 0,
                            phone: '',
                            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            conditions: [],
                            visits: 0,
                          ),
                        ),
                      ),
                    );

                    // Show info
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Quick Canvas mode - Add patient later to save',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.blue.shade700,
                            duration: Duration(seconds: 4),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    });
                  },
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: const Text(
                    'Open Blank Canvas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(color: Colors.orange.shade700, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 3: Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
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

  Widget _buildPatientSelectionDialog(List<Patient> patients) {
    // Initialize filtered list
    if (_filteredPatientsForDialog.isEmpty && patients.isNotEmpty) {
      _filteredPatientsForDialog = patients;
    }

    return Dialog(
      child: Container(
        width: 600,
        height: 720, // Increased from 650 to show more patients
        child: Column(
          children: [
            // ========== HEADER ==========
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.draw, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Patient for Canvas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose patient or demo mode',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9)
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _dialogSearchController.clear();
                      _filteredPatientsForDialog = [];
                      Navigator.pop(context);
                    },
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
                      iconColor: Colors.orange.shade700,
                      iconBg: Colors.orange.shade100,
                      title: 'Add New Patient',
                      subtitle: 'Register & annotate',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.pushNamed(context, '/patient-registration');
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Column 2: Blank Canvas
                  Expanded(
                    child: _buildCompactActionCard(
                      icon: Icons.edit,
                      iconColor: Colors.blue.shade700,
                      iconBg: Colors.blue.shade100,
                      title: 'Blank Canvas',
                      subtitle: 'Start demo mode',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CanvasScreen(
                              patient: Patient(
                                id: 'TEMP_${DateTime.now().millisecondsSinceEpoch}',
                                name: 'Quick Canvas',
                                age: 0,
                                phone: '',
                                date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                conditions: [],
                                visits: 0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ========== DIVIDER ==========
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SELECT EXISTING PATIENT',
                      style: TextStyle(
                        fontSize: 10,
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
                controller: _dialogSearchController,
                onChanged: (value) => _filterPatientsInDialog(value, patients),
                decoration: InputDecoration(
                  hintText: 'Search patients by name, ID, or phone...',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _dialogSearchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _dialogSearchController.clear();
                      _filterPatientsInDialog('', patients);
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

            // ========== PATIENT LIST (Now with more space!) ==========
            Expanded(
              child: _filteredPatientsForDialog.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _dialogSearchController.text.isEmpty
                          ? Icons.person_off
                          : Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _dialogSearchController.text.isEmpty
                          ? 'No patients registered'
                          : 'No patients found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filteredPatientsForDialog.length,
                itemBuilder: (context, index) {
                  final patient = _filteredPatientsForDialog[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFF97316),
                        child: Text(
                          patient.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.badge,
                                size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(patient.id,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 12),
                            Icon(Icons.cake,
                                size: 13, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('${patient.age} years',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              // Navigate to history
                              _dialogSearchController.clear();
                              _filteredPatientsForDialog = [];
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VisitHistoryScreen(patient: patient),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history,
                                    size: 16,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 4),
                                const Text('History',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _dialogSearchController.clear();
                              _filteredPatientsForDialog = [];
                              Navigator.pop(context, patient);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 4),
                                Text('New Canvas',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
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
}