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
import '../patient/visit_history_screen.dart';
import '../canvas/canvas_system_selection_screen.dart';
import '../library/library_screen.dart';
import '../setup/asset_download_screen.dart';
import '../models_3d/models_3d_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    // Logo & App Name
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.medical_services, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IHA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Integrated Health App',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // User Profile
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF3B82F6),
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                user.specialty ?? 'Doctor',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                            color: const Color(0xFF1E293B),
                            onSelected: (value) {
                              if (value == 'logout') {
                                UserService.logout();
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Logout', style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Welcome Section
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dr. ${user.name.split(' ').first}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),

                const SizedBox(height: 48),

                // Main Feature Cards - 2x2 Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 24) / 2;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: [
                        // Canvas Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.draw_rounded,
                          title: 'Canvas',
                          subtitle: 'Annotate medical diagrams with markers and drawings',
                          color: const Color(0xFFF97316),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CanvasSystemSelectionScreen()),
                          ),
                        ),

                        // 3D Models Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.view_in_ar_rounded,
                          title: '3D Models',
                          subtitle: 'Interactive 3D anatomical models with annotations',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Models3DScreen()),
                          ),
                        ),

                        // Library Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.photo_library_rounded,
                          title: 'Library',
                          subtitle: 'View saved annotations and exported images',
                          color: const Color(0xFF3B82F6),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          ),
                        ),

                        // Downloads Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.download_rounded,
                          title: 'Downloads',
                          subtitle: 'Manage 3D model downloads and assets',
                          color: const Color(0xFF10B981),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssetDownloadScreen(onComplete: () => Navigator.pop(context)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Medical Templates Section
                _buildSectionHeader('Medical Templates', Icons.healing_rounded),
                const SizedBox(height: 16),
                _buildTemplateCard(
                  icon: Icons.assignment_rounded,
                  title: 'Disease Assessment',
                  subtitle: 'Track conditions with structured templates',
                  color: const Color(0xFF9333EA),
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const MedicalTemplatePatientSelectionDialog(),
                    );
                    if (result != null && mounted) {
                      final patient = result['patient'] as Patient?;
                      final isQuickMode = result['quickMode'] as bool? ?? false;
                      if (patient != null) {
                        Navigator.pushNamed(context, '/medical-systems', arguments: {
                          'patient': patient,
                          'isQuickMode': isQuickMode,
                        });
                      }
                    }
                  },
                ),

                const SizedBox(height: 48),

                // Quick Stats
                _buildSectionHeader('Activity', Icons.analytics_rounded),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, int>>(
                  future: _getMyStats(),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? {'today': 0, 'week': 0, 'total': 0};
                    return Row(
                      children: [
                        Expanded(child: _buildStatCard('Today', '${stats['today']}', 'visits', const Color(0xFF3B82F6))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('This Week', '${stats['week']}', 'consultations', const Color(0xFF10B981))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Total', '${stats['total']}', 'records', const Color(0xFF8B5CF6))),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard({
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF334155), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, int>> _getMyStats() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'visits',
      where: 'doctor_id = ?',
      whereArgs: [UserService.currentUserId],
      orderBy: 'created_at DESC',
    );
    final visits = maps.map((m) => Visit.fromMap(m)).toList();

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayVisits = visits.where((v) => v.createdAt.isAfter(todayStart)).length;

    final weekStart = today.subtract(const Duration(days: 7));
    final weekVisits = visits.where((v) => v.createdAt.isAfter(weekStart)).length;

    return {
      'today': todayVisits,
      'week': weekVisits,
      'total': visits.length,
    };
  }
}
