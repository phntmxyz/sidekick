import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;
// ignore: implementation_imports, sk_sidekick is not a published package and already depends on sidekick_core from path
import 'package:sidekick_core/src/version_checker.dart';
import 'package:yaml/yaml.dart';

class LockDependenciesCommand extends Command {
  @override
  final String description = 'Locks all dependencies to their upper bounds';

  @override
  final String name = 'lock-dependencies';

  @override
  String get invocation => super.invocation.replaceFirst(
    '[arguments]',
    '[package-path] [--[no]-check-dart-version]',
  );

  LockDependenciesCommand() {
    argParser.addFlag(
      'check-dart-version',
      defaultsTo: true,
      help:
          'Whether to check that Dart is at the latest stable version. '
          'Depending on the Dart version, different upper bounds are resolved.',
    );
  }

  @override
  Future<void> run() async {
    final package = DartPackage.fromArgResults(argResults!);

    if (argResults!['check-dart-version'] as bool) {
      final systemDartExecutablePath = systemDartExecutable();
      if (systemDartExecutablePath == null) {
        throw "Couldn't find dart executable on PATH.";
      }
      if (!await VersionChecker.isLatestStableDart(systemDartExecutablePath)) {
        throw 'Aborting because Dart is not at the latest stable version.\n'
            'This is important because depending on the Dart version, '
            'different upper bounds are resolved.\n'
            '${red('Please update Dart to the latest stable version and try again.')}';
      }
    }

    final pubspecOverrides = package.root.file('pubspec_overrides.yaml');
    if (pubspecOverrides.existsSync()) {
      pubspecOverrides.deleteSync();
    }

    systemDart(
      ['pub', 'get'],
      workingDirectory: package.root,
      throwOnError: () => "Couldn't update dependencies in ${package.root}",
    );

    final lockfile = package.lockfile;
    if (!lockfile.existsSync()) {
      throw "Lockfile doesn't exist in ${package.root}";
    }

    final constrainedVersions =
        (loadYaml(package.pubspec.readAsStringSync())
                as YamlMap)['dependencies']
            as YamlMap;
    final lockedVersions =
        // ignore: avoid_dynamic_calls
        loadYaml(lockfile.readAsStringSync())['packages'] as YamlMap;

    final Map<String, VersionRange> directDependencies = {};
    final Map<String, VersionRange> transitiveDependencies = {};
    for (final package in lockedVersions.entries) {
      final value = package.value as YamlMap;
      final type = value['dependency'];
      final packageName = package.key as String;
      final Version latestVersion = Version.parse(value['version'] as String);
      final VersionRange? constraints = () {
        try {
          final rawConstraints = constrainedVersions[packageName] as String?;
          return VersionConstraint.parse(rawConstraints!) as VersionRange;
        } catch (e) {
          return null;
        }
      }();

      if (type != 'direct dev' && value['source'] != 'hosted') {
        throw "Can only handle dependencies from hosted sources, but $packageName violates this.";
      }

      final VersionRange range;
      if (constraints == null) {
        // Not a direct dependency,
        final lowerBound = latestVersion.major > 0
            ? Version(latestVersion.major, 0, 0)
            : Version(0, latestVersion.minor, 0);
        range = VersionRange(
          min: lowerBound,
          max: latestVersion,
          includeMax: true,
          includeMin: true,
        );
      } else {
        // Direct dependency with constraints
        // Combines latest version from pub (lock file) with the version
        // constraints from the pubspec.yaml file
        range = VersionRange(
          min: constraints.min,
          max: latestVersion,
          includeMax: true,
          includeMin: true,
        );
      }
      assert(
        range.allows(latestVersion),
        'Latest version $latestVersion is not allowed by $range',
      );

      switch (type) {
        case 'transitive':
          transitiveDependencies[packageName] = range;
        case 'direct main':
          directDependencies[packageName] = range;
        // case 'direct dev' is irrelevant
      }
    }

    final pinnedDirectDependencies = directDependencies
        .mapEntries((e) => "  ${e.key}: '${e.value}'")
        .sorted();
    final pinnedTransitiveDependencies = transitiveDependencies
        .mapEntries((e) => "  ${e.key}: '${e.value}'")
        .sorted();

    final lockedDependencies = [
      'dependencies:',
      '  # direct dependencies',
      ...pinnedDirectDependencies,
      '',
      '  # transitive dependencies',
      ...pinnedTransitiveDependencies,
    ].join('\n');

    final currentDependenciesBlock = RegExp(
      r'^dependencies:.*((\n\s*#.*)|(\n {2}.*))*',
      multiLine: true,
    ).firstMatch(package.pubspec.readAsStringSync())?.group(0);
    if (currentDependenciesBlock == null) {
      throw "Couldn't parse current dependencies block in ${package.pubspec.path}: ${package.pubspec.readAsStringSync()}";
    }

    package.pubspec.copySync('${package.pubspec.absolute.path}.unlocked');
    package.pubspec.replaceFirst(currentDependenciesBlock, lockedDependencies);

    print(green('Locked dependencies of ${package.name}!'));
  }
}
