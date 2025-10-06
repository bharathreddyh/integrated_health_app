// lib/services/global_voice_navigation.dart

import 'package:flutter/material.dart';
import '../main.dart'; // Import to access navigatorKey

class GlobalVoiceNavigation {
  static void handleCommand(BuildContext context, String command) {
    final lowercaseCommand = command.toLowerCase().trim();
    print('🎯 Heard: "$lowercaseCommand"');

    // Get navigator from global key - this works from anywhere!
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      print('❌ Navigator not available');
      _showFeedback(context, '❌ Navigation not ready');
      return;
    }

    try {
      // HOME navigation
      if (_containsAny(lowercaseCommand, ['home', 'go home', 'main screen', 'dashboard'])) {
        print('✅ Action: Going home');
        navigator.pushNamedAndRemoveUntil('/doctor-home', (r) => false);
        _showFeedback(context, '→ Going Home');
      }
      // SELECT PATIENT
      else if (_containsAny(lowercaseCommand, [
        'select patient',
        'find patient',
        'choose patient',
        'patient list',
        'show patients',
        'patients'
      ])) {
        print('✅ Action: Patient selection');
        navigator.pushNamed('/patient-selection');
        _showFeedback(context, '→ Patient Selection');
      }
      // REGISTER NEW PATIENT
      else if (_containsAny(lowercaseCommand, [
        'register',
        'new patient',
        'add patient',
        'register patient',
        'register new patient',
        'create patient',
        'add new patient'
      ])) {
        print('✅ Action: Register patient');
        navigator.pushNamed('/patient-registration');
        _showFeedback(context, '→ Register Patient');
      }
      // GO BACK
      else if (_containsAny(lowercaseCommand, ['back', 'go back', 'previous'])) {
        print('✅ Action: Going back');
        if (navigator.canPop()) {
          navigator.pop();
          _showFeedback(context, '← Back');
        } else {
          print('⚠️ Cannot pop - already at root');
          _showFeedback(context, '⚠️ Already at home');
        }
      }
      // NO MATCH
      else {
        print('❌ No match for: "$lowercaseCommand"');
        _showFeedback(context, '❌ Say: "go home", "register", or "select patient"');
      }
    } catch (e, stackTrace) {
      print('❌ Navigation Error: $e');
      print('Stack trace: $stackTrace');
      _showFeedback(context, '❌ Error: ${e.toString()}');
    }
  }

  static bool _containsAny(String text, List<String> keywords) {
    // Check for exact phrase matches first, then partial matches
    for (String keyword in keywords) {
      if (text == keyword) return true;
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static void _showFeedback(BuildContext context, String message) {
    if (!context.mounted) {
      print('⚠️ Cannot show feedback - context not mounted');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: message.startsWith('❌') || message.startsWith('⚠️')
              ? Colors.red
              : Colors.green.shade700,
        ),
      );
    } catch (e) {
      print('⚠️ Could not show snackbar: $e');
    }
  }
}