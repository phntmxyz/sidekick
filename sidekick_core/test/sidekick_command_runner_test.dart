import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'util/fake_stdio.dart';
import 'util/local_testing.dart';

void main() {
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
}
