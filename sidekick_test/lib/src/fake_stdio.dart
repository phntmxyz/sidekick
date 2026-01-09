import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/fake.dart';

class FakeStdoutStream with Fake implements Stdout {
  FakeStdoutStream({void Function(String)? onWrite}) : _onWrite = onWrite;

  final List<List<int>> _writes = <List<int>>[];
  final void Function(String)? _onWrite;

  List<String> get lines => _writes.map(utf8.decode).toList();

  @override
  void add(List<int> bytes) {
    _writes.add(bytes);
    _onWrite?.call(utf8.decode(bytes));
  }

  @override
  void writeln([Object? object = ""]) {
    final text = '$object';
    _writes.add(utf8.encode(text));
    _onWrite?.call(text);
  }

  @override
  void write(Object? object) {
    final text = '$object';
    _writes.add(utf8.encode(text));
    _onWrite?.call(text);
  }

  @override
  void writeAll(Iterable objects, [String sep = ""]) {
    final text = objects.join(sep);
    _writes.add(utf8.encode(text));
    _onWrite?.call(text);
  }

  @override
  void writeCharCode(int charCode) {
    final text = String.fromCharCode(charCode);
    _writes.add(utf8.encode(text));
    _onWrite?.call(text);
  }

  @override
  bool get supportsAnsiEscapes => false;
}

/// A wrapper around both stdout and stderr fake streams that tracks
/// the order of writes across both streams.
///
/// This simplifies test code that needs to capture and inspect both stdout
/// and stderr output. In most cases, you should use [combined] to check
/// output, since that's what users see in their terminal where stdout and
/// stderr are mixed together.
///
/// Only use [stdout] or [stderr] separately when you specifically need to
/// verify which stream was used (e.g., when testing commands designed to be
/// piped to other programs).
///
/// Example:
/// ```dart
/// final streams = FakeIoStreams();
/// await overrideIoStreams(
///   stdout: () => streams.stdout,
///   stderr: () => streams.stderr,
///   body: () async {
///     print('hello');      // goes to stdout
///     stderr.writeln('error'); // goes to stderr
///     print('world');      // goes to stdout
///   },
/// );
///
/// // Prefer: Check combined output (what users see)
/// expect(streams.combined, ['hello', 'error', 'world']);
///
/// // Only when specifically needed: Check individual streams
/// expect(streams.stdout.lines, ['hello', 'world']);
/// expect(streams.stderr.lines, ['error']);
/// ```
class FakeIoStreams {
  final List<String> _combined = [];

  late final FakeStdoutStream stdout = FakeStdoutStream(
    onWrite: (text) => _combined.add(text),
  );

  late final FakeStdoutStream stderr = FakeStdoutStream(
    onWrite: (text) => _combined.add(text),
  );

  /// All lines written to stdout and stderr in the order they were written.
  ///
  /// This is what users see in their terminal, where stdout and stderr are
  /// mixed together. **Prefer this over checking [stdout] or [stderr]
  /// separately** unless you specifically need to verify which stream was used.
  List<String> get combined => _combined;
}

class FakeStdinStream with Fake implements Stdin {
  FakeStdinStream({required this.hasTerminal});
  @override
  final bool hasTerminal;
}

T overrideIoStreams<T>({
  required T Function() body,
  Stdin Function()? stdin,
  Stdout Function()? stdout,
  Stdout Function()? stderr,
}) {
  return runZoned(
    () => IOOverrides.runZoned(
      body,
      stdout: stdout,
      stdin: stdin,
      stderr: stderr,
    ),
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        final override = IOOverrides.current;
        override?.stdout.writeln(line);
      },
    ),
  );
}
