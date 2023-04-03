// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:mfm/src/mfm_parser.dart';
import 'package:mfm/src/node.dart';
import 'package:test/test.dart';

void main() {
  final parse = MfmParser().parse;
  final equals = const DeepCollectionEquality().equals;

  group("SimpleParser", () {
    group("text", () {
      test("basic", () {
        const input = "abc";
        final output = [MfmText("abc")];
        expect(parse(input), orderedEquals(output));
      });

      test("ignore hashtag", () {
        // TODO
      });
      test("keycap number sign", () {
        // TODO
      });
    });

    group("emoji", () {
      test("basic", () {
        const input = ":foo:";
        final output = [MfmEmojiCode("foo")];
        expect(parse(input), orderedEquals(output));
      });

      test("between texts", () {
        const input = "foo:bar:baz";
        final output = [MfmText("foo:bar:baz")];
        expect(parse(input), orderedEquals(output));
      });

      test("between text 2", () {
        const input = "12:34:56";
        final output = [MfmText("12:34:56")];
        expect(parse(input), orderedEquals(output));
      });

      test("between text 3", () {
        const input = "あ:bar:い";
        final output = [MfmText("あ"), MfmEmojiCode("bar"), MfmText("い")];
        expect(parse(input), orderedEquals(output));
      });
    });

    test("disalow other syntaxes", () {
      //TODO
    });
  });

  group("FullParser", () {
    group("text", () {
      test("普通のテキストを入力すると1つのテキストノードが返される", () {
        const input = "abc";
        final output = [MfmText("abc")];
        expect(parse(input), orderedEquals(output));
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
          final result = parse(input);
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
                MfmText("I'm"),
                MfmMention("ai", null, "@ai"),
                MfmText(", An bot of misskey!"),
              ])
            ])
          ];
          final result = parse(input);
          expect(parse(input), orderedEquals(output));
        });
      });
      //TODO: バグを修正して続きのテストを記述する
    });
  });
  //TODO: 検索構文未実装

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
      final input = "abc\n```const abc  1;\n```\n123";
      final output = [
        MfmText("abc"),
        MfmCodeBlock("const ab = 1;", null),
        MfmText("abc")
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

  //TODO: 数式ブロック未実装

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

  // unicode emoji 未実装

  group("big", () {
    test("basic", () {
      final input = "***abc***";
      final output = [
        MfmFn(name: "tada", args: {}, children: [MfmText("abc")])
      ];

      expect(parse(input), orderedEquals(output));
    });
  });
}
