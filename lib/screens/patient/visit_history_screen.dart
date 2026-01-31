import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../models/disease_template.dart';
import '../../models/patient.dart';

class VisitHistoryScreen extends StatefulWidget {
  final Patient patient;
  const VisitHistoryScreen({super.key, required this.patient});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late Future<List<DiseaseTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    setState(() {
      _templatesFuture = DatabaseHelper.instance.getAllDiseaseTemplates();
    });
  }

  void _openTemplate(DiseaseTemplate template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template: ${template.name}')),
    );
  }

  void _createNewTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template editor coming soon')),
    );
  }

  void _deleteTemplate(DiseaseTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && template.id != null) {
      try {
        await DatabaseHelper.instance.deleteDiseaseTemplate(template.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTemplates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting template: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Disease Templates'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTemplate,
            tooltip: 'Create New Template',
          ),
        ],
      ),
      body: FutureBuilder<List<DiseaseTemplate>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTemplates,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 80,
                      color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No Templates Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first disease template',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _createNewTemplate,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadTemplates(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _openTemplate(template),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template.name.isNotEmpty
                                          ? template.name
                                          : '(Untitled)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (template.category.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        template.category,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteTemplate(template);
                                  } else if (value == 'edit') {
                                    _openTemplate(template);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 18,
                                            color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (template.details.isNotEmpty) ...[
                            const Divider(height: 24),
                            Text(
                              '${template.details.length} field(s) configured',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
    );
  }
}