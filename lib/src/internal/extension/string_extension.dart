import 'dart:math';

extension StringExtension on String {
  String slice(int start, int end) => substring(start, min(end, length));
  String substr(int start, int length) => substring(start, min(start + length, this.length));
}