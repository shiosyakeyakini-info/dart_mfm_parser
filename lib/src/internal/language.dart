import 'package:mfm_parser/src/internal/extension/string_extension.dart';
import 'package:mfm_parser/src/internal/core/core.dart';
import 'package:mfm_parser/src/internal/tweemoji_parser.dart';
import 'package:mfm_parser/src/internal/utils.dart';
import 'package:mfm_parser/src/node.dart';

final space = regexp(RegExp(r"[\u0020\u3000\t]"));
final alphaAndNum = regexp(RegExp(r"[a-zA-Z0-9]"));
final newLine = alt([crlf, cr, lf]);

Parser seqOrText(List<Parser> parsers) {
  return Parser(handler: (input, index, state) {
    final accum = [];
    var latestIndex = index;
    for (var i = 0; i < parsers.length; i++) {
      final result = parsers[i].handler(input, latestIndex, state);
      if (!result.success) {
        if (latestIndex == index) {
          return failure();
        } else {
          return success(latestIndex, input.slice(index, latestIndex));
        }
      }
      accum.add(result.value);
      latestIndex = result.index!;
    }
    return success(latestIndex, accum);
  });
}

Parser notLinkLabel = Parser(handler: (_, index, state) {
  return (!state.linkLabel) ? success(index, null) : failure();
});

Parser nestable = Parser(handler: (_, index, state) {
  return (state.depth < state.nestLimit) ? success(index, null) : failure();
});

Parser nest(Parser parser, {Parser? fallback}) {
  final inner = alt([
    seq([nestable, parser], select: 1),
    (fallback != null) ? fallback : char
  ]);
  return Parser(handler: (input, index, state) {
    state.depth++;
    final result = inner.handler(input, index, state);
    state.depth--;
    return result;
  });
}

class Language {
  late final Map<String, dynamic> _l;
  Parser get fullParser => _l["full"].many(0);
  Parser get simpleParser => _l["simple"].many(0);
  Parser get quote => _l["quote"];
  Parser get big => _l["big"];
  Parser get boldAsta => _l["boldAsta"];
  Parser get boldTag => _l["boldTag"];
  Parser get text => _l["text"];
  Parser get inline => _l["inline"];
  Parser get boldUnder => _l["boldUnder"];
  Parser get smallTag => _l["smallTag"];
  Parser get italicTag => _l["italicTag"];
  Parser get italicAsta => _l["italicAsta"];
  Parser get italicUnder => _l["italicUnder"];
  Parser get codeBlock => _l["codeBlock"];
  Parser get strikeTag => _l["strikeTag"];
  Parser get strikeWave => _l["strikeWave"];
  Parser get emojiCode => _l["emojiCode"];
  Parser get mathBlock => _l["mathBlock"];
  Parser get centerTag => _l["centerTag"];
  Parser get plainTag => _l["plainTag"];
  Parser get inlineCode => _l["inlineCode"];
  Parser get mathInline => _l["mathInline"];
  Parser get mention => _l["mention"];
  Parser get fn => _l["fn"];
  Parser get hashTag => _l["hashtag"];
  Parser get link => _l["link"];
  Parser get url => _l["url"];
  Parser get urlAlt => _l["urlAlt"];
  Parser get unicodeEmoji => _l["unicodeEmoji"];
  Parser get search => _l["search"];

  Language() {
    _l = createLanguage({
      "full": () => alt([
            unicodeEmoji,
            centerTag,
            smallTag,
            plainTag,
            boldTag,
            italicTag,
            strikeTag,
            urlAlt,
            big,
            boldAsta,
            italicAsta,
            boldUnder,
            italicUnder,
            codeBlock,
            inlineCode,
            quote,
            mathBlock,
            mathInline,
            strikeWave,
            fn,
            mention,
            hashTag,
            emojiCode,
            link,
            url,
            search,
            text,
          ]),
      "simple": () => alt([unicodeEmoji, emojiCode, text]),
      "inline": () => alt([
            unicodeEmoji,
            smallTag,
            plainTag,
            boldTag,
            italicTag,
            strikeTag,
            urlAlt,
            big,
            boldAsta,
            italicAsta,
            boldUnder,
            italicUnder,
            inlineCode,
            mathInline,
            strikeWave,
            fn,
            mention,
            hashTag,
            emojiCode,
            link,
            url,
            text,
          ]),
      "quote": () {
        final Parser<List> lines = seq([
          str(">"),
          space.option(),
          seq([notMatch(newLine), char], select: 1).many(0).text(),
        ], select: 2)
            .sep(newLine, 1);

        final parser = seq([
          newLine.option(),
          newLine.option(),
          lineBegin,
          lines,
          newLine.option(),
          newLine.option(),
        ], select: 3);

        return Parser(handler: (input, index, state) {
          Result result = parser.handler(input, index, state);
          if (!result.success) {
            return result;
          }

          final contents = result.value;
          final quoteIndex = result.index!;

          if (contents.length == 1 && contents[0].length == 0) {
            return failure();
          }

          final contentParser = nest(fullParser).many(0);
          result = contentParser.handler(contents.join("\n"), 0, state);

          if (!result.success) {
            return result;
          }

          return success(
              quoteIndex, MfmQuote(children: mergeText(result.value)));
        });
      },
      "codeBlock": () {
        final mark = str("```");
        return seq([
          newLine.option(),
          lineBegin,
          mark,
          seq([notMatch(newLine), char], select: 1).many(0),
          newLine,
          seq([
            notMatch(seq([newLine, mark, lineEnd])),
            char
          ], select: 1)
              .many(1),
          newLine,
          mark,
          lineEnd,
          newLine.option()
        ]).map((result) {
          final lang = result[3].join("").trim();
          final code = result[5].join("");

          return MfmCodeBlock(code, (lang.length > 0 ? lang : null));
        });
      },
      "mathBlock": () {
        final open = str(r"\[");
        final close = str(r"\]");

        return seq([
          newLine.option(),
          lineBegin,
          open,
          newLine.option(),
          seq([
            notMatch(seq([newLine.option(), close])),
            char
          ], select: 1)
              .many(1),
          newLine.option(),
          close,
          lineEnd,
          newLine.option()
        ]).map((result) {
          final formula = result[4].join("");
          return MfmMathBlock(formula);
        });
      },
      "centerTag": () {
        final open = str("<center>");
        final close = str("</center>");

        return seq([
          newLine.option(),
          lineBegin,
          open,
          newLine.option(),
          seq([
            notMatch(seq([newLine.option(), close])),
            nest(inline)
          ], select: 1)
              .many(1),
          newLine.option(),
          close,
          lineEnd,
          newLine.option()
        ]).map((result) {
          return MfmCenter(children: mergeText(result[4]).cast<MfmInline>());
        });
      },
      "big": () {
        final mark = str("***");
        return seqOrText([
          mark,
          seq([notMatch(mark), nest(inline)], select: 1).many(1),
          mark,
        ]).map((result) {
          if (result is String) return result;
          return MfmFn(name: "tada", args: {}, children: mergeText(result[1]));
        });
      },
      "text": () => char,
      "boldAsta": () {
        final mark = str("**");
        return seqOrText([
          mark,
          seq([notMatch(mark), nest(inline)], select: 1).many(1),
          mark
        ]).map((result) {
          if (result is String) return result;
          return MfmBold(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "boldTag": () {
        final open = str("<b>");
        final close = str("</b>");

        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmBold(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "boldUnder": () {
        final mark = str("__");
        return seq([
          mark,
          alt([alphaAndNum, space]).many(1),
          mark,
        ]).map((result) => MfmBold(mergeText(result[1]).cast<MfmInline>()));
      },
      "smallTag": () {
        final open = str("<small>");
        final close = str("</small>");
        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close
        ]).map((result) {
          if (result is String) return result;
          return MfmSmall(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "italicTag": () {
        final open = str("<i>");
        final close = str("</i>");
        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmItalic(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "italicAsta": () {
        final mark = str("*");
        final parser = seq([
          mark,
          alt([alphaAndNum, space]).many(1),
          mark
        ]);
        return Parser(handler: (input, index, state) {
          final result = parser.handler(input, index, state);
          if (!result.success) {
            return failure();
          }
          final beforeStr = input.slice(0, index);
          if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
            return failure();
          }
          return success(result.index!,
              MfmItalic(mergeText(result.value[1]).cast<MfmInline>()));
        });
      },
      "italicUnder": () {
        final mark = str("_");
        final parser = seq([
          mark,
          alt([alphaAndNum, space]).many(1),
          mark
        ]);

        return Parser(handler: (input, index, state) {
          final result = parser.handler(input, index, state);
          if (!result.success) {
            return failure();
          }
          final beforeStr = input.slice(0, index);
          if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
            return failure();
          }
          return success(result.index!,
              MfmItalic(mergeText(result.value[1]).cast<MfmInline>()));
        });
      },
      "strikeTag": () {
        final open = str("<s>");
        final close = str("</s>");

        return seqOrText([
          open,
          seq([notMatch(close), nest(inline)], select: 1).many(1),
          close,
        ]).map((result) {
          if (result is String) return result;
          return MfmStrike(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "strikeWave": () {
        final mark = str("~~");
        return seqOrText([
          mark,
          seq([
            notMatch(alt([mark, newLine])),
            nest(inline)
          ], select: 1)
              .many(1),
          mark,
        ]).map((result) {
          if (result is String) return result;
          return MfmStrike(mergeText(result[1]).cast<MfmInline>());
        });
      },
      "unicodeEmoji": () {
        return regexp(tweEmojiParser)
            .map((content) => MfmUnicodeEmoji(content));
      },
      "emojiCode": () {
        final side = notMatch(regexp(RegExp(r"[a-zA-Z0-9]")));
        final mark = str(":");
        return seq([
          alt([lineBegin, side]),
          mark,
          regexp(RegExp(r"[a-zA-Z0-9_+-]+")),
          mark,
          alt([lineEnd, side])
        ], select: 2)
            .map((name) => MfmEmojiCode(name));
      },
      "plainTag": () {
        final open = str("<plain>");
        final close = str("</plain>");

        return seq([
          open,
          newLine.option(),
          seq([
            notMatch(seq([newLine.option(), close])),
            char
          ], select: 1)
              .many(1)
              .text(),
          newLine.option(),
          close
        ], select: 2)
            .map((result) => MfmPlain(result));
      },
      "fn": () {
        final fnName = Parser(handler: (input, index, state) {
          final result =
              regexp(RegExp("[a-zA-Z0-9_]+")).handler(input, index, state);
          if (!result.success) {
            return result;
          }
          return success(result.index!, result.value);
        });

        final Parser<Map<String, dynamic>> arg = seq([
          regexp(RegExp("[a-zA-Z0-9_]+")),
          seq([
            str("="),
            regexp(RegExp("[a-zA-Z0-9_.-]+")),
          ], select: 1)
              .option(),
        ]).map((result) {
          return {
            "k": result[0],
            "v": (result[1] != null) ? result[1] : "",
          };
        });

        final args = seq([
          str("."),
          arg.sep(str(","), 1),
        ], select: 1)
            .map((pairs) {
          final result = {};
          for (final pair in pairs) {
            result[pair["k"]] = pair["v"];
          }
          return result;
        });

        final fnClose = str("]");

        return seqOrText([
          str(r"$["),
          fnName,
          args.option(),
          str(" "),
          seq([notMatch(fnClose), nest(inline)], select: 1).many(1),
          fnClose,
        ]).map((result) {
          if (result is String) return result;
          final name = result[1];
          final args =
              (result[2] as Map<dynamic, dynamic>?)?.cast<String, dynamic>();
          final content = result[4];
          return MfmFn(
              name: name as String,
              args: args ?? {},
              children: mergeText(content));
        });
      },
      "inlineCode": () {
        final mark = str("`");
        return seq([
          mark,
          seq([
            notMatch(alt([mark, str("´"), newLine])),
            char,
          ], select: 1)
              .many(1),
          mark
        ]).map((result) => MfmInlineCode(code: result[1].join("")));
      },
      "mathInline": () {
        final open = str(r"\(");
        final close = str(r"\)");
        return seq([
          open,
          seq([
            notMatch(alt([close, newLine])),
            char
          ], select: 1)
              .many(1),
          close
        ]).map((result) => MfmMathInline(formula: result[1].join("")));
      },
      "mention": () {
        final parser = seq([
          notLinkLabel,
          str("@"),
          regexp(RegExp(r"[a-zA-Z0-9_-]+")),
          seq([
            str("@"),
            regexp(RegExp(r"[a-zA-Z0-9_.-]+")),
          ], select: 1)
              .option(),
        ]);

        return Parser(handler: (input, index, state) {
          Result result = parser.handler(input, index, state);
          if (!result.success) return failure();

          final beforeStr = input.slice(0, index);
          if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) return failure();

          var invalidMention = false;
          final resultIndex = result.index!;
          final username = result.value[2] as String;
          final hostname = result.value[3] as String?;

          var modifiedHost = hostname;
          if (hostname != null) {
            final regResult = RegExp(r"[.-]+$").firstMatch(hostname);
            if (regResult != null) {
              modifiedHost = hostname.slice(0, (-1 * regResult[0]!.length));
              if (modifiedHost.isEmpty) {
                // disallow invalid char only hostname
                invalidMention = true;
                modifiedHost = null;
              }
            }
          }
          // remove "-" of tail of username
          String modifiedName = username;
          final regResult2 = RegExp(r"-+$").firstMatch(username);
          if (regResult2 != null) {
            if (modifiedHost == null) {
              modifiedName = username.slice(0, (-1 * regResult2[0]!.length));
            } else {
              // cannnot to remove tail of username if exist hostname
              invalidMention = true;
            }
          }
          // disallow "-" of head of username
          if (modifiedName.isEmpty || modifiedName[0] == '-') {
            invalidMention = true;
          }
          // disallow [.-] of head of hostname
          if (modifiedHost != null && RegExp(r"^[.-]").hasMatch(modifiedHost)) {
            invalidMention = true;
          }
          // generate a text if mention is invalid
          if (invalidMention) {
            return success(resultIndex, input.slice(index, resultIndex));
          }
          final acct = modifiedHost != null
              ? "@$modifiedName@$modifiedHost"
              : "@$modifiedName";
          return success(index + acct.length,
              MfmMention(modifiedName, modifiedHost, acct));
        });
      },
      "hashtag": () {
        final mark = str("#");
        final Parser hashTagChar = seq([
          notMatch(alt([
            regexp(RegExp(r"""[ \u3000\t.,!?'"#:/[\]【】()「」（）<>]""")),
            space,
            newLine
          ])),
          char,
        ], select: 1);
        Parser? innerItem;
        innerItem = lazy(() => alt([
              seq([
                str('('),
                nest(innerItem!, fallback: hashTagChar).many(0),
                str(')'),
              ]),
              seq([
                str('['),
                nest(innerItem, fallback: hashTagChar).many(0),
                str(']'),
              ]),
              seq([
                str('「'),
                nest(innerItem, fallback: hashTagChar).many(0),
                str('」'),
              ]),
              seq([
                str('（'),
                nest(innerItem, fallback: hashTagChar).many(0),
                str('）'),
              ]),
              hashTagChar,
            ]));
        final parser = seq([
          notLinkLabel,
          mark,
          innerItem.many(1).text(),
        ], select: 2);
        return Parser(handler: (input, index, state) {
          final result = parser.handler(input, index, state);
          if (!result.success) {
            return failure();
          }
          // check before
          final beforeStr = input.slice(0, index);
          if (RegExp(r"[a-zA-Z0-9]$").hasMatch(beforeStr)) {
            return failure();
          }
          final resultIndex = result.index!;
          final resultValue = result.value;
          // disallow number only
          if (RegExp(r"^[0-9]+$").hasMatch(resultValue)) {
            return failure();
          }
          return success(resultIndex, MfmHashTag(resultValue));
        });
      },
      "link": () {
        final labelInline = Parser(handler: (input, index, state) {
          state.linkLabel = true;
          final result = inline.handler(input, index, state);
          state.linkLabel = false;
          return result;
        });
        final closeLabel = str(']');
        return seq([
          notLinkLabel,
          alt([str('?['), str('[')]),
          seq([
            notMatch(alt([closeLabel, newLine])),
            nest(labelInline),
          ], select: 1)
              .many(1),
          closeLabel,
          str('('),
          alt([urlAlt, url]),
          str(')'),
        ]).map((result) {
          final silent = (result[1] == '?[');
          final label = result[2];
          final url = result[5] as MfmURL;
          return MfmLink(
              silent: silent, url: url.value, children: mergeText(label));
        });
      },
      "url": () {
        final urlChar = regexp(RegExp(r"""[.,a-zA-Z0-9_/:%#@$&?!~=+-]"""));
        Parser? innerItem;
        innerItem = lazy(() => alt([
              seq([
                str('('),
                nest(innerItem!, fallback: urlChar).many(0),
                str(')'),
              ]),
              seq([
                str('['),
                nest(innerItem, fallback: urlChar).many(0),
                str(']'),
              ]),
              urlChar,
            ]));
        final parser = seq([
          notLinkLabel,
          regexp(RegExp(r"https?://")),
          innerItem.many(1).text(),
        ]);
        return Parser(handler: (input, index, state) {
          Result result = parser.handler(input, index, state);
          if (!result.success) {
            return failure();
          }
          final resultIndex = result.index;
          var modifiedIndex = resultIndex!;
          final schema = result.value[1] as String;
          var content = result.value[2] as String;
          // remove the ".," at the right end
          var regexpResult = RegExp(r"[.,]+$").firstMatch(content);
          if (regexpResult != null) {
            modifiedIndex -= regexpResult.group(0)!.length;
            content = content.slice(0, (-1 * regexpResult.group(0)!.length));
            if (content.isEmpty) {
              return success(resultIndex, input.slice(index, resultIndex));
            }
          }
          return success(modifiedIndex, MfmURL(schema + content, false));
        });
      },
      "urlAlt": () {
        final open = str('<');
        final close = str('>');
        final parser = seq([
          notLinkLabel,
          open,
          regexp(RegExp(r"https?://")),
          seq([
            notMatch(alt([close, space])),
            char
          ], select: 1)
              .many(1),
          close,
        ]).text();
        return Parser(handler: (input, index, state) {
          final result = parser.handler(input, index, state);
          if (!result.success) {
            return failure();
          }
          final text = result.value!.slice(1, (result.value!.length - 1));
          return success(result.index!, MfmURL(text, true));
        });
      },
      "search": () {
        final button = alt([
          regexp(RegExp(r"\[(検索|[sS][eE][aA][rR][cC][hH])\]")),
          regexp(RegExp(r"(検索|[sS][eE][aA][rR][cC][hH])"))
        ]);

        return seq([
          newLine.option(),
          lineBegin,
          seq([
            notMatch(alt([
              newLine,
              seq([space, button, lineEnd])
            ])),
            char
          ], select: 1)
              .many(1),
          space,
          button,
          lineEnd,
          newLine.option(),
        ]).map((result) {
          final query = result[2].join('');
          return MfmSearch(query, "$query${result[3]}${result[4]}");
        });
      }
    });
  }
}
