import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/nurse_home_screen.dart';
import 'screens/home/patient_home_screen.dart';
import 'screens/patient/patient_selection_screen.dart';
import 'screens/kidney/kidney_screen.dart';
import 'models/patient.dart';

void main() {
  runApp(const ClinicClarityApp());
}

class ClinicClarityApp extends StatelessWidget {
  const ClinicClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Clarity Suite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/doctor-home': (context) => const HomeScreen(),
        '/nurse-home': (context) => const NurseHomeScreen(),
        '/patient-home': (context) => const PatientHomeScreen(),
        '/patient-selection': (context) => const PatientSelectionScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/kidney') {
          final patient = settings.arguments as Patient?;
          return MaterialPageRoute(
            builder: (context) => KidneyScreen(patient: patient!),
          );
        }
        return null;
      },
    );
  }
}