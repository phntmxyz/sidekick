import 'dart:io';

import 'package:dcli/dcli.dart';

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
