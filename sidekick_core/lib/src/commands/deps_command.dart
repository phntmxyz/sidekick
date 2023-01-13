import 'package:dcli/dcli.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Downloads dependencies of all Flutter/Dart packages in the repository
class DepsCommand extends Command {
  @override
  final String description = 'Gets dependencies for all packages';

  @override
  final String name = 'deps';

  /// packages whose dependencies should not be loaded
  final List<DartPackage> exclude;

  /// glob patterns of packages whose dependencies should not be loaded
  final List<String> excludeGlob;

  DepsCommand({
    this.exclude = const [],
    this.excludeGlob = const [],
  }) {
    argParser.addOption(
      'package',
      abbr: 'p',
    );
  }

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;

    final List<DartPackage> allPackages =
        SidekickContext.repository.findAllPackages();
    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${SidekickContext.repository.root.path}";
      }
      // only get deps for selected package
      _getDependencies(package);
      return;
    }

    final errorBuffer = StringBuffer();

    final excluded = excludeGlob
        .map((p) => Glob(p))
        .map(
          (e) => e.listSync(
            // See https://github.com/dart-lang/glob/issues/52
            root: Directory.current.path,
          ),
        )
        .expand((e) => e) // flattens nested list
        .whereType<Directory>()
        .mapNotNull((e) => DartPackage.fromDirectory(e))
        .append(exclude);
    for (final package in allPackages.whereNot(excluded.contains)) {
      try {
        _getDependencies(package);
      } catch (e, stack) {
        print('Error while getting dependencies for ${package.name} '
            '(${package.root.path})');
        errorBuffer.writeln("${package.name}: $e\n$stack");
      }
    }
    final errorText = errorBuffer.toString();
    if (errorText.isNotEmpty) {
      printerr("\n\nErrors while getting dependencies:");
      printerr(errorText);
      exitCode = 1;
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
    if (exitCode != 0) {
      throw "Failed to get dependencies for package ${package.root.path}";
    }
    print("\n");
  }
}
