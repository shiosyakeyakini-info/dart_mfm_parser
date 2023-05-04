import 'dart:math';

extension StringExtension on String {
  String slice(int start, int end) {
    int realEnd;
    int realStart = start < 0 ? length + start : start;
    realEnd = end < 0 ? length + end : end;

    return substring(realStart, realEnd);
  }

  String substr(int start, int length) =>
      substring(start, min(start + length, this.length));
}
