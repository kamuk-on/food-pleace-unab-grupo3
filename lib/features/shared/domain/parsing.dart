/// Excepcion lanzada cuando un JSON no puede convertirse a una entidad valida.
class ParsingException implements Exception {
  ParsingException(this.field, this.reason);

  final String field;
  final String reason;

  @override
  String toString() => 'ParsingException(field: $field, reason: $reason)';
}

/// Helpers de parseo defensivo para mapear JSON proveniente del API.
abstract final class JsonParser {
  static String requireString(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw ParsingException(key, 'Se esperaba un string no vacio.');
  }

  static String? optionalString(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static int requireInt(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final int? parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ParsingException(key, 'Se esperaba un entero.');
  }

  static double requireDouble(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final double? parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ParsingException(key, 'Se esperaba un numero decimal.');
  }

  static bool optionalBool(
    Map<String, dynamic> json,
    String key, {
    bool defaultValue = false,
  }) {
    final dynamic value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  static DateTime requireDateTime(Map<String, dynamic> json, String key) {
    final dynamic value = json[key];
    if (value is DateTime) return value;
    if (value is String) {
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ParsingException(key, 'Se esperaba una fecha ISO-8601.');
  }

  static List<Map<String, dynamic>> requireObjectList(
    Map<String, dynamic> json,
    String key,
  ) {
    final dynamic value = json[key];
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    throw ParsingException(key, 'Se esperaba una lista de objetos.');
  }
}
