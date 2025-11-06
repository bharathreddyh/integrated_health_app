// lib/services/database_helper.dart
// ✅ FIXED VERSION - All compilation errors resolved

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/prescription.dart';
import '../models/user.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/lab_test.dart';
import '../models/endocrine/endocrine_condition.dart';
import '../models/endocrine/lab_test_result.dart';
import '../models/endocrine/investigation_finding.dart';
import '../models/disease_template.dart';
import 'cloud_sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final CloudSyncService _cloudSync = CloudSyncService();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clinic_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('🔧 Database path: $path');
    print('🔧 Database version: 14');
    return await openDatabase(
      path,
      version: 14,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    print('🔨 Creating NEW database with version $version');


    await db.execute('''
      CREATE TABLE disease_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        details TEXT NOT NULL
      )
    ''');

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        specialty TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Patients table
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        phone TEXT NOT NULL,
        date TEXT NOT NULL,
        conditions TEXT,
        notes TEXT,
        visits INTEGER DEFAULT 0,
        vitals TEXT
      )
    ''');

    // Visits table with ALL required columns
    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        system TEXT DEFAULT 'kidney',        
        diagram_type TEXT NOT NULL,
        markers TEXT NOT NULL,
        drawing_paths TEXT, 
        notes TEXT,
        created_at TEXT NOT NULL,
        canvas_image BLOB,
        is_edited INTEGER DEFAULT 0,
        original_visit_id INTEGER,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Prescriptions table
    await db.execute('''
      CREATE TABLE prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_id INTEGER NOT NULL,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        medication_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        duration TEXT NOT NULL,
        instructions TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (visit_id) REFERENCES visits (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Lab tests table
    await db.execute('''
      CREATE TABLE lab_tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visit_id INTEGER NOT NULL,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        test_name TEXT NOT NULL,
        test_category TEXT NOT NULL,
        ordered_date TEXT NOT NULL,
        result_date TEXT,
        result_value TEXT,
        result_unit TEXT,
        normal_range_min TEXT,
        normal_range_max TEXT,
        is_abnormal INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (visit_id) REFERENCES visits (id) ON DELETE CASCADE,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Endocrine conditions table
    await db.execute('''
      CREATE TABLE endocrine_conditions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        gland TEXT NOT NULL,
        category TEXT NOT NULL,
        disease_id TEXT NOT NULL,
        disease_name TEXT NOT NULL,
        status TEXT NOT NULL,
        diagnosis_date TEXT,
        severity TEXT,
        chief_complaint TEXT,
        history_present_illness TEXT,
        past_medical_history TEXT,
        family_history TEXT,
        allergies TEXT,
        vitals TEXT,
        measurements TEXT,
        ordered_lab_tests TEXT,
        ordered_investigations TEXT,
        additional_data TEXT,
        lab_test_results TEXT,
        investigation_findings TEXT,
        selected_symptoms TEXT,
        selected_diagnostic_criteria TEXT,
        selected_complications TEXT,
        lab_readings TEXT,
        clinical_features TEXT,
        complications TEXT,
        medications TEXT,
        images TEXT,
        notes TEXT,
        treatment_plan TEXT,
        next_visit TEXT,
        follow_up_plan TEXT,
        created_at TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');

    // Endocrine visits table
    await db.execute('''
      CREATE TABLE endocrine_visits (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        visit_date TEXT NOT NULL,
        gland TEXT NOT NULL,
        category TEXT,
        disease_id TEXT,
        disease_name TEXT,
        status TEXT NOT NULL,
        severity TEXT,
        chief_complaint TEXT,
        history_present_illness TEXT,
        past_medical_history TEXT,
        family_history TEXT,
        allergies TEXT,
        vitals TEXT,
        measurements TEXT,
        ordered_lab_tests TEXT,
        ordered_investigations TEXT,
        clinical_features TEXT,
        lab_readings TEXT,
        investigation_findings TEXT,
        images TEXT,
        medications TEXT,
        treatment_plan TEXT,
        complications TEXT,
        notes TEXT,
        follow_up_plan TEXT,
        next_visit TEXT,
        created_at TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Patient data snapshots table
    await db.execute('''
      CREATE TABLE patient_data_snapshots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId TEXT NOT NULL,
        chiefComplaint TEXT,
        historyOfPresentIllness TEXT,
        pastMedicalHistory TEXT,
        familyHistory TEXT,
        allergies TEXT,
        vitals TEXT,
        height TEXT,
        weight TEXT,
        bmi TEXT,
        lastUpdated TEXT NOT NULL,
        updatedFrom TEXT NOT NULL,
        FOREIGN KEY (patientId) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Consultation drafts table
    await db.execute('''
      CREATE TABLE consultation_drafts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patientId TEXT NOT NULL UNIQUE,
        chiefComplaint TEXT,
        historyOfPresentIllness TEXT,
        pastMedicalHistory TEXT,
        familyHistory TEXT,
        allergies TEXT,
        bloodPressure TEXT,
        heartRate TEXT,
        temperature TEXT,
        spo2 TEXT,
        respiratoryRate TEXT,
        height TEXT,
        weight TEXT,
        diagnosis TEXT,
        dietPlan TEXT,
        lifestylePlan TEXT,
        prescriptionsJson TEXT,
        labResultsJson TEXT,
        isDraft INTEGER DEFAULT 1,
        lastSaved TEXT,
        updatedAt TEXT
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_endocrine_visits_patient 
      ON endocrine_visits(patient_id, visit_date DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_endocrine_visits_disease 
      ON endocrine_visits(patient_id, disease_id, visit_date DESC)
    ''');

    // Create default admin user (password: "admin123")
    await db.insert('users', {
      'id': 'USR001',
      'name': 'Dr. Admin',
      'email': 'admin@clinic.com',
      'password_hash': _hashPassword('admin123'),
      'role': 'doctor',
      'specialty': 'General Medicine',
      'created_at': DateTime.now().toIso8601String(),
    });

    print('✅ Database created successfully with all tables!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 6: Add user authentication
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL,
          specialty TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      try {
        await db.execute('ALTER TABLE visits ADD COLUMN doctor_id TEXT DEFAULT "USR001"');
      } catch (e) {
        print('doctor_id already exists in visits: $e');
      }

      try {
        await db.execute('ALTER TABLE prescriptions ADD COLUMN doctor_id TEXT DEFAULT "USR001"');
      } catch (e) {
        print('doctor_id already exists in prescriptions: $e');
      }

      final users = await db.query('users', where: 'email = ?', whereArgs: ['admin@clinic.com']);
      if (users.isEmpty) {
        await db.insert('users', {
          'id': 'USR001',
          'name': 'Dr. Admin',
          'email': 'admin@clinic.com',
          'password_hash': _hashPassword('admin123'),
          'role': 'doctor',
          'specialty': 'General Medicine',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }

    // Version 7: Add lab tests
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS lab_tests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          visit_id INTEGER NOT NULL,
          patient_id TEXT NOT NULL,
          doctor_id TEXT NOT NULL,
          test_name TEXT NOT NULL,
          test_category TEXT NOT NULL,
          ordered_date TEXT NOT NULL,
          result_date TEXT,
          result_value TEXT,
          result_unit TEXT,
          normal_range_min TEXT,
          normal_range_max TEXT,
          is_abnormal INTEGER DEFAULT 0,
          status TEXT NOT NULL,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (visit_id) REFERENCES visits (id) ON DELETE CASCADE,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
          FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }

    // Version 8: Add canvas_image column
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE visits ADD COLUMN canvas_image BLOB');
        print('✅ Added canvas_image column to visits table');
      } catch (e) {
        print('canvas_image column may already exist: $e');
      }
    }

    // Version 9: Add system column
    if (oldVersion < 9) {
      try {
        await db.execute('ALTER TABLE visits ADD COLUMN system TEXT DEFAULT "kidney"');
        print('✅ Added system column to visits table');
      } catch (e) {
        print('system column may already exist: $e');
      }
    }

    // Version 10: Add endocrine conditions table
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS endocrine_conditions (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          gland TEXT NOT NULL,
          category TEXT NOT NULL,
          disease_id TEXT NOT NULL,
          disease_name TEXT NOT NULL,
          status TEXT NOT NULL,
          diagnosis_date TEXT,
          severity TEXT,
          lab_readings TEXT,
          clinical_features TEXT,
          complications TEXT,
          medications TEXT,
          images TEXT,
          notes TEXT,
          treatment_plan TEXT,
          next_visit TEXT,
          follow_up_plan TEXT,
          created_at TEXT NOT NULL,
          last_updated TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
    }

    // Version 11: Add endocrine visits table
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS endocrine_visits (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          doctor_id TEXT NOT NULL,
          visit_date TEXT NOT NULL,
          gland TEXT NOT NULL,
          category TEXT,
          disease_id TEXT,
          disease_name TEXT,
          status TEXT NOT NULL,
          severity TEXT,
          clinical_features TEXT,
          lab_readings TEXT,
          images TEXT,
          medications TEXT,
          treatment_plan TEXT,
          complications TEXT,
          notes TEXT,
          follow_up_plan TEXT,
          next_visit TEXT,
          created_at TEXT NOT NULL,
          last_updated TEXT NOT NULL,
          is_active INTEGER DEFAULT 1,
          FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
          FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_endocrine_visits_patient 
        ON endocrine_visits(patient_id, visit_date DESC)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_endocrine_visits_disease 
        ON endocrine_visits(patient_id, disease_id, visit_date DESC)
      ''');
    }

    // Version 12: Add is_edited and original_visit_id columns to visits
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE visits ADD COLUMN is_edited INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE visits ADD COLUMN original_visit_id INTEGER');
        print('✅ Added is_edited and original_visit_id columns to visits table');
      } catch (e) {
        print('Columns may already exist: $e');
      }
    }

    // Version 13: Add patient data columns to endocrine tables
    if (oldVersion < 13) {
      try {
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN chief_complaint TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN history_present_illness TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN past_medical_history TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN family_history TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN allergies TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN vitals TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN measurements TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN ordered_lab_tests TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN ordered_investigations TEXT');
        await db.execute('ALTER TABLE endocrine_visits ADD COLUMN investigation_findings TEXT');
        print('✅ Added patient data columns to endocrine_visits table');
      } catch (e) {
        print('Some columns may already exist in endocrine_visits: $e');
      }

      try {
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN chief_complaint TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN history_present_illness TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN past_medical_history TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN family_history TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN allergies TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN vitals TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN measurements TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN ordered_lab_tests TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN ordered_investigations TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN additional_data TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN lab_test_results TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN investigation_findings TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN selected_symptoms TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN selected_diagnostic_criteria TEXT');
        await db.execute('ALTER TABLE endocrine_conditions ADD COLUMN selected_complications TEXT');
        print('✅ Added patient data columns to endocrine_conditions table');
      } catch (e) {
        print('Some columns may already exist in endocrine_conditions: $e');
      }
    }
    if (oldVersion < 14) {
      print('   📋 Adding disease_templates table...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS disease_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          details TEXT NOT NULL
        )
      ''');
      print('   ✅ disease_templates table added');
    }


  }

  // ==================== HELPER METHODS (MUST BE DECLARED BEFORE USE) ====================

  // PASSWORD HASHING
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // ENDOCRINE CONDITION MAPPING FROM DATABASE
  EndocrineCondition _endocrineConditionFromMap(Map<String, dynamic> map) {
    return EndocrineCondition(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      patientName: '',
      gland: map['gland'] as String,
      category: (map['category'] as String?) ?? '',
      diseaseId: map['disease_id'] as String,
      diseaseName: map['disease_name'] as String,
      status: DiagnosisStatus.values.firstWhere(
            (e) => e.toString().split('.').last == map['status'],
      ),
      severity: map['severity'] != null
          ? DiseaseSeverity.values.firstWhere(
            (e) => e.toString().split('.').last == map['severity'],
      )
          : null,
      chiefComplaint: map['chief_complaint'] as String?,
      historyOfPresentIllness: map['history_present_illness'] as String?,
      pastMedicalHistory: map['past_medical_history'] as String?,
      familyHistory: map['family_history'] as String?,
      allergies: map['allergies'] as String?,
      vitals: map['vitals'] != null
          ? Map<String, String>.from(jsonDecode(map['vitals']))
          : null,
      measurements: map['measurements'] != null
          ? Map<String, String>.from(jsonDecode(map['measurements']))
          : null,
      orderedLabTests: map['ordered_lab_tests'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['ordered_lab_tests']))
          : null,
      orderedInvestigations: map['ordered_investigations'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['ordered_investigations']))
          : null,
      labTestResults: map['lab_test_results'] != null
          ? (jsonDecode(map['lab_test_results']) as List)
          .map((x) => LabTestResult.fromJson(x))
          .toList()
          : [],
      investigationFindings: map['investigation_findings'] != null
          ? (jsonDecode(map['investigation_findings']) as List)
          .map((x) => InvestigationFinding.fromJson(x))
          .toList()
          : [],
      selectedSymptoms: map['selected_symptoms'] != null
          ? List<String>.from(jsonDecode(map['selected_symptoms']))
          : null,
      selectedDiagnosticCriteria: map['selected_diagnostic_criteria'] != null
          ? List<String>.from(jsonDecode(map['selected_diagnostic_criteria']))
          : null,
      selectedComplications: map['selected_complications'] != null
          ? List<String>.from(jsonDecode(map['selected_complications']))
          : null,
      clinicalFeatures: map['clinical_features'] != null
          ? (jsonDecode(map['clinical_features']) as List)
          .map((x) => ClinicalFeature.fromJson(x))
          .toList()
          : [],
      labReadings: map['lab_readings'] != null
          ? (jsonDecode(map['lab_readings']) as List)
          .map((x) => LabReading.fromJson(x))
          .toList()
          : [],
      complications: map['complications'] != null
          ? (jsonDecode(map['complications']) as List)
          .map((x) => Complication.fromJson(x))
          .toList()
          : [],
      medications: map['medications'] != null
          ? (jsonDecode(map['medications']) as List)
          .map((x) => Medication.fromJson(x))
          .toList()
          : [],
      images: map['images'] != null
          ? (jsonDecode(map['images']) as List)
          .map((x) => MedicalImage.fromJson(x))
          .toList()
          : [],
      notes: map['notes'] as String? ?? '',
      treatmentPlan: map['treatment_plan'] != null
          ? TreatmentPlan.fromJson(jsonDecode(map['treatment_plan']))
          : null,
      nextVisit: map['next_visit'] != null
          ? DateTime.parse(map['next_visit'] as String)
          : null,
      followUpPlan: map['follow_up_plan'] as String? ?? '',
      diagnosisDate: map['diagnosis_date'] != null
          ? DateTime.parse(map['diagnosis_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  // CALCULATE CHANGES BETWEEN TWO VISITS
  Map<String, dynamic> _calculateChanges(EndocrineCondition current, EndocrineCondition previous) {
    Map<String, dynamic> changes = {};

    // Lab changes
    Map<String, Map<String, dynamic>> labChanges = {};
    for (var currentReading in current.labReadings) {
      var previousReading = previous.labReadings.firstWhere(
            (r) => r.testName == currentReading.testName,
        orElse: () => currentReading,
      );

      if (previousReading != currentReading) {
        labChanges[currentReading.testName] = {
          'previous': previousReading.value,
          'current': currentReading.value,
          'change': currentReading.value - previousReading.value,
          'percentChange': previousReading.value != 0
              ? ((currentReading.value - previousReading.value) / previousReading.value * 100).toStringAsFixed(1)
              : '0.0',
          'trend': currentReading.value > previousReading.value ? 'up' : 'down',
        };
      }
    }
    changes['labs'] = labChanges;

    // Feature changes
    List<String> newFeatures = [];
    List<String> resolvedFeatures = [];

    for (var feature in current.clinicalFeatures) {
      if (feature.isPresent && !previous.clinicalFeatures.any((f) => f.name == feature.name && f.isPresent)) {
        newFeatures.add(feature.name);
      }
    }

    for (var feature in previous.clinicalFeatures) {
      if (feature.isPresent && !current.clinicalFeatures.any((f) => f.name == feature.name && f.isPresent)) {
        resolvedFeatures.add(feature.name);
      }
    }

    changes['features'] = {
      'new': newFeatures,
      'resolved': resolvedFeatures,
    };

    // Medication changes
    List<String> newMeds = [];
    List<String> stoppedMeds = [];

    for (var med in current.medications) {
      if (med.isActive && !previous.medications.any((m) => m.name == med.name && m.isActive)) {
        newMeds.add(med.name);
      }
    }

    for (var med in previous.medications) {
      if (med.isActive && !current.medications.any((m) => m.name == med.name && m.isActive)) {
        stoppedMeds.add(med.name);
      }
    }

    changes['medications'] = {
      'new': newMeds,
      'stopped': stoppedMeds,
    };

    return changes;
  }

  // ==================== USER METHODS ====================

  Future<User?> authenticateUser(String email, String password) async {
    final db = await this.database;
    final passwordHash = _hashPassword(password);

    final maps = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.toLowerCase(), passwordHash],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> createUser(User user, String password) async {
    final db = await this.database;
    final userMap = user.toMap();
    userMap['password_hash'] = _hashPassword(password);
    return await db.insert('users', userMap);
  }

  Future<User?> getUserById(String id) async {
    final db = await this.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await this.database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllDoctors() async {
    final db = await this.database;
    final maps = await db.query('users', where: 'role = ?', whereArgs: ['doctor']);
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // ==================== PATIENT METHODS ====================

  Future<int> createPatient(Patient patient) async {
    final db = await this.database;
    return await db.insert('patients', patient.toMap());
  }

  Future<int> insertPatient(Patient patient) async {
    final result = await createPatient(patient);

    // Sync to cloud if authenticated
    if (_cloudSync.isAuthenticated) {
      _cloudSync.syncPatientToCloud(patient).catchError((e) {
        print('⚠️ Failed to sync patient to cloud: $e');
      });
    }

    return result;
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await this.database;
    final maps = await db.query('patients', orderBy: 'name ASC');
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  // Alias for getAllPatients (used by CloudSyncService)
  Future<List<Patient>> getPatients() async {
    return await getAllPatients();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await this.database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await this.database;
    final result = await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );

    // Sync to cloud if authenticated
    if (_cloudSync.isAuthenticated) {
      _cloudSync.syncPatientToCloud(patient).catchError((e) {
        print('⚠️ Failed to sync patient update to cloud: $e');
      });
    }

    return result;
  }

  Future<int> deletePatient(String id) async {
    final db = await this.database;
    final result = await db.delete('patients', where: 'id = ?', whereArgs: [id]);

    // Delete from cloud if authenticated
    if (_cloudSync.isAuthenticated) {
      _cloudSync.deletePatientFromCloud(id).catchError((e) {
        print('⚠️ Failed to delete patient from cloud: $e');
      });
    }

    return result;
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await this.database;
    final maps = await db.query(
      'patients',
      where: 'name LIKE ? OR id LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  // ==================== VISIT METHODS ====================

  Future<int> insertVisit(Visit visit, String doctorId) async {
    final db = await this.database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;
    visitMap['is_edited'] = visit.isEdited ? 1 : 0;
    visitMap['original_visit_id'] = visit.originalVisitId;
    return await db.insert('visits', visitMap);
  }

  Future<int> createVisit(Visit visit, String doctorId) async {
    return await insertVisit(visit, doctorId);
  }

  Future<int> updateVisit(Visit visit, String doctorId) async {
    final db = await this.database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;
    visitMap['is_edited'] = visit.isEdited ? 1 : 0;
    visitMap['original_visit_id'] = visit.originalVisitId;
    return await db.update(
      'visits',
      visitMap,
      where: 'id = ?',
      whereArgs: [visit.id],
    );
  }

  Future<List<Visit>> getVisitsByPatient(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<List<Visit>> getPatientVisits(String patientId) async {
    return await getVisitsByPatient(patientId);
  }

  Future<List<Visit>> getAllVisitsForPatient({required String patientId}) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<Visit?> getVisitById(int id) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<Visit?> getLastVisit(String patientId, {String? diagramType}) async {
    final db = await this.database;
    String whereClause = 'patient_id = ?';
    List<dynamic> whereArgs = [patientId];

    if (diagramType != null) {
      whereClause += ' AND diagram_type = ?';
      whereArgs.add(diagramType);
    }

    final maps = await db.query(
      'visits',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<Visit?> getLatestVisit({
    required String patientId,
    required String diagramType,
    String? system,
  }) async {
    final db = await this.database;

    String whereClause;
    List<dynamic> whereArgs;

    if (system != null) {
      whereClause = 'patient_id = ? AND diagram_type = ? AND system = ?';
      whereArgs = [patientId, diagramType, system];
    } else {
      whereClause = 'patient_id = ? AND diagram_type = ?';
      whereArgs = [patientId, diagramType];
    }

    final maps = await db.query(
      'visits',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<List<Visit>> getVisitsByPatientAndSystem({
    required String patientId,
    required String system,
  }) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ? AND system = ?',
      whereArgs: [patientId, system],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<Visit?> getLatestVisitBySystem({
    required String patientId,
    required String system,
    required String diagramType,
  }) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ? AND system = ? AND diagram_type = ?',
      whereArgs: [patientId, system, diagramType],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<Map<String, List<Visit>>> getVisitsGroupedBySystem(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );

    final visits = maps.map((map) => Visit.fromMap(map)).toList();
    final Map<String, List<Visit>> grouped = {};

    for (final visit in visits) {
      if (!grouped.containsKey(visit.system)) {
        grouped[visit.system] = [];
      }
      grouped[visit.system]!.add(visit);
    }

    return grouped;
  }

  Future<int> deleteVisit(int id) async {
    final db = await this.database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PRESCRIPTION METHODS ====================

  Future<int> insertPrescription(Prescription prescription, String doctorId) async {
    final db = await this.database;
    final prescMap = prescription.toMap();
    prescMap['doctor_id'] = doctorId;
    return await db.insert('prescriptions', prescMap);
  }

  Future<int> updatePrescription(Prescription prescription, String doctorId) async {
    final db = await this.database;
    final prescMap = prescription.toMap();
    prescMap['doctor_id'] = doctorId;
    return await db.update(
      'prescriptions',
      prescMap,
      where: 'id = ?',
      whereArgs: [prescription.id],
    );
  }

  Future<int> deletePrescription(int id) async {
    final db = await this.database;
    return await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Prescription>> getPrescriptionsByVisit(int visitId) async {
    final db = await this.database;
    final maps = await db.query(
      'prescriptions',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  Future<List<Prescription>> getPrescriptionsByPatient(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'prescriptions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // ==================== LAB TEST METHODS ====================

  Future<int> insertLabTest(LabTest labTest, String doctorId) async {
    final db = await this.database;
    final testMap = labTest.toMap();
    testMap['doctor_id'] = doctorId;
    return await db.insert('lab_tests', testMap);
  }

  Future<int> updateLabTest(LabTest labTest, String doctorId) async {
    final db = await this.database;
    final testMap = labTest.toMap();
    testMap['doctor_id'] = doctorId;
    return await db.update(
      'lab_tests',
      testMap,
      where: 'id = ?',
      whereArgs: [labTest.id],
    );
  }

  Future<int> deleteLabTest(int id) async {
    final db = await this.database;
    return await db.delete('lab_tests', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LabTest>> getLabTestsByVisit(int visitId) async {
    final db = await this.database;
    final maps = await db.query(
      'lab_tests',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  Future<List<LabTest>> getLabTestsByPatient(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'lab_tests',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  Future<List<LabTest>> getPendingLabTests(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'lab_tests',
      where: 'patient_id = ? AND status = ?',
      whereArgs: [patientId, 'pending'],
      orderBy: 'ordered_date DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  // ==================== ENDOCRINE CONDITION METHODS ====================

  Future<int> saveEndocrineCondition(EndocrineCondition condition) async {
    final db = await this.database;

    print('💾 Saving endocrine condition to endocrine_conditions table');
    print('💾 Patient ID: ${condition.patientId}');
    print('💾 Disease: ${condition.diseaseName}');

    final data = {
      'id': condition.id,
      'patient_id': condition.patientId,
      'gland': condition.gland,
      'category': condition.category,
      'disease_id': condition.diseaseId,
      'disease_name': condition.diseaseName,
      'status': condition.status.toString().split('.').last,
      'diagnosis_date': condition.diagnosisDate?.toIso8601String(),
      'severity': condition.severity?.toString().split('.').last,
      'chief_complaint': condition.chiefComplaint,
      'history_present_illness': condition.historyOfPresentIllness,
      'past_medical_history': condition.pastMedicalHistory,
      'family_history': condition.familyHistory,
      'allergies': condition.allergies,
      'vitals': condition.vitals != null ? jsonEncode(condition.vitals) : null,
      'measurements': condition.measurements != null ? jsonEncode(condition.measurements) : null,
      'ordered_lab_tests': condition.orderedLabTests != null ? jsonEncode(condition.orderedLabTests) : null,
      'ordered_investigations': condition.orderedInvestigations != null ? jsonEncode(condition.orderedInvestigations) : null,
      'additional_data': condition.additionalData != null ? jsonEncode(condition.additionalData) : null,
      'lab_test_results': condition.labTestResults != null ? jsonEncode(condition.labTestResults) : null,
      'investigation_findings': condition.investigationFindings != null ? jsonEncode(condition.investigationFindings) : null,
      'selected_symptoms': condition.selectedSymptoms != null ? jsonEncode(condition.selectedSymptoms) : null,
      'selected_diagnostic_criteria': condition.selectedDiagnosticCriteria != null ? jsonEncode(condition.selectedDiagnosticCriteria) : null,
      'selected_complications': condition.selectedComplications != null ? jsonEncode(condition.selectedComplications) : null,
      'lab_readings': jsonEncode(condition.labReadings.map((x) => x.toJson()).toList()),
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((x) => x.toJson()).toList()),
      'complications': jsonEncode(condition.complications.map((x) => x.toJson()).toList()),
      'medications': jsonEncode(condition.medications.map((x) => x.toJson()).toList()),
      'images': jsonEncode(condition.images.map((x) => x.toJson()).toList()),
      'notes': condition.notes,
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,
      'next_visit': condition.nextVisit?.toIso8601String(),
      'follow_up_plan': condition.followUpPlan,
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': condition.lastUpdated.toIso8601String(),
      'is_active': condition.isActive ? 1 : 0,
    };

    final result = await db.insert(
      'endocrine_conditions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync to cloud if authenticated
    if (_cloudSync.isAuthenticated) {
      _cloudSync.syncEndocrineConditionToCloud(data).catchError((e) {
        print('⚠️ Failed to sync endocrine condition to cloud: $e');
      });
    }

    return result;
  }

  Future<List<EndocrineCondition>> getEndocrineConditionsByPatient(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_conditions',
      where: 'patient_id = ? AND is_active = ?',
      whereArgs: [patientId, 1],
    );
    // ✅ FIX: Properly cast to List<EndocrineCondition>
    return List<EndocrineCondition>.from(
        maps.map((map) => EndocrineCondition.fromJson(map))
    );
  }



  Future<EndocrineCondition?> getActiveEndocrineCondition(String patientId, String diseaseId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_conditions',
      where: 'patient_id = ? AND disease_id = ? AND is_active = ?',
      whereArgs: [patientId, diseaseId, 1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return EndocrineCondition.fromJson(maps.first);
  }
// ✅ NEW METHOD: Get specific condition by ID
  Future<EndocrineCondition?> getEndocrineConditionById(String conditionId) async {
    final db = await this.database;

    // Check endocrine_conditions table
    final conditionMaps = await db.query(
      'endocrine_conditions',
      where: 'id = ?',
      whereArgs: [conditionId],
      limit: 1,
    );

    if (conditionMaps.isNotEmpty) {
      return _endocrineConditionFromMap(conditionMaps.first);
    }

    // Check endocrine_visits table
    final visitMaps = await db.query(
      'endocrine_visits',
      where: 'id = ?',
      whereArgs: [conditionId],
      limit: 1,
    );

    if (visitMaps.isNotEmpty) {
      return _endocrineConditionFromMap(visitMaps.first);
    }

    return null;
  }

  Future<int> updateEndocrineCondition(EndocrineCondition condition) async {
    final db = await this.database;

    final updateData = {
      'patient_id': condition.patientId,
      'gland': condition.gland,
      'category': condition.category,
      'disease_id': condition.diseaseId,
      'disease_name': condition.diseaseName,
      'status': condition.status.toString().split('.').last,
      'diagnosis_date': condition.diagnosisDate?.toIso8601String(),
      'severity': condition.severity?.toString().split('.').last,
      'chief_complaint': condition.chiefComplaint,
      'history_present_illness': condition.historyOfPresentIllness,
      'past_medical_history': condition.pastMedicalHistory,
      'family_history': condition.familyHistory,
      'allergies': condition.allergies,
      'vitals': condition.vitals != null ? jsonEncode(condition.vitals) : null,
      'measurements': condition.measurements != null ? jsonEncode(condition.measurements) : null,
      'ordered_lab_tests': condition.orderedLabTests != null ? jsonEncode(condition.orderedLabTests) : null,
      'ordered_investigations': condition.orderedInvestigations != null ? jsonEncode(condition.orderedInvestigations) : null,
      'additional_data': condition.additionalData != null ? jsonEncode(condition.additionalData) : null,
      'lab_test_results': condition.labTestResults != null ? jsonEncode(condition.labTestResults) : null,
      'investigation_findings': condition.investigationFindings != null ? jsonEncode(condition.investigationFindings) : null,
      'selected_symptoms': condition.selectedSymptoms != null ? jsonEncode(condition.selectedSymptoms) : null,
      'selected_diagnostic_criteria': condition.selectedDiagnosticCriteria != null ? jsonEncode(condition.selectedDiagnosticCriteria) : null,
      'selected_complications': condition.selectedComplications != null ? jsonEncode(condition.selectedComplications) : null,
      'lab_readings': jsonEncode(condition.labReadings.map((x) => x.toJson()).toList()),
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((x) => x.toJson()).toList()),
      'complications': jsonEncode(condition.complications.map((x) => x.toJson()).toList()),
      'medications': jsonEncode(condition.medications.map((x) => x.toJson()).toList()),
      'images': jsonEncode(condition.images.map((x) => x.toJson()).toList()),
      'notes': condition.notes,
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,
      'next_visit': condition.nextVisit?.toIso8601String(),
      'follow_up_plan': condition.followUpPlan,
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
      'is_active': condition.isActive ? 1 : 0,
    };

    return await db.update(
      'endocrine_conditions',
      updateData,
      where: 'id = ?',
      whereArgs: [condition.id],
    );
  }

  // ==================== ENDOCRINE VISIT METHODS ====================

  Future<String> saveEndocrineVisit(EndocrineCondition condition, String doctorId) async {
    final db = await this.database;

    final visitData = {
      'id': condition.id,
      'patient_id': condition.patientId,
      'doctor_id': doctorId,
      'visit_date': DateTime.now().toIso8601String(),
      'gland': condition.gland,
      'category': condition.category,
      'disease_id': condition.diseaseId,
      'disease_name': condition.diseaseName,
      'status': condition.status.toString().split('.').last,
      'severity': condition.severity?.toString().split('.').last,
      'chief_complaint': condition.chiefComplaint,
      'history_present_illness': condition.historyOfPresentIllness,
      'past_medical_history': condition.pastMedicalHistory,
      'family_history': condition.familyHistory,
      'allergies': condition.allergies,
      'vitals': condition.vitals != null ? jsonEncode(condition.vitals) : null,
      'measurements': condition.measurements != null ? jsonEncode(condition.measurements) : null,
      'ordered_lab_tests': condition.orderedLabTests != null ? jsonEncode(condition.orderedLabTests) : null,
      'ordered_investigations': condition.orderedInvestigations != null ? jsonEncode(condition.orderedInvestigations) : null,
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((f) => f.toJson()).toList()),
      'lab_readings': jsonEncode(condition.labReadings.map((r) => r.toJson()).toList()),
      'investigation_findings': condition.investigationFindings != null ? jsonEncode(condition.investigationFindings) : null,
      'images': jsonEncode(condition.images.map((i) => i.toJson()).toList()),
      'medications': jsonEncode(condition.medications.map((m) => m.toJson()).toList()),
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,
      'complications': jsonEncode(condition.complications.map((c) => c.toJson()).toList()),
      'notes': condition.notes,
      'follow_up_plan': condition.followUpPlan,
      'next_visit': condition.nextVisit?.toIso8601String(),
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
      'is_active': condition.isActive ? 1 : 0,
    };

    await db.insert('endocrine_visits', visitData, conflictAlgorithm: ConflictAlgorithm.replace);

    // Sync visit to cloud if authenticated
    if (_cloudSync.isAuthenticated) {
      _cloudSync.syncEndocrineVisitToCloud(visitData).catchError((e) {
        print('⚠️ Failed to sync endocrine visit to cloud: $e');
      });
    }

    return condition.id;
  }

  Future<List<EndocrineCondition>> getEndocrineVisitsByPatient(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'visit_date DESC',
    );
    // ✅ FIX: Properly cast to List<EndocrineCondition>
    return List<EndocrineCondition>.from(
        maps.map((map) => _endocrineConditionFromMap(map))
    );
  }

  Future<List<EndocrineCondition>> getEndocrineVisitsByDisease(String patientId, String diseaseId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ? AND disease_id = ?',
      whereArgs: [patientId, diseaseId],
      orderBy: 'visit_date DESC',
    );
    // ✅ FIX: Properly cast to List<EndocrineCondition>
    return List<EndocrineCondition>.from(
        maps.map((map) => _endocrineConditionFromMap(map))
    );
  }

  Future<EndocrineCondition?> getLatestEndocrineVisit(String patientId, String diseaseId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ? AND disease_id = ?',
      whereArgs: [patientId, diseaseId],
      orderBy: 'visit_date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _endocrineConditionFromMap(maps.first);
  }

  Future<int> deleteEndocrineVisit(String visitId) async {
    final db = await this.database;

    print('🗑️ Deleting endocrine visit with ID: $visitId');

    final result = await db.delete(
      'endocrine_visits',
      where: 'id = ?',
      whereArgs: [visitId],
    );

    await db.delete(
      'endocrine_conditions',
      where: 'id = ?',
      whereArgs: [visitId],
    );

    print('✅ Deleted endocrine visit: $visitId');
    return result;
  }

  Future<List<Map<String, dynamic>>> getLabTrendsForPatient(String patientId, String testName) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'visit_date ASC',
    );

    List<Map<String, dynamic>> trends = [];
    for (var map in maps) {
      if (map['lab_readings'] != null) {
        final readings = jsonDecode(map['lab_readings'] as String) as List;
        for (var reading in readings) {
          if (reading['testName'] == testName) {
            trends.add({
              'date': DateTime.parse(map['visit_date'] as String),
              'value': reading['value'],
              'unit': reading['unit'],
              'status': reading['abnormalityType'] ?? 'normal',
            });
          }
        }
      }
    }
    return trends;
  }

  Future<Map<String, dynamic>> getComparisonData(String patientId, String diseaseId) async {
    final visits = await getEndocrineVisitsByDisease(patientId, diseaseId);

    if (visits.length < 2) {
      return {'hasComparison': false};
    }

    final latest = visits[0];
    final previous = visits[1];

    return {
      'hasComparison': true,
      'currentVisit': {
        'date': latest.createdAt,
        'labReadings': latest.labReadings,
        'clinicalFeatures': latest.clinicalFeatures,
        'medications': latest.medications,
      },
      'previousVisit': {
        'date': previous.createdAt,
        'labReadings': previous.labReadings,
        'clinicalFeatures': previous.clinicalFeatures,
        'medications': previous.medications,
      },
      'changes': _calculateChanges(latest, previous),
    };
  }

  // ==================== PATIENT DATA METHODS ====================

  Future<int> savePatientData(Map<String, dynamic> data) async {
    final db = await this.database;
    return await db.insert(
      'patient_data_snapshots',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLatestPatientData(String patientId) async {
    final db = await this.database;
    final results = await db.query(
      'patient_data_snapshots',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'lastUpdated DESC',
      limit: 1,
    );

    if (results.isNotEmpty) {
      final data = results.first;
      data['vitals'] = data['vitals'] != null
          ? jsonDecode(data['vitals'] as String)
          : {};
      return data;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPatientDataHistory(String patientId) async {
    final db = await this.database;
    return await db.query(
      'patient_data_snapshots',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'lastUpdated DESC',
      limit: 10,
    );
  }

  // ==================== CONSULTATION DRAFT METHODS ====================

  Future<void> saveDraftConsultation(String patientId, Map<String, dynamic> data) async {
    final db = await this.database;
    data['patientId'] = patientId;
    data['isDraft'] = 1;
    data['updatedAt'] = DateTime.now().toIso8601String();
    await db.insert(
      'consultation_drafts',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadDraftConsultation(String patientId) async {
    final db = await this.database;
    final results = await db.query(
      'consultation_drafts',
      where: 'patientId = ? AND isDraft = ?',
      whereArgs: [patientId, 1],
      orderBy: 'updatedAt DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteDraftConsultation(String patientId) async {
    final db = await this.database;
    await db.delete(
      'consultation_drafts',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
  }
  Future<DiseaseTemplate?> getDiseaseTemplateById(int id) async {
    final db = await database;
    final result = await db.query(
      'disease_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DiseaseTemplate.fromMap(result.first);
  }

  /// Get all disease templates
  Future<List<DiseaseTemplate>> getAllDiseaseTemplates() async {
    final db = await database;
    final result = await db.query(
      'disease_templates',
      orderBy: 'id DESC', // newest first
    );

    return result.map((map) => DiseaseTemplate.fromMap(map)).toList();
  }

  /// Insert a new disease template
  Future<int> insertDiseaseTemplate(DiseaseTemplate template) async {
    final db = await database;
    return await db.insert(
      'disease_templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing disease template
  Future<int> updateDiseaseTemplate(DiseaseTemplate template) async {
    final db = await database;
    return await db.update(
      'disease_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Delete a disease template
  Future<int> deleteDiseaseTemplate(int id) async {
    final db = await database;
    return await db.delete(
      'disease_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get templates by category
  Future<List<DiseaseTemplate>> getTemplatesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'disease_templates',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );

    return result.map((map) => DiseaseTemplate.fromMap(map)).toList();
  }

  /// Search templates by name
  Future<List<DiseaseTemplate>> searchTemplates(String query) async {
    final db = await database;
    final result = await db.query(
      'disease_templates',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return result.map((map) => DiseaseTemplate.fromMap(map)).toList();
  }

}