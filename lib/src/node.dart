

import 'package:collection/collection.dart';

abstract class MfmNode {
  final String type;
  final Map<String, dynamic>? props;
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
          const MapEquality().equals(props, other.props) &&
          const DeepCollectionEquality().equals(children, other.children);
    } else {
      return false;
    }
  }

  @override
  int get hashCode => Object.hash(type, props, children);
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

class MfmQuote extends MfmBlock {
  MfmQuote({required super.children}) : super(type: "quote");
}

class MfmSearch extends MfmBlock {
  MfmSearch(String query, String content)
      : super(type: "search", props: {"query": query, "content": content});
}

class MfmCodeBlock extends MfmBlock {
  final String code;
  final String? lang;
  MfmCodeBlock(this.code, this.lang)
      : super(type: "blockCode", props: {"code": code, "lang": lang});
}

class MfmCenter extends MfmBlock {
  MfmCenter(List<MfmInline> chilren) : super(type: "center", children: chilren);
}

class MfmEmojiCode extends MfmInline {
  final String name;
  MfmEmojiCode(this.name) : super(type: "emojiCode", props: {"name": name});
}

class MfmBold extends MfmInline {
  MfmBold(List<MfmInline> children) : super(type: "bold", children: children);
}

class MfmSmall extends MfmInline {
  MfmSmall(List<MfmInline> children) : super(type: "small", children: children);
}

class MfmItalic extends MfmInline {
  MfmItalic(List<MfmInline> children)
      : super(type: "small", children: children);
}

class MfmStrike extends MfmInline {
  MfmStrike(List<MfmInline> children)
      : super(type: "strike", children: children);
}

class MfmPlain extends MfmInline {
  final String text;
  MfmPlain(this.text) : super(type: "plain", children: [MfmText(text)]);
}

class MfmFn extends MfmInline {
  final String name;
  final Map<String, dynamic> args;

  MfmFn({required this.name, required this.args, super.children})
      : super(type: "fn", props: {"name": name, "args": args});
}

class MfmInlineCode extends MfmInline {
  final String code;
  MfmInlineCode({required this.code})
      : super(type: "inlineCode", props: {"code": code});
}

class MfmText extends MfmInline {
  final String text;
  MfmText(this.text) : super(type: "text", props: {"text": text});
}

class MfmMention extends MfmInline {
  final String username;
  final String? host;
  final String acct;

  MfmMention(this.username, this.host, this.acct)
      : super(
            type: "mention",
            props: {"username": username, "host": host, "acct": acct});
}
