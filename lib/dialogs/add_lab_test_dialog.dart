// lib/dialogs/add_lab_test_dialog.dart
// FIXED VERSION - Proper spacing and layout, no overlapping elements

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/endocrine/lab_test_result.dart';
import '../config/lab_test_library.dart';

class AddLabTestDialog extends StatefulWidget {
  final LabTestResult? existingResult;
  final Function(LabTestResult)? onResultAdded;

  const AddLabTestDialog({
    Key? key,
    this.existingResult,
    this.onResultAdded,
  }) : super(key: key);

  @override
  State<AddLabTestDialog> createState() => _AddLabTestDialogState();
}

class _AddLabTestDialogState extends State<AddLabTestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _reportedByController = TextEditingController();
  final _searchController = TextEditingController();

  String? _selectedCategory;
  String? _selectedTestName;
  Map<String, dynamic>? _selectedTestDetails;
  DateTime _testDate = DateTime.now();

  // For custom entry
  final _customTestNameController = TextEditingController();
  final _customUnitController = TextEditingController();
  final _customMinController = TextEditingController();
  final _customMaxController = TextEditingController();
  bool _isCustomEntry = false;

  // Search functionality
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.existingResult != null) {
      final existingResult = widget.existingResult!;

      _selectedCategory = LabTestLibrary.getCategoryForTest(existingResult.testName);

      if (_selectedCategory != null) {
        _selectedTestName = existingResult.testName;
        _selectedTestDetails = LabTestLibrary.getTestDetails(_selectedCategory!, existingResult.testName);
      }

      if (_selectedTestDetails == null) {
        _isCustomEntry = true;
        _customTestNameController.text = existingResult.testName;
        _customUnitController.text = existingResult.unit;
        _customMinController.text = existingResult.normalMin.toString();
        _customMaxController.text = existingResult.normalMax.toString();
        _selectedCategory = existingResult.category.isNotEmpty
            ? existingResult.category
            : LabTestLibrary.categories.first;
      }

      _valueController.text = existingResult.value.toString();
      _notesController.text = existingResult.notes ?? '';
      _reportedByController.text = existingResult.reportedBy ?? '';
      _testDate = existingResult.testDate;
    }
  }

  List<String> get availableTestNames {
    if (_selectedCategory == null) return [];
    return LabTestLibrary.getTestsForCategory(_selectedCategory!);
  }

  void _onTestSelected(String? testName) {
    setState(() {
      _selectedTestName = testName;
      if (testName != null && _selectedCategory != null) {
        _selectedTestDetails = LabTestLibrary.getTestDetails(_selectedCategory!, testName);
        if (_selectedTestDetails != null) {
          _customUnitController.text = _selectedTestDetails!['unit'] ?? '';
          _customMinController.text = (_selectedTestDetails!['min'] ?? '').toString();
          _customMaxController.text = (_selectedTestDetails!['max'] ?? '').toString();
        }
      } else {
        _selectedTestDetails = null;
      }
    });
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
      _searchResults = LabTestLibrary.searchTests(query);
      _showSearchResults = _searchResults.isNotEmpty;
    });
  }

  void _selectTestFromSearch(Map<String, dynamic> test) {
    setState(() {
      _selectedCategory = test['category'];
      _selectedTestName = test['name'];
      _selectedTestDetails = test;
      _customUnitController.text = test['unit'] ?? '';
      _customMinController.text = (test['min'] ?? '').toString();
      _customMaxController.text = (test['max'] ?? '').toString();
      _searchController.clear();
      _showSearchResults = false;
      _isCustomEntry = false;
    });

    FocusScope.of(context).nextFocus();
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = screenHeight * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: dialogHeight,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existingResult == null ? 'Add Lab Test Result' : 'Edit Lab Test Result',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${LabTestLibrary.totalTestCount} Tests',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Info banner

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tests (e.g., TSH, Glucose, HbA1c)...',
                      prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                  if (_showSearchResults) ...[
                    const SizedBox(height: 8),
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
                          final test = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.biotech, color: Colors.blue.shade700, size: 20),
                            ),
                            title: Text(
                              test['name'],
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              test['category'] + ' • ' + test['unit'] + ' • Range: ' + test['min'].toString() + '-' + test['max'].toString(),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Icon(Icons.add_circle_outline, color: Colors.blue),
                            onTap: () => _selectTestFromSearch(test),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search above or choose from ${LabTestLibrary.categories.length} categories with ${LabTestLibrary.totalTestCount} tests',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form - Fixed spacing
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24), // Increased padding
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Dropdown - Fixed height and spacing
                      SizedBox(
                        height: 80, // Fixed height to prevent overlap
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Test Category *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.category),
                            helperText: 'Select from ${LabTestLibrary.categories.length} categories',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: LabTestLibrary.categories.map((category) {
                            final testCount = LabTestLibrary.getTestCountForCategory(category);
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$testCount tests',
                                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _selectedTestName = null;
                              _selectedTestDetails = null;
                              _isCustomEntry = false;
                              _customTestNameController.clear();
                              _customUnitController.clear();
                              _customMinController.clear();
                              _customMaxController.clear();
                            });
                          },
                          validator: (value) => value == null ? 'Please select a category' : null,
                          menuMaxHeight: 300,
                        ),
                      ),
                      const SizedBox(height: 24), // Increased spacing

                      // Test Selection Row - Fixed layout
                      if (_selectedCategory != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Test Dropdown - Fixed width
                            Expanded(
                              child: SizedBox(
                                height: 80, // Fixed height
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTestName,
                                  decoration: const InputDecoration(
                                    labelText: 'Test Name *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.assignment),
                                    helperText: 'Select from test library',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  items: availableTestNames.map((testName) {
                                    final testDetails = LabTestLibrary.getTestDetails(_selectedCategory!, testName);
                                    return DropdownMenuItem(
                                      value: testName,
                                      child: Container(
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    testName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (testDetails != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade100,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      testDetails['unit'] ?? '',
                                                      style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (testDetails != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                testDetails['fullName'] ?? testName,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isCustomEntry ? null : _onTestSelected,
                                  validator: !_isCustomEntry
                                      ? (value) => value == null ? 'Please select a test' : null
                                      : null,
                                  isExpanded: true,
                                  menuMaxHeight: 400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16), // Consistent spacing
                            // Custom Entry Toggle - Fixed size
                            Container(
                              width: 80,
                              height: 60, // Reduced height to match
                              decoration: BoxDecoration(
                                border: Border.all(color: _isCustomEntry ? Colors.orange : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: _isCustomEntry ? Colors.orange.shade50 : Colors.grey.shade50,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isCustomEntry = !_isCustomEntry;
                                    if (_isCustomEntry) {
                                      _selectedTestName = null;
                                      _selectedTestDetails = null;
                                    } else {
                                      _customTestNameController.clear();
                                      _customUnitController.clear();
                                      _customMinController.clear();
                                      _customMaxController.clear();
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isCustomEntry ? Icons.edit : Icons.add_circle_outline,
                                      color: _isCustomEntry ? Colors.orange.shade700 : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _isCustomEntry ? Colors.orange.shade700 : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Custom Entry Field
                        if (_isCustomEntry) ...[
                          TextFormField(
                            controller: _customTestNameController,
                            decoration: const InputDecoration(
                              labelText: 'Custom Test Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.science),
                              helperText: 'Enter test name not in our library',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => value == null || value.isEmpty ? 'Please enter test name' : null,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Test Details Card - Fixed spacing
                        if (_selectedTestDetails != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedTestDetails!['fullName'] ?? _selectedTestDetails!['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedTestDetails!['description'] ?? 'Lab test',
                                            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.straighten, size: 16, color: Colors.blue.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Unit: ${_selectedTestDetails!['unit']}',
                                      style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.bar_chart, size: 16, color: Colors.green.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Range: ${_selectedTestDetails!['min']}-${_selectedTestDetails!['max']}',
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Value and Unit Row - Fixed spacing
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _valueController,
                                decoration: const InputDecoration(
                                  labelText: 'Test Value *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.looks_one),
                                  helperText: 'Numeric result',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _customUnitController,
                                decoration: InputDecoration(
                                  labelText: 'Unit *',
                                  border: const OutlineInputBorder(),
                                  helperText: _selectedTestDetails != null ? 'From library' : 'e.g., mg/dL',
                                  filled: _selectedTestDetails != null,
                                  fillColor: _selectedTestDetails != null ? Colors.grey.shade100 : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                readOnly: _selectedTestDetails != null,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Normal Range Row - Fixed spacing
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customMinController,
                                decoration: InputDecoration(
                                  labelText: 'Normal Min *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.arrow_downward),
                                  filled: _selectedTestDetails != null,
                                  fillColor: _selectedTestDetails != null ? Colors.grey.shade100 : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                readOnly: _selectedTestDetails != null,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _customMaxController,
                                decoration: InputDecoration(
                                  labelText: 'Normal Max *',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.arrow_upward),
                                  filled: _selectedTestDetails != null,
                                  fillColor: _selectedTestDetails != null ? Colors.grey.shade100 : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                                readOnly: _selectedTestDetails != null,
                                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Test Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _testDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _testDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Test Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text('${_testDate.day}/${_testDate.month}/${_testDate.year}'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reported By
                      TextFormField(
                        controller: _reportedByController,
                        decoration: const InputDecoration(
                          labelText: 'Reported By (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Lab name or technician',
                          prefixIcon: Icon(Icons.person),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                          helperText: 'Additional observations',
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32), // Extra space at bottom
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (MediaQuery.of(context).size.height < 700)
                    Row(
                      children: [
                        Icon(Icons.swipe_vertical, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Scroll to see all fields', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )
                  else
                    const SizedBox.shrink(),

                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final testName = _isCustomEntry
                                ? _customTestNameController.text
                                : _selectedTestName!;

                            final categoryName = _selectedCategory!;

                            final result = LabTestResult(
                              id: widget.existingResult?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              testName: testName,
                              category: categoryName,
                              value: double.parse(_valueController.text),
                              unit: _customUnitController.text,
                              normalMin: double.parse(_customMinController.text),
                              normalMax: double.parse(_customMaxController.text),
                              testDate: _testDate,
                              notes: _notesController.text.isEmpty ? null : _notesController.text,
                              reportedBy: _reportedByController.text.isEmpty ? null : _reportedByController.text,
                            );

                            if (widget.existingResult != null) {
                              Navigator.pop(context, result);
                              return;
                            }

                            final shouldAddMore = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                                      child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(child: Text('Test Result Added!')),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Test: $testName', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('Category: $categoryName', style: TextStyle(color: Colors.grey.shade700)),
                                    SizedBox(height: 4),
                                    Text('Value: ${_valueController.text} ${_customUnitController.text}', style: TextStyle(color: Colors.grey.shade700)),
                                    SizedBox(height: 4),
                                    Text('Status: ${result.status.toUpperCase()}', style: TextStyle(color: result.isAbnormal ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 16),
                                    Text('Would you like to add another test result?'),
                                  ],
                                ),
                                actions: [
                                  TextButton.icon(
                                    onPressed: () => Navigator.pop(context, false),
                                    icon: Icon(Icons.close, size: 18),
                                    label: Text('Close'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.pop(context, true),
                                    icon: Icon(Icons.add_circle_outline, size: 18),
                                    label: Text('Add More'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                                  ),
                                ],
                              ),
                            );

                            if (widget.onResultAdded != null) {
                              widget.onResultAdded!(result);
                            }

                            if (shouldAddMore == true) {
                              setState(() {
                                _selectedTestName = null;
                                _selectedTestDetails = null;
                                _valueController.clear();
                                _notesController.clear();
                                _reportedByController.clear();
                                _testDate = DateTime.now();

                                if (_isCustomEntry) {
                                  _customTestNameController.clear();
                                  _customUnitController.clear();
                                  _customMinController.clear();
                                  _customMaxController.clear();
                                }
                              });

                              _scrollController.animateTo(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 8), Text('Ready to add another test result')]),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } else {
                              Navigator.pop(context, true);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(children: [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 8), Expanded(child: Text('Please fill all required fields (marked with *)'))]),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        child: Text(widget.existingResult == null ? 'Add Result' : 'Update Result'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    _reportedByController.dispose();
    _customTestNameController.dispose();
    _customUnitController.dispose();
    _customMinController.dispose();
    _customMaxController.dispose();
    super.dispose();
  }
}