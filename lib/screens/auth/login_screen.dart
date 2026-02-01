import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Dev auto-login: skip password entry
    _devAutoLogin();
  }

  Future<void> _devAutoLogin() async {
    try {
      final user = await DatabaseHelper.instance.authenticateUser(
        'admin@clinic.com',
        'admin123',
      );
      if (user != null && mounted) {
        await UserService.login(user);
        Navigator.pushReplacementNamed(context, '/doctor-home');
      }
    } catch (_) {
      // Fall through to manual login if auto-login fails
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await DatabaseHelper.instance.authenticateUser(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user == null) {
        setState(() {
          _errorMessage = 'Invalid email or password';
          _isLoading = false;
        });
        return;
      }

      // Save login state
      await UserService.login(user);

      if (!mounted) return;

      // Navigate based on role
      switch (user.role) {
        case UserRole.doctor:
          Navigator.pushReplacementNamed(context, '/doctor-home');
          break;
        case UserRole.nurse:
          Navigator.pushReplacementNamed(context, '/nurse-home');
          break;
        case UserRole.patient:
          Navigator.pushReplacementNamed(context, '/patient-home');
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizing
    final isSmallScreen = screenHeight < 700;
    final logoSize = isSmallScreen ? 80.0 : 100.0;
    final titleSize = isSmallScreen ? 28.0 : 32.0;
    final spacing = isSmallScreen ? 16.0 : 24.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  physics: constraints.maxHeight < 600
                      ? const AlwaysScrollableScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth > 600 ? 48 : 24,
                          vertical: spacing,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.local_hospital,
                                size: logoSize * 0.5,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            SizedBox(height: spacing),

                            // Title
                            Text(
                              'IHA',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: spacing * 0.3),
                            Text(
                              'Medical Practice Management',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13.0 : 16.0,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacing * 1.5),

                            // Login Card
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: screenWidth > 600 ? 400 : double.infinity,
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 20.0 : 24.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: spacing * 0.8),

                                    // Error Message
                                    if (_errorMessage != null)
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        margin: EdgeInsets.only(bottom: spacing * 0.6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline,
                                              color: Colors.red.shade700,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: const TextStyle(fontSize: 13),
                                        prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: spacing * 0.6),

                                    // Password Field
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(fontSize: 13),
                                        prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: spacing),

                                    // Login Button
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 14 : 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14.0 : 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: spacing * 0.5),

                                    // Register Link
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const RegistrationScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                      child: Text(
                                        "Don't have an account? Register",
                                        style: TextStyle(fontSize: isSmallScreen ? 12.0 : 13.0),
                                      ),
                                    ),

                                    SizedBox(height: spacing * 0.6),
                                    const Divider(height: 1),
                                    SizedBox(height: spacing * 0.6),

                                    // Demo Credentials
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Demo Credentials',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Email: admin@clinic.com\nPassword: admin123',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}