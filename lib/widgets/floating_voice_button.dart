// lib/widgets/floating_voice_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/whisper_voice_service.dart';
import '../services/global_voice_navigation.dart';
import '../services/medical_dictation_service.dart';

// Callback type for dictation results
typedef DictationCallback = void Function(DictationResult result);

class FloatingVoiceButton extends StatefulWidget {
  const FloatingVoiceButton({super.key});

  @override
  State<FloatingVoiceButton> createState() => FloatingVoiceButtonState();
}

// CHANGED: Made class name public (removed underscore)
class FloatingVoiceButtonState extends State<FloatingVoiceButton> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  // Store dictation callback from current screen
  static DictationCallback? _dictationCallback;

  // Register a screen's dictation callback
  static void registerDictationCallback(DictationCallback? callback) {
    _dictationCallback = callback;
    print('📝 Dictation callback ${callback != null ? "registered" : "unregistered"}');
  }

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    print('🎤 Initializing voice service...');
    final voiceService = WhisperVoiceService.instance;
    final initialized = await voiceService.initialize();
    print('🎤 Voice service initialized: $initialized');

    voiceService.onTranscription = (transcription) {
      print('📝 Transcription received: "$transcription"');

      if (!mounted) {
        print('❌ Widget not mounted');
        return;
      }

      // First, check if this is a navigation command
      final lowerText = transcription.toLowerCase().trim();
      final isNavCommand = _isNavigationCommand(lowerText);

      if (isNavCommand) {
        print('🧭 Detected navigation command');
        GlobalVoiceNavigation.handleCommand(context, transcription);
        return;
      }

      // If not navigation, check if a screen has registered for dictation
      if (_dictationCallback != null) {
        print('📋 Processing as medical dictation');
        final result = MedicalDictationService.parseDictation(transcription);

        // Show feedback
        _showDictationFeedback(result);

        // Send to registered screen
        _dictationCallback!(result);
      } else {
        print('⚠️ No dictation callback registered, trying navigation');
        GlobalVoiceNavigation.handleCommand(context, transcription);
      }
    };
    print('🎤 Voice callback registered');
  }

  bool _isNavigationCommand(String text) {
    return text.contains('home') ||
        text.contains('back') ||
        text.contains('register') ||
        text.contains('select patient') ||
        text.contains('find patient') ||
        text.contains('patient list');
  }

  void _showDictationFeedback(DictationResult result) {
    if (!mounted) return;

    Color backgroundColor;
    IconData icon;

    switch (result.type) {
      case DictationType.vitals:
        backgroundColor = Colors.blue.shade700;
        icon = Icons.favorite;
        break;
      case DictationType.prescription:
        backgroundColor = Colors.green.shade700;
        icon = Icons.medication;
        break;
      case DictationType.labTest:
        backgroundColor = Colors.orange.shade700;
        icon = Icons.science;
        break;
      case DictationType.diagnosis:
        backgroundColor = Colors.purple.shade700;
        icon = Icons.medical_information;
        break;
      case DictationType.treatment:
        backgroundColor = Colors.teal.shade700;
        icon = Icons.healing;
        break;
      case DictationType.notes:
        backgroundColor = Colors.indigo.shade700;
        icon = Icons.note_add;
        break;
      default:
        backgroundColor = Colors.red.shade700;
        icon = Icons.error_outline;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.feedback,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    if (!mounted) return;

    final size = MediaQuery.maybeOf(context)?.size;
    if (size == null) return;

    final screenWidth = size.width;
    final screenHeight = size.height;

    setState(() {
      if (_position.dx < screenWidth / 2) {
        _position = Offset(20, _position.dy);
      } else {
        _position = Offset(screenWidth - 80, _position.dy);
      }

      _position = Offset(
        _position.dx,
        _position.dy.clamp(50.0, screenHeight - 150.0),
      );
    });
  }

  void _toggleVoiceRecording() async {
    print('🎤 Toggle voice recording');
    final voiceService = WhisperVoiceService.instance;

    if (voiceService.isListening) {
      print('🛑 Stopping recording...');
      await voiceService.stopListening();
    } else {
      print('🔴 Starting recording (5 seconds)...');
      await voiceService.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: WhisperVoiceService.instance,
      child: Consumer<WhisperVoiceService>(
        builder: (context, voiceService, child) {
          return Stack(
            children: [
              // Voice button
              Positioned(
                left: _position.dx,
                top: _position.dy,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onPanStart: (_) => setState(() => _isDragging = true),
                  onTap: _toggleVoiceRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getButtonColor(voiceService.state),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: _isDragging ? 12 : 8,
                          spreadRadius: _isDragging ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIcon(voiceService.state),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // Transcription overlay
              if (voiceService.transcription.isNotEmpty)
                Positioned(
                  left: _position.dx + 70,
                  top: _position.dy,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - _position.dx - 90,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: voiceService.state == VoiceState.listening
                          ? Colors.red.shade900
                          : voiceService.state == VoiceState.error
                          ? Colors.red.shade900
                          : Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (voiceService.state == VoiceState.listening)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        if (voiceService.state == VoiceState.listening)
                          const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            voiceService.transcription,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Color _getButtonColor(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return const Color(0xFF3B82F6);
      case VoiceState.listening:
        return Colors.red;
      case VoiceState.processing:
        return Colors.orange;
      case VoiceState.error:
        return Colors.red.shade900;
    }
  }

  IconData _getIcon(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return Icons.mic_none;
      case VoiceState.listening:
        return Icons.mic;
      case VoiceState.processing:
        return Icons.hourglass_bottom;
      case VoiceState.error:
        return Icons.error_outline;
    }
  }
}