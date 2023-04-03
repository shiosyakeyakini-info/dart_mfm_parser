import 'package:mfm/mfm.dart';
import 'package:test/scaffolding.dart';

String indent(int indent) {
  var result = "";
  for(var i=0;i<indent;i++) {
    result += "  ";
  }
  return result;
}

void printNode(List<MfmNode> nodes, {int depth = 0}) {
  for(final node in nodes) {
    final prop2 = node.props;
    prop2?.removeWhere((key, _) => key == "children");

    print("${indent(depth)}${node.type} ${prop2?.toString().replaceAll("\n", "\\n") ?? ""}");
    final children = node.children;
    if(children != null) {
      printNode(children, depth: depth + 1);
    }
  }
}

void main() {
  test("test", (){

    final parseResult = MfmParser().parse(r"""
ヤツメ漱石
""");

printNode(parseResult);

  });
}