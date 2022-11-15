import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Updates the sidekick cli
///
///
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  Future<void> run() async {
    // TODO (?) read version with which this sidekick CLI was generated (prerequisite: write this info into new block in pubspec) + current sidekick version on pub
    // TODO read this package's sidekick_core version + current sidekick_core version on pub

    final latestSidekickCoreVersion =
        await getLatestPackageVersion('sidekick_core');

    final currentMinimumSidekickCoreVersion =
        getCurrentMinimumPackageVersion('sidekick_core');

    if (currentMinimumSidekickCoreVersion >= latestSidekickCoreVersion) {
      print('No need to update because you are already using the '
          'latest version of sidekick_core ($latestSidekickCoreVersion)');
      return;
    }

    // TODO update pubspec.yaml

    updateVersionConstraint('sidekick_core', latestSidekickCoreVersion);
    dart(['pub', 'get'], workingDirectory: Repository.requiredCliPackage);

    // TODO generate new shell scripts (just overwrite because users shouldn't have to touch these files anyways)
    // ? how to call new generator (sidekick_core/lib/src/template)? maybe with reflection?

    // TODO apply changes to CLI dart files. how to preserve changes by users? Override everything but keep imports + ..addCommand(...)?
  }

  Future<Version> getLatestPackageVersion(String package) async {
    final response =
        await get(Uri.parse('https://pub.dev/api/packages/$package'));

    if (response.statusCode != HttpStatus.ok) {
      throw "Package '$package' not found on pub.dev";
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final latestVersion = body['latest']['version'] as String;

    return Version.parse(latestVersion);
  }

  Version getCurrentMinimumPackageVersion(String package) {
    final regEx = RegExp(
      '^  $package:\\s*[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
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
