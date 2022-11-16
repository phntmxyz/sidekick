import 'dart:convert';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:test/test.dart';

void main() {
  test('UpdateCommand generates new files', () async {
    await insideFakeProjectWithSidekick((projectDir) async {
      final sidekickDir = projectDir.directory('packages/dash');
      final expectedFilesToGenerate = [
        'tool/download_dart.sh',
        'tool/install.sh',
        'tool/run.sh',
        'tool/sidekick_config.sh',
        'bin/main.dart',
        'lib/src/dash_project.dart',
        'lib/dash_sidekick.dart',
        'analysis_options.yaml',
        '.gitignore',
      ].map(sidekickDir.file);

      for (final file in expectedFilesToGenerate) {
        expect(
          !file.existsSync() || file.readAsStringSync().isEmpty,
          isTrue,
          reason: '${file.path} exists or is not empty',
        );
      }

      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: systemDartSdkPath(),
      );

      final beforeVersion = getCurrentMinimumSidekickCoreVersion();

      runner.addCommand(UpdateCommand());
      await runner.run(['update']);

      final afterVersion = getCurrentMinimumSidekickCoreVersion();
      expect(beforeVersion, lessThan(afterVersion));
      expect(afterVersion, await getLatestSidekickCoreVersion());

      for (final file in expectedFilesToGenerate) {
        expect(
          file.existsSync() && file.readAsStringSync().isNotEmpty,
          isTrue,
          reason: '${file.path} does not exist or is empty',
        );
      }
    });
  });
}

R insideFakeProjectWithSidekick<R>(R Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
  print(tempDir);
  'git init ${tempDir.path}'.run;

  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: main_project\n');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:
  sidekick_core: 0.7.1
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  overrideSidekickCoreWithLocalPath(fakeSidekickDir);

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
  });

  return IOOverrides.runZoned(
    () => block(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}

Version getCurrentMinimumSidekickCoreVersion() {
  final regEx = RegExp(
    '\n  sidekick_core:\\s*[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
  );
  final pubspec = Repository.requiredSidekickPackage.pubspec.readAsStringSync();

  final minVersion =
      regEx.allMatches(pubspec).map((e) => e.group(1)).whereNotNull().single;

  return Version.parse(minVersion);
}

/// True when dependencies should be linked to local sidekick dependencies
final bool shouldUseLocalDeps = env['SIDEKICK_PUB_DEPS'] != 'true';

/// Changes the sidekick_core dependency to a local override
void overrideSidekickCoreWithLocalPath(Directory package) {
  if (!shouldUseLocalDeps) return;
  print('Overriding sidekick_core dependency to local');
  final pubspec = package.file("pubspec.yaml");
  // assuming cwd when running those tests is in the sidekick package
  final corePath = canonicalize('../sidekick_core');
  pubspec.writeAsStringSync(
    '''

dependency_overrides:
  sidekick_core:
    path: $corePath

  ''',
    mode: FileMode.append,
  );
}

Future<Version> getLatestSidekickCoreVersion() async {
  final response =
      await get(Uri.parse('https://pub.dev/api/packages/sidekick_core'));

  if (response.statusCode != HttpStatus.ok) {
    throw "pub.dev didn't respond";
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final latestVersion =
      (body['latest'] as Map<String, dynamic>)['version'] as String;

  return Version.parse(latestVersion);
}
