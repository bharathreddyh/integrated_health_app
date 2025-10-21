// lib/screens/consultation/template_screens/disease_template_screen.dart

import 'package:flutter/material.dart';
import '../../../models/disease_template.dart';
import '../../../models/consultation_data.dart';

class DiseaseTemplateScreen extends StatefulWidget {
  final DiseaseTemplate template;
  final ConsultationData consultationData;

  const DiseaseTemplateScreen({
    super.key,
    required this.template,
    required this.consultationData,
  });

  @override
  State<DiseaseTemplateScreen> createState() => _DiseaseTemplateScreenState();
}

class _DiseaseTemplateScreenState extends State<DiseaseTemplateScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _selectedDiagrams = {};
  bool _canAddAnatomyDiagram = true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _autoFillFromLabResults();
  }

  void _loadExistingData() {
    final templateData = widget.consultationData.getTemplateData(widget.template.id);

    if (templateData != null) {
      _selectedDiagrams.addAll(templateData.selectedDiagramIds);

      for (var field in widget.template.dataFields) {
        final controller = TextEditingController(
          text: templateData.fieldValues[field.id] ?? '',
        );
        _controllers[field.id] = controller;
      }
    } else {
      for (var field in widget.template.dataFields) {
        _controllers[field.id] = TextEditingController();
      }
    }
  }

  void _autoFillFromLabResults() {
    for (var field in widget.template.dataFields) {
      if (field.autoFillFromLab != null) {
        final labResult = widget.consultationData.getLabResultByName(field.autoFillFromLab!);
        if (labResult != null && _controllers[field.id]!.text.isEmpty) {
          _controllers[field.id]!.text = '${labResult.value} ${labResult.unit}';
        }
      }
    }
  }

  void _saveData() {
    final fieldValues = <String, String>{};
    _controllers.forEach((key, controller) {
      fieldValues[key] = controller.text;
    });

    widget.consultationData.updateTemplateData(
      widget.template.id,
      fieldValues,
      _selectedDiagrams.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveData();
              Navigator.pop(context);
            },
            tooltip: 'Save & Return',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient-Friendly Diagrams Section
            _buildDiagramsSection(),
            const SizedBox(height: 24),

            // Clinical Data Fields Section
            _buildClinicalDataSection(),
            const SizedBox(height: 24),

            // Add Anatomical Diagram Button
            if (_canAddAnatomyDiagram)
              _buildAddAnatomyButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDiagramsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Patient-Friendly Diagrams',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select diagrams to include in patient explanation',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...widget.template.diagrams.map((diagram) {
              final isSelected = _selectedDiagrams.contains(diagram.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value!) {
                      _selectedDiagrams.add(diagram.id);
                    } else {
                      _selectedDiagrams.remove(diagram.id);
                    }
                  });
                },
                title: Text(diagram.title),
                subtitle: Text(diagram.description),
                secondary: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, color: Colors.purple.shade700),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalDataSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Clinical Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  'Auto-filled from lab results',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.template.dataFields.map((field) {
              return _buildDataField(field);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataField(TemplateDataField field) {
    final controller = _controllers[field.id]!;
    final labResult = field.autoFillFromLab != null
        ? widget.consultationData.getLabResultByName(field.autoFillFromLab!)
        : null;
    final isAbnormal = labResult?.isAbnormal ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (field.autoFillFromLab != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade700),
              ],
              if (isAbnormal) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    'ABNORMAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: field.unit != null ? 'Enter ${field.label} (${field.unit})' : 'Enter ${field.label}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: isAbnormal ? Colors.red.shade50 : Colors.grey.shade50,
              suffixText: field.unit,
            ),
            keyboardType: field.fieldType == 'number'
                ? TextInputType.number
                : TextInputType.text,
            onChanged: (value) => _saveData(),
          ),
          if (labResult != null && labResult.normalRangeMin != null) ...[
            const SizedBox(height: 4),
            Text(
              'Normal range: ${labResult.normalRangeMin} - ${labResult.normalRangeMax} ${labResult.unit}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddAnatomyButton() {
    return OutlinedButton.icon(
      onPressed: () {
        // TODO: Navigate to anatomy diagram selection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add anatomical diagram feature coming soon')),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Add Detailed Anatomical Diagram'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.purple.shade300),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedDiagrams.length} diagrams selected',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${_controllers.values.where((c) => c.text.isNotEmpty).length}/${_controllers.length} fields filled',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _saveData();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }
}