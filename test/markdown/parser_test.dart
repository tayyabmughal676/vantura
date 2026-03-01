import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/markdown/nodes.dart';
import 'package:vantura/markdown/parser.dart';

void main() {
  group('Markdown Parser', () {
    test('parses horizontal rule', () {
      final text = '---';
      final blocks = parseMarkdown(text);
      expect(blocks.length, 1);
      expect(blocks[0], isA<HorizontalRuleBlock>());
    });

    test('parses multiple horizontal rules with spacing', () {
      final text = '---\n\n---';
      final blocks = parseMarkdown(text);
      expect(blocks.length, 2);
      expect(blocks[0], isA<HorizontalRuleBlock>());
      expect(blocks[1], isA<HorizontalRuleBlock>());
    });

    group('Headers', () {
      test('parses H1', () {
        final text = '# Heading 1';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        final header = blocks[0] as HeaderBlock;
        expect(header.level, 1);
        expect(header.text, 'Heading 1');
      });

      test('parses H3', () {
        final text = '### Heading 3';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        final header = blocks[0] as HeaderBlock;
        expect(header.level, 3);
        expect(header.text, 'Heading 3');
      });

      test('ignores headers without space', () {
        final text = '#Invalid Header';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        // It is parsed as a Paragraph block
        expect(blocks[0], isA<ParagraphBlock>());
      });
    });

    group('Lists', () {
      test('parses bullet list', () {
        final text = '- Item 1\n- Item 2\n- Item 3';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        final list = blocks[0] as ListBlock;
        expect(list.items.length, 3);
        expect(list.items[0], 'Item 1');
        expect(list.items[1], 'Item 2');
        expect(list.items[2], 'Item 3');
      });

      test('parses mixed content with list', () {
        final text = 'Intro\n\n- Item 1\n- Item 2\n\nOutro';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 3);
        expect(blocks[0], isA<ParagraphBlock>());
        expect(blocks[1], isA<ListBlock>());
        final list = blocks[1] as ListBlock;
        expect(list.items.length, 2);
        expect(blocks[2], isA<ParagraphBlock>());
      });
    });

    group('Paragraphs and Inline Formatting', () {
      test('parses simple paragraph', () {
        final text = 'Hello world!';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        final para = blocks[0] as ParagraphBlock;
        expect(para.inlines.length, 1);
        expect(para.inlines[0], isA<TextInline>());
        expect((para.inlines[0] as TextInline).text, 'Hello world!');
      });

      test('groups consecutive text into one paragraph', () {
        final text = 'Line 1\nLine 2';
        final blocks = parseMarkdown(text);
        expect(blocks.length, 1);
        final para = blocks[0] as ParagraphBlock;
        expect(para.inlines.length, 1);
        expect((para.inlines[0] as TextInline).text, 'Line 1\nLine 2');
      });

      test('parseInlines handles code', () {
        final inlines = parseInlines('This is `code` block.');
        expect(inlines.length, 3);
        expect(inlines[0], isA<TextInline>());
        expect((inlines[0] as TextInline).text, 'This is ');
        expect(inlines[1], isA<CodeInline>());
        expect((inlines[1] as CodeInline).code, 'code');
        expect(inlines[2], isA<TextInline>());
        expect((inlines[2] as TextInline).text, ' block.');
      });

      test('parseInlines handles bold', () {
        final inlines = parseInlines('This is **bold** text.');
        expect(inlines.length, 3);
        expect(inlines[0], isA<TextInline>());
        expect((inlines[0] as TextInline).text, 'This is ');
        expect(inlines[1], isA<BoldInline>());
        expect(
          ((inlines[1] as BoldInline).children[0] as TextInline).text,
          'bold',
        );
        expect(inlines[2], isA<TextInline>());
      });

      test('parseInlines handles italic', () {
        final inlines = parseInlines('This is *italic* text.');
        expect(inlines.length, 3);
        expect(inlines[0], isA<TextInline>());
        expect((inlines[0] as TextInline).text, 'This is ');
        expect(inlines[1], isA<ItalicInline>());
        expect(
          ((inlines[1] as ItalicInline).children[0] as TextInline).text,
          'italic',
        );
        expect(inlines[2], isA<TextInline>());
      });

      test('parseInlines combines formatting', () {
        final inlines = parseInlines(
          'Hi **bold** and *italic* and `code` done.',
        );
        expect(inlines.length, 7);
        expect(inlines[0], isA<TextInline>());
        expect(inlines[1], isA<BoldInline>());
        expect(inlines[2], isA<TextInline>()); // ' and '
        expect(inlines[3], isA<ItalicInline>());
        expect(inlines[4], isA<TextInline>()); // ' and '
        expect(inlines[5], isA<CodeInline>());
        expect(inlines[6], isA<TextInline>()); // ' done.'
      });
    });

    test('parses full document structure', () {
      final doc = '''
# Title
---
This is a **bold** paragraph.

## Subtitle

- Item 1
- Item 2
''';
      final blocks = parseMarkdown(doc);
      expect(blocks.length, 5);
      expect(blocks[0], isA<HeaderBlock>());
      expect(blocks[1], isA<HorizontalRuleBlock>());
      expect(blocks[2], isA<ParagraphBlock>());
      expect(blocks[3], isA<HeaderBlock>());
      expect(blocks[4], isA<ListBlock>());
    });
  });
}
