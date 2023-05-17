import 'package:sidekick_core/sidekick_core.dart';

extension DirectoryExt on Directory {
  /// Recursively goes up and tries to find a [Directory] matching [predicate]
  ///
  /// Returns `null` when reaching root (/) without a match
  Directory? findParent(bool Function(Directory dir) predicate) {
    var dir = this;
    while (true) {
      if (predicate(dir)) {
        return dir;
      }
      final parent = dir.parent;
      if (canonicalize(dir.path) == canonicalize(parent.path)) {
        // not found
        return null;
      }
      dir = dir.parent;
    }
  }

  Iterable<Directory> allSubDirectories(
    bool Function(Directory dir) predicate,
  ) sync* {
    yield this;
    for (final dir in listSync().whereType<Directory>().where(predicate)) {
      yield* dir.allSubDirectories(predicate);
    }
  }

  Iterable<Directory> allParentDirectories([
    bool Function(Directory dir)? predicate,
  ]) sync* {
    Directory current = this;
    while (true) {
      if (predicate?.call(current) ?? true) {
        yield current;
      }
      final parent = current.parent;
      if (canonicalize(parent.path) == canonicalize(current.path)) {
        break;
      }
      current = parent;
    }
  }
}
