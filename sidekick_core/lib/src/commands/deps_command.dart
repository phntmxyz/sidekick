import 'package:sidekick_core/sidekick_core.dart';

/// Downloads dependencies of all Flutter/Dart packages in the repository
class DepsCommand extends Command {
  @override
  final String description = 'Gets dependencies for all packages';

  @override
  final String name = 'deps';

  /// packages whose dependencies should not be loaded
  final List<DartPackage> excluded;

  DepsCommand({this.excluded = const []}) {
    argParser.addOption(
      'package',
      abbr: 'p',
    );
  }

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;

    final List<DartPackage> allPackages = repository.findAllPackages();

    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${repository.root.path}";
      }
      // only get deps for selected package
      _getDependencies(package);
      return;
    }

    final List<Object> errors = [];
    for (final package in allPackages) {
      try {
        _getDependencies(package);
      } catch (e) {
        errors.add(e);
      }
    }
    if (errors.isNotEmpty) {
      printerr("Errors while getting dependencies:");
      throw errors.join("\n");
    }
  }

  void _getDependencies(DartPackage package) {
    print(yellow('=== package ${package.name} ==='));
    final int exitCode;
    if (package.isFlutterPackage) {
      exitCode = flutter(['packages', 'get'], workingDirectory: package.root);
    } else {
      exitCode = dart(['pub', 'get'], workingDirectory: package.root);
    }
    print("\n");
    if (exitCode != 0) {
      throw "Failed to get dependencies for package ${package.name}";
    }
  }
}
