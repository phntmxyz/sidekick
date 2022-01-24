import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/global_sidekick_root.dart';

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
Repository findRepository(String relativeCliPackagePath) {
  final root = _findRootInWorkingDir(_isRepositoryRootDir);
  if (root != null) {
    return Repository(
      root: root,
      // TODO is it really relative to root?
      cliPackage: root.directory(relativeCliPackagePath),
      // TODO always lookup global entry point or detect the script location reliably
      entryPoint: null,
    );
  }

  // Outside of repository. Read link to binary
  try {
    final globalEntryPoint =
        GlobalSidekickRoot.linkedBinary(cliName).resolveSymbolicLinksSync();
    final entryPoint = File(globalEntryPoint);

    if (!entryPoint.existsSync()) {
      // TODO remove broken symlink?
      throw 'could not read system link target';
    }
    return Repository(
      root: entryPoint.parent,
      cliPackage: entryPoint.parent.directory(relativeCliPackagePath),
      entryPoint: entryPoint,
    );
  } catch (e) {
    error(
      'Could not find the $cliName entrypoint in parent of ${Directory.current}',
    );
  }
}

/// The repository of the project
///
/// Might be a single dart project or multiple packages, or even non dart packages
class Repository {
  Repository({
    required this.root,
    required this.cliPackage,
    required this.entryPoint,
  });

  final Directory root;

  final Directory cliPackage;

  final File? entryPoint;
}
