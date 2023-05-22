import 'package:googleapis/storage/v1.dart';
import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';

class DartArchive {
  static const String base =
      'https://storage.googleapis.com/storage/v1/b/dart-archive/';

  final StorageApi _api = StorageApi(Client());

  Stream<Version> getLatestDartVersions() async* {
    String? nextToken;
    do {
      const prefix = 'channels/stable/release/';
      const delimiter = '/';
      final objects = await _api.objects.list(
        'dart-archive',
        prefix: prefix,
        delimiter: delimiter,
        pageToken: nextToken,
      );
      nextToken = objects.nextPageToken;
      final prefixes = objects.prefixes;
      if (prefixes == null) {
        continue;
      }
      for (final path in prefixes) {
        try {
          final rawVersion = path.replaceAll(RegExp('[^\\d.]*'), '');
          final version = Version.parse(rawVersion);
          yield version;
        } catch (_) {
          // ignore
        }
      }
    } while (nextToken != null);
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
