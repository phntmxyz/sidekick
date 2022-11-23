import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'util/local_testing.dart';

void main() {
  test('prints warnings to update outdated CLI', () async {
    final printLog = <String>[];
    // override print to verify output
    final spec = ZoneSpecification(
      print: (_, __, ___, line) => printLog.add(line),
    );
    await Zone.current.fork(specification: spec).run(() async {
      await insideFakeProjectWithSidekick(
        (tempDir) async {
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

          expect(
            printLog,
            containsAllInOrder([
              expectedCliVersionIntegrityWarning,
              expectedOutdatedWarning,
            ]),
          );
        },
        sidekickCoreVersion: "0.0.2",
        sidekickCliVersion: "0.0.1",
      );
    });
  });
}
