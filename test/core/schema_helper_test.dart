import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/core/schema_helper.dart';

void main() {
  group('SchemaHelper', () {
    group('generateSchema', () {
      test('generates schema with all properties required by default', () {
        final schema = SchemaHelper.generateSchema({
          'name': SchemaHelper.stringProperty(description: 'The name'),
          'age': SchemaHelper.integerProperty(description: 'The age'),
        });

        expect(schema['type'], 'object');
        expect(schema['properties'], isA<Map>());
        expect(schema['required'], containsAll(['name', 'age']));
      });

      test('generates schema with explicit required fields', () {
        final schema = SchemaHelper.generateSchema(
          {
            'name': SchemaHelper.stringProperty(),
            'nickname': SchemaHelper.stringProperty(),
          },
          required: ['name'],
        );

        expect(schema['required'], ['name']);
        expect(schema['required'], isNot(contains('nickname')));
      });

      test('generates schema with empty properties', () {
        final schema = SchemaHelper.generateSchema({});

        expect(schema['type'], 'object');
        expect(schema['properties'], isEmpty);
        expect(schema['required'], isEmpty);
      });
    });

    group('stringProperty', () {
      test('creates a basic string property', () {
        final prop = SchemaHelper.stringProperty();
        expect(prop['type'], 'string');
        expect(prop.containsKey('description'), isFalse);
        expect(prop.containsKey('enum'), isFalse);
      });

      test('creates a string property with description', () {
        final prop = SchemaHelper.stringProperty(description: 'A test field');
        expect(prop['type'], 'string');
        expect(prop['description'], 'A test field');
      });

      test('creates a string property with enum values', () {
        final prop = SchemaHelper.stringProperty(enumValues: ['a', 'b', 'c']);
        expect(prop['type'], 'string');
        expect(prop['enum'], ['a', 'b', 'c']);
      });

      test('creates a string property with both description and enum', () {
        final prop = SchemaHelper.stringProperty(
          description: 'Pick one',
          enumValues: ['x', 'y'],
        );
        expect(prop['type'], 'string');
        expect(prop['description'], 'Pick one');
        expect(prop['enum'], ['x', 'y']);
      });
    });

    group('numberProperty', () {
      test('creates a basic number property', () {
        final prop = SchemaHelper.numberProperty();
        expect(prop['type'], 'number');
      });

      test('creates a number property with description', () {
        final prop = SchemaHelper.numberProperty(description: 'The value');
        expect(prop['type'], 'number');
        expect(prop['description'], 'The value');
      });
    });

    group('integerProperty', () {
      test('creates a basic integer property', () {
        final prop = SchemaHelper.integerProperty();
        expect(prop['type'], 'integer');
      });

      test('creates an integer property with description', () {
        final prop = SchemaHelper.integerProperty(description: 'Count');
        expect(prop['type'], 'integer');
        expect(prop['description'], 'Count');
      });
    });

    group('booleanProperty', () {
      test('creates a basic boolean property', () {
        final prop = SchemaHelper.booleanProperty();
        expect(prop['type'], 'boolean');
      });

      test('creates a boolean property with description', () {
        final prop = SchemaHelper.booleanProperty(description: 'Is active');
        expect(prop['type'], 'boolean');
        expect(prop['description'], 'Is active');
      });
    });

    group('arrayProperty', () {
      test('creates a basic array property', () {
        final prop = SchemaHelper.arrayProperty();
        expect(prop['type'], 'array');
      });

      test('creates an array property with description', () {
        final prop = SchemaHelper.arrayProperty(description: 'List of items');
        expect(prop['type'], 'array');
        expect(prop['description'], 'List of items');
      });

      test('creates an array property with items schema', () {
        final prop = SchemaHelper.arrayProperty(
          description: 'Tags',
          items: SchemaHelper.stringProperty(description: 'A tag'),
        );
        expect(prop['type'], 'array');
        expect(prop['items']['type'], 'string');
        expect(prop['items']['description'], 'A tag');
      });
    });

    group('emptySchema', () {
      test('returns a valid empty object schema', () {
        final schema = SchemaHelper.emptySchema;
        expect(schema['type'], 'object');
        expect(schema['properties'], isEmpty);
        expect(schema.containsKey('required'), isFalse);
      });
    });
  });
}
