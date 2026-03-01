import 'nodes.dart';

/// Parses raw markdown text into a list of [BlockNode]s.
///
/// Supported blocks: Headers, Lists, Paragraphs, and Horizontal Rules.
List<BlockNode> parseMarkdown(String text) {
  List<String> lines = text.split('\n');
  List<BlockNode> blocks = [];
  int i = 0;
  while (i < lines.length) {
    String line = lines[i].trim();
    if (line.isEmpty) {
      i++;
      continue;
    }

    if (line.startsWith('#')) {
      int level = 0;
      while (level < line.length && line[level] == '#') {
        level++;
      }
      if (level < line.length && line[level] == ' ') {
        String headerText = line.substring(level + 1).trim();
        blocks.add(HeaderBlock(level, headerText));
        i++;
        continue;
      }
    }

    if (line.startsWith('---')) {
      blocks.add(HorizontalRuleBlock());
      i++;
      continue;
    }

    if (line.startsWith('- ')) {
      List<String> items = [];
      while (i < lines.length && lines[i].trim().startsWith('- ')) {
        items.add(lines[i].trim().substring(2).trim());
        i++;
      }
      blocks.add(ListBlock(items));
      continue;
    }

    // Paragraph
    String para = '';
    while (i < lines.length && lines[i].trim().isNotEmpty) {
      String currentLine = lines[i].trim();
      // Stop if we hit a different block type
      if (currentLine.startsWith('---')) break;
      if (currentLine.startsWith('- ')) break;
      if (currentLine.startsWith('#')) {
        int level = 0;
        while (level < currentLine.length && currentLine[level] == '#') level++;
        if (level < currentLine.length && currentLine[level] == ' ') break;
      }

      para += (para.isEmpty ? '' : '\n') + lines[i];
      i++;
    }

    if (para.isNotEmpty) {
      blocks.add(ParagraphBlock(parseInlines(para)));
    }
  }
  return blocks;
}

List<InlineNode> parseInlines(String text) {
  List<InlineNode> inlines = [];
  int cursor = 0;

  while (cursor < text.length) {
    int boldIdx = text.indexOf('**', cursor);
    int italicIdx = text.indexOf('*', cursor);
    int codeIdx = text.indexOf('`', cursor);

    int earliest = -1;
    String delim = '';

    if (boldIdx != -1 && (earliest == -1 || boldIdx < earliest)) {
      earliest = boldIdx;
      delim = '**';
    }
    if (italicIdx != -1 && (earliest == -1 || italicIdx < earliest)) {
      // Ensure we don't mistake part of ** for *
      if (boldIdx != italicIdx) {
        earliest = italicIdx;
        delim = '*';
      }
    }
    if (codeIdx != -1 && (earliest == -1 || codeIdx < earliest)) {
      earliest = codeIdx;
      delim = '`';
    }

    if (earliest == -1) {
      inlines.add(TextInline(text.substring(cursor)));
      break;
    }

    if (earliest > cursor) {
      inlines.add(TextInline(text.substring(cursor, earliest)));
    }

    int startOfContent = earliest + delim.length;
    int endIdx = text.indexOf(delim, startOfContent);

    if (endIdx == -1) {
      inlines.add(TextInline(text.substring(earliest)));
      cursor = text.length;
    } else {
      String content = text.substring(startOfContent, endIdx);
      if (delim == '`') {
        inlines.add(CodeInline(content));
      } else if (delim == '**') {
        inlines.add(BoldInline([TextInline(content)]));
      } else if (delim == '*') {
        inlines.add(ItalicInline([TextInline(content)]));
      }
      cursor = endIdx + delim.length;
    }
  }

  // Combine adjacent TextInlines if any
  if (inlines.isEmpty) return [];
  List<InlineNode> combined = [];
  for (var node in inlines) {
    if (combined.isNotEmpty &&
        combined.last is TextInline &&
        node is TextInline) {
      combined[combined.length - 1] = TextInline(
        (combined.last as TextInline).text + node.text,
      );
    } else {
      combined.add(node);
    }
  }

  return combined;
}
