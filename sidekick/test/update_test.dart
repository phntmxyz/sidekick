import 'dart:async';

import 'package:process/process.dart';
import 'package:sidekick/sidekick.dart';
import 'package:sidekick/src/commands/update_command.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  late MockProcessManager mockProcessManager;

  setUp(() {
    mockProcessManager = MockProcessManager();
  });

  tearDown(() {
    verifyNoMoreInteractions(mockProcessManager);
  });

  test('no update when CLI already is at specified version', () async {
    final printLog = <String>[];

    Future<void> code() async {
      final runner =
          GlobalSidekickCommandRunner(processManager: mockProcessManager);

      await runner.run(['update', version.toString()]);
      expect(
        printLog,
        contains('No need to update because the global sidekick CLI already is '
            'at the specified or latest version ($version).'),
      );
    }

    await runZoned(
      code,
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  });

  test('updates CLI to latest version', () async {
    final printLog = <String>[];

    Future<void> code() async {
      when(() => mockProcessManager.runSync(any()))
          .thenAnswer((_) => FakeProcessResult());
      final latest = Version(13, 12, 1989);
      fakeGetLatestDependencyVersion({'sidekick': latest});
      final runner =
          GlobalSidekickCommandRunner(processManager: mockProcessManager);

      await runner.run(['update']);

      verify(
        () => mockProcessManager
            .runSync(['dart', 'pub', 'global', 'activate', 'sidekick', latest]),
      ).called(1);

      expect(
        printLog,
        contains(
          green('Successfully updated sidekick from $version to $latest!'),
        ),
      );
    }

    await runZoned(
      code,
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  });

  test('handles update errors', () async {
    final printLog = <String>[];

    Future<void> code() async {
      when(() => mockProcessManager.runSync(any()))
          .thenAnswer((_) => FakeProcessResult(exitCode: 1, stderr: 'foo'));

      final latest = Version(13, 12, 1989);
      fakeGetLatestDependencyVersion({'sidekick': latest});
      final runner =
          GlobalSidekickCommandRunner(processManager: mockProcessManager);

      await expectLater(
        () => runner.run(['update']),
        throwsA('Updating sidekick failed, this is the stderr output of '
            '`dart pub global activate`:\nfoo'),
      );

      verify(
        () => mockProcessManager
            .runSync(['dart', 'pub', 'global', 'activate', 'sidekick', latest]),
      ).called(1);

      expect(
        printLog,
        contains(
          red('Update to $latest failed. Please check your internet '
              'connection and whether the sidekick version exists on pub.dev.'),
        ),
      );
    }

    await runZoned(
      code,
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class FakeProcessResult extends Fake implements ProcessResult {
  FakeProcessResult({
    this.exitCode = 0,
    this.stderr,
  });

  @override
  final int exitCode;

  @override
  final String? stderr;
}

void fakeGetLatestDependencyVersion(Map<String, Version> latestVersions) {
  testFakeGetLatestDependencyVersion =
      (String dependency) async => latestVersions[dependency]!;
  addTearDown(() => testFakeGetLatestDependencyVersion = null);
}
