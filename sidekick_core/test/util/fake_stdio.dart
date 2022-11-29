import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/fake.dart';

class FakeStdoutStream with Fake implements Stdout {
  final List<List<int>> _writes = <List<int>>[];

  List<String> get lines => _writes.map(utf8.decode).toList();

  @override
  void add(List<int> bytes) {
    _writes.add(bytes);
  }

  @override
  void writeln([Object? object = ""]) {
    _writes.add(utf8.encode('$object'));
  }

  @override
  void write(Object? object) {
    _writes.add(utf8.encode('$object'));
  }

  @override
  void writeAll(Iterable objects, [String sep = ""]) {
    _writes.add(utf8.encode(objects.join(sep)));
  }

  @override
  void writeCharCode(int charCode) {
    _writes.add(utf8.encode(String.fromCharCode(charCode)));
  }
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
