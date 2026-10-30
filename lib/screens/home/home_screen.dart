import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../favorites/favorites_screen.dart';
import '../../services/model_catalog_service.dart';
import '../../widgets/new_models_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _fact = _facts[0];

  @override
  void initState() {
    super.initState();
    _loadNextFact();
    _checkForNewModels();
  }

  /// Time-of-day greeting, no name.
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// A rotating medical "Did you know?" fact. Advances to the next fact in
  /// order every time the home screen opens, wrapping around at the end.
  static const List<String> _facts = [
    'The uterus can expand to over 500 times its normal size during pregnancy.',
    'A tubal ectopic pregnancy accounts for about 95% of all ectopic pregnancies.',
    'The placenta is the only organ the body grows and then discards.',
    'Fetal heartbeats can be detected on ultrasound as early as 6 weeks.',
    'The ovaries release roughly 400–500 eggs over a woman\'s reproductive lifetime.',
    'Amniotic fluid is almost completely replaced every 3 hours near term.',
    'Monozygotic (identical) twins occur in about 3–4 of every 1,000 births.',
    'The cervix softens and changes colour (Goodell\'s and Chadwick\'s signs) in early pregnancy.',
    'A full-term placenta weighs about one-sixth of the baby\'s weight.',
    'Braxton Hicks contractions can begin as early as the second trimester.',
    'The fallopian tubes move the egg using tiny hair-like cilia, not muscle alone.',
    'Fibroids are the most common benign tumours of the female reproductive tract.',
    'A dermoid cyst can contain hair, teeth, and skin tissue.',
    'The fetal kidneys start producing urine around week 9 of gestation.',
    'PCOS affects an estimated 1 in 10 women of reproductive age.',
  ];

  Future<void> _loadNextFact() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = (prefs.getInt('home_fact_index') ?? 0) % _facts.length;
      if (mounted) setState(() => _fact = _facts[index]);
      // Advance for the next time the screen opens.
      await prefs.setInt('home_fact_index', (index + 1) % _facts.length);
    } catch (_) {
      // SharedPreferences unavailable — keep the default first fact.
    }
  }

  Future<void> _checkForNewModels() async {
    try {
      final catalog = ModelCatalogService.instance;

      // Check for updated models first (user already has these, but they changed)
      final updatedModels = await catalog.checkForUpdatedModels();
      if (updatedModels.isNotEmpty && mounted) {
        await UpdatedModelsDialog.show(context, updatedModels);
      }

      // Then check for brand new models
      final newModels = await catalog.checkForNewModels();
      if (newModels.isNotEmpty && mounted) {
        NewModelsDialog.show(context, newModels);
      }
    } catch (e) {
      // Silently fail - don't block the home screen
      print('New model check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserService.currentUser!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Background download progress banner
                const BackgroundDownloadBanner(),

                // Top Bar
                Row(
                  children: [
                    // Logo & App Name
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4FA3FF), Color(0xFF8B5CF6)],
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
                          '3D Clinic',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // User Profile
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141E38),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF4FA3FF),
                            child: Text(
                              user.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                            color: const Color(0xFF141E38),
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
                  _greeting(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // Daily "Did you know?" medical fact
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141E38),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF22325C)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFA78BFA),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Did you know?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFA78BFA),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _fact,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

                        // Favourites Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.favorite_rounded,
                          title: 'Favourites',
                          subtitle: 'Quickly access your saved 3D models',
                          color: const Color(0xFFEF4444),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          ),
                        ),

                        // Library Card
                        _buildMainCard(
                          width: cardWidth,
                          icon: Icons.photo_library_rounded,
                          title: 'Library',
                          subtitle: 'View saved annotations and exported images',
                          color: const Color(0xFF4FA3FF),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF141E38),
                  Color.alphaBlend(
                      color.withOpacity(0.07), const Color(0xFF141E38)),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF22325C), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.28),
                        color.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
            color: const Color(0xFF141E38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF22325C), width: 1),
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
        color: const Color(0xFF141E38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22325C), width: 1),
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
