import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'util/local_testing.dart';

void main() {
  test('throws when CLI version does not match sidekick_core version',
      () async {
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        final runner = initializeSidekick(
          name: 'dash',
        );

        final expectedErrorMessage =
            'You probably updated the sidekick_core dependency of your '
            'CLI package manually.\n'
            'Please run ${cyan('dash sidekick update')} to repair your CLI.';

        var errorOccured = false;
        await runner.run(['-h']).onError((error, stackTrace) {
          expect(error, expectedErrorMessage);
          errorOccured = true;
        });
        expect(errorOccured, isTrue);
      },
      sidekickCoreVersion: "1.1.0",
      sidekickCliVersion: "1.0.0",
    );
  });
}
