import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateDcli4_255 = MigrationStep.inline(
  (context) {
    final pubspecFile = SidekickContext.sidekickPackage.pubspec;
    final content = pubspecFile.readAsStringSync();

    final pubspec = Pubspec.parse(content);

    pubspec.dependencies.remove('dcli');
    pubspec.dependencies['dcli'] = HostedDependency(
      version: VersionConstraint.parse('^4.0.1-beta.4'),
    );
  },
  name: 'Do not ignore sidekick pubspec.lock file',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/253',
  targetVersion: Version(3, 0, 0, pre: 'preview.0'),
);
