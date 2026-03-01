import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/core/cancellation_token.dart';

void main() {
  group('CancellationToken', () {
    test('is not cancelled by default', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('isCancelled returns true after cancel() is called', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test(
      'cancel() is idempotent — calling it multiple times stays cancelled',
      () {
        final token = CancellationToken();
        token.cancel();
        token.cancel();
        token.cancel();
        expect(token.isCancelled, isTrue);
      },
    );

    test('independent tokens do not affect each other', () {
      final tokenA = CancellationToken();
      final tokenB = CancellationToken();
      tokenA.cancel();
      expect(tokenA.isCancelled, isTrue);
      expect(tokenB.isCancelled, isFalse);
    });
  });
}
