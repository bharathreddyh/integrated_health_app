// lib/models/template_stubs.dart
// Temporary stub classes to fix compilation errors
// These provide minimal implementations to prevent "undefined" errors
// TODO: Replace with proper implementation once the architecture is decided

class DiseaseTemplates {
  /// Returns a disease template by ID
  /// Currently returns null as a stub
  static dynamic getById(String id) {
    // TODO: Implement proper template retrieval
    return null;
  }

  /// Returns templates grouped by medical system
  /// Currently returns empty map as a stub
  static Map<String, List<dynamic>> get groupedBySystem {
    // TODO: Implement proper template grouping
    return {};
  }
}

class MedicalSystems {
  /// Returns a medical system by ID
  /// Currently returns null as a stub
  static dynamic getById(String id) {
    // TODO: Implement proper system retrieval
    return null;
  }
}