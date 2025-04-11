import 'package:pubspec_manager/pubspec_manager.dart' hide Version;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateDart35dcli7_260 = MigrationStep.inline(
  (context) async {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;

    final pubspec = PubSpec.loadFromPath(pubspecFile.path);

    pubspec.environment.set(sdk: "'>=3.5.0 <4.0.0'");
    if (pubspec.dependencies.exists('dcli')) {
      pubspec.dependencies.remove('dcli');
    }
    pubspec.dependencies.add(
      DependencyBuilderPubHosted(
        name: 'dcli',
        versionConstraint: '^7.0.2',
      ),
    );
    pubspec.save();
  },
  name: 'Update dcli to 7.0.2 and sdk constraint to 3.5.0',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/260',
  targetVersion: Version(3, 0, 0),
);
