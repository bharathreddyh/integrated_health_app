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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('clinic_v2.db');
    return _database!;
  }
  Future<void> migrateEndocrineConditionsData() async {
    final db = await this.database;

    try {
      print('🔧 Starting endocrine_conditions data migration...');

      // Get all endocrine conditions
      final conditions = await db.query('endocrine_conditions');
      print('Found ${conditions.length} conditions to migrate');

      for (var condition in conditions) {
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Check if vitals needs re-encoding
        if (condition['vitals'] != null && condition['vitals'] is String) {
          try {
            // Try to decode to verify it's valid JSON
            final vitalsStr = condition['vitals'] as String;
            if (vitalsStr.isNotEmpty) {
              jsonDecode(vitalsStr);
              // If successful, no update needed for this field
            }
          } catch (e) {
            // If decode fails, the data might be corrupted
            print('⚠️ Corrupted vitals data for condition ${condition['id']}, will reset');
            updates['vitals'] = null;
            needsUpdate = true;
          }
        }

        // Check if measurements needs re-encoding
        if (condition['measurements'] != null && condition['measurements'] is String) {
          try {
            // Try to decode to verify it's valid JSON
            final measurementsStr = condition['measurements'] as String;
            if (measurementsStr.isNotEmpty) {
              jsonDecode(measurementsStr);
              // If successful, no update needed for this field
            }
          } catch (e) {
            // If decode fails, the data might be corrupted
            print('⚠️ Corrupted measurements data for condition ${condition['id']}, will reset');
            updates['measurements'] = null;
            needsUpdate = true;
          }
        }

        // Ensure is_active is an integer
        if (condition['is_active'] != null) {
          final isActive = condition['is_active'];
          if (isActive is bool) {
            updates['is_active'] = isActive ? 1 : 0;
            needsUpdate = true;
          }
        }

        // Update if needed
        if (needsUpdate) {
          await db.update(
            'endocrine_conditions',
            updates,
            where: 'id = ?',
            whereArgs: [condition['id']],
          );
          print('✅ Migrated condition ${condition['id']}');
        }
      }

      print('✅ Migration complete');
    } catch (e) {
      print('❌ Migration error: $e');
    }
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('🔧 Database path: $path');
    print('🔧 Database version: 13');
    return await openDatabase(
      path,
      version: 14,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    print('🔨 Creating NEW database with version $version');

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

    // ✅ FIXED: Visits table with ALL required columns including is_edited and original_visit_id
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
    print('✅ endocrine_conditions table has columns: patient_id, disease_id, chief_complaint, etc.');
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

    // Version 10: Add consultation drafts
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS consultation_drafts(
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
      print('✅ Created consultation_drafts table');
    }

    // Version 11: Add patient data snapshots
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patient_data_snapshots (
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
      print('✅ Created patient_data_snapshots table');
    }

    // Version 12: Add editing support columns
    if (oldVersion < 12) {
      try {
        await db.execute('ALTER TABLE visits ADD COLUMN is_edited INTEGER DEFAULT 0');
        print('✅ Added is_edited column to visits table');
      } catch (e) {
        print('is_edited column may already exist: $e');
      }

      try {
        await db.execute('ALTER TABLE visits ADD COLUMN original_visit_id INTEGER');
        print('✅ Added original_visit_id column to visits table');
      } catch (e) {
        print('original_visit_id column may already exist: $e');
      }
    }

    // Version 13: Add patient data columns to endocrine_conditions
    if (oldVersion < 13) {
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
      await migrateEndocrineConditionsData();
      print('✅ Migrated to version 14');
    }

  // PASSWORD HASHING
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
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
    return await createPatient(patient);
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await this.database;
    final maps = await db.query('patients', orderBy: 'name ASC');
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await this.database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await this.database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(String id) async {
    final db = await this.database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
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

    // ✅ Ensure is_edited and original_visit_id are properly set
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

    // ✅ Ensure is_edited and original_visit_id are properly set
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

  // ✅ ADDED: Get all visits for patient (for diagram gallery)
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

  // ✅ ADDED: Get latest visit with optional system parameter
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

    // ✅ FIX: Properly format data to match database schema
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

      // Patient Data
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
      'lab_test_results': jsonEncode(condition.labTestResults),
      'investigation_findings': jsonEncode(condition.investigationFindings),
      'selected_symptoms': jsonEncode(condition.selectedSymptoms),
      'selected_diagnostic_criteria': jsonEncode(condition.selectedDiagnosticCriteria),
      'selected_complications': jsonEncode(condition.selectedComplications),

      // Clinical Data - JSON encoded
      'lab_readings': jsonEncode(condition.labReadings.map((x) => x.toJson()).toList()),
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((x) => x.toJson()).toList()),
      'complications': jsonEncode(condition.complications.map((x) => x.toJson()).toList()),
      'medications': jsonEncode(condition.medications.map((x) => x.toJson()).toList()),
      'images': jsonEncode(condition.images.map((x) => x.toJson()).toList()),

      // Simple fields
      'notes': condition.notes,
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,
      'next_visit': condition.nextVisit?.toIso8601String(),
      'follow_up_plan': condition.followUpPlan,

      // Meta
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': condition.lastUpdated.toIso8601String(),
      // ✅ CRITICAL: Convert boolean to integer
      'is_active': condition.isActive ? 1 : 0,
    };

    return await db.insert(
      'endocrine_conditions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EndocrineCondition>> getEndocrineConditions(String patientId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_conditions',
      where: 'patient_id = ? AND is_active = ?',
      whereArgs: [patientId, 1],
    );
    return maps.map((map) => _endocrineConditionFromMap(map)).toList();
  }

  // ✅ NEW: Get specific active condition by disease
  Future<EndocrineCondition?> getActiveEndocrineCondition(String patientId, String diseaseId) async {
    final db = await this.database;

    print('🔍 DB QUERY: getActiveEndocrineCondition');
    print('   patient_id = "$patientId"');
    print('   disease_id = "$diseaseId"');

    final maps = await db.query(
      'endocrine_conditions',
      where: 'patient_id = ? AND disease_id = ? AND is_active = ?',
      whereArgs: [patientId, diseaseId, 1],
      orderBy: 'last_updated DESC',
      limit: 1,
    );

    print('   Found ${maps.length} active conditions in endocrine_conditions table');

    if (maps.isEmpty) {
      print('   ⚠️  No active condition found in endocrine_conditions');
      return null;
    }

    print('   ✅ Found active condition');

    try {
      final condition = _endocrineConditionFromMap(maps.first);
      print('   ✅ Successfully parsed condition');
      print('      Chief complaint: "${condition.chiefComplaint ?? "null"}"');
      print('      Has vitals: ${condition.vitals != null}');
      print('      Vitals keys: ${condition.vitals?.keys.toList()}');
      return condition;
    } catch (e, stackTrace) {
      print('   ❌ ERROR PARSING CONDITION');
      print('      Error: $e');
      print('      Stack: ${stackTrace.toString().split('\n').take(5).join('\n      ')}');
      rethrow;
    }
  }

  Future<int> deleteEndocrineVisit(String visitId) async {
    final db = await this.database;

    print('🗑️ Deleting endocrine visit with ID: $visitId');

    // Delete from endocrine_visits table
    final result = await db.delete(
      'endocrine_visits',
      where: 'id = ?',
      whereArgs: [visitId],
    );

    // Also delete from endocrine_conditions table if it exists there
    await db.delete(
      'endocrine_conditions',
      where: 'id = ?',
      whereArgs: [visitId],
    );

    print('✅ Deleted endocrine visit: $visitId');
    return result;
  }
  // ✅ ADDED: Update endocrine condition
  Future<int> updateEndocrineCondition(EndocrineCondition condition) async {
    final db = await this.database;

    // ✅ FIX: Properly format data to match database schema
    final updateData = {
      'patient_id': condition.patientId,
      'gland': condition.gland,
      'category': condition.category,
      'disease_id': condition.diseaseId,
      'disease_name': condition.diseaseName,
      'status': condition.status.toString().split('.').last,
      'diagnosis_date': condition.diagnosisDate?.toIso8601String(),
      'severity': condition.severity?.toString().split('.').last,

      // Patient Data
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
      'lab_test_results': jsonEncode(condition.labTestResults),
      'investigation_findings': jsonEncode(condition.investigationFindings),
      'selected_symptoms': jsonEncode(condition.selectedSymptoms),
      'selected_diagnostic_criteria': jsonEncode(condition.selectedDiagnosticCriteria),
      'selected_complications': jsonEncode(condition.selectedComplications),

      // Clinical Data - JSON encoded
      'lab_readings': jsonEncode(condition.labReadings.map((x) => x.toJson()).toList()),
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((x) => x.toJson()).toList()),
      'complications': jsonEncode(condition.complications.map((x) => x.toJson()).toList()),
      'medications': jsonEncode(condition.medications.map((x) => x.toJson()).toList()),
      'images': jsonEncode(condition.images.map((x) => x.toJson()).toList()),

      // Simple fields
      'notes': condition.notes,
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,
      'next_visit': condition.nextVisit?.toIso8601String(),
      'follow_up_plan': condition.followUpPlan,

      // Meta
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
      // ✅ CRITICAL: Convert boolean to integer
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

      // Patient Data
      'chief_complaint': condition.chiefComplaint,
      'history_present_illness': condition.historyOfPresentIllness,
      'past_medical_history': condition.pastMedicalHistory,
      'family_history': condition.familyHistory,
      'allergies': condition.allergies,
      'vitals': condition.vitals != null ? jsonEncode(condition.vitals) : null,
      'measurements': condition.measurements != null ? jsonEncode(condition.measurements) : null,
      'ordered_lab_tests': condition.orderedLabTests != null ? jsonEncode(condition.orderedLabTests) : null,
      'ordered_investigations': condition.orderedInvestigations != null ? jsonEncode(condition.orderedInvestigations) : null,

      // Clinical Features
      'clinical_features': jsonEncode(condition.clinicalFeatures.map((f) => f.toJson()).toList()),

      // Lab Readings
      'lab_readings': jsonEncode(condition.labReadings.map((r) => r.toJson()).toList()),

      // Investigations
      'investigation_findings': condition.investigationFindings != null ? jsonEncode(condition.investigationFindings) : null,
      'images': jsonEncode(condition.images.map((i) => i.toJson()).toList()),

      // Treatment
      'medications': jsonEncode(condition.medications.map((m) => m.toJson()).toList()),
      'treatment_plan': condition.treatmentPlan != null ? jsonEncode(condition.treatmentPlan!.toJson()) : null,

      // Complications
      'complications': jsonEncode(condition.complications.map((c) => c.toJson()).toList()),

      // Notes
      'notes': condition.notes,
      'follow_up_plan': condition.followUpPlan,
      'next_visit': condition.nextVisit?.toIso8601String(),

      // Meta
      'created_at': condition.createdAt.toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
      'is_active': condition.isActive ? 1 : 0,
    };

    await db.insert('endocrine_visits', visitData, conflictAlgorithm: ConflictAlgorithm.replace);
    return condition.id;
  }

  Future<List<EndocrineCondition>> getEndocrineVisitsByPatient(String patientId) async {
    final db = await this.database;

    print('🔍 Loading endocrine visits for patient: $patientId');

    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'visit_date DESC',
    );

    print('   Found ${maps.length} visits in database');

    try {

      final conditions = maps.map((map) => _endocrineConditionFromMap(map)).toList();
      print('✅ Successfully parsed all ${conditions.length} conditions');
      return conditions;
    } catch (e, stackTrace) {
      print('❌ Error parsing endocrine visits: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<EndocrineCondition>> getEndocrineVisitsByDisease(String patientId, String diseaseId) async {
    final db = await this.database;
    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ? AND disease_id = ?',
      whereArgs: [patientId, diseaseId],
      orderBy: 'visit_date DESC',
    );
    return maps.map((map) => _endocrineConditionFromMap(map)).toList();
  }

  Future<EndocrineCondition?> getLatestEndocrineVisit(String patientId, String diseaseId) async {
    final db = await this.database;

    print('🔍 DB QUERY: getLatestEndocrineVisit');
    print('   patient_id = "$patientId"');
    print('   disease_id = "$diseaseId"');

    final maps = await db.query(
      'endocrine_visits',
      where: 'patient_id = ? AND disease_id = ?',
      whereArgs: [patientId, diseaseId],
      orderBy: 'visit_date DESC',
      limit: 1,
    );

    print('   Found ${maps.length} records');

    if (maps.isEmpty) {
      print('   ⚠️  No matching records');

      // DEBUG: Check what's actually in the database
      final allForPatient = await db.query(
        'endocrine_visits',
        where: 'patient_id = ?',
        whereArgs: [patientId],
      );
      print('   DEBUG: Patient has ${allForPatient.length} total visits');
      for (var record in allForPatient) {
        print('      - disease_id: "${record['disease_id']}" (${record['disease_name']})');
      }

      return null;
    }

    print('   ✅ Found matching record');

    try {
      final condition = _endocrineConditionFromMap(maps.first);
      print('   ✅ Successfully parsed condition');
      print('      Chief complaint: "${condition.chiefComplaint ?? "null"}"');
      print('      Has vitals: ${condition.vitals != null}');
      return condition;
    } catch (e, stackTrace) {
      print('   ❌ ERROR PARSING CONDITION');
      print('      Error: $e');
      print('      This will cause blank screen!');
      print('      Stack: ${stackTrace.toString().split('\n').take(5).join('\n      ')}');

      // ⚠️ DO NOT return null - rethrow so we see the error
      rethrow;
    }
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
          'percentChange': ((currentReading.value - previousReading.value) / previousReading.value * 100).toStringAsFixed(1),
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

  EndocrineCondition _endocrineConditionFromMap(Map<String, dynamic> map) {
    // ==================== SAFE JSON PARSING HELPERS ====================

    T? _safeJsonDecode<T>(dynamic value, T Function(dynamic) parser) {
      if (value == null) return null;
      // Handle both String (JSON) and direct Map/List values
      if (value is T) return value;
      if (value is String) {
        if (value.isEmpty) return null;
        try {
          final decoded = jsonDecode(value);
          return parser(decoded);
        } catch (e) {
          print('⚠️ JSON decode error for value: $value');
          print('   Error: $e');
          return null;
        }
      }
      if (value is Map || value is List) {
        try {
          return parser(value);
        } catch (e) {
          print('⚠️ Parse error for direct value: $e');
          return null;
        }
      }
      return null;
    }

    List<T> _safeJsonDecodeList<T>(dynamic value, T Function(dynamic) itemParser) {
      if (value == null) return [];
      // Handle both String (JSON) and direct List values
      if (value is List) {
        return value
            .map((item) {
          try {
            return itemParser(item);
          } catch (e) {
            print('⚠️ Item parse error: $e');
            return null;
          }
        })
            .where((item) => item != null)
            .cast<T>()
            .toList();
      }
      if (value is String) {
        if (value.isEmpty) return [];
        try {
          final decoded = jsonDecode(value);
          if (decoded is! List) return [];
          return (decoded as List)
              .map((item) {
            try {
              return itemParser(item);
            } catch (e) {
              return null;
            }
          })
              .where((item) => item != null)
              .cast<T>()
              .toList();
        } catch (e) {
          print('⚠️ JSON list decode error: $e');
          return [];
        }
      }
      return [];
    }

    // ==================== BUILD CONDITION WITH FIELD CHECKING ====================

    try {
      // Debug: Print available fields and their values for patient data
      print('📋 Loading condition from database:');
      print('   ID: ${map['id']}');
      print('   Patient: ${map['patient_id']}');
      print('   Disease: ${map['disease_name']}');
      print('   Chief Complaint: "${map['chief_complaint'] ?? "null"}"');

      // Debug vitals parsing
      if (map['vitals'] != null) {
        print('   Vitals raw type: ${map['vitals'].runtimeType}');
        print('   Vitals raw value: ${map['vitals']}');
      }

      // Debug measurements parsing
      if (map['measurements'] != null) {
        print('   Measurements raw type: ${map['measurements'].runtimeType}');
        print('   Measurements raw value: ${map['measurements']}');
      }

      // Helper to safely get string fields
      String? _safeString(String key) => map[key] as String?;

      // Parse vitals with better error handling
      Map<String, String>? parsedVitals;
      if (map['vitals'] != null) {
        parsedVitals = _safeJsonDecode(
          map['vitals'],
              (decoded) {
            if (decoded is Map) {
              // Convert all values to strings
              return Map<String, String>.from(
                  decoded.map((key, value) => MapEntry(key.toString(), value.toString()))
              );
            }
            return null;
          },
        );
        print('   Parsed vitals: ${parsedVitals?.keys.toList()}');
      }

      // Parse measurements with better error handling
      Map<String, String>? parsedMeasurements;
      if (map['measurements'] != null) {
        parsedMeasurements = _safeJsonDecode(
          map['measurements'],
              (decoded) {
            if (decoded is Map) {
              // Convert all values to strings
              return Map<String, String>.from(
                  decoded.map((key, value) => MapEntry(key.toString(), value.toString()))
              );
            }
            return null;
          },
        );
        print('   Parsed measurements: ${parsedMeasurements?.keys.toList()}');
      }

      final condition = EndocrineCondition(
        // Required fields
        id: map['id'] as String,
        patientId: map['patient_id'] as String,
        patientName: _safeString('patient_name') ?? '',
        gland: _safeString('gland') ?? 'thyroid',
        category: _safeString('category') ?? '',
        diseaseId: _safeString('disease_id') ?? '',
        diseaseName: _safeString('disease_name') ?? '',

        // Enum with safe parsing
        status: DiagnosisStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['status'],
          orElse: () => DiagnosisStatus.suspected,
        ),

        severity: _safeString('severity') != null
            ? DiseaseSeverity.values.firstWhere(
              (e) => e.toString().split('.').last == map['severity'],
          orElse: () => DiseaseSeverity.mild,
        )
            : null,

        // Date fields
        diagnosisDate: _safeString('diagnosis_date') != null
            ? DateTime.tryParse(_safeString('diagnosis_date')!)
            : null,

        // Text fields (Patient Data Tab) - CRITICAL: These must be loaded correctly
        chiefComplaint: _safeString('chief_complaint'),
        historyOfPresentIllness: _safeString('history_present_illness'),
        pastMedicalHistory: _safeString('past_medical_history'),
        familyHistory: _safeString('family_history'),
        allergies: _safeString('allergies'),

        // JSON fields - CRITICAL: Use the parsed values
        vitals: parsedVitals,
        measurements: parsedMeasurements,

        orderedLabTests: _safeJsonDecode(
          map['ordered_lab_tests'],
              (decoded) {
            if (decoded is List) {
              return List<Map<String, dynamic>>.from(decoded);
            }
            return null;
          },
        ),

        orderedInvestigations: _safeJsonDecode(
          map['ordered_investigations'],
              (decoded) {
            if (decoded is List) {
              return List<Map<String, dynamic>>.from(decoded);
            }
            return null;
          },
        ),

        additionalData: _safeJsonDecode(
          map['additional_data'],
              (decoded) {
            if (decoded is Map) {
              return Map<String, dynamic>.from(decoded);
            }
            return null;
          },
        ),

        investigationFindings: _safeJsonDecode(
          map['investigation_findings'],
              (decoded) => decoded,
        ),

        // These fields might not exist in older database versions
        labTestResults: map.containsKey('lab_test_results')
            ? _safeJsonDecodeList(map['lab_test_results'], (item) => item)
            : [],

        selectedSymptoms: map.containsKey('selected_symptoms')
            ? _safeJsonDecodeList(map['selected_symptoms'], (item) => item.toString())
            : [],

        selectedDiagnosticCriteria: map.containsKey('selected_diagnostic_criteria')
            ? _safeJsonDecodeList(map['selected_diagnostic_criteria'], (item) => item.toString())
            : [],

        selectedComplications: map.containsKey('selected_complications')
            ? _safeJsonDecodeList(map['selected_complications'], (item) => item.toString())
            : [],

        // Complex JSON arrays
        labReadings: map.containsKey('lab_readings')
            ? _safeJsonDecodeList(
          map['lab_readings'],
              (item) => LabReading.fromJson(Map<String, dynamic>.from(item)),
        )
            : [],

        clinicalFeatures: map.containsKey('clinical_features')
            ? _safeJsonDecodeList(
          map['clinical_features'],
              (item) => ClinicalFeature.fromJson(Map<String, dynamic>.from(item)),
        )
            : [],

        complications: map.containsKey('complications')
            ? _safeJsonDecodeList(
          map['complications'],
              (item) => Complication.fromJson(Map<String, dynamic>.from(item)),
        )
            : [],

        medications: map.containsKey('medications')
            ? _safeJsonDecodeList(
          map['medications'],
              (item) => Medication.fromJson(Map<String, dynamic>.from(item)),
        )
            : [],

        images: map.containsKey('images')
            ? _safeJsonDecodeList(
          map['images'],
              (item) => MedicalImage.fromJson(Map<String, dynamic>.from(item)),
        )
            : [],

        // Simple fields
        notes: _safeString('notes') ?? '',

        treatmentPlan: _safeJsonDecode(
          map['treatment_plan'],
              (decoded) => TreatmentPlan.fromJson(Map<String, dynamic>.from(decoded)),
        ),

        nextVisit: _safeString('next_visit') != null
            ? DateTime.tryParse(_safeString('next_visit')!)
            : null,

        followUpPlan: _safeString('follow_up_plan') ?? '',

        // Timestamps
        createdAt: _safeString('created_at') != null
            ? DateTime.parse(_safeString('created_at')!)
            : DateTime.now(),

        lastUpdated: _safeString('last_updated') != null
            ? DateTime.parse(_safeString('last_updated')!)
            : DateTime.now(),

        // Active flag - handle both integer (from DB) and boolean
        isActive: map['is_active'] == 1 || map['is_active'] == true,
      );

      print('✅ Successfully parsed condition:');
      print('   Chief Complaint: "${condition.chiefComplaint ?? "null"}"');
      print('   Vitals: ${condition.vitals?.keys.toList() ?? "null"}');
      print('   Measurements: ${condition.measurements?.keys.toList() ?? "null"}');

      return condition;
    } catch (e, stackTrace) {
      print('❌ ERROR in _endocrineConditionFromMap');
      print('   Map keys: ${map.keys.toList()}');
      print('   Error: $e');
      print('   Stack: ${stackTrace.toString().split('\n').take(10).join('\n   ')}');
      rethrow;
    }
  }
// ==================== PATIENT DATA SNAPSHOT METHODS ====================

// ✅ ADDED: Save patient data
  Future<void> savePatientData(Map<String, dynamic> data) async {
    final db = await this.database;

    final dataToSave = {
      'patientId': data['patientId'],
      'chiefComplaint': data['chiefComplaint'],
      'historyOfPresentIllness': data['historyOfPresentIllness'],
      'pastMedicalHistory': data['pastMedicalHistory'],
      'familyHistory': data['familyHistory'],
      'allergies': data['allergies'],
      'vitals': jsonEncode(data['vitals']),
      'height': data['height'],
      'weight': data['weight'],
      'bmi': data['bmi'],
      'lastUpdated': data['lastUpdated'],
      'updatedFrom': data['updatedFrom'],
    };

    await db.insert(
      'patient_data_snapshots',
      dataToSave,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// ✅ ADDED: Get latest patient data
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
  }}
}