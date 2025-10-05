import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/database_helper.dart';
import '../../models/patient.dart';
import '../patient/patient_data_edit_screen.dart';
import '../../models/visit.dart';  // ADD THIS

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


  // Add to home_screen.dart:
  Future<List<Visit>> _getMyVisits() async {
    final db = await DatabaseHelper.instance.database;  // FIXED
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

    final todayVisits = visits.where((v) =>
        v.createdAt.isAfter(todayStart)
    ).length;

    final weekStart = today.subtract(Duration(days: 7));
    final weekVisits = visits.where((v) =>
        v.createdAt.isAfter(weekStart)
    ).length;

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
                  // Top Bar with FUNCTIONAL SEARCH
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
          Text('Select an action to begin consultation', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 48) / 3;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: cardWidth * 2 + 24,
                    child: _buildLargeActionCard(
                      context: context,
                      icon: Icons.play_circle_outline,
                      title: 'Start Consultation',
                      subtitle: 'Begin new patient session',
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/patient-selection'),
                    ),
                  ),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.library_books_outlined, 'Library', 'Medical diagrams', '45', Colors.purple, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.history, 'Past Summaries', 'Patient records', '24', Colors.orange, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.star_outline, 'Quick Access', 'Favorites', '8', Colors.green, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.language, 'Language', 'English', 'EN', Colors.indigo, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.share, 'WhatsApp', 'Share summaries', '', Colors.green, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.analytics_outlined, 'Analytics', 'Practice insights', '', Colors.cyan, () {})),
                  SizedBox(width: cardWidth, child: _buildMediumActionCard(Icons.admin_panel_settings_outlined, 'Admin', 'Settings', '', Colors.red, () {})),
                ],
              );
            },
          ),
        ],
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

  Widget _buildLargeActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 36),
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediumActionCard(IconData icon, String title, String subtitle, String count, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  if (count.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(count, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    ),
                ],
              ),
              const Spacer(),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}