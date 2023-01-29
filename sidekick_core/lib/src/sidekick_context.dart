import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/sidekick_core.dart' as core;

/// Environment variable containing the location of the shell `entryPoint`, when
/// executing the sidekick CLI with the shell entrypoint
///
/// May be not set when debugging where the CLI is executed directly on the
/// DartVM by calling `dart bin/main.dart` without the entrypoint
const String _envEntryPointHome = 'SIDEKICK_ENTRYPOINT_HOME';

/// Environment variable containing the path of the entrypoint when executing
/// the sidekick CLI with the shell entrypoint
///
/// May be not set when debugging where the CLI is executed directly on the
/// DartVM by calling `dart bin/main.dart` without the entrypoint
const String _envEntryPointFile = 'SIDEKICK_ENTRYPOINT_FILE';

/// Environment variable containing the location of the dart package of this
/// sidekick CLI. It contains the source code and tool scripts of this sidekick
/// CLI.
///
/// SIDEKICK_PACKAGE_HOME is set by the `tool/run.sh` script and always called
/// when executed via `entryPoint`
const String _envPackageHome = 'SIDEKICK_PACKAGE_HOME';

/// Global information about the sidekick cli that is being executed
///
/// Get the location of the [entryPoint] and the [sidekickPackage] which works
/// when
/// - executed via the shell entrypoint (default) or
/// - when debugging the cli on the DartVM or
/// - when running tests for your custom commands
class SidekickContext {
  /// Private constructor, no instances
  SidekickContext._();

  /// Caches expensive lookups, disabled by default
  ///
  /// The idea is to cache repeated lookups while [SidekickCommandRunner] is
  /// executing a command. [SidekickCommandRunner] is responsible for setting
  /// and resetting this value (exposed via [internalSidekickContextCache]).
  /// Caution! Commands may be nested. Completion of one command should revert
  /// the cache of the previous command.
  ///
  /// ## Why can't we always cache?
  ///
  /// Because of tests. Tests run in the same process and would share the cache.
  ///
  /// [SidekickContext] picks up all information from environment variables,
  /// and the file system. Those information don't change when using the CLI in
  /// production. The process is started from entrypoint and ends when one
  /// command (and the nested commands) is executed. The process only knows
  /// about a single sidekick package.
  ///
  /// When testing, multiple tests are executed in the same process.
  /// This leads to shared memory. If the cache would be
  /// enabled outside of [SidekickCommandRunner] executing a single command,
  /// we would cache the values for the first test and reuse it in all others.
  /// But each test uses a different temp directory, resulting in different
  /// environment variables. Those can't be cached across tests.
  static SidekickContextCache _cache = SidekickContextCache.noCache();

  /// The sidekick package inside the [projectRoot]
  static SidekickPackage get sidekickPackage {
    return _cache.getOrCreate('sidekickPackage', _findSidekickPackage);
  }

  /// Returns the name of the CLI
  static String get cliName {
    return sidekickPackage.cliName;
  }

  static SidekickPackage _findSidekickPackage() {
    // Strategy 1: Use the environment variable SIDEKICK_PACKAGE_HOME injected
    // by entryPoint shell script
    final envPackage = _findSidekickPackageFromEnv();
    if (envPackage != null) {
      return envPackage;
    }

    // Strategy 2: Script is within the sidekick package
    final scriptPackage = _findSidekickPackageFromScript();
    if (scriptPackage != null) {
      return scriptPackage;
    }

    // Fallback strategy: searching all parent folders until we find a dart package root
    final discovery = _discoverProject();
    return discovery.sidekickPackage;
  }

  static SidekickPackage? _findSidekickPackageFromEnv() {
    final injectedPackageHome = env[_envPackageHome];
    if (injectedPackageHome != null && injectedPackageHome.isNotBlank) {
      // When called via entryPoint, immediately return the package
      return SidekickPackage.fromDirectory(Directory(injectedPackageHome))!;
    }
    return null;
  }

  static SidekickPackage? _findSidekickPackageFromScript() {
    final script = File(DartScript.self.pathToScript);
    final scriptPath = script.uri.path;

    // When CLI is run with compiled entryPoint: <sidekick package>/build/cli.exe
    if (scriptPath.endsWith('/build/cli.exe')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // When CLI is run with `dart bin/main.dart`: <sidekick package>/bin/main.dart
    if (scriptPath.endsWith('/bin/main.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // in `UpdateCommand` when the latest `update_sidekick_cli.dart` is written to <sidekick package>/build/update.dart to be executed
    if (scriptPath.endsWith('/bin/update.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }
    return null;
  }

  /// The directory where the [entryPoint] is located
  ///
  /// This directory is considered the project root.
  static Directory get projectRoot {
    return _cache.getOrCreate('projectRoot', _findProjectRoot);
  }

  static Directory _findProjectRoot() {
    if (env.exists(_envEntryPointHome)) {
      // CLI is called via entryPoint
      final injectedEntryPointPath = env[_envEntryPointHome];
      if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
        throw 'Injected entryPoint was not set (env.$_envEntryPointHome)';
      }
      final Directory dir = Directory(injectedEntryPointPath);
      if (!dir.existsSync()) {
        throw 'Injected entryPoint does not exist ${dir.absolute.path}';
      }
      return dir;
    }
    return entryPoint.parent;
  }

  /// The location of the entryPoint, the shell script that is used to execute
  /// the cli.
  ///
  /// The entryPoint also marks the root of the project ([projectRoot]).
  ///
  /// Usually injected from the entryPoint itself via `env.SIDEKICK_ENTRYPOINT_HOME`
  static File get entryPoint {
    return _cache.getOrCreate('findEntryPoint', _findEntryPoint);
  }

  static File _findEntryPoint() {
    // Strategy 1: Use the environment variable SIDEKICK_ENTRYPOINT_FILE injected
    // by entryPoint shell script
    if (env.exists(_envEntryPointFile)) {
      final path = env[_envEntryPointFile]!;
      return File(path);
    }

    // Fallback strategy: Search all parents directories for the entryPoint.
    // This case is used when debugging the cli and the dart program is
    // started on the DartVM, and not called and compiled with the entrypoint
    final discovery = _discoverProject(
      knownSidekickPackage: _findSidekickPackageFromEnv(),
    );
    return discovery.entryPoint;
  }

  /// Searches the folder structure upwards from the [DartScript.self], scanning
  /// for the [SidekickPackage] and the [entryPoint].
  /// [DartScript.self] is guaranteed to be a inside [SidekickPackage].
  /// [SidekickPackage] is guaranteed to be inside parent of [entryPoint].
  static _ProjectDiscoveryResult _discoverProject({
    SidekickPackage? knownSidekickPackage,
  }) {
    return _cache.getOrCreate('_discoverProject', () {
      final script = File(DartScript.self.pathToScript);
      final startDir = knownSidekickPackage?.root ?? script.parent;

      SidekickPackage? sidekickPackage = knownSidekickPackage;
      File? entryPoint;
      _ProjectDiscoveryResult? result;
      for (final dir in startDir.allParentDirectories()) {
        sidekickPackage ??= SidekickPackage.fromDirectory(dir);
        entryPoint ??= () {
          if (sidekickPackage == null) {
            // sidekickPackage is always found first, when searching upwards
            return null;
          }
          final String entryPointName = sidekickPackage.cliName;
          final entryPoint = dir
              .listSync()
              .whereType<File>()
              .firstOrNullWhere((it) => it.name == entryPointName);
          if (entryPoint != null) {
            return entryPoint;
          }
          return null;
        }();
        if (sidekickPackage != null && entryPoint != null) {
          result = _ProjectDiscoveryResult(
            sidekickPackage: sidekickPackage,
            entryPoint: entryPoint,
          );
          break;
        }
      }
      if (result == null) {
        throw StateError(
          "Can't find sidekick package and entryPoint from ${script.path}.\n"
          'entryPoint: $entryPoint,\n'
          'sidekickPackage: $sidekickPackage',
        );
      }
      return result;
    });
  }

  /// The git repository root the [sidekickPackage] is located in
  ///
  /// It may return `null` when there's not git repository. In most cases it is
  /// better to use [projectRoot] instead.
  ///
  /// Why would there not be a git repository?
  /// Code can be downloaded as a zip file (from github) or may be hosted in a
  /// non-git mono repository. Anyways, your sidekick CLI should always be
  /// functional.
  static Directory? get repository {
    return _cache.getOrCreate('findRepository', _findRepository);
  }

  /// Searches the parent directories of [entryPoint] for a git repository
  ///
  /// Returns `null` when no `.git` folder is found.
  ///
  /// This method is faster than calling `git rev-parse --show-toplevel`
  static Directory? _findRepository() {
    return entryPoint.parent
        .findParent((dir) => dir.directory('.git').existsSync());
  }
}

/// Read the current cache of [SidekickContext]
///
/// This is a private API and should only be used by [SidekickCommandRunner]
SidekickContextCache get internalSidekickContextCache => SidekickContext._cache;

/// Set the cache of [SidekickContext], don't forget to reset it after
/// a command has been executed.
///
/// This is a private API and should only be used by [SidekickCommandRunner]
set internalSidekickContextCache(SidekickContextCache value) {
  SidekickContext._cache = value;
}

/// Interface of the cache of [SidekickContext]
abstract class SidekickContextCache {
  /// Returns the cached value when available or creates a new value
  T getOrCreate<T extends Object?>(Object key, T Function() create);

  /// Creates a cache that keeps values in memory
  factory SidekickContextCache({String? debugName}) = _InMemoryCache;

  /// Creates a cache that caches nothing (noop)
  factory SidekickContextCache.noCache() = _NoCache;
}

class _NoCache implements SidekickContextCache {
  @override
  T getOrCreate<T extends Object?>(Object key, T Function() create) {
    return create();
  }
}

class _InMemoryCache implements SidekickContextCache {
  _InMemoryCache({this.debugName});
  final Map<Object, Object?> _map = {};
  final String? debugName;

  @override
  T getOrCreate<T extends Object?>(Object key, T Function() create) {
    final value = _map[key] as T?;
    if (value != null) {
      return value;
    }
    final newValue = create();
    _map[key] = newValue;
    return newValue;
  }

  @override
  String toString() {
    return '_InMemoryCache{debugName: $debugName}';
  }
}

/// The result of [SidekickContext._discoverProject]
class _ProjectDiscoveryResult {
  final SidekickPackage sidekickPackage;
  final File entryPoint;

  _ProjectDiscoveryResult({
    required this.sidekickPackage,
    required this.entryPoint,
  });
}
