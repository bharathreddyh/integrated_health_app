import 'package:flutter/material.dart';
import '../models/disease_template.dart';

class DiseaseTemplateDialog extends StatefulWidget {
  final DiseaseTemplate template;
  final Map<String, dynamic>? existingData;  // For editing existing templates

  const DiseaseTemplateDialog({
    Key? key,
    required this.template,
    this.existingData,
  }) : super(key: key);

  @override
  State<DiseaseTemplateDialog> createState() => _DiseaseTemplateDialogState();
}

class _DiseaseTemplateDialogState extends State<DiseaseTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers for lab tests
    for (final test in widget.template.requiredLabTests) {
      final controller = TextEditingController();

      // If editing, load existing values
      if (widget.existingData != null) {
        final existingValue = widget.existingData!['data']?[test];
        if (existingValue != null) {
          controller.text = existingValue.toString();
        }
      }

      _controllers[test] = controller;
      _focusNodes[test] = FocusNode();
    }

    // Initialize controllers for additional fields
    _controllers['findings'] = TextEditingController(
      text: widget.existingData?['data']?['findings'] ?? '',
    );
    _controllers['diagnosis'] = TextEditingController(
      text: widget.existingData?['data']?['diagnosis'] ?? '',
    );
    _controllers['notes'] = TextEditingController(
      text: widget.existingData?['data']?['notes'] ?? '',
    );

    _focusNodes['findings'] = FocusNode();
    _focusNodes['diagnosis'] = FocusNode();
    _focusNodes['notes'] = FocusNode();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate()) {
      // Collect all data
      final data = <String, dynamic>{};

      // Add lab test values
      for (final entry in _controllers.entries) {
        if (entry.value.text.isNotEmpty) {
          data[entry.key] = entry.value.text;
        }
      }

      // Create the template result
      final result = {
        'templateId': widget.template.id,
        'templateName': widget.template.name,
        'data': data,
        'createdAt': widget.existingData?['createdAt'] ??
            DateTime.now().toIso8601String(),
      };

      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple.shade700,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.medical_information,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.existingData != null
                              ? 'Edit template data'
                              : 'Fill in the template data',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lab Tests Section
                      if (widget.template.requiredLabTests.isNotEmpty) ...[
                        _buildSectionHeader(
                          'Required Lab Tests',
                          Icons.science,
                          Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildLabTestsGrid(),
                        const SizedBox(height: 24),
                      ],

                      // Clinical Findings Section
                      _buildSectionHeader(
                        'Clinical Findings',
                        Icons.assessment,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['findings']!,
                        focusNode: _focusNodes['findings']!,
                        label: 'Findings',
                        hint: 'Describe clinical findings...',
                        maxLines: 4,
                        required: false,
                      ),
                      const SizedBox(height: 24),

                      // Diagnosis Section
                      _buildSectionHeader(
                        'Diagnosis',
                        Icons.local_hospital,
                        Colors.red,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['diagnosis']!,
                        focusNode: _focusNodes['diagnosis']!,
                        label: 'Diagnosis',
                        hint: 'Enter diagnosis...',
                        maxLines: 2,
                        required: false,
                      ),
                      const SizedBox(height: 24),

                      // Additional Notes Section
                      _buildSectionHeader(
                        'Additional Notes',
                        Icons.note,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _controllers['notes']!,
                        focusNode: _focusNodes['notes']!,
                        label: 'Notes',
                        hint: 'Any additional observations...',
                        maxLines: 4,
                        required: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveTemplate,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(widget.existingData != null ? 'Update' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildLabTestsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3,
      ),
      itemCount: widget.template.requiredLabTests.length,
      itemBuilder: (context, index) {
        final testName = widget.template.requiredLabTests[index];
        return _buildLabTestField(testName);
      },
    );
  }

  Widget _buildLabTestField(String testName) {
    return TextFormField(
      controller: _controllers[testName],
      focusNode: _focusNodes[testName],
      decoration: InputDecoration(
        labelText: testName,
        hintText: 'Enter value',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.purple.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator: (value) {
        // Optional validation - you can make it required if needed
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }
          : null,
    );
  }
}
