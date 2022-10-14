import 'package:dcli/dcli.dart' as dcli;

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/pub/pub.dart' as pub;

/// Plugins are extensions for sidekick CLIs that can be installed from pub.dev
class PluginsCommand extends Command {
  @override
  final String description = 'Manages plugins for external commands';

  @override
  final String name = 'plugins';

  PluginsCommand() {
    addSubcommand(InstallPluginCommand());
  }
}

/// Installs a sidekick plugin
class InstallPluginCommand extends Command {
  @override
  final String description = 'Adds a new command to this sidekick cli';

  @override
  final String name = 'install';

  InstallPluginCommand() {
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
    final source = args['source'] as String;

    if (args.rest.isEmpty) {
      usageException(
        'No package name/git repository url/path to activate given.',
      );
    }

    final installer = args.rest.first;
    print(
      white('Installing $installer for '
          '${Repository.sidekickPackage!.cliName}'),
    );
    final Directory installerPackageRootDir = () {
      switch (source) {
        case 'path':
          return Directory(installer);
        case 'hosted':
          print('Downloading from pub $installer...');
          return _getPackageRootDirForHostedOrGitSource(args);
        case 'git':
          print('Downloading from git $installer...');
          return _getPackageRootDirForHostedOrGitSource(args);
        default:
          throw StateError('unreachable');
      }
    }();

    print('Installer downloaded');

    if (!installerPackageRootDir.existsSync()) {
      error("Package directory doesn't exist");
    }

    // get installer dependencies
    print('Installing dependencies...');
    sidekickDartRuntime.dart(
      ['pub', 'get'],
      workingDirectory: installerPackageRootDir,
      progress: Progress.printStdErr(),
    );

    print(white('Running Installer $installer'));
    // Execute installer. Requires a tool/install.dart file to execute
    final installScript = installerPackageRootDir.file('tool/install.dart');
    if (!installScript.existsSync()) {
      error(
        'No ${installScript.path} script found in package at $installerPackageRootDir',
      );
    }
    sidekickDartRuntime.dart(
      [installScript.path, Repository.requiredCliPackage.path],
      workingDirectory: Repository.requiredCliPackage,
    );

    print(
      green('Installed $installer for '
          '${Repository.sidekickPackage!.cliName}'),
    );
  }
}

// Welcome to the world of magic
Directory _getPackageRootDirForHostedOrGitSource(ArgResults args) {
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
    // don't make bin folder of package globally available
    '--no-executables',
    // verbose output so we can parse the git SHA which is a part of
    // the cache directory for packages downloaded with the git source
    '-v',
    ...args.arguments,
  ];

  final progress = dcli.Progress(
    dcli.devNull,
    stderr: print,
    // this parameter has a typo in dcli and actually is captureStdOut
    captureStdin: true,
    captureStderr: true,
  );
  sidekickDartRuntime.dart(pubGlobalActivateArgs, progress: progress);

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
  // For source == 'git':
  // <pub cache>/git/<package repository name>-<git SHA>/<if not null: git-path>
  // E.g. /Users/pepe/.pub-cache/git/mason-0184b2b833053731878a7f408dd3ed03765a70e8
  // Note that <package repository name> isn't necessarily equal to the package name.
  // E.g. for `dart pub global activate --no-executables --source git --git-path packages/umbra_cli https://github.com/wolfenrain/umbra`
  // The name of the activated package is 'umbra_cli', however the package repository name is 'umbra'.
  // The git-path is packages/umbra_cli and thus the cache directory is
  // /Users/pepe/.pub-cache/git/umbra-2d41bb5e233a61fb251cbb1e4cb3acda4e240bd2/packages/umbra_cli
  //
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
  final activationInfo =
      progress.lines.map(activationRegExp.matchAsPrefix).whereNotNull().single;
  final packageName = activationInfo.group(1)!;
  final packageVersion = activationInfo.group(2)!;

  // The package was only activated to cache it and can be deactivated now
  sidekickDartRuntime.dart(
    [
      'pub',
      'global',
      'deactivate',
      packageName,
    ],
    progress: Progress.printStdErr(),
  );

  final source = args['source'] as String;
  switch (source) {
    case 'hosted':
      final String hostedUrl = args.wasParsed('hosted-url')
          ? pub
              .validateAndNormalizeHostedUrl(args['hosted-url'] as String)
              .toString()
          : pub.defaultUrl;

      return Directory(
        join(
          pub.pubCacheDir,
          'hosted',
          pub.urlToDirectory(hostedUrl),
          '$packageName-$packageVersion',
        ),
      );
    case 'git':
      final gitSHARegExp =
          // either git show or git checkout is executed depending on whether the package is already cached
          RegExp(r'.*git (?:show|checkout) ([a-f0-9]{40})\b');
      final gitSHA = progress.lines
          .map(gitSHARegExp.matchAsPrefix)
          .whereNotNull()
          .map((e) => e.group(1)!)
          .toSet()
          .single;

      // The name of the activated package and the name of the cache directory aren't necessarily equal.
      // E.g. for `dart pub global activate --no-executables --source git --git-path packages/umbra_cli https://github.com/wolfenrain/umbra -v`
      // The name of the activated package is 'umbra_cli', however the package repository name is 'umbra'
      // The git-path is packages/umbra_cli and thus the cache directory is
      // /Users/pepe/.pub-cache/git/umbra-2d41bb5e233a61fb251cbb1e4cb3acda4e240bd2/packages/umbra_cli
      //
      // Thus join(pubCacheDir, 'git', '$packageName-$gitSHA') isn't always right.
      //
      // However, the verbose activate command writes this output to stderr which contains the correct path under the key "rootUri"
      //      |     {
      //      |       "name": "umbra_cli",
      //      |       "rootUri": "file:///Users/pepe/.pub-cache/git/umbra-2d41bb5e233a61fb251cbb1e4cb3acda4e240bd2/packages/umbra_cli",
      //      |       "packageUri": "lib/",
      //      |       "languageVersion": "2.17"
      //      |     },
      //
      // Since we know the full git SHA which is always part of the cache directory,
      // as well as the location of the cache directory, we can search the line
      // with the key "rootUri" to get the correct cache path of the directory
      //
      // This approach to get the package repository name should be safer
      // than parsing the package repository name from the git url.
      // A naive approach would be to split the git url on '/' and get the last element
      // (e.g. https://github.com/wolfenrain/umbra -> umbra),
      // however this would fail with an equivalent url (e.g. https://github.com/wolfenrain/umbra.git -> umbra.git)
      // and one would also have to test this with all other possible git hosting solutions as well.

      final gitCachePackagePathRegExp = RegExp(
        '.*"rootUri": ".*(${join(pub.pubCacheDir, 'git')}.*-$gitSHA\\b.*)"',
      );
      final packageRootDir = progress.lines
          .map(gitCachePackagePathRegExp.matchAsPrefix)
          .whereNotNull()
          .single
          .group(1)!;

      return Directory(packageRootDir);
    default:
      throw StateError('unreachable');
  }
}
