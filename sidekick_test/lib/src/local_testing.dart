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

/// Links [SidekickDartRuntime] to [_systemDartSdkPath]
///
/// Use when testing a command which depends on [SidekickDartRuntime.dart] with
/// a fake sidekick package
void overrideSidekickDartRuntimeWithSystemDartRuntime(Directory sidekick) {
  env['SIDEKICK_PACKAGE_HOME'] = sidekick.absolute.path;

  final link = Link(sidekick.file('build/cache/dart-sdk').path)
    ..createSync(
      _systemDartSdkPath()!,
      recursive: true,
    );

  addTearDown(() {
    link.deleteSync();
    env['SIDEKICK_PACKAGE_HOME'] = null;
  });
}

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

/// Returns the Dart SDK of the `dart` executable on `PATH`
Directory? _systemDartSdk() {
  // /opt/homebrew/bin/dart
  final path = _systemDartExecutable();
  if (path == null) {
    // dart not on path
    return null;
  }
  final file = File(path);
  // /opt/homebrew/Cellar/dart/2.18.1/libexec/bin/dart
  final realpath = file.resolveSymbolicLinksSync();

  final libexec = File(realpath).parent.parent;
  return libexec;
}

/// Returns the path to Dart SDK of the `dart` executable on `PATH`
String? _systemDartSdkPath() => _systemDartSdk()?.path;

String? _systemDartExecutable() =>
    // /opt/homebrew/bin/dart
    start('which dart', progress: Progress.capture(), nothrow: true).firstLine;
