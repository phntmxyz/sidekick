import 'package:sidekick_core/sidekick_core.dart';

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

void _overrideDependency({
  required Directory package,
  required String dependency,
  required String path,
}) {
  final pubspec =
      PubSpec.fromFile(package.file('pubspec.yaml').path);
  pubspec.dependencyOverrides = {
    ...pubspec.dependencyOverrides,
    dependency: Dependency.fromPath(dependency, path),
  };
  pubspec.saveToFile(package.path);
}
