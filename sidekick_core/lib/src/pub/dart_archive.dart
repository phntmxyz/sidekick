import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';

class DartArchive {
  static const String base =
      'https://storage.googleapis.com/storage/v1/b/dart-archive/';

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

class DartVersionInfo {
  final String raw;

  DartVersionInfo(this.raw);

  @override
  String toString() {
    return 'DartVersionInfo{raw: $raw}';
  }
}
