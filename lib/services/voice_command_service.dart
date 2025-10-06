import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

enum CommandType {
  navigation,
  zoom,
  placeTool,
  editMarker,
  generateSummary,
  unknown,
}

class VoiceCommand {
  final CommandType type;
  final Map<String, dynamic> parameters;
  final String originalText;

  VoiceCommand({
    required this.type,
    required this.parameters,
    required this.originalText,
  });

  // Get friendly feedback message
  String getFeedbackMessage() {
    switch (type) {
      case CommandType.navigation:
        final preset = parameters['preset'] ?? 'anatomical';
        final presetNames = {
          'anatomical': 'Detailed Anatomy',
          'simple': 'Simple Diagram',
          'crossSection': 'Cross-Section View',
          'nephron': 'Nephron',
          'polycystic': 'Polycystic Kidney Disease',
          'pyelonephritis': 'Pyelonephritis',
          'glomerulonephritis': 'Glomerulonephritis',
        };
        return 'Switching to ${presetNames[preset] ?? preset}';

      case CommandType.zoom:
        final action = parameters['action'];
        if (action == 'in') return 'Zooming in';
        if (action == 'out') return 'Zooming out';
        if (action == 'reset') return 'Resetting view';
        return 'Adjusting zoom';

      case CommandType.placeTool:
        final tool = parameters['toolType'] ?? 'marker';
        final size = parameters['size'];
        if (size != null) {
          return 'Ready to place ${tool.toUpperCase()} (${size}mm) - Tap to place';
        }
        return 'Ready to place ${tool.toUpperCase()} - Tap to place';

      case CommandType.editMarker:
        final number = parameters['markerNumber'];
        final action = parameters['action'];
        if (action == 'delete') return 'Deleting marker $number';
        if (action == 'resize') return 'Selecting marker $number for resize';
        return 'Selecting marker $number';

      case CommandType.generateSummary:
        return 'Generating patient summary...';

      case CommandType.unknown:
        return 'Command not recognized. Try again.';

      default:
        return 'Processing command...';
    }
  }
}

class VoiceCommandService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  // Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      return false;
    }

    // Initialize speech recognition
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    return _isInitialized;
  }

  // Start listening
  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized && !_isListening) {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords.toLowerCase());
            _isListening = false;
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  // Parse voice command
  VoiceCommand parseCommand(String text) {
    text = text.toLowerCase().trim();

    // Navigation commands
    if (_containsAny(text, ['open kidney', 'show kidney', 'load kidney', 'switch to'])) {
      return _parseNavigationCommand(text);
    }

    // Zoom commands
    if (_containsAny(text, ['zoom in', 'zoom out', 'reset view', 'reset zoom'])) {
      return _parseZoomCommand(text);
    }

    // Place marker commands
    if (_containsAny(text, ['place', 'add', 'mark', 'put'])) {
      return _parsePlaceToolCommand(text);
    }

    // Edit marker commands
    if (_containsAny(text, ['delete', 'remove', 'change', 'edit', 'modify', 'select'])) {
      return _parseEditMarkerCommand(text);
    }

    // Generate summary
    if (_containsAny(text, ['generate', 'create summary', 'create report', 'make pdf', 'summary'])) {
      return VoiceCommand(
        type: CommandType.generateSummary,
        parameters: {},
        originalText: text,
      );
    }

    // Unknown command
    return VoiceCommand(
      type: CommandType.unknown,
      parameters: {},
      originalText: text,
    );
  }

  // Parse navigation command
  VoiceCommand _parseNavigationCommand(String text) {
    final presets = {
      'anatomical': ['anatomical', 'detailed', 'anatomy'],
      'simple': ['simple', 'basic'],
      'crossSection': ['cross section', 'cross-section', 'section'],
      'nephron': ['nephron'],
      'polycystic': ['polycystic'],
      'pyelonephritis': ['pyelonephritis', 'pyelo'],
      'glomerulonephritis': ['glomerulonephritis', 'glomero'],
    };

    for (var entry in presets.entries) {
      if (_containsAny(text, entry.value)) {
        return VoiceCommand(
          type: CommandType.navigation,
          parameters: {'preset': entry.key},
          originalText: text,
        );
      }
    }

    // Default to anatomical if no specific preset
    return VoiceCommand(
      type: CommandType.navigation,
      parameters: {'preset': 'anatomical'},
      originalText: text,
    );
  }

  // Parse zoom command
  VoiceCommand _parseZoomCommand(String text) {
    if (text.contains('zoom in') || text.contains('zoomin')) {
      return VoiceCommand(
        type: CommandType.zoom,
        parameters: {'action': 'in'},
        originalText: text,
      );
    } else if (text.contains('zoom out') || text.contains('zoomout')) {
      return VoiceCommand(
        type: CommandType.zoom,
        parameters: {'action': 'out'},
        originalText: text,
      );
    } else if (text.contains('reset')) {
      return VoiceCommand(
        type: CommandType.zoom,
        parameters: {'action': 'reset'},
        originalText: text,
      );
    }

    return VoiceCommand(
      type: CommandType.unknown,
      parameters: {},
      originalText: text,
    );
  }

  // Parse place tool command
  VoiceCommand _parsePlaceToolCommand(String text) {
    // Tool types
    String? toolType;
    if (_containsAny(text, ['calculi', 'calculus', 'stone', 'kidney stone'])) {
      toolType = 'calculi';
    } else if (_containsAny(text, ['cyst'])) {
      toolType = 'cyst';
    } else if (_containsAny(text, ['tumor', 'tumour', 'mass'])) {
      toolType = 'tumor';
    } else if (_containsAny(text, ['inflammation', 'inflamed'])) {
      toolType = 'inflammation';
    } else if (_containsAny(text, ['blockage', 'obstruction', 'block'])) {
      toolType = 'blockage';
    }

    if (toolType == null) {
      return VoiceCommand(
        type: CommandType.unknown,
        parameters: {},
        originalText: text,
      );
    }

    // Extract size (optional)
    double? size;
    final sizeMatch = RegExp(r'(\d+)\s*(mm|millimeter|millimeters)?').firstMatch(text);
    if (sizeMatch != null) {
      size = double.tryParse(sizeMatch.group(1) ?? '');
    }

    // Parse word numbers
    if (size == null) {
      size = _parseWordNumber(text);
    }

    return VoiceCommand(
      type: CommandType.placeTool,
      parameters: {
        'toolType': toolType,
        'size': size,
      },
      originalText: text,
    );
  }

  // Parse edit marker command
  VoiceCommand _parseEditMarkerCommand(String text) {
    // Extract marker number
    int? markerNumber;

    // Try to find "marker X" or "number X"
    final numberMatch = RegExp(r'marker\s+(\d+)|number\s+(\d+)').firstMatch(text);
    if (numberMatch != null) {
      markerNumber = int.tryParse(numberMatch.group(1) ?? numberMatch.group(2) ?? '');
    }

    // Try word numbers (first, second, etc.)
    if (markerNumber == null) {
      final wordNumbers = {
        'first': 1, 'one': 1,
        'second': 2, 'two': 2,
        'third': 3, 'three': 3,
        'fourth': 4, 'four': 4,
        'fifth': 5, 'five': 5,
        'last': -1,
      };

      for (var entry in wordNumbers.entries) {
        if (text.contains(entry.key)) {
          markerNumber = entry.value;
          break;
        }
      }
    }

    if (markerNumber == null) {
      return VoiceCommand(
        type: CommandType.unknown,
        parameters: {},
        originalText: text,
      );
    }

    // Determine action
    String action;
    if (_containsAny(text, ['delete', 'remove'])) {
      action = 'delete';
    } else if (_containsAny(text, ['change size', 'resize', 'make larger', 'make smaller'])) {
      action = 'resize';
    } else if (_containsAny(text, ['edit', 'modify', 'change'])) {
      action = 'edit';
    } else {
      action = 'select';
    }

    return VoiceCommand(
      type: CommandType.editMarker,
      parameters: {
        'markerNumber': markerNumber,
        'action': action,
      },
      originalText: text,
    );
  }

  // Helper: Check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // Helper: Parse word numbers to double
  double? _parseWordNumber(String text) {
    final wordNumbers = {
      'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0,
      'six': 6.0, 'seven': 7.0, 'eight': 8.0, 'nine': 9.0, 'ten': 10.0,
      'fifteen': 15.0, 'twenty': 20.0, 'thirty': 30.0,
    };

    for (var entry in wordNumbers.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  // Dispose
  Future<void> dispose() async {
    await stopListening();
  }
}