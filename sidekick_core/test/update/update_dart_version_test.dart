import 'dart:convert';

import 'package:fake_http_client/fake_http_client.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update_sidekick_cli.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    registerFallbackValue(Uri());
  });

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    'git init -q'.start(workingDirectory: tempDir.path);
    env['SIDEKICK_PACKAGE_HOME'] = tempDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_PACKAGE_HOME'] = null;
    });
  });

  test('Update Dart version to latest', () async {
    final pubspec = tempDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync("""
name: some_package
environment:
  sdk: ">=2.14.0 <3.0.0"
""");

    await _migrate(latestDartVersion: '2.18.0');

    expect(pubspec.readAsStringSync(), """
name: some_package
environment:
  sdk: ">=2.18.0 <3.0.0"
""");
  });

  test('Ignore Dart 3.0 update', () async {
    final pubspec = tempDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync("""
name: some_package
environment:
  sdk: ">=2.18.0 <3.0.0"
""");

    await _migrate(latestDartVersion: '3.0.0');

    expect(pubspec.readAsStringSync(), """
name: some_package
environment:
  sdk: ">=2.18.0 <3.0.0"
""");
  });
}

Future<void> _migrate({required String latestDartVersion}) async {
  await HttpOverrides.runZoned(
    () async {
      await migrate(
        from: Version(0, 0, 1),
        to: Version(0, 0, 2),
        migrations: [UseLatestDartVersionMigration(Version(0, 0, 2))],
      );
    },
    createHttpClient: (context) {
      final client = FakeHttpClient((req, client) async {
        return FakeHttpResponse(
          body: utf8.encode('{"version": "$latestDartVersion"}'),
        );
      });
      return client;
    },
  );
}
