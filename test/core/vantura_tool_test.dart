import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/core/vantura_tool.dart';
import 'package:vantura/core/schema_helper.dart';

/// Concrete test implementation of VanturaTool.
class _AddTool extends VanturaTool<Map<String, dynamic>> {
  @override
  String get name => 'add';

  @override
  String get description => 'Adds two numbers';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'a': SchemaHelper.numberProperty(description: 'First number'),
    'b': SchemaHelper.numberProperty(description: 'Second number'),
  });

  @override
  Map<String, dynamic> parseArgs(Map<String, dynamic> json) => json;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final a = (args['a'] as num);
    final b = (args['b'] as num);
    return 'Result: ${a + b}';
  }
}

/// Tool with requiresConfirmation = true and a custom timeout.
class _DangerousTool extends VanturaTool<Map<String, dynamic>> {
  @override
  String get name => 'danger';

  @override
  String get description => 'A dangerous operation';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.emptySchema;

  @override
  bool get requiresConfirmation => true;

  @override
  Duration get timeout => const Duration(seconds: 5);

  @override
  Map<String, dynamic> parseArgs(Map<String, dynamic> json) => json;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    return 'executed';
  }
}

void main() {
  group('VanturaTool', () {
    test('concrete tool has correct name, description and parameters', () {
      final tool = _AddTool();
      expect(tool.name, 'add');
      expect(tool.description, 'Adds two numbers');
      expect(tool.parameters['type'], 'object');
      expect(tool.parameters['properties'], isA<Map>());
      expect(tool.parameters['required'], containsAll(['a', 'b']));
    });

    test('default requiresConfirmation is false', () {
      final tool = _AddTool();
      expect(tool.requiresConfirmation, isFalse);
    });

    test('default timeout is 30 seconds', () {
      final tool = _AddTool();
      expect(tool.timeout, const Duration(seconds: 30));
    });

    test('execute returns expected result', () async {
      final tool = _AddTool();
      final result = await tool.execute({'a': 3, 'b': 7});
      expect(result, 'Result: 10');
    });

    test('parseArgs passes through correctly', () {
      final tool = _AddTool();
      final parsed = tool.parseArgs({'a': 1, 'b': 2});
      expect(parsed['a'], 1);
      expect(parsed['b'], 2);
    });
  });

  group('VanturaTool with overrides', () {
    test('requiresConfirmation can be overridden to true', () {
      final tool = _DangerousTool();
      expect(tool.requiresConfirmation, isTrue);
    });

    test('timeout can be overridden', () {
      final tool = _DangerousTool();
      expect(tool.timeout, const Duration(seconds: 5));
    });
  });

  group('NullArgs', () {
    test('NullArgs can be constructed', () {
      const args = NullArgs();
      expect(args, isA<NullArgs>());
    });

    test('const NullArgs are identical', () {
      const a = NullArgs();
      const b = NullArgs();
      expect(identical(a, b), isTrue);
    });
  });
}
