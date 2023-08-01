import 'package:collection/collection.dart';

/// Misskey Elements Base Node
abstract class MfmNode {
  /// node type.
  final String type;

  /// elements property. it is compatible for typescript one.
  final Map<String, dynamic>? props;

  /// if node has child, will be array.
  final List<MfmNode>? children;

  MfmNode({required this.type, this.props, this.children});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is MfmNode) {
      return runtimeType == other.runtimeType &&
          type == other.type &&
          const DeepCollectionEquality().equals(props, other.props) &&
          const DeepCollectionEquality().equals(children, other.children);
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(type, props, children);

  @override
  String toString() {
    return "$type (props: ${(props?.entries.toString().replaceAll("\n", "\\n") ?? "")}, children: ${(children ?? "")})";
  }
}

abstract class MfmSimpleNode extends MfmNode {
  MfmSimpleNode({required super.type, super.props, super.children});
}

abstract class MfmBlock extends MfmNode {
  MfmBlock({required super.type, super.props, super.children});
}

abstract class MfmInline extends MfmSimpleNode {
  MfmInline({required super.type, super.props, super.children});
}

/// Quote Node
class MfmQuote extends MfmBlock {
  MfmQuote({required super.children}) : super(type: "quote");
}

/// Search Node
/// [query] is search query
class MfmSearch extends MfmBlock {
  final String query;
  final String content;
  MfmSearch(this.query, this.content)
      : super(type: "search", props: {"query": query, "content": content});
}

/// Code Block Node
class MfmCodeBlock extends MfmBlock {
  final String code;
  final String? lang;
  MfmCodeBlock(this.code, this.lang)
      : super(type: "blockCode", props: {"code": code, "lang": lang});
}

class MfmMathBlock extends MfmBlock {
  final String formula;
  MfmMathBlock(this.formula)
      : super(type: "MfmMathBlock", props: {"formula": formula});
}

/// Centering Node
class MfmCenter extends MfmBlock {
  MfmCenter({super.children}) : super(type: "center");
}

/// Unicode Emoji Node
class MfmUnicodeEmoji extends MfmInline {
  final String emoji;
  MfmUnicodeEmoji(this.emoji)
      : super(type: "unicodeEmoji", props: {"emoji": emoji});
}

/// Misskey style Emoji Node
class MfmEmojiCode extends MfmInline {
  final String name;
  MfmEmojiCode(this.name) : super(type: "emojiCode", props: {"name": name});
}

/// Bold Element Node
class MfmBold extends MfmInline {
  MfmBold(List<MfmInline> children) : super(type: "bold", children: children);
}

/// Small Element Node
class MfmSmall extends MfmInline {
  MfmSmall(List<MfmInline> children) : super(type: "small", children: children);
}

/// Italic Element Node
class MfmItalic extends MfmInline {
  MfmItalic(List<MfmInline> children)
      : super(type: "small", children: children);
}

/// Strike Element Node
class MfmStrike extends MfmInline {
  MfmStrike(List<MfmInline> children)
      : super(type: "strike", children: children);
}

/// Plain Element Node
///
/// text will be unapplicated misskey element.
class MfmPlain extends MfmInline {
  final String text;
  MfmPlain(this.text) : super(type: "plain", children: [MfmText(text)]);
}

/// Misskey Style Function Node
///
/// `$[position.x=3 something]` will be
/// `MfmFn(name: position, arg: {"x": "3"}, children: MfmText(something))`
class MfmFn extends MfmInline {
  final String name;
  final Map<String, dynamic> args;

  MfmFn({required this.name, required this.args, super.children})
      : super(type: "fn", props: {"name": name, "args": args});
}

/// Inline Code Node
class MfmInlineCode extends MfmInline {
  final String code;
  MfmInlineCode({required this.code})
      : super(type: "inlineCode", props: {"code": code});
}

class MfmMathInline extends MfmInline {
  final String formula;
  MfmMathInline({required this.formula})
      : super(type: "mathInline", props: {"formula": formula});
}

/// Basically Text Node
class MfmText extends MfmInline {
  final String text;
  MfmText(this.text) : super(type: "text", props: {"text": text});
}

/// Mention Node
///
/// `@ai` will be MfmMention(username: "ai", acct: "@ai")
///
/// `@ai@misskey.io` will be `MfmMention(username: "ai", host: "misskey.io", acct: "@ai@misskey.io")`
class MfmMention extends MfmInline {
  final String username;
  final String? host;
  final String acct;

  MfmMention(this.username, this.host, this.acct)
      : super(
            type: "mention",
            props: {"username": username, "host": host, "acct": acct});
}

/// Hashtag Node
class MfmHashTag extends MfmInline {
  final String hashTag;
  MfmHashTag(this.hashTag)
      : super(type: "hashtag", props: {"hashtag": hashTag});
}

/// Link Node
///
/// if [silent] is true, will not display url.
class MfmLink extends MfmInline {
  final String url;
  final bool silent;

  MfmLink({required this.silent, required this.url, super.children})
      : super(
          type: "link",
          props: {"silent": silent, "url": url},
        );
}

/// URL Node
///
/// if brackets is true, will display "<https://...>"
class MfmURL extends MfmInline {
  final String value;
  final bool? brackets;

  MfmURL(this.value, this.brackets)
      : super(type: "url", props: {
          "url": value,
          "brackets": brackets,
        });
}
