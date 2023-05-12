# mfm_parser

[MFM (Misskey Flavor Markdown)](https://misskey-hub.net/en/docs/features/mfm.html) parser implementation for dart.

This package is not **renderer** of the mfm.

## Features

This package was ported from typescript project of
[misskey-dev/mfm.js](https://github.com/misskey-dev/mfm.js/tree/develop) and
depended on [twitter/twemoji-parser](https://github.com/twitter/twemoji-parser/blob/master/src/lib/regex.js) too.

## Getting started

```
dart pub add mfm_parser
```

if you use flutter,

```
flutter pub add mfm_parser
```

## Usage

you can use `MfmParser().parse()` or `MfmParser().parseSimple()`.
simpleParser is only supported to the text and emoji. you can used it for such as user name.

```dart
final text = r"""
<center>$[x2 **What's @ai**]</center>
@ai is official mascot character of the Misskey.
you can see more information from <https://xn--931a.moe/>
""";

final list = const MfmParser().parse(text);

print(list);
```

## TODO

These feature will be supported in the future.

- This package is not compatible with 'toString()' and many api from the official mfm.js.
- This package is not support math-inline and math-block.