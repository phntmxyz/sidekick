library sidekick_core;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/dart_package.dart';
import 'package:sidekick_core/src/repository.dart';
import 'package:sidekick_core/src/sidekick_context.dart';
import 'package:sidekick_core/src/version_checker.dart';

export 'dart:io' hide sleep;

export 'package:args/command_runner.dart';
export 'package:dartx/dartx.dart';
export 'package:dartx/dartx_io.dart';
export 'package:dcli/dcli.dart' hide run, start, startFromArgs, absolute;
export 'package:pub_semver/pub_semver.dart' show Version;
export 'package:sidekick_core/src/cli_util.dart';
export 'package:sidekick_core/src/commands/analyze_command.dart';
export 'package:sidekick_core/src/commands/bash_command.dart';
export 'package:sidekick_core/src/commands/dart_command.dart';
export 'package:sidekick_core/src/commands/deps_command.dart';
export 'package:sidekick_core/src/commands/flutter_command.dart';
export 'package:sidekick_core/src/commands/format_command.dart'
    show FormatCommand;
export 'package:sidekick_core/src/commands/install_global_command.dart';
export 'package:sidekick_core/src/commands/plugins/plugins_command.dart';
export 'package:sidekick_core/src/commands/recompile_command.dart';
export 'package:sidekick_core/src/commands/sidekick_command.dart';
export 'package:sidekick_core/src/dart.dart';
export 'package:sidekick_core/src/dart_package.dart';
export 'package:sidekick_core/src/dart_runtime.dart';
export 'package:sidekick_core/src/directory_ext.dart';
export 'package:sidekick_core/src/file_util.dart';
export 'package:sidekick_core/src/flutter.dart';
export 'package:sidekick_core/src/forward_command.dart';
export 'package:sidekick_core/src/repository.dart';
export 'package:sidekick_core/src/sidekick_context.dart' show SidekickContext;
export 'package:sidekick_core/src/sidekick_package.dart';
export 'package:sidekick_core/src/template/sidekick_package.template.dart';

/// The version of package:sidekick_core
///
/// This is used by the update command to determine if your sidekick cli
/// requires an update
// DO NOT MANUALLY EDIT THIS VERSION, instead run `sk bump-version sidekick_core`
final Version version = Version.parse('1.3.1');

/// Initializes sidekick, call this at the very start of your CLI program
///
/// All paths are resolved relative to the location of the
/// [SidekickContext.entryPoint], or absolute.
///
/// Set [flutterSdkPath] when you bind a Flutter SDK to this project. This SDK
/// enables the [flutter] and [dart] commands.
/// [dartSdkPath] is inherited from [flutterSdkPath]. Set it only for pure Dart
/// projects.
/// The paths can either be absolute or relative to the projectRoot (where the
/// entryPoint is located). I.e. when the entrypoint is in `/Users/foo/project-x/`
/// set `dartSdkPath = 'third_party/dart-sdk'` to use the Dart SDK in
/// `/Users/foo/project-x/third_party/dart-sdk`.
///
/// [mainProjectPath] should be set when you have a package that you
/// consider the main package of the whole repository.
/// When your repository contains only one Flutter package in projectRoot set
/// `mainProjectPath = '.'`.
/// In a multi package repository you might use the same when the main package
/// is in projectRoot, or `mainProjectPath = 'packages/my_app'` when it is in a subfolder.
SidekickCommandRunner initializeSidekick({
  @Deprecated('Not used anymore') String? name,
  String? description,
  String? mainProjectPath,
  String? flutterSdkPath,
  String? dartSdkPath,
}) {
  final repoRoot = SidekickContext.repository;
  final projectRoot = SidekickContext.projectRoot;

  /// Migrates a [path] relative to the [SidekickContext.repository] (as it
  /// was default before sidekick 1.0.0) to a path relative to the
  /// [SidekickContext.projectRoot]
  ///
  /// This usually works because the projectRoot is usually also the repository
  /// root.
  /// If the Directory is found in only one resolved location that one is used
  /// and warning to migrate to paths relative to the projectRoot is printed.
  /// If the Directory is found in both locations the one relative to the
  /// projectRoot is returned.
  Directory? resolveDirectoryBackwardsCompatible(
    String parameterName,
    String? path,
  ) {
    if (path == null) return null;
    final fromRepoRoot =
        repoRoot == null ? null : _resolveSdkPath(path, repoRoot);
    final fromProjectRoot = _resolveSdkPath(path, projectRoot);

    if (fromRepoRoot == null && fromProjectRoot == null) {
      throw "Could not find directory $parameterName at '$path'. The resolved path is: ${projectRoot.directory(path).path}";
    }

    if (fromProjectRoot != null && fromRepoRoot == fromProjectRoot) {
      if (fromProjectRoot.isAbsolute) {
        // identical absolute paths, all good
        return fromProjectRoot;
      }
    }

    if (fromProjectRoot != null && fromRepoRoot == null) {
      // path has been migrated, all good
      return fromProjectRoot;
    }

    if (fromRepoRoot != null && fromProjectRoot == null) {
      // Found deprecated path relative to repo root. This is fully working
      // when inside a git repo.
      // Show a warning to migrate the path so it will work when not in a git
      // repo
      final correctPath = relative(
        fromRepoRoot.path,
        from: SidekickContext.projectRoot.path,
      );
      printerr(
        red('$parameterName is defined relative to your git repository. '
            'Please migrate it to be relative to the ${SidekickContext.cliName} entryPoint at ${SidekickContext.projectRoot}.\n'),
      );
      printerr(
        "Please use the following path:\n"
        "final runner = initializeSidekick(\n"
        "  //...\n"
        "  $parameterName: '$correctPath'\n"
        ");",
      );
      return fromRepoRoot;
    }
    printerr('Found $parameterName at both: ${fromRepoRoot!.path} and '
        '${fromProjectRoot!.path}. Using the latter which is relative '
        'to the ${SidekickContext.cliName} entryPoint');
    return fromProjectRoot;
  }

  DartPackage? mainProject;
  Directory? flutterSdk;
  Directory? dartSdk;

  if (repoRoot == null) {
    // Not in a git repo. This is not a breaking change. Sidekick did not
    // support project without a git repo, before the migration
    if (mainProjectPath != null) {
      mainProject =
          DartPackage.fromDirectory(projectRoot.directory(mainProjectPath));
    }
    flutterSdk = _resolveSdkPath(flutterSdkPath, projectRoot);
    dartSdk = _resolveSdkPath(dartSdkPath, projectRoot);
  } else if (canonicalize(repoRoot.path) == canonicalize(projectRoot.path)) {
    // EntryPoint is in root of repository, we can safely migrate
    if (mainProjectPath != null) {
      mainProject =
          DartPackage.fromDirectory(projectRoot.directory(mainProjectPath));
    }
    flutterSdk = _resolveSdkPath(flutterSdkPath, projectRoot);
    dartSdk = _resolveSdkPath(dartSdkPath, projectRoot);
  } else {
    // Detected that repoRoot and projectRoot differ
    // This is where shit hits the fan. Users have to migrate their paths from
    // relative to repo-root to relative to project-root

    try {
      flutterSdk =
          resolveDirectoryBackwardsCompatible('flutterSdkPath', flutterSdkPath);
    } catch (e, stack) {
      throw SdkNotFoundException(
        flutterSdkPath!,
        repoRoot,
        cause: e,
        causeStackTrace: stack,
      );
    }
    try {
      dartSdk = resolveDirectoryBackwardsCompatible('dartSdkPath', dartSdkPath);
    } catch (e, stack) {
      throw SdkNotFoundException(
        dartSdkPath!,
        repoRoot,
        cause: e,
        causeStackTrace: stack,
      );
    }

    final mainProjectDir =
        resolveDirectoryBackwardsCompatible('mainProjectPath', mainProjectPath);
    if (mainProjectDir != null) {
      mainProject = DartPackage.fromDirectory(mainProjectDir);
    }
  }

  if (flutterSdkPath != null && dartSdkPath != null) {
    printerr("It's unnecessary to set both `flutterSdkPath` and `dartSdkPath`, "
        "because `dartSdkPath` is inherited from `flutterSdkPath. "
        "Set `dartSdkPath` only for pure dart projects.");
  }

  if (flutterSdkPath != null && flutterSdk?.existsSync() != true) {
    throw SdkNotFoundException(flutterSdkPath, projectRoot);
  }
  if (dartSdkPath != null && dartSdk?.existsSync() != true) {
    throw SdkNotFoundException(dartSdkPath, projectRoot);
  }
  if (mainProjectPath != null && mainProject?.root.existsSync() != true) {
    throw "mainProjectPath $mainProjectPath couldn't be resolved";
  }

  final runner = SidekickCommandRunner._(
    description: description ??
        'A sidekick CLI to equip Dart/Flutter projects with custom tasks',
    mainProject: mainProject,
    flutterSdk: flutterSdk,
    dartSdk: dartSdk,
  );
  return runner;
}

/// A CommandRunner that makes lookups in [SidekickContext] faster
class SidekickCommandRunner<T> extends CommandRunner<T> {
  SidekickCommandRunner._({
    required String description,
    this.mainProject,
    this.flutterSdk,
    this.dartSdk,
  }) : super(SidekickContext.cliName, description) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the sidekick version of this CLI.',
    );
  }

  @Deprecated('Use SidekickContext.projectRoot or SidekickContext.repository')
  Repository get repository => findRepository();

  final DartPackage? mainProject;
  final Directory? flutterSdk;
  final Directory? dartSdk;

  /// Mounts the sidekick related globals, returns a function to unmount them
  /// and restore the previous globals
  Unmount mount({String? debugName}) {
    final SidekickCommandRunner? oldRunner = _activeRunner;
    final SidekickContextCache oldCache = internalSidekickContextCache;
    _activeRunner = this;
    final newCache = SidekickContextCache(debugName: debugName);
    internalSidekickContextCache = newCache;
    final Directory? oldWorkingDirectory = _entryWorkingDirectory;
    _entryWorkingDirectory = Directory.current;

    return () {
      _activeRunner = oldRunner;
      assert(() {
        final mountedCache = internalSidekickContextCache;
        if (!identical(mountedCache, newCache)) {
          throw "Tried to unmount the SidekickContext.cache but the currently "
              "registered cache $mountedCache@${mountedCache.hashCode} is not the same "
              "as the one that was mounted $newCache@${newCache.hashCode}.";
        }
        return true;
      }());
      internalSidekickContextCache = oldCache;
      _entryWorkingDirectory = oldWorkingDirectory;
    };
  }

  @override
  Future<T?> run(Iterable<String> args) async {
    // a new command gets executes, reset whatever exitCode the previous command has set
    exitCode = 0;

    final unmount = mount(debugName: args.join(' '));

    ArgResults? parsedArgs;
    try {
      parsedArgs = parse(args);
      if (parsedArgs['version'] == true) {
        print('${SidekickContext.cliName} is using sidekick version $version');
        return null;
      }

      final result = await super.runCommand(parsedArgs);
      return result;
    } finally {
      try {
        if (_isUpdateCheckEnabled && !_isSidekickCliUpdateCommand(parsedArgs)) {
          // print warning if the user didn't fully update their CLI
          _checkCliVersionIntegrity();
          // print warning if CLI update is available
          // TODO start the update check in the background at command start
          // TODO prevent multiple update checks when a command start another command
          await _checkForUpdates();
        }
      } finally {
        unmount();
      }
    }
  }

  /// Print a warning if the CLI isn't up to date
  Future<void> _checkForUpdates() async {
    try {
      final updateFuture = VersionChecker.isDependencyUpToDate(
        package: SidekickContext.sidekickPackage,
        dependency: 'sidekick_core',
        pubspecKeys: ['sidekick', 'cli_version'],
      );
      // If it takes too long, don't wait for it
      final isUpToDate = await updateFuture.timeout(const Duration(seconds: 3));
      if (!isUpToDate) {
        printerr(
          '${yellow('Update available!')}\n'
          'Run ${cyan('${SidekickContext.cliName} sidekick update')} to update your CLI.',
        );
      }
    } catch (_) {
      /* ignore */
    }
  }

  /// Print a warning if the user manually updated the sidekick_core
  /// minimum version of their CLI and that version doesn't match with the
  /// CLI version listed in the pubspec at the path ['sidekick', 'cli_version']
  void _checkCliVersionIntegrity() {
    try {
      final sidekickCoreVersion = VersionChecker.getResolvedVersion(
        SidekickContext.sidekickPackage,
        'sidekick_core',
      );
      if (sidekickCoreVersion == null) {
        // Couldn't parse sidekick_core version. Most likely because it uses
        // a git or path dependency.
        return;
      }

      final sidekickCliVersion = VersionChecker.getMinimumVersionConstraint(
        SidekickContext.sidekickPackage,
        ['sidekick', 'cli_version'],
      );
      if (sidekickCliVersion == null) {
        // old CLI which has no version information yet
        // _checkForUpdates will print a warning to update the CLI in this case
        return;
      }

      if (sidekickCliVersion != sidekickCoreVersion) {
        printerr(
          "Dependency sidekick_core:${sidekickCoreVersion.canonicalizedVersion} "
          "doesn't match sidekick.cli_version ${sidekickCliVersion.canonicalizedVersion} in your pubspec.yaml.\n"
          "This is a signal that sidekick_core was updated manually without calling 'sidekick update'. "
          "Some features in your CLI might not work as expected.\n\n"
          'Please run ${cyan('${SidekickContext.cliName} sidekick update')} to execute the missing migrations.',
        );
      }
    } catch (e, s) {
      printerr(e.toString());
      printerr(s.toString());
    }
  }

  /// Returns true if the command executed from [parsedArgs] is [UpdateCommand]
  ///
  /// Copied and adapted from CommandRunner.runCommand
  bool _isSidekickCliUpdateCommand(ArgResults? parsedArgs) {
    if (parsedArgs == null) {
      return false;
    }
    var argResults = parsedArgs;
    Command? command;
    var commands = Map.of(this.commands);

    while (commands.isNotEmpty) {
      if (argResults.command == null) {
        return false;
      }

      // Step into the command.
      argResults = argResults.command!;
      command = commands[argResults.name];
      commands = Map.from(command!.subcommands);
    }

    if (parsedArgs['help'] as bool) {
      // execute HelpCommand from args library
      return false;
    }

    return command is UpdateCommand;
  }
}

/// Enables the [SidekickCommandRunner] to check for `sidekick` updates
///
/// Enables checking for `sidekick` updates in [SidekickCommandRunner]
///
/// Defaults to true, unless `export SIDEKICK_ENABLE_UPDATE_CHECK=false` is set
bool get _isUpdateCheckEnabled =>
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] != 'false';

typedef Unmount = void Function();

/// The runner that is currently executing, used for nesting
SidekickCommandRunner? _activeRunner;

/// The working directory (cwd) from which the cli run method was started
///
/// Can be useful in case a command has changed the current working directory
/// and the initial working directory is needed
///
/// Nested calls to the cli run method may return different directories
Directory get entryWorkingDirectory =>
    _entryWorkingDirectory ?? Directory.current;
Directory? _entryWorkingDirectory;

/// Name of the cli program
///
/// Usually a short acronym, like 3 characters
@Deprecated('Use SidekickContext.cliName')
String get cliName => SidekickContext.cliName;

/// Name of the cli program (if running a generated sidekick CLI)
/// or null (if running the global sidekick CLI)
@Deprecated('Use SidekickContext.cliName')
String? get cliNameOrNull => SidekickContext.cliName;

/// The root of the repository which contains all projects
@Deprecated('Use SidekickContext.projectRoot or SidekickContext.repository')
Repository get repository {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('repository');
  }
  return _activeRunner!.repository;
}

/// The main package which should be executed by default
///
/// The mainProjectPath has to be set by the user in [initializeSidekick].
/// It's optional, not every project has a mainProject, there are repositories
/// with zero or multiple projects.
DartPackage? get mainProject {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('mainProject');
  }
  return _activeRunner?.mainProject;
}

/// Returns the path to he Flutter SDK sidekick should use for the [flutter] command
///
/// This variable is usually set to a pinned version of the Flutter SDK per project, i.e.
/// - https://github.com/passsy/flutter_wrapper
/// - https://github.com/fluttertools/fvm
Directory? get flutterSdk {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('flutterSdk');
  }
  return _activeRunner?.flutterSdk;
}

/// Returns the path to the Dart SDK sidekick should use for the [dart] command
///
/// Usually inherited from [flutterSdk] which ships with an embedded Dart SDK
Directory? get dartSdk {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('dartSdk');
  }
  return _activeRunner?.dartSdk;
}

/// The Dart or Flutter SDK path is set in [initializeSidekick],
/// but the directory doesn't exist
class SdkNotFoundException implements Exception {
  SdkNotFoundException(
    this.sdkPath,
    this.repoRoot, {
    this.cause,
    this.causeStackTrace,
  });

  final String sdkPath;
  final Directory repoRoot;
  final Object? cause;
  final StackTrace? causeStackTrace;

  late final String message =
      "Dart or Flutter SDK set to '$sdkPath', but that directory doesn't exist. "
      "Please fix the path in `initializeSidekick` (dartSdkPath/flutterSdkPath). "
      "Note that relative sdk paths are resolved relative to the project root, "
      "which in this case is '${repoRoot.path}'.";

  @override
  String toString() {
    return [
      "SdkNotFoundException{",
      "message: $message",
      if (cause != null) "cause: $cause",
      if (causeStackTrace != null) "cause stack:\n$causeStackTrace",
      "}",
    ].join('\n');
  }
}

/// Transforms [sdkPath] to an absolute directory
///
/// This is to make passing `flutterSdkPath`/`dartSdkPath`
/// in `initializeSidekick` a relative path work from anywhere.
///
/// If [sdkPath] is a relative path, it is resolved relative to
/// the project root [repoRoot].
///
/// Throws a [SdkNotFoundException] if [sdkPath] is given but no
/// existing directory can be found.
Directory? _resolveSdkPath(String? sdkPath, Directory repoRoot) {
  if (sdkPath == null) {
    return null;
  }

  final resolvedDir = (Directory(sdkPath).isAbsolute
          ? Directory(sdkPath)
          // resolve relative path relative to project root
          : repoRoot.directory(sdkPath))
      .absolute;

  if (!resolvedDir.existsSync()) {
    return null;
  }

  return resolvedDir;
}

/// Called when properties of [SidekickCommandRunner] are accessed outside of
/// the execution of a command
class OutOfCommandRunnerScopeException implements Exception {
  String get message => "Can't access SidekickCommandRunner.$property "
      "when no command is executed.";

  final String property;

  OutOfCommandRunnerScopeException(this.property);

  @override
  String toString() {
    return "OutOfCommandRunnerScopeException{message: $message}";
  }
}
