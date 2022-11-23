import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Checks and updates dependencies of the generated sidekick CLI
class SidekickVersionChecker {
  const SidekickVersionChecker();

  /// Checks whether the latest version of [package] is being used in the generated sidekick CLI
  ///
  /// [pubspecPath] can be passed to override the default behavior of reading
  /// the current package version from the pubspec.yaml at ['dependencies'][package]
  /// E.g. ['dev_dependencies', 'some_dev_dependency'] or ['sidekick', 'cli_version']
  Future<bool> isUpToDate({
    required String package,
    List<String>? pubspecPath,
  }) async {
    final latest = await getLatestPackageVersion(package);
    final current = getCurrentMinimumPackageVersion(
      pubspecPath ?? ['dependencies', package],
    );

    return latest == current;
  }

  /// Updates the version constraint of [package] to the latest version
  Future<void> updateVersionConstraintToLatest(String package) async =>
      updateVersionConstraint(
        package: package,
        newMinimumVersion: await getLatestPackageVersion(package),
      );

  /// Replaces the current version constraint of [package] in pubspec.yaml with [newMinimumVersion]
  ///
  /// If [pinVersion] is true, the new version constraint will only allow [newMinimumVersion]
  /// Else it will allow a version range from [newMinimumVersion] until the next breaking version
  void updateVersionConstraint({
    required String package,
    required Version newMinimumVersion,
    bool pinVersion = false,
  }) {
    final pubspec = Repository.requiredSidekickPackage.pubspec;
    final lines = pubspec.readAsLinesSync();

    final newVersionConstraint = pinVersion
        ? newMinimumVersion.canonicalizedVersion
        : newMinimumVersion.major > 0
            ? '^${newMinimumVersion.canonicalizedVersion}'
            : "'>=${newMinimumVersion.canonicalizedVersion} <1.0.0'";

    final index = lines.indexWhere((it) => it.startsWith('  $package:'));
    lines[index] = '  $package: $newVersionConstraint';

    pubspec.writeAsStringSync(lines.join('\n'));
  }

  /// Returns the latest version of [package] available on pub.dev
  Future<Version> getLatestPackageVersion(String package) async {
    final response =
        await get(Uri.parse('https://pub.dev/api/packages/$package'));

    if (response.statusCode != HttpStatus.ok) {
      throw "Package '$package' not found on pub.dev";
    }

    final latestVersion =
        ((jsonDecode(response.body) as Map<String, dynamic>)['latest']
            as Map<String, dynamic>)['version'] as String;

    return Version.parse(latestVersion);
  }

  /// Returns the current minimum version of [package] being used in the generated sidekick CLI
  ///
  /// [pubspecPath] is the path from which to retrieve the version in pubspec.yaml, e.g.
  /// - ['dependencies', 'sidekick_core']
  /// - ['dev_dependencies', 'lint']
  /// - ['sidekick', 'cli_version']
  Version getCurrentMinimumPackageVersion(List<String> pubspecPath) {
    final versionConstraint = _readFromPubspecYaml(pubspecPath);
    if (versionConstraint == null) {
      return Version.none;
    }

    final versionConstraintRegEx = RegExp(
      '[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
    );

    final minVersion = versionConstraintRegEx
        .allMatches(versionConstraint)
        .map((e) => e.group(1))
        .whereNotNull()
        .first;

    return Version.parse(minVersion);
  }

  String? _readFromPubspecYaml(List<Object> path) {
    if (path.isEmpty) {
      throw 'Need at least one key in path parameter, but it was empty.';
    }

    final pubspec =
        loadYaml(Repository.requiredSidekickPackage.pubspec.readAsStringSync());

    Object? current = pubspec[path.first];
    for (final key in path.sublist(1)) {
      if (current is Map && current != null) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current as String?;
  }
}
