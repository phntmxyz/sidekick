import 'package:sidekick_core/sidekick_core.dart';

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
