import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';

/// Load data from the Dart SDK Archive https://dart.dev/get-dart/archive
class DartArchive {
  /// Returns the latest dart versions
  Stream<Version> getLatestDartVersions() async* {
    final url = Uri.parse(
      'https://storage.googleapis.com/storage/v1/b/dart-archive/o?delimiter=/&prefix=channels/stable/release/',
    );
    final response = await get(url);
    if (response.statusCode != 200) {
      throw Exception('Received status code ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<dynamic, dynamic>;

    final prefixes = json['prefixes'] as List<dynamic>;
    for (final path in prefixes) {
      try {
        final rawVersion = (path as String).replaceAll(RegExp('[^\\d.]*'), '');
        final version = Version.parse(rawVersion);
        yield version;
      } catch (_) {
        // ignore
      }
    }
  }
}
