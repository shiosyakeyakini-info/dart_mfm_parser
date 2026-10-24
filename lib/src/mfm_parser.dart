import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/language.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/node.dart';

/// MFM Parser class
class MfmParser {
  const MfmParser();

  /// parse full syntax.
  /// if you want to limit elements nest, input [nestLimit]
  List<MfmNode> parse(String input, {int? nestLimit}) {
    final result = Language().fullParser.handler(
        input,
        0,
        FullParserOpts(
            nestLimit: nestLimit ?? 20,
            nestBudget: input.length * 20 + 1000,
            depth: 0,
            linkLabel: false,
            trace: false)) as Success;

    final res = mergeText(result.value);
    return res;
  }

  /// parse limited syntax.
  /// it will parse text or emoji.
  List<MfmNode> parseSimple(String input) {
    final result = Language().simpleParser.handler(
        input,
        0,
        FullParserOpts(
            nestLimit: 20,
            depth: 0,
            linkLabel: false,
            trace: false)) as Success;
    return mergeText(result.value);
  }
}

class FullParserOpts {
  int nestLimit;
  int? nestBudget;
  int depth;
  bool linkLabel;
  bool trace;
  Map<Parser, Map<String, Span>>? untilSpans;
  Map<Parser, Map<String, Map<int, Set<int>>>>? manyThenFailures;

  FullParserOpts(
      {required this.nestLimit,
      this.nestBudget,
      required this.depth,
      required this.linkLabel,
      required this.trace,
      this.untilSpans,
      this.manyThenFailures});
}
