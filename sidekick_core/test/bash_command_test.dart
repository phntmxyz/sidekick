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
          withStdIn: false,
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
          withStdIn: false,
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
          withStdIn: false,
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
}
