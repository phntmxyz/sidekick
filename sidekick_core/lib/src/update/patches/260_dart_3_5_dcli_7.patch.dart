import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec2/pubspec2.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateDart35dcli7_260 = MigrationStep.inline(
  (context) async {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;
    final content = pubspecFile.readAsStringSync();

    final pubspec = PubSpec.fromYamlString(content);
    pubspec.copy(
      environment: Environment(
        VersionConstraint.parse('>=3.5.0 <4.0.0'),
        null,
      ),
    );

    pubspec.dependencies.remove('dcli');
    pubspec.dependencies['dcli'] = HostedReference(
      VersionConstraint.parse('^7.0.2'),
    );
    await pubspec.save(pubspecFile.parent);
  },
  name: 'Update dcli to 7.0.2 and sdk constraint to 3.5.0',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/260',
  targetVersion: Version(3, 0, 0),
);
