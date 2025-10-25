// lib/dialogs/add_investigation_dialog.dart

import 'package:flutter/material.dart';
import '../models/endocrine/investigation_finding.dart';
import '../config/investigation_library.dart';

class AddInvestigationDialog extends StatefulWidget {
  final InvestigationFinding? existingFinding;
  final Function(InvestigationFinding)? onFindingAdded;

  const AddInvestigationDialog({
    super.key,
    this.existingFinding,
    this.onFindingAdded,
  });

  @override
  State<AddInvestigationDialog> createState() => _AddInvestigationDialogState();
}

class _AddInvestigationDialogState extends State<AddInvestigationDialog> {
  final _searchController = TextEditingController();
  final _investigationNameController = TextEditingController();
  final _findingsController = TextEditingController();
  final _impressionController = TextEditingController();
  final _performedByController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedCategory;
  DateTime _performedDate = DateTime.now();
  bool _showSearchResults = false;
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingFinding != null) {
      _loadExistingData();
    }

    _searchController.addListener(_onSearchChanged);
  }

  void _loadExistingData() {
    final finding = widget.existingFinding!;
    _selectedCategory = finding.category;
    _investigationNameController.text = finding.investigationName;
    _findingsController.text = finding.findings;
    _impressionController.text = finding.impression ?? '';
    _performedByController.text = finding.performedBy ?? '';
    _performedDate = finding.performedDate;
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = InvestigationLibrary.searchInvestigations(query);
      _showSearchResults = _searchResults.isNotEmpty;
    });
  }

  void _selectInvestigation(Map<String, String> investigation) {
    setState(() {
      _selectedCategory = investigation['category'];
      _investigationNameController.text = investigation['name']!;
      _searchController.clear();
      _showSearchResults = false;
    });

    // Focus on findings field
    FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.medical_services, color: Colors.teal.shade700, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingFinding == null ? 'Add Investigation' : 'Edit Investigation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Text(
                      'Search Investigation *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Type to search (e.g., Ultrasound, CT Scan)',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _showSearchResults = false);
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),

                    // Search Results
                    if (_showSearchResults) ...[
                      SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final investigation = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.image_search, color: Colors.teal.shade700, size: 20),
                              ),
                              title: Text(
                                investigation['name']!,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                investigation['category']!,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: Icon(Icons.add_circle_outline, color: Colors.teal),
                              onTap: () => _selectInvestigation(investigation),
                            );
                          },
                        ),
                      ),
                    ],

                    SizedBox(height: 24),
                    Divider(),
                    SizedBox(height: 16),

                    // Category Display
                    if (_selectedCategory != null) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category, color: Colors.teal.shade700, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Category: $_selectedCategory',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Investigation Name
                    _buildLabel('Investigation Name *'),
                    TextField(
                      controller: _investigationNameController,
                      decoration: _inputDecoration('Selected investigation'),
                      readOnly: true,
                    ),
                    SizedBox(height: 16),

                    // Performed Date
                    _buildLabel('Performed Date *'),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _performedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _performedDate = date);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.teal.shade700),
                            SizedBox(width: 12),
                            Text(
                              '${_performedDate.day}/${_performedDate.month}/${_performedDate.year}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Findings
                    _buildLabel('Findings *'),
                    TextField(
                      controller: _findingsController,
                      decoration: _inputDecoration('Enter detailed findings'),
                      maxLines: 4,
                    ),
                    SizedBox(height: 16),

                    // Impression
                    _buildLabel('Impression/Diagnosis'),
                    TextField(
                      controller: _impressionController,
                      decoration: _inputDecoration('Enter radiologist impression'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),

                    // Performed By
                    _buildLabel('Performed By'),
                    TextField(
                      controller: _performedByController,
                      decoration: _inputDecoration('Dr. name or facility'),
                    ),
                    SizedBox(height: 16),

                    // Info Box
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.teal.shade700, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Use the search bar to quickly find and auto-fill investigation details',
                              style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveFinding,
                    icon: Icon(Icons.check),
                    label: Text(widget.existingFinding == null ? 'Add Finding' : 'Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _saveFinding() {
    if (_investigationNameController.text.isEmpty ||
        _selectedCategory == null ||
        _findingsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields (marked with *)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final finding = InvestigationFinding(
      category: _selectedCategory!,
      investigationName: _investigationNameController.text,
      performedDate: _performedDate,
      findings: _findingsController.text,
      impression: _impressionController.text.isEmpty ? null : _impressionController.text,
      performedBy: _performedByController.text.isEmpty ? null : _performedByController.text,
    );

    if (widget.onFindingAdded != null) {
      widget.onFindingAdded!(finding);
    }

    if (widget.existingFinding == null) {
      // Ask if want to add more
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Finding Added'),
            ],
          ),
          content: Text('Add another investigation?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('No, Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: Text('Add More'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context, finding);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCategory = null;
      _investigationNameController.clear();
      _findingsController.clear();
      _impressionController.clear();
      _performedByController.clear();
      _searchController.clear();
      _performedDate = DateTime.now();
      _showSearchResults = false;
    });

    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _investigationNameController.dispose();
    _findingsController.dispose();
    _impressionController.dispose();
    _performedByController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}