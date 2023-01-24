import 'package:sidekick_core/sidekick_core.dart';
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
      help: 'Whether to check that Dart is at the latest stable version. '
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

    systemDart(
      ['pub', 'get'],
      workingDirectory: package.root,
      throwOnError: () => "Couldn't get dependencies in ${package.root}",
    );

    final lockfile = package.lockfile;
    if (!lockfile.existsSync()) {
      throw "Lockfile doesn't exist in ${package.root}";
    }

    final packages =
        // ignore: avoid_dynamic_calls
        loadYaml(lockfile.readAsStringSync())['packages'] as YamlMap;

    final Map<String, String> directDependencies = {};
    final Map<String, String> transitiveDependencies = {};
    for (final package in packages.entries) {
      final value = package.value as YamlMap;
      final type = value['dependency'];
      final packageName = package.key as String;
      final version = value['version'] as String;

      if (type != 'direct dev' && value['source'] != 'hosted') {
        throw "Can only handle dependencies from hosted sources, but $packageName violates this.";
      }

      switch (type) {
        case 'transitive':
          transitiveDependencies[packageName] = version;
          break;
        case 'direct main':
          directDependencies[packageName] = version;
          break;
        // case 'direct dev' is irrelevant
      }
    }

    final pinnedDirectDependencies = directDependencies
        .mapEntries((e) => "  ${e.key}: ${e.value.lockedConstraintRange}")
        .sorted();
    final pinnedTransitiveDependencies = transitiveDependencies
        .mapEntries((e) => "  ${e.key}: ${e.value.lockedConstraintRange}")
        .sorted();

    final lockedDependencies = [
      'dependencies:',
      '  # direct dependencies',
      ...pinnedDirectDependencies,
      '  # transitive dependencies',
      ...pinnedTransitiveDependencies,
    ].join('\n');

    final currentDependenciesBlock =
        RegExp(r'^dependencies:.*((\n\s*#.*)|(\n {2}.*))*', multiLine: true)
            .firstMatch(package.pubspec.readAsStringSync())
            ?.group(0);
    if (currentDependenciesBlock == null) {
      throw "Couldn't parse current dependencies block in ${package.pubspec.path}: ${package.pubspec.readAsStringSync()}";
    }

    package.pubspec.copySync('${package.pubspec.absolute.path}.unlocked');
    package.pubspec.replaceFirst(currentDependenciesBlock, lockedDependencies);

    print(green('Locked dependencies of ${package.name}!'));
  }
}

extension on String {
  String get lockedConstraintRange {
    final version = Version.parse(this);
    final lowerBound = version.major > 0
        ? Version(version.major, 0, 0)
        : Version(0, version.minor, 0);

    return version == lowerBound ? '$version' : "'>=$lowerBound <=$version'";
  }
}
