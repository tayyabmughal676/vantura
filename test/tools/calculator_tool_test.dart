import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/tools/calculator_tool.dart';

void main() {
  group('CalculatorTool', () {
    late CalculatorTool tool;

    setUp(() {
      tool = CalculatorTool();
    });

    test('metadata is correct', () {
      expect(tool.name, 'calculator');
      expect(tool.description, 'Performs basic arithmetic operations');
      expect(tool.parameters['required'], containsAll(['operation', 'a', 'b']));
    });

    test('parseArgs converts JSON map to CalculatorArgs', () {
      final jsonMap = {'operation': 'add', 'a': 5, 'b': 10};

      final args = tool.parseArgs(jsonMap);

      expect(args.operation, 'add');
      expect(args.a, 5);
      expect(args.b, 10);
    });

    group('execute operations', () {
      test('adds two numbers', () async {
        final result = await tool.execute(
          CalculatorArgs(operation: 'add', a: 5, b: 3),
        );
        expect(result, 'Result: 8');
      });

      test('subtracts two numbers', () async {
        // use double precision check and integer operations
        final result = await tool.execute(
          CalculatorArgs(operation: 'subtract', a: 10, b: 4.5),
        );
        expect(result, 'Result: 5.5');
      });

      test('multiplies two numbers', () async {
        final result = await tool.execute(
          CalculatorArgs(operation: 'multiply', a: 6, b: 7),
        );
        expect(result, 'Result: 42');
      });

      test('divides two numbers', () async {
        final result = await tool.execute(
          CalculatorArgs(operation: 'divide', a: 10, b: 2),
        );
        expect(result, 'Result: 5.0');
      });

      test('handles division by zero gracefully', () async {
        final result = await tool.execute(
          CalculatorArgs(operation: 'divide', a: 10, b: 0),
        );
        expect(result, 'Error: Division by zero');
      });

      test('returns error for unknown operation', () async {
        final result = await tool.execute(
          CalculatorArgs(operation: 'power', a: 2, b: 3),
        );
        expect(result, 'Unknown operation');
      });
    });
  });
}
