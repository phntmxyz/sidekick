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
  // assuming cwd when running those tests is in the sidekick package
  final path = canonicalize('../sidekick_core');
  _overrideDependency(
    package: package,
    dependency: 'sidekick_core',
    path: path,
  );
}


/// Changes the sidekick_plugin_installer dependency to a local override
void overrideSidekickPluginInstallerWithLocalPath(Directory package) {
  if (!shouldUseLocalDeps) return;
  print('Overriding sidekick_plugin_installer dependency to local');
  // assuming cwd when running those tests is in the sidekick package
  final path = canonicalize('../sidekick_plugin_installer');
  _overrideDependency(
    package: package,
    dependency: 'sidekick_plugin_installer',
    path: path,
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
    ..writeAsStringSync('''
name: main_project
environment:
  sdk: ^2.10.0
''');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash_sdk')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash_sdk
environment:
  sdk: ^2.10.0
''');
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

void _overrideDependency({
  required Directory package,
  required String dependency,
  required String path,
}) {
  final pubspecPath = package.file('pubspec.yaml').path;
  final pubspec = PubSpec.fromFile(pubspecPath);
  pubspec.dependencyOverrides = {
    ...pubspec.dependencyOverrides,
    dependency: Dependency.fromPath(dependency, path),
  };
  pubspec.saveToFile(pubspecPath);
}
