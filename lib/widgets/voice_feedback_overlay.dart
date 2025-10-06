import 'package:flutter/material.dart';

class VoiceFeedbackOverlay extends StatelessWidget {
  final String message;
  final bool isListening;
  final bool waitingForClick;
  final VoidCallback? onCancel;

  const VoiceFeedbackOverlay({
    super.key,
    required this.message,
    this.isListening = false,
    this.waitingForClick = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty && !isListening && !waitingForClick) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.isNotEmpty ? message : 'Listening...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (waitingForClick && onCancel != null)
                    IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              if (isListening)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (waitingForClick) return const Color(0xFF10B981); // Green
    if (isListening) return const Color(0xFF3B82F6); // Blue
    if (message.contains('not recognized') || message.contains('does not exist')) {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFF6B7280); // Gray
  }

  Widget _buildIcon() {
    if (isListening) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (waitingForClick) {
      return const Icon(Icons.touch_app, color: Colors.white, size: 24);
    }

    if (message.contains('not recognized') || message.contains('does not exist')) {
      return const Icon(Icons.error_outline, color: Colors.white, size: 24);
    }

    return const Icon(Icons.check_circle_outline, color: Colors.white, size: 24);
  }
}