import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/markdown/nodes.dart';
import 'package:vantura/markdown/renderer.dart';
import 'package:vantura/markdown/markdown.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('MarkdownRenderer', () {
    testWidgets('renders simple text paragraph', (WidgetTester tester) async {
      final blocks = [
        ParagraphBlock([TextInline('Hello World')]),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders bold text', (WidgetTester tester) async {
      final blocks = [
        ParagraphBlock([
          TextInline('Start '),
          BoldInline([TextInline('BOLD')]),
          TextInline(' End'),
        ]),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textSpan!.toPlainText(), 'Start BOLD End');

      final richText = find.byType(RichText);
      expect(richText, findsOneWidget);
    });

    testWidgets('renders italic text', (WidgetTester tester) async {
      final blocks = [
        ParagraphBlock([
          TextInline('Start '),
          ItalicInline([TextInline('ITALIC')]),
          TextInline(' End'),
        ]),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textSpan!.toPlainText(), 'Start ITALIC End');

      final richText = find.byType(RichText);
      expect(richText, findsOneWidget);
    });

    testWidgets('renders code text', (WidgetTester tester) async {
      final blocks = [
        ParagraphBlock([
          TextInline('Run '),
          CodeInline('echo hi'),
          TextInline(' now'),
        ]),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      expect(find.text('echo hi'), findsOneWidget);

      final textWidget = tester.widget<Text>(
        find.descendant(of: find.byType(RichText), matching: find.byType(Text)),
      );

      expect(textWidget.data, 'echo hi');
    });

    testWidgets('renders headings', (WidgetTester tester) async {
      final blocks = [HeaderBlock(1, 'H1 Title'), HeaderBlock(3, 'H3 Title')];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      expect(find.text('H1 Title'), findsOneWidget);
      expect(find.text('H3 Title'), findsOneWidget);

      // Verify the gradient container is present below headings
      // Each heading creates a Container housing the text, and a child Container housing the line
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders lists', (WidgetTester tester) async {
      final blocks = [
        ListBlock(['Alpha', 'Beta', 'Gamma']),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);

      // Check for bullet points (Containers with BoxShape.circle)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final bulletPoints = containers.where((c) {
        final boxDec = c.decoration as BoxDecoration?;
        return boxDec?.shape == BoxShape.circle;
      });

      expect(bulletPoints.length, 3);
    });

    testWidgets('renders horizontal rules', (WidgetTester tester) async {
      final blocks = [
        HeaderBlock(1, 'Title'),
        HorizontalRuleBlock(),
        ParagraphBlock([TextInline('Body')]),
      ];
      await tester.pumpWidget(buildApp(MarkdownRenderer(blocks)));

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('MarkdownText', () {
    testWidgets('converts raw markdown to rendered widgets', (
      WidgetTester tester,
    ) async {
      final text = '''
# Heading

This is **bold**, *italic*, and `code`.

---

- Bullet 1
- Bullet 2
''';

      await tester.pumpWidget(buildApp(MarkdownText(text)));

      expect(find.text('Heading'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);

      // Use textContaining instead of exact matches as spans are grouped in a RichText.
      expect(find.textContaining('bold'), findsOneWidget);
      expect(find.textContaining('italic'), findsOneWidget);
      expect(
        find.textContaining('code'),
        findsOneWidget,
      ); // Inner code widget span
      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('Bullet 1'), findsOneWidget);
      expect(find.text('Bullet 2'), findsOneWidget);
    });
  });
}
