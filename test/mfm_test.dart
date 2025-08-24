import 'package:mfm_parser/src/mfm_parser.dart';
import 'package:mfm_parser/src/node.dart';
import 'package:test/test.dart';

void main() {
  final parse = MfmParser().parse;

  group("SimpleParser", () {
    group("text", () {
      test("basic", () {
        const input = "abc";
        final output = [MfmText("abc")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });

      test("ignore hashtag", () {
        final input = "abc#abc";
        final output = [MfmText("abc#abc")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });
      test("keycap number sign", () {
        final input = "abc#️⃣abc";
        final output = [MfmText("abc"), MfmUnicodeEmoji("#️⃣"), MfmText("abc")];

        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });
    });

    group("emoji", () {
      test("basic", () {
        const input = ":foo:";
        final output = [MfmEmojiCode("foo")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });

      test("between texts", () {
        const input = "foo:bar:baz";
        final output = [MfmText("foo:bar:baz")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });

      test("between text 2", () {
        const input = "12:34:56";
        final output = [MfmText("12:34:56")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });

      test("between text 3", () {
        const input = "あ:bar:い";
        final output = [MfmText("あ"), MfmEmojiCode("bar"), MfmText("い")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });

      test("ignore variation selecter", () {
        const input = "\uFE0F";
        final output = [MfmText("\uFE0F")];
        expect(MfmParser().parseSimple(input), orderedEquals(output));
      });
    });

    test("disallow other syntaxes", () {
      const input = "foo **bar** baz";
      final output = [MfmText("foo **bar** baz")];
      expect(MfmParser().parseSimple(input), orderedEquals(output));
    });
  });

  group("FullParser", () {
    group("text", () {
      test("普通のテキストを入力すると1つのテキストノードが返される", () {
        const input = "abc";
        final output = [MfmText("abc")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("quote", () {
      test("1行の引用ブロックを使用できる", () {
        const input = "> abc";
        final output = [
          MfmQuote(children: [MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("複数行の引用ブロックを使用できる", () {
        const input = """
> abc
> 123
""";
        final output = [
          MfmQuote(children: [MfmText("abc\n123")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックはブロックをネストできる", () {
        const input = """
> <center>
> a
> </center>
""";
        final output = [
          MfmQuote(children: [
            MfmCenter(children: [MfmText("a")])
          ]),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックはインライン構文を含んだブロックをネストできる", () {
        const input = r"""
> <center>
> I'm @ai, An bot of misskey!
> </center>
""";
        final output = [
          MfmQuote(children: [
            MfmCenter(children: [
              MfmText("I'm "),
              MfmMention("ai", null, "@ai"),
              MfmText(", An bot of misskey!"),
            ])
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("複数行の引用ブロックでは空行を含めることができる", () {
        final input = r"""
> abc
>
> 123
""";
        final output = [
          MfmQuote(children: [MfmText("abc\n\n123")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("1行の引用ブロックを空行にはできない", () {
        final input = "> ";
        final output = [MfmText("> ")];
        expect(parse(input), orderedEquals(output));
      });

      test("引用ブロックの後ろの空行は無視される", () {
        final input = r"""
> foo
> bar

hoge""";
        final output = [
          MfmQuote(children: [MfmText("foo\nbar")]),
          MfmText("hoge")
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("2つの引用行の間に空行がある場合は2つの引用ブロックが生成される", () {
        final input = r"""
> foo

> bar

hoge""";
        final output = [
          MfmQuote(children: [MfmText("foo")]),
          MfmQuote(children: [MfmText("bar")]),
          MfmText("hoge")
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("引用中にハッシュタグがある場合", () {
        final input = "> before #abc after";
        final output = [
          MfmQuote(children: [
            MfmText("before "),
            MfmHashTag("abc"),
            MfmText(" after"),
          ])
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("search", () {
      group("検索構文を使用できる", () {
        test("Search", () {
          final input = "MFM 書き方 123 Search";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
        test("[Search]", () {
          final input = "MFM 書き方 123 [Search]";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
        test("search", () {
          final input = "MFM 書き方 123 search";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
        test("[search]", () {
          final input = "MFM 書き方 123 [search]";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
        test("検索", () {
          final input = "MFM 書き方 123 検索";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
        test("[検索]", () {
          final input = "MFM 書き方 123 [検索]";
          final output = [MfmSearch("MFM 書き方 123", input)];
          expect(parse(input), output);
        });
      });
      test("ブロックの前後にあるテキストが正しく解釈される", () {
        final input = "abc\nhoge piyo bebeyo 検索\n123";
        final output = [
          MfmText("abc"),
          MfmSearch("hoge piyo bebeyo", "hoge piyo bebeyo 検索"),
          MfmText("123")
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("code block", () {
      test("コードブロックを使用できる", () {
        final input = "```\nabc\n```";
        final output = [MfmCodeBlock("abc", null)];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックには複数行のコードを入力できる", () {
        final input = "```\na\nb\nc\n```";
        final output = [MfmCodeBlock("a\nb\nc", null)];
        expect(parse(input), orderedEquals(output));
      });

      test("コードブロックは言語を指定できる", () {
        final input = "```js\nconst a = 1;\n```";
        final output = [
          MfmCodeBlock("const a = 1;", "js"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        final input = "abc\n```\nconst abc = 1;\n```\n123";
        final output = [
          MfmText("abc"),
          MfmCodeBlock("const abc = 1;", null),
          MfmText("123")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore internal marker", () {
        final input = "```\naaa```bbb\n```";
        final output = [MfmCodeBlock("aaa```bbb", null)];

        expect(parse(input), orderedEquals(output));
      });

      test("trim after line break", () {
        final input = "```\nfoo\n```\nbar";
        final output = [MfmCodeBlock("foo", null), MfmText("bar")];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("mathBlock", () {
      test("1行の数式ブロックを使用できる", () {
        final input = r"\[math1\]";
        final output = [MfmMathBlock("math1")];
        expect(parse(input), orderedEquals(output));
      });

      test("ブロックの前後にあるテキストが正しく解釈される", () {
        final input = "abc\n\\[math1\\]\n123";
        final output = [MfmText("abc"), MfmMathBlock("math1"), MfmText("123")];
        expect(parse(input), orderedEquals(output));
      });

      test("行末以外に閉じタグがある場合はマッチしない", () {
        final input = r"\[aaa\]after";
        final output = [MfmText(r"\[aaa\]after")];
        expect(parse(input), orderedEquals(output));
      });

      test("行頭以外に開始タグがある場合はマッチしない", () {
        final input = r"before\[aaa\]";
        final output = [MfmText(r"before\[aaa\]")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("center", () {
      test("single text", () {
        final input = "<center>abc</center>";
        final output = [
          MfmCenter(children: [MfmText("abc")])
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("multiple text", () {
        final input = "before\n<center>\nabc\n123\npiyo\n</center>\nafter";
        final output = [
          MfmText("before"),
          MfmCenter(children: [MfmText("abc\n123\npiyo")]),
          MfmText("after")
        ];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("emoji code", () {
      test("basic", () {
        final input = ":abc:";
        final output = [MfmEmojiCode("abc")];

        expect(parse(input), orderedEquals(output));
      });
    });

    group("unicode emoji", () {
      test("basic", () {
        final input = "今起きた😇";
        final output = [MfmText("今起きた"), MfmUnicodeEmoji("😇")];
        expect(parse(input), output);
      });

      test("keycap number sign", () {
        final input = "abc#️⃣123";
        final output = [MfmText("abc"), MfmUnicodeEmoji("#️⃣"), MfmText("123")];
        expect(parse(input), output);
      });

      test("Unicode 15.0", () {
        final input = "🫨🩷🫷🫎🪽🪻🫚🪭🪇🪯🛜";
        final output = [
          MfmUnicodeEmoji("🫨"),
          MfmUnicodeEmoji("🩷"),
          MfmUnicodeEmoji("🫷"),
          MfmUnicodeEmoji("🫎"),
          MfmUnicodeEmoji("🪽"),
          MfmUnicodeEmoji("🪻"),
          MfmUnicodeEmoji("🫚"),
          MfmUnicodeEmoji("🪭"),
          MfmUnicodeEmoji("🪇"),
          MfmUnicodeEmoji("🪯"),
          MfmUnicodeEmoji("🛜"),
        ];
        expect(parse(input), output);
      });
    });

    group("big", () {
      test("basic", () {
        final input = "***abc***";
        final output = [
          MfmFn(name: "tada", args: {}, children: [MfmText("abc")])
        ];

        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        final input = "***123**abc**123***";
        final output = [
          MfmFn(name: "tada", args: {}, children: [
            MfmText("123"),
            MfmBold([MfmText("abc")]),
            MfmText("123")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("内容は改行できる", () {
        final input = "***123\n**abc**\n123***";
        final output = [
          MfmFn(name: "tada", args: {}, children: [
            MfmText("123\n"),
            MfmBold([MfmText("abc")]),
            MfmText("\n123")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold tag", () {
      test("basic", () {
        final input = "<b>abc</b>";
        final output = [
          MfmBold([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("inline syntax allowed inside", () {
        final input = "<b>123~~abc~~123</b>";
        final output = [
          MfmBold([
            MfmText("123"),
            MfmStrike([MfmText("abc")]),
            MfmText("123"),
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("line breaks", () {
        final input = "<b>123\n~~abc~~\n123</b>";
        final output = [
          MfmBold([
            MfmText("123\n"),
            MfmStrike([MfmText("abc")]),
            MfmText("\n123"),
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("bold", () {
      test("basic", () {
        final input = "**abc**";
        final output = [
          MfmBold([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("内容にはインライン構文を利用できる", () {
        final input = "**123~~abc~~123**";
        final output = [
          MfmBold([
            MfmText("123"),
            MfmStrike([MfmText("abc")]),
            MfmText("123"),
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("内容は改行できる", () {
        final input = "**123\n~~abc~~\n123**";
        final output = [
          MfmBold([
            MfmText("123\n"),
            MfmStrike([MfmText("abc")]),
            MfmText("\n123")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("small", () {
      test("basic", () {
        final input = "<small>abc</small>";
        final output = [
          MfmSmall([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容にはインライン構文を利用できる", () {
        final input = "<small>abc**123**abc</small>";
        final output = [
          MfmSmall([
            MfmText("abc"),
            MfmBold([MfmText("123")]),
            MfmText("abc")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("内容は改行できる", () {
        final input = "<small>abc\n**123**\nabc</small>";
        final output = [
          MfmSmall([
            MfmText("abc\n"),
            MfmBold([MfmText("123")]),
            MfmText("\nabc")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic tag", () {
      test("basic", () {
        final input = "<i>abc</i>";
        final output = [
          MfmItalic([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("内容にはインライン構文を利用できる", () {
        final input = "<i>abc**123**abc</i>";
        final output = [
          MfmItalic([
            MfmText("abc"),
            MfmBold([MfmText("123")]),
            MfmText("abc")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("内容は改行できる", () {
        final input = "<i>abc\n**123**\nabc</i>";
        final output = [
          MfmItalic([
            MfmText("abc\n"),
            MfmBold([MfmText("123")]),
            MfmText("\nabc")
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("italic alt 1", () {
      test("basic", () {
        final input = "*abc*";
        final output = [
          MfmItalic([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("basic 2", () {
        final input = "before *abc* after";
        final output = [
          MfmText("before "),
          MfmItalic([MfmText("abc")]),
          MfmText(" after"),
        ];
        expect(parse(input), orderedEquals(output));
      });
      test(
          "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
          () {
        final input = "before*abc*after";
        final output = [MfmText("before*abc*after")];
        expect(parse(input), orderedEquals(output));

        final input2 = "あいう*abc*えお";
        final output2 = [
          MfmText("あいう"),
          MfmItalic([MfmText("abc")]),
          MfmText("えお")
        ];
        expect(parse(input2), orderedEquals(output2));
      });
    });

    group("italic alt 2", () {
      test("basic", () {
        final input = "_abc_";
        final output = [
          MfmItalic([MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });
      test("basic 2", () {
        final input = "before _abc_ after";
        final output = [
          MfmText("before "),
          MfmItalic([MfmText("abc")]),
          MfmText(" after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
          "ignore a italic syntax if the before char is either a space nor an LF nor [^a-z0-9]i",
          () {
        final input = "before_abc_after";
        final output = [MfmText("before_abc_after")];
        expect(parse(input), orderedEquals(output));

        final input2 = "あいう_abc_えお";
        final output2 = [
          MfmText("あいう"),
          MfmItalic([MfmText("abc")]),
          MfmText("えお")
        ];
        expect(parse(input2), orderedEquals(output2));
      });
    });

    group("strike tag", () {
      test("basic", () {
        final input = "<s>foo</s>";
        final output = [
          MfmStrike([MfmText("foo")])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("strike", () {
      test("basic", () {
        final input = "~~foo~~";
        final output = [
          MfmStrike([MfmText("foo")])
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("inlineCode", () {
      test("basic", () {
        final input = '`var x = "Strawberry Crisis";`';
        final output = [MfmInlineCode(code: 'var x = "Strawberry Crisis";')];
        expect(parse(input), output);
      });

      test("disallow line break", () {
        final input = "`foo\nbar`";
        final output = [MfmText("`foo\nbar`")];
        expect(parse(input), output);
      });

      test("disallow ´", () {
        final input = "`foo´bar`";
        final output = [MfmText("`foo´bar`")];
        expect(parse(input), output);
      });
    });

    group("mathInline", () {
      test("basic", () {
        final input = '\\(x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}\\)';
        final output = [
          MfmMathInline(formula: 'x = {-b \\pm \\sqrt{b^2-4ac} \\over 2a}')
        ];
        expect(parse(input), output);
      });
    });

    group("mention", () {
      test("basic", () {
        final input = "@abc";
        final output = [MfmMention("abc", null, "@abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        final input = "before @abc after";
        final output = [
          MfmText("before "),
          MfmMention("abc", null, "@abc"),
          MfmText(" after")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote", () {
        final input = "@abc@misskey.io";
        final output = [MfmMention("abc", "misskey.io", "@abc@misskey.io")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 2", () {
        final input = "before @abc@misskey.io after";
        final output = [
          MfmText("before "),
          MfmMention("abc", "misskey.io", "@abc@misskey.io"),
          MfmText(" after"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("basic remote 3", () {
        final input = "before\n@abc@misskey.io\nafter";
        final output = [
          MfmText("before\n"),
          MfmMention("abc", "misskey.io", "@abc@misskey.io"),
          MfmText("\nafter"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore format of mail address", () {
        final input = "abc@example.com";
        final output = [MfmText("abc@example.com")];
        expect(parse(input), orderedEquals(output));
      });

      test("detect as a mention if the before char is [^a-z0-9]i", () {
        final input = "あいう@abc";
        final output = [MfmText("あいう"), MfmMention("abc", null, "@abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only username", () {
        final input = "@-";
        final output = [MfmText("@-")];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid char only hostname", () {
        final input = "@abc@.";
        final output = [MfmText("@abc@.")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `-` in username", () {
        final input = "@abc-d";
        final output = [MfmMention("abc-d", null, "@abc-d")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of username", () {
        final input = "@-abc";
        final output = [MfmText("@-abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        final input = "@abc-";
        final output = [MfmMention("abc", null, "@abc"), MfmText("-")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow `.` in middle of username", () {
        final input = "@a.bc";
        final output = [MfmMention("a.bc", null, "@a.bc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of username", () {
        final input = "@.abc";
        final output = [MfmText("@.abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of username", () {
        final input = "@abc.";
        final output = [MfmMention("abc", null, "@abc"), MfmText(".")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in head of hostname", () {
        final input = "@abc@.aaa";
        final output = [MfmText("@abc@.aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `.` in tail of hostname", () {
        final input = "@abc@aaa.";
        final output = [MfmMention("abc", "aaa", "@abc@aaa"), MfmText(".")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in head of hostname", () {
        final input = "@abc@-aaa";
        final output = [MfmText("@abc@-aaa")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow `-` in tail of username", () {
        final input = "@abc@aaa-";
        final output = [MfmMention("abc", "aaa", "@abc@aaa"), MfmText("-")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("hashtag", () {
      test("basic", () {
        final input = "#abc";
        final output = [MfmHashTag("abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("basic 2", () {
        final input = "before #abc after";
        final output = [
          MfmText("before "),
          MfmHashTag("abc"),
          MfmText(" after")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign", () {
        final input = "#️⃣abc123 #abc";
        final output = [
          MfmUnicodeEmoji("#️⃣"),
          MfmText("abc123 "),
          MfmHashTag("abc")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with keycap number sign 2", () {
        final input = "abc\n#️⃣abc";
        final output = [
          MfmText("abc\n"),
          MfmUnicodeEmoji("#️⃣"),
          MfmText("abc")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test(
          "ignore a hashtag if the before char is neither a space nor an LF nor [^a-z0-9]i",
          () {
        final input = "abc#abc";
        final output = [MfmText("abc#abc")];
        expect(parse(input), orderedEquals(output));

        final input2 = "あいう#abc";
        final output2 = [MfmText("あいう"), MfmHashTag("abc")];
        expect(parse(input2), orderedEquals(output2));
      });

      test("ignore comma and period", () {
        final input = "Foo #bar, baz #piyo.";
        final output = [
          MfmText("Foo "),
          MfmHashTag("bar"),
          MfmText(", baz "),
          MfmHashTag("piyo"),
          MfmText(".")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore exclamation mark", () {
        final input = "#Foo!";
        final output = [MfmHashTag("Foo"), MfmText("!")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore colon", () {
        final input = "#Foo:";
        final output = [MfmHashTag("Foo"), MfmText(":")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore single quote", () {
        final input = "#Foo'";
        final output = [MfmHashTag("Foo"), MfmText("'")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore double quote", () {
        final input = "#Foo\"";
        final output = [MfmHashTag("Foo"), MfmText("\"")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore square bracket", () {
        final input = "#Foo]";
        final output = [MfmHashTag("Foo"), MfmText("]")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore slash", () {
        final input = "#Foo/bar";
        final output = [MfmHashTag("Foo"), MfmText("/bar")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore angle bracket", () {
        final input = "#Foo<bar>";
        final output = [MfmHashTag("Foo"), MfmText("<bar>")];
        expect(parse(input), orderedEquals(output));
      });

      test("allow including number", () {
        final input = "#foo123";
        final output = [MfmHashTag("foo123")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets ()", () {
        final input = "(#foo)";
        final output = [MfmText("("), MfmHashTag("foo"), MfmText(")")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」", () {
        final input = "「#foo」";
        final output = [MfmText("「"), MfmHashTag("foo"), MfmText("」")];
        expect(parse(input), orderedEquals(output));
      });

      test("with mix brackets", () {
        final input = "「#foo(bar)」";
        final output = [MfmText("「"), MfmHashTag("foo(bar)"), MfmText("」")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets () (space before)", () {
        final input = "(bar #foo)";
        final output = [MfmText("(bar "), MfmHashTag("foo"), MfmText(")")];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets 「」(space before)", () {
        final input = "「bar #foo」";
        final output = [MfmText("「bar "), MfmHashTag("foo"), MfmText("」")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only", () {
        final input = "#123";
        final output = [MfmText("#123")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow number only (with brackets)", () {
        final input = "(#123)";
        final output = [MfmText("(#123)")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("url", () {
      test("basic", () {
        final input = "https://misskey.io/@ai";
        final output = [MfmURL("https://misskey.io/@ai", false)];
        expect(parse(input), orderedEquals(output));
      });

      test("with other texts", () {
        final input = "official instance: https://misskey.io/@ai.";
        final output = [
          MfmText("official instance: "),
          MfmURL("https://misskey.io/@ai", false),
          MfmText(".")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing period", () {
        final input = "https://misskey.io/@ai.";
        final output = [MfmURL("https://misskey.io/@ai", false), MfmText(".")];
        expect(parse(input), orderedEquals(output));
      });

      test("disallow period only.", () {
        final input = "https://.";
        final output = [MfmText("https://.")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore trailing periods", () {
        final input = "https://misskey.io/@ai...";
        final output = [
          MfmURL("https://misskey.io/@ai", false),
          MfmText("...")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets", () {
        final input = "https://example.com/foo(bar)";
        final output = [MfmURL("https://example.com/foo(bar)", false)];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets", () {
        final input = "(https://example.com/foo)";
        final output = [
          MfmText("("),
          MfmURL("https://example.com/foo", false),
          MfmText(")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets(2)", () {
        final input = "(foo https://example.com/foo)";
        final output = [
          MfmText("(foo "),
          MfmURL("https://example.com/foo", false),
          MfmText(")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent brackets with internal brackets", () {
        final input = "(https://example.com/foo(bar))";
        final output = [
          MfmText("("),
          MfmURL("https://example.com/foo(bar)", false),
          MfmText(")"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore parent []", () {
        final input = "foo [https://example.com/foo] bar";
        final output = [
          MfmText("foo ["),
          MfmURL("https://example.com/foo", false),
          MfmText("] bar"),
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore non-ascii characters contained url without angle brackets",
          () {
        final input =
            "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com";
        final output = [
          MfmText(
              "https://たまにポプカルやシャマレと一緒にいることもあるどうか忘れないでほしいスズランは我らの光であり.example.com")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("match non-ascii characters contained url with angle brackets", () {
        final input = "<https://こいしちゃんするやつ.example.com>";
        final output = [MfmURL("https://こいしちゃんするやつ.example.com", true)];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        final input = "javascript:foo";
        final output = [MfmText("javascript:foo")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("link", () {
      test("basic", () {
        final input = "[official instance](https://misskey.io/@ai).";
        final output = [
          MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText("official instance")]),
          MfmText(".")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("silent flag", () {
        final input = "?[official instance](https://misskey.io/@ai).";
        final output = [
          MfmLink(
              silent: true,
              url: "https://misskey.io/@ai",
              children: [MfmText("official instance")]),
          MfmText(".")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with angle brackets url", () {
        final input = "[official instance](<https://misskey.io/@ai>).";
        final output = [
          MfmLink(
              silent: false,
              url: "https://misskey.io/@ai",
              children: [MfmText("official instance")]),
          MfmText(".")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("prevent xss", () {
        final input = "[click here](javascript:foo)";
        final output = [MfmText("[click here](javascript:foo)")];
        expect(parse(input), orderedEquals(output));
      });

      group("cannot nest a url in a link label", () {
        test("basic", () {
          final input =
              "official instance: [https://misskey.io/@ai](https://misskey.io/@ai).";
          final output = [
            MfmText("official instance: "),
            MfmLink(
                silent: false,
                url: "https://misskey.io/@ai",
                children: [MfmText("https://misskey.io/@ai")]),
            MfmText("."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          final input =
              "official instance: [https://misskey.io/@ai**https://misskey.io/@ai**](https://misskey.io/@ai).";
          final output = [
            MfmText("official instance: "),
            MfmLink(silent: false, url: "https://misskey.io/@ai", children: [
              MfmText("https://misskey.io/@ai"),
              MfmBold([MfmText("https://misskey.io/@ai")])
            ]),
            MfmText("."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a link in a link label", () {
        test("basic", () {
          final input =
              "official instance: [[https://misskey.io/@ai](https://misskey.io/@ai)](https://misskey.io/@ai).";
          final output = [
            MfmText("official instance: "),
            MfmLink(
                silent: false,
                url: "https://misskey.io/@ai",
                children: [MfmText("[https://misskey.io/@ai")]),
            MfmText("]("),
            MfmURL("https://misskey.io/@ai", false),
            MfmText(")."),
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          final input =
              "official instance: [**[https://misskey.io/@ai](https://misskey.io/@ai)**](https://misskey.io/@ai).";
          final output = [
            MfmText("official instance: "),
            MfmLink(silent: false, url: "https://misskey.io/@ai", children: [
              MfmBold(
                  [MfmText("[https://misskey.io/@ai](https://misskey.io/@ai)")])
            ]),
            MfmText("."),
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      group("cannot nest a mention in a link label", () {
        test("basic", () {
          final input = "[@example](https://example.com)";
          final output = [
            MfmLink(
                silent: false,
                url: "https://example.com",
                children: [MfmText("@example")])
          ];
          expect(parse(input), orderedEquals(output));
        });

        test("nested", () {
          final input = "[@example**@example**](https://example.com)";
          final output = [
            MfmLink(silent: false, url: "https://example.com", children: [
              MfmText("@example"),
              MfmBold([MfmText("@example")])
            ])
          ];
          expect(parse(input), orderedEquals(output));
        });
      });

      test("with brackets", () {
        final input = "[foo](https://example.com/foo(bar))";
        final output = [
          MfmLink(
              silent: false,
              url: "https://example.com/foo(bar)",
              children: [MfmText("foo")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with parent brackets", () {
        final input = "([foo](https://example.com/foo(bar)))";
        final output = [
          MfmText("("),
          MfmLink(
              silent: false,
              url: "https://example.com/foo(bar)",
              children: [MfmText("foo")]),
          MfmText(")")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with brackets before", () {
        final input = "[test] foo [bar](https://example.com)";
        final output = [
          MfmText("[test] foo "),
          MfmLink(silent: false, url: "https://example.com", children: [
            MfmText("bar"),
          ])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test('bad url in url part', () {
        const input = "[test](http://..)";
        final output = [MfmText("[test](http://..)")];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("fn", () {
      test("basic", () {
        final input = r"$[tada abc]";
        final output = [
          MfmFn(name: "tada", args: {}, children: [MfmText("abc")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments", () {
        final input = r"$[spin.speed=1.1s a]";
        final output = [
          MfmFn(name: "spin", args: {"speed": "1.1s"}, children: [MfmText("a")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("with a string arguments 2", () {
        final input = r"$[position.x=-3 a]";
        final output = [
          MfmFn(name: "position", args: {"x": "-3"}, children: [MfmText("a")])
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("invalid fn name", () {
        final input = r"$[関数 text]";
        final output = [MfmText(r"$[関数 text]")];
        expect(parse(input), orderedEquals(output));
      });

      test("nest", () {
        final input = r"$[spin.speed=1.1s $[shake a]]";
        final output = [
          MfmFn(
            name: "spin",
            args: {"speed": "1.1s"},
            children: [
              MfmFn(name: "shake", args: {}, children: [MfmText("a")]),
            ],
          ),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("plain", () {
      test("multiple line", () {
        final input = "a\n<plain>\n**Hello**\nworld\n</plain>\nb";
        final output = [
          MfmText("a\n"),
          MfmPlain("**Hello**\nworld"),
          MfmText("\nb")
        ];
        expect(parse(input), orderedEquals(output));
      });

      test("single line", () {
        final input = "a\n<plain>**Hello** world</plain>\nb";
        final output = [
          MfmText("a\n"),
          MfmPlain("**Hello** world"),
          MfmText("\nb"),
        ];
        expect(parse(input), orderedEquals(output));
      });
    });

    group("nesting limit", () {
      group("quote", () {
        test("basic", () {
          final input = ">>> abc";
          final output = [
            MfmQuote(children: [
              MfmQuote(children: [
                MfmText("> abc"),
              ])
            ]),
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("basic 2", () {
          final input = ">> **abc**";
          final output = [
            MfmQuote(children: [
              MfmQuote(children: [
                MfmText("**abc**"),
              ])
            ])
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      test("big", () {
        final input = "<b><b>***abc***</b></b>";
        final output = [
          MfmBold([
            MfmBold([
              MfmText("***abc***"),
            ])
          ])
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      group("bold", () {
        test("basic", () {
          final input = "<i><i>**abc**</i></i>";
          final output = [
            MfmItalic([
              MfmItalic([
                MfmText("**abc**"),
              ])
            ])
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          final input = "<i><i><b>abc</b></i></i>";
          final output = [
            MfmItalic([
              MfmItalic([
                MfmText("<b>abc</b>"),
              ])
            ])
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      test("small", () {
        final input = "<i><i><small>abc</small></i></i>";
        final output = [
          MfmItalic([
            MfmItalic([
              MfmText("<small>abc</small>"),
            ])
          ])
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      test("italic", () {
        final input = "<b><b><i>abc</i></b></b>";
        final output = [
          MfmBold([
            MfmBold([
              MfmText("<i>abc</i>"),
            ])
          ])
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));
      });

      group("strike", () {
        test("basic", () {
          final input = "<b><b>~~abc~~</b></b>";
          final output = [
            MfmBold([
              MfmBold([
                MfmText("~~abc~~"),
              ])
            ])
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });

        test("tag", () {
          final input = "<b><b><s>abc</s></b></b>";
          final output = [
            MfmBold([
              MfmBold([MfmText("<s>abc</s>")])
            ])
          ];
          expect(parse(input, nestLimit: 2), orderedEquals(output));
        });
      });

      group("hashtag", () {
        test("basic", () {
          final input = "<b>#abc(xyz)</b>";
          final output = [
            MfmBold([MfmHashTag("abc(xyz)")])
          ];
          expect(parse(input, nestLimit: 2), output);

          final input2 = "<b>#abc(x(y)z)</b>";
          final output2 = [
            MfmBold([MfmHashTag("abc"), MfmText("(x(y)z)")])
          ];
          expect(parse(input2, nestLimit: 2), output2);
        });

        test("outside ()", () {
          final input = "(#abc)";
          final output = [MfmText("("), MfmHashTag("abc"), MfmText(")")];
          expect(parse(input), orderedEquals(output));
        });

        test("outside []", () {
          final input = "[#abc]";
          final output = [MfmText("["), MfmHashTag("abc"), MfmText("]")];
          expect(parse(input), orderedEquals(output));
        });

        test("outside 「」", () {
          final input = "「#abc」";
          final output = [MfmText("「"), MfmHashTag("abc"), MfmText("」")];
          expect(parse(input), orderedEquals(output));
        });

        test("outside ()", () {
          final input = "(#abc)";
          final output = [MfmText("("), MfmHashTag("abc"), MfmText(")")];
          expect(parse(input), orderedEquals(output));
        });
      });

      test("url", () {
        final input = "<b>https://example.com/abc(xyz)</b>";
        final output = [
          MfmBold([
            MfmURL("https://example.com/abc(xyz)", false),
          ])
        ];
        expect(parse(input, nestLimit: 2), orderedEquals(output));

        final input2 = "<b>https://example.com/abc(x(y)z)</b>";
        final output2 = [
          MfmBold([
            MfmURL("https://example.com/abc", false),
            MfmText("(x(y)z)"),
          ])
        ];
        expect(parse(input2, nestLimit: 2), output2);
      });

      test("fn", () {
        final input = r"<b><b>$[a b]</b></b>";
        final output = [
          MfmBold([
            MfmBold([
              MfmText(r"$[a b]"),
            ])
          ])
        ];
        expect(parse(input, nestLimit: 2), output);
      });
    });

    test("composite", () {
      final input = r"""before
<center>
Hello $[tada everynyan! 🎉]

I'm @ai, A bot of misskey!

https://github.com/syuilo/ai
</center>
after""";
      final output = [
        MfmText("before"),
        MfmCenter(children: [
          MfmText("Hello "),
          MfmFn(name: "tada", args: {}, children: [
            MfmText("everynyan! "),
            MfmUnicodeEmoji("🎉"),
          ]),
          MfmText("\n\nI'm "),
          MfmMention("ai", null, "@ai"),
          MfmText(", A bot of misskey!\n\n"),
          MfmURL("https://github.com/syuilo/ai", false)
        ]),
        MfmText("after"),
      ];

      expect(parse(input), orderedEquals(output));
    });
  });
}
