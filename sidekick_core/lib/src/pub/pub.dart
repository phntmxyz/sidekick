/// Package that exposes some copy-pasted APIs from https://github.com/dart-lang/pub that isn't on pub.dev
/// Needed by plugins_command.dart to install plugins.
///
/// The pub package is not published on the official package repository pub.dev and only available on GitHub.
///
/// However, https://dart.dev/tools/pub/custom-package-repositories states:
/// To ensure that public packages are usable to everyone, the official package repository, pub.dev,
/// doesn’t allow publication of packages with git-dependencies or hosted-dependencies from custom package repositories.
///
/// Therefore, the needed code needs can't be added as a pub.dev dependency or git dependency and is copied here instead.
///
/// Alternatives:
/// - open a PR for pub to expose the information needed by plugin_command.dart directly (so internal code isn't needed anymore)
/// - publish a sidekick_pub package containing the required modified pub code and depend on it
library;

import 'package:sidekick_core/sidekick_core.dart';

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L54
/// This is needed to normalize a given pub server url.
/// Depends on [sidekickDartVersion]
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
/// If [sidekickDartVersion] < 2.19:
/// We change `https://pub.dev` to `https://pub.dartlang.org`, this  maintains
/// avoids churn for `pubspec.lock`-files which contain
/// `https://pub.dartlang.org`.
/// Else:
/// We change `https://pub.dartlang.org` to `https://pub.dev`, this  maintains
/// backwards compatibility with `pubspec.lock`-files which contain
/// `https://pub.dartlang.org`.
///
/// Throws [FormatException] if there is anything wrong with [hostedUrl].
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
  if (sidekickDartVersion.version < Version(2, 19, 0)) {
    if (u == Uri.parse('https://pub.dev')) {
      print('Using https://pub.dartlang.org instead of https://pub.dev.');
      u = Uri.parse('https://pub.dartlang.org');
    }
  } else {
    if (u == Uri.parse('https://pub.dartlang.org')) {
      print('Using https://pub.dev instead of https://pub.dartlang.org.');
      u = Uri.parse('https://pub.dev');
    }
  }

  return u;
}

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L138
/// Depends on [sidekickDartVersion]
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
    var defaultHostedUrl = sidekickDartVersion.version < Version(2, 19, 0)
        ? 'https://pub.dartlang.org'
        : 'https://pub.dev';
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

/// Copied from https://github.com/dart-lang/pub/blob/master/lib/src/source/hosted.dart#L1099
/// This function is used to convert the (custom) pub server url to a directory name.
/// The directory name is then used to download packages from that pub server to ~/.pub-cache/hosted/\<directory-name\>
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
String urlToDirectory(String hostedUrl) {
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
  return _replace(
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
String _replace(String source, Pattern matcher, String Function(Match) fn) {
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
final String pubCacheDir = () {
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
}();
