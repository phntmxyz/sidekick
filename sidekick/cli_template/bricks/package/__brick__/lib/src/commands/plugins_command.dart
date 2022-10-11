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
      'origin',
      abbr: 'o',
      help: 'The origin used to find the package.',
      allowed: ['git-url', 'pub-server', 'local-path'],
      defaultsTo: 'pub-server',
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
      'pub-server-url',
      abbr: 'u',
      help:
          'A custom pub server URL for the package. Only applies when using the `pub-server` origin.',
    );
  }

  @override
  Future<void> run() async {
    final args = argResults!;

    Uri? pubServerUrl;
    if (args.wasParsed('pub-server-url')) {
      try {
        pubServerUrl =
            validateAndNormalizeHostedUrl(args['pub-server-url'] as String);
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

    if (args['origin'] != 'git-url' &&
        (args['git-path'] != null || args['git-ref'] != null)) {
      usageException(
          'Options `--git-path` and `--git-ref` can only be used with --origin=git-url.');
    }

    final globals = GlobalPackages(SystemCache());

    late final Entrypoint entrypoint;
    final origin = args['origin'] as String;
    switch (origin) {
      case 'git-url':
        var repo = readArg('No Git repository given.');
        validateNoExtraArgs();
        entrypoint = await globals.activateGit(
          repo,
          [],
          overwriteBinStubs: false,
          path: args['git-path'] as String?,
          ref: args['git-ref'] as String?,
        );
        break;

      case 'pub-server':
        var package = readArg('No package to activate given.');

        // Parse the version constraint, if there is one.
        var constraint = VersionConstraint.any;
        if (argsRest.isNotEmpty) {
          try {
            constraint = VersionConstraint.parse(readArg());
          } on FormatException catch (error) {
            usageException(error.message);
          }
        }

        validateNoExtraArgs();
        entrypoint = await globals.activateHosted(
          package,
          constraint,
          [],
          overwriteBinStubs: false,
          url: pubServerUrl?.toString(),
        );
        break;

      case 'path':
        var path = readArg('No package to activate given.');
        validateNoExtraArgs();
        entrypoint = await globals.activatePath(
          path,
          [],
          overwriteBinStubs: false,
          analytics: null,
        );
        break;
      default:
        usageException(
          'Invalid value "$origin" for "--origin". '
          'Allowed values are "git-url", "pub-server", "local-path".',
        );
    }

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
  }
}
