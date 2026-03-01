import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit/main.dart';

void main() {
  testWidgets('OrbitApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrbitApp()));

    // Basic smoke test — the app should render a MaterialApp
    expect(find.byType(OrbitApp), findsOneWidget);
  });
}
