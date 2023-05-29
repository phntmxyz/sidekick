import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

/// Add the plugin itself as dependency to the sidekick CLI
///
/// Uses [PluginContext] to get the necessary information
///
/// Should be called from tool/install.dart
void addSelfAsDependency() {
  final isPluginProtocolV2 = PluginContext.name != null;
  if (isPluginProtocolV2) {
    // Starting with sidekick_core: >=0.13.0
    // - PluginContext.sidekickPackage (always available)
    // - PluginContext.name (always available)

    // Available when installed from local path
    // - PluginContext.localPath (always)
    // - PluginContext.versionConstraint (optional)

    // Available when installed from git
    // - PluginContext.gitUrl (always)
    // - PluginContext.gitRef (optional)
    // - PluginContext.gitPath (optional)
    // - PluginContext.versionConstraint (optional)

    // Available when installed from hosted
    // - PluginContext.hostedUrl (optional)
    // - PluginContext.versionConstraint (optional)
    addDependency(
      package: PluginContext.sidekickPackage,
      dependency: PluginContext.name!,
      versionConstraint: PluginContext.versionConstraint,
      localPath: PluginContext.localPath,
      hostedUrl: PluginContext.hostedUrl,
      gitUrl: PluginContext.gitUrl,
      gitRef: PluginContext.gitRef,
      gitPath: PluginContext.gitPath,
    );
    return;
  }

  // Protocol v1 (sidekick_core: >=0.11.0 <=0.12.0)
  // Injected env vars are:
  // - PluginContext.sidekickPackage (always available)
  // - PluginContext.localPlugin (when installed via local path)
  final pluginName = PluginContext.installerPlugin.name;
  if (PluginContext.localPlugin == null) {
    // install from hosted source which is the default when given nothing else
    addDependency(
      package: PluginContext.sidekickPackage,
      dependency: pluginName,
    );
  } else {
    // install from local source
    addDependency(
      package: PluginContext.sidekickPackage,
      dependency: pluginName,
      localPath: PluginContext.localPlugin!.root.path,
    );
  }
}

/// Adds [dependency] to [package] as a path, hosted, or git dependency.
///
/// If no additional parameters are specified, a dependency is added as
/// hosted dependency by default.
void addDependency({
  required DartPackage package,
  required String dependency,
  String? versionConstraint,
  // path dependency parameters
  String? localPath,
  // hosted dependency parameters
  String? hostedUrl,
  // git dependency parameters
  String? gitUrl,
  String? gitRef,
  String? gitPath,
}) {
  final path = localPath != null;
  final git = [gitUrl, gitRef, gitPath].any((e) => e != null);
  // hosted is the default if none of the other arguments are given
  final hosted = hostedUrl != null || (!git && !path);

  if (!(path ^ hosted ^ git)) {
    throw 'Too many arguments. Pass only one type of arguments (path/hosted/git).';
  }
  if (git && gitUrl == null) {
    throw 'git arguments were passed, but `gitUrl` was null.';
  }

  final List<String> pubAddArgs = [
    'pub',
    'add',
    if (versionConstraint != null)
      '$dependency:$versionConstraint'
    else
      dependency,
    if (path) ...[
      '--path',
      localPath
    ] else if (hosted) ...[
      if (hostedUrl != null) ...['--hosted-url', hostedUrl],
    ] else if (git) ...[
      '--git-url',
      gitUrl!,
      if (gitRef != null) ...['--git-ref', gitRef],
      if (gitPath != null) ...['--git-path', gitPath]
    ]
  ];

  if (package.pubspec.readAsStringSync().contains('$dependency:')) {
    sidekickDartRuntime.dart(
      ['pub', 'remove', dependency],
      workingDirectory: package.root,
      progress: Progress.devNull(),
    );
  }
  sidekickDartRuntime.dart(
    pubAddArgs,
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
