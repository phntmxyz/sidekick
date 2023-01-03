import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Checks and updates dependencies of the given [package]
class VersionChecker {
  const VersionChecker(this.package);

  final DartPackage package;

  /// Checks whether the latest version of [dependency] is being used in the generated sidekick CLI
  ///
  /// [pubspecKeys] can be passed to override the default behavior of reading
  /// the current package version from the pubspec.yaml at ['dependencies'][dependency]
  /// E.g. ['dev_dependencies', 'some_dev_dependency'] or ['sidekick', 'cli_version']
  Future<bool> isUpToDate({
    required String dependency,
    List<String>? pubspecKeys,
  }) async {
    final latest = await getLatestDependencyVersion(dependency);
    final current = getMinimumVersionConstraint(
      pubspecKeys ?? ['dependencies', dependency],
    );

    return latest == current;
  }

  /// Updates the version constraint of [dependency] to the latest version
  Future<void> updateVersionConstraintToLatest(String dependency) async =>
      updateVersionConstraint(
        pubspecKeys: ['dependencies', dependency],
        newMinimumVersion: await getLatestDependencyVersion(dependency),
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
    final pubspec = package.pubspec;
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

  /// Returns the latest version of [dependency] available on pub.dev
  Future<Version> getLatestDependencyVersion(String dependency) async {
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

  /// Returns the minimum version constraint of a dependency in [package]
  ///
  /// [pubspecKeys] is the path from which to retrieve the version in
  /// the pubspec.yaml of [package], e.g.
  /// - ['dependencies', 'sidekick_core']
  /// - ['dev_dependencies', 'lint']
  /// - ['sidekick', 'cli_version']
  ///
  /// Returns null if pubspec.yaml does not contain [pubspecKeys]
  Version? getMinimumVersionConstraint(List<String> pubspecKeys) =>
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
  Version? getResolvedVersion(String dependency) {
    final pubspecLockFile = package.root.file('pubspec.lock');
    final resolvedVersion =
        _readFromYaml(pubspecLockFile, ['packages', dependency, 'version']);
    return resolvedVersion.match(
      () => null,
      (t) => t != null ? Version.parse(t) : null,
    );
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

    return _Some(current as String?);
  }

  /// Return regex matching a potentially nested yaml key
  ///
  /// Examples:
  /// - createNestedVersionYamlRegex(['version'])
  ///   -> '^dependencies:'
  /// - createNestedVersionYamlRegex(['dependencies', 'foo'])
  ///   -> '^dependencies:\\s*(\\n  .*)*\\n  foo:'
  /// - createNestedVersionYamlRegex(['dependencies', 'foo', 'bar'])
  ///   -> '^dependencies:\\s*(\\n  .*)*\\n  foo:\\s*(\\n    .*)*\\n    bar:'
  RegExp _createNestedYamlKeyRegex(List<String> keys) {
    final sb = StringBuffer('^');
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      sb.write('$key:');

      if (i < keys.length - 1) {
        final indentation = '  ' * (i + 1);
        sb.write('\\s*(\\n$indentation.*)*\\n$indentation');
      }
    }
    return RegExp(
      sb.toString(),
      multiLine: true,
    );
  }

  /// Returns the minimum version constraint of a dependency in [package]
  /// or null if the package does not depend on the dependency
  ///
  /// [pubspecKeys] is the path from which to retrieve the version in
  /// the pubspec.yaml of [package], e.g.
  /// - ['dependencies', 'sidekick_core']
  /// - ['dev_dependencies', 'lint']
  /// - ['sidekick', 'cli_version']
  @Deprecated('Use `getMinimumVersionConstraint` instead.')
  Version? getMinimumVersionConstraintOrNull(List<String> pubspecKeys) {
    const pathNotFoundInYaml = Object();
    dynamic deprecatedReadFromYaml(File yamlFile, List<Object> path) {
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
        return pathNotFoundInYaml;
      }

      // ignore: avoid_dynamic_calls, pubspec currently is a [YamlMap] but will be a [HashMap] in future versions
      Object? /* Map? | String? */ current = yaml[path.first];
      var i = 1;
      for (final key in path.sublist(1)) {
        if (current is Map) {
          current = current[key];
        } else {
          if (i != path.length) {
            return pathNotFoundInYaml;
          }
        }
        i++;
      }

      return current as String?;
    }

    final result = deprecatedReadFromYaml(package.pubspec, pubspecKeys);
    if (result == pathNotFoundInYaml) {
      return null;
    }
    // `dependency: ` is equivalent to `dependency: any`
    return VersionConstraint.parse((result as String?) ?? 'any').minVersion;
  }
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
