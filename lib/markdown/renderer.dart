import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'nodes.dart';

class MarkdownRenderer extends StatelessWidget {
  final List<BlockNode> blocks;
  final bool isUser;

  const MarkdownRenderer(this.blocks, {this.isUser = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, BlockNode block) {
    if (block is HeaderBlock) {
      double fontSize = 20.0 - (block.level * 2.0);
      return Container(
        padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.text,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: isUser ? Colors.white : Colors.blueAccent.shade100,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 2.5,
              width: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: isUser
                      ? [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0),
                        ]
                      : [Colors.blueAccent, Colors.blueAccent.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (block is HorizontalRuleBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Divider(
          color: isUser ? Colors.white24 : Colors.white10,
          thickness: 1,
        ),
      );
    } else if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text.rich(
          _buildInline(context, block.inlines),
          style: GoogleFonts.inter(
            color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.9),
            height: 1.6,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      );
    } else if (block is ListBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8.0, right: 14.0),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isUser ? Colors.white70 : Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            color: isUser
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    return const SizedBox();
  }

  InlineSpan _buildInline(BuildContext context, List<InlineNode> inlines) {
    List<InlineSpan> spans = [];
    for (InlineNode inline in inlines) {
      if (inline is TextInline) {
        if (inline.text.isEmpty) continue;
        spans.add(TextSpan(text: inline.text));
      } else if (inline is BoldInline) {
        spans.add(
          TextSpan(
            children: [_buildInline(context, inline.children)],
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      } else if (inline is ItalicInline) {
        spans.add(
          TextSpan(
            children: [_buildInline(context, inline.children)],
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isUser ? Colors.white.withValues(alpha: 0.8) : Colors.white70,
            ),
          ),
        );
      } else if (inline is CodeInline) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isUser ? Colors.black26 : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isUser
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Text(
                inline.code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: isUser ? Colors.white : Colors.blueAccent.shade100,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}
