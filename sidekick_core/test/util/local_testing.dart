import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

/// Set to true, when the code should be checked for lint warnings and code
/// formatting
///
/// Usually, this should be checked only on the latest dart version, because
/// dartfmt is updated with the sdk and may require different formatting
final bool analyzeGeneratedCode = env['SIDEKICK_ANALYZE'] == 'true';

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

/// Links [SidekickDartRuntime] to [systemDartSdkPath]
///
/// Use when testing a command which depends on [SidekickDartRuntime.dart] with
/// a fake sidekick package
void overrideSidekickDartRuntimeWithSystemDartRuntime(Directory sidekick) {
  Link(sidekick.file('build/cache/dart-sdk').path).createSync(
    systemDartSdkPath()!,
    recursive: true,
  );
}

/// Fakes a sidekick package by writing required files and environment variables
///
/// Optional Parameters:
/// - [overrideSidekickCoreWithLocalDependency] whether to add a dependency
///   override to use the local sidekick_core dependency
/// - [overrideSidekickDartWithSystemDart] whether to link [SidekickDartRuntime]
///   to [systemDartSdkPath]. Useful when testing a command which depends
///   on [SidekickDartRuntime.dart]
/// - [sidekickCoreVersion] the dependency of sidekick_core in the pubspec.
///   Default value: 0.0.0
/// - [sidekickCliVersion] sidekick: cli_version: <sidekickCliVersion> in the
///   pubspec. Default value: 0.0.0
R insideFakeProjectWithSidekick<R>(
  R Function(Directory projectDir) callback, {
  bool overrideSidekickCoreWithLocalDependency = false,
  bool overrideSidekickDartWithSystemDart = false,
  String sidekickCoreVersion = "0.0.0",
  String sidekickCliVersion = "0.0.0",
}) {
  final tempDir = Directory.systemTemp.createTempSync();
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
  sidekick_core: $sidekickCoreVersion

sidekick:
  cli_version: $sidekickCliVersion
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
