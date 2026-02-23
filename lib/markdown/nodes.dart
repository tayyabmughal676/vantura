abstract class MarkdownNode {}

abstract class BlockNode extends MarkdownNode {}

abstract class InlineNode extends MarkdownNode {}

class HorizontalRuleBlock extends BlockNode {}

class HeaderBlock extends BlockNode {
  final int level;
  final String text;
  HeaderBlock(this.level, this.text);
}

class ParagraphBlock extends BlockNode {
  final List<InlineNode> inlines;
  ParagraphBlock(this.inlines);
}

class ListBlock extends BlockNode {
  final List<String> items;
  ListBlock(this.items);
}

class TextInline extends InlineNode {
  final String text;
  TextInline(this.text);
}

class BoldInline extends InlineNode {
  final List<InlineNode> children;
  BoldInline(this.children);
}

class ItalicInline extends InlineNode {
  final List<InlineNode> children;
  ItalicInline(this.children);
}

class CodeInline extends InlineNode {
  final String code;
  CodeInline(this.code);
}
