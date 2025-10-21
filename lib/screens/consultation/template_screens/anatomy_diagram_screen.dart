// lib/screens/consultation/template_screens/anatomy_diagram_screen.dart

import 'package:flutter/material.dart';
import '../../../models/consultation_data.dart';

class AnatomyDiagramScreen extends StatelessWidget {
  final AnatomySelection anatomySelection;
  final ConsultationData consultationData;

  const AnatomyDiagramScreen({
    super.key,
    required this.anatomySelection,
    required this.consultationData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${anatomySelection.organSystem} - ${anatomySelection.viewType}'),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '${anatomySelection.organSystem} Diagram',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              anatomySelection.viewType,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This will be your existing kidney diagram screen or similar annotation interface.\n\nIntegrate your existing KidneyScreen here with markers and free drawing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}