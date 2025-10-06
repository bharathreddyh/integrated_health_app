import 'package:flutter/material.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  dateDesc,
  dateAsc,
  ageAsc,
  ageDesc,
}

class PatientFilterWidget extends StatefulWidget {
  final Set<String> selectedConditions;
  final SortOption sortOption;
  final DateTimeRange? dateRange;
  final Function(Set<String>) onConditionsChanged;
  final Function(SortOption) onSortChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onClearFilters;

  const PatientFilterWidget({
    super.key,
    required this.selectedConditions,
    required this.sortOption,
    required this.dateRange,
    required this.onConditionsChanged,
    required this.onSortChanged,
    required this.onDateRangeChanged,
    required this.onClearFilters,
  });

  @override
  State<PatientFilterWidget> createState() => _PatientFilterWidgetState();
}

class _PatientFilterWidgetState extends State<PatientFilterWidget> {
  final List<String> _allConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Arthritis',
    'GERD',
    'Migraine',
    'Depression',
    'Anxiety',
    'Thyroid Disorder',
    'Heart Disease',
    'Kidney Disease',
    'Chronic Pain',
  ];

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = widget.selectedConditions.isNotEmpty ||
        widget.dateRange != null ||
        widget.sortOption != SortOption.dateDesc;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Filters & Sort',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasActiveFilters)
                  TextButton(
                    onPressed: widget.onClearFilters,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Options
                  _buildSectionTitle('Sort By'),
                  const SizedBox(height: 8),
                  _buildSortOption('Most Recent', SortOption.dateDesc),
                  _buildSortOption('Oldest First', SortOption.dateAsc),
                  _buildSortOption('Name (A-Z)', SortOption.nameAsc),
                  _buildSortOption('Name (Z-A)', SortOption.nameDesc),
                  _buildSortOption('Age (Low-High)', SortOption.ageAsc),
                  _buildSortOption('Age (High-Low)', SortOption.ageDesc),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date Range
                  _buildSectionTitle('Date Range'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      widget.dateRange == null
                          ? 'Select Date Range'
                          : '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (widget.dateRange != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => widget.onDateRangeChanged(null),
                      icon: const Icon(Icons.clear, size: 14),
                      label: const Text('Clear Date Filter', style: TextStyle(fontSize: 12)),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Conditions Filter
                  _buildSectionTitle('Filter by Condition'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allConditions.map((condition) {
                      final isSelected = widget.selectedConditions.contains(condition);
                      return FilterChip(
                        label: Text(condition, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          final newConditions = Set<String>.from(widget.selectedConditions);
                          if (selected) {
                            newConditions.add(condition);
                          } else {
                            newConditions.remove(condition);
                          }
                          widget.onConditionsChanged(newConditions);
                        },
                        selectedColor: const Color(0xFFDCEAFE),
                        checkmarkColor: const Color(0xFF1E40AF),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Quick Filters
                  _buildSectionTitle('Quick Filters'),
                  const SizedBox(height: 8),
                  _buildQuickFilter(
                    'Today',
                    Icons.today,
                        () => _setQuickDateFilter(0),
                  ),
                  _buildQuickFilter(
                    'This Week',
                    Icons.view_week,
                        () => _setQuickDateFilter(7),
                  ),
                  _buildQuickFilter(
                    'This Month',
                    Icons.calendar_month,
                        () => _setQuickDateFilter(30),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSortOption(String label, SortOption option) {
    final isSelected = widget.sortOption == option;
    return RadioListTile<SortOption>(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      value: option,
      groupValue: widget.sortOption,
      onChanged: (value) {
        if (value != null) {
          widget.onSortChanged(value);
        }
      },
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF3B82F6),
    );
  }

  Widget _buildQuickFilter(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.blue.shade700),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.dateRange,
    );
    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }

  void _setQuickDateFilter(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    widget.onDateRangeChanged(DateTimeRange(start: start, end: end));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}