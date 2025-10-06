// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/nurse_home_screen.dart';
import 'screens/home/patient_home_screen.dart';
import 'screens/patient/patient_selection_screen.dart';
import 'screens/kidney/kidney_screen.dart';
import 'models/patient.dart';
import 'services/user_service.dart';
import 'services/whisper_voice_service.dart';
import 'widgets/floating_voice_button.dart';
import 'screens/patient/patient_registration_screen.dart';

// Global navigator key for voice commands
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 App starting...');

  // Initialize voice service
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
        navigatorKey: navigatorKey, // ADD THIS - gives global access to navigator
        title: 'Clinic Clarity Suite',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,

        // Show floating button on ALL screens
        builder: (context, child) {
          print('🗃️ Builder called - adding floating button');
          return Stack(
            children: [
              child!,
              const FloatingVoiceButton(), // Always visible for testing
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
          if (settings.name == '/kidney') {
            final patient = settings.arguments as Patient?;
            return MaterialPageRoute(
              builder: (context) => KidneyScreen(patient: patient),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final route = await UserService.getInitialRoute();
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}