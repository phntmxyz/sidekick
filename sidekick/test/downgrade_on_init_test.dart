import 'package:dcli/dcli.dart' as dcli;
import 'package:path/path.dart' as path;
import 'package:sidekick/sidekick.dart' as sidekick show main;
import 'package:sidekick_core/sidekick_core.dart' hide version;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as descriptor;
import 'package:test_process/test_process.dart';
import 'util/cli_runner.dart';

//TODO(danielmolnar) Remove text_descriptor dependency once this file gets deleted
/// Starts a Dart process running [script] in a main method.
Future<TestProcess> _startDartProcess(String script) {
  final dartPath = path.join(descriptor.sandbox, 'test.dart');
  File(dartPath).writeAsStringSync('''
    import 'dart:async';
    import 'dart:convert';
    import 'dart:io';
    var stdinLines = stdin
        .transform(utf8.decoder)
        .transform(new LineSplitter());
    void main() {
      $script
    }
  ''');
  return TestProcess.start(Platform.executable, ['--enable-asserts', dartPath]);
}

void main() {
  test('stdin writes to the process', () async {
    final process = await _startDartProcess(r'''
      stdinLines.listen((line) => print("> $line"));
    ''');

    process.stdin.writeln('hello');
    await expectLater(process.stdout, emits('> hello'));
    process.stdin.writeln('world');
    await expectLater(process.stdout, emits('> world'));
    await process.kill();
  });

  group('Case of pre-existing sidekick in directory', () {
    test(
      'Warning',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final package = tempDir.directory('dashi_sidekick')..createSync();
        package.file('pubspec.yaml').writeAsStringSync("""
name: dashi_sidekick
environment:
  sdk: '>=2.14.0 <3.0.0'
sidekick:
  cli_version: 0.13.1
            """);

        // Create sidekick again in the same directory
        final TestProcess process = await cachedGlobalSidekickCli.run(
          ['init', '-n', 'dashi', '-c', '.'],
          workingDirectory: package.parent,
        );
        await process.shouldExit(0);

        await expectLater(
          process.stdout,
          emitsThrough(
            "Welcome to sidekick. You're about to initialize a sidekick project",
          ),
        );

        await expectLater(
          process.stdout,
          emitsThrough(
            "You already have an existing sidekick project initialized in dashi_sidekick.",
          ),
        );
        await expectLater(
          process.stdout,
          emitsThrough(
            "In order to update your existing project run ${dcli.cyan('<cli> sidekick update')} instead.",
          ),
        );
      },
    );
    test(
      'Override',
      () async {
        final tempDir = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final package = tempDir.directory('dashi_sidekick')..createSync();
        package.file('pubspec.yaml').writeAsStringSync("""
name: dashi_sidekick
environment:
  sdk: '>=2.14.0 <3.0.0'
sidekick:
  cli_version: 0.13.1
            """);

        // Create sidekick again in the same directory
        final TestProcess process = await cachedGlobalSidekickCli.run(
          ['init', '-n', 'dashi', '-c', '.'],
          workingDirectory: package.parent,
          forwardStdio: true,
        );

        process.stdoutStream().listen((event) {
          if (event == "Do you want to override your existing CLI?") {
            process.stdin.writeln('y');
          }
          print(event);
        });

        process.stdin.writeln('y');

        await process.shouldExit(0);

        await expectLater(
          process.stdout,
          emitsThrough(
            "Welcome to sidekick. You're about to initialize a sidekick project",
          ),
        );

        await expectLater(
          process.stdout,
          emitsThrough(
            "You already have an existing sidekick project initialized in dashi_sidekick.",
          ),
        );
        await expectLater(
          process.stdout,
          emitsThrough(
            "In order to update your existing project run ${dcli.cyan('<cli> sidekick update')} instead.",
          ),
        );
        await expectLater(
          process.stdout,
          emitsThrough(
            "Do you want to override your existing CLI?",
          ),
        );

        await expectLater(
          process.stdout,
          emitsThrough(
            "y",
          ),
        );
      },
    );
  });

/*  secondProcess.stdoutStream().listen((event) {
    if (event == "Do you want to override your existing CLI?") {
      secondProcess.stdin.writeln('y');
    }
    print(event);
  });

  await secondProcess.shouldExit(0);*/
}
