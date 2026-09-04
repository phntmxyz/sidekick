import 'dart:async';
import 'dart:convert';

import 'package:sidekick_core/sidekick_core.dart' hide isEmpty;
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('runs cleanups in reverse registration order after the command',
      () async {
    final log = <String>[];
    await _runCommand(() async {
      addCleanup(() => log.add('first'));
      addCleanup(() => log.add('second'));
      addCleanup(() => log.add('third'));
      expect(log, isEmpty,
          reason: 'cleanups run after the command, not immediately');
    });
    expect(log, ['third', 'second', 'first']);
  });

  test('awaits async cleanups', () async {
    final log = <String>[];
    await _runCommand(() async {
      addCleanup(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        log.add('slow');
      });
      addCleanup(() => log.add('fast'));
    });
    expect(log, ['fast', 'slow']);
  });

  test('runs cleanups registered while cleaning up', () async {
    final log = <String>[];
    await _runCommand(() async {
      addCleanup(() {
        log.add('outer');
        addCleanup(() => log.add('nested'));
      });
    });
    expect(log, ['outer', 'nested']);
  });

  test('runs cleanups when the command throws and rethrows the command error',
      () async {
    final log = <String>[];
    await expectLater(
      _runCommand(() {
        addCleanup(() => log.add('cleaned'));
        throw 'command failed';
      }),
      throwsA('command failed'),
    );
    expect(log, ['cleaned']);
  });

  test('runs every cleanup when one throws and rethrows the first error',
      () async {
    final log = <String>[];
    final fakeStderr = FakeStdoutStream();
    await expectLater(
      _runCommand(
        () async {
          addCleanup(() => throw 'last cleanup failed');
          addCleanup(() => throw 'first cleanup failed');
          addCleanup(() => log.add('cleaned'));
        },
        stderr: fakeStderr,
      ),
      throwsA('first cleanup failed'),
    );
    expect(log, ['cleaned']);
    expect(fakeStderr.lines.join('\n'),
        contains('Cleanup failed: last cleanup failed'));
    expect(
        fakeStderr.lines.join('\n'), isNot(contains('first cleanup failed')));
  });

  test('command error wins over cleanup errors, which are printed', () async {
    final fakeStderr = FakeStdoutStream();
    await expectLater(
      _runCommand(
        () {
          addCleanup(() => throw 'cleanup failed');
          throw 'command failed';
        },
        stderr: fakeStderr,
      ),
      throwsA('command failed'),
    );
    expect(fakeStderr.lines.join('\n'),
        contains('Cleanup failed: cleanup failed'));
  });

  test('throws when no command is executing', () async {
    expect(() => addCleanup(() {}),
        throwsA(isA<OutOfCommandRunnerScopeException>()));

    // the scope is gone again once the command finished
    await _runCommand(() async {});
    expect(() => addCleanup(() {}),
        throwsA(isA<OutOfCommandRunnerScopeException>()));
  });

  test('a nested run cleans up its own cleanups when it finishes', () async {
    final log = <String>[];
    await insideFakeProjectWithSidekick((_) async {
      final runner = initializeSidekick();
      runner.addCommand(DelegatedCommand(
        name: 'inner',
        block: () => addCleanup(() => log.add('inner')),
      ));
      runner.addCommand(DelegatedCommand(
        name: 'outer',
        block: () async {
          addCleanup(() => log.add('outer'));
          await runner.run(['inner']);
          expect(log, ['inner']);
        },
      ));
      await runner.run(['outer']);
    });
    expect(log, ['inner', 'outer']);
  });

  group('termination signals', () {
    for (final (signal, expectedExitCode) in [
      (ProcessSignal.sigint, 130),
      (ProcessSignal.sigterm, 143),
    ]) {
      test('$signal runs the cleanups and exits with $expectedExitCode',
          () async {
        final cli = _FakeCli();
        final process = await cli.start(['hang']);
        await process.stdout.firstWhere((line) => line == 'ready');

        process.kill(signal);

        expect(await process.exitCode, expectedExitCode);
        expect(process.stdoutLines,
            containsAllInOrder(['ready', 'cleanup 2', 'cleanup 1']));
        expect(process.stderrLines.join('\n'),
            contains('Received $signal, cleaning up'));
      });
    }

    test('a second signal exits immediately without waiting for cleanups',
        () async {
      final cli = _FakeCli();
      final process = await cli.start(['hang', '--stuck-cleanup']);
      await process.stdout.firstWhere((line) => line == 'ready');

      process.kill(ProcessSignal.sigint);
      await process.stdout.firstWhere((line) => line == 'stuck');
      process.kill(ProcessSignal.sigint);

      expect(await process.exitCode, 130);
      expect(process.stdoutLines, isNot(contains('cleanup 1')));
    });

    test('a signal while a cleanup is already running waits for it', () async {
      final cli = _FakeCli();
      final process = await cli.start(['hang', '--return']);
      await process.stdout.firstWhere((line) => line == 'cleanup 2 started');

      process.kill(ProcessSignal.sigint);

      expect(await process.exitCode, 130);
      expect(process.stdoutLines,
          containsAllInOrder(['cleanup 2 started', 'cleanup 2', 'cleanup 1']));
    });

    test('a signal without pending cleanups exits quietly', () async {
      final cli = _FakeCli();
      final process = await cli.start(['hang', '--no-cleanups']);
      await process.stdout.firstWhere((line) => line == 'ready');

      process.kill(ProcessSignal.sigint);

      expect(await process.exitCode, 130);
      expect(process.stderrLines.join('\n'), isNot(contains('cleaning up')));
    });
  }, testOn: 'posix');
}

/// Runs [body] as the body of a command in a fake sidekick project
Future<void> _runCommand(
  Future<void> Function() body, {
  FakeStdoutStream? stderr,
}) async {
  await insideFakeProjectWithSidekick((_) async {
    await overrideIoStreams(
      stderr: stderr == null ? null : () => stderr,
      body: () async {
        final runner = initializeSidekick();
        runner.addCommand(DelegatedCommand(name: 'cmd', block: body));
        await runner.run(['cmd']);
      },
    );
  });
}

/// A minimal sidekick CLI in a temp dir, depending on this sidekick_core, that
/// can be started as a separate process to test signal handling
class _FakeCli {
  _FakeCli() : this._(Directory.systemTemp.createTempSync('sidekick_cleanup'));

  _FakeCli._(this.projectRoot)
      : packageDir = projectRoot.directory('packages/dash') {
    projectRoot.file('pubspec.yaml').writeAsStringSync('name: main_project\n');
    projectRoot.file('dash').createSync();
    packageDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('name: dash\n');
    packageDir.file('bin/main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(_fakeCliMain);
    packageDir.file('lib/dash_sidekick.dart').createSync(recursive: true);
    addTearDown(() => projectRoot.deleteSync(recursive: true));
  }

  final Directory projectRoot;
  final Directory packageDir;

  Future<_CliProcess> start(List<String> args) async {
    final process = await Process.start(
      // The VM binary running this test, not a `dart` wrapper script from PATH
      // which would receive the signal instead of the CLI
      Platform.resolvedExecutable,
      [
        // `dart run` executes the script in a child VM and doesn't forward
        // signals to it either, so run the script in this VM directly
        '--disable-dart-dev',
        // Resolve sidekick_core through the package config of this test run
        // instead of running `dart pub get` against whatever is on PATH
        '--packages=${Directory.current.path}/.dart_tool/package_config.json',
        'bin/main.dart',
        ...args,
      ],
      workingDirectory: packageDir.path,
      environment: {
        'SIDEKICK_PACKAGE_HOME': packageDir.absolute.path,
        'SIDEKICK_ENTRYPOINT_HOME': projectRoot.absolute.path,
        'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
      },
    );
    final cliProcess = _CliProcess(process);
    addTearDown(() => process.kill(ProcessSignal.sigkill));
    return cliProcess;
  }
}

class _CliProcess {
  _CliProcess(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stdoutLines.add(line);
      _stdout.add(line);
    }, onDone: _stdout.close);
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrLines.add);
  }

  final Process _process;
  final _stdout = StreamController<String>.broadcast();
  final stdoutLines = <String>[];
  final stderrLines = <String>[];

  Stream<String> get stdout => _stdout.stream;

  Future<int> get exitCode => _process.exitCode;

  void kill(ProcessSignal signal) => _process.kill(signal);
}

const _fakeCliMain = '''
import 'package:sidekick_core/sidekick_core.dart' hide isEmpty;

Future<void> main(List<String> args) async {
  final runner = initializeSidekick();
  runner.addCommand(HangCommand());
  runner.addCommand(OuterCommand(runner));
  runner.addCommand(InnerCommand());
  await runner.run(args);
}

/// Registers cleanups, then waits to be interrupted
class HangCommand extends Command<void> {
  HangCommand() {
    argParser.addFlag('stuck-cleanup', help: 'Register a cleanup that never completes');
    argParser.addFlag('no-cleanups', help: 'Register no cleanups at all');
    argParser.addFlag('return', help: 'Return right away so the cleanups start running');
  }

  @override
  String get name => 'hang';

  @override
  String get description => 'hangs until interrupted';

  @override
  Future<void> run() async {
    if (argResults!['no-cleanups'] != true) {
      addCleanup(() => print('cleanup 1'));
      if (argResults!['stuck-cleanup'] == true) {
        addCleanup(() async {
          print('stuck');
          await Future<void>.delayed(const Duration(minutes: 1));
        });
      } else {
        addCleanup(() async {
          print('cleanup 2 started');
          await Future<void>.delayed(const Duration(milliseconds: 500));
          print('cleanup 2');
        });
      }
    }
    print('ready');
    if (argResults!['return'] == true) {
      return;
    }
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}

/// Registers a cleanup that registers another one, then runs [InnerCommand]
class OuterCommand extends Command<void> {
  OuterCommand(this.runner);

  final CommandRunner<void> runner;

  @override
  String get name => 'outer';

  @override
  String get description => 'runs inner';

  @override
  Future<void> run() async {
    addCleanup(() {
      print('outer cleanup');
      addCleanup(() => print('cleanup registered by outer cleanup'));
    });
    await runner.run(['inner']);
  }
}

/// Hangs until interrupted
class InnerCommand extends Command<void> {
  @override
  String get name => 'inner';

  @override
  String get description => 'hangs until interrupted';

  @override
  Future<void> run() async {
    print('inner ready');
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}
''';
