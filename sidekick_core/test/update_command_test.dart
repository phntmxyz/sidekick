import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/version_checker.dart';
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

          final targetVersion = Version(0, 12, 0);

          runner.addCommand(UpdateCommand());
          await runner.run(['update', targetVersion.toString()]);

          final versionChecker =
              VersionChecker(Repository.requiredSidekickPackage);

          final sidekickVersionAfterUpdate = versionChecker
              .getMinimumVersionConstraint(['sidekick', 'cli_version']);
          final sidekickCoreVersionAfterUpdate =
              versionChecker.getMinimumVersionConstraint(
            ['dependencies', 'sidekick_core'],
          );

          expect(sidekickVersionAfterUpdate, targetVersion);
          expect(sidekickCoreVersionAfterUpdate, targetVersion);

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
                'Updating sidekick CLI dash from version 0.0.0 to $targetVersion ...',
              ),
              green(
                'Successfully updated sidekick CLI dash from version 0.0.0 to $targetVersion!',
              ),
            ]),
          );
        },
        overrideSidekickCoreWithLocalDependency: true,
        overrideSidekickDartWithSystemDart: true,
        sidekickCliVersion: '0.0.0',
      );
    });
  });

  test('UpdateCommand does not downgrade', () async {
    final printLog = <String>[];
    // override print to verify output
    final spec = ZoneSpecification(
      print: (_, __, ___, line) => printLog.add(line),
    );
    await Zone.current.fork(specification: spec).run(() async {
      await insideFakeProjectWithSidekick(
        (projectDir) async {
          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: systemDartSdkPath(),
          );

          runner.addCommand(UpdateCommand());
          await runner.run(['update', '0.1.0']);

          final versionChecker =
              VersionChecker(Repository.requiredSidekickPackage);

          final sidekickVersionAfterUpdate = versionChecker
              .getMinimumVersionConstraint(['sidekick', 'cli_version']);
          final sidekickCoreVersionAfterUpdate =
              versionChecker.getMinimumVersionConstraint(
            ['dependencies', 'sidekick_core'],
          );
          expect(sidekickVersionAfterUpdate, Version(0, 5, 0));
          expect(sidekickCoreVersionAfterUpdate, Version(0, 5, 0));

          expect(
            printLog,
            contains('No need to update because you are already using the '
                'latest sidekick cli version.'),
          );
        },
        overrideSidekickCoreWithLocalDependency: true,
        overrideSidekickDartWithSystemDart: true,
        sidekickCliVersion: '0.5.0',
        sidekickCoreVersion: '0.5.0',
      );
    });
  });
}
