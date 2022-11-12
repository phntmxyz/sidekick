import 'dart:async';
import 'dart:convert';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'fake_sdk.dart';
import 'init_test.dart';

void main() {
  test('dart command works when dartSdkPath is set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('dart command fails when dartSdkPath is not set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        // ignore: avoid_redundant_argument_values
        dartSdkPath: null,
      );
      runner.addCommand(DartCommand());
      expect(
        () => runner.run(['dart']),
        throwsA(isA<DartSdkNotSetException>()),
      );
    });
  });

  test('dart command links to embedded Dart SDK in Flutter SDK', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        flutterSdkPath: fakeFlutterSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('When dart command fails it reports stdout and stderr', () async {
    final out = _FakeStdoutStream();
    final err = _FakeStdoutStream();

    Future<void> code() async {
      final fakeSdk = fakeFlutterSdk();
      final runner = initializeSidekick(
        name: 'dash',
        flutterSdkPath: fakeSdk.path,
      );
      runner.addCommand(DartCommand());

      /// initialize dart command in cache
      await runner.run(['dart']);

      // override dart command to fail
      fakeSdk.file('bin/cache/dart-sdk/bin/dart').writeAsStringSync('''
                #!/bin/sh
                echo "stdout"
                echo "stderr" >&2
                exit 1
            ''');
      await expectLater(
        () => runner.run(['dart']),
        throwsA(
          isA<String>().having((it) => it, 'text', contains('exit code 1')),
        ),
      );
    }

    await insideFakeProjectWithSidekick(
      (dir) => overrideIoStreams(
        code,
        stdout: () => out,
        stderr: () => err,
      ),
    );
    expect(out.lines.join(), '');
    expect(err.lines.join(), contains('stdout'));
    expect(err.lines.join(), contains('stderr'));
    expect(err.lines.join(), contains('Script failed with exitCode: 1'));
  });

  test('be backwards compatible with dcli.Progress api', () async {
    final out = _FakeStdoutStream();
    final err = _FakeStdoutStream();

    Future<void> code() async {
      final fakeSdk = fakeFlutterSdk();
      final runner = initializeSidekick(
        name: 'dash',
        flutterSdkPath: fakeSdk.path,
      );
      runner.addCommand(_DcliProgressCommand());

      /// initialize dart command in cache
      await runner.run(['dcli-progress']);

      // override dart command for expected output
      fakeSdk.file('bin/cache/dart-sdk/bin/dart').writeAsStringSync('''
                #!/bin/sh
                echo "stdout"
                echo "stderr" >&2
            ''');
      final progress = await runner.run(['dcli-progress']) as Progress;
      expect(progress.toList(), ['stdout', 'stderr']);
    }

    await insideFakeProjectWithSidekick(
      (dir) => overrideIoStreams(
        code,
        stdout: () => out,
        stderr: () => err,
      ),
    );
    expect(out.lines.join(), '');
    expect(err.lines.join(), '');
  });
}

class _DcliProgressCommand extends Command {
  @override
  final String description = 'My command';

  @override
  final String name = 'dcli-progress';

  @override
  Future<Progress> run() async {
    final output = Progress.capture();
    // ignore: deprecated_member_use_from_same_package
    dart([], progress: output);
    return output;
  }
}

Future<File> installFlutterWrapper(Directory directory) async {
  writeAndRunShellScript(
    r'sh -c "$(curl -fsSL https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh)"',
    workingDirectory: directory,
  );
  final exe = directory.file('flutterw');
  assert(exe.existsSync());
  return exe;
}

class _FakeStdoutStream with Fake implements Stdout {
  final List<List<int>> writes = <List<int>>[];

  List<String> get lines => writes.map(utf8.decode).toList();

  @override
  void add(List<int> bytes) {
    writes.add(bytes);
  }

  @override
  void writeln([Object? object = ""]) {
    writes.add(utf8.encode('$object'));
  }

  @override
  void write(Object? object) {
    writes.add(utf8.encode('$object'));
  }

  @override
  void writeAll(Iterable objects, [String sep = ""]) {
    writes.add(utf8.encode(objects.join(sep)));
  }

  @override
  void writeCharCode(int charCode) {
    writes.add(utf8.encode(String.fromCharCode(charCode)));
  }
}

T overrideIoStreams<T>(
  T Function() body, {
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
