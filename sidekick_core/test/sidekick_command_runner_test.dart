import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'true';
  });

  tearDown(() {
    addTearDown(() => env['SIDEKICK_ENABLE_UPDATE_CHECK'] = null);
  });

  test('prints warnings to update outdated CLI', () async {
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(
              name: 'dash',
            );

            await runner.run(['-h']);

            final expectedCliVersionIntegrityWarning =
                'The sidekick_core version is incompatible with the bash scripts '
                'in /tool and entrypoint because you probably updated the '
                'sidekick_core dependency of your CLI package manually.\n'
                'Please run ${cyan('dash sidekick update')} to repair your CLI.';
            final expectedOutdatedWarning = '${yellow('Update available!')}\n'
                'Run ${cyan('dash sidekick update')} to update your CLI.';
            final expectedWarnings = [
              expectedCliVersionIntegrityWarning,
              expectedOutdatedWarning,
            ];

            expect(fakeStderr.lines, expectedWarnings);
          },
        );
      },
      sidekickCoreVersion: "0.0.2",
      sidekickCliVersion: "0.0.1",
    );
  });

  test(
      'prints no warnings when offline and CLI version matches sidekick_core version',
      () async {
    addTearDown(() => HttpOverrides.global = null);
    // mock being offline by overriding with a HttpClient which only throws
    HttpOverrides.global = _ThrowingHttpClient();

    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(
              name: 'dash',
            );

            await runner.run(['-h']);

            expect(fakeStderr.lines.isEmpty, isTrue);
          },
        );
      },
      sidekickCoreVersion: "0.0.1",
      sidekickCliVersion: "0.0.1",
    );
  });
}

class _ThrowingHttpClient extends Fake implements HttpOverrides {}
