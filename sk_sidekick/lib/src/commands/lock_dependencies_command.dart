import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

class LockDependenciesCommand extends Command {
  @override
  final String description = 'Locks all dependencies to their upper bounds';

  @override
  final String name = 'lock-dependencies';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        '[package-path]',
      );

  @override
  Future<void> run() async {
    final package = DartPackage.fromArgResults(argResults!);

    final pubGet = systemDart(['pub', 'get'], workingDirectory: package.root);
    if (pubGet != 0) {
      throw "Couldn't get dependencies in ${package.root}";
    }

    final lockfile = package.lockfile;
    if (!lockfile.existsSync()) {
      throw "Lockfile doesn't exist in ${package.root}";
    }

    final packages =
        loadYaml(lockfile.readAsStringSync())['packages'] as YamlMap;

    final Map<String, String> directDependencies = {};
    final Map<String, String> transitiveDependencies = {};
    for (final package in packages.entries) {
      final type = package.value['dependency'];
      final packageName = package.key as String;
      final version = package.value['version'] as String;

      if (type != 'direct dev' && package.value['source'] != 'hosted') {
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
