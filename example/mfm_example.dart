import 'package:mfm/mfm.dart';

void main() {
  final input = r"""

<center>$[x3 **Hello, Markup language For Misskey.]</center>

$[x2 1. Feature]

- mention, such as @example @username@example.com
- hashtag, such as #something
- custom emoji, such as custom emoji

  """;
  final List<MfmNode> parsedText = MfmParser.parse(input);

  print(parsedText);
  
}
