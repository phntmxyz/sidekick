import 'package:pubspec_manager/pubspec_manager.dart' hide Version;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateDcli4_255 = MigrationStep.inline(
  (context) {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;

    final pubspec = PubSpec.loadFromPath(pubspecFile.path);

    if (pubspec.dependencies.exists('dcli')) {
      pubspec.dependencies.remove('dcli');
    }
    pubspec.dependencies.add(
      DependencyBuilderPubHosted(
        name: 'dcli',
        versionConstraint: '^4.0.1-beta.4',
      ),
    );
    pubspec.save();
  },
  name: 'Update dcli to ^4.0.1-beta.4',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/255',
  targetVersion: Version(3, 0, 0, pre: 'preview.0'),
);
