// lib/models/enhanced_disease_template.dart
// Enhanced Disease Template with Auto-Suggestion Rules

import 'package:flutter/foundation.dart';

/// Enhanced Disease Template with intelligent auto-suggestion rules
class EnhancedDiseaseTemplate {
  final String id;
  final String name;
  final String category; // e.g., "Diabetes", "Hypertension", "Thyroid"
  final String description;

  // Clinical Protocol Configuration
  final FollowUpProtocol followUpProtocol;
  final List<InvestigationProtocol> investigationProtocols;
  final List<String> criticalCheckpoints; // Things doctor must check
  final Map<String, String> protocolGuidelines; // Key metrics to display

  // AI/Rules Engine Configuration
  final bool aiEnabled;
  final String? customPromptTemplate;

  // Treatment Templates
  final List<String> commonMedications;
  final List<String> lifestyleAdvice;
  final String followUpPlanTemplate;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const EnhancedDiseaseTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.followUpProtocol,
    required this.investigationProtocols,
    this.criticalCheckpoints = const [],
    this.protocolGuidelines = const {},
    this.aiEnabled = true,
    this.customPromptTemplate,
    this.commonMedications = const [],
    this.lifestyleAdvice = const [],
    required this.followUpPlanTemplate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'followUpProtocol': followUpProtocol.toJson(),
    'investigationProtocols': investigationProtocols.map((p) => p.toJson()).toList(),
    'criticalCheckpoints': criticalCheckpoints,
    'protocolGuidelines': protocolGuidelines,
    'aiEnabled': aiEnabled,
    'customPromptTemplate': customPromptTemplate,
    'commonMedications': commonMedications,
    'lifestyleAdvice': lifestyleAdvice,
    'followUpPlanTemplate': followUpPlanTemplate,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'createdBy': createdBy,
  };

  factory EnhancedDiseaseTemplate.fromJson(Map<String, dynamic> json) {
    return EnhancedDiseaseTemplate(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      followUpProtocol: FollowUpProtocol.fromJson(json['followUpProtocol']),
      investigationProtocols: (json['investigationProtocols'] as List)
          .map((p) => InvestigationProtocol.fromJson(p))
          .toList(),
      criticalCheckpoints: List<String>.from(json['criticalCheckpoints'] ?? []),
      protocolGuidelines: Map<String, String>.from(json['protocolGuidelines'] ?? {}),
      aiEnabled: json['aiEnabled'] ?? true,
      customPromptTemplate: json['customPromptTemplate'],
      commonMedications: List<String>.from(json['commonMedications'] ?? []),
      lifestyleAdvice: List<String>.from(json['lifestyleAdvice'] ?? []),
      followUpPlanTemplate: json['followUpPlanTemplate'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdBy: json['createdBy'],
    );
  }
}

/// Follow-up visit scheduling protocol
class FollowUpProtocol {
  final int defaultIntervalDays; // Default follow-up interval
  final int minIntervalDays; // Minimum safe interval
  final int maxIntervalDays; // Maximum recommended interval

  // Conditional rules for adjusting intervals
  final List<IntervalAdjustmentRule> adjustmentRules;

  // Rationale templates
  final String defaultRationale;
  final Map<String, String> conditionalRationales; // condition -> rationale

  const FollowUpProtocol({
    required this.defaultIntervalDays,
    required this.minIntervalDays,
    required this.maxIntervalDays,
    this.adjustmentRules = const [],
    required this.defaultRationale,
    this.conditionalRationales = const {},
  });

  Map<String, dynamic> toJson() => {
    'defaultIntervalDays': defaultIntervalDays,
    'minIntervalDays': minIntervalDays,
    'maxIntervalDays': maxIntervalDays,
    'adjustmentRules': adjustmentRules.map((r) => r.toJson()).toList(),
    'defaultRationale': defaultRationale,
    'conditionalRationales': conditionalRationales,
  };

  factory FollowUpProtocol.fromJson(Map<String, dynamic> json) {
    return FollowUpProtocol(
      defaultIntervalDays: json['defaultIntervalDays'],
      minIntervalDays: json['minIntervalDays'],
      maxIntervalDays: json['maxIntervalDays'],
      adjustmentRules: (json['adjustmentRules'] as List?)
          ?.map((r) => IntervalAdjustmentRule.fromJson(r))
          .toList() ?? [],
      defaultRationale: json['defaultRationale'],
      conditionalRationales: Map<String, String>.from(
          json['conditionalRationales'] ?? {}
      ),
    );
  }
}

/// Rules for adjusting follow-up intervals based on conditions
class IntervalAdjustmentRule {
  final String condition; // e.g., "uncontrolled", "new_diagnosis", "stable"
  final int adjustmentDays; // +/- days to adjust
  final String rationale;

  // Condition evaluation
  final RuleConditionType conditionType;
  final String? vitalParameter; // e.g., "blood_sugar", "blood_pressure"
  final double? thresholdValue;
  final String? comparisonOperator; // ">", "<", ">=", "<=", "=="

  const IntervalAdjustmentRule({
    required this.condition,
    required this.adjustmentDays,
    required this.rationale,
    required this.conditionType,
    this.vitalParameter,
    this.thresholdValue,
    this.comparisonOperator,
  });

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'adjustmentDays': adjustmentDays,
    'rationale': rationale,
    'conditionType': conditionType.name,
    'vitalParameter': vitalParameter,
    'thresholdValue': thresholdValue,
    'comparisonOperator': comparisonOperator,
  };

  factory IntervalAdjustmentRule.fromJson(Map<String, dynamic> json) {
    return IntervalAdjustmentRule(
      condition: json['condition'],
      adjustmentDays: json['adjustmentDays'],
      rationale: json['rationale'],
      conditionType: RuleConditionType.values.byName(json['conditionType']),
      vitalParameter: json['vitalParameter'],
      thresholdValue: json['thresholdValue']?.toDouble(),
      comparisonOperator: json['comparisonOperator'],
    );
  }
}

enum RuleConditionType {
  isInitialVisit,
  vitalOutOfRange,
  investigationOverdue,
  customCondition,
  patientAge,
  daysSinceLastVisit,
}

/// Investigation/Test scheduling protocol
class InvestigationProtocol {
  final String investigationName;
  final String code; // Lab test code
  final int recommendedFrequencyDays; // How often should this be done
  final bool isMandatory; // Must be done at every visit
  final bool isUrgentIfOverdue; // Mark as urgent if overdue

  // Conditional rules
  final List<InvestigationCondition> conditions;
  final String defaultRationale;
  final Map<String, String> conditionalRationales;

  const InvestigationProtocol({
    required this.investigationName,
    required this.code,
    required this.recommendedFrequencyDays,
    this.isMandatory = false,
    this.isUrgentIfOverdue = false,
    this.conditions = const [],
    required this.defaultRationale,
    this.conditionalRationales = const {},
  });

  Map<String, dynamic> toJson() => {
    'investigationName': investigationName,
    'code': code,
    'recommendedFrequencyDays': recommendedFrequencyDays,
    'isMandatory': isMandatory,
    'isUrgentIfOverdue': isUrgentIfOverdue,
    'conditions': conditions.map((c) => c.toJson()).toList(),
    'defaultRationale': defaultRationale,
    'conditionalRationales': conditionalRationales,
  };

  factory InvestigationProtocol.fromJson(Map<String, dynamic> json) {
    return InvestigationProtocol(
      investigationName: json['investigationName'],
      code: json['code'],
      recommendedFrequencyDays: json['recommendedFrequencyDays'],
      isMandatory: json['isMandatory'] ?? false,
      isUrgentIfOverdue: json['isUrgentIfOverdue'] ?? false,
      conditions: (json['conditions'] as List?)
          ?.map((c) => InvestigationCondition.fromJson(c))
          .toList() ?? [],
      defaultRationale: json['defaultRationale'],
      conditionalRationales: Map<String, String>.from(
          json['conditionalRationales'] ?? {}
      ),
    );
  }
}

/// Conditions that trigger investigation recommendations
class InvestigationCondition {
  final String condition;
  final bool required; // Must be done if condition is true
  final String? vitalParameter;
  final double? thresholdValue;
  final String? comparisonOperator;

  const InvestigationCondition({
    required this.condition,
    this.required = false,
    this.vitalParameter,
    this.thresholdValue,
    this.comparisonOperator,
  });

  Map<String, dynamic> toJson() => {
    'condition': condition,
    'required': required,
    'vitalParameter': vitalParameter,
    'thresholdValue': thresholdValue,
    'comparisonOperator': comparisonOperator,
  };

  factory InvestigationCondition.fromJson(Map<String, dynamic> json) {
    return InvestigationCondition(
      condition: json['condition'],
      required: json['required'] ?? false,
      vitalParameter: json['vitalParameter'],
      thresholdValue: json['thresholdValue']?.toDouble(),
      comparisonOperator: json['comparisonOperator'],
    );
  }
}

/// Patient context for generating suggestions
class PatientContext {
  final String patientId;
  final int age;
  final String gender;

  // Current visit data
  final Map<String, double> currentVitals; // e.g., {"blood_sugar": 180.0}
  final List<String> currentComplaints;
  final List<String> currentMedications;

  // Historical data
  final DateTime? lastVisitDate;
  final Map<String, DateTime> lastInvestigations; // investigation -> last date
  final Map<String, double> lastVitals;
  final List<String> chronicConditions;

  // Clinical state
  final bool isNewDiagnosis;
  final bool hasComplications;
  final String controlStatus; // "controlled", "uncontrolled", "borderline"

  const PatientContext({
    required this.patientId,
    required this.age,
    required this.gender,
    this.currentVitals = const {},
    this.currentComplaints = const [],
    this.currentMedications = const [],
    this.lastVisitDate,
    this.lastInvestigations = const {},
    this.lastVitals = const {},
    this.chronicConditions = const [],
    this.isNewDiagnosis = false,
    this.hasComplications = false,
    this.controlStatus = "unknown",
  });

  int? get daysSinceLastVisit {
    if (lastVisitDate == null) return null;
    return DateTime.now().difference(lastVisitDate!).inDays;
  }

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'age': age,
    'gender': gender,
    'currentVitals': currentVitals,
    'currentComplaints': currentComplaints,
    'currentMedications': currentMedications,
    'lastVisitDate': lastVisitDate?.toIso8601String(),
    'lastInvestigations': lastInvestigations.map(
            (k, v) => MapEntry(k, v.toIso8601String())
    ),
    'lastVitals': lastVitals,
    'chronicConditions': chronicConditions,
    'isNewDiagnosis': isNewDiagnosis,
    'hasComplications': hasComplications,
    'controlStatus': controlStatus,
  };
}

/// Result of auto-suggestion generation
class SuggestionResult {
  final DateTime suggestedNextVisit;
  final String nextVisitRationale;

  final List<InvestigationSuggestion> suggestedInvestigations;

  final String followUpPlanText;

  final List<String> criticalReminders;

  final Map<String, dynamic> metadata; // For debugging/audit

  const SuggestionResult({
    required this.suggestedNextVisit,
    required this.nextVisitRationale,
    required this.suggestedInvestigations,
    required this.followUpPlanText,
    this.criticalReminders = const [],
    this.metadata = const {},
  });
}

/// Individual investigation suggestion
class InvestigationSuggestion {
  final String name;
  final String code;
  final String rationale;
  final bool isUrgent;
  final bool isOverdue;
  final DateTime? lastPerformed;
  final int? daysSinceLastPerformed;
  final int? daysOverdue;

  const InvestigationSuggestion({
    required this.name,
    required this.code,
    required this.rationale,
    this.isUrgent = false,
    this.isOverdue = false,
    this.lastPerformed,
    this.daysSinceLastPerformed,
    this.daysOverdue,
  });
}