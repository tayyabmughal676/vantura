/// Base class for all elements in the markdown abstract syntax tree.
abstract class MarkdownNode {}

/// Represents a block-level element like a paragraph or header.
abstract class BlockNode extends MarkdownNode {}

/// Represents an inline-level element like bold text or a link.
abstract class InlineNode extends MarkdownNode {}

/// A horizontal rule `<hr>`.
class HorizontalRuleBlock extends BlockNode {}

/// A header with a specific [level] (1-6) and [text] content.
class HeaderBlock extends BlockNode {
  /// The level of the header (e.g., 1 for #).
  final int level;

  /// The raw text content of the header.
  final String text;

  HeaderBlock(this.level, this.text);
}

/// A paragraph containing a list of [inlines].
class ParagraphBlock extends BlockNode {
  /// The inline segments that make up the paragraph.
  final List<InlineNode> inlines;

  ParagraphBlock(this.inlines);
}

/// A bulleted list containing multiple [items].
class ListBlock extends BlockNode {
  /// The raw text for each list item.
  final List<String> items;

  ListBlock(this.items);
}

/// Plain text inside a paragraph or other inline container.
class TextInline extends InlineNode {
  /// The text content.
  final String text;

  TextInline(this.text);
}

/// Bold text containing other [children] inlines.
class BoldInline extends InlineNode {
  /// The nested inline nodes.
  final List<InlineNode> children;

  BoldInline(this.children);
}

/// Italic text containing other [children] inlines.
class ItalicInline extends InlineNode {
  /// The nested inline nodes.
  final List<InlineNode> children;

  ItalicInline(this.children);
}

/// Inline code or a monospace snippet.
class CodeInline extends InlineNode {
  /// The raw code content.
  final String code;

  CodeInline(this.code);
}
