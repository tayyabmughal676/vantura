/// Helper class for generating JSON schemas from Dart Maps.
/// Simplifies tool parameter definition by automatically wrapping properties
/// in the standard JSON schema object structure.
class SchemaHelper {
  /// Generates a complete JSON schema from a map of property definitions.
  ///
  /// [properties] should be a Map where keys are parameter names and values
  /// are Maps containing schema details like 'type', 'description', 'enum', etc.
  ///
  /// [required] is an optional list of required parameter names. If not provided,
  /// all properties are assumed to be required.
  static Map<String, dynamic> generateSchema(
    Map<String, dynamic> properties, {
    List<String>? required,
  }) {
    final requiredFields = required ?? properties.keys.toList();

    return {
      'type': 'object',
      'properties': properties,
      'required': requiredFields,
    };
  }

  /// Helper method to create a string property schema.
  static Map<String, dynamic> stringProperty({
    String? description,
    List<String>? enumValues,
  }) {
    final property = <String, dynamic>{'type': 'string'};
    if (description != null) property['description'] = description;
    if (enumValues != null) property['enum'] = enumValues;
    return property;
  }

  /// Helper method to create a number property schema.
  static Map<String, dynamic> numberProperty({String? description}) {
    final property = <String, dynamic>{'type': 'number'};
    if (description != null) property['description'] = description;
    return property;
  }

  /// Helper method to create an integer property schema.
  static Map<String, dynamic> integerProperty({String? description}) {
    final property = <String, dynamic>{'type': 'integer'};
    if (description != null) property['description'] = description;
    return property;
  }

  /// Helper method to create a boolean property schema.
  static Map<String, dynamic> booleanProperty({String? description}) {
    final property = <String, dynamic>{'type': 'boolean'};
    if (description != null) property['description'] = description;
    return property;
  }

  /// Helper method to create an array property schema.
  static Map<String, dynamic> arrayProperty({
    String? description,
    Map<String, dynamic>? items,
  }) {
    final property = <String, dynamic>{'type': 'array'};
    if (description != null) property['description'] = description;
    if (items != null) property['items'] = items;
    return property;
  }

  /// Represents an empty JSON schema for tools without parameters.
  static Map<String, dynamic> get emptySchema => {
    'type': 'object',
    'properties': {},
  };
}
