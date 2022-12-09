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

/// Fakes a sidekick package by writing required files and environment variables
///
/// Optional Parameters:
/// - [overrideSidekickCoreWithLocalDependency] whether to add a dependency
///   override to use the local sidekick_core dependency
/// - [overrideSidekickDartWithSystemDart] whether to link [SidekickDartRuntime]
///   to [_systemDartSdkPath]. Useful when testing a command which depends
///   on [SidekickDartRuntime.dart]
/// - [sidekickCoreVersion] the dependency of sidekick_core in the pubspec.
///   Only written to pubspec if value is not null.
/// - [sidekickCliVersion] sidekick: cli_version: <sidekickCliVersion> in the
///   pubspec. Only written to pubspec if value is not null.
R insideFakeProjectWithSidekick<R>(
  R Function(Directory projectDir) callback, {
  bool overrideSidekickCoreWithLocalDependency = false,
  bool overrideSidekickDartWithSystemDart = false,
  String? sidekickCoreVersion,
  String? sidekickCliVersion,
}) {
  final tempDir = Directory.systemTemp.createTempSync();
  'git init ${tempDir.path}'.run;

  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: main_project

environment:
  sdk: '>=2.14.0 <3.0.0'
''');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash

environment:
  sdk: '>=2.14.0 <3.0.0'
  
${sidekickCoreVersion == null && !overrideSidekickCoreWithLocalDependency ? '' : '''
dependencies:
  sidekick_core: ${sidekickCoreVersion ?? '0.0.0'}
'''}

${sidekickCliVersion == null ? '' : '''
sidekick:
  cli_version: $sidekickCliVersion
'''}
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;

  if (overrideSidekickCoreWithLocalDependency) {
    overrideSidekickCoreWithLocalPath(fakeSidekickDir);
  }

  if (overrideSidekickDartWithSystemDart) {
    overrideSidekickDartRuntimeWithSystemDartRuntime(fakeSidekickDir);
  }

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
  });

  return IOOverrides.runZoned<R>(
    () => callback(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}

/// Links [SidekickDartRuntime] to [_systemDartSdkPath]
///
/// Use when testing a command which depends on [SidekickDartRuntime.dart] with
/// a fake sidekick package
void overrideSidekickDartRuntimeWithSystemDartRuntime(Directory sidekick) {
  env['SIDEKICK_PACKAGE_HOME'] = sidekick.absolute.path;

  final systemDartSdkPath = _systemDartSdkPath();
  if (systemDartSdkPath == null) {
    throw "Tried overriding Dart SDK of package '${sidekick.path}', but "
        "couldn't get path of system Dart SDK.";
  }

  final dartSdk = sidekick.directory('build/cache/dart-sdk');
  if (dartSdk.existsSync()) {
    // otherwise Link.createSync throws an exception
    dartSdk.deleteSync(recursive: true);
  }

  final dartSdkLink = Link(dartSdk.path)
    ..createSync(
      systemDartSdkPath,
      recursive: true,
    );

  print(
    'Overrode Dart SDK at ${dartSdkLink.absolute.path} '
    'to link to ${dartSdkLink.resolveSymbolicLinksSync()}',
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
