import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec2/pubspec2.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateDcli4_255 = MigrationStep.inline(
  (context) async {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;
    final content = pubspecFile.readAsStringSync();

    final pubspec = PubSpec.fromYamlString(content);

    pubspec.dependencies.remove('dcli');
    pubspec.dependencies['dcli'] = HostedReference(
      VersionConstraint.parse('^4.0.1-beta.4'),
    );
    await pubspec.save(pubspecFile.parent);
  },
  name: 'Do not ignore sidekick pubspec.lock file',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/253',
  targetVersion: Version(3, 0, 0, pre: 'preview.0'),
);
