import 'dart:async';

import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/language.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/mfm_parser.dart';
import 'package:mfm_parser/src/node.dart';
import 'package:test/test.dart';

FullParserOpts createState() {
  return FullParserOpts(
    nestLimit: 20,
    depth: 0,
    linkLabel: false,
    trace: false,
  );
}

void main() {
  group("core", () {
    group("first", () {
      test("match at the declared chars", () {
        final parser = first("a", str("ab"));
        final result = parser.handler("ab", 0, createState());
        expect(result.success, isTrue);
        expect(result.index, 2);
        expect(result.value, "ab");
      });

      test("fail at other chars", () {
        final parser = first("a", str("b"));
        expect(parser.handler("b", 0, createState()).success, isFalse);
      });

      test("fail at the end of input", () {
        final parser = first("a", lineEnd);
        expect(parser.handler("a", 1, createState()).success, isFalse);
      });
    });

    group("alt", () {
      test("skip parsers that cannot start with the current char", () {
        var calls = 0;
        final handler = Parser(handler: (input, index, state) {
          calls += 1;
          return success<String>(1, "b");
        });
        final parser = alt(
          [
            first("a", handler),
            str("b"),
          ],
        );
        final result = parser.handler("b", 0, createState());
        expect(result.success, isTrue);
        expect(result.index, 1);
        expect(result.value, "b");
        expect(calls, 0);
      });

      test("skip parsers made by first at the end of input", () {
        final parser = alt(
          [
            first("a", str("a")),
            lineEnd,
          ],
        );
        final result = parser.handler("a", 1, createState());
        expect(result.success, isTrue);
        expect(result.index, 1);
        expect(result.value, isNull);
      });
    });

    group("until", () {
      test("basic", () {
        final parser = until(str("]"), 1);
        final result = parser.handler("ab]", 0, createState());
        expect(result.success, isTrue);
        expect(result.index, 2);
        expect(result.value, "ab");
      });

      test("reuse the scanned span", () {
        var calls = 0;
        final terminator = Parser(handler: (input, index, state) {
          calls += 1;
          return str("]").handler(input, index, state);
        });
        final parser = until(terminator, 1);
        final state = createState();
        final result1 = parser.handler("ab]", 0, state);
        expect(result1.success, isTrue);
        expect(result1.index, 2);
        expect(result1.value, "ab");
        final callsAfterFirst = calls;
        final result2 = parser.handler("ab]", 1, state);
        expect(result2.success, isTrue);
        expect(result2.index, 2);
        expect(result2.value, "b");
        expect(calls, callsAfterFirst);
      });

      test("fail if shorter than min", () {
        final parser = until(str("]"), 1);
        expect(parser.handler("]", 0, createState()).success, isFalse);
      });
    });

    group("manyThen", () {
      test("basic", () {
        final parser = manyThen(char, str("]"), str("]"), 1);
        final result = parser.handler("ab]", 0, createState());
        expect(result.success, isTrue);
        expect(result.index, 3);
        expect(result.value!.items, ["a", "b"]);
        expect(result.value!.afterValue, "]");
      });

      test("fail if fewer items than min", () {
        final parser = manyThen(char, str("]"), str("]"), 1);
        expect(parser.handler("]", 0, createState()).success, isFalse);
      });

      test("skip the after parser when reaching a known failure", () {
        var calls = 0;
        final after = Parser(handler: (input, index, state) {
          calls += 1;
          return str("]").handler(input, index, state);
        });
        final parser = manyThen(char, str("]"), after, 1);
        final state = createState();
        expect(parser.handler("xab", 1, state).success, isFalse);
        final callsAfterFirst = calls;
        expect(parser.handler("xab", 0, state).success, isFalse);
        expect(calls, callsAfterFirst);
      });

      test("keep failures separately for each state", () {
        final after = Parser<String?>(handler: (input, index, state) {
          return state.linkLabel
              ? success<String?>(index, null)
              : failure<String?>();
        });
        final parser = manyThen(char, str("]"), after, 1);
        final state = createState();
        expect(parser.handler("ab", 0, state).success, isFalse);
        state.linkLabel = true;
        final result = parser.handler("ab", 0, state);
        expect(result.success, isTrue);
        expect(result.index, 2);
        expect(result.value!.items, ["a", "b"]);
        expect(result.value!.afterValue, isNull);
      });
    });

    group("createLanguage", () {
      test("log the calls of the rules when trace is enabled", () {
        final lines = <String>[];
        runZoned(
          () {
            final lang = createLanguage({"a": () => str("a")});
            final state = createState();
            state.trace = true;
            lang["a"]!.handler("a", 0, state);
            lang["a"]!.handler("b", 0, state);
          },
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => lines.add(line),
          ),
        );
        expect(
          lines,
          [
            "0     enter a",
            "0:1   match a",
            "0     enter a",
            "0     fail a",
          ],
        );
      });

      test("throw if the syntax does not return a parser", () {
        final lang = createLanguage({"a": () => null});
        expect(
          () => lang["a"]!.handler("a", 0, createState()),
          throwsA(
            predicate(
              (error) =>
                  error.toString().contains("syntax must return a parser."),
            ),
          ),
        );
      });
    });
  });

  group("nest budget", () {
    test("nest while the budget remains", () {
      const input = "**<i>a</i>**";
      final state = createState();
      state.nestBudget = 2;
      final result = Language().fullParser.handler(input, 0, state);
      expect(result.success, isTrue);
      expect(
        mergeText(result.value as List<dynamic>),
        orderedEquals(
          [
            MfmBold(
              [
                MfmItalic([MfmText("a")]),
              ],
            ),
          ],
        ),
      );
    });

    test("stop nesting once the budget runs out", () {
      const input = "**<i>a</i>**";
      final state = createState();
      state.nestBudget = 0;
      final result = Language().fullParser.handler(input, 0, state);
      expect(result.success, isTrue);
      expect(
        mergeText((result as Success<dynamic>).value as List<dynamic>),
        orderedEquals(
          [
            MfmBold([MfmText("<i>a</i>")]),
          ],
        ),
      );
    });

    test("no limit without the budget", () {
      const input = "**<i>a</i>**";
      final result = Language().fullParser.handler(input, 0, createState());
      expect(result.success, isTrue);
      expect(
        mergeText((result as Success<dynamic>).value as List),
        orderedEquals(
          [
            MfmBold(
              [
                MfmItalic([MfmText("a")]),
              ],
            ),
          ],
        ),
      );
    });
  });
}
