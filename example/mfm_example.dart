import 'package:mfm_parser/mfm_parser.dart';

void main() {
  final input = r"""
<center>$[x2 **Hello, Markup language For Misskey.**]</center>

$[x2 1. Feature]

1. mention, such as @example @username@example.com
2. hashtag, such as #something
3. custom emoji, such as custom emoji :something_emoji: and 🚀🚀🚀

  """;
  final List<MfmNode> parsed = MfmParser().parse(input);

  print(parsed);

  final userName = "🎂:ai_yay: momoi :ai_yay_fast:🎂@C100 Z-999";
  final List<MfmNode> parsedUserName = MfmParser().parseSimple(userName);

  print(parsedUserName);
}
