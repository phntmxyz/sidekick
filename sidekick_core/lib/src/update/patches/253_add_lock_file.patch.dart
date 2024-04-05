import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final forceAddPubspecLock253 = MigrationStep.inline(
  (context) {
    final gitignore = SidekickContext.sidekickPackage.root.file('.gitignore');
    final content = gitignore.readAsStringSync();

    if (content.contains('!pubspec.lock')) {
      return;
    }

    gitignore.writeAsStringSync(
      '''
# Lock dependencies for deterministic builds on all systems
!pubspec.lock
''',
      mode: FileMode.append,
    );
  },
  name: 'Do not ignore sidekick pubspec.lock file',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/253',
  targetVersion: Version(2, 1, 2),
);
