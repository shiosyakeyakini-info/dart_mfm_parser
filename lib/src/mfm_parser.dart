import 'package:mfm/src/internal/core/core.dart';
import 'package:mfm/src/internal/language.dart';
import 'package:mfm/src/internal/utils.dart';
import 'package:mfm/src/node.dart';

class MfmParser {
  static List<MfmNode> parse(String input, {int? nestLimit}) {
    final result = Language().fullParser.handler(
        input,
        0,
        FullParserOpts(
            nestLimit: nestLimit ?? 20,
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