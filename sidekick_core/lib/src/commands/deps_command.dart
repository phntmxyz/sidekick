import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Called once after dependency fetching was attempted for the selected packages.
typedef DepsHook = Future<void> Function(DepsContext context);

final Map<DepsHook, Object> _depsHooks = {};

/// Registers a hook after [DepsCommand] finishes attempting dependency fetching.
///
/// Hooks apply to every DepsCommand instance and run sequentially in registration
/// order, including `deps --package` and empty selections. They are awaited;
/// an exception fails the command and stops the remaining hooks. Hooks also run
/// after dependency failures; inspect [DepsContext.isSuccess] before performing
/// setup that requires successful dependencies. Argument/selection errors do not
/// dispatch hooks. Hooks run while the normal Sidekick context is available.
///
/// Register during CLI initialization, alongside [addSdkInitializer]. Registering
/// the same function again has no effect. The returned function unregisters it.
/// Registrations persist until removed; changes during dispatch affect the next
/// run. Removing an old registration cannot remove a later re-registration.
Removable addDepsHook(DepsHook hook) {
  final registration = _depsHooks.putIfAbsent(hook, Object.new);
  return () {
    if (identical(_depsHooks[hook], registration)) {
      _depsHooks.remove(hook);
    }
  };
}

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
      final result = await _attempt(package);
      try {
        await _complete([result]);
      } catch (error, stackTrace) {
        if (result.isSuccess) {
          rethrow;
        }
        // Keep the dependency error primary, but report the hook failure too.
        printerr('Error in deps hook: $error\n$stackTrace');
      }
      if (!result.isSuccess) {
        Error.throwWithStackTrace(result.error!, result.stackTrace!);
      }
      return;
    }

    _warnIfNotInProject();
    final errorBuffer = StringBuffer();
    final results = <DepsPackageResult>[];

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

    final selectedPackages = allPackages.whereNot(excluded.contains).toList();
    for (final package in selectedPackages) {
      final result = await _attempt(package);
      results.add(result);
      if (!result.isSuccess) {
        print('Error while getting dependencies for ${package.name} '
            '(${package.root.path})');
        errorBuffer
            .writeln('${package.name}: ${result.error}\n${result.stackTrace}');
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
    try {
      await _complete(results);
    } finally {
      if (results.any((result) => !result.isSuccess)) {
        exitCode = 1;
      }
    }
  }

  Future<DepsPackageResult> _attempt(DartPackage package) async {
    try {
      await _getDependencies(package);
      return DepsPackageResult.success(package);
    } catch (error, stackTrace) {
      return DepsPackageResult.failure(package,
          error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _complete(List<DepsPackageResult> results) async {
    final context = DepsContext(results: results);
    // Snapshot registrations so changes made by hooks affect the next run.
    for (final hook in _depsHooks.keys.toList()) {
      await hook(context);
    }
  }

  Future<void> _getDependencies(DartPackage package) async {
    print(yellow('=== package ${package.name} ==='));
    final packageDir = package.root;
    final dartOrFlutter = package.isFlutterPackage ? flutter : dart;
    final progress = Progress(
      print,
      stderr: printerr,
      captureStdout: true,
      captureStderr: true,
    );
    await dartOrFlutter(
      ['pub', 'get'],
      workingDirectory: packageDir,
      progress: progress,
      throwOnError: () => [
        'Failed to get dependencies for package ${packageDir.path}',
        ...progress.lines,
      ].join('\n'),
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

/// Results of a dependency-fetching run, passed to a [DepsHook].
///
/// Project information remains available from [SidekickContext], [mainProject],
/// and [entryWorkingDirectory] while the hook runs.
class DepsContext {
  DepsContext({required List<DepsPackageResult> results})
      : results = List.unmodifiable(results);

  /// One result per attempted package, in execution order. Excluded packages
  /// are omitted. An empty list means no packages needed processing.
  final List<DepsPackageResult> results;

  /// Whether every attempt succeeded. An empty run is successful.
  /// This describes dependency fetching, not the outcome of other hooks.
  bool get isSuccess => results.every((result) => result.isSuccess);
}

/// Outcome of fetching dependencies for one package.
class DepsPackageResult {
  const DepsPackageResult.success(this.package)
      : error = null,
        stackTrace = null;

  const DepsPackageResult.failure(
    this.package, {
    required Object this.error,
    required StackTrace this.stackTrace,
  });

  final DartPackage package;

  /// The failure, or null when the attempt succeeded. For a nonzero pub exit,
  /// this includes the package path and captured stdout/stderr diagnostics.
  /// SDK initialization and other exceptions are preserved as thrown.
  final Object? error;

  /// The stack trace of the failure, or null when the attempt succeeded.
  final StackTrace? stackTrace;

  bool get isSuccess => error == null;
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
