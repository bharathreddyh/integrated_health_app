import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _loginAs(BuildContext context, UserRole role) {
    User user;
    String routeName;

    switch (role) {
      case UserRole.doctor:
        user = const User(
          id: 'DOC001',
          name: 'Dr. Smith',
          email: 'doctor@clinic.com',
          role: UserRole.doctor,
          specialty: 'General Medicine',
        );
        routeName = '/doctor-home';
        break;
      case UserRole.nurse:
        user = const User(
          id: 'NUR001',
          name: 'Nurse Sarah',
          email: 'nurse@clinic.com',
          role: UserRole.nurse,
        );
        routeName = '/nurse-home';
        break;
      case UserRole.patient:
        user = const User(
          id: 'PAT001',
          name: 'John Doe',
          email: 'patient@example.com',
          role: UserRole.patient,
          patientId: 'P001',
        );
        routeName = '/patient-home';
        break;
    }

    UserService.login(user);
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Side - Branding
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Clinic Clarity Suite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Patient education made simple',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Right Side - Login Options
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Welcome',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select your role to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Doctor Login Button
                      _buildRoleButton(
                        context: context,
                        icon: Icons.medical_services,
                        title: 'Doctor',
                        subtitle: 'Consultations & Annotations',
                        color: const Color(0xFF3B82F6),
                        onTap: () => _loginAs(context, UserRole.doctor),
                      ),
                      const SizedBox(height: 16),

                      // Nurse Login Button
                      _buildRoleButton(
                        context: context,
                        icon: Icons.health_and_safety,
                        title: 'Nurse',
                        subtitle: 'Patient Registration & Intake',
                        color: const Color(0xFF10B981),
                        onTap: () => _loginAs(context, UserRole.nurse),
                      ),
                      const SizedBox(height: 16),

                      // Patient Login Button
                      _buildRoleButton(
                        context: context,
                        icon: Icons.person,
                        title: 'Patient',
                        subtitle: 'View My Medical Records',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _loginAs(context, UserRole.patient),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}