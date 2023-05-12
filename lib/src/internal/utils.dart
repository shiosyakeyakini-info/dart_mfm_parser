import 'package:mfm_parser/src/node.dart';

List<MfmNode> mergeText(List nodes) {
  final List<MfmNode> dest = <MfmNode>[];
  final List<String> storedChars = <String>[];

  void generateText() {
    if (storedChars.isNotEmpty) {
      dest.add(MfmText(storedChars.join("")));
      storedChars.clear();
    }
  }

  for (final node in nodes) {
    if (node is String) {
      storedChars.add(node);
    } else if (node is! List && node.type == "text") {
      storedChars.add((node as MfmText).text);
    } else {
      generateText();
      if (node is List) {
        var str = "";
        for (final nodeElement in node) {
          if (nodeElement is String) {
            str += nodeElement;
          } else if (nodeElement is MfmNode) {
            dest.add(MfmText(str));
            str = "";
            dest.add(nodeElement);
          }
        }
        if (str != "") {
          dest.add(MfmText(str));
        }
      } else {
        dest.add(node);
      }
    }
  }
  generateText();

  return dest;
}
