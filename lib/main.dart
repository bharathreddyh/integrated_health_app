import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/nurse_home_screen.dart';
import 'screens/home/patient_home_screen.dart';
import 'screens/patient/patient_selection_screen.dart';
import 'screens/kidney/kidney_screen.dart';
import 'models/patient.dart';
import 'services/user_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AuthWrapper(),
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

// Auth Wrapper - checks if user is logged in
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserService.getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final route = snapshot.data ?? '/login';

        // Navigate to appropriate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, route);
        });

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}