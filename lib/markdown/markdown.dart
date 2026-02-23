import 'package:flutter/material.dart';
import 'parser.dart';
import 'renderer.dart';

/// A widget that renders markdown text.
///
/// Supports basic markdown: headers (#), paragraphs, bold (**), italic (*), code (`), lists (-).
class MarkdownText extends StatelessWidget {
  final String data;
  final bool isUser;

  const MarkdownText(this.data, {this.isUser = false, super.key});

  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdown(data);
    return MarkdownRenderer(blocks, isUser: isUser);
  }
}
