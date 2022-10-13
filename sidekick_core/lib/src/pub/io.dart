import 'dart:io';

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/io.dart#L558
/// Needed by [defaultUrl]
///
/// Whether the current process is a pub subprocess being run from a test.
///
/// The "_PUB_TESTING" variable is automatically set for all the test code's
/// invocations of pub.
final bool runningFromTest =
    Platform.environment.containsKey('_PUB_TESTING') && _assertionsEnabled;

final bool _assertionsEnabled = () {
  try {
    assert(false);
    // ignore: avoid_catching_errors
  } on AssertionError {
    return true;
  }
  return false;
}();
