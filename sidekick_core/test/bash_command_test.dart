import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('bash command receives arguments', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BashCommand(
          script: () => 'echo \$@',
          description: 'description',
          name: 'script',
        ),
      );
      final fakeStdOut = FakeStdoutStream();
      await overrideIoStreams(
        stdout: () => fakeStdOut,
        body: () => runner.run(['script', 'asdf', 'qwer']),
      );

      expect(fakeStdOut.lines, contains('asdf qwer'));
    });
  });

  test('workingDirectory default to cwd', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BashCommand(
          script: () => 'echo \$PWD',
          description: 'description',
          name: 'script',
        ),
      );
      final fakeStdOut = FakeStdoutStream();
      await overrideIoStreams(
        stdout: () => fakeStdOut,
        body: () => runner.run(['script']),
      );

      expect(fakeStdOut.lines.join(), endsWith(Directory.current.path));
    });
  });

  test('workingDirectory can be set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final subDir = dir.directory('someSubDir')..createSync();
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BashCommand(
          script: () => 'echo \$PWD',
          description: 'description',
          name: 'script',
          workingDirectory: subDir,
        ),
      );
      final fakeStdOut = FakeStdoutStream();
      await overrideIoStreams(
        stdout: () => fakeStdOut,
        body: () => runner.run(['script']),
      );

      expect(fakeStdOut.lines.join(), endsWith(subDir.path));
    });
  });

  test('throw BashCommandException on error', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BashCommand(
          script: () => '#scriptContent\nexit 34',
          description: 'description',
          name: 'script',
        ),
      );
      try {
        await runner.run(['script']);
        fail('should throw');
      } catch (e) {
        expect(
          e,
          isA<BashCommandException>()
              .having((it) => it.exitCode, 'exitCode', 34)
              .having((it) => it.script, 'script', contains('#scriptContent'))
              .having((it) => it.commandName, 'commandName', 'script')
              .having((it) => it.arguments, 'arguments', [])
              .having((it) => it.cause, 'cause', isA<RunException>())
              .having(
                (it) => it.stack,
                'stack',
                isA<StackTrace>().having(
                  (it) => it.toString(),
                  'toString',
                  contains('bash_command_test.dart'),
                ),
              )
              .having(
                (it) => it.toString(),
                'toString()',
                contains('exitCode=34'),
              )
              .having(
                (it) => it.toString(),
                'toString()',
                contains('<no arguments>'),
              ),
        );
      }
    });
  });

  test('BashCommandException contains arguments', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(
        BashCommand(
          script: () => '#scriptContent\nexit 34',
          description: 'description',
          name: 'script',
        ),
      );
      try {
        await runner.run(['script', 'asdf', 'qwer']);
        fail('should throw');
      } catch (e) {
        expect(
          e,
          isA<BashCommandException>()
              .having((it) => it.exitCode, 'exitCode', 34)
              .having(
            (it) => it.arguments,
            'arguments',
            ['asdf', 'qwer'],
          ).having(
            (it) => it.toString(),
            'toString()',
            contains('asdf qwer'),
          ),
        );
      }
    });
  });
}
