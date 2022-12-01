import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/sidekick_version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('UpdateCommand generates new files', () async {
    final printLog = <String>[];
    // override print to verify output
    final spec = ZoneSpecification(
      print: (_, __, ___, line) => printLog.add(line),
    );
    await Zone.current.fork(specification: spec).run(() async {
      await insideFakeProjectWithSidekick(
        (projectDir) async {
          final sidekickDir = projectDir.directory('packages/dash');
          final expectedFilesToGenerate = [
            'tool/download_dart.sh',
            'tool/install.sh',
            'tool/run.sh',
            'tool/sidekick_config.sh',
          ].map(sidekickDir.file);

          for (final file in expectedFilesToGenerate) {
            expect(
              !file.existsSync() || file.readAsStringSync().isEmpty,
              isTrue,
              reason: '${file.path} exists or is not empty',
            );
          }

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: systemDartSdkPath(),
          );

          runner.addCommand(UpdateCommand());
          await runner.run(['update']);

          const versionChecker = SidekickVersionChecker();

          final sidekickVersionAfterUpdate = versionChecker
              .getCurrentMinimumPackageVersion(['sidekick', 'cli_version']);
          final sidekickCoreVersionAfterUpdate =
              versionChecker.getCurrentMinimumPackageVersion(
            ['dependencies', 'sidekick_core'],
          );
          final latestSidekickCoreVersion =
              await versionChecker.getLatestPackageVersion('sidekick_core');

          expect(sidekickVersionAfterUpdate, latestSidekickCoreVersion);
          expect(sidekickCoreVersionAfterUpdate, latestSidekickCoreVersion);

          for (final file in expectedFilesToGenerate) {
            expect(
              file.existsSync() && file.readAsStringSync().isNotEmpty,
              isTrue,
              reason: '${file.path} does not exist or is empty',
            );
          }

          expect(
            printLog,
            containsAllInOrder([
              grey(
                'Updating sidekick CLI dash from version 0.0.0 to $latestSidekickCoreVersion ...',
              ),
              green(
                'Successfully updated sidekick CLI dash from version 0.0.0 to $latestSidekickCoreVersion!',
              ),
            ]),
          );
        },
        overrideSidekickCoreWithLocalDependency: true,
        overrideSidekickDartWithSystemDart: true,
      );
    });
  });
}