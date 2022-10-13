/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/utils.dart#L315
/// Needed by [_urlToDirectory]
///
/// Replace each instance of [matcher] in [source] with the return value of
/// [fn].
String replace(String source, Pattern matcher, String Function(Match) fn) {
  final buffer = StringBuffer();
  var start = 0;
  for (final match in matcher.allMatches(source)) {
    buffer.write(source.substring(start, match.start));
    start = match.end;
    buffer.write(fn(match));
  }
  buffer.write(source.substring(start));
  return buffer.toString();
}
