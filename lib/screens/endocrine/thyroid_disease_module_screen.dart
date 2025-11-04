

import 'package:flutter/material.dart';
import '../../models/endocrine/endocrine_condition.dart';
import '../../models/patient.dart';
import '../../config/thyroid_disease_config.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';
import 'tabs/overview_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/labs_trends_tab.dart';
import 'tabs/clinical_features_tab.dart';
import 'tabs/investigations_tab.dart';
import 'tabs/treatment_tab.dart';
import 'tabs/patient_data_tab.dart';
import '../../widgets/ai_pdf_generator_button.dart';

class ThyroidDiseaseModuleScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String diseaseId;
  final String diseaseName;
  final bool isQuickMode;
  final String? conditionId;  // ✅ CRITICAL: Specific condition ID from visit history

  const ThyroidDiseaseModuleScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.diseaseId,
    required this.diseaseName,
    this.isQuickMode = false,
    this.conditionId,  // ✅ Accept conditionId parameter
  });

  @override
  State<ThyroidDiseaseModuleScreen> createState() =>
      _ThyroidDiseaseModuleScreenState();
}

class _ThyroidDiseaseModuleScreenState extends State<ThyroidDiseaseModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EndocrineCondition _condition;
  late ThyroidDiseaseConfig _diseaseConfig;
  late Patient _patient;
  bool _hasUnsavedChanges = false;
  bool _isLoadingCondition = true;
  DateTime? _lastAutoSave;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _diseaseConfig = ThyroidDiseaseConfig.getDiseaseConfig(widget.diseaseId)!;

    _patient = Patient(
      id: widget.patientId,
      name: widget.patientName,
      age: 0,
      phone: '',
      date: DateTime.now().toString(),
    );

    // Load existing condition or create new
    _loadOrCreateCondition();

    _tabController.addListener(() {
      setState(() {});
    });
  }

  // ✅ FIXED METHOD: Now checks for specific conditionId FIRST
  Future<void> _loadOrCreateCondition() async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('🔍 LOADING CONDITION');
      print('   Patient ID: ${widget.patientId}');
      print('   Patient Name: ${widget.patientName}');
      print('   Disease ID: ${widget.diseaseId}');
      print('   Disease Name: ${widget.diseaseName}');
      print('   Condition ID from history: ${widget.conditionId ?? "none - will search"}');
      print('═══════════════════════════════════════');

      // ✅ PRIORITY 1: If specific conditionId provided, load THAT exact condition
      if (widget.conditionId != null) {
        print('📌 PRIORITY 1: Loading SPECIFIC condition by ID...');
        print('   Searching for condition ID: ${widget.conditionId}');

        final specificCondition = await DatabaseHelper.instance.getEndocrineConditionById(
          widget.conditionId!,
        );

        if (specificCondition != null) {
          print('✅ SUCCESS: Found specific condition!');
          print('   Condition ID: ${specificCondition.id}');
          print('   Disease: ${specificCondition.diseaseName}');
          print('   Status: ${specificCondition.status}');
          print('   Chief Complaint: "${specificCondition.chiefComplaint ?? "null"}"');
          print('   Has vitals: ${specificCondition.vitals != null}');
          print('   Vitals data: ${specificCondition.vitals}');
          print('   Lab readings count: ${specificCondition.labReadings.length}');
          print('   Medications count: ${specificCondition.medications.length}');

          setState(() {
            _condition = specificCondition;
            _hasUnsavedChanges = false;
            _isLoadingCondition = false;
          });

          print('✅ STATE UPDATED - Specific condition loaded successfully');
          print('═══════════════════════════════════════');
          return;
        } else {
          print('⚠️ WARNING: Condition ID provided but not found!');
          print('   Falling back to search by patient + disease...');
        }
      }

      // PRIORITY 2: Check endocrine_conditions table (active working condition)
      print('📌 PRIORITY 2: Checking endocrine_conditions table...');
      final activeCondition = await DatabaseHelper.instance.getActiveEndocrineCondition(
        widget.patientId,
        widget.diseaseId,
      );

      if (activeCondition != null) {
        print('✅ FOUND ACTIVE CONDITION in endocrine_conditions');
        print('   Condition ID: ${activeCondition.id}');
        print('   Chief Complaint: "${activeCondition.chiefComplaint ?? "null"}"');

        // Verify data integrity
        if (activeCondition.vitals != null) {
          print('   Vitals keys: ${activeCondition.vitals!.keys.toList()}');
          print('   Vitals values: ${activeCondition.vitals!.values.toList()}');
        } else {
          print('   Vitals: null');
        }

        if (activeCondition.measurements != null) {
          print('   Measurements keys: ${activeCondition.measurements!.keys.toList()}');
          print('   Measurements values: ${activeCondition.measurements!.values.toList()}');
        } else {
          print('   Measurements: null');
        }

        setState(() {
          _condition = activeCondition;
          _hasUnsavedChanges = false;
          _isLoadingCondition = false;
        });

        print('✅ STATE UPDATED - Active condition loaded successfully');
        print('═══════════════════════════════════════');
        return;
      }

      // PRIORITY 3: If not in main table, check visit history as fallback
      print('📌 PRIORITY 3: Not in endocrine_conditions, checking endocrine_visits...');
      final historyVisit = await DatabaseHelper.instance.getLatestEndocrineVisit(
        widget.patientId,
        widget.diseaseId,
      );

      if (historyVisit != null) {
        print('✅ FOUND IN VISIT HISTORY (endocrine_visits)');
        print('   Migrating to active condition...');

        // IMPORTANT: Migrate to active conditions table for future use
        await DatabaseHelper.instance.saveEndocrineCondition(historyVisit);

        setState(() {
          _condition = historyVisit;
          _hasUnsavedChanges = false;
          _isLoadingCondition = false;
        });

        print('✅ Migrated visit to active condition');
        print('═══════════════════════════════════════');
        return;
      }

      // PRIORITY 4: No existing condition found - create new
      print('📌 PRIORITY 4: NO EXISTING CONDITION FOUND');
      print('   Creating new blank condition...');

      final newCondition = EndocrineCondition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patientId,
        patientName: widget.patientName,
        gland: 'thyroid',
        category: _diseaseConfig.category,
        diseaseId: widget.diseaseId,
        diseaseName: widget.diseaseName,
        status: DiagnosisStatus.suspected,
      );

      // IMPORTANT: Save the new condition immediately to prevent future issues
      await DatabaseHelper.instance.saveEndocrineCondition(newCondition);

      setState(() {
        _condition = newCondition;
        _hasUnsavedChanges = false;
        _isLoadingCondition = false;
      });

      print('✅ Created and saved new condition');
      print('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      print('');
      print('❌❌❌ ERROR IN _loadOrCreateCondition ❌❌❌');
      print('   Error: $e');
      print('   Stack trace:');
      print('   ${stackTrace.toString().split('\n').take(10).join('\n   ')}');
      print('═══════════════════════════════════════');

      // Fallback: create new condition
      setState(() {
        _condition = EndocrineCondition(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          patientId: widget.patientId,
          patientName: widget.patientName,
          gland: 'thyroid',
          category: _diseaseConfig.category,
          diseaseId: widget.diseaseId,
          diseaseName: widget.diseaseName,
          status: DiagnosisStatus.suspected,
        );
        _hasUnsavedChanges = false;
        _isLoadingCondition = false;
      });
    }
  }

  @override
  void dispose() {
    // Save any unsaved changes before disposing
    if (_hasUnsavedChanges) {
      _saveConditionToDatabase();
    }
    _tabController.dispose();
    super.dispose();
  }

  // IMPROVED: Update condition with auto-save functionality
  void _updateCondition(EndocrineCondition updated) async {
    setState(() {
      _condition = updated;
      _hasUnsavedChanges = true;
    });

    // Auto-save after 2 seconds of no changes to prevent data loss
    _debounceAutoSave();
  }

  // NEW: Debounced auto-save to prevent excessive saves
  void _debounceAutoSave() async {
    final now = DateTime.now();
    _lastAutoSave = now;

    await Future.delayed(const Duration(seconds: 2));

    // Only save if no newer save has been initiated
    if (_lastAutoSave == now && _hasUnsavedChanges) {
      try {
        await DatabaseHelper.instance.saveEndocrineCondition(_condition);
        setState(() {
          _hasUnsavedChanges = false;
        });
        print('✅ Auto-saved condition at ${DateTime.now()}');
      } catch (e) {
        print('⚠️ Auto-save failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while checking for existing data
    if (_isLoadingCondition) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          title: const Text('Loading...', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading patient data...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // ✅ ALWAYS show save confirmation dialog before exiting
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,  // Prevent accidental dismiss
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.save_outlined, color: Colors.blue.shade600, size: 28),
                const SizedBox(width: 12),
                const Text('Save Before Exit?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Do you want to save your data before leaving?',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Auto-save may have already saved your data, but saving again ensures nothing is lost.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'discard'),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                label: const Text(
                  'Exit Without Saving',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'cancel'),
                icon: Icon(Icons.close, color: Colors.grey.shade700, size: 20),
                label: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'save'),
                icon: const Icon(Icons.save, size: 20),
                label: const Text('Save & Exit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        );

        // Handle the result
        if (result == 'save') {
          // Save the condition
          print('');
          print('💾 ═══════════════════════════════════════');
          print('💾 USER PRESSED: Save & Exit');
          print('💾 ═══════════════════════════════════════');

          await _saveConditionToDatabase();

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Data saved successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Wait a moment for user to see the message
            await Future.delayed(const Duration(milliseconds: 500));
          }
          return true;  // Allow navigation
        } else if (result == 'discard') {
          // User chose to discard changes
          print('');
          print('🗑️  ═══════════════════════════════════════');
          print('🗑️  USER PRESSED: Exit Without Saving');
          print('🗑️  ═══════════════════════════════════════');

          return true;  // Allow navigation
        } else {
          // User cancelled (or dismissed)
          print('');
          print('❌ ═══════════════════════════════════════');
          print('❌ USER PRESSED: Cancel');
          print('❌ ═══════════════════════════════════════');

          return false;  // Prevent navigation
        }
      },
      child: Scaffold(
        // ... rest of your UI stays the same
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          // Handle unsaved changes on back button
          if (_hasUnsavedChanges) {
            final shouldSave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Save changes?'),
                content: const Text('You have unsaved changes. Save before leaving?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Discard'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );

            if (shouldSave == true) {
              await _saveConditionToDatabase();
            }
          }
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _diseaseConfig.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.patientName,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
        ],
      ),
      actions: [
        // AI PDF Button
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          tooltip: 'Generate AI Report',
          onPressed: _showAIPDFDialog,
        ),
        // Completion indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_condition.completionPercentage.toInt()}% Complete',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _showAIPDFDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                '🤖 AI-Powered Medical Report',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Generate a comprehensive medical report with AI analysis of all patient data, labs, imaging, and treatment plans.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(Icons.speed, 'Lightning Fast', 'Generated in seconds'),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.insights, 'AI Analysis', 'Smart insights and trends'),
                    const SizedBox(height: 8),
                    _buildFeatureItem(Icons.picture_as_pdf, 'Professional PDF', 'Ready to share'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AIPDFGeneratorButton(
                condition: _condition,
                patient: _patient,
                onSuccess: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
      ],
    );
  }

  Future<void> _saveCondition() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving...'),
              ],
            ),
          ),
        ),
      ),
    );

    await _saveConditionToDatabase();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${_condition.diseaseName} saved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // IMPROVED: Save condition with better error handling and logging
  Future<void> _saveConditionToDatabase() async {
    try {
      print('');
      print('═══════════════════════════════════════');
      print('💾 SAVING CONDITION TO DATABASE');
      print('═══════════════════════════════════════');
      print('Disease: ${_condition.diseaseName}');
      print('Patient: ${_condition.patientName}');
      print('Condition ID: ${_condition.id}');
      print('Chief Complaint: "${_condition.chiefComplaint ?? "empty"}"');

      if (_condition.vitals != null) {
        print('Vitals to save: ${_condition.vitals}');
      } else {
        print('⚠️ No vitals to save');
      }

      if (_condition.measurements != null) {
        print('Measurements to save: ${_condition.measurements}');
      } else {
        print('⚠️ No measurements to save');
      }

      print('Lab readings count: ${_condition.labReadings.length}');
      print('Medications count: ${_condition.medications.length}');

      // Save to endocrine_conditions table (active working version)
      await DatabaseHelper.instance.saveEndocrineCondition(_condition);
      print('✅ Saved to endocrine_conditions table');

      // Also save as a visit record for history
      final doctorId = UserService.currentUserId ?? 'unknown';
      await DatabaseHelper.instance.saveEndocrineVisit(_condition, doctorId);
      print('✅ Saved to endocrine_visits table (history)');

      setState(() => _hasUnsavedChanges = false);

      print('✅ Save complete - Data persisted to database');
      print('═══════════════════════════════════════');
      print('');
    } catch (e, stackTrace) {
      print('❌ Error saving condition: $e');
      print('Stack trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error saving: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}