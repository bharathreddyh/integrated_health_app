// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/nurse_home_screen.dart';
import 'screens/home/patient_home_screen.dart';
import 'screens/patient/patient_selection_screen.dart';
import 'screens/patient/patient_registration_screen.dart';
import 'screens/consultation/three_page_consultation_screen.dart';
import 'screens/canvas/canvas_screen.dart';
import 'models/patient.dart';
import 'services/user_service.dart';
import 'services/whisper_voice_service.dart';
import 'widgets/floating_voice_button.dart';
import 'screens/medical_templates/medical_systems_screen.dart';
import 'screens/patient/visit_history_screen.dart';
import 'screens/endocrine/thyroid_disease_module_screen.dart';



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 App starting...');

  final initialized = await WhisperVoiceService.instance.initialize();
  print('🎤 Voice service initialized: $initialized');

  runApp(const ClinicClarityApp());
}

class ClinicClarityApp extends StatelessWidget {
  const ClinicClarityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: WhisperVoiceService.instance,
      child: MaterialApp(
        title: 'IHA',
        navigatorKey: navigatorKey,  // ADD THIS LINE
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,

        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const FloatingVoiceButton(),
            ],
          );
        },

        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/doctor-home': (context) => const HomeScreen(),
          '/nurse-home': (context) => const NurseHomeScreen(),
          '/patient-home': (context) => const PatientHomeScreen(),
          '/patient-selection': (context) => const PatientSelectionScreen(),
          '/patient-registration': (context) => const PatientRegistrationScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle 3-page consultation with patient data
          if (settings.name == '/consultation') {
            final patient = settings.arguments as Patient?;
            if (patient != null) {
              return MaterialPageRoute(
                builder: (context) => ThreePageConsultationScreen(patient: patient),
              );
            }
          }

          // Handle kidney annotation
          if (settings.name == '/kidney') {
            final patient = settings.arguments as Patient?;
            if (patient != null) {
              return MaterialPageRoute(
                builder: (context) => CanvasScreen(patient: patient),
              );
            }
          }
          if (settings.name == '/medical-systems') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              final patient = args['patient'] as Patient;
              final isQuickMode = args['isQuickMode'] as bool? ?? false;
              return MaterialPageRoute(
                builder: (context) => MedicalSystemsScreen(
                  patient: patient,
                  isQuickMode: isQuickMode,
                ),
              );
            }
          }
          if (settings.name == '/patient-history') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null && args['patient'] != null) {
              final patient = args['patient'] as Patient;
              return MaterialPageRoute(
                builder: (context) => VisitHistoryScreen(patient: patient),
              );
            }
          }

          if (settings.name == '/thyroid-module') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              final patientId = args['patientId'] as String;
              final patientName = args['patientName'] as String;
              final diseaseId = args['diseaseId'] as String;
              final diseaseName = args['diseaseName'] as String;
              final conditionId = args['conditionId'] as String?;  // ✅ ADD THIS LINE
              return MaterialPageRoute(
                builder: (context) => ThyroidDiseaseModuleScreen(
                  patientId: patientId,
                  patientName: patientName,
                  diseaseId: diseaseId,
                  diseaseName: diseaseName,
                  conditionId: conditionId,  // ✅ ADD THIS LINE
                ),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return const LoginScreen();
        }

        final user = UserService.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        switch (user.role) {
          case 'doctor':
            return const HomeScreen();
          case 'nurse':
            return const NurseHomeScreen();
          case 'patient':
            return const PatientHomeScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}