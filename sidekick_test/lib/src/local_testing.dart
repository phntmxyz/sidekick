import 'dart:async';
import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:sidekick_test/src/download_dart.sh.template.dart';
import 'package:sidekick_test/src/sidekick_config.sh.template.dart';
import 'package:test/test.dart';

/// True when dependencies should be linked to local sidekick dependencies
final bool shouldUseLocalDeps = env['SIDEKICK_PUB_DEPS'] != 'true';

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
/// - [sidekickCoreVersion] the dependency of sidekick_core in the pubspec.
///   Only written to pubspec if value is not null.
/// - [lockedSidekickCoreVersion] the used version in pubspec.lock
/// - [sidekickCliVersion] sidekick: cli_version: <sidekickCliVersion> in the
///   pubspec. Only written to pubspec if value is not null.
R insideFakeProjectWithSidekick<R>(
  R Function(Directory projectRoot) callback, {
  bool overrideSidekickCoreWithLocalDependency = false,
  String? sidekickCoreVersion,
  String? lockedSidekickCoreVersion,
  String? sidekickCliVersion,
  bool insideGitRepo = false,
}) {
  final tempDir = Directory.systemTemp.createTempSync();
  Directory projectRoot = tempDir;
  if (insideGitRepo) {
    'git init -q ${tempDir.path}'.run;
    projectRoot = tempDir.directory('myProject')..createSync();
  }

  projectRoot.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: main_project

environment:
  sdk: '>=2.14.0 <3.0.0'
''');
  projectRoot.file('dash').createSync();

  final fakeSidekickDir = projectRoot.directory('packages/dash')
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
  fakeSidekickDir.file('pubspec.lock')
    ..createSync()
    ..writeAsStringSync('''
packages:
  sidekick_core:
    dependency: "direct main"
    source: hosted
    description:
      name: sidekick_core
      url: "https://pub.dev"
    version: "${lockedSidekickCoreVersion ?? '0.0.0'}"
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  // tool dir
  final toolDir = fakeSidekickDir.directory('tool')..createSync();
  toolDir.file('download_dart.sh')
    ..createSync(recursive: true)
    ..writeAsStringSync(downloadDartSh);
  final sidekickConfig = toolDir.file('sidekick_config.sh')
    ..createSync(recursive: true)
    ..writeAsStringSync(sidekickConfigSh);
  chmod(sidekickConfig.path, permission: '755');

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = projectRoot.absolute.path;
  if (!env.exists('SIDEKICK_ENABLE_UPDATE_CHECK')) {
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'false';
  }

  if (overrideSidekickCoreWithLocalDependency) {
    overrideSidekickCoreWithLocalPath(fakeSidekickDir);
  }

  addTearDown(() {
    projectRoot.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = null;
  });

  Directory cwd = projectRoot;

  // Use FileSystemEntity.typeSync and FileSystemEntity.type of old zone,
  // otherwise doesn't work correctly in Dart >= 2.18
  final oldZone = Zone.current;

  return IOOverrides.runZoned<R>(
    () => callback(projectRoot),
    getCurrentDirectory: () => cwd,
    setCurrentDirectory: (dir) => cwd = Directory(dir),
    fseGetTypeSync: (String path, bool followLinks) {
      return oldZone.run(
        () => FileSystemEntity.typeSync(path, followLinks: followLinks),
      );
    },
    fseGetType: (String path, bool followLinks) {
      return oldZone.run(
        () => FileSystemEntity.type(path, followLinks: followLinks),
      );
    },
  );
}

/// Links [SidekickDartRuntime] to [_systemDartSdkPath]
///
/// Use when testing a command which depends on [SidekickDartRuntime.dart] with
/// a fake sidekick package
///
/// TODO doesn't work yet for functional sidekick CLI packages because
/// their recompile will kick off and redownload its Dart runtime
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
