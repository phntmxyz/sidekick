import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

// ignore: avoid_classes_with_only_static_members
/// Checks and updates dependencies
abstract class VersionChecker {
  /// Checks whether the latest version of [package] is [version]
  static Future<bool> isPackageUpToDate({
    required String package,
    required Version version,
  }) async {
    final latest = await getLatestDependencyVersion(package);
    return latest == version;
  }

  /// Checks whether the latest version of [dependency] is being used in [package]
  ///
  /// [pubspecKeys] can be passed to override the default behavior of reading
  /// the current package version from the pubspec.yaml at ['dependencies'][dependency]
  /// E.g. ['dev_dependencies', 'some_dev_dependency'] or ['sidekick', 'cli_version']
  static Future<bool> isDependencyUpToDate({
    required DartPackage package,
    required String dependency,
    List<String>? pubspecKeys,
  }) async {
    final latest = await getLatestDependencyVersion(dependency);
    final current = getMinimumVersionConstraint(
      package,
      pubspecKeys ?? ['dependencies', dependency],
    );

    return latest == current;
  }

  /// Updates the version constraint of [dependency] to the latest version
  static Future<void> updateVersionConstraintToLatest(
    DartPackage package,
    String dependency,
  ) async =>
      updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', dependency],
        newMinimumVersion: await getLatestDependencyVersion(dependency),
      );

  /// Sets the version constraint at [pubspecKeys] in pubspec.yaml to [newMinimumVersion]
  ///
  /// If [pinVersion] is true, the new version constraint will only allow [newMinimumVersion]
  /// Else it will allow a version range from [newMinimumVersion] until the next breaking version
  static void updateVersionConstraint({
    required DartPackage package,
    required List<String> pubspecKeys,
    required Version newMinimumVersion,
    bool pinVersion = false,
  }) {
    final pubspec = package.pubspec;
    final pubspecContent = pubspec.readAsStringSync();

    final editor = YamlEditor(pubspecContent);

    final newVersionConstraint = pinVersion
        ? newMinimumVersion.canonicalizedVersion
        : newMinimumVersion.major > 0
            ? '^${newMinimumVersion.canonicalizedVersion}'
            : ">=${newMinimumVersion.canonicalizedVersion} <1.0.0";

    // This whole ceremony creates missing keys until reaching the actual key to update
    final existingKeys = [];
    for (final key in pubspecKeys) {
      existingKeys.add(key);
      // use this pseudo object as fallback when a value is absent
      const nothing = '\$\$nothing\$\$';
      final parent = editor.parseAt(existingKeys.dropLast(1));
      final node =
          editor.parseAt(existingKeys, orElse: () => wrapAsYamlNode(nothing));
      if (node.value == nothing) {
        // The node is missing beginning at this point in the tree
        final missingKeys = pubspecKeys.sublist(existingKeys.length - 1);

        // Create the complete missing object and insert it as a single block
        // This helps YamlEditor to actually use the BLOCK syntax. Adding the
        // nodes one at a time falls back to FLOW syntax
        YamlMap missing = missingKeys.reversed.fold(
          YamlMap.wrap({}, style: CollectionStyle.BLOCK),
          (previousValue, element) {
            return YamlMap.wrap(
              {element: previousValue},
              style: CollectionStyle.BLOCK,
            );
          },
        );

        // We don't want to replace the complete parent node, only add new keys
        if (parent is YamlMap) {
          // YamlMap is unmodifiable, therefore create a new one
          missing = YamlMap.wrap({
            ...parent,
            ...missing,
          });
        }

        // insert the full missing nodes and exit
        editor.update(
          existingKeys.dropLast(1),
          missing,
        );
        break;
      }
    }

    // All parent nodes have been added, finally replace the value.
    editor.update(pubspecKeys, newVersionConstraint);
    String generatedYaml = editor.toString();

    // Best practice, close the file with \n (which YamlEditor removed)
    if (!generatedYaml.endsWith('\n')) {
      generatedYaml += '\n';
    }
    pubspec.writeAsStringSync(generatedYaml);
  }

  /// Returns the minimum version constraint of a dependency in [package]
  ///
  /// [pubspecKeys] is the path from which to retrieve the version in
  /// the pubspec.yaml of [package], e.g.
  /// - ['dependencies', 'sidekick_core']
  /// - ['dev_dependencies', 'lint']
  /// - ['sidekick', 'cli_version']
  ///
  /// Returns null if pubspec.yaml does not contain [pubspecKeys]
  static Version? getMinimumVersionConstraint(
    DartPackage package,
    List<String> pubspecKeys,
  ) =>
      _readFromYaml(package.pubspec, pubspecKeys).match(
        () => null,
        // `dependency: ` is equivalent to `dependency: any`
        (t) => VersionConstraint.parse(t ?? 'any').minVersion,
      );

  /// Returns the resolved version of [dependency] as specified in the lock file
  ///
  /// Returns null if the lock file doesn't contain [dependency]
  ///
  /// Every dependency in pubspec.lock has a version,
  /// even if a local dependency doesn't explicitly specify a version in their
  /// pubspec.yaml, there always is an implicit version of 0.0.0
  static Version? getResolvedVersion(DartPackage package, String dependency) {
    try {
      final resolvedVersion =
          _readFromYaml(package.lockfile, ['packages', dependency, 'version']);
      return resolvedVersion.match(
        () => null,
        (t) => t != null ? Version.parse(t) : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns the latest version of [dependency] available on pub.dev
  static Future<Version> getLatestDependencyVersion(String dependency) async {
    if (testFakeGetLatestDependencyVersion != null) {
      return testFakeGetLatestDependencyVersion!(dependency);
    }

    final response =
        await get(Uri.parse('https://pub.dev/api/packages/$dependency'));

    if (response.statusCode != HttpStatus.ok) {
      throw "Package '$dependency' not found on pub.dev";
    }

    final latestVersion =
        ((jsonDecode(response.body) as Map<String, dynamic>)['latest']
            as Map<String, dynamic>)['version'] as String;

    return Version.parse(latestVersion);
  }

  /// Whether [dartExecutablePath] is the latest stable version of Dart
  static Future<bool> isLatestStableDart(String dartExecutablePath) async {
    // e.g. Dart SDK version: 2.18.4 (stable) (Tue Nov 1 15:15:07 2022 +0000) on "macos_arm64"
    final dartVersionResult = '$dartExecutablePath --version'
        .start(progress: Progress.capture())
        .firstLine;
    if (dartVersionResult == null) {
      throw "Couldn't determine version of Dart executable $dartExecutablePath";
    }

    final dartVersionRegExp = RegExp(r'Dart SDK version: (\S+) \((\S+)\)');
    final match = dartVersionRegExp.firstMatch(dartVersionResult)!;
    final currentChannel = match.group(2)!;
    if (currentChannel != 'stable') {
      return false;
    }

    final currentVersion = Version.parse(match.group(1)!);
    final latestVersion = await getLatestStableDartVersion();

    return currentVersion == latestVersion;
  }

  static Future<Version> getLatestStableDartVersion() async {
    final endpoint = Uri.parse(
      'https://storage.googleapis.com/dart-archive/channels/stable/release/latest/VERSION',
    );
    final response = await get(endpoint);
    if (response.statusCode != HttpStatus.ok) {
      throw 'Failed to get latest stable Dart version from $endpoint: ${response.body}';
    }

    // e.g. {"date": "2022-12-13", "version": "2.18.6", "revision": "f16b62ea92cc0f04cfd9166992f93419e425c809"}
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final version = json['version'] as String;
    return Version.parse(version);
  }

  /// Set to override behavior of [getLatestDependencyVersion] in tests
  @visibleForTesting
  static Future<Version> Function(String dependency)?
      testFakeGetLatestDependencyVersion;
}

/// Returns the string specified by [path] in [yamlFile]
///
/// The string can be null, e.g. for the yaml `foo: ` and path `foo` returns null
/// If the [path] can't be found in the yaml, returns nothing
_Option<String?> _readFromYaml(File yamlFile, List<Object> path) {
  if (path.isEmpty) {
    throw 'Need at least one key in path parameter, but it was empty.';
  }
  if (!yamlFile.existsSync()) {
    throw "Tried reading '[${path.map((e) => "'$e'").join(', ')}]' "
        "from yaml file '${yamlFile.path}', but that file doesn't exist.";
  }

  final yaml = loadYaml(yamlFile.readAsStringSync());

  // ignore: avoid_dynamic_calls, pubspec currently is a [YamlMap] but will be a [HashMap] in future versions
  if (!(yaml.keys.contains(path.first) as bool)) {
    return const _None();
  }

  // ignore: avoid_dynamic_calls, pubspec currently is a [YamlMap] but will be a [HashMap] in future versions
  Object? /* Map? | String? */ current = yaml[path.first];
  var i = 1;
  for (final key in path.sublist(1)) {
    if (current is Map) {
      current = current[key];
    } else {
      if (i != path.length) {
        return const _None();
      }
    }
    i++;
  }

  if (current is String?) {
    return _Some(current);
  }

  // most likely still a YamlMap or YamlList
  return const _None();
}

extension on VersionConstraint {
  Version get minVersion {
    final versionConstraint = this;
    if (versionConstraint is VersionRange) {
      final minVersion = versionConstraint.min;
      if (minVersion == null) {
        return Version.none;
      }
      return versionConstraint.includeMin ? minVersion : minVersion.nextPatch;
    } else if (versionConstraint is Version) {
      return versionConstraint;
    } else {
      throw 'Unknown $versionConstraint';
    }
  }
}

/// Functional programming classes [_Option], [_None], [_Some] are shortened
/// versions copied from fpdart containing only the necessary functionality
/// https://github.com/SandroMaglione/fpdart/blob/main/lib/src/option.dart

abstract class _Option<T> {
  const _Option();

  B match<B>(B Function() onNone, B Function(T t) onSome);
}

class _Some<T> extends _Option<T> {
  final T _value;

  const _Some(this._value);

  @override
  B match<B>(B Function() onNone, B Function(T t) onSome) => onSome(_value);
}

class _None<T> extends _Option<T> {
  const _None();

  @override
  B match<B>(B Function() onNone, B Function(T t) onSome) => onNone();
}
