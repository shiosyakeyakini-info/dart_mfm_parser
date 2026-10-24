import 'dart:math';

import 'package:mfm_parser/src/mfm_parser.dart';

class Success<T> extends Result<T> {
  const Success(
      {required super.value, required super.index, super.success = true});
}

class Failure<T> extends Result<T> {
  const Failure({super.success = false});
}

abstract class Result<T> {
  final bool success;
  final T? value;
  final int? index;

  const Result({required this.success, this.value, this.index});
}

class Span {
  final int start;
  final int end;

  const Span(this.start, this.end);
}

class ManyThenItems<T, U> {
  final List<T> items;
  final U afterValue;

  const ManyThenItems(this.items, this.afterValue);
}

typedef ParserHandler<T> = Result<T> Function(
    String input, int index, FullParserOpts state);

Success<T> success<T>(int index, T value) =>
    Success<T>(value: value, index: index);
Failure<T> failure<T>() => Failure<T>();

class Parser<T> {
  String? name;
  late ParserHandler<T> handler;
  String? firstChars;

  Parser({required this.handler, this.name});

  Parser<U> map<U>(U Function(T value) fn) {
    return Parser<U>(handler: (input, index, state) {
      final result = handler(input, index, state);
      if (!result.success) {
        if (result is! Failure<U>) {
          return failure<U>();
        }

        return result as Result<U>;
      }
      return success(result.index!, fn(result.value as T));
    });
  }

  Parser<String> text() {
    return Parser(handler: (input, index, state) {
      final result = handler(input, index, state);
      if (!result.success) {
        if (result is! Result<String>) {
          return failure();
        }
        return result as Result<String>;
      }
      final succeed = result as Success;
      final text = input.substring(index, result.index);
      return success(succeed.index!, text);
    });
  }

  Parser<List<T2>> many<T2>(int min) {
    return Parser(handler: (input, index, state) {
      Result result;
      var latestIndex = index;
      final List<T2> accum = [];
      while (latestIndex < input.length) {
        result = handler(input, latestIndex, state);
        if (!result.success) {
          break;
        }
        latestIndex = result.index!;
        accum.add(result.value);
      }
      if (accum.length < min) {
        return failure<List<T2>>();
      }
      return success(latestIndex, accum);
    });
  }

  Parser<List<T>> sep(Parser<dynamic> separator, int min) {
    if (min < 1) {
      throw Exception('"min" must be a value greater than or equal to 1.');
    }

    return seq([
      this,
      seq([
        separator,
        this,
      ], select: 1)
          .many(min - 1),
    ]).map((result) => <T>[result[0], for (final elem in result[1]) elem]);
  }

  Parser option<T2>() {
    return alt([
      this,
      succeeded(null),
    ]);
  }
}

Parser<T> str<T extends String>(T value) {
  return Parser(handler: (input, index, _) {
    if (!input.startsWith(value, index)) {
      return failure();
    }

    return success(index + value.length, value);
  });
}

Parser<String> regexp<T extends RegExp>(T pattern) {
  return Parser(handler: (input, index, _) {
    final result = pattern.matchAsPrefix(input, index);

    if (result == null) {
      return failure();
    }
    return success(index + result.group(0)!.length, result.group(0)!);
  });
}

Parser seq(List<Parser> parsers, {int? select}) {
  return Parser(handler: (input, index, state) {
    Result result;
    var latestIndex = index;
    final accum = [];

    for (var i = 0; i < parsers.length; i++) {
      result = parsers[i].handler(input, latestIndex, state);
      if (!result.success) {
        return result;
      }
      latestIndex = result.index!;
      accum.add(result.value);
    }
    return success(latestIndex, (select != null ? accum[select] : accum));
  });
}

Parser alt(List<Parser> parsers) {
  final candidatesByChar =
      parsers.any((p) => p.firstChars != null) ? <int, List<Parser>>{} : null;
  return Parser(handler: (input, index, state) {
    List<Parser> candidates = parsers;
    if (candidatesByChar != null) {
      final code =
          index < input.length ? min(input.codeUnitAt(index), 0x80) : -1;
      var cached = candidatesByChar[code];
      if (cached == null) {
        cached = parsers
            .where((parser) =>
                parser.firstChars == null ||
                (code >= 0 &&
                    parser.firstChars!.contains(String.fromCharCode(code))))
            .toList();
        candidatesByChar[code] = cached;
      }
      candidates = cached;
    }
    for (var i = 0; i < candidates.length; i++) {
      final parser = candidates[i];
      final result = parser.handler(input, index, state);
      if (result.success) {
        return result;
      }
    }
    return failure();
  });
}

Parser<T> first<T>(String chars, Parser<T> parser) {
  final guarded = Parser<T>(handler: (input, index, state) {
    if (index >= input.length || !chars.contains(input[index])) {
      return failure();
    }
    return parser.handler(input, index, state);
  });
  guarded.firstChars = chars;
  return guarded;
}

Parser<T> succeeded<T>(T value) {
  return Parser(handler: (_, index, __) {
    return success(index, value);
  });
}

Parser notMatch(Parser parser) {
  return Parser(handler: (input, index, state) {
    final result = parser.handler(input, index, state);
    return !result.success ? success(index, null) : failure();
  });
}

int stateKey(FullParserOpts state) {
  return state.depth * 2 + (state.linkLabel ? 1 : 0);
}

Parser<String> until(Parser terminator, int min) {
  late final Parser<String> parser;
  parser = Parser<String>(handler: (input, index, state) {
    state.untilSpans ??= {};
    final spans = state.untilSpans!.putIfAbsent(parser, () => {});
    final span = spans[input];
    int end;
    if (span != null && span.start <= index && index <= span.end) {
      end = span.end;
    } else {
      end = index;
      while (end < input.length &&
          !terminator.handler(input, end, state).success) {
        end++;
      }
      spans[input] = Span(index, end);
    }
    if (end - index < min) {
      return failure();
    }
    return success(end, input.substring(index, end));
  });
  return parser;
}

Parser<ManyThenItems<T, U>> manyThen<T, U>(
  Parser<T> item,
  Parser stop,
  Parser<U> after,
  int min,
) {
  final element = seq([notMatch(stop), item], select: 1);
  late final Parser<ManyThenItems<T, U>> parser;
  parser = Parser(handler: (input, index, state) {
    state.manyThenFailures ??= {};
    final byInput = state.manyThenFailures!.putIfAbsent(parser, () => {});
    final byState = byInput.putIfAbsent(input, () => {});
    final failures = byState.putIfAbsent(stateKey(state), () => {});
    final boundaries = <int>[];
    final items = <T>[];
    var latestIndex = index;
    while (!failures.contains(latestIndex)) {
      boundaries.add(latestIndex);
      if (latestIndex >= input.length) {
        break;
      }
      final result = element.handler(input, latestIndex, state);
      if (!result.success) {
        break;
      }
      items.add(result.value as T);
      latestIndex = result.index!;
    }
    if (items.length < min) {
      return failure();
    }
    final afterResult = failures.contains(latestIndex)
        ? failure<U>()
        : after.handler(input, latestIndex, state);
    if (!afterResult.success) {
      failures.addAll(boundaries);
      return failure();
    }
    return success(
      afterResult.index!,
      ManyThenItems(items, afterResult.value as U),
    );
  });
  return parser;
}

final Parser cr = str("\r");
final Parser lf = str("\n");
final Parser crlf = str("\r\n");
final Parser newline = alt([crlf, cr, lf]);
final Parser char = Parser(handler: (input, index, _) {
  if ((input.length - index) < 1) {
    return failure();
  }
  final value = input[index];
  return success(index + 1, value);
});

final Parser lineBegin = Parser(handler: (input, index, state) {
  if (index == 0) {
    return success(index, null);
  }
  if (cr.handler(input, index - 1, state).success) {
    return success(index, null);
  }
  if (lf.handler(input, index - 1, state).success) {
    return success(index, null);
  }
  return failure();
});

Parser lineEnd = Parser(handler: (input, index, state) {
  if (index == input.length) {
    return success(index, null);
  }
  if (cr.handler(input, index, state).success) {
    return success(index, null);
  }
  if (lf.handler(input, index, state).success) {
    return success(index, null);
  }
  return failure();
});

Parser lazy<T>(Parser<T> Function() fn) {
  Parser? parser;
  parser = Parser(handler: (input, index, state) {
    parser!.handler = fn().handler;
    return parser.handler(input, index, state);
  });
  return parser;
}

Parser<T> traced<T>(Parser<T> parser, String name) {
  return Parser(
    handler: (input, index, state) {
      if (!state.trace) {
        return parser.handler(input, index, state);
      }
      final pos = "$index";
      print("${pos.padRight(6)}enter $name");
      final result = parser.handler(input, index, state);
      if (result.success) {
        final pos = "$index:${result.index}";
        print("${pos.padRight(6)}match $name");
      } else {
        final pos = "$index";
        print("${pos.padRight(6)}fail $name");
      }
      return result;
    },
    name: name,
  );
}

Map<String, Parser> createLanguage<T>(
    Map<String, Parser? Function()> syntaxes) {
  final Map<String, Parser> rules = {};

  for (final entry in syntaxes.entries) {
    rules[entry.key] = lazy(() {
      final Parser? parser = syntaxes[entry.key]!();
      if (parser == null) {
        throw Exception('syntax must return a parser.');
      }
      return traced(parser, entry.key);
    });
  }
  return rules;
}
