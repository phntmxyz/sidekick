import 'package:sidekick_core/sidekick_core.dart';

/// Recursively goes up and tries to find a [Directory] matching [predicate]
///
/// Returns `null` when reaching root (/) without a match
Directory? _findRootInWorkingDir(bool Function(Directory dir) predicate) {
  var dir = Directory.current;
  while (true) {
    if (predicate(dir)) {
      return dir;
    }
    final parent = dir.parent;
    if (dir.toString() == parent.toString()) {
      // not found
      return null;
    }
    dir = dir.parent;
  }
}

bool _isRepositoryRootDir(Directory dir) {
  final gitDir = dir.directory('.git');
  if (!gitDir.existsSync()) {
    return false;
  }

  final cliEntry = dir.file(cliName);
  if (!cliEntry.existsSync()) {
    return false;
  }

  return true;
}

/// Attempts to find the root of
Repository findRepository() {
  var root = _findRootInWorkingDir(_isRepositoryRootDir);
  if (root == null) {
    try {
      final String entrypointPath =
          "realpath /usr/local/bin/$cliName".lastLine!;
      final entryPoint = File(entrypointPath);
      if (!entryPoint.existsSync()) {
        throw 'could not read system link target';
      }
      root = entryPoint.parent;
    } catch (e) {
      error(
        'Could not find the $cliName entrypoint in parent of ${Directory.current}',
      );
    }
  }
  return Repository(root);
}

/// The repository of the project
///
/// Might be a single dart project or multiple packages, or even non dart packages
class Repository {
  Repository(this.root);

  final Directory root;
}
