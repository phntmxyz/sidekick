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

  test('print error code and script on error', () async {
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
      final fakeStdOut = FakeStdoutStream();
      final fakeStdErr = FakeStdoutStream();
      try {
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          stderr: () => fakeStdErr,
          body: () => runner.run(['script']),
        );
        fail('should throw');
      } catch (e) {
        expect(
          e,
          isA<RunException>().having((it) => it.exitCode, 'exitCode', 34),
        );
      }

      expect(fakeStdErr.lines.join(), contains('exitCode=34'));
      expect(fakeStdErr.lines.join(), contains('#scriptContent'));
      expect(fakeStdErr.lines.join(), contains('exit 34'));
      expect(
        fakeStdErr.lines.join(),
        contains("Error executing script 'script'"),
      );
      expect(fakeStdOut.lines.join(), "");
    });
  });
}
