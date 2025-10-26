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
    _database = await _initDB('clinic.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
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

    // ✅ FIXED: Visits table with ALL required columns
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
        patientId TEXT NOT NULL,
        gland TEXT NOT NULL,
        category TEXT NOT NULL,
        diseaseId TEXT NOT NULL,
        diseaseName TEXT NOT NULL,
        status TEXT NOT NULL,
        diagnosisDate TEXT,
        severity TEXT,
        labReadings TEXT,
        clinicalFeatures TEXT,
        complications TEXT,
        medications TEXT,
        images TEXT,
        notes TEXT,
        treatmentPlan TEXT,
        nextVisit TEXT,
        followUpPlan TEXT,
        createdAt TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (patientId) REFERENCES patients (id)
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
  }

  // PASSWORD HASHING
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // USER METHODS
  Future<User?> authenticateUser(String email, String password) async {
    final db = await database;
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
    final db = await database;
    final userMap = user.toMap();
    userMap['password_hash'] = _hashPassword(password);
    return await db.insert('users', userMap);
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllDoctors() async {
    final db = await database;
    final maps = await db.query('users', where: 'role = ?', whereArgs: ['doctor']);
    return maps.map((map) => User.fromMap(map)).toList();
  }

  // PATIENT METHODS
  Future<int> createPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<int> insertPatient(Patient patient) async {
    return await createPatient(patient);
  }

  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final maps = await db.query('patients', orderBy: 'name ASC');
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  Future<Patient?> getPatient(String id) async {
    final db = await database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Patient.fromMap(maps.first);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> deletePatient(String id) async {
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final maps = await db.query(
      'patients',
      where: 'name LIKE ? OR id LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => Patient.fromMap(map)).toList();
  }

  // VISIT METHODS
  Future<int> insertVisit(Visit visit, String doctorId) async {
    final db = await database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;

    // ✅ ADDED: Ensure is_edited and original_visit_id are properly set
    visitMap['is_edited'] = visit.isEdited ? 1 : 0;
    visitMap['original_visit_id'] = visit.originalVisitId;

    return await db.insert('visits', visitMap);
  }

  Future<int> createVisit(Visit visit, String doctorId) async {
    return await insertVisit(visit, doctorId);
  }

  Future<int> updateVisit(Visit visit, String doctorId) async {
    final db = await database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;

    // ✅ ADDED: Ensure is_edited and original_visit_id are properly set
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
    final db = await database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Visit.fromMap(map)).toList();
  }

  Future<Visit?> getVisitById(int id) async {
    final db = await database;
    final maps = await db.query(
      'visits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<Visit?> getLastVisit(String patientId, {String? diagramType}) async {
    final db = await database;
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

  Future<Map<String, List<Visit>>> getVisitsGroupedBySystem(String patientId) async {
    final db = await database;
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
    final db = await database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  // PRESCRIPTION METHODS
  Future<int> insertPrescription(Prescription prescription, String doctorId) async {
    final db = await database;
    final prescMap = prescription.toMap();
    prescMap['doctor_id'] = doctorId;
    return await db.insert('prescriptions', prescMap);
  }

  Future<int> updatePrescription(Prescription prescription, String doctorId) async {
    final db = await database;
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
    final db = await database;
    return await db.delete('prescriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Prescription>> getPrescriptionsByVisit(int visitId) async {
    final db = await database;
    final maps = await db.query(
      'prescriptions',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  Future<List<Prescription>> getPrescriptionsByPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'prescriptions',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Prescription.fromMap(map)).toList();
  }

  // LAB TEST METHODS
  Future<int> insertLabTest(LabTest test) async {
    final db = await database;
    return await db.insert('lab_tests', test.toMap());
  }

  Future<int> updateLabTest(LabTest test) async {
    final db = await database;
    return await db.update(
      'lab_tests',
      test.toMap(),
      where: 'id = ?',
      whereArgs: [test.id],
    );
  }

  Future<List<LabTest>> getLabTestsByVisit(int visitId) async {
    final db = await database;
    final maps = await db.query(
      'lab_tests',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'ordered_date DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  Future<List<LabTest>> getLabTestsByPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'lab_tests',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'ordered_date DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  // CONSULTATION DRAFT METHODS
  Future<void> saveDraftConsultation(String patientId, Map<String, dynamic> data) async {
    final db = await database;
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
    final db = await database;
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
    final db = await database;
    await db.delete(
      'consultation_drafts',
      where: 'patientId = ?',
      whereArgs: [patientId],
    );
  }

  // PATIENT DATA SNAPSHOT METHODS
  Future<void> savePatientDataSnapshot(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('patient_data_snapshots', data);
  }

  Future<List<Map<String, dynamic>>> getPatientDataSnapshots(String patientId) async {
    final db = await database;
    return await db.query(
      'patient_data_snapshots',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'lastUpdated DESC',
      limit: 10,
    );
  }
}