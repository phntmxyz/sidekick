import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:test/test.dart';

/// True when dependencies should be linked to local sidekick dependencies
final bool shouldUseLocalDeps = env['SIDEKICK_PUB_DEPS'] != 'true';

/// Add this to the test name
final String localOrPubDepsLabel = shouldUseLocalDeps ? "(local)" : "(pub)";

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

/// Set to true, when the code should be checked for lint warnings and code
/// formatting
///
/// Usually, this should be checked only on the latest dart version, because
/// dartfmt is updated with the sdk and may require different formatting
final bool analyzeGeneratedCode = env['SIDEKICK_ANALYZE'] == 'true';


R insideFakeProjectWithSidekick<R>(R Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
  'git init ${tempDir.path}'.run;

  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: main_project\n');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash_sdk')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: dash_sdk\n');
  fakeSidekickDir.directory('lib').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
  });

  return IOOverrides.runZoned(
        () => block(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}
