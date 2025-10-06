import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/visit.dart';
import '../models/prescription.dart';
import '../models/user.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/lab_test.dart';

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
    return await openDatabase(path, version: 7, onCreate: _createDB, onUpgrade: _onUpgrade);  }

  Future<void> _createDB(Database db, int version) async {
    // Users table - NEW
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

    await db.execute('''
      CREATE TABLE visits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        diagram_type TEXT NOT NULL,
        markers TEXT NOT NULL,
        drawing_paths TEXT, 
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

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
    if (oldVersion < 6) {
      // Create users table
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
      // Add doctor_id to visits
      try {
        await db.execute('ALTER TABLE visits ADD COLUMN doctor_id TEXT DEFAULT "USR001"');
      } catch (e) {
        print('doctor_id already exists in visits: $e');
      }

      // Add doctor_id to prescriptions
      try {
        await db.execute('ALTER TABLE prescriptions ADD COLUMN doctor_id TEXT DEFAULT "USR001"');
      } catch (e) {
        print('doctor_id already exists in prescriptions: $e');
      }

      // Create default admin if not exists
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

  // VISIT METHODS (UPDATED)
  Future<int> insertVisit(Visit visit, String doctorId) async {
    final db = await database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;
    return await db.insert('visits', visitMap);
  }

  Future<int> createVisit(Visit visit, String doctorId) async {
    return await insertVisit(visit, doctorId);
  }

  Future<int> updateVisit(Visit visit, String doctorId) async {
    final db = await database;
    final visitMap = visit.toMap();
    visitMap['doctor_id'] = doctorId;
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

  Future<List<Visit>> getPatientVisits(String patientId) async {
    return await getVisitsByPatient(patientId);
  }

  Future<Visit?> getLatestVisit({
    required String patientId,
    required String diagramType,
  }) async {
    final db = await database;
    final maps = await db.query(
      'visits',
      where: 'patient_id = ? AND diagram_type = ?',
      whereArgs: [patientId, diagramType],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Visit.fromMap(maps.first);
  }

  Future<int> deleteVisit(int id) async {
    final db = await database;
    return await db.delete('visits', where: 'id = ?', whereArgs: [id]);
  }

  // PRESCRIPTION METHODS (UPDATED)
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
  Future<int> insertLabTest(LabTest labTest, String doctorId) async {
    final db = await database;
    final testMap = labTest.toMap();
    testMap['doctor_id'] = doctorId;
    return await db.insert('lab_tests', testMap);
  }

  Future<int> updateLabTest(LabTest labTest, String doctorId) async {
    final db = await database;
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
    final db = await database;
    return await db.delete('lab_tests', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LabTest>> getLabTestsByVisit(int visitId) async {
    final db = await database;
    final maps = await db.query(
      'lab_tests',
      where: 'visit_id = ?',
      whereArgs: [visitId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  Future<List<LabTest>> getLabTestsByPatient(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'lab_tests',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }

  Future<List<LabTest>> getPendingLabTests(String patientId) async {
    final db = await database;
    final maps = await db.query(
      'lab_tests',
      where: 'patient_id = ? AND status = ?',
      whereArgs: [patientId, 'pending'],
      orderBy: 'ordered_date DESC',
    );
    return maps.map((map) => LabTest.fromMap(map)).toList();
  }
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}