import 'package:pubspec_manager/pubspec_manager.dart' hide Version;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final updateDcli8PubspecManager3_280 = MigrationStep.inline(
  (context) {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;

    final pubspec = PubSpec.loadFromPath(pubspecFile.path);

    if (pubspec.dependencies.exists('dcli')) {
      pubspec.dependencies.remove('dcli');
    }
    pubspec.dependencies.add(
      DependencyBuilderPubHosted(
        name: 'dcli',
        versionConstraint: '^8.2.0',
      ),
    );

    if (pubspec.dependencies.exists('pubspec_manager')) {
      pubspec.dependencies.remove('pubspec_manager');
    }
    pubspec.dependencies.add(
      DependencyBuilderPubHosted(
        name: 'pubspec_manager',
        versionConstraint: '^3.0.0',
      ),
    );

    pubspec.save();
  },
  name: 'Update dcli to ^8.2.0 and pubspec_manager to ^3.0.0',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/280',
  targetVersion: Version(3, 1, 0),
);
