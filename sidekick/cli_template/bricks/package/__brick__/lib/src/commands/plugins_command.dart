import 'package:dcli/dcli.dart' as dcli;

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
    /// 'hosted' -> package name; 'git' -> git repository; 'path' -> path
    final packageNameOrGitRepoOrPath =
        readArg('No package name/git repository/path to activate given.');

    late final Directory packageRootDir;
    switch (source) {
      case 'path':
        packageRootDir = Directory(packageNameOrGitRepoOrPath);
        break;
      case 'hosted':
      case 'git':
        final gitPath = args['git-path'] as String?;
        final gitRef = args['git-ref'] as String?;

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
          packageNameOrGitRepoOrPath,
          // optional version constraint (only valid for hosted source)
          if (source == 'hosted' && argsRest.isNotEmpty) readArg(),
          // verbose output so we can parse the git SHA which is a part of
          // the cache directory for packages downloaded with the git source
          '-v'
        ];
        validateNoExtraArgs();

        final progress = dcli.Progress.capture(captureStderr: false);
        _dartThrowing(pubGlobalActivateArgs, progress: progress);

        // TODO: We should definitely do this in a less hacky way
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
        final activationRegExp =
            RegExp(r'.*Activated ([a-z_][a-z\d_]*) (\S+)[. ]');
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
            packageRootDir = Directory(
              join(
                pubCacheDir,
                'hosted',
                _urlToDirectory(hostedUrl?.toString() ?? defaultUrl),
                '$packageName-$packageVersion',
              ),
            );
            break;
          case 'git':
            final gitSHARegExp =
                RegExp(r'.*git (?:show|checkout) ([a-f0-9]{40})\b');
            final gitSHA = progress.lines
                .map(gitSHARegExp.matchAsPrefix)
                .whereNotNull()
                .single
                .group(1)!;

            packageRootDir =
                Directory(join(pubCacheDir, 'git', '$packageName-$gitSHA'));
            break;
          default:
            throw StateError('unreachable');
        }

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

// TODO move to sidekick_core/pub_utilities or something

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L138
///
/// Gets the default URL for the package server for hosted dependencies.
final String defaultUrl = () {
  // Changing this to pub.dev raises the following concerns:
  //
  //  1. It would blow through users caches.
  //  2. It would cause conflicts for users checking pubspec.lock into git, if using
  //     different versions of the dart-sdk / pub client.
  //  3. It might cause other problems (investigation needed) for pubspec.lock across
  //     different versions of the dart-sdk / pub client.
  //  4. It would expand the API surface we're committed to supporting long-term.
  //
  // Clearly, a bit of investigation is necessary before we update this to
  // pub.dev, it might be attractive to do next time we change the server API.
  try {
    var defaultHostedUrl = 'https://pub.dartlang.org';
    // Allow the defaultHostedUrl to be overriden when running from tests
    if (runningFromTest) {
      defaultHostedUrl = Platform.environment['_PUB_TEST_DEFAULT_HOSTED_URL'] ??
          defaultHostedUrl;
    }
    return validateAndNormalizeHostedUrl(
      Platform.environment['PUB_HOSTED_URL'] ?? defaultHostedUrl,
    ).toString();
  } on FormatException catch (e) {
    throw Exception('Invalid `PUB_HOSTED_URL="${e.source}"`: ${e.message}');
  }
}();

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/io.dart#L558
/// Needed by [defaultUrl]
///
/// Whether the current process is a pub subprocess being run from a test.
///
/// The "_PUB_TESTING" variable is automatically set for all the test code's
/// invocations of pub.
final bool runningFromTest =
    Platform.environment.containsKey('_PUB_TESTING') && _assertionsEnabled;

final bool _assertionsEnabled = () {
  try {
    assert(false);
    // ignore: avoid_catching_errors
  } on AssertionError {
    return true;
  }
  return false;
}();

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/system_cache.dart#L40
final String pubCacheDir = (() {
  if (Platform.environment.containsKey('PUB_CACHE')) {
    return Platform.environment['PUB_CACHE']!;
  } else if (Platform.isWindows) {
    // %LOCALAPPDATA% is preferred as the cache location over %APPDATA%, because the latter is synchronised between
    // devices when the user roams between them, whereas the former is not.
    // The default cache dir used to be in %APPDATA%, so to avoid breaking old installs,
    // we use the old dir in %APPDATA% if it exists. Else, we use the new default location
    // in %LOCALAPPDATA%.
    //  TODO(sigurdm): handle missing APPDATA.
    final appData = Platform.environment['APPDATA']!;
    final appDataCacheDir = join(appData, 'Pub', 'Cache');
    if (Directory(appDataCacheDir).existsSync()) {
      return appDataCacheDir;
    }
    final localAppData = Platform.environment['LOCALAPPDATA']!;
    return join(localAppData, 'Pub', 'Cache');
  } else {
    return '${Platform.environment['HOME']}/.pub-cache';
  }
})();

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L54
/// This is needed to normalize a given pub server url.
///
/// Validates and normalizes a [hostedUrl] which is pointing to a pub server.
///
/// A [hostedUrl] is a URL pointing to a _hosted pub server_ as defined by the
/// [repository-spec-v2][1]. The default value is `pub.dev`, and can be
/// overwritten using `PUB_HOSTED_URL`. It can also specified for individual
/// hosted-dependencies in `pubspec.yaml`, and for the root package using the
/// `publish_to` key.
///
/// The [hostedUrl] is always normalized to a [Uri] with path that ends in slash
/// unless the path is merely `/`, in which case we normalize to the bare
/// domain.
///
/// We change `https://pub.dev` to `https://pub.dartlang.org`, this  maintains
/// avoids churn for `pubspec.lock`-files which contain
/// `https://pub.dartlang.org`.
///
/// Throws [FormatException] if there is anything wrong [hostedUrl].
///
/// [1]: ../../../doc/repository-spec-v2.md
Uri validateAndNormalizeHostedUrl(String hostedUrl) {
  Uri u;
  try {
    u = Uri.parse(hostedUrl);
  } on FormatException catch (e) {
    throw FormatException(
      'invalid url: ${e.message}',
      e.source,
      e.offset,
    );
  }
  if (!u.hasScheme || (u.scheme != 'http' && u.scheme != 'https')) {
    throw FormatException('url scheme must be https:// or http://', hostedUrl);
  }
  if (!u.hasAuthority || u.host == '') {
    throw FormatException('url must have a hostname', hostedUrl);
  }
  if (u.userInfo != '') {
    throw FormatException('user-info is not supported in url', hostedUrl);
  }
  if (u.hasQuery) {
    throw FormatException('querystring is not supported in url', hostedUrl);
  }
  if (u.hasFragment) {
    throw FormatException('fragment is not supported in url', hostedUrl);
  }
  u = u.normalizePath();
  // If we have a path of only `/`
  if (u.path == '/') {
    u = u.replace(path: '');
  }
  // If there is a path, and it doesn't end in a slash we normalize to slash
  if (u.path.isNotEmpty && !u.path.endsWith('/')) {
    u = u.replace(path: '${u.path}/');
  }
  // pub.dev and pub.dartlang.org are identical.
  //
  // We rewrite here to avoid caching both, and to avoid having different
  // credentials for these two.
  //
  // Changing this to pub.dev raises the following concerns:
  //
  //  1. It would blow through users caches.
  //  2. It would cause conflicts for users checking pubspec.lock into git, if using
  //     different versions of the dart-sdk / pub client.
  //  3. It might cause other problems (investigation needed) for pubspec.lock across
  //     different versions of the dart-sdk / pub client.
  //  4. It would expand the API surface we're committed to supporting long-term.
  //
  // Clearly, a bit of investigation is necessary before we update this to
  // pub.dev, it might be attractive to do next time we change the server API.
  if (u == Uri.parse('https://pub.dev')) {
    print('Using https://pub.dartlang.org instead of https://pub.dev.');
    u = Uri.parse('https://pub.dartlang.org');
  }
  return u;
}

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L1099
/// This function is used to convert the (custom) pub server url to a directory name.
/// The directory name is then used to download packages from that pub server to ~/.pub-cache/hosted/<directory-name>
///
/// E.g. _urlToDirectory('https://pub.flutter-io.cn') -> pub.flutter-io.cn -> packages will be downloaded to ~/.pub-cache/hosted/pub.flutter-io.cn
/// E.g. _urlToDirectory('https://pub.dartlang.org') -> pub.dartlang.org -> packages will be downloaded to ~/.pub-cache/hosted/pub.dartlang.org
///
/// It's important that the url is normalized with [validateAndNormalizeHostedUrl] first,
/// otherwise the equivalent urls 'https://pub.dartlang.org' and 'https://pub.dartlang.org/' (note the additional slash)
/// would result in the directory names 'pub.dartlang.org' vs. 'pub.dartlang.org%47'
///
/// Given a URL, returns a "normalized" string to be used as a directory name
/// for packages downloaded from the server at that URL.
///
/// This normalization strips off the scheme (which is presumed to be HTTP or
/// HTTPS) and *sort of* URL-encodes it. I say "sort of" because it does it
/// incorrectly: it uses the character's *decimal* ASCII value instead of hex.
///
/// This could cause an ambiguity since some characters get encoded as three
/// digits and others two. It's possible for one to be a prefix of the other.
/// In practice, the set of characters that are encoded don't happen to have
/// any collisions, so the encoding is reversible.
///
/// This behavior is a bug, but is being preserved for compatibility.
String _urlToDirectory(String hostedUrl) {
  // Normalize all loopback URLs to "localhost".
  final url = hostedUrl.replaceAllMapped(
      RegExp(r'^(https?://)(127\.0\.0\.1|\[::1\]|localhost)?'), (match) {
    // Don't include the scheme for HTTPS URLs. This makes the directory names
    // nice for the default and most recommended scheme. We also don't include
    // it for localhost URLs, since they're always known to be HTTP.
    final localhost = match[2] == null ? '' : 'localhost';
    final scheme =
        match[1] == 'https://' || localhost.isNotEmpty ? '' : match[1];
    return '$scheme$localhost';
  });
  return replace(
    url,
    RegExp(r'[<>:"\\/|?*%]'),
    (match) => '%${match[0]!.codeUnitAt(0)}',
  );
}

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/utils.dart#L315
/// Needed by [_urlToDirectory]
///
/// Replace each instance of [matcher] in [source] with the return value of
/// [fn].
String replace(String source, Pattern matcher, String Function(Match) fn) {
  final buffer = StringBuffer();
  var start = 0;
  for (final match in matcher.allMatches(source)) {
    buffer.write(source.substring(start, match.start));
    start = match.end;
    buffer.write(fn(match));
  }
  buffer.write(source.substring(start));
  return buffer.toString();
}
