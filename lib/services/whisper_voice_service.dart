import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/api_keys.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  error,
}

class WhisperVoiceService extends ChangeNotifier {
  static final WhisperVoiceService instance = WhisperVoiceService._();
  WhisperVoiceService._();

  static final String _apiKey = ApiKeys.openAiApiKey;
  static const String _whisperEndpoint = 'https://api.openai.com/v1/audio/transcriptions';

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;

  VoiceState _state = VoiceState.idle;
  String _transcription = '';
  String? _recordingPath;
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

      await _recorder.openRecorder();
      _isRecorderInitialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> startListening() async {
    try {
      if (!_isRecorderInitialized) {
        throw Exception('Recorder not initialized');
      }

      _setState(VoiceState.listening);
      _transcription = 'Listening...';

      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacMP4,
        bitRate: 128000,
        sampleRate: 16000,
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
      _setState(VoiceState.processing);
      _transcription = 'Processing...';

      await _recorder.stopRecorder();

      if (_recordingPath == null) {
        throw Exception('No recording');
      }

      final file = File(_recordingPath!);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final fileSize = await file.length();
      if (fileSize < 1000) {
        throw Exception('Too short');
      }

      final transcription = await _transcribeWithWhisper(_recordingPath!);

      _transcription = transcription;
      _setState(VoiceState.idle);

      if (onTranscription != null) {
        onTranscription!(transcription);
      }
    } catch (e) {
      _setState(VoiceState.error);
      _transcription = 'Error: $e';

      Future.delayed(Duration(seconds: 3), () {
        if (_state == VoiceState.error) reset();
      });
    }
  }

  Future<String> _transcribeWithWhisper(String audioPath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_whisperEndpoint));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'en';

      request.files.add(await http.MultipartFile.fromPath('file', audioPath, filename: 'audio.m4a'));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        return json['text'] as String;
      } else if (response.statusCode == 400) {
        throw Exception('Bad Request');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API Key');
      } else {
        throw Exception('API Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('$e');
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
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
    }
    super.dispose();
  }
}