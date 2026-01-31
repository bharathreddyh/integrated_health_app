// lib/services/template_suggestion_service.dart
// Service for generating intelligent auto-suggestions based on disease templates

import 'dart:math';
import '../models/enhanced_disease_template.dart';

class TemplateSuggestionService {
  static final TemplateSuggestionService instance = TemplateSuggestionService._();

  TemplateSuggestionService._();

  /// Generate comprehensive suggestions for the current consultation
  Future<SuggestionResult> generateSuggestions({
    required EnhancedDiseaseTemplate template,
    required PatientContext context,
    bool isInitialVisit = false,
  }) async {
    // Simulate async processing (in real app, might call AI API)
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate each component
    final nextVisit = _calculateNextVisit(template, context);
    final investigations = _suggestInvestigations(template, context);
    final followUpPlan = _generateFollowUpPlan(template, context);
    final criticalReminders = _generateCriticalReminders(template, context);

    return SuggestionResult(
      suggestedNextVisit: nextVisit.date,
      nextVisitRationale: nextVisit.rationale,
      suggestedInvestigations: investigations,
      followUpPlanText: followUpPlan,
      criticalReminders: criticalReminders,
      metadata: {
        'generatedAt': DateTime.now().toIso8601String(),
        'templateId': template.id,
        'patientId': context.patientId,
        'isInitialVisit': isInitialVisit,
      },
    );
  }

  /// Calculate optimal next visit date based on protocol and patient context
  ({DateTime date, String rationale}) _calculateNextVisit(
      EnhancedDiseaseTemplate template,
      PatientContext context,
      ) {
    final protocol = template.followUpProtocol;
    int intervalDays = protocol.defaultIntervalDays;
    String rationale = protocol.defaultRationale;

    // Apply adjustment rules
    for (final rule in protocol.adjustmentRules) {
      if (_evaluateAdjustmentRule(rule, context)) {
        intervalDays += rule.adjustmentDays;

        // Use conditional rationale if available
        if (protocol.conditionalRationales.containsKey(rule.condition)) {
          rationale = protocol.conditionalRationales[rule.condition]!;
        } else {
          rationale = rule.rationale;
        }

        // Only apply first matching rule
        break;
      }
    }

    // Ensure within bounds
    intervalDays = intervalDays.clamp(
      protocol.minIntervalDays,
      protocol.maxIntervalDays,
    );

    final nextVisitDate = DateTime.now().add(Duration(days: intervalDays));

    return (date: nextVisitDate, rationale: rationale);
  }

  /// Evaluate if an adjustment rule applies to current context
  bool _evaluateAdjustmentRule(
      IntervalAdjustmentRule rule,
      PatientContext context,
      ) {
    switch (rule.conditionType) {
      case RuleConditionType.isInitialVisit:
        return context.lastVisitDate == null || context.isNewDiagnosis;

      case RuleConditionType.vitalOutOfRange:
        if (rule.vitalParameter == null ||
            rule.thresholdValue == null ||
            rule.comparisonOperator == null) {
          return false;
        }

        final vitalValue = context.currentVitals[rule.vitalParameter];
        if (vitalValue == null) return false;

        return _compareValues(
          vitalValue,
          rule.thresholdValue!,
          rule.comparisonOperator!,
        );

      case RuleConditionType.investigationOverdue:
      // Check if any investigation is significantly overdue
        return _hasOverdueInvestigations(context);

      case RuleConditionType.patientAge:
        if (rule.thresholdValue == null || rule.comparisonOperator == null) {
          return false;
        }
        return _compareValues(
          context.age.toDouble(),
          rule.thresholdValue!,
          rule.comparisonOperator!,
        );

      case RuleConditionType.daysSinceLastVisit:
        final days = context.daysSinceLastVisit;
        if (days == null ||
            rule.thresholdValue == null ||
            rule.comparisonOperator == null) {
          return false;
        }
        return _compareValues(
          days.toDouble(),
          rule.thresholdValue!,
          rule.comparisonOperator!,
        );

      case RuleConditionType.customCondition:
      // Handle custom conditions based on control status, complications, etc.
        return _evaluateCustomCondition(rule.condition, context);
    }
  }

  /// Compare two values based on operator
  bool _compareValues(double value, double threshold, String operator) {
    switch (operator) {
      case '>':
        return value > threshold;
      case '<':
        return value < threshold;
      case '>=':
        return value >= threshold;
      case '<=':
        return value <= threshold;
      case '==':
        return (value - threshold).abs() < 0.01; // Float comparison
      default:
        return false;
    }
  }

  /// Evaluate custom conditions
  bool _evaluateCustomCondition(String condition, PatientContext context) {
    switch (condition.toLowerCase()) {
      case 'uncontrolled':
        return context.controlStatus == 'uncontrolled';
      case 'controlled':
        return context.controlStatus == 'controlled';
      case 'has_complications':
        return context.hasComplications;
      case 'new_diagnosis':
        return context.isNewDiagnosis;
      default:
        return false;
    }
  }

  /// Check if patient has overdue investigations
  bool _hasOverdueInvestigations(PatientContext context) {
    // Simple heuristic: if any investigation is > 60 days overdue
    for (final lastDate in context.lastInvestigations.values) {
      final daysSince = DateTime.now().difference(lastDate).inDays;
      if (daysSince > 60) return true;
    }
    return false;
  }

  /// Generate investigation suggestions
  List<InvestigationSuggestion> _suggestInvestigations(
      EnhancedDiseaseTemplate template,
      PatientContext context,
      ) {
    final suggestions = <InvestigationSuggestion>[];

    for (final protocol in template.investigationProtocols) {
      final lastPerformed = context.lastInvestigations[protocol.code];
      final daysSince = lastPerformed != null
          ? DateTime.now().difference(lastPerformed).inDays
          : null;

      // Determine if investigation should be suggested
      bool shouldSuggest = false;
      bool isUrgent = false;
      bool isOverdue = false;
      int? daysOverdue;
      String rationale = protocol.defaultRationale;

      // Mandatory investigations
      if (protocol.isMandatory) {
        shouldSuggest = true;
        rationale = 'Mandatory test for ${template.name} management';
      }

      // Check frequency-based recommendations
      if (lastPerformed == null) {
        shouldSuggest = true;
        rationale = 'Baseline measurement needed';
        if (context.isNewDiagnosis) {
          isUrgent = true;
        }
      } else if (daysSince! >= protocol.recommendedFrequencyDays) {
        shouldSuggest = true;
        daysOverdue = daysSince - protocol.recommendedFrequencyDays;
        isOverdue = true;

        if (protocol.isUrgentIfOverdue && daysOverdue > 30) {
          isUrgent = true;
          rationale = 'Significantly overdue (${daysOverdue} days past due)';
        } else {
          rationale = 'Due for routine monitoring (last done ${_formatDaysAgo(daysSince)})';
        }
      }

      // Evaluate conditional requirements
      for (final condition in protocol.conditions) {
        if (_evaluateInvestigationCondition(condition, context)) {
          shouldSuggest = true;
          if (condition.required) {
            isUrgent = true;
          }
          if (protocol.conditionalRationales.containsKey(condition.condition)) {
            rationale = protocol.conditionalRationales[condition.condition]!;
          }
        }
      }

      if (shouldSuggest) {
        suggestions.add(InvestigationSuggestion(
          name: protocol.investigationName,
          code: protocol.code,
          rationale: rationale,
          isUrgent: isUrgent,
          isOverdue: isOverdue,
          lastPerformed: lastPerformed,
          daysSinceLastPerformed: daysSince,
          daysOverdue: daysOverdue,
        ));
      }
    }

    // Sort: urgent first, then overdue, then by days since last performed
    suggestions.sort((a, b) {
      if (a.isUrgent != b.isUrgent) {
        return a.isUrgent ? -1 : 1;
      }
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }
      final aDays = a.daysSinceLastPerformed ?? 99999;
      final bDays = b.daysSinceLastPerformed ?? 99999;
      return bDays.compareTo(aDays);
    });

    return suggestions;
  }

  /// Evaluate investigation condition
  bool _evaluateInvestigationCondition(
      InvestigationCondition condition,
      PatientContext context,
      ) {
    if (condition.vitalParameter != null &&
        condition.thresholdValue != null &&
        condition.comparisonOperator != null) {
      final vitalValue = context.currentVitals[condition.vitalParameter];
      if (vitalValue != null) {
        return _compareValues(
          vitalValue,
          condition.thresholdValue!,
          condition.comparisonOperator!,
        );
      }
    }

    // Custom condition evaluation
    return _evaluateCustomCondition(condition.condition, context);
  }

  /// Generate follow-up plan text
  String _generateFollowUpPlan(
      EnhancedDiseaseTemplate template,
      PatientContext context,
      ) {
    // Use template as base
    String plan = template.followUpPlanTemplate;

    // Replace placeholders with context-specific values
    plan = _replacePlaceholders(plan, template, context);

    // Add dynamic sections based on current state
    final sections = <String>[];

    // Medication review
    if (context.currentMedications.isNotEmpty) {
      sections.add('Continue current medications as prescribed.');
    }

    // Lifestyle modifications
    if (template.lifestyleAdvice.isNotEmpty) {
      sections.add('\nLifestyle Recommendations:');
      for (final advice in template.lifestyleAdvice) {
        sections.add('• $advice');
      }
    }

    // Monitoring instructions
    if (context.controlStatus == 'uncontrolled') {
      sections.add('\nSelf-Monitoring:');
      sections.add('• Monitor symptoms daily and maintain a health diary');
      sections.add('• Contact clinic if condition worsens');
    }

    // Investigation follow-up
    final investigations = _suggestInvestigations(template, context);
    if (investigations.isNotEmpty) {
      sections.add('\nScheduled Investigations:');
      for (final inv in investigations.take(3)) {
        sections.add('• ${inv.name}${inv.isUrgent ? " (Urgent)" : ""}');
      }
    }

    // Warning signs
    if (template.criticalCheckpoints.isNotEmpty) {
      sections.add('\nSeek immediate care if you experience:');
      for (final checkpoint in template.criticalCheckpoints) {
        sections.add('• $checkpoint');
      }
    }

    plan += '\n\n' + sections.join('\n');

    return plan.trim();
  }

  /// Replace template placeholders with actual values
  String _replacePlaceholders(
      String template,
      EnhancedDiseaseTemplate diseaseTemplate,
      PatientContext context,
      ) {
    String result = template;

    // Common replacements
    result = result.replaceAll('{patient_age}', context.age.toString());
    result = result.replaceAll('{disease_name}', diseaseTemplate.name);
    result = result.replaceAll('{control_status}', context.controlStatus);

    // Vital-specific replacements
    context.currentVitals.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });

    // Date replacements
    final now = DateTime.now();
    result = result.replaceAll(
      '{current_date}',
      '${now.day}/${now.month}/${now.year}',
    );

    return result;
  }

  /// Generate critical reminders based on current state
  List<String> _generateCriticalReminders(
      EnhancedDiseaseTemplate template,
      PatientContext context,
      ) {
    final reminders = <String>[];

    // New diagnosis reminders
    if (context.isNewDiagnosis) {
      reminders.add(
        'NEW DIAGNOSIS: Ensure patient education about ${template.name} is provided',
      );
    }

    // Uncontrolled condition
    if (context.controlStatus == 'uncontrolled') {
      reminders.add(
        'UNCONTROLLED ${template.name.toUpperCase()}: Consider medication adjustment',
      );
    }

    // Complications
    if (context.hasComplications) {
      reminders.add(
        'COMPLICATIONS PRESENT: Refer to specialist if not already done',
      );
    }

    // Urgent investigations
    final investigations = _suggestInvestigations(template, context);
    final urgentCount = investigations.where((i) => i.isUrgent).length;
    if (urgentCount > 0) {
      reminders.add(
        'URGENT: $urgentCount investigation(s) significantly overdue',
      );
    }

    // Long overdue visit
    final daysSince = context.daysSinceLastVisit;
    if (daysSince != null && daysSince > 90) {
      reminders.add(
        'LONG OVERDUE: Patient last visited $daysSince days ago - ensure comprehensive assessment',
      );
    }

    // Add template-specific critical checkpoints
    if (context.isNewDiagnosis && template.criticalCheckpoints.isNotEmpty) {
      reminders.add(
        'Ensure assessment of: ${template.criticalCheckpoints.join(", ")}',
      );
    }

    return reminders;
  }

  /// Format days ago for display
  String _formatDaysAgo(int days) {
    if (days < 30) {
      return '$days days ago';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return '$months month${months > 1 ? "s" : ""} ago';
    } else {
      final years = (days / 365).floor();
      return '$years year${years > 1 ? "s" : ""} ago';
    }
  }

  /// Get protocol guidelines for display
  Map<String, String> getProtocolGuidelines(EnhancedDiseaseTemplate template) {
    return template.protocolGuidelines;
  }

  /// Validate if a template is properly configured
  bool validateTemplate(EnhancedDiseaseTemplate template) {
    // Check required fields
    if (template.name.isEmpty) return false;
    if (template.followUpProtocol.defaultIntervalDays <= 0) return false;
    if (template.followUpPlanTemplate.isEmpty) return false;

    // Check protocol consistency
    if (template.followUpProtocol.minIntervalDays >
        template.followUpProtocol.maxIntervalDays) {
      return false;
    }

    // Validate investigation protocols
    for (final protocol in template.investigationProtocols) {
      if (protocol.investigationName.isEmpty || protocol.code.isEmpty) {
        return false;
      }
      if (protocol.recommendedFrequencyDays <= 0) return false;
    }

    return true;
  }
}