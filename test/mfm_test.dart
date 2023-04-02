
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:mfm/src/mfm_parser.dart';
import 'package:mfm/src/node.dart';
import 'package:test/test.dart';

void main() {
  const parse = MfmParser.parse;
  final equals = const DeepCollectionEquality().equals;

  group("SimpleParser", () {
    group("text", () {
      test("basic", () {
        const input = "abc";
        final output = [MfmText("abc")];

        expect(equals(parse(input), output), isTrue);
      });

      test("ignore hashtag", (){ // TODO
      });
      test("keycap number sign", () {// TODO
      });
    });

    group("emoji", () {
      test("basic", (){
        const input = ":foo:";
        final output = [MfmEmojiCode("foo")];
        expect(equals(parse(input), output), isTrue);
      });

      test("between texts", () {
        const input = "foo:bar:baz";
        final output = [MfmText("foo:bar:baz")];
        expect(equals(parse(input), output), isTrue);
      });

      test("between text 2", () {
        const input = "12:34:56";
        final output = [MfmText("12:34:56")];
        expect(equals(parse(input), output), isTrue);
      });

      test("between text 3", () {
        const input = "あ:bar:い";
        final output = [MfmText("あ"), MfmEmojiCode("bar"), MfmText("い")];
        expect(equals(parse(input), output), isTrue);
      });
    });

    test("disalow other syntaxes", () { //TODO
    });
  });

  group("FullParser", () {
    group("text", () {
      test("普通のテキストを入力すると1つのテキストノードが返される", () {
        const input = "abc";
        final output = [MfmText("abc")];
        expect(equals(parse(input), output), isTrue);
      });

      group("quote", () {
        test("1行の引用ブロックを使用できる", () {
          const input = "> abc";
          final output = [MfmQuote(children: [MfmText("abc")])];
          expect(equals(parse(input), output), isTrue);
        });

        test("複数行の引用ブロックを使用できる", () {
          			const input = """
> abc
> 123
""";
                final output = [
                  MfmQuote(children: [MfmText("abc\n123")])
                ];
                expect(equals(parse(input), output), isTrue);
        });
      });

    });
  });
}