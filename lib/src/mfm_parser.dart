import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/language.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/node.dart';

class MfmParser {
  const MfmParser();

  List<MfmNode> parse(String input, {int? nestLimit}) {
    final result = Language().fullParser.handler(
        input,
        0,
        FullParserOpts(
            nestLimit: nestLimit ?? 20,
            depth: 0,
            linkLabel: false,
            trace: false)) as Success;

    final res = mergeText(result.value);
    return res;
  }

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
  int depth;
  bool linkLabel;
  bool trace;

  FullParserOpts(
      {required this.nestLimit,
      required this.depth,
      required this.linkLabel,
      required this.trace});
}
