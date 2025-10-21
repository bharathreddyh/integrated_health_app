// lib/services/whisper_voice_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  error,
}

class WhisperVoiceService extends ChangeNotifier {
  static final WhisperVoiceService instance = WhisperVoiceService._();
  WhisperVoiceService._();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  VoiceState _state = VoiceState.idle;
  String _transcription = '';
  Timer? _recordingTimer;
  final int _maxRecordingSeconds = 5;

  VoiceState get state => _state;
  String get transcription => _transcription;
  bool get isListening => _state == VoiceState.listening;

  Function(String)? onTranscription;

  Future<bool> initialize() async {
    try {
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) return false;

      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Error: $error'),
        onStatus: (status) => print('Status: $status'),
      );

      return _isInitialized;
    } catch (e) {
      return false;
    }
  }

  Future<void> startListening() async {
    try {
      if (!_isInitialized) {
        throw Exception('Not initialized');
      }

      _setState(VoiceState.listening);
      _transcription = 'Listening...';

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            _transcription = result.recognizedWords;
            _setState(VoiceState.idle);

            if (onTranscription != null) {
              onTranscription!(result.recognizedWords);
            }
          } else {
            _transcription = result.recognizedWords;
            notifyListeners();
          }
        },
        listenFor: Duration(seconds: _maxRecordingSeconds),
        pauseFor: const Duration(seconds: 3),
      );

      _recordingTimer = Timer(Duration(seconds: _maxRecordingSeconds), () {
        stopListening();
      });
    } catch (e) {
      _setState(VoiceState.error);
      _transcription = 'Error: $e';
    }
  }

  Future<void> stopListening() async {
    _recordingTimer?.cancel();

    try {
      await _speechToText.stop();

      if (_state != VoiceState.error) {
        _setState(VoiceState.idle);
      }
    } catch (e) {
      _setState(VoiceState.error);
      _transcription = 'Error: $e';

      Future.delayed(Duration(seconds: 3), () {
        if (_state == VoiceState.error) reset();
      });
    }
  }

  void _setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  void reset() {
    _setState(VoiceState.idle);
    _transcription = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }
}