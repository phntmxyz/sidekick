import 'package:dcli/dcli.dart' as dcli;

import 'package:sidekick_core/sidekick_core.dart';

// TODO use sidekick_core/src/pub instead
part 'pub_utils.dart';

class PluginsCommand extends Command {
  @override
  final String description = 'Manages plugins for external commands';

  @override
  final String name = 'plugins';

  PluginsCommand() {
    addSubcommand(AddPluginsCommand());
  }
}

class AddPluginsCommand extends Command {
  @override
  final String description = 'Adds a new command to this sidekick cli';

  @override
  final String name = 'add';

  AddPluginsCommand() {
    argParser.addOption(
      'source',
      abbr: 's',
      help: 'The source used to find the package.',
      allowed: ['git', 'hosted', 'path'],
      defaultsTo: 'hosted',
    );

    argParser.addOption(
      'git-path',
      help: 'Path of git package in repository',
    );

    argParser.addOption(
      'git-ref',
      help: 'Git branch or commit to be retrieved',
    );

    argParser.addOption(
      'hosted-url',
      abbr: 'u',
      help:
          'A custom pub server URL for the package. Only applies when using the `hosted` source.',
    );
  }

  @override
  Future<void> run() async {
    final args = argResults!;
    Iterable<String> argsRest = args.rest;

    String readArg([String error = '']) {
      if (argsRest.isEmpty) usageException(error);
      final arg = argsRest.first;
      argsRest = argsRest.skip(1);
      return arg;
    }

    void validateNoExtraArgs() {
      if (argsRest.isEmpty) return;
      final unexpectedArguments = argsRest.map((e) => '"$e"').join(', ');
      usageException('Unexpected argument(s): $unexpectedArguments');
    }

    final source = args['source'] as String;

    if (source != 'git' &&
        (args['git-path'] != null || args['git-ref'] != null)) {
      usageException(
        'Options `--git-path` and `--git-ref` can only be used with --source=git.',
      );
    }

    Uri? hostedUrl;
    if (source == 'hosted' && args.wasParsed('hosted-url')) {
      try {
        hostedUrl = validateAndNormalizeHostedUrl(args['hosted-url'] as String);
      } on FormatException catch (e) {
        usageException('Invalid hosted-url: $e');
      }
    }

    /// depends on [source]
    /// 'hosted' -> package name on pub server; 'git' -> git repository url; 'path' -> local path
    final hostedPackageNameOrGitRepoUrlOrLocalPath =
        readArg('No package name/git repository url/path to activate given.');

    late final Directory packageRootDir;
    switch (source) {
      case 'path':
        packageRootDir = Directory(hostedPackageNameOrGitRepoUrlOrLocalPath);
        break;
      case 'hosted':
      case 'git':
        final gitPath = args['git-path'] as String?;
        final gitRef = args['git-ref'] as String?;
        final hostedVersionConstraint =
            source == 'hosted' && argsRest.isNotEmpty ? readArg() : null;
        validateNoExtraArgs();

        packageRootDir = _getPackageRootDirForHostedOrGitSource(
          source: source,
          hostedPackageNameOrGitRepoUrl:
              hostedPackageNameOrGitRepoUrlOrLocalPath,
          gitPath: gitPath,
          gitRef: gitRef,
          hostedUrl: hostedUrl,
          hostedVersionConstraint: hostedVersionConstraint,
        );
        break;
      default:
        throw StateError('unreachable');
    }
    assert(packageRootDir.existsSync(), "Package directory doesn't exist");

    // Run dart pub get on downloaded plugin
    _dartThrowing(['pub', 'get'], workingDirectory: packageRootDir);

    // Execute their bin/install.dart file
    final installScript = packageRootDir.directory('bin').file('install.dart');
    if (installScript.existsSync()) {
      _dartThrowing(
        [installScript.path],
        workingDirectory: Repository.requiredCliPackage,
      );
    }

    // Run dart pub get on sidekick cli
    _dartThrowing(
      ['pub', 'get'],
      workingDirectory: Repository.requiredCliPackage,
    );

    // Show errors warning, further instructions
    // TODO shouldn't the bin/install.dart script do this?
  }

  Directory _getPackageRootDirForHostedOrGitSource({
    required String source,
    required String hostedPackageNameOrGitRepoUrl,
    String? gitPath,
    String? gitRef,
    Uri? hostedUrl,
    String? hostedVersionConstraint,
  }) {
    // TODO Maybe we should do a `dart pub global list` first to check if
    // the package is already activated. If it is already activated,
    // we should at least print a warning because we are altering the
    // user's environment in a possibly unexpected way by calling
    // `dart pub global activate/deactivate`.
    //
    // In the end, we're calling `dart pub global activate` only to
    // make sure that the package is available in the cache directory
    // so we can execute its installation script (bin/install.dart).
    // The `dart pub cache` command would be more suitable, however it
    // doesn't offer a way to specify different sources (git/hosted/path)
    // or version constraints. If it offers these options one day,
    // we should start using it instead.

    final pubGlobalActivateArgs = [
      'pub',
      'global',
      'activate',
      '--no-executables',
      '--source',
      source,
      if (hostedUrl != null) hostedUrl.toString(),
      if (gitPath != null) ...['--git-path', gitPath],
      if (gitRef != null) ...['--git-ref', gitRef],
      hostedPackageNameOrGitRepoUrl,
      // optional version constraint (only valid for hosted source)
      if (hostedVersionConstraint != null) hostedVersionConstraint,
      // verbose output so we can parse the git SHA which is a part of
      // the cache directory for packages downloaded with the git source
      '-v'
    ];

    final progress = dcli.Progress.capture(captureStderr: false);
    _dartThrowing(pubGlobalActivateArgs, progress: progress);

    // TODO We should definitely do this in a less hacky way
    // Our goal is to get the cache directory of the package.
    // We're currently doing this by parsing the package name
    // and either version (source == 'hosted) or git SHA (source == 'git').
    // This information is then used to construct the directory names:
    //
    // For source == 'hosted':
    // <pub cache>/hosted/<transformed pub server url>/<package name>-<version>
    // E.g. /Users/pepe/.pub-cache/hosted/pub.dartlang.org/umbra-0.1.0-dev.4
    //
    // For source == 'git': <pub cache>/git/<package name>-<git SHA>
    // E.g. /Users/pepe/.pub-cache/git/mason-0184b2b833053731878a7f408dd3ed03765a70e8
    //
    // It would be great if the pub tool offered a way to directly get
    // the cache directory instead of using this hacky workaround, maybe we
    // can raise an issue or open a PR for this on the pub repository.
    // We should at least add some tests to the pub repository so this
    // workaround doesn't break in the future.

    // This line contains information about the package name
    // and resolved version.
    // - source == 'path':
    //   Activated bar 1.0.0 at path "/Users/pepe/dev/repos/foo".
    // - source == 'hosted':
    //   Activated sidekick_vault 0.5.4.
    // - source == 'git':
    //   Activated mason_cli 0.1.0-dev.36 from Git repository "https://github.com/felangel/mason".
    //
    // Also see:
    // https://github.com/dart-lang/pub/blob/master/lib/src/global_packages.dart#L188
    // https://github.com/dart-lang/pub/blob/master/lib/src/global_packages.dart#L276
    // https://github.com/dart-lang/pub/blob/master/lib/src/global_packages.dart#L459
    final activationRegExp = RegExp(r'.*Activated ([a-z_][a-z\d_]*) (\S+)[. ]');
    final activationInfo = progress.lines
        .map(activationRegExp.matchAsPrefix)
        .whereNotNull()
        .single;
    final packageName = activationInfo.group(1)!;
    final packageVersion = activationInfo.group(2)!;

    // The package was only activated to cache it and can be deactivated now
    _dartThrowing([
      'pub',
      'global',
      'deactivate',
      packageName,
    ]);

    switch (source) {
      case 'hosted':
        return Directory(
          join(
            pubCacheDir,
            'hosted',
            _urlToDirectory(hostedUrl?.toString() ?? defaultUrl),
            '$packageName-$packageVersion',
          ),
        );
      case 'git':
        final gitSHARegExp =
            RegExp(r'.*git (?:show|checkout) ([a-f0-9]{40})\b');
        final gitSHA = progress.lines
            .map(gitSHARegExp.matchAsPrefix)
            .whereNotNull()
            .single
            .group(1)!;

        return Directory(join(pubCacheDir, 'git', '$packageName-$gitSHA'));
      default:
        throw StateError('unreachable');
    }
  }
}

/// Wrapper around [dart] which throws when exit code is non-zero
/// TODO when dart exposes nothrow parameter, replace usages of this wrapper with dart(..., nothrow: true)
void _dartThrowing(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final exitCode = dart(
    args,
    workingDirectory: workingDirectory,
    progress: progress,
  );

  if (exitCode != 0) {
    throw Exception(
      "Unexpected exit code $exitCode when running 'dart $args'"
      "${workingDirectory != null ? " from directory '${workingDirectory.path}'" : ""}"
      ".",
    );
  }
}
