import 'dart:convert';

import 'package:http/http.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Checks and updates dependencies of the generated sidekick CLI
class SidekickVersionChecker {
  const SidekickVersionChecker();

  /// Checks whether the latest version of [package] is being used in the generated sidekick CLI
  ///
  /// [pubspecKeys] can be passed to override the default behavior of reading
  /// the current package version from the pubspec.yaml at ['dependencies'][package]
  /// E.g. ['dev_dependencies', 'some_dev_dependency'] or ['sidekick', 'cli_version']
  Future<bool> isUpToDate({
    required String package,
    List<String>? pubspecKeys,
  }) async {
    final latest = await getLatestPackageVersion(package);
    final current = getCurrentMinimumPackageVersion(
      pubspecKeys ?? ['dependencies', package],
    );

    return latest == current;
  }

  /// Updates the version constraint of [package] to the latest version
  Future<void> updateVersionConstraintToLatest(String package) async =>
      updateVersionConstraint(
        pubspecKeys: ['dependencies', package],
        newMinimumVersion: await getLatestPackageVersion(package),
      );

  /// Sets the version constraint at [pubspecKeys] in pubspec.yaml to [newMinimumVersion]
  ///
  /// If [pinVersion] is true, the new version constraint will only allow [newMinimumVersion]
  /// Else it will allow a version range from [newMinimumVersion] until the next breaking version
  void updateVersionConstraint({
    required List<String> pubspecKeys,
    required Version newMinimumVersion,
    bool pinVersion = false,
  }) {
    final pubspec = Repository.requiredSidekickPackage.pubspec;
    final pubspecContent = pubspec.readAsStringSync();

    final newVersionConstraint = pinVersion
        ? newMinimumVersion.canonicalizedVersion
        : newMinimumVersion.major > 0
            ? '^${newMinimumVersion.canonicalizedVersion}'
            : "'>=${newMinimumVersion.canonicalizedVersion} <1.0.0'";

    // get startTag which matches as many parts of [pubspecKeys] as possible
    String? largestMatch;
    final List<String> missingKeys = () {
      for (int i = 0; i < pubspecKeys.length; i++) {
        final regex = _createNestedYamlKeyRegex(pubspecKeys.sublist(0, i + 1));
        final match = regex.firstMatch(pubspecContent);
        if (match == null) {
          // no match
          return pubspecKeys.sublist(i);
        }
        largestMatch = match.group(0);
      }
      return <String>[];
    }();

    if (largestMatch == null) {
      // everything is missing, add it to the end of the file
      pubspec.writeAsStringSync(
        '\n${missingKeys.mapIndexed(
              (index, key) => '${'  ' * index}$key:',
            ).join('\n')} $newVersionConstraint\n',
        mode: FileMode.append,
      );
    } else {
      // only a part of the nested block is missing
      // add the missing part under the existing part
      pubspec.replaceSectionWith(
        startTag: largestMatch!,
        endTag: '\n',
        content: '${missingKeys.isNotEmpty ? '\n' : ''}${missingKeys.mapIndexed(
              (index, key) =>
                  '${'  ' * (index + pubspecKeys.length - missingKeys.length)}$key:',
            ).join('\n')} $newVersionConstraint',
      );
    }
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
  /// [pubspecKeys] is the path from which to retrieve the version in pubspec.yaml, e.g.
  /// - ['dependencies', 'sidekick_core']
  /// - ['dev_dependencies', 'lint']
  /// - ['sidekick', 'cli_version']
  Version getCurrentMinimumPackageVersion(List<String> pubspecKeys) {
    final versionConstraint = _readFromPubspecYaml(pubspecKeys);
    if (versionConstraint == null) {
      return Version.none;
    }

    final versionConstraintRegEx =
        RegExp('[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)');
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

    Object? current =
        // ignore: avoid_dynamic_calls, pubspec currently is a [YamlMap] but will be a [HashMap] in future versions
        pubspec[path.first];
    for (final key in path.sublist(1)) {
      if (current is Map) {
        current = current[key];
      } else {
        return null;
      }
    }

    return current as String?;
  }

  /// Return regex matching a potentially nested yaml key
  ///
  /// Examples:
  /// - createNestedVersionYamlRegex(['version'])
  ///   -> '^dependencies:'
  /// - createNestedVersionYamlRegex(['dependencies', 'foo'])
  ///   -> '^dependencies:(\\n  .*)*\\n  foo:'
  /// - createNestedVersionYamlRegex(['dependencies', 'foo', 'bar'])
  ///   -> '^dependencies:(\\n  .*)*\\n  foo:(\\n    .*)*\\n    bar:'
  RegExp _createNestedYamlKeyRegex(List<String> keys) {
    final sb = StringBuffer('^');
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      sb.write('$key:');

      if (i < keys.length - 1) {
        final indentation = '  ' * (i + 1);
        sb.write('(\\n$indentation.*)*\\n$indentation');
      }
    }
    return RegExp(
      sb.toString(),
      multiLine: true,
    );
  }
}
