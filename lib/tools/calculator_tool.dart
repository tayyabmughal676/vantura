import '../core/index.dart';

/// Arguments for the CalculatorTool.
class CalculatorArgs {
  final String operation;
  final num a;
  final num b;

  CalculatorArgs({required this.operation, required this.a, required this.b});

  /// Creates CalculatorArgs from a JSON map.
  factory CalculatorArgs.fromJson(Map<String, dynamic> json) {
    return CalculatorArgs(
      operation: json['operation'] as String,
      a: json['a'] as num,
      b: json['b'] as num,
    );
  }
}

/// A tool for performing basic arithmetic operations.
///
/// Supports addition, subtraction, multiplication, and division.
class CalculatorTool extends VanturaTool<CalculatorArgs> {
  @override
  String get name => 'calculator';

  @override
  String get description => 'Performs basic arithmetic operations';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'operation': SchemaHelper.stringProperty(
      description: 'The arithmetic operation to perform',
      enumValues: ['add', 'subtract', 'multiply', 'divide'],
    ),
    'a': SchemaHelper.numberProperty(description: 'First number'),
    'b': SchemaHelper.numberProperty(description: 'Second number'),
  });

  @override
  CalculatorArgs parseArgs(Map<String, dynamic> json) =>
      CalculatorArgs.fromJson(json);

  @override
  Future<String> execute(CalculatorArgs args) async {
    final op = args.operation;
    final a = args.a;
    final b = args.b;
    num result;
    switch (op) {
      case 'add':
        result = a + b;
        break;
      case 'subtract':
        result = a - b;
        break;
      case 'multiply':
        result = a * b;
        break;
      case 'divide':
        if (b == 0) return 'Error: Division by zero';
        result = a / b;
        break;
      default:
        return 'Unknown operation';
    }
    return 'Result: $result';
  }
}
