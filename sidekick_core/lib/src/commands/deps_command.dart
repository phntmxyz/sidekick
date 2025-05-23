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
  ///
  /// Search starts at repository root.
  ///
  /// Example project layout:
  ///
  /// ```sh
  /// repo-root
  /// ├── packages
  /// │   ├── package1
  /// │   ├── package2
  /// │   └── circle
  /// └── third_party
  ///     ├── circle
  ///     │   ├── packageA
  ///     │   └── packageB
  ///     └── square
  /// ```
  ///
  /// - Use `packages/package1/**` to exclude only `packages/package1`.
  /// - Use `**/circle/**` to exclude `packages/circle` as well as
  ///   `third_party/circle/packageA` and `third_party/circle/packageB`.
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
        findAllPackages(SidekickContext.projectRoot);
    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in "
            "${SidekickContext.projectRoot.path}";
      }
      _warnIfNotInProject();
      // only get deps for selected package
      await _getDependencies(package);
      return;
    }

    _warnIfNotInProject();
    final errorBuffer = StringBuffer();

    final globExcludes = excludeGlob
        .expand((rule) {
          // start search at repo root
          final root = SidekickContext.projectRoot.path;
          return Glob("$root/$rule").listSync(root: root);
        })
        .whereType<Directory>()
        .mapNotNull((e) => DartPackage.fromDirectory(e));

    final excluded = [
      ...exclude,
      ...globExcludes,
      // exclude the sidekick package, because it should load it's dependencies
      // using the embedded sdk.
      // Since this command is already running, the deps are already loaded.
      DartPackage.fromDirectory(SidekickContext.sidekickPackage.root)!,
    ];

    for (final package in allPackages.whereNot(excluded.contains)) {
      try {
        await _getDependencies(package);
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
    } else {
      exitCode = 0;
    }
  }

  Future<void> _getDependencies(DartPackage package) async {
    print(yellow('=== package ${package.name} ==='));
    final packageDir = package.root;
    final dartOrFlutter = package.isFlutterPackage ? flutter : dart;
    await dartOrFlutter(
      ['pub', 'get'],
      workingDirectory: packageDir,
      throwOnError: () =>
          'Failed to get dependencies for package ${packageDir.path}',
    );
    print("\n");
  }

  void _warnIfNotInProject() {
    final currentDir = Directory.current;
    final projectRoot = SidekickContext.projectRoot;
    if (!currentDir.isWithinOrEqual(projectRoot)) {
      printerr("Warning: You aren't getting the dependencies of the current "
          "working directory, but of project '${SidekickContext.cliName}'.");
    }
  }
}

extension on Directory {
  bool isWithinOrEqual(Directory dir) {
    return this.isWithin(dir) ||
        // canonicalize is necessary, otherwise '/a/b/c' != '/a/b/c/' != '/a/b/c/.' != '/a/b/c/../c'
        dir.canonicalized.path == canonicalized.path;
  }

  /// A [Directory] whose path is the canonicalized path of [this].
  Directory get canonicalized => Directory(canonicalize(path));
}
