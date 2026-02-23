import 'nodes.dart';

List<BlockNode> parseMarkdown(String text) {
  List<String> lines = text.split('\n');
  List<BlockNode> blocks = [];
  int i = 0;
  while (i < lines.length) {
    String line = lines[i].trim();
    if (line.startsWith('#')) {
      int level = 0;
      while (level < line.length && line[level] == '#') {
        level++;
      }
      if (level < line.length && line[level] == ' ') {
        String headerText = line.substring(level + 1);
        blocks.add(HeaderBlock(level, headerText));
        i++;
        continue;
      }
    } else if (line.startsWith('---')) {
      blocks.add(HorizontalRuleBlock());
      i++;
      continue;
    } else if (line.startsWith('- ')) {
      List<String> items = [];
      while (i < lines.length && lines[i].trim().startsWith('- ')) {
        items.add(lines[i].trim().substring(2));
        i++;
      }
      blocks.add(ListBlock(items));
      continue;
    } else if (line.isNotEmpty) {
      // Paragraph
      String para = '';
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          !lines[i].trim().startsWith('#') &&
          !lines[i].trim().startsWith('- ')) {
        para += '${lines[i]}\n';
        i++;
      }
      para = para.trim();
      if (para.isNotEmpty) {
        List<InlineNode> inlines = parseInlines(para);
        blocks.add(ParagraphBlock(inlines));
      }
      continue;
    }
    i++;
  }
  return blocks;
}

List<InlineNode> parseInlines(String text) {
  List<InlineNode> inlines = [];
  // Simple parser, assume no nesting
  List<String> parts = text.split(RegExp(r'(\*\*|\*|`)'));
  bool bold = false;
  bool italic = false;
  bool code = false;
  for (String part in parts) {
    if (part == '**') {
      bold = !bold;
    } else if (part == '*') {
      italic = !italic;
    } else if (part == '`') {
      code = !code;
    } else {
      InlineNode node;
      if (code) {
        node = CodeInline(part);
      } else if (bold) {
        node = BoldInline([TextInline(part)]);
      } else if (italic) {
        node = ItalicInline([TextInline(part)]);
      } else {
        node = TextInline(part);
      }
      inlines.add(node);
    }
  }
  return inlines;
}
