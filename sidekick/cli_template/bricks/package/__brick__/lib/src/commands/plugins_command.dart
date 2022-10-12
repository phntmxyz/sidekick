// TODO copy needed code to lib/src/pub_utilities instead
// because depending on internals of other packages is naughty
// and in this case not possible anyways, because this is a git dependency (only pub dependencies are allowed on pub.dev)
import 'package:pub/src/entrypoint.dart';
import 'package:pub/src/global_packages.dart';
import 'package:pub/src/source/hosted.dart';
import 'package:pub/src/system_cache.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:sidekick_core/sidekick_core.dart';

// TODO move into sidekick_core
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

    Uri? hostedUrl;
    if (args.wasParsed('hosted-url')) {
      try {
        hostedUrl = validateAndNormalizeHostedUrl(args['hosted-url'] as String);
      } on FormatException catch (e) {
        usageException('Invalid hosted-url: $e');
      }
    }

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

    if (args['source'] != 'git' &&
        (args['git-path'] != null || args['git-ref'] != null)) {
      usageException(
        'Options `--git-path` and `--git-ref` can only be used with --source=git.',
      );
    }

    final source = args['source'] as String;
    final gitPath = args['git-path'] as String?;
    final gitRef = args['git-ref'] as String?;

    /// depends on args['source']:
    /// 'hosted' -> package name; 'git' -> git repository; 'path' -> path
    final packageNameOrGitRepoOrPath =
        readArg('No package name/git repository/path to activate given.');
    final pubGlobalActivateArgs = [
      'pub',
      'global',
      'activate',
      '--no-executables',
      '--source',
      source,
      if (gitPath != null) ...['--git-path', gitPath],
      if (gitRef != null) ...['--git-ref', gitRef],
      packageNameOrGitRepoOrPath,
      // optional version constraint (only valid for hosted source)
      if (source == 'hosted' && argsRest.isNotEmpty) readArg(),
    ];
    validateNoExtraArgs();
    dart(pubGlobalActivateArgs);
    // TODO: danach wieder deactivate; package bleibt noch im cache

    late final String packageRootDir;
    switch (source) {
      case 'git':
        break;
      case 'hosted':
        break;
      case 'path':
        packageRootDir = packageNameOrGitRepoOrPath;
        break;
      default:
        throw StateError('unreachable');
    }

    // TODO: Entrypoint[^ ] in global_packages.dart von pub die ersten 3 Results -> schauen wo der Path herkommt, das ist entrypoint.root.dir das weiter unten verwendet wird; dasselbe konstruieren und nutzen

    // TODO
    // Run plugin installer
    // Research how pub global activate downloads the package.
    // Use pub package to download packages. All is done, only SystemCache has to be pointed to /build
    // https://github.com/dart-lang/pub/blob/master/lib/src/command/global_activate.dart
    // -> globals.activateGit/Hosted/Path mit executables = []
    // https://github.com/dart-lang/pub/blob/master/lib/src/global_packages.dart
    // https://github.com/dart-lang/pub/blob/bc32a30ea5c86653e2a1899613c0a19d91b9a21c/lib/src/system_cache.dart
    // https://github.com/dart-lang/pub/blob/610ce7f280189f39ec411eb0a8592a191940d8d2/lib/src/solver/result.dart
    // TODO use entrypoint to run dart pub get && bin/install.dart
    // run dart pub get on plugin (with own dart runtime)

    /*
    final Process pubGetProcess = await Process.start(
      'dart',
      ['pub', 'get'],
      workingDirectory: entrypoint.root.dir,
    );
    stdout.addStream(pubGetProcess.stdout);
    stderr.addStream(pubGetProcess.stderr);
    final exitCode = await pubGetProcess.exitCode;
    if (exitCode != 0) {
      throw Exception("Exit code for 'dart pub get' was not okay: $exitCode");
    }

    // Execute their bin/install.dart file
    final installScript = join(entrypoint.root.dir, 'bin', 'install.dart');
    if (File(installScript).existsSync()) {
      final Process process = await Process.start(
        'dart',
        [installScript],
        workingDirectory: null, // TODO
      );
      stdout.addStream(process.stdout);
      stderr.addStream(process.stderr);
      final exitCode = await pubGetProcess.exitCode;
      if (exitCode != 0) {
        throw Exception("Exit code for install script was not okay: $exitCode");
      }
    }

    // Run dart pub get on sidekick cli

    // Show errors warning, further instructions

     */
  }
}
