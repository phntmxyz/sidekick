import 'package:sidekick_core/sidekick_core.dart';

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

  if (path ^ hosted ^ git) {
    throw 'Exactly one type of dependency arguments  (path/hosted/git) '
        'must be passed, but they were mixed or none were given.';
  }
  if (git && gitUrl != null) {
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
      localPath!
    ] else if (hosted) ...[
      if (hostedUrl != null) '--hosted-url',
      hostedUrl!
    ] else if (git) ...[
      '--git-url',
      gitUrl!,
      if (gitRef != null) ...['--git-ref', gitRef],
      if (gitPath != null) ...['--git-path', gitPath]
    ]
  ];

  sidekickDartRuntime.dart(
    ['pub', 'remove', dependency],
    workingDirectory: package.root,
    progress: Progress.devNull(),
  );
  sidekickDartRuntime.dart(
    pubAddArgs,
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
