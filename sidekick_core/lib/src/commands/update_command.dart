import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update_sidekick_cli.dart';

/// Updates the sidekick cli
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  Future<void> run() async {
    // TODO instead read version with which this sidekick CLI was generated (prerequisite: write this info into new block in pubspec) + current sidekick version on pub
    // do not read sidekick_core version

    // read this package's sidekick_core version + latest sidekick_core version on pub
    // TODO use vgv package pub updater
    final latestSidekickCoreVersion =
        await getLatestPackageVersion('sidekick_core');
    final currentMinimumSidekickCoreVersion =
        getCurrentMinimumPackageVersion('sidekick_core');

    if (currentMinimumSidekickCoreVersion >= latestSidekickCoreVersion) {
      print('No need to update because you are already using the '
          'latest version of sidekick_core ($latestSidekickCoreVersion)');
      return;
    }

    // update pubspec.yaml
    updateVersionConstraint('sidekick_core', latestSidekickCoreVersion);
    dart(['pub', 'upgrade'], workingDirectory: Repository.requiredCliPackage);

    // generate new shell scripts + update CLI dart files while preserving changes of users

    // call the latest update script
    // the process running this command uses the old dependency of sidekick_core
    // and its dependencies can't be changed at runtime
    // as a workaround, a new process is started (with `dart([updateScript.path])`)
    // which contains the latest sidekick_core dependency
    // and thus the latest update script
    final updateScript =
        Repository.requiredSidekickPackage.buildDir.file('update.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'package:sidekick_core/src/update_sidekick_cli.dart' as update;
Future<void> main() async {
  await update.main(['${Repository.requiredSidekickPackage.cliName}']);
}
''');
    /* TODO pass mainProjectPath to update.main
    final mainProjectPath = mainProject != null
        ? relative(mainProject!.root.path, from: repoRoot.absolute.path)
        : null;
*/
    dart([updateScript.path]);

    updateScript.deleteSync();
  }

  Future<Version> getLatestPackageVersion(String package) async {
    final response =
        await get(Uri.parse('https://pub.dev/api/packages/$package'));

    if (response.statusCode != HttpStatus.ok) {
      throw "Package '$package' not found on pub.dev";
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final latestVersion =
        (body['latest'] as Map<String, dynamic>)['version'] as String;

    return Version.parse(latestVersion);
  }

  Version getCurrentMinimumPackageVersion(String package) {
    final regEx = RegExp(
      '\n  $package:\\s*[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
    );
    final pubspec =
        Repository.requiredSidekickPackage.pubspec.readAsStringSync();

    final minVersion =
        regEx.allMatches(pubspec).map((e) => e.group(1)).whereNotNull().single;

    return Version.parse(minVersion);
  }

  void updateVersionConstraint(String package, Version newMinimumVersion) {
    final pubspec = Repository.requiredSidekickPackage.pubspec;
    final lines = pubspec.readAsLinesSync();

    final newVersionConstraint = newMinimumVersion.major > 0
        ? '^${newMinimumVersion.canonicalizedVersion}'
        : "'>=${newMinimumVersion.canonicalizedVersion} <1.0.0'";

    final index = lines.indexWhere((it) => it.startsWith('  $package:'));
    assert(index > 0);
    lines[index] = '  $package: $newVersionConstraint';

    pubspec.writeAsStringSync(lines.join('\n'));
  }
}
